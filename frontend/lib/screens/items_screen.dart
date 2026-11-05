import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/household_item.dart' show ItemCategory, categoryToString;
import '../models/product.dart';
import '../services/api_service.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_widgets.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/auth_scope.dart';
import '../state/data_refresh.dart';
import '../i18n/locale_scope.dart';
import '../i18n/app_strings.dart';
import 'add_product_screen.dart';
import 'record_purchase_screen.dart';
import 'product_detail_screen.dart';

/// Two-step add flow for the Items tab:
///   1) choose: create a new product master / record a purchase for existing
///   2a) if new: choose scan barcode / manual entry → AddProductScreen
///   2b) if existing: RecordPurchaseScreen (pick product → purchase form)
/// Returns true if anything was created/recorded (so the caller can refresh).
Future<bool> showAddProductFlow(BuildContext context) async {
  final choice = await _showAddSheet(
    context,
    title: context.strings.addFlowTitle,
    options: [
      _AddOption(
        value: 'new',
        icon: Icons.add_box_outlined,
        title: context.strings.addNewProductOption,
        subtitle: context.strings.addNewProductOptionHint,
      ),
      _AddOption(
        value: 'existing',
        icon: Icons.receipt_long_outlined,
        title: context.strings.recordPurchaseOption,
        subtitle: context.strings.recordPurchaseOptionHint,
      ),
    ],
  );
  if (choice == null || !context.mounted) return false;

  if (choice == 'existing') {
    final done = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RecordPurchaseScreen()),
    );
    return done == true;
  }

  // new product → choose scan vs manual
  final mode = await _showAddSheet(
    context,
    title: context.strings.createProductHow,
    options: [
      _AddOption(
        value: 'scan',
        icon: Icons.qr_code_scanner_rounded,
        title: context.strings.scanBarcodeOption,
        subtitle: context.strings.scanBarcodeOptionHint,
      ),
      _AddOption(
        value: 'manual',
        icon: Icons.edit_note_rounded,
        title: context.strings.manualEntryOption,
        subtitle: context.strings.manualEntryOptionHint,
      ),
    ],
  );
  if (mode == null || !context.mounted) return false;
  final created = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => AddProductScreen(autoScan: mode == 'scan'),
    ),
  );
  return created == true;
}

class _AddOption {
  final String value;
  final IconData icon;
  final String title;
  final String subtitle;
  const _AddOption({
    required this.value,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

Future<String?> _showAddSheet(
  BuildContext context, {
  required String title,
  required List<_AddOption> options,
}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    backgroundColor: Theme.of(context).cardTheme.color,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppType.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            for (int i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.md),
              _AddChoiceTile(
                icon: options[i].icon,
                title: options[i].title,
                subtitle: options[i].subtitle,
                onTap: () => Navigator.pop(sheetContext, options[i].value),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _AddChoiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _AddChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rLg,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: AppRadius.rLg,
          border: Border.all(color: AppColors.neutral300),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.brand100,
                borderRadius: AppRadius.rMd,
              ),
              child: Icon(icon, color: AppColors.brand500, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppType.bodyMedium
                          .copyWith(color: AppColors.neutral500)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.neutral400),
          ],
        ),
      ),
    );
  }
}

