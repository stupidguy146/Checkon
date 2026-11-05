import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/customer_service.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_widgets.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/auth_scope.dart';
import '../state/data_refresh.dart';
import '../i18n/locale_scope.dart';

/// Record a purchase for an existing product: pick a product from the master
/// list, then fill a short purchase form. Pops `true` when a purchase is saved.
class RecordPurchaseScreen extends StatefulWidget {
  /// When provided, skip the picker and go straight to the purchase form for
  /// this product (used by the To-buy "Buy" action).
  final Product? preselected;
  const RecordPurchaseScreen({super.key, this.preselected});

  @override
  State<RecordPurchaseScreen> createState() => _RecordPurchaseScreenState();
}

class _RecordPurchaseScreenState extends State<RecordPurchaseScreen> {
  ApiService? _api;
  Future<List<Product>>? _future;
  final _searchCtrl = TextEditingController();
  String _search = '';

  Product? _selected; // null = still picking

  // purchase form
  final _formKey = GlobalKey<FormState>();
  final _qty = TextEditingController(text: '1');
  final _price = TextEditingController();
  final _store = TextEditingController();
  final _buyer = TextEditingController();
  DateTime _purchaseDate = DateTime.now();
  bool _saving = false;
  bool _prefilledBuyer = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.preselected;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_api == null) {
      _api = ApiService(auth: AuthScope.of(context));
      _future = _api!.getProducts();
      if (_selected != null && !_prefilledBuyer) {
        _prefilledBuyer = true;
        _prefillBuyerName();
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _qty.dispose();
    _price.dispose();
    _store.dispose();
    _buyer.dispose();
    super.dispose();
  }

  Future<void> _prefillBuyerName() async {
    try {
      final profile =
          await CustomerService(auth: AuthScope.of(context)).getMyProfile();
      if (!mounted) return;
      final name =
          profile.fullName.isNotEmpty ? profile.fullName : profile.username;
      if (name.isNotEmpty && _buyer.text.trim().isEmpty) {
        setState(() => _buyer.text = name);
      }
    } catch (_) {
      /* leave buyer empty on failure */
    }
  }

  void _select(Product p) {
    setState(() => _selected = p);
    if (!_prefilledBuyer) {
      _prefilledBuyer = true;
      _prefillBuyerName();
    }
  }

  Future<void> _pickPurchaseDate() async {
    final picked = await showAdaptiveDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final s = context.strings;
    final messenger = ScaffoldMessenger.of(context);
    final dataRefresh = DataScope.of(context);
    final navigator = Navigator.of(context);
    final body = <String, dynamic>{
      'quantity': int.tryParse(_qty.text.trim()) ?? 1,
      'price': double.tryParse(_price.text.trim()) ?? 0,
      'store': _store.text.trim().isEmpty ? null : _store.text.trim(),
      'buyer': _buyer.text.trim().isEmpty ? null : _buyer.text.trim(),
      'purchasedAt': _purchaseDate.toIso8601String().substring(0, 10),
    };
    try {
      await _api!.createPurchase(_selected!.productId, body);
      dataRefresh.bump();
      if (!mounted) return;
      AppSnackBar.show(messenger, s.purchaseSaved, SnackKind.success);
      navigator.pop(true);
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(messenger, s.errorWith(e), SnackKind.error);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: s.recordPurchaseTitle,
            subtitle: _selected == null ? s.pickProduct : s.purchaseDetails,
            leading: HeaderIconButton(
              icon: Icons.chevron_left_rounded,
              onTap: () {
                // when on the form, "back" returns to the product picker
                if (_selected != null) {
                  setState(() => _selected = null);
                } else {
                  Navigator.of(context).maybePop();
                }
              },
            ),
          ),
          Expanded(
            child: _selected == null ? _buildPicker(s) : _buildForm(s),
          ),
        ],
      ),
    );
  }

  Widget _buildPicker(dynamic s) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: s.searchProducts,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
            onChanged: (v) => setState(() => _search = v.trim()),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Product>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SkeletonList();
              }
              if (snap.hasError) {
                return ErrorView(
                    error: snap.error!,
                    onRetry: () => setState(() {
                          _future = _api!.getProducts();
                        }));
              }
              var products = snap.data ?? [];
              if (_search.isNotEmpty) {
                final q = _search.toLowerCase();
                products = products
                    .where((p) => p.name.toLowerCase().contains(q))
                    .toList();
              }
              if (products.isEmpty) {
                return EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: s.noProductsYet,
                  message: s.noProductsYetHint,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, 32),
                itemCount: products.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, i) {
                  final p = products[i];
                  return _ProductPickTile(product: p, onTap: () => _select(p));
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildForm(dynamic s) {
    final df = DateFormat('d MMM yyyy', context.locale.lang);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // selected product summary + change
          AppCard(
            child: Row(
              children: [
                _ProductThumb(imageBase64: _selected!.imageBase64),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(_selected!.name,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                TextButton(
                  onPressed: () => setState(() => _selected = null),
                  child: Text(s.changeProduct),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _qty,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: s.quantity),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    if (n == null || n < 1) return s.positiveIntegerOnly;
                    return null;
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextFormField(
                  controller: _price,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: s.unitPrice),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return null;
                    if (double.tryParse(t) == null) return s.decimalNumberOnly;
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _store,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: s.storeLabel),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _buyer,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: s.buyerLabel),
          ),
          const SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: _pickPurchaseDate,
            borderRadius: AppRadius.rMd,
            child: InputDecorator(
              decoration: InputDecoration(labelText: s.purchaseDateLabel),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(df.format(_purchaseDate)),
                  const Icon(Icons.calendar_today_rounded, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : Text(s.save),
          ),
        ],
      ),
    );
  }
}

class _ProductPickTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  const _ProductPickTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (product.sizeLabel.isNotEmpty) product.sizeLabel,
    ].join(' · ');
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          _ProductThumb(imageBase64: product.imageBase64),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.neutral400),
        ],
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  final String? imageBase64;
  const _ProductThumb({required this.imageBase64});

  @override
  Widget build(BuildContext context) {
    final img = _decode(imageBase64);
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.brand100,
        borderRadius: AppRadius.rMd,
        image: img != null
            ? DecorationImage(image: MemoryImage(img), fit: BoxFit.cover)
            : null,
      ),
      child: img == null
          ? const Icon(Icons.inventory_2_outlined, color: AppColors.brand500)
          : null,
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
