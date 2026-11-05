import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/purchase.dart';
import '../services/api_service.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_widgets.dart';
import '../widgets/auth_scope.dart';
import '../state/data_refresh.dart';
import '../i18n/locale_scope.dart';

/// Monthly budget + summary (merged screen).
///
/// Shows, for a selectable month, the spend from purchases vs a locally-stored
/// budget target, plus purchase stats, category / buyer breakdowns, and the
/// list of purchases. Budget target is per-month-compared and stored in
/// shared_preferences (shared with the home budget card via the same key).
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

/// Everything the month view needs, fetched together.
class _MonthData {
  final MonthlySummary summary;
  final List<Purchase> purchases;
  final Map<String, Product> productsById;
  final List<MonthSpend> spendSeries; // last N months, oldest→newest
  _MonthData(this.summary, this.purchases, this.productsById, this.spendSeries);
}

class _BudgetScreenState extends State<BudgetScreen> {
  static const _kBudgetKey = 'app_budget';
  ApiService? _api;
  Future<_MonthData>? _future;
  double _budget = 3000;
  late DateTime _month; // first day of selected month
  late DateTime _chartEndMonth;
  int _rev = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _chartEndMonth = _month;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_api == null) {
      _api = ApiService(auth: AuthScope.of(context));
      _future = _load();
      _loadBudget();
    }
    final rev = DataScope.watch(context);
    if (rev != _rev) {
      _rev = rev;
      _future = _load();
      _loadBudget();
    }
  }

  Future<_MonthData> _load() async {
    final selectedMonth = _month;
    final chartEndMonth = _chartEndMonth;
    final key =
        '${selectedMonth.year.toString().padLeft(4, '0')}-${selectedMonth.month.toString().padLeft(2, '0')}';
    final results = await Future.wait([
      _api!.getMonthlySummary(key),
      _api!.getPurchasesByMonth(key),
      _api!.getProducts(),
    ]);
    final summary = results[0] as MonthlySummary;
    final purchases = results[1] as List<Purchase>;
    final products = results[2] as List<Product>;
    final spendSummaries = await Future.wait(
      List.generate(6, (index) {
        final month = DateTime(
          chartEndMonth.year,
          chartEndMonth.month - 5 + index,
        );
        final monthKey =
            '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
        return monthKey == key
            ? Future.value(summary)
            : _api!.getMonthlySummary(monthKey);
      }),
    );
    final spendSeries = spendSummaries
        .map(
            (month) => MonthSpend(month: month.month, amount: month.grandTotal))
        .toList();
    final byId = {for (final p in products) p.productId: p};
    return _MonthData(summary, purchases, byId, spendSeries);
  }

  Future<void> _loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final b = prefs.getDouble(_kBudgetKey);
    if (b != null && mounted) setState(() => _budget = b);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  /// Jump directly to a month (from tapping a bar in the chart).
  void _selectMonth(DateTime m) {
    final target = DateTime(m.year, m.month);
    if (target.year == _month.year && target.month == _month.month) return;
    setState(() {
      _month = target;
      final chartStartMonth =
          DateTime(_chartEndMonth.year, _chartEndMonth.month - 5);
      if (target.isBefore(chartStartMonth) || target.isAfter(_chartEndMonth)) {
        _chartEndMonth = target;
      }
      _future = _load();
    });
  }

  Future<void> _editBudget() async {
    final s = context.strings;
    final dataRefresh = DataScope.of(context);
    final ctrl = TextEditingController(text: _budget.toStringAsFixed(0));
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.setBudget),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: s.budgetField),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(s.save2)),
        ],
      ),
    );
    if (saved == true) {
      final v = double.tryParse(ctrl.text) ?? _budget;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kBudgetKey, v);
      if (mounted) setState(() => _budget = v);
      dataRefresh.bump(); // let the home budget card pick up the new budget
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final now = DateTime.now();

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            GradientHeader(
              title: s.budgetTitle,
              titleIcon: Icons.account_balance_wallet_rounded,
              subtitle: s.appTitle,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: MonthNavigator(
                month: _month,
                onChanged: _selectMonth,
                locale: context.locale.lang,
                firstMonth: DateTime(2020, 1),
                lastMonth: DateTime(now.year, now.month),
                prevTooltip: s.prevMonth,
                nextTooltip: s.nextMonth,
                pickerTitle: s.selectMonth,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _reload(),
                child: FutureBuilder<_MonthData>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const SkeletonList();
                    }
                    if (snap.hasError) {
                      return ErrorView(error: snap.error!, onRetry: _reload);
                    }
                    final data = snap.data!;
                    return _Body(
                      data: data,
                      budget: _budget,
                      selectedMonth: _month,
                      onSetBudget: _editBudget,
                      onSelectMonth: _selectMonth,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final _MonthData data;
  final double budget;
  final DateTime selectedMonth;
  final VoidCallback onSetBudget;
  final ValueChanged<DateTime> onSelectMonth;
  const _Body({
    required this.data,
    required this.budget,
    required this.selectedMonth,
    required this.onSetBudget,
    required this.onSelectMonth,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final baht = NumberFormat.currency(
        locale: context.locale.lang, symbol: '฿', decimalDigits: 0);
    final df = DateFormat('d MMM yyyy', context.locale.lang);
    final summary = data.summary;
    final pct = budget > 0
        ? (summary.grandTotal / budget * 100).clamp(0, 999).toDouble()
        : 0.0;
    // A past month is finished — setting/comparing a budget for it is
    // meaningless, so we only show the budget card for the current month.
    final now = DateTime.now();
    final isPast = selectedMonth.year < now.year ||
        (selectedMonth.year == now.year && selectedMonth.month < now.month);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 90),
      children: [
        if (isPast)
          _SpentTotalCard(spent: summary.grandTotal, baht: baht)
        else
          _BudgetCard(
            spent: summary.grandTotal,
            budget: budget,
            pct: pct,
            baht: baht,
            onSetBudget: onSetBudget,
          ),

        // monthly spend bar chart (purchase-based) — tap a bar to select it
        if (data.spendSeries.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(title: s.spendByMonth),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: _BarChart(
              months: data.spendSeries,
              locale: context.locale.lang,
              selectedMonth: selectedMonth,
              onSelectMonth: onSelectMonth,
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.lg),

        // purchase stats
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: s.totalPurchasesLabel,
                value: '${summary.totalPurchases}',
                icon: Icons.receipt_long_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _StatCard(
                label: s.totalQtyLabel,
                value: '${summary.totalQty}',
                icon: Icons.inventory_2_rounded,
              ),
            ),
          ],
        ),

        if (summary.byCategory.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(title: s.spendByCategory),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              children: [
                Center(
                  child: _PieChart(
                    slices: [
                      for (var i = 0; i < summary.byCategory.length; i++)
                        _Slice(summary.byCategory[i].amount, _sliceColor(i)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                for (var i = 0; i < summary.byCategory.length; i++)
                  _CategoryRow(
                    category: summary.byCategory[i].category,
                    amount: summary.byCategory[i].amount,
                    total: summary.grandTotal,
                    baht: baht,
                    color: _sliceColor(i),
                  ),
              ],
            ),
          ),
        ],

        if (summary.byBuyer.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(title: s.byBuyerTitle),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: _PieChart(
                    slices: [
                      for (var i = 0; i < summary.byBuyer.length; i++)
                        _Slice(summary.byBuyer[i].amount, _sliceColor(i)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                for (var i = 0; i < summary.byBuyer.length; i++)
                  _BreakdownRow(
                    label: summary.byBuyer[i].buyer.trim().isEmpty
                        ? s.unknownBuyer
                        : summary.byBuyer[i].buyer,
                    value: baht.format(summary.byBuyer[i].amount),
                    percent: summary.grandTotal > 0
                        ? summary.byBuyer[i].amount / summary.grandTotal * 100
                        : 0,
                    color: _sliceColor(i),
                  ),
              ],
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.lg),
        SectionHeader(title: s.purchasesThisMonth),
        const SizedBox(height: AppSpacing.sm),
        if (data.purchases.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: s.noPurchasesThisMonth,
            ),
          )
        else
          ...data.purchases.map((p) {
            final name = data.productsById[p.productId]?.name ?? '—';
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _PurchaseCard(
                name: name,
                purchase: p,
                baht: baht,
                dateText:
                    s.purchasedOn(df.format(DateTime.parse(p.purchasedAt))),
                qtyUnit: s.pieces,
              ),
            );
          }),
      ],
    );
  }
}