/// Items screen, viewed per month: shows products "in use" during the selected
/// month — bought that month, or bought earlier and still not marked out
/// (carried over). Month is selectable (prev / next, no future months).
class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  ApiService? _api;
  Future<List<Product>>? _future;
  final _searchCtrl = TextEditingController();
  String _search = '';
  ItemCategory? _category; // null = all
  late DateTime _month; // first day of selected month
  int _rev = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_api == null) {
      _api = ApiService(auth: AuthScope.of(context));
      _future = _load();
    }
    final rev = DataScope.watch(context);
    if (rev != _rev) {
      _rev = rev;
      if (_api != null) _future = _load();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _monthKey =>
      '${_month.year.toString().padLeft(4, '0')}-${_month.month.toString().padLeft(2, '0')}';

  Future<List<Product>> _load() => _api!.getProductsByMonth(_monthKey);

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<bool> _confirmDelete(Product p) async {
    final s = context.strings;
    final messenger = ScaffoldMessenger.of(context);
    final dataRefresh = DataScope.of(context);
    final monthLabel =
        DateFormat('MMMM yyyy', context.locale.lang).format(_month);
    final confirmed = await showConfirmDialog(
      context,
      title: s.removeProductFromMonthTitle,
      message: s.removeProductFromMonthMessage(p.name, monthLabel),
      confirmLabel: s.delete,
      cancelLabel: s.cancel,
      icon: Icons.delete_outline_rounded,
      danger: true,
    );
    if (!confirmed) return false;
    try {
      await _api!.removeProductFromMonth(p.productId, _monthKey);
      dataRefresh.bump();
      if (mounted) {
        AppSnackBar.show(
          messenger,
          s.productRemovedFromMonth,
          SnackKind.success,
        );
        _reload();
      }
      return false;
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(messenger, s.errorWith(e), SnackKind.error);
      }
      return false;
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
              title: s.itemsTitle,
              titleIcon: Icons.inventory_2_rounded,
              subtitle: s.appTitle,
            ),
            // month navigator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: MonthNavigator(
                month: _month,
                locale: context.locale.lang,
                firstMonth: DateTime(2020, 1),
                lastMonth: DateTime(now.year, now.month),
                prevTooltip: s.prevMonth,
                nextTooltip: s.nextMonth,
                pickerTitle: s.selectMonth,
                onChanged: (m) => setState(() {
                  _month = DateTime(m.year, m.month);
                  _future = _load();
                }),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: s.searchItems,
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
                onChanged: (v) => setState(() => _search = v.trim()),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // category filter chips
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  _CatChip(
                    label: s.categoryAll,
                    selected: _category == null,
                    onTap: () => setState(() => _category = null),
                  ),
                  for (final c in ItemCategory.values)
                    _CatChip(
                      label: s.categoryName(categoryToString(c)),
                      selected: _category == c,
                      onTap: () => setState(() => _category = c),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _reload(),
                child: FutureBuilder<List<Product>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const SkeletonList();
                    }
                    if (snap.hasError) {
                      return ErrorView(error: snap.error!, onRetry: _reload);
                    }
                    var products = snap.data ?? [];
                    final hasAny = products.isNotEmpty;
                    if (_category != null) {
                      products = products
                          .where((p) => p.category == _category)
                          .toList();
                    }
                    if (_search.isNotEmpty) {
                      final q = _search.toLowerCase();
                      products = products
                          .where((p) => p.name.toLowerCase().contains(q))
                          .toList();
                    }
                    if (products.isEmpty) {
                      if (hasAny) {
                        return EmptyState(
                          icon: Icons.search_off_rounded,
                          title: s.noMatchingProducts,
                          message: s.noMatchingItemsHint,
                          action: FilledButton(
                            onPressed: () => setState(() {
                              _search = '';
                              _searchCtrl.clear();
                              _category = null;
                            }),
                            child: Text(s.clearFilters),
                          ),
                        );
                      }
                      return EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: s.noItemsThisMonth,
                        message: s.noItemsThisMonthHint,
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, 0, AppSpacing.lg, 90),
                      itemCount: products.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, i) {
                        final p = products[i];
                        return Dismissible(
                          key: ValueKey(p.productId),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            await _confirmDelete(p);
                            return false;
                          },
                          background: _SwipeDeleteBackground(label: s.delete),
                          child: _ProductCard(
                            product: p,
                            onTap: () async {
                              final changed = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(
                                    productId: p.productId,
                                    removeFromMonth: _monthKey,
                                  ),
                                ),
                              );
                              if (changed == true) _reload();
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_items',
        onPressed: () async {
          final changed = await showAddProductFlow(context);
          if (changed) _reload();
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

/// Map the user-driven product status to the shared StockStatus chip.
StockStatus _stockStatusOf(ProductStatus s) {
  switch (s) {
    case ProductStatus.inStock:
      return StockStatus.normal;
    case ProductStatus.low:
      return StockStatus.low;
    case ProductStatus.out:
      return StockStatus.out;
  }
}

String _statusLabel(AppStrings s, ProductStatus st) {
  switch (st) {
    case ProductStatus.inStock:
      return s.productStatusInStock;
    case ProductStatus.low:
      return s.productStatusLow;
    case ProductStatus.out:
      return s.productStatusOut;
  }
}

class _SwipeDeleteBackground extends StatelessWidget {
  final String label;
  const _SwipeDeleteBackground({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: AppRadius.rLg,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppType.label.copyWith(color: Colors.white)),
          const SizedBox(width: AppSpacing.sm),
          const Icon(Icons.delete_outline_rounded, color: Colors.white),
        ],
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CatChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Material(
        color:
            selected ? AppColors.brand500 : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: selected ? null : AppShadows.sm,
            ),
            child: Text(
              label,
              style: AppType.label.copyWith(
                color: selected ? Colors.white : AppColors.neutral600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final img = _decode(product.imageBase64);
    final subtitle = [
      if (product.sizeLabel.isNotEmpty) product.sizeLabel,
    ].join(' · ');
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.brand100,
              borderRadius: AppRadius.rMd,
              image: img != null
                  ? DecorationImage(image: MemoryImage(img), fit: BoxFit.cover)
                  : null,
            ),
            child: img == null
                ? const Icon(Icons.inventory_2_outlined,
                    color: AppColors.brand500)
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(product.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (product.isRecurring) ...[
                      const SizedBox(width: AppSpacing.sm),
                      _RecurringBadge(label: s.recurringBadge),
                    ],
                  ],
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusChip(
            status: _stockStatusOf(product.status),
            label: _statusLabel(s, product.status),
          ),
        ],
      ),
    );
  }

  static dynamic _decode(String? b64) {
    if (b64 == null || b64.isEmpty) return null;
    try {
      final s = b64.contains(',') ? b64.split(',').last : b64;
      return base64Decode(s);
    } catch (_) {
      return null;
    }
  }
}

class _RecurringBadge extends StatelessWidget {
  final String label;
  const _RecurringBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.brand100,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.autorenew_rounded,
              size: 12, color: AppColors.brand600),
          const SizedBox(width: 2),
          Text(
            label,
            style: AppType.caption.copyWith(
              color: AppColors.brand600,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
