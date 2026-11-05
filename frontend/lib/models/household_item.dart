/// Household item categories (must match backend enum).
enum ItemCategory { laundry, kitchen, bathroom, food, personal, other }

ItemCategory categoryFromString(String? v) {
  switch (v) {
    case 'laundry':
      return ItemCategory.laundry;
    case 'kitchen':
      return ItemCategory.kitchen;
    case 'bathroom':
      return ItemCategory.bathroom;
    case 'food':
      return ItemCategory.food;
    case 'personal':
      return ItemCategory.personal;
    default:
      return ItemCategory.other;
  }
}

String categoryToString(ItemCategory c) => c.name;

/// Client-side model for a household item (mirrors gateway JSON).
class HouseholdItem {
  final int? id; // running id
  final String itemId; // public UUID
  final String name;
  final ItemCategory category;
  final String? size;
  final String? unit;
  final int quantity;
  final double price;
  final double subtotal;
  final String? store;
  final String? purchaseDate; // yyyy-mm-dd
  final String? buyer;
  final String? expiryDate; // yyyy-mm-dd
  final int? daysUntilExpiry;
  final String? imageBase64;
  final bool notifyRecurring;
  final int? recurringDays;

  HouseholdItem({
    this.id,
    required this.itemId,
    required this.name,
    required this.category,
    this.size,
    this.unit,
    required this.quantity,
    required this.price,
    this.subtotal = 0,
    this.store,
    this.purchaseDate,
    this.buyer,
    this.expiryDate,
    this.daysUntilExpiry,
    this.imageBase64,
    this.notifyRecurring = false,
    this.recurringDays,
  });

  factory HouseholdItem.fromJson(Map<String, dynamic> json) {
    return HouseholdItem(
      id: (json['id'] as num?)?.toInt(),
      itemId: json['itemId'] as String,
      name: json['name'] as String,
      category: categoryFromString(json['category'] as String?),
      size: json['size'] as String?,
      unit: json['unit'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      store: json['store'] as String?,
      purchaseDate: json['purchaseDate'] != null
          ? (json['purchaseDate'] as String).substring(0, 10)
          : null,
      buyer: json['buyer'] as String?,
      expiryDate: json['expiryDate'] != null
          ? (json['expiryDate'] as String).substring(0, 10)
          : null,
      daysUntilExpiry: (json['daysUntilExpiry'] as num?)?.toInt(),
      imageBase64: json['imageBase64'] as String?,
      notifyRecurring: (json['notifyRecurring'] ?? false) as bool,
      recurringDays: (json['recurringDays'] as num?)?.toInt(),
    );
  }

  /// size + unit, e.g. "1.5 ลิตร"
  String get sizeLabel =>
      [size, unit].where((s) => (s ?? '').trim().isNotEmpty).join(' ').trim();
}
