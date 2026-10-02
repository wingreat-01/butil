import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/rice_product.dart';
import '../models/sale.dart';

class StoreProvider extends ChangeNotifier {
  static const _productsKey = 'bigasan_products';
  static const _salesKey = 'bigasan_sales';

  final List<RiceProduct> _products = [];
  final List<CartItem> _cart = [];
  final List<Sale> _sales = [];
  String _category = 'All';

  List<RiceProduct> get products => List.unmodifiable(_products);
  List<CartItem> get cart => List.unmodifiable(_cart);
  List<Sale> get sales => List.unmodifiable(_sales);
  String get category => _category;

  List<String> get categories {
    final set = <String>{'All'};
    set.addAll(_products.map((p) => p.category));
    return set.toList();
  }

  double get cartTotal => _cart.fold(0, (sum, item) => sum + item.total);
  double get cartKg => _cart.fold(0, (sum, item) => sum + item.quantityKg);
  int get cartLines => _cart.length;

  double get todayRevenue {
    final now = DateTime.now();
    return _sales.where((s) =>
      s.timestamp.year == now.year &&
      s.timestamp.month == now.month &&
      s.timestamp.day == now.day
    ).fold(0, (sum, s) => sum + s.total);
  }

  double get todayKg {
    final now = DateTime.now();
    return _sales.where((s) =>
      s.timestamp.year == now.year &&
      s.timestamp.month == now.month &&
      s.timestamp.day == now.day
    ).fold(0, (sum, s) => sum + s.lines.fold(0, (a, l) => a + l.quantityKg));
  }

  double get inventoryValue =>
      _products.fold(0, (sum, p) => sum + p.stockKg * p.costPerKg);

  List<RiceProduct> get filteredProducts {
    if (_category == 'All') return products;
    return _products.where((p) => p.category == _category).toList();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawProducts = prefs.getString(_productsKey);
    final rawSales = prefs.getString(_salesKey);

    if (rawProducts == null) {
      _products.addAll(_seedProducts());
    } else {
      _products.addAll((jsonDecode(rawProducts) as List).map(_productFromJson));
    }

    if (rawSales != null) {
      _sales.addAll((jsonDecode(rawSales) as List).map(_saleFromJson));
    }
    notifyListeners();
  }

  List<RiceProduct> _seedProducts() => const [
    RiceProduct(id: '1', name: 'Regular Milled Rice', category: 'Regular', pricePerKg: 48, costPerKg: 42, stockKg: 300, lowStockKg: 50),
    RiceProduct(id: '2', name: 'Dinorado', category: 'Premium', pricePerKg: 58, costPerKg: 50, stockKg: 180, lowStockKg: 40, sackKg: 25),
    RiceProduct(id: '3', name: 'Jasmine Rice', category: 'Premium', pricePerKg: 65, costPerKg: 56, stockKg: 120, lowStockKg: 30, sackKg: 10),
    RiceProduct(id: '4', name: 'Sinandomeng', category: 'Regular', pricePerKg: 55, costPerKg: 47, stockKg: 90, lowStockKg: 25),
    RiceProduct(id: '5', name: 'Well Milled Rice', category: 'Regular', pricePerKg: 52, costPerKg: 45, stockKg: 240, lowStockKg: 50),
    RiceProduct(id: '6', name: 'Brown Rice', category: 'Healthy', pricePerKg: 72, costPerKg: 62, stockKg: 70, lowStockKg: 20),
  ];

  void setCategory(String value) {
    _category = value;
    notifyListeners();
  }

  void addToCart(RiceProduct product, double kg) {
    if (kg <= 0 || kg > product.stockKg) return;
    final existing = _cart.where((i) => i.product.id == product.id).toList();
    if (existing.isEmpty) {
      _cart.add(CartItem(product: product, quantityKg: kg));
    } else {
      final item = existing.first;
      final newQty = item.quantityKg + kg;
      if (newQty <= product.stockKg) item.quantityKg = newQty;
    }
    notifyListeners();
  }

  void setCartQuantity(CartItem item, double kg) {
    if (kg <= 0) {
      _cart.remove(item);
    } else if (kg <= item.product.stockKg) {
      item.quantityKg = kg;
    }
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  Future<bool> checkout(double cash) async {
    if (_cart.isEmpty || cash < cartTotal) return false;

    final lines = _cart.map((i) => SaleLine(
      productName: i.product.name,
      quantityKg: i.quantityKg,
      pricePerKg: i.product.pricePerKg,
      total: i.total,
    )).toList();

    final sale = Sale(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      lines: lines,
      total: cartTotal,
      cash: cash,
      change: cash - cartTotal,
    );

    for (final item in _cart) {
      final index = _products.indexWhere((p) => p.id == item.product.id);
      if (index >= 0) {
        _products[index] = _products[index].copyWith(
          stockKg: _products[index].stockKg - item.quantityKg,
        );
      }
    }

    _sales.add(sale);
    _cart.clear();
    await _save();
    notifyListeners();
    return true;
  }

  Future<void> restock(RiceProduct product, double kg) async {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index < 0 || kg <= 0) return;
    _products[index] = _products[index].copyWith(
      stockKg: _products[index].stockKg + kg,
    );
    await _save();
    notifyListeners();
  }

  Future<void> updatePrice(RiceProduct product, double price) async {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index < 0 || price <= 0) return;
    _products[index] = _products[index].copyWith(pricePerKg: price);
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_productsKey, jsonEncode(_products.map((p) => {
      'id': p.id, 'name': p.name, 'category': p.category,
      'pricePerKg': p.pricePerKg, 'costPerKg': p.costPerKg,
      'stockKg': p.stockKg, 'lowStockKg': p.lowStockKg, 'sackKg': p.sackKg,
    }).toList()));
    await prefs.setString(_salesKey, jsonEncode(_sales.map((s) => {
      'id': s.id,
      'timestamp': s.timestamp.toIso8601String(),
      'total': s.total, 'cash': s.cash, 'change': s.change,
      'lines': s.lines.map((l) => {
        'productName': l.productName, 'quantityKg': l.quantityKg,
        'pricePerKg': l.pricePerKg, 'total': l.total,
      }).toList(),
    }).toList()));
  }

  RiceProduct _productFromJson(dynamic x) => RiceProduct(
    id: x['id'], name: x['name'], category: x['category'],
    pricePerKg: (x['pricePerKg'] as num).toDouble(),
    costPerKg: (x['costPerKg'] as num).toDouble(),
    stockKg: (x['stockKg'] as num).toDouble(),
    lowStockKg: (x['lowStockKg'] as num).toDouble(),
    sackKg: (x['sackKg'] as num?)?.toDouble() ?? 50,
  );

  Sale _saleFromJson(dynamic x) => Sale(
    id: x['id'],
    timestamp: DateTime.parse(x['timestamp']),
    total: (x['total'] as num).toDouble(),
    cash: (x['cash'] as num).toDouble(),
    change: (x['change'] as num).toDouble(),
    lines: (x['lines'] as List).map((l) => SaleLine(
      productName: l['productName'],
      quantityKg: (l['quantityKg'] as num).toDouble(),
      pricePerKg: (l['pricePerKg'] as num).toDouble(),
      total: (l['total'] as num).toDouble(),
    )).toList(),
  );
}
