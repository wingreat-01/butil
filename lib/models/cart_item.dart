import 'rice_product.dart';

class CartItem {
  final RiceProduct product;
  double quantityKg;

  CartItem({required this.product, required this.quantityKg});

  double get total => quantityKg * product.pricePerKg;
}
