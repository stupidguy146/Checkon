import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/household_item.dart';
import '../models/api_error.dart';
import '../services/api_service.dart';
import '../services/customer_service.dart';
import '../services/product_lookup_service.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_widgets.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/auth_scope.dart';
import '../state/data_refresh.dart';

import '../i18n/locale_scope.dart';
import 'barcode_scanner_screen.dart';
import '../validators/item_form_validators.dart';

/// Icon representing each item category (used in the category selector).
IconData categoryIcon(ItemCategory c) {
  switch (c) {
    case ItemCategory.laundry:
      return Icons.local_laundry_service_rounded;
    case ItemCategory.kitchen:
      return Icons.restaurant_rounded;
    case ItemCategory.bathroom:
      return Icons.bathtub_rounded;
    case ItemCategory.food:
      return Icons.fastfood_rounded;
    case ItemCategory.personal:
      return Icons.face_retouching_natural_rounded;
    case ItemCategory.other:
      return Icons.category_rounded;
  }
}

/// Shows a bottom sheet letting the user choose how to add an item — scan a
/// barcode or enter manually — then opens the add form accordingly.
/// Returns true if an item was created.
Future<bool> showAddItemFlow(BuildContext context) async {
  final s = context.strings;
  final mode = await showModalBottomSheet<String>(
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
            Text(s.addItemHow, style: AppType.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            _AddChoiceTile(
              icon: Icons.qr_code_scanner_rounded,
              title: s.scanBarcodeOption,
              subtitle: s.scanBarcodeOptionHint,
              onTap: () => Navigator.pop(sheetContext, 'scan'),
            ),
            const SizedBox(height: AppSpacing.md),
            _AddChoiceTile(
              icon: Icons.edit_note_rounded,
              title: s.manualEntryOption,
              subtitle: s.manualEntryOptionHint,
              onTap: () => Navigator.pop(sheetContext, 'manual'),
            ),
          ],
        ),
      ),
    ),
  );
  if (mode == null || !context.mounted) return false;
  final created = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => AddEditItemScreen(autoScan: mode == 'scan'),
    ),
  );
  return created == true;
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

/// Add or edit a household item using the Checkon design system.
class AddEditItemScreen extends StatefulWidget {
  final HouseholdItem? existing;

  /// When true (add mode), open the barcode scanner automatically on entry.
  final bool autoScan;
  const AddEditItemScreen({super.key, this.existing, this.autoScan = false});

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _size;
  late final TextEditingController _unit;
  late final TextEditingController _qty;
  late final TextEditingController _price;
  late final TextEditingController _store;
  late final TextEditingController _buyer;
  late final TextEditingController _recurringDays;

  ApiService? _api;
  ItemCategory _category = ItemCategory.other;
  DateTime? _purchaseDate;
  DateTime? _expiryDate;
  String? _image;
  bool _recurring = false;
  bool _saving = false;
  bool _lookingUpBarcode = false;
  bool _didAutoScan = false;
  bool _prefilledBuyer = false;
  String? _scannedBarcode;
  final _productLookup = ProductLookupService();

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _size = TextEditingController(text: e?.size ?? '');
    _unit = TextEditingController(text: e?.unit ?? '');
    _qty = TextEditingController(text: '${e?.quantity ?? 1}');
    // price: keep the existing value when editing; leave blank for new items
    // so the user enters it themselves.
    _price = TextEditingController(text: _isEdit ? '${e!.price}' : '');
    _store = TextEditingController(text: e?.store ?? '');
    _buyer = TextEditingController(text: e?.buyer ?? '');
    _category = e?.category ?? ItemCategory.other;
    _image = e?.imageBase64;
    _recurring = e?.notifyRecurring ?? false;
    _recurringDays = TextEditingController(
        text: e?.recurringDays != null ? '${e!.recurringDays}' : '');
    if (e?.purchaseDate != null) {
      _purchaseDate = DateTime.tryParse(e!.purchaseDate!);
    } else if (!_isEdit) {
      // new item: default the purchase date to today
      _purchaseDate = DateTime.now();
    }
    if (e?.expiryDate != null) _expiryDate = DateTime.tryParse(e!.expiryDate!);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _api ??= ApiService(auth: AuthScope.of(context));

