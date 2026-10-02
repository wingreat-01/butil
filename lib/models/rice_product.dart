class RiceProduct {
  final String id;
  final String name;
  final String category;
  final double pricePerKg;
  final double costPerKg;
  final double stockKg;
  final double lowStockKg;
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
