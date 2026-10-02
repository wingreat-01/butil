import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../state/store_provider.dart';
import '../models/cart_item.dart';
import '../models/rice_product.dart';
import '../models/sale.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _search = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final pages = [
      _RegisterPage(search: _search),
      const _InventoryPage(),
      const _SalesPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bigasan POS', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (_index == 0)
            IconButton(
              tooltip: 'Clear cart',
              icon: const Icon(Icons.remove_shopping_cart_outlined),
              onPressed: store.cart.isEmpty ? null : store.clearCart,
            ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'Register'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Stock'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Sales'),
        ],
      ),
    );
  }
}

class _RegisterPage extends StatelessWidget {
  final TextEditingController search;
  const _RegisterPage({required this.search});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final products = store.filteredProducts.where((p) =>
      p.name.toLowerCase().contains(search.text.toLowerCase())).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: TextField(
            controller: search,
            onChanged: (_) => (context as Element).markNeedsBuild(),
            decoration: InputDecoration(
              hintText: 'Search rice variety...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: search.text.isEmpty ? null : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () { search.clear(); (context as Element).markNeedsBuild(); },
              ),
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: store.categories.map((c) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(c),
                selected: store.category == c,
                onSelected: (_) => store.setCategory(c),
              ),
            )).toList(),
          ),
        ),
        Expanded(
          child: products.isEmpty
            ? const Center(child: Text('No rice varieties found.'))
            : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 210, childAspectRatio: .95,
                  crossAxisSpacing: 10, mainAxisSpacing: 10,
                ),
                itemCount: products.length,
                itemBuilder: (_, i) => _RiceCard(product: products[i]),
              ),
        ),
        _CartBar(),
      ],
    );
  }
}

class _RiceCard extends StatelessWidget {
  final RiceProduct product;
  const _RiceCard({required this.product});

  String _formatPackageCount(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<StoreProvider>();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: product.stockKg <= 0 ? null : () => _showQuantity(context, product),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F1E8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Icon(Icons.grain, size: 48)),
                ),
              ),
              const SizedBox(height: 8),
              Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800)),
              Text('₱${product.pricePerKg.toStringAsFixed(2)} / kg'),
              Text('${product.stockKg.toStringAsFixed(1)} kg in stock',
                style: TextStyle(color: product.lowStock ? Colors.red : Colors.grey[700], fontSize: 12)),
              const SizedBox(height: 2),
              Text('10kg: ${_formatPackageCount(product.packagesFor(10))} • '
                   '25kg: ${_formatPackageCount(product.packagesFor(25))} • '
                   '50kg: ${_formatPackageCount(product.packagesFor(50))}',
                style: TextStyle(color: Colors.grey[600], fontSize: 10)),
              if (product.lowStock)
                const Text('LOW STOCK', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuantity(BuildContext context, RiceProduct product) {
    final controller = TextEditingController(text: '1');
    String unit = 'kg';
    double packageKg = product.sackKg;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) {
        final qty = double.tryParse(controller.text) ?? 0;
        final kg = unit == 'kg' ? qty : qty * packageKg;
        final total = kg * product.pricePerKg;

        return Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('₱${product.pricePerKg.toStringAsFixed(2)} per kg'),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'kg', label: Text('By KG'), icon: Icon(Icons.scale)),
                ButtonSegment(value: 'package', label: Text('By Pack'), icon: Icon(Icons.inventory_2_outlined)),
              ],
              selected: {unit},
              onSelectionChanged: (v) => setModal(() {
                unit = v.first;
                controller.text = '1';
              }),
            ),
            const SizedBox(height: 12),
            if (unit == 'package')
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<double>(
                  segments: const [
                    ButtonSegment(value: 10, label: Text('10 kg')),
                    ButtonSegment(value: 25, label: Text('25 kg')),
                    ButtonSegment(value: 50, label: Text('50 kg')),
                  ],
                  selected: {packageKg},
                  onSelectionChanged: (v) => setModal(() {
                    packageKg = v.first;
                    controller.text = '1';
                  }),
                ),
              ),
            if (unit == 'package') const SizedBox(height: 10),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setModal(() {}),
              decoration: InputDecoration(
                labelText: unit == 'kg'
                    ? 'Quantity (kg)'
                    : 'Number of ${packageKg.toStringAsFixed(0)} kg packs',
                prefixIcon: const Icon(Icons.scale),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                unit == 'kg'
                    ? '${qty.toStringAsFixed(1)} kg'
                    : '${qty.toStringAsFixed(qty == qty.roundToDouble() ? 0 : 1)} pack × ${packageKg.toStringAsFixed(0)} kg = ${kg.toStringAsFixed(1)} kg',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
            const SizedBox(height: 8),
            Text('Total: ₱${total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Add to Cart'),
              onPressed: qty <= 0 || kg > product.stockKg ? null : () {
                context.read<StoreProvider>().addToCart(product, kg);
                Navigator.pop(ctx);
              },
            )),
          ]),
        );
      }),
    );
  }
}