    // New item: default the buyer to the signed-in user's name, and (if asked)
    // open the scanner automatically. Both run once.
    if (!_isEdit) {
      if (!_prefilledBuyer && _buyer.text.trim().isEmpty) {
        _prefilledBuyer = true;
        _prefillBuyerName();
      }
      if (widget.autoScan && !_didAutoScan) {
        _didAutoScan = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _scanBarcode());
      }
    }
  }

  /// Fetch the signed-in user's profile and default the buyer field to their
  /// full name (falls back to username). Silent on failure.
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

  @override
  void dispose() {
    _productLookup.close();
    for (final c in [
      _name,
      _size,
      _unit,
      _qty,
      _price,
      _store,
      _buyer,
      _recurringDays
    ]) {
      c.dispose();
    }
    super.dispose();
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

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (barcode == null || !mounted) return;

    setState(() {
      _scannedBarcode = barcode;
      _lookingUpBarcode = true;
    });
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
        // default the purchase date to today if not already set
        _purchaseDate ??= DateTime.now();
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
      if (mounted) setState(() => _lookingUpBarcode = false);
    }
  }

  /// Preview of the auto-computed expiry date for a recurring item: shown only
  /// when the user ticked "recurring", entered a cycle, and has NOT set their
  /// own expiry date (their value always wins). Returns a formatted date, or
  /// null when no preview should show.
  String? get _recurringPreview {
    if (!_recurring) return null;
    if (_expiryDate != null) return null; // user's own expiry wins
    final days = int.tryParse(_recurringDays.text.trim());
    if (days == null || days < 1) return null;
    final base = _purchaseDate ?? DateTime.now();
    final computed = base.add(Duration(days: days));
    return DateFormat('d MMM yyyy', context.locale.lang).format(computed);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final recurringDays = int.tryParse(_recurringDays.text.trim());
    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'category': categoryToString(_category),
      'size': _size.text.trim().isEmpty ? null : _size.text.trim(),
      'unit': _unit.text.trim().isEmpty ? null : _unit.text.trim(),
      'quantity': int.tryParse(_qty.text) ?? 1,
      'price': double.tryParse(_price.text) ?? 0,
      'store': _store.text.trim().isEmpty ? null : _store.text.trim(),
      'buyer': _buyer.text.trim().isEmpty ? null : _buyer.text.trim(),
      'purchaseDate': _purchaseDate?.toIso8601String().substring(0, 10),
      'expiryDate': _expiryDate?.toIso8601String().substring(0, 10),
      'imageBase64': _image,
      'notifyRecurring': _recurring,
      'recurringDays': _recurring ? recurringDays : null,
    };
    final messenger = ScaffoldMessenger.of(context);
    final s = context.strings;
    final dataRefresh = DataScope.of(context);
    try {
      if (_isEdit) {
        await _api!.updateItem(widget.existing!.itemId, body);
      } else {
        await _api!.createItem(body);
      }
      dataRefresh.bump();
      if (mounted) {
        AppSnackBar.show(messenger, s.itemSaved, SnackKind.success);
        Navigator.pop(context, true);
      }
    } on ApiError catch (e) {
      AppSnackBar.show(messenger, s.errorForCode(e.code, fallback: e.message),
          SnackKind.error);
    } catch (e) {
      AppSnackBar.show(messenger, s.errorWith(e), SnackKind.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final df = DateFormat('d MMM yyyy', context.locale.lang);
    final img = _decode(_image);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            GradientHeader(
              subtitle: s.itemsTitle,
              title: _isEdit ? s.editItemTitle : s.addItemTitle,
              leading: _Back(onTap: () => Navigator.pop(context)),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // image picker
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.brand100,
                            borderRadius: AppRadius.rLg,
                            image: img != null
                                ? DecorationImage(
                                    image: MemoryImage(img), fit: BoxFit.cover)
                                : null,
                          ),
                          child: img == null
                              ? const Icon(Icons.add_a_photo_outlined,
                                  color: AppColors.brand500, size: 30)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _name,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            ItemFormValidators.nameCharacters),
                      ],
                      decoration: InputDecoration(
                        labelText: s.itemName,
                        helperText: _scannedBarcode == null
                            ? null
                            : s.scannedBarcode(_scannedBarcode!),
                        suffixIcon: _lookingUpBarcode
                            ? const Padding(
                                padding: EdgeInsets.all(AppSpacing.md),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                tooltip: s.scanBarcode,
                                onPressed: _scanBarcode,
                                icon: const Icon(Icons.qr_code_scanner_rounded),
                              ),
                      ),
                      validator: (v) => ItemFormValidators.requiredName(
                        v,
                        requiredMessage: s.itemName,
                        invalidMessage: s.lettersNumbersSpacesOnly,
                      ),
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
                      // In the closed field, show label only — the category
                      // icon already appears as the prefixIcon (avoid 2 icons).
                      selectedItemBuilder: (context) => ItemCategory.values
                          .map((c) => Align(
                                alignment: Alignment.centerLeft,
                                child:
                                    Text(s.categoryName(categoryToString(c))),
                              ))
                          .toList(),
                      items: ItemCategory.values
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Row(
                                  children: [
                                    Icon(categoryIcon(c),
                                        size: 20, color: AppColors.brand500),
                                    const SizedBox(width: AppSpacing.md),
                                    Text(s.categoryName(categoryToString(c))),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _category = v ?? _category),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _size,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              TextInputFormatter.withFunction(
                                (oldValue, newValue) => ItemFormValidators
                                        .decimalInput
                                        .hasMatch(newValue.text)
                                    ? newValue
                                    : oldValue,
                              ),
                            ],
                            decoration: InputDecoration(labelText: s.sizeLabel),
                            validator: (v) =>
                                ItemFormValidators.optionalDecimal(
                              v,
                              s.decimalNumberOnly,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: TextFormField(
                            controller: _unit,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  ItemFormValidators.letterCharacters),
                            ],
                            decoration:
                                InputDecoration(labelText: s.unitFieldLabel),
                            validator: (v) =>
                                ItemFormValidators.optionalLetters(
                              v,
                              s.lettersOnly,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _qty,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(labelText: s.quantity),
                            validator: (v) =>
                                ItemFormValidators.positiveInteger(
                              v,
                              requiredMessage: s.quantity,
                              invalidMessage: s.positiveIntegerOnly,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _price,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        TextInputFormatter.withFunction(
                          (oldValue, newValue) => ItemFormValidators.priceInput
                                  .hasMatch(newValue.text)
                              ? newValue
                              : oldValue,
                        ),
                      ],
                      decoration: InputDecoration(labelText: s.unitPrice),
                      validator: (v) => ItemFormValidators.requiredPrice(
                        v,
                        requiredMessage: s.unitPrice,
                        invalidMessage: s.priceFormat,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _store,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            ItemFormValidators.nameCharacters),
                      ],
                      decoration: InputDecoration(
                        labelText: s.storeLabel,
                        prefixIcon: const Icon(Icons.store_outlined),
                      ),
                      validator: (v) => ItemFormValidators.optionalName(
                        v,
                        s.lettersNumbersSpacesOnly,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DateField(
                      label: _purchaseDate == null
                          ? s.purchaseDateLabel
                          : '${s.purchaseDateLabel}: ${df.format(_purchaseDate!)}',
                      icon: Icons.event_outlined,
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showAdaptiveDatePicker(
                          context: context,
                          initialDate: _purchaseDate ?? now,
                          firstDate: DateTime(now.year - 5),
                          lastDate: DateTime(now.year + 1),
                        );
                        if (picked != null) {
                          setState(() => _purchaseDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _buyer,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            ItemFormValidators.nameCharacters),
                      ],
                      decoration: InputDecoration(
                        labelText: s.buyerLabel,
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                      ),
                      validator: (v) => ItemFormValidators.optionalName(
                        v,
                        s.lettersNumbersSpacesOnly,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DateField(
                      label: _expiryDate == null
                          ? s.pickExpiry
                          : '${s.expiryLabel}: ${df.format(_expiryDate!)}',
                      icon: Icons.schedule_rounded,
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showAdaptiveDatePicker(
                          context: context,
                          initialDate: _expiryDate ?? now,
                          firstDate: DateTime(now.year - 1),
                          lastDate: DateTime(now.year + 10),
                        );
                        if (picked != null) {
                          setState(() => _expiryDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SwitchListTile.adaptive(
                      value: _recurring,
                      onChanged: (v) => setState(() => _recurring = v),
                      title: Text(s.recurringLabel),
                      subtitle: Text(s.recurringHint,
                          style: AppType.caption
                              .copyWith(color: AppColors.neutral500)),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_recurring) ...[
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _recurringDays,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: s.recurringDaysLabel,
                          hintText: s.recurringDaysHint,
                          prefixIcon: const Icon(Icons.autorenew_rounded),
                          suffixText: s.daysUnit,
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          if (!_recurring) return null;
                          final t = v?.trim() ?? '';
                          if (t.isEmpty) return null; // optional
                          final n = int.tryParse(t);
                          if (n == null || n < 1 || n > 3650) {
                            return s.recurringDaysInvalid;
                          }
                          return null;
                        },
                      ),
                      if (_recurringPreview != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.brand500.withValues(alpha: 0.08),
                            borderRadius: AppRadius.rMd,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_available_rounded,
                                  size: 18, color: AppColors.brand500),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  s.recurringPreview(_recurringPreview!),
                                  style: AppType.bodyMedium
                                      .copyWith(color: AppColors.brand700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : Text(s.save),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

class _Back extends StatelessWidget {
  final VoidCallback onTap;
  const _Back({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return HeaderIconButton(
      icon: Icons.chevron_left_rounded,
      onTap: onTap,
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _DateField(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.rMd,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).inputDecorationTheme.fillColor ??
              AppColors.neutral100,
          borderRadius: AppRadius.rMd,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.neutral500, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }
}
