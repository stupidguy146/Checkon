import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_widgets.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/auth_scope.dart';
import '../state/data_refresh.dart';
import '../i18n/locale_scope.dart';
import 'product_detail_screen.dart';

/// "To buy" checklist — products marked `out` or `low`, grouped by urgency.
/// Selected products are recorded directly with their quantity and price.
class ToBuyScreen extends StatefulWidget {
  const ToBuyScreen({super.key});

  @override
  State<ToBuyScreen> createState() => _ToBuyScreenState();
}

class _ToBuyScreenState extends State<ToBuyScreen> {
  ApiService? _api;
  Future<List<Product>>? _future;
  final Set<String> _selectedIds = {};
  final Map<String, int> _quantities = {};
  final Map<String, double?> _unitPrices = {};
  bool _buyingSelected = false;
  int _rev = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_api == null) {
      _api = ApiService(auth: AuthScope.of(context));
      _future = _loadProductsToBuy();
    }
    final rev = DataScope.watch(context);
    if (rev != _rev) {
      _rev = rev;
      if (_api != null) {
        _future = _loadProductsToBuy();
      }
    }
  }

  void _reload() => setState(() {
        _future = _loadProductsToBuy();
      });

  Future<List<Product>> _loadProductsToBuy() async {
    final products = await _api!.getProductsToBuy();
    final productIds = products.map((product) => product.productId).toSet();
    _selectedIds.removeWhere((productId) => !productIds.contains(productId));
    final histories = await Future.wait(
      products.map((product) => _api!.getProductHistory(product.productId)),
    );
    for (var index = 0; index < products.length; index++) {
      final history = histories[index]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _unitPrices[products[index].productId] =
          history.isEmpty ? null : history.first.price;
    }
    return products;
  }

  Future<void> _refresh() async {
    _reload();
    await _future!;
  }

  void _setSelected(Product product, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(product.productId);
      } else {
        _selectedIds.remove(product.productId);
      }
    });
  }

  void _setAllSelected(List<Product> products, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.addAll(products.map((product) => product.productId));
      } else {
        _selectedIds.removeAll(products.map((product) => product.productId));
      }
    });
  }

  void _setQuantity(Product product, int quantity) {
    setState(() => _quantities[product.productId] = quantity);
  }

  Future<void> _buySelected(List<Product> products) async {
    if (_buyingSelected || products.isEmpty) return;

    final s = context.strings;
    final messenger = ScaffoldMessenger.of(context);
    final purchases = <({Product product, int quantity, double price})>[];
    for (final product in products) {
      final price = _unitPrices[product.productId];
      if (price == null || !price.isFinite || price < 0) {
        AppSnackBar.show(messenger, s.priceRequired, SnackKind.error);
        return;
      }
      purchases.add((
        product: product,
        quantity: _quantities[product.productId] ?? 1,
        price: price,
      ));
    }

    final dataRefresh = DataScope.of(context);
    setState(() => _buyingSelected = true);
    var purchased = 0;
    try {
      for (final purchase in purchases) {
        await _api!.createPurchase(purchase.product.productId, {
          'quantity': purchase.quantity,
          'price': purchase.price,
          'purchasedAt': DateTime.now().toIso8601String().substring(0, 10),
        });
        purchased++;
      }
      if (mounted) {
        AppSnackBar.show(
          messenger,
          s.purchaseBatchSaved(purchased),
          SnackKind.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(messenger, s.errorWith(e), SnackKind.error);
      }
    } finally {
      if (mounted) {
        if (purchased > 0) dataRefresh.bump();
        setState(() {
          _buyingSelected = false;
        });
      }
    }
  }

  Future<void> _openDetail(Product p) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          productId: p.productId,
          readOnly: true,
        ),
      ),
    );
    if (changed == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            GradientHeader(
              title: s.toBuyTitle,
              titleIcon: Icons.shopping_cart_rounded,
              subtitle: s.appTitle,
            ),
            Expanded(
              child: FutureBuilder<List<Product>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SkeletonList();
                  }
                  if (snap.hasError) {
                    return ErrorView(error: snap.error!, onRetry: _reload);
                  }
                  final products = snap.data ?? [];
                  if (products.isEmpty) {
                    return EmptyState(
                      icon: Icons.check_circle_outline_rounded,
                      title: s.toBuyEmpty,
                      message: s.toBuyEmptyHint,
                    );
                  }
                  final out = products
                      .where((p) => p.status == ProductStatus.out)
                      .toList();
                  final low = products
                      .where((p) => p.status == ProductStatus.low)
                      .toList();
                  final selectedProducts = products
                      .where((p) => _selectedIds.contains(p.productId))
                      .toList();
                  final allSelected =
                      selectedProducts.length == products.length;
                  final hasUnpricedSelection = selectedProducts.any(
                    (product) => _unitPrices[product.productId] == null,
                  );
                  final grandTotal = hasUnpricedSelection
                      ? null
                      : selectedProducts.fold<double>(
                          0,
                          (total, product) =>
                              total +
                              _unitPrices[product.productId]! *
                                  (_quantities[product.productId] ?? 1),
                        );
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                            children: [
                              InkWell(
                                borderRadius: AppRadius.rMd,
                                onTap: () => _setAllSelected(
                                  products,
                                  !allSelected,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.sm,
                                  ),
                                  child: Row(
                                    children: [
                                      _RoundedCheckbox(
                                        value: allSelected,
                                        onChanged: (value) =>
                                            _setAllSelected(products, value),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(s.selectAll),
                                    ],
                                  ),
                                ),
                              ),
                              if (out.isNotEmpty) ...[
                                _SectionLabel(
                                  label: '🔴 ${s.toBuyOutSection}',
                                  count: out.length,
                                ),
                                for (final p in out)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: AppSpacing.md),
                                    child: _ToBuyCard(
                                      product: p,
                                      checked:
                                          _selectedIds.contains(p.productId),
                                      quantity: _quantities[p.productId] ?? 1,
                                      unitPrice: _unitPrices[p.productId],
                                      onChanged: (value) =>
                                          _setSelected(p, value),
                                      onQuantityChanged: (value) =>
                                          _setQuantity(p, value),
                                      enabled: !_buyingSelected,
                                      onTap: () => _openDetail(p),
                                    ),
                                  ),
                              ],
                              if (low.isNotEmpty) ...[
                                _SectionLabel(
                                  label: '🟡 ${s.toBuyLowSection}',
                                  count: low.length,
                                ),
                                for (final p in low)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: AppSpacing.md),
                                    child: _ToBuyCard(
                                      product: p,
                                      checked:
                                          _selectedIds.contains(p.productId),
                                      quantity: _quantities[p.productId] ?? 1,
                                      unitPrice: _unitPrices[p.productId],
                                      onChanged: (value) =>
                                          _setSelected(p, value),
                                      onQuantityChanged: (value) =>
                                          _setQuantity(p, value),
                                      enabled: !_buyingSelected,
                                      onTap: () => _openDetail(p),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                        _SelectionBar(
                          count: _selectedIds.length,
                          grandTotal: grandTotal,
                          loading: _buyingSelected,
                          onBuy: () => _buySelected(selectedProducts),
                        ),
                      ],
                    ),
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

