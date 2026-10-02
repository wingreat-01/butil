class SaleLine {
  final String productName;
  final double quantityKg;
  final double pricePerKg;
  final double total;

  const SaleLine({
    required this.productName,
    required this.quantityKg,
    required this.pricePerKg,
    required this.total,
  });
}

class Sale {
  final String id;
  final DateTime timestamp;
  final List<SaleLine> lines;
  final double total;
  final double cash;
  final double change;

  const Sale({
    required this.id,
    required this.timestamp,
    required this.lines,
    required this.total,
    required this.cash,
    required this.change,
  });
}
