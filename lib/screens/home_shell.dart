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
              Text('${product.stockKg.toStringAsFixed(0)} kg in stock',
                style: TextStyle(color: product.lowStock ? Colors.red : Colors.grey[700], fontSize: 12)),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) {
        final qty = double.tryParse(controller.text) ?? 0;
        return Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('₱${product.pricePerKg.toStringAsFixed(2)} per kg'),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'kg', label: Text('Kilogram')),
                ButtonSegment(value: 'sack', label: Text('50 kg Sack')),
              ],
              selected: {unit},
              onSelectionChanged: (v) {
                setModal(() {
                  unit = v.first;
                  controller.text = unit == 'sack' ? '1' : '1';
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setModal(() {}),
              decoration: InputDecoration(
                labelText: unit == 'kg' ? 'Quantity (kg)' : 'Number of sacks',
                prefixIcon: const Icon(Icons.scale),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Total: ₱${((unit == 'sack' ? qty * product.sackKg : qty) * product.pricePerKg).toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Add to Cart'),
              onPressed: qty <= 0 || (unit == 'kg' ? qty : qty * product.sackKg) > product.stockKg ? null : () {
                final kg = unit == 'sack' ? qty * product.sackKg : qty;
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

class _InventoryPage extends StatelessWidget {
  const _InventoryPage();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          const Icon(Icons.warehouse_outlined, size: 36),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Inventory Value', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('₱${store.inventoryValue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            Text('Based on cost per kilogram'),
          ])),
        ]))),
        const SizedBox(height: 8),
        ...store.products.map((p) => Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(p.stockKg.toStringAsFixed(0))),
            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('₱${p.pricePerKg.toStringAsFixed(2)}/kg • Cost ₱${p.costPerKg.toStringAsFixed(2)}/kg'),
            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${p.stockKg.toStringAsFixed(1)} kg'),
              if (p.lowStock) const Text('LOW', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ]),
            onTap: () => _restock(context, p),
          ),
        )),
      ],
    );
  }

  void _restock(BuildContext context, RiceProduct product) {
    final c = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Restock ${product.name}'),
      content: TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: 'Add kilograms', suffixText: 'kg'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          final kg = double.tryParse(c.text) ?? 0;
          context.read<StoreProvider>().restock(product, kg);
          Navigator.pop(ctx);
        }, child: const Text('Add Stock')),
      ],
    ));
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
