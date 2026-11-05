import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/household_item.dart' show categoryToString;
import '../models/product.dart';
import '../models/purchase.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_widgets.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/auth_scope.dart';
import '../state/data_refresh.dart';
import '../i18n/locale_scope.dart';
import 'add_product_screen.dart';

/// Bundle fetched for the detail view.
class _DetailData {
  final Product product;
  final List<Purchase> history;
  _DetailData(this.product, this.history);
}

/// Product master detail: info + stock-status actions + purchase history +
/// delete. Pops `true` when anything changed so the caller can refresh.
class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final bool readOnly;
  final String? removeFromMonth;
  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.readOnly = false,
    this.removeFromMonth,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ApiService? _api;
  Future<_DetailData>? _future;
  bool _changed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_api == null) {
      _api = ApiService(auth: AuthScope.of(context));
      _future = _load();
    }
  }

  Future<_DetailData> _load() async {
    final results = await Future.wait([
      _api!.getProduct(widget.productId),
      _api!.getProductHistory(widget.productId),
    ]);
    final history = results[1] as List<Purchase>
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return _DetailData(results[0] as Product, history);
  }

  void _reload() => setState(() {
        _future = _load();
      });

  Future<void> _setStatus(ProductStatus status) async {
    final s = context.strings;
    final messenger = ScaffoldMessenger.of(context);
    final dataRefresh = DataScope.of(context);
    try {
      final updated = await _api!
          .updateProductStatus(widget.productId, productStatusToString(status));
      try {
        await NotificationService.instance.syncProductStatusReminder(
          product: updated,
          strings: s,
        );
      } catch (error, stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'notifications',
            context: ErrorDescription(
              'while scheduling a product status reminder',
            ),
          ),
        );
      }
      _changed = true;
      dataRefresh.bump();
      if (mounted) {
        AppSnackBar.show(messenger, s.statusUpdated, SnackKind.success);
        _reload();
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(messenger, s.errorWith(e), SnackKind.error);
    }
  }

  Future<void> _edit(Product product) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddProductScreen(initialProduct: product),
      ),
    );
    if (updated == true && mounted) {
      _changed = true;
      _reload();
    }
  }

  Future<void> _delete(Product p) async {
    final s = context.strings;
    final messenger = ScaffoldMessenger.of(context);
    final dataRefresh = DataScope.of(context);
    final navigator = Navigator.of(context);
    final monthLabel = widget.removeFromMonth == null
        ? null
        : DateFormat('MMMM yyyy', context.locale.lang)
            .format(DateTime.parse('${widget.removeFromMonth!}-01'));
    final confirmed = await showConfirmDialog(
      context,
      title: widget.removeFromMonth == null
          ? s.deleteProductConfirmTitle
          : s.removeProductFromMonthTitle,
      message: widget.removeFromMonth == null
          ? s.deleteProductConfirmMessage(p.name)
          : s.removeProductFromMonthMessage(p.name, monthLabel!),
      confirmLabel: s.delete,
      cancelLabel: s.cancel,
      icon: Icons.delete_outline_rounded,
      danger: true,
    );
    if (!confirmed) return;
    try {
      if (widget.removeFromMonth != null) {
        await _api!.removeProductFromMonth(
          p.productId,
          widget.removeFromMonth!,
        );
      } else {
        await _api!.deleteProduct(p.productId);
        try {
          await NotificationService.instance.cancelProductStatusReminder(
            productId: p.productId,
          );
        } catch (error, stackTrace) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
              library: 'notifications',
              context: ErrorDescription(
                'while cancelling a product status reminder',
              ),
            ),
          );
        }
      }
      dataRefresh.bump();
      if (mounted) {
        AppSnackBar.show(
          messenger,
          widget.removeFromMonth == null
              ? s.productDeleted
              : s.productRemovedFromMonth,
          SnackKind.success,
        );
        navigator.pop(true);
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(messenger, s.errorWith(e), SnackKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        body: Column(
          children: [
            GradientHeader(
              title: s.productDetailTitle,
              subtitle: s.appTitle,
              leading: HeaderIconButton(
                icon: Icons.chevron_left_rounded,
                onTap: () => Navigator.of(context).pop(_changed),
              ),
            ),
            Expanded(
              child: FutureBuilder<_DetailData>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SkeletonList();
                  }
                  if (snap.hasError) {
                    return ErrorView(error: snap.error!, onRetry: _reload);
                  }
                  return _Body(
                    data: snap.data!,
                    readOnly: widget.readOnly,
                    onSetStatus: _setStatus,
                    onEdit: _edit,
                    onDelete: _delete,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class _Body extends StatelessWidget {
  final _DetailData data;
  final bool readOnly;
  final ValueChanged<ProductStatus> onSetStatus;
  final ValueChanged<Product> onEdit;
  final ValueChanged<Product> onDelete;
  const _Body({
    required this.data,
    required this.readOnly,
    required this.onSetStatus,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final baht = NumberFormat.currency(
        locale: context.locale.lang, symbol: '฿', decimalDigits: 0);
    final unitBaht = NumberFormat.currency(
        locale: context.locale.lang, symbol: '฿', decimalDigits: 2);
    final df = DateFormat('d MMM yyyy', context.locale.lang);
    final p = data.product;
    final img = _decode(p.imageBase64);
    final meta = [
      s.categoryName(categoryToString(p.category)),
      if (!readOnly && p.sizeLabel.isNotEmpty) p.sizeLabel,
    ].join(' · ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 32),
      children: [
        // Product identity and catalog attributes.
        AppCard(
          child: Row(
            children: [
              Container(
                width: readOnly ? 96 : 72,
                height: readOnly ? 96 : 72,
                decoration: BoxDecoration(
                  color: AppColors.brand100,
                  borderRadius: AppRadius.rMd,
                  image: img != null
                      ? DecorationImage(
                          image: MemoryImage(img), fit: BoxFit.cover)
                      : null,
                ),
                child: img == null
                    ? const Icon(Icons.inventory_2_outlined,
                        color: AppColors.brand500, size: 30)
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(meta, style: Theme.of(context).textTheme.bodyMedium),
                    if (!readOnly) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          StatusChip(
                            status: _stockStatusOf(p.status),
                            label: {
                              ProductStatus.inStock: s.productStatusInStock,
                              ProductStatus.low: s.productStatusLow,
                              ProductStatus.out: s.productStatusOut,
                            }[p.status]!,
                          ),
                          if (p.isRecurring) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.brand100,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.autorenew_rounded,
                                      size: 12, color: AppColors.brand600),
                                  const SizedBox(width: 2),
                                  Text(s.recurringBadge,
                                      style: AppType.caption.copyWith(
                                          color: AppColors.brand600,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        if (!readOnly) ...[
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(title: s.statusSection),
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              s.statusActionHint,
              style: AppType.caption.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _StatusButton(
                  label: s.markLowButton,
                  color: AppColors.statusLow,
                  foregroundColor: AppColors.warning,
                  selectedForeground: AppColors.statusLowForeground,
                  icon: Icons.warning_amber_rounded,
                  selected: p.status == ProductStatus.low,
                  onTap: () => onSetStatus(ProductStatus.low),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatusButton(
                  label: s.markOutButton,
                  color: AppColors.danger,
                  icon: Icons.inventory_2_outlined,
                  selected: p.status == ProductStatus.out,
                  onTap: () => onSetStatus(ProductStatus.out),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatusButton(
                  label: s.markInStockButton,
                  color: AppColors.success,
                  icon: Icons.inventory_rounded,
                  selected: p.status == ProductStatus.inStock,
                  onTap: () => onSetStatus(ProductStatus.inStock),
                ),
              ),
            ],
          ),
        ],

        if (readOnly) ...[
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.pricePerUnit,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  data.history.isEmpty
                      ? s.noPriceHistory
                      : unitBaht.format(data.history.first.price),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                if (p.sizeLabel.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(s.productSize,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(p.sizeLabel,
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ],
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.lg),
        SectionHeader(
          title: s.purchaseHistory,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (data.history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: s.noPurchaseHistory,
            ),
          )
        else
          ...data.history.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              df.format(DateTime.parse(h.purchasedAt)),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [
                                '${h.quantity} ${s.pieces}',
                                if ((h.store ?? '').isNotEmpty) h.store!,
                                if ((h.buyer ?? '').isNotEmpty) h.buyer!,
                              ].join(' · '),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Text(baht.format(h.subtotal),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              )),

        if (readOnly) ...[
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () => onEdit(p),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(s.editProductTitle),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => onDelete(p),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: Text(s.deleteItem),
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () => onDelete(p),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: Text(s.deleteItem),
          ),
        ],
      ],
    );
  }

  static Uint8List? _decode(String? b64) {
    if (b64 == null || b64.isEmpty) return null;
    try {
      return base64Decode(b64.contains(',') ? b64.split(',').last : b64);
    } catch (_) {
      return null;
    }
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color? foregroundColor;
  final Color selectedForeground;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _StatusButton({
    required this.label,
    required this.color,
    this.foregroundColor,
    this.selectedForeground = Colors.white,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color:
          selected ? color : theme.colorScheme.surface.withValues(alpha: 0.88),
      borderRadius: AppRadius.rMd,
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: AppRadius.rMd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.rMd,
            border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.55),
              width: selected ? 1.8 : 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.check_circle_rounded : icon,
                size: 20,
                color:
                    selected ? selectedForeground : (foregroundColor ?? color),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppType.label.copyWith(
                  color: selected
                      ? selectedForeground
                      : (foregroundColor ?? theme.colorScheme.onSurface),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
