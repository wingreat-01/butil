class RestockRecord {
  final String id;
  final String productName;
  final double quantityKg;
  final double costPerKg;
  final String supplier;
  final DateTime timestamp;

  const RestockRecord({
    required this.id,
    required this.productName,
    required this.quantityKg,
    required this.costPerKg,
    required this.supplier,
    required this.timestamp,
  });

  double get totalCost => quantityKg * costPerKg;
}