class _CartBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    if (store.cart.isEmpty) return const SizedBox(height: 4);
    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${store.cartLines} item${store.cartLines == 1 ? '' : 's'} • ${store.cartKg.toStringAsFixed(1)} kg'),
              Text('₱${store.cartTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            ])),
            FilledButton.icon(
              icon: const Icon(Icons.payments),
              label: const Text('Checkout'),
              onPressed: () => _checkout(context),
            ),
          ]),
        ),
      ),
    );
  }

  void _checkout(BuildContext context) {
    final store = context.read<StoreProvider>();
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) {
        final cash = double.tryParse(controller.text) ?? 0;
        final change = cash - store.cartTotal;
        return Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Checkout', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('Amount Due', style: TextStyle(color: Colors.grey[600])),
            Text('₱${store.cartTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setModal(() {}),
              decoration: const InputDecoration(labelText: 'Cash received', prefixText: '₱ '),
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 8, children: [100, 200, 500, 1000].map((v) => OutlinedButton(
              onPressed: () { controller.text = v.toString(); setModal(() {}); },
              child: Text('₱$v'),
            )).toList()),
            const SizedBox(height: 8),
            if (cash >= store.cartTotal)
              Text('Change: ₱${change.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.green)),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: FilledButton(
              onPressed: cash < store.cartTotal ? null : () async {
                await store.checkout(cash);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  _receipt(context);
                }
              },
              child: const Text('Complete Sale'),
            )),
          ]),
        );
      }),
    );
  }

  void _receipt(BuildContext context) {
    final store = context.read<StoreProvider>();
    final sale = store.sales.last;
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Sale Complete'),
      content: _Receipt(sale: sale),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
      ],
    ));
  }
}

class _Receipt extends StatelessWidget {
  final Sale sale;
  const _Receipt({required this.sale});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(child: Text('BIGASAN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
        const Center(child: Text('Sales Receipt')),
        const Divider(),
        ...sale.lines.map((l) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Expanded(child: Text('${l.productName}\n${l.quantityKg.toStringAsFixed(1)} kg × ₱${l.pricePerKg.toStringAsFixed(2)}')),
            Text('₱${l.total.toStringAsFixed(2)}'),
          ]),
        )),
        const Divider(),
        _r('TOTAL', sale.total),
        _r('CASH', sale.cash),
        _r('CHANGE', sale.change),
        const SizedBox(height: 8),
        Center(child: Text(DateFormat('MMM d, yyyy • h:mm a').format(sale.timestamp),
          style: TextStyle(fontSize: 11, color: Colors.grey[600]))),
      ],
    ));
  }

  Widget _r(String label, double value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [Text(label, style: const TextStyle(fontWeight: FontWeight.bold)), Text('₱${value.toStringAsFixed(2)}')],
  );
}

class _InventoryPage extends StatefulWidget {
  const _InventoryPage();

