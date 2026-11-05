/// A single purchase event for a product (mirrors gateway JSON).
class Purchase {
  final String purchaseId;
  final String productId;
  final int quantity;
  final double price;
  final double subtotal;
  final String? buyer;
  final String? store;
  final String purchasedAt; // yyyy-mm-dd
  final DateTime createdAt;

  Purchase({
    required this.purchaseId,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.subtotal,
    this.buyer,
    this.store,
    required this.purchasedAt,
    required this.createdAt,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      purchaseId: json['purchaseId'] as String,
      productId: json['productId'] as String,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      buyer: json['buyer'] as String?,
      store: json['store'] as String?,
      purchasedAt: (json['purchasedAt'] as String).substring(0, 10),
      createdAt: json['createdAt'] == null
          ? DateTime.parse((json['purchasedAt'] as String).substring(0, 10))
          : DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Monthly purchase summary (from analytics /summary-month).
class MonthlySummary {
  final String month; // yyyy-mm
  final double grandTotal;
  final int totalPurchases;
  final int totalQty;
  final List<CategoryAmount> byCategory;
  final List<BuyerAmount> byBuyer;

  MonthlySummary({
    required this.month,
    required this.grandTotal,
    required this.totalPurchases,
    required this.totalQty,
    required this.byCategory,
    required this.byBuyer,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> json) {
    return MonthlySummary(
      month: json['month'] as String,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0,
      totalPurchases: (json['totalPurchases'] as num?)?.toInt() ?? 0,
      totalQty: (json['totalQty'] as num?)?.toInt() ?? 0,
      byCategory: ((json['byCategory'] as List?) ?? [])
          .map((e) => CategoryAmount(
                category: e['category'] as String,
                amount: (e['amount'] as num).toDouble(),
              ))
          .toList(),
      byBuyer: ((json['byBuyer'] as List?) ?? [])
          .map((e) => BuyerAmount(
                buyer: e['buyer'] as String,
                amount: (e['amount'] as num).toDouble(),
              ))
          .toList(),
    );
  }
}

class CategoryAmount {
  final String category;
  final double amount;
  CategoryAmount({required this.category, required this.amount});
}

class BuyerAmount {
  final String buyer;
  final double amount;
  BuyerAmount({required this.buyer, required this.amount});
}
