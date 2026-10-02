class RiceProduct {
  final String id;
  final String name;
  final String category;
  final double pricePerKg;
  final double costPerKg;
  final double stockKg;
  final double lowStockKg;
  /// Default purchase/restock package size for this rice.
  final double sackKg;

  const RiceProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.pricePerKg,
    required this.costPerKg,
    required this.stockKg,
    required this.lowStockKg,
    this.sackKg = 50,
  });

  bool get lowStock => stockKg <= lowStockKg;

  /// Equivalent package count. This is only a view of the same kg stock.
  double packagesFor(double packageKg) {
    if (packageKg <= 0) return 0;
    return stockKg / packageKg;
  }

  RiceProduct copyWith({
    double? stockKg,
    double? pricePerKg,
    double? costPerKg,
    double? lowStockKg,
    double? sackKg,
  }) {
    return RiceProduct(
      id: id,
      name: name,
      category: category,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      costPerKg: costPerKg ?? this.costPerKg,
      stockKg: stockKg ?? this.stockKg,
      lowStockKg: lowStockKg ?? this.lowStockKg,
      sackKg: sackKg ?? this.sackKg,
    );
  }
}
