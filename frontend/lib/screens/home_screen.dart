import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer_profile.dart';
import '../models/expiring_item.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/customer_service.dart';
import '../services/notification_read_store.dart';
import '../services/notification_service.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_widgets.dart';
import '../widgets/auth_scope.dart';
import '../widgets/notification_bell.dart';
import '../i18n/locale_scope.dart';
import '../state/data_refresh.dart';
import 'item_detail_screen.dart';
import 'product_detail_screen.dart';

/// Checkon home dashboard built from household items and analytics.
class HomeScreen extends StatefulWidget {
  final VoidCallback? onSeeAllItems;
  final VoidCallback? onInitialLoadComplete;
  final bool showStartupArtwork;
  const HomeScreen({
    super.key,
    this.onSeeAllItems,
    this.onInitialLoadComplete,
    this.showStartupArtwork = true,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ApiService? _api;
  CustomerService? _customer;
  final _store = NotificationStore();
  Future<_HomeData>? _future;
  bool _initialLoadComplete = false;
  bool _initialLoadNotified = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_api == null) {
      final auth = AuthScope.of(context);
      _api = ApiService(auth: auth);
      _customer = CustomerService(auth: auth);
      _future = _loadInitial();
    }
    // re-fetch when global data changes (create/update/delete/profile)
    final rev = DataScope.watch(context);
    if (rev != _rev) {
      _rev = rev;
      if (_api != null) {
        _future = _initialLoadComplete ? _load() : _loadInitial();
      }
    }
  }

  int _rev = 0;

  Future<_HomeData> _loadInitial() async {
    final stopwatch = Stopwatch()..start();
    try {
      return await _load();
    } finally {
      if (widget.showStartupArtwork) {
        const minimumSplashDuration = Duration(milliseconds: 1500);
        final remaining = minimumSplashDuration - stopwatch.elapsed;
        if (remaining > Duration.zero) await Future<void>.delayed(remaining);
      }
      _initialLoadComplete = true;
    }
  }

  Future<_HomeData> _load() async {
    final summaryFuture = _api!.getSummary();
    final expiringFuture = _api!.getExpiringSoon(days: 30);
    final productsToBuyFuture = _api!.getProductsToBuy();
    final productsFuture = _api!.getProducts();
    final profileFuture = _loadProfile();
    final results = await Future.wait<Object?>(
      [
        summaryFuture,
        expiringFuture,
        productsToBuyFuture,
        profileFuture,
        productsFuture,
      ],
    );
    final summary = results[0] as AnalyticsSummary;
    final expiring = results[1] as List<ExpiringItem>;
    final productsToBuy = results[2] as List<Product>;
    final profile = results[3] as CustomerProfile?;
    final products = results[4] as List<Product>;

    // keep OS reminders in sync on every home load (app start / after login /
    // after add-edit-delete via DataScope). no-op on web.
    if (mounted) {
      unawaited(
        NotificationService.instance
            .syncExpiring(expiring, context.strings)
            .catchError((Object error, StackTrace stackTrace) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
              library: 'notifications',
              context:
                  ErrorDescription('while syncing expiring-item reminders'),
            ),
          );
        }),
      );
      unawaited(
        NotificationService.instance
            .syncProductStatusRemindersForMonth(
          products: products,
          productsToBuy: productsToBuy,
          strings: context.strings,
        )
            .catchError((Object error, StackTrace stackTrace) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
              library: 'notifications',
              context: ErrorDescription(
                'while syncing monthly product status reminders',
              ),
            ),
          );
        }),
      );
    }
    // bell badge = expiring within threshold AND not yet read (local).
    // reuse the same event store the notifications screen uses, so retention
    // (7 days) and read-state stay consistent.
    final expiringIds = expiring
        .where((it) =>
            (it.daysUntilExpiry ?? 9999) <= NotificationService.thresholdDays)
        .map((it) => it.itemId)
        .toSet();
    final events = await _store.sync(expiringIds);
    final unread = events.where((e) => !e.read).length;
    return _HomeData(
        total: summary.grandTotal,
        totalItems: summary.totalItems,
        expiring: expiring,
        productsToBuy: productsToBuy,
        unreadCount: unread,
        profile: profile);
  }

  Future<CustomerProfile?> _loadProfile() async {
    try {
      return await _customer!.getMyProfile();
    } catch (_) {
      return null;
    }
  }

  void _reload() {
    setState(() {
      _future = _initialLoadComplete ? _load() : _loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final baht = NumberFormat.currency(
        locale: context.locale.lang, symbol: '฿', decimalDigits: 0);
    final df = DateFormat('d MMM yyyy', context.locale.lang);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<_HomeData>(
          future: _future,
          builder: (context, snap) {
            if (_initialLoadComplete &&
                snap.connectionState != ConnectionState.waiting &&
                !_initialLoadNotified) {
              _initialLoadNotified = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) widget.onInitialLoadComplete?.call();
              });
            }
            if (snap.connectionState == ConnectionState.waiting) {
              return _initialLoadComplete || !widget.showStartupArtwork
                  ? const SkeletonList()
                  : const StartupLoadingView();
            }
            if (snap.hasError) {
              return ErrorView(error: snap.error!, onRetry: _reload);
            }
            final data = snap.data!;
            final attention = [...data.expiring]..sort((a, b) =>
                (a.daysUntilExpiry ?? 9999)
                    .compareTo(b.daysUntilExpiry ?? 9999));
            final productsToBuy = [...data.productsToBuy]..sort((a, b) {
                final statusRank = (a.status == ProductStatus.out ? 0 : 1)
                    .compareTo(b.status == ProductStatus.out ? 0 : 1);
                return statusRank != 0 ? statusRank : a.name.compareTo(b.name);
              });
            final name = data.profile?.firstName ?? '';

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                _GreetingHeader(
                  greeting: s.greeting(name),
                  question: s.homeQuestion,
                  expiringCount: data.unreadCount,
                  onBellReturn: _reload,
                ),
                Transform.translate(
                  offset: const Offset(0, -16),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: _HomeSummaryCard(
                      totalItems: '${data.totalItems}',
                      attentionCount:
                          '${attention.length + productsToBuy.length}',
                      itemsLabel: s.statAllItems,
                      attentionLabel: s.statLowItems,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                  child: SectionHeader(
                    title: s.toManage,
                    action: widget.onSeeAllItems == null
                        ? null
                        : TextButton(
                            onPressed: widget.onSeeAllItems,
                            child: Text(s.seeAll),
                          ),
                  ),
                ),
                if (attention.isEmpty && productsToBuy.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: AppCard(
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              color: AppColors.success),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: Text(s.nothingToManage)),
                        ],
                      ),
                    ),
                  )
                else ...[
                  ...productsToBuy.take(5).map((product) => Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                        child: _ProductStatusCard(product: product),
                      )),
                  ...attention
                      .take((5 - productsToBuy.length).clamp(0, 5).toInt())
                      .map((it) => Padding(
                            padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                            child: _AttentionCard(item: it, df: df),
                          )),
                ],
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _BudgetCard(spent: data.total, baht: baht),
                ),
                const SizedBox(height: 80),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HomeData {
  final double total;
  final int totalItems;
  final List<ExpiringItem> expiring;
  final List<Product> productsToBuy;
  final int unreadCount;
  final CustomerProfile? profile;
  _HomeData(
      {required this.total,
      required this.totalItems,
      required this.expiring,
      required this.productsToBuy,
      this.unreadCount = 0,
      this.profile});
}

