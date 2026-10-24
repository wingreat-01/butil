class Customer {
  final String id;
  final String name;
  final double balance;

  const Customer({required this.id, required this.name, required this.balance});

  Customer copyWith({String? name, double? balance}) => Customer(
    id: id,
    name: name ?? this.name,
    balance: balance ?? this.balance,
  );
}
