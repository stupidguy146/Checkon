import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/household_item.dart' show ItemCategory, categoryToString;
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/product_lookup_service.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_widgets.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/auth_scope.dart';
import '../state/data_refresh.dart';
import '../i18n/locale_scope.dart';
import 'barcode_scanner_screen.dart';
import 'add_edit_item_screen.dart' show categoryIcon;

/// Create a new Product (master) with an optional "first purchase" section.
/// When [autoScan] is true, the barcode scanner opens automatically on entry.
/// Returns `true` via Navigator.pop when a product was created.
class AddProductScreen extends StatefulWidget {
  final bool autoScan;
  final Product? initialProduct;
  const AddProductScreen({
    super.key,
    this.autoScan = false,
    this.initialProduct,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  ApiService? _api;

  // product fields
  final _name = TextEditingController();
  final _size = TextEditingController();
  final _unit = TextEditingController();
  ItemCategory _category = ItemCategory.other;
  bool _recurring = false;
  static const _commonSizeUnits = [
    'มล.',
    'ลิตร',
    'มก.',
    'กรัม',
    'กก.',
    'ชิ้น',
    'แพ็ค',
    'ขวด',
    'กระป๋อง',
    'หลอด',
    'กล่อง',
    'ถุง',
    'ฟอง',
    'แผ่น',
  ];
  final _recurringDays = TextEditingController();

  // first purchase (optional)
  bool _addPurchase = false;
  final _qty = TextEditingController(text: '1');
  final _price = TextEditingController();
  final _store = TextEditingController();
  final _buyer = TextEditingController();
  DateTime _purchaseDate = DateTime.now();

  bool _saving = false;

  // barcode scan / lookup
  final _productLookup = ProductLookupService();
  String? _image; // data URL from the looked-up product image
  bool _lookingUp = false;
  bool _didAutoScan = false;

  @override
  void initState() {
    super.initState();
    final product = widget.initialProduct;
    if (product != null) {
      _name.text = product.name;
      _size.text = product.size ?? '';
      _unit.text = product.unit ?? '';
      _category = product.category;
      _recurring = product.isRecurring;
      _recurringDays.text = product.recurringDaysManual?.toString() ?? '';
      _image = product.imageBase64;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _api ??= ApiService(auth: AuthScope.of(context));
    if (widget.autoScan && !_didAutoScan) {
      _didAutoScan = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scanBarcode());
    }
  }

  @override
  void dispose() {
    _productLookup.close();
    _name.dispose();
    _size.dispose();
    _unit.dispose();
    _recurringDays.dispose();
    _qty.dispose();
    _price.dispose();
    _store.dispose();
    _buyer.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (barcode == null || !mounted) return;
    setState(() => _lookingUp = true);
    final s = context.strings;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final product = await _productLookup.lookup(barcode);
      if (!mounted) return;
      if (product == null) {
        AppSnackBar.show(messenger, s.barcodeLookupNotFound, SnackKind.info);
        return;
      }
      setState(() {
        _name.text = product.displayName;
        if (product.size != null) _size.text = product.size!;
        if (product.unit != null) _unit.text = product.unit!;
        if (product.category != null) _category = product.category!;
        if (product.store != null && product.store!.isNotEmpty) {
          _store.text = product.store!;
        }
      });
      // fetch the product image in the background and fill it in when ready
      if (product.imageUrl != null && _image == null) {
        final dataUrl =
            await _productLookup.fetchImageAsDataUrl(product.imageUrl!);
        if (mounted && dataUrl != null && _image == null) {
          setState(() => _image = dataUrl);
        }
      }
      AppSnackBar.show(messenger, s.barcodeLookupSuccess, SnackKind.success);
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(messenger, s.errorWith(e), SnackKind.error);
      }
    } finally {
      if (mounted) setState(() => _lookingUp = false);
    }
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    setState(() => _image = 'data:$mime;base64,${base64Encode(bytes)}');
  }

  void _removeImage() => setState(() => _image = null);

  /// Decode the current [_image] data URL to bytes for preview (null if unset).
  Uint8List? get _imageBytes {
    final b64 = _image;
    if (b64 == null || b64.isEmpty) return null;
    try {
      return base64Decode(b64.contains(',') ? b64.split(',').last : b64);
    } catch (_) {
      return null;
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

    final recurringDays = int.tryParse(_recurringDays.text.trim());
    final productBody = <String, dynamic>{
      'name': _name.text.trim(),
      'category': categoryToString(_category),
      'size': _size.text.trim().isEmpty ? null : _size.text.trim(),
      'unit': _unit.text.trim().isEmpty ? null : _unit.text.trim(),
      'imageBase64': _image,
      'isRecurring': _recurring,
      'recurringDaysManual': _recurring ? recurringDays : null,
    };

    // Optionally attach the first purchase so the backend records it in one go.
    if (_addPurchase) {
      productBody['initialPurchase'] = <String, dynamic>{
        'quantity': int.tryParse(_qty.text.trim()) ?? 1,
        'price': double.tryParse(_price.text.trim()) ?? 0,
        'store': _store.text.trim().isEmpty ? null : _store.text.trim(),
        'buyer': _buyer.text.trim().isEmpty ? null : _buyer.text.trim(),
        'purchasedAt': _purchaseDate.toIso8601String().substring(0, 10),
      };
    }

    try {
      final existingProduct = widget.initialProduct;
      if (existingProduct != null) {
        await _api!.updateProduct(existingProduct.productId, productBody);
      } else {
        await _api!.createProduct(productBody);
      }
      dataRefresh.bump();
      if (!mounted) return;
      AppSnackBar.show(
        messenger,
        widget.initialProduct == null ? s.productSaved : s.productUpdated,
        SnackKind.success,
      );
      navigator.pop(true);
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(messenger, s.errorWith(e), SnackKind.error);
        setState(() => _saving = false);
      }
    }
  }