class _GreetingHeader extends StatelessWidget {
  final String greeting;
  final String question;
  final int expiringCount;
  final VoidCallback? onBellReturn;
  const _GreetingHeader({
    required this.greeting,
    required this.question,
    this.expiringCount = 0,
    this.onBellReturn,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: isDark ? AppGradients.brandDark : AppGradients.brand,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xxl),
        ),
        boxShadow: AppShadows.brandGlow(AppColors.oceanBlue),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -54,
            top: 24,
            child: _AeroOrb(
              size: 190,
              color: AppColors.skyBlue.withValues(alpha: 0.24),
            ),
          ),
          Positioned(
            right: 86,
            top: 132,
            child: _AeroOrb(
              size: 58,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.xxxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/images/logos/953b0995-0966-4844-9cac-afe275ac9282.png',
                        height: 64,
                        fit: BoxFit.contain,
                      ),
                      const Spacer(),
                      NotificationBell(
                        count: expiringCount,
                        onReturn: onBellReturn,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    greeting,
                    style: AppType.titleMedium.copyWith(
                      color: (isDark ? Colors.white : AppColors.brand900)
                          .withValues(alpha: 0.82),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.home_rounded,
                        size: 28,
                        color: isDark ? Colors.white : AppColors.brand900,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          question,
                          style: AppType.headlineMedium.copyWith(
                            color: isDark ? Colors.white : AppColors.brand900,
                            height: 1.12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _HomeGlassCard({
    required this.child,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(AppRadius.card);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppGlass.blurSigma,
          sigmaY: AppGlass.blurSigma,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark
                ? AppSurfaces.darkGlass.withValues(alpha: 0.82)
                : Colors.white.withValues(alpha: 0.72),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.white.withValues(alpha: 0.09),
                      Colors.white.withValues(alpha: 0.025),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.48),
                      Colors.white.withValues(alpha: 0.12),
                    ],
            ),
            borderRadius: radius,
            border: Border.all(
              color: isDark
                  ? AppColors.brand300.withValues(alpha: 0.24)
                  : Colors.white.withValues(alpha: 0.88),
              width: 1.2,
            ),
            boxShadow: AppShadows.glass,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _AeroOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _AeroOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _HomeSummaryCard extends StatelessWidget {
  final String totalItems;
  final String attentionCount;
  final String itemsLabel;
  final String attentionLabel;

  const _HomeSummaryCard({
    required this.totalItems,
    required this.attentionCount,
    required this.itemsLabel,
    required this.attentionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return _HomeGlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryMetric(
              icon: Icons.inventory_2_rounded,
              value: totalItems,
              label: itemsLabel,
              color: AppColors.brand600,
            ),
          ),
          Container(
            width: 1,
            height: 64,
            color: Theme.of(context).dividerColor,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          ),
          Expanded(
            child: _SummaryMetric(
              icon: Icons.notifications_active_rounded,
              value: attentionCount,
              label: attentionLabel,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _SummaryMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBackground =
        color == AppColors.warning ? AppColors.amberTint : AppColors.brand100;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark
                ? color.withValues(alpha: 0.2)
                : iconBackground.withValues(alpha: 0.8),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppType.headlineMedium.copyWith(
                  color: isDark ? color : AppColors.brand800,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.neutral800,
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AttentionCard extends StatelessWidget {
  final ExpiringItem item;
  final DateFormat df;
  const _AttentionCard({required this.item, required this.df});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final d = item.daysUntilExpiry;
    final status = AppStatus.fromDays(d);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = AppStatus.fg(status, dark: isDark);
    final statusLabel = {
      StockStatus.normal: s.statusNormal,
      StockStatus.low: s.statusLow,
      StockStatus.shouldBuy: s.statusShouldBuy,
      StockStatus.out: s.statusOut,
    }[status]!;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ItemDetailScreen(itemId: item.itemId)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppStatus.bg(status, dark: isDark),
              borderRadius: AppRadius.rMd,
            ),
            child: Icon(Icons.inventory_2_outlined, color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  item.expiryDate != null
                      ? (d != null && d < 0
                          ? s.overdueDays(-d)
                          : s.expireShort(df.format(item.expiryDate!)))
                      : '${item.quantity} ${s.pieces}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          StatusChip(status: status, label: statusLabel),
          const SizedBox(width: AppSpacing.xs),
          Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _ProductStatusCard extends StatelessWidget {
  final Product product;
  const _ProductStatusCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final isOut = product.status == ProductStatus.out;
    final color = isOut ? AppColors.danger : AppColors.warning;
    final label = isOut ? s.productStatusOut : s.productStatusLow;
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: product.productId),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isOut ? AppColors.coralTint : AppColors.amberTint,
              borderRadius: AppRadius.rMd,
            ),
            child: Icon(
              isOut
                  ? Icons.remove_shopping_cart_rounded
                  : Icons.warning_amber_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  s.toBuyTitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          StatusChip(
            status: isOut ? StockStatus.out : StockStatus.shouldBuy,
            label: label,
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatefulWidget {
  final double spent;
  final NumberFormat baht;
  const _BudgetCard({required this.spent, required this.baht});

  @override
  State<_BudgetCard> createState() => _BudgetCardState();
}

class _BudgetCardState extends State<_BudgetCard> {
  static const _kBudgetKey = 'app_budget';
  double _budget = 3000;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // re-read whenever the shared data revision bumps (e.g. budget changed)
    DataScope.watch(context);
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final b = prefs.getDouble(_kBudgetKey);
    if (b != null && mounted && b != _budget) {
      setState(() => _budget = b);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final spent = widget.spent;
    final baht = widget.baht;
    // progress = spent / budget, clamped to 0..1; guard divide-by-zero
    final ratio = _budget > 0 ? (spent / _budget) : 0.0;
    final progress = ratio.clamp(0.0, 1.0);
    final pct = (ratio * 100).round();
    final overBudget = spent > _budget;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = overBudget ? AppColors.danger : AppColors.brand700;
    final trackColor = isDark ? AppColors.darkSurfaceAlt : AppColors.neutral300;

    return _HomeGlassCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppGradients.aqua,
                  borderRadius: AppRadius.rMd,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  s.monthlyBudget,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5,
                      strokeCap: StrokeCap.round,
                      backgroundColor: trackColor,
                      valueColor: AlwaysStoppedAnimation(barColor),
                    ),
                    Center(
                      child: Text(
                        '$pct%',
                        style: AppType.caption.copyWith(
                          color: barColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            baht.format(spent),
            style: AppType.displayLarge.copyWith(
              color: overBudget
                  ? AppColors.danger
                  : isDark
                      ? AppColors.brand300
                      : AppColors.brand800,
              height: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${s.ofBudgetUsed('$pct')} · ${baht.format(_budget)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      isDark ? AppColors.darkTextMuted : AppColors.neutral800,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: trackColor,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
        ],
      ),
    );
  }
}
