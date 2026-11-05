import 'household_item.dart' show ItemCategory, categoryFromString;

/// Stock status of a product (user-driven via buttons).
enum ProductStatus { inStock, low, out }

ProductStatus productStatusFromString(String? v) {
  switch (v) {
    case 'low':
      return ProductStatus.low;
    case 'out':
      return ProductStatus.out;
    default:
      return ProductStatus.inStock;
  }
}

String productStatusToString(ProductStatus s) {
  switch (s) {
    case ProductStatus.low:
      return 'low';
    case ProductStatus.out:
      return 'out';
    case ProductStatus.inStock:
      return 'in_stock';
  }
}

/// Product master — the durable catalogue entry (mirrors gateway JSON).
class Product {
  final String productId;
  final String name;
  final ItemCategory category;
  final String? size;
  final String? unit;
  final String? imageBase64;
  final bool isRecurring;
  final int? recurringDaysManual;
  final String? expiryDate; // yyyy-mm-dd
  final int? daysUntilExpiry;
  final ProductStatus status;

  Product({
    required this.productId,
    required this.name,
    required this.category,
    this.size,
    this.unit,
    this.imageBase64,
    this.isRecurring = false,
    this.recurringDaysManual,
    this.expiryDate,
    this.daysUntilExpiry,
    this.status = ProductStatus.inStock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['productId'] as String,
      name: json['name'] as String,
      category: categoryFromString(json['category'] as String?),
      size: json['size'] as String?,
      unit: json['unit'] as String?,
      imageBase64: json['imageBase64'] as String?,
      isRecurring: (json['isRecurring'] ?? false) as bool,
      recurringDaysManual: (json['recurringDaysManual'] as num?)?.toInt(),
      expiryDate: json['expiryDate'] != null
          ? (json['expiryDate'] as String).substring(0, 10)
          : null,
      daysUntilExpiry: (json['daysUntilExpiry'] as num?)?.toInt(),
      status: productStatusFromString(json['status'] as String?),
    );
  }

  /// size + unit, e.g. "1.5 ลิตร"
  String get sizeLabel =>
      [size, unit].where((s) => (s ?? '').trim().isNotEmpty).join(' ').trim();
}