  @override
  State<_InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<_InventoryPage> {
  final _stockSearch = TextEditingController();

  @override
  void dispose() {
    _stockSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final query = _stockSearch.text.trim().toLowerCase();
    final products = query.isEmpty
        ? store.products
        : store.products.where((p) => p.name.toLowerCase().contains(query)).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          const Icon(Icons.warehouse_outlined, size: 36),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Inventory Value', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('₱${store.inventoryValue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const Text('Based on cost per kilogram'),
          ])),
        ]))),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.add_box_outlined),
            label: const Text('Add New Stock'),
            onPressed: () => _addProduct(context),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            controller: _stockSearch,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search rice variety in stock...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _stockSearch.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _stockSearch.clear();
                        setState(() {});
                      },
                    ),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Card(child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Text('Rice Stock', style: TextStyle(fontWeight: FontWeight.w900)),
            SizedBox(height: 4),
            Text('Stock is stored in kilograms. Package counts are equivalent views of the same stock, not additional stock.'),
            SizedBox(height: 4),
            Text('Tap a rice item to add stock or edit its details, price, cost, package size, and low-stock alert.'),
          ]),
        )),
        const SizedBox(height: 8),
        if (products.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(child: Text('No rice varieties found.')),
          ),
        ...products.map((p) => Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _productActions(context, p),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CircleAvatar(child: Text(p.stockKg.toStringAsFixed(0))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(p.category, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('₱${p.pricePerKg.toStringAsFixed(2)}/kg',
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                    Text('Cost ₱${p.costPerKg.toStringAsFixed(2)}/kg',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  ]),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(Icons.scale, size: 18),
                  const SizedBox(width: 6),
                  Text('${p.stockKg.toStringAsFixed(1)} kg',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(width: 12),
                  if (p.lowStock)
                    const Text('LOW STOCK', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 7),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  _PackageChip('10 kg', p.packagesFor(10)),
                  _PackageChip('25 kg', p.packagesFor(25)),
                  _PackageChip('50 kg', p.packagesFor(50)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Text('Default purchase pack: ${p.sackKg.toStringAsFixed(0)} kg',
                    style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                  const Spacer(),
                  const Icon(Icons.edit_outlined, size: 18),
                  const SizedBox(width: 4),
                  const Text('Edit'),
                ]),
              ]),
            ),
          ),
        )),
      ],
    );
  }

  static void _productActions(BuildContext context, RiceProduct product) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit Stock Details'),
            subtitle: const Text('Name, category, price, cost, stock, alert, package size'),
            onTap: () {
              Navigator.pop(ctx);
              _editProduct(context, product);
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_box_outlined),
            title: const Text('Add Stock Quantity'),
            subtitle: Text('Current stock: ${product.stockKg.toStringAsFixed(1)} kg'),
            onTap: () {
              Navigator.pop(ctx);
              _restock(context, product);
            },
          ),
        ]),
      ),
    );
  }

  static void _addProduct(BuildContext context) {
    _productForm(context, null);
  }

  static void _editProduct(BuildContext context, RiceProduct product) {
    _productForm(context, product);
  }

  static void _productForm(BuildContext context, RiceProduct? product) {
    final isEdit = product != null;
    final name = TextEditingController(text: product?.name ?? '');
    final category = TextEditingController(text: product?.category ?? 'Regular');
    final price = TextEditingController(text: product?.pricePerKg.toStringAsFixed(2) ?? '0');
    final cost = TextEditingController(text: product?.costPerKg.toStringAsFixed(2) ?? '0');
    final stock = TextEditingController(text: product?.stockKg.toStringAsFixed(1) ?? '0');
    final lowStock = TextEditingController(text: product?.lowStockKg.toStringAsFixed(1) ?? '20');
    double packageKg = product?.sackKg ?? 50;
    String stockMode = 'kg';

    void syncPackQuantity() {
      final currentKg = double.tryParse(stock.text.trim()) ?? 0;
      final packs = packageKg <= 0 ? 0 : currentKg / packageKg;
      stock.text = packs == packs.roundToDouble()
          ? packs.toStringAsFixed(0)
          : packs.toStringAsFixed(1);
      stock.selection = TextSelection.collapsed(offset: stock.text.length);
    }

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) {
      return AlertDialog(
        title: Text(isEdit ? 'Edit Stock' : 'Add New Stock'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, autofocus: !isEdit, decoration: const InputDecoration(labelText: 'Rice name', prefixIcon: Icon(Icons.grain))),
            const SizedBox(height: 10),
            TextField(controller: category, decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined))),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Selling price / kg', prefixText: '₱ '))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: cost, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Cost / kg', prefixText: '₱ '))),
            ]),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Current stock', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'kg', label: Text('By KG'), icon: Icon(Icons.scale_outlined)),
                  ButtonSegment(value: 'package', label: Text('By Pack'), icon: Icon(Icons.inventory_2_outlined)),
                ],
                selected: {stockMode},
                onSelectionChanged: (v) {
                  final next = v.first;
                  setModal(() {
                    if (next == 'package' && stockMode == 'kg') {
                      syncPackQuantity();
                    } else if (next == 'kg' && stockMode == 'package') {
                      final packs = double.tryParse(stock.text.trim()) ?? 0;
                      final kg = packs * packageKg;
                      stock.text = kg == kg.roundToDouble()
                          ? kg.toStringAsFixed(0)
                          : kg.toStringAsFixed(1);
                      stock.selection = TextSelection.collapsed(offset: stock.text.length);
                    }
                    stockMode = next;
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: stock,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: stockMode == 'package'
                    ? 'Number of ${packageKg.toStringAsFixed(0)} kg packs'
                    : 'Current stock',
                suffixText: stockMode == 'package' ? 'packs' : 'kg',
                prefixIcon: Icon(stockMode == 'package' ? Icons.inventory_2_outlined : Icons.scale),
              ),
              onChanged: (_) => setModal(() {}),
            ),
            if (stockMode == 'package') ...[
              const SizedBox(height: 6),
              Builder(builder: (_) {
                final packs = double.tryParse(stock.text.trim()) ?? 0;
                final kg = packs * packageKg;
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Equivalent stock: ${kg.toStringAsFixed(1)} kg',
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                );
              }),
            ],
            const SizedBox(height: 10),
            TextField(controller: lowStock, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Low-stock alert', suffixText: 'kg')),
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerLeft, child: Text('Default purchase package', style: TextStyle(color: Colors.grey[700], fontSize: 12))),
            const SizedBox(height: 6),
            SizedBox(width: double.infinity, child: SegmentedButton<double>(
              segments: const [
                ButtonSegment(value: 10, label: Text('10 kg')),
                ButtonSegment(value: 25, label: Text('25 kg')),
                ButtonSegment(value: 50, label: Text('50 kg')),
              ],
              selected: {packageKg},
              onSelectionChanged: (v) {
                final newPackageKg = v.first;
                setModal(() {
                  if (stockMode == 'package') {
                    final packs = double.tryParse(stock.text.trim()) ?? 0;
                    final kg = packs * packageKg;
                    packageKg = newPackageKg;
                    final newPacks = packageKg <= 0 ? 0 : kg / packageKg;
                    stock.text = newPacks == newPacks.roundToDouble()
                        ? newPacks.toStringAsFixed(0)
                        : newPacks.toStringAsFixed(1);
                    stock.selection = TextSelection.collapsed(offset: stock.text.length);
                  } else {
                    packageKg = newPackageKg;
                  }
                });
              },
            )),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final n = name.text.trim();
              final p = double.tryParse(price.text.trim()) ?? 0;
              final c = double.tryParse(cost.text.trim()) ?? 0;
              final enteredStock = double.tryParse(stock.text.trim()) ?? -1;
              final s = stockMode == 'package' ? enteredStock * packageKg : enteredStock;
              final l = double.tryParse(lowStock.text.trim()) ?? -1;
              if (n.isEmpty || p <= 0 || c < 0 || enteredStock < 0 || l < 0 || s < 0) return;
              final store = context.read<StoreProvider>();
              if (isEdit) {
                await store.updateProduct(product, name: n, category: category.text.trim(), pricePerKg: p, costPerKg: c, stockKg: s, lowStockKg: l, sackKg: packageKg);
              } else {
                await store.addProduct(name: n, category: category.text.trim(), pricePerKg: p, costPerKg: c, stockKg: s, lowStockKg: l, sackKg: packageKg);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(isEdit ? 'Save Changes' : 'Add Stock'),
          ),
        ],
      );
    }));
  }

  static void _editPrice(BuildContext context, RiceProduct product) {
    final c = TextEditingController(text: product.pricePerKg.toStringAsFixed(2));
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Edit Price • ${product.name}'),
      content: TextField(
        controller: c,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Selling price per kilogram',
          prefixText: '₱ ',
          suffixText: '/ kg',
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            final price = double.tryParse(c.text.trim()) ?? 0;
            if (price <= 0) return;
            await context.read<StoreProvider>().updatePrice(product, price);
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Save Price'),
        ),
      ],
    ));
  }

  static void _restock(BuildContext context, RiceProduct product) {
    final c = TextEditingController();
    double packageKg = product.sackKg;
    String mode = 'package';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) {
      final qty = double.tryParse(c.text) ?? 0;
      final kg = mode == 'package' ? qty * packageKg : qty;
      return AlertDialog(
        title: Text('Add Stock • ${product.name}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'package', label: Text('Pack')),
              ButtonSegment(value: 'kg', label: Text('KG')),
            ],
            selected: {mode},
            onSelectionChanged: (v) => setModal(() {
              mode = v.first;
              c.clear();
            }),
          ),
          const SizedBox(height: 12),
          if (mode == 'package')
            SegmentedButton<double>(
              segments: const [
                ButtonSegment(value: 10, label: Text('10 kg')),
                ButtonSegment(value: 25, label: Text('25 kg')),
                ButtonSegment(value: 50, label: Text('50 kg')),
              ],
              selected: {packageKg},
              onSelectionChanged: (v) => setModal(() {
                packageKg = v.first;
                c.clear();
              }),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: c,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setModal(() {}),
            decoration: InputDecoration(
              labelText: mode == 'package'
                  ? 'Number of ${packageKg.toStringAsFixed(0)} kg packs'
                  : 'Add kilograms',
              suffixText: mode == 'kg' ? 'kg' : 'packs',
            ),
          ),
          if (qty > 0) ...[
            const SizedBox(height: 8),
            Text('Adds ${kg.toStringAsFixed(1)} kg to inventory',
              style: TextStyle(color: Colors.grey[700])),
          ],
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: kg <= 0 ? null : () {
            context.read<StoreProvider>().restock(product, kg);
            Navigator.pop(ctx);
          }, child: const Text('Add Stock')),
        ],
      );
    }));
  }
}

