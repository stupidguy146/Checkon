import 'dart:convert';
import 'package:flutter/material.dart';
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
import 'product_detail_screen.dart';
import 'items_screen.dart' show showAddProductFlow;

/// Master catalogue of products (the durable "what we own" list).
/// Search + category filter + recurring badge.
class ProductMasterScreen extends StatefulWidget {
  const ProductMasterScreen({super.key});

  @override
  State<ProductMasterScreen> createState() => _ProductMasterScreenState();
}

class _ProductMasterScreenState extends State<ProductMasterScreen> {
  ApiService? _api;
  Future<List<Product>>? _future;
  final _searchCtrl = TextEditingController();
  String _search = '';
  ItemCategory? _category; // null = all
  int _rev = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_api == null) {
      _api = ApiService(auth: AuthScope.of(context));
      _future = _api!.getProducts();
    }
    final rev = DataScope.watch(context);
    if (rev != _rev) {
      _rev = rev;
      _future = _api!.getProducts();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = _api!.getProducts();
    });
  }

  Future<void> _openAdd() async {
    final created = await showAddProductFlow(context);
    if (created) _reload();
  }

  Future<bool> _confirmDelete(Product p) async {
    final s = context.strings;
    final messenger = ScaffoldMessenger.of(context);
    final dataRefresh = DataScope.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: s.deleteProductConfirmTitle,
      message: s.deleteProductConfirmMessage(p.name),
      confirmLabel: s.delete,
      cancelLabel: s.cancel,
      icon: Icons.delete_outline_rounded,
      danger: true,
    );
    if (!confirmed) return false;
    try {
      await _api!.deleteProduct(p.productId);
      dataRefresh.bump();
      if (mounted) {
        AppSnackBar.show(messenger, s.productDeleted, SnackKind.success);
        _reload();
      }
      return true;
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

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: s.productMasterTitle,
            subtitle: s.appTitle,
            leading: HeaderIconButton(
              icon: Icons.chevron_left_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                      AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: s.searchProducts,
                      prefixIcon: const Icon(Icons.search_rounded),
                    ),
                    onChanged: (v) => setState(() => _search = v.trim()),
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
                          return ErrorView(
                              error: snap.error!, onRetry: _reload);
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
                            title: s.noProductsYet,
                            message: s.noProductsYetHint,
                            action: FilledButton.icon(
                              onPressed: () => _openAdd(),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: Text(s.addProductTitle),
                            ),
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
                              background:
                                  _SwipeDeleteBackground(label: s.delete),
                              child: _ProductCard(
                                product: p,
                                onTap: () async {
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
        ],
      ),
      floatingActionButton: FutureBuilder<List<Product>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.data?.isNotEmpty != true) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton(
            heroTag: 'fab_products',
            onPressed: _openAdd,
            child: const Icon(Icons.add_rounded),
          );
        },
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