/// Read-only spend total shown for past months (no budget target / progress,
/// since setting a budget for a finished month is meaningless).
class _SpentTotalCard extends StatelessWidget {
  final double spent;
  final NumberFormat baht;
  const _SpentTotalCard({required this.spent, required this.baht});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.grandTotalLabel,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(baht.format(spent),
              style: AppType.displayLarge.copyWith(color: AppColors.brand600)),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final double spent;
  final double budget;
  final double pct;
  final NumberFormat baht;
  final VoidCallback onSetBudget;
  const _BudgetCard({
    required this.spent,
    required this.budget,
    required this.pct,
    required this.baht,
    required this.onSetBudget,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final over = pct > 100;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(s.grandTotalLabel,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              Material(
                color: AppColors.brand500.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: InkWell(
                  onTap: onSetBudget,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tune_rounded,
                            color: AppColors.brand600, size: 16),
                        const SizedBox(width: AppSpacing.xs),
                        Text(s.setBudget,
                            style: AppType.label
                                .copyWith(color: AppColors.brand600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(baht.format(spent),
              style: AppType.displayLarge.copyWith(
                  color: over ? AppColors.danger : AppColors.brand600)),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.neutral200,
              valueColor: AlwaysStoppedAnimation(
                  over ? AppColors.danger : AppColors.brand500),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${s.ofBudgetUsed(pct.toStringAsFixed(0))} · ${baht.format(budget)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Monthly spend bar chart (no chart library). Bars are tappable — tapping a
/// bar selects that month. The selected month's bar is highlighted.
class _BarChart extends StatelessWidget {
  final List<MonthSpend> months;
  final String locale;
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onSelectMonth;
  const _BarChart({
    required this.months,
    required this.locale,
    required this.selectedMonth,
    required this.onSelectMonth,
  });

  @override
  Widget build(BuildContext context) {
    final maxAmount =
        months.map((m) => m.amount).fold<double>(0, (a, b) => a > b ? a : b);
    final selKey =
        '${selectedMonth.year.toString().padLeft(4, '0')}-${selectedMonth.month.toString().padLeft(2, '0')}';
    return SizedBox(
      height: 168,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final m in months)
            Expanded(
              child: _Bar(
                amount: m.amount,
                maxAmount: maxAmount,
                label: _label(m.month),
                selected: m.month == selKey,
                amountLabel:
                    NumberFormat.compact(locale: locale).format(m.amount),
                onTap: () => onSelectMonth(_parse(m.month)),
              ),
            ),
        ],
      ),
    );
  }

  DateTime _parse(String yyyymm) {
    final p = yyyymm.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]));
  }

  String _label(String yyyymm) {
    final p = yyyymm.split('-');
    if (p.length < 2) return yyyymm;
    return DateFormat('MMM', locale)
        .format(DateTime(int.parse(p[0]), int.parse(p[1])));
  }
}

class _Bar extends StatelessWidget {
  final double amount;
  final double maxAmount;
  final String label;
  final String amountLabel;
  final bool selected;
  final VoidCallback onTap;
  const _Bar({
    required this.amount,
    required this.maxAmount,
    required this.label,
    required this.amountLabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final barHeight = maxAmount > 0 ? (amount / maxAmount) * 100 + 4 : 4.0;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rSm,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            amountLabel,
            style: AppType.caption.copyWith(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w400,
              color: selected ? AppColors.brand600 : null,
            ),
          ),
          const SizedBox(height: 4),
          FractionallySizedBox(
            widthFactor: selected ? 0.66 : 0.5,
            child: Container(
              height: barHeight,
              decoration: BoxDecoration(
                gradient: selected
                    ? (Theme.of(context).brightness == Brightness.dark
                        ? AppGradients.brandDark
                        : AppGradients.brand)
                    : null,
                color: selected ? null : AppColors.brand100,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.sm)),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppType.caption.copyWith(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w400,
              color: selected ? AppColors.brand600 : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Distinct, cycling palette for pie slices (brand + accent + semantic).
const List<Color> _sliceColors = [
  AppColors.brand500,
  AppColors.accent500,
  AppColors.success,
  AppColors.shouldBuy,
  AppColors.brand300,
  AppColors.warning,
  AppColors.danger,
  AppColors.neutral400,
];

Color _sliceColor(int i) => _sliceColors[i % _sliceColors.length];

/// One slice of a pie: a value and the color to draw it with.
class _Slice {
  final double value;
  final Color color;
  const _Slice(this.value, this.color);
}

/// Donut pie chart drawn with CustomPaint (no chart dependency).
class _PieChart extends StatelessWidget {
  final List<_Slice> slices;
  const _PieChart({required this.slices});

  @override
  Widget build(BuildContext context) {
    const size = 150.0;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PiePainter(
          slices: slices,
          gapColor: Theme.of(context).cardTheme.color ?? AppColors.neutral0,
        ),
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  final List<_Slice> slices;
  final Color gapColor;
  _PiePainter({required this.slices, required this.gapColor});

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (a, s) => a + s.value);
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.shortestSide / 2;

    if (total <= 0) {
      // nothing to show → draw a light ring so the area isn't empty
      final p = Paint()
        ..color = AppColors.neutral200
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, p);
    } else {
      var start = -math.pi / 2; // start at 12 o'clock
      for (final s in slices) {
        if (s.value <= 0) continue;
        final sweep = (s.value / total) * 2 * math.pi;
        final paint = Paint()
          ..color = s.color
          ..style = PaintingStyle.fill;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          start,
          sweep,
          true,
          paint,
        );
        start += sweep;
      }
    }

    // punch a hole in the middle → donut
    final hole = Paint()..color = gapColor;
    canvas.drawCircle(center, radius * 0.56, hole);
  }

  @override
  bool shouldRepaint(_PiePainter old) =>
      old.slices != slices || old.gapColor != gapColor;
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.brand500),
          const SizedBox(height: AppSpacing.sm),
          Text(value,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: AppType.caption.copyWith(color: AppColors.neutral600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  final double percent;
  final Color color;
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(label,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('${percent.toStringAsFixed(0)}%',
              style: AppType.caption.copyWith(color: AppColors.neutral500)),
          const SizedBox(width: AppSpacing.md),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String category;
  final double amount;
  final double total;
  final NumberFormat baht;
  final Color color;
  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.total,
    required this.baht,
    required this.color,
  });

  IconData get _icon {
    switch (category) {
      case 'laundry':
        return Icons.local_laundry_service_outlined;
      case 'kitchen':
        return Icons.kitchen_outlined;
      case 'bathroom':
        return Icons.bathtub_outlined;
      case 'food':
        return Icons.restaurant_outlined;
      case 'personal':
        return Icons.face_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final pct = total > 0 ? (amount / total * 100) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: AppRadius.rMd,
            ),
            child: Icon(_icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.categoryName(category),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: (pct / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.neutral200,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(baht.format(amount),
                  style:
                      AppType.titleMedium.copyWith(color: AppColors.brand600)),
              Text('${pct.toStringAsFixed(0)}%', style: AppType.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  final String name;
  final Purchase purchase;
  final NumberFormat baht;
  final String dateText;
  final String qtyUnit;
  const _PurchaseCard({
    required this.name,
    required this.purchase,
    required this.baht,
    required this.dateText,
    required this.qtyUnit,
  });

  @override
  Widget build(BuildContext context) {
    final meta = [
      '${purchase.quantity} $qtyUnit',
      if ((purchase.store ?? '').isNotEmpty) purchase.store!,
      dateText,
    ].join(' · ');
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(meta,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(baht.format(purchase.subtotal),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