class _PackageChip extends StatelessWidget {
  final String label;
  final double count;
  const _PackageChip(this.label, this.count);

  @override
  Widget build(BuildContext context) {
    final countText = count == count.roundToDouble()
        ? count.toStringAsFixed(0)
        : count.toStringAsFixed(1);
    return Chip(
      avatar: const Icon(Icons.inventory_2_outlined, size: 16),
      label: Text('$label: $countText'),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _SalesPage extends StatelessWidget {
  const _SalesPage();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(children: [
          Expanded(child: _Metric('Today Sales', '₱${store.todayRevenue.toStringAsFixed(2)}', Icons.payments)),
          const SizedBox(width: 8),
          Expanded(child: _Metric('Rice Sold', '${store.todayKg.toStringAsFixed(1)} kg', Icons.scale)),
        ]),
        const SizedBox(height: 12),
        _Metric('Transactions', '${store.sales.where((s) {
          final n = DateTime.now();
          return s.timestamp.year == n.year && s.timestamp.month == n.month && s.timestamp.day == n.day;
        }).length}', Icons.receipt_long),
        const SizedBox(height: 16),
        const Text('Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        if (store.sales.isEmpty)
          const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No sales yet.')))
        else
          ...store.sales.reversed.map((s) => Card(
            child: ExpansionTile(
              title: Text('₱${s.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text('${DateFormat('MMM d, h:mm a').format(s.timestamp)} • ${s.lines.fold(0.0, (a, l) => a + l.quantityKg).toStringAsFixed(1)} kg'),
              children: s.lines.map((l) => ListTile(
                dense: true,
                title: Text(l.productName),
                subtitle: Text('${l.quantityKg.toStringAsFixed(1)} kg × ₱${l.pricePerKg.toStringAsFixed(2)}'),
                trailing: Text('₱${l.total.toStringAsFixed(2)}'),
              )).toList(),
            ),
          )),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _Metric(this.title, this.value, this.icon);

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
      Icon(icon, size: 30),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: Colors.grey[700])),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      ])),
    ])),
  );
}