class _SectionLabel extends StatelessWidget {
  final String label;
  final int count;
  const _SectionLabel({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text('$label ($count)',
          style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _SelectionBar extends StatelessWidget {
  final int count;
  final double? grandTotal;
  final bool loading;
  final VoidCallback onBuy;
  const _SelectionBar({
    required this.count,
    required this.grandTotal,
    required this.loading,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final currency = NumberFormat.currency(
      locale: context.locale.lang,
      symbol: '฿',
      decimalDigits: 2,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        boxShadow: AppShadows.lg,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.selectedItems(count),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  grandTotal == null ? '—' : currency.format(grandTotal),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: loading || count == 0 ? null : onBuy,
                icon: loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.shopping_cart_checkout_rounded,
                        size: 18,
                      ),
                label: Text(s.buySelected(count)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToBuyCard extends StatelessWidget {
  final Product product;
  final bool checked;
  final int quantity;
  final double? unitPrice;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onTap;
  const _ToBuyCard({
    required this.product,
    required this.checked,
    required this.quantity,
    required this.unitPrice,
    required this.enabled,
    required this.onChanged,
    required this.onQuantityChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: context.locale.lang,
      symbol: '฿',
      decimalDigits: 2,
    );
    final total = unitPrice == null ? null : unitPrice! * quantity;
    final img = _decode(product.imageBase64);
    final expiryLabel = product.expiryDate == null
        ? null
        : context.strings.expireShort(
            DateFormat('d MMM yyyy', context.locale.lang)
                .format(DateTime.parse(product.expiryDate!)),
          );
    final subtitle = [
      if (product.sizeLabel.isNotEmpty) product.sizeLabel,
    ].join(' · ');
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _RoundedCheckbox(
                value: checked,
                enabled: enabled,
                onChanged: onChanged,
                height: 72,
              ),
              const SizedBox(width: AppSpacing.sm),
              Material(
                color: Colors.transparent,
                borderRadius: AppRadius.rMd,
                child: InkWell(
                  borderRadius: AppRadius.rMd,
                  onTap: onTap,
                  child: Container(
                    width: 72,
                    height: 72,
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
                            color: AppColors.brand500)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: SizedBox(
                  height: 72,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: onTap,
                                borderRadius: AppRadius.rSm,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.xxs,
                                  ),
                                  child: Text(
                                    product.name,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            total == null ? '—' : currency.format(total),
                            textAlign: TextAlign.end,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: expiryLabel == null
                    ? const SizedBox.shrink()
                    : Text(
                        expiryLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
              ),
              _QuantityStepper(
                quantity: quantity,
                enabled: enabled,
                onDecrement: () => onQuantityChanged(quantity - 1),
                onIncrement: () => onQuantityChanged(quantity + 1),
              ),
            ],
          ),
        ],
      ),
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

class _RoundedCheckbox extends StatelessWidget {
  final bool value;
  final bool enabled;
  final double height;
  final ValueChanged<bool> onChanged;

  const _RoundedCheckbox({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.rMd,
          onTap: enabled ? () => onChanged(!value) : null,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: value
                    ? AppColors.brand500
                    : Theme.of(context).colorScheme.surface,
                borderRadius: AppRadius.rSm,
                border: Border.all(
                  color: value
                      ? AppColors.brand500
                      : Theme.of(context).colorScheme.outline,
                  width: 1.8,
                ),
              ),
              child: value
                  ? const Icon(Icons.check_rounded,
                      size: 16, color: Colors.white)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final bool enabled;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  const _QuantityStepper({
    required this.quantity,
    required this.enabled,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperButton(
          icon: Icons.remove_rounded,
          enabled: enabled && quantity > 1,
          onTap: onDecrement,
        ),
        SizedBox(
          width: 44,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        _StepperButton(
          icon: Icons.add_rounded,
          enabled: enabled && quantity < 100000,
          onTap: onIncrement,
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = enabled
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.onSurface.withValues(alpha: 0.12);
    final foreground = enabled
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface.withValues(alpha: 0.38);
    return SizedBox(
      width: 44,
      height: 44,
      child: Tooltip(
        message: icon == Icons.add_rounded
            ? context.strings.increaseQuantity
            : context.strings.decreaseQuantity,
        child: Material(
          color: background,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: enabled ? onTap : null,
            customBorder: const CircleBorder(),
            child: Icon(icon, size: 21, color: foreground),
          ),
        ),
      ),
    );
  }
}