  List<String> get _sizeUnitOptions {
    final options = [..._commonSizeUnits];
    final current = _unit.text.trim();
    if (current.isNotEmpty && !options.contains(current)) {
      options.insert(0, current);
    }
    return options;
  }

  String? get _selectedSizeUnit {
    final unit = _unit.text.trim();
    return unit.isEmpty ? null : unit;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final df = DateFormat('d MMM yyyy', context.locale.lang);

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: widget.initialProduct == null
                ? s.addProductTitle
                : s.editProductTitle,
            subtitle: s.productMasterTitle,
            leading: HeaderIconButton(
              icon: Icons.chevron_left_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _SectionLabel(s.productInfoSection),
                  const SizedBox(height: AppSpacing.md),
                  // product image: tap to pick/change from gallery (also auto-filled
                  // from a barcode scan). Remove button appears when set.
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.brand100,
                              borderRadius: AppRadius.rLg,
                              image: _imageBytes != null
                                  ? DecorationImage(
                                      image: MemoryImage(_imageBytes!),
                                      fit: BoxFit.cover)
                                  : null,
                            ),
                            child: _imageBytes == null
                                ? const Icon(Icons.add_a_photo_outlined,
                                    color: AppColors.brand500, size: 30)
                                : null,
                          ),
                        ),
                        if (_imageBytes != null)
                          TextButton.icon(
                            onPressed: _removeImage,
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18),
                            label: Text(s.removePhoto),
                          )
                        else
                          TextButton(
                            onPressed: _pickImage,
                            child: Text(s.changePhoto),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (widget.initialProduct == null)
                    OutlinedButton.icon(
                      onPressed: _lookingUp ? null : _scanBarcode,
                      icon: _lookingUp
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.2),
                            )
                          : const Icon(Icons.qr_code_scanner_rounded, size: 20),
                      label: Text(s.scanBarcode),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(labelText: s.itemName),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? s.enterProductName
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AdaptiveDropdownFormField<ItemCategory>(
                    initialValue: _category,
                    decoration: InputDecoration(
                      labelText: s.categoryLabel,
                      prefixIcon: Icon(categoryIcon(_category)),
                    ),
                    dropdownColor: Theme.of(context).cardTheme.color,
                    borderRadius: AppRadius.rMd,
                    // closed field shows the label only — the category icon is
                    // already the prefixIcon (avoid showing two icons).
                    selectedItemBuilder: (context) => ItemCategory.values
                        .map((c) => Align(
                              alignment: Alignment.centerLeft,
                              child: Text(s.categoryName(categoryToString(c))),
                            ))
                        .toList(),
                    items: [
                      for (final c in ItemCategory.values)
                        DropdownMenuItem(
                          value: c,
                          child: Row(
                            children: [
                              Icon(categoryIcon(c),
                                  size: 20, color: AppColors.brand500),
                              const SizedBox(width: AppSpacing.md),
                              Text(s.categoryName(categoryToString(c))),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (v) =>
                        setState(() => _category = v ?? ItemCategory.other),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _size,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(labelText: s.sizeLabel),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AdaptiveDropdownFormField<String>(
                          initialValue: _selectedSizeUnit,
                          decoration:
                              InputDecoration(labelText: s.unitFieldLabel),
                          dropdownColor: Theme.of(context).cardTheme.color,
                          borderRadius: AppRadius.rMd,
                          items: [
                            for (final unit in _sizeUnitOptions)
                              DropdownMenuItem(
                                value: unit,
                                child: Text(unit),
                              ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _unit.text = value ?? '';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _recurring,
                    onChanged: (v) => setState(() => _recurring = v),
                    title: Text(s.recurringLabel,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  if (_recurring) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _recurringDays,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: s.recurringDaysLabel,
                        hintText: s.recurringDaysHint,
                        suffixText: s.daysUnit,
                      ),
                      validator: (v) {
                        if (!_recurring) return null;
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return null; // manual cycle is optional
                        final n = int.tryParse(t);
                        if (n == null || n < 1 || n > 3650) {
                          return s.recurringDaysInvalid;
                        }

                        return null;
                      },
                    ),
                  ],

                  if (widget.initialProduct == null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _SectionLabel(s.firstPurchaseSection),
                    const SizedBox(height: AppSpacing.xs),
                    Text(s.firstPurchaseHint,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: AppSpacing.sm),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _addPurchase,
                      onChanged: (v) => setState(() => _addPurchase = v),
                      title: Text(s.firstPurchaseSection,
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                  ],
                  if (widget.initialProduct == null && _addPurchase) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _qty,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(labelText: s.quantity),
                            validator: (v) {
                              if (!_addPurchase) return null;
                              final n = int.tryParse((v ?? '').trim());
                              if (n == null || n < 1) {
                                return s.positiveIntegerOnly;
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: TextFormField(
                            controller: _price,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(labelText: s.unitPrice),
                            validator: (v) {
                              if (!_addPurchase) return null;
                              final t = (v ?? '').trim();
                              if (t.isEmpty) return null;
                              if (double.tryParse(t) == null) {
                                return s.decimalNumberOnly;
                              }
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
                        decoration:
                            InputDecoration(labelText: s.purchaseDateLabel),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(df.format(_purchaseDate)),
                            const Icon(Icons.calendar_today_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : Text(widget.initialProduct == null
                            ? s.save
                            : s.saveChanges),
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppType.label.copyWith(
        color: AppColors.brand600,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
