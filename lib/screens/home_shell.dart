import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../state/store_provider.dart';
import '../models/cart_item.dart';
import '../models/rice_product.dart';
import '../models/sale.dart';
import 'paywall_screen.dart';

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
      const _MorePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _index == 0 ? 'New Sale' : _index == 1 ? 'Rice Stock' : _index == 2 ? 'Sales' : 'More',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
        ),
        actions: [
          if (_index == 0 && store.cart.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: 'Clear cart',
                icon: const Icon(Icons.delete_sweep_outlined),
                onPressed: store.clearCart,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          const TrialBanner(),
          Expanded(child: pages[_index]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: 'Sell'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Stock'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Sales'),
          NavigationDestination(icon: Icon(Icons.more_horiz), selectedIcon: Icon(Icons.more), label: 'More'),
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
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: _MiniSummary(
                  icon: Icons.payments_outlined,
                  label: 'Today',
                  value: '₱${store.todayRevenue.toStringAsFixed(0)}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniSummary(
                  icon: Icons.scale_outlined,
                  label: 'Sold today',
                  value: '${store.todayKg.toStringAsFixed(0)} kg',
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
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
                  maxCrossAxisExtent: 210,
                  mainAxisExtent: 205,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
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
    final canSell = product.stockKg > 0;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: canSell ? () => _showQuantity(context, product) : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 72,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4EC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  children: [
                    const Center(child: Icon(Icons.grain, size: 42)),
                    if (product.lowStock && canSell)
                      Positioned(
                        top: 7,
                        right: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE9E7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'LOW',
                            style: TextStyle(
                              color: Color(0xFFC62828),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              const SizedBox(height: 3),
              Text(
                '₱${product.pricePerKg.toStringAsFixed(2)} / kg',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    canSell ? Icons.inventory_2_outlined : Icons.remove_shopping_cart_outlined,
                    size: 16,
                    color: canSell ? Colors.grey[700] : const Color(0xFFC62828),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      canSell
                          ? '${product.stockKg.toStringAsFixed(1)} kg available'
                          : 'Out of stock',
                      style: TextStyle(
                        color: canSell ? Colors.grey[700] : const Color(0xFFC62828),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (canSell)
                    const Icon(Icons.add_circle, size: 21),
                ],
              ),
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
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                unit == 'kg' ? 'Quick quantity' : 'Quick packs',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: (unit == 'kg' ? <double>[1, 2, 5, 10, 25] : <double>[1, 2, 3, 5]).map((v) => OutlinedButton(
                onPressed: () { controller.text = v.toString(); setModal(() {}); },
                child: Text(unit == 'kg' ? '${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1)} kg' : '${v.toStringAsFixed(0)} pack'),
              )).toList(),
            ),
            const SizedBox(height: 8),
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
    String paymentMethod = 'Cash';
    final customerController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) {
        final cash = double.tryParse(controller.text) ?? 0;
        final change = cash - store.cartTotal;
        final isUtang = paymentMethod == 'Utang';
        final isCash = paymentMethod == 'Cash';
        return Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Checkout', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    ),
                    TextButton.icon(
                      onPressed: store.cart.isEmpty ? null : () {
                        store.clearCart();
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.delete_sweep_outlined, size: 19),
                      label: const Text('Clear cart'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Card(
                  color: const Color(0xFFF8FAF7),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text('Order summary', style: TextStyle(fontWeight: FontWeight.w900)),
                            ),
                            Text(
                              '${store.cartLines} item${store.cartLines == 1 ? '' : 's'}',
                              style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        ...store.cart.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF4EC),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.grain, size: 21, color: Color(0xFF287A45)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.quantityKg.toStringAsFixed(item.quantityKg % 1 == 0 ? 0 : 1)} kg × ₱${item.product.pricePerKg.toStringAsFixed(2)}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('₱${item.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900)),
                              IconButton(
                                tooltip: 'Remove item',
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () {
                                  store.setCartQuantity(item, 0);
                                  setModal(() {});
                                },
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Amount to collect', style: TextStyle(color: Colors.grey[600])),
                Text('₱${store.cartTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Cash', label: Text('Cash'), icon: Icon(Icons.payments_outlined)),
                ButtonSegment(value: 'GCash', label: Text('GCash'), icon: Icon(Icons.phone_android)),
                ButtonSegment(value: 'Utang', label: Text('Utang'), icon: Icon(Icons.account_balance_wallet_outlined)),
              ],
              selected: {paymentMethod},
              onSelectionChanged: (v) => setModal(() { paymentMethod = v.first; }),
            ),
            const SizedBox(height: 12),
            if (isUtang) TextField(
              controller: customerController,
              onChanged: (_) => setModal(() {}),
              decoration: const InputDecoration(labelText: 'Customer name', prefixIcon: Icon(Icons.person_outline)),
            ),
            if (isUtang) const SizedBox(height: 10),
            if (isCash) TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setModal(() {}),
              decoration: InputDecoration(
                labelText: 'Cash received',
                prefixText: '₱ ',
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear amount',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                          setModal(() {});
                        },
                      ),
              ),
            ),
            if (paymentMethod == 'GCash')
              const Align(alignment: Alignment.centerLeft, child: Text('Mark as paid via GCash. No change is calculated.', style: TextStyle(fontSize: 12))),
            const SizedBox(height: 10),
            if (isCash) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Quick cash', style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: _quickCashAmounts(store.cartTotal).map((v) => OutlinedButton(
                  onPressed: () { controller.text = v.toStringAsFixed(0); setModal(() {}); },
                  child: Text('₱${v.toStringAsFixed(0)}'),
                )).toList(),
              ),
            ],
            const SizedBox(height: 8),
            if (isCash && cash >= store.cartTotal)
              Text('CHANGE  ₱${change.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF287A45))),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: FilledButton(
              onPressed: isUtang
                  ? (customerController.text.trim().isEmpty ? null : () async {
                      await store.checkout(0, paymentMethod: paymentMethod, customerName: customerController.text.trim());
                      if (ctx.mounted) { Navigator.pop(ctx); _receipt(context); }
                    })
                  : (isCash && cash < store.cartTotal ? null : () async {
                      await store.checkout(isCash ? cash : store.cartTotal, paymentMethod: paymentMethod);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        _receipt(context);
                      }
                    }),
              child: const Text('Complete Sale'),
            )),
          ]),
        ),
      ),
    );
      }),
    );
  }

  String _receiptText(Sale sale) {
    final b = StringBuffer();
    b.writeln('BIGASAN POS');
    b.writeln('Sales Receipt');
    b.writeln(DateFormat('MMM d, yyyy • h:mm a').format(sale.timestamp));
    b.writeln('--------------------');
    for (final l in sale.lines) {
      b.writeln('${l.productName}');
      b.writeln('${l.quantityKg.toStringAsFixed(1)} kg × ₱${l.pricePerKg.toStringAsFixed(2)} = ₱${l.total.toStringAsFixed(2)}');
    }
    b.writeln('--------------------');
    b.writeln('TOTAL: ₱${sale.total.toStringAsFixed(2)}');
    b.writeln('PAYMENT: ${sale.paymentMethod}');
    if (sale.paymentMethod == 'Cash') {
      b.writeln('CASH: ₱${sale.cash.toStringAsFixed(2)}');
      b.writeln('CHANGE: ₱${sale.change.toStringAsFixed(2)}');
    }
    if (sale.paymentMethod == 'Utang') b.writeln('CUSTOMER: ${sale.customerName ?? ''}');
    return b.toString();
  }

  void _receipt(BuildContext context) {
    final store = context.read<StoreProvider>();
    final sale = store.sales.last;
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Sale Complete'),
      content: _Receipt(sale: sale),
      actions: [
        TextButton(
          onPressed: () async {
            await Share.share(_receiptText(sale));
          },
          child: const Text('Share'),
        ),
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
        if (sale.paymentMethod == 'Cash') ...[
          _r('CASH', sale.cash),
          _r('CHANGE', sale.change),
        ],
        const SizedBox(height: 4),
        Text('Payment: ${sale.paymentMethod}', style: const TextStyle(fontWeight: FontWeight.w700)),
        if (sale.customerName != null) Text('Customer: ${sale.customerName}'),
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Inventory', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 3),
                      Text(
                        '${products.length} rice varieties',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                _InventoryAlertCount(products: products),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (products.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(child: Text('No rice varieties found.')),
          ),
        ...products.map((p) => Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _productActions(context, p),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: p.lowStock ? const Color(0xFFFFEEEC) : const Color(0xFFEAF4EC),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.grain,
                      color: p.lowStock ? const Color(0xFFC62828) : const Color(0xFF287A45),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                        const SizedBox(height: 3),
                        Text(
                          '${p.stockKg.toStringAsFixed(1)} kg in stock',
                          style: TextStyle(
                            color: p.lowStock ? const Color(0xFFC62828) : Colors.grey[700],
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Selling ₱${p.pricePerKg.toStringAsFixed(2)} / kg',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 5,
                          children: [
                            _StockPackChip(label: '10kg', count: p.packagesFor(10)),
                            _StockPackChip(label: '25kg', count: p.packagesFor(25)),
                            _StockPackChip(label: '50kg', count: p.packagesFor(50)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: Colors.grey[500]),
                ],
              ),
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
    final cost = TextEditingController(text: product.costPerKg.toStringAsFixed(2));
    final supplier = TextEditingController();
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
          const SizedBox(height: 12),
          TextField(
            controller: cost,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Cost per kg', prefixText: '₱ '),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: supplier,
            decoration: const InputDecoration(labelText: 'Supplier (optional)', prefixIcon: Icon(Icons.local_shipping_outlined)),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: kg <= 0 ? null : () {
            final costValue = double.tryParse(cost.text.trim()) ?? product.costPerKg;
            if (costValue < 0) return;
            context.read<StoreProvider>().restock(product, kg, costPerKg: costValue, supplier: supplier.text);
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
    final todayCount = store.todaySales.length;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(children: [
          Expanded(child: _Metric('Today sales', '₱${store.todayRevenue.toStringAsFixed(0)}', Icons.payments_outlined)),
          const SizedBox(width: 8),
          Expanded(child: _Metric('Est. profit', '₱${store.todayProfit.toStringAsFixed(0)}', Icons.trending_up_outlined)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _Metric('Rice sold', '${store.todayKg.toStringAsFixed(0)} kg', Icons.scale_outlined)),
          const SizedBox(width: 8),
          Expanded(child: _Metric('Transactions', '$todayCount', Icons.receipt_long_outlined)),
        ]),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF287A45)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Customer receivables', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text('Unpaid utang: ₱${store.totalReceivables.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey[700])),
                ])),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text('Recent transactions', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        if (store.sales.isEmpty)
          const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No sales yet.')))
        else
          ...store.sales.reversed.map((s) => Card(
            child: ExpansionTile(
              title: Row(children: [
                Expanded(child: Text('₱${s.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900))),
                _PaymentChip(s.paymentMethod),
              ]),
              subtitle: Text('${DateFormat('MMM d, h:mm a').format(s.timestamp)} • ${s.lines.fold(0.0, (a, l) => a + l.quantityKg).toStringAsFixed(1)} kg${s.customerName == null ? '' : ' • ${s.customerName}'}'),
              children: [
                ...s.lines.map((l) => ListTile(
                  dense: true,
                  title: Text(l.productName),
                  subtitle: Text('${l.quantityKg.toStringAsFixed(1)} kg × ₱${l.pricePerKg.toStringAsFixed(2)}'),
                  trailing: Text('₱${l.total.toStringAsFixed(2)}'),
                )),
                if (s.paymentMethod == 'Cash') ListTile(dense: true, title: const Text('Change'), trailing: Text('₱${s.change.toStringAsFixed(2)}')),
              ],
            ),
          )),
      ],
    );
  }
}

class _PaymentChip extends StatelessWidget {
  final String method;
  const _PaymentChip(this.method);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: const Color(0xFFEAF4EC), borderRadius: BorderRadius.circular(20)),
    child: Text(method, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF287A45))),
  );
}

class _MorePage extends StatelessWidget {
  const _MorePage();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final low = store.products.where((p) => p.lowStock).toList();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('Business tools', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFC62828)),
                const SizedBox(width: 8),
                const Expanded(child: Text('Low-stock dashboard', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
                Text('${low.length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              ]),
              const SizedBox(height: 8),
              if (low.isEmpty) const Text('Everything is above its low-stock alert.')
              else ...low.map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                  Text('${p.stockKg.toStringAsFixed(1)} kg', style: const TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.w800)),
                ]),
              )),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Card(child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.people_alt_outlined)),
          title: const Text('Customers & Utang', style: TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text('${store.customers.length} customers • ₱${store.totalReceivables.toStringAsFixed(2)} unpaid'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showCustomers(context),
        )),
        Card(child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.local_shipping_outlined)),
          title: const Text('Restock history', style: TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text('${store.restocks.length} stock deliveries recorded'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showRestocks(context),
        )),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const Icon(Icons.inventory_2_outlined, color: Color(0xFF287A45)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Inventory value', style: TextStyle(fontWeight: FontWeight.w800)),
                Text('Estimated cost of current stock', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
              ])),
              Text('₱${store.inventoryValue.toStringAsFixed(0)}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            ]),
          ),
        ),
      ],
    );
  }

  static void _showCustomers(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final store = ctx.watch<StoreProvider>();
        return SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Customers & Utang', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            if (store.customers.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('No unpaid customers yet.'))
            else ...store.customers.map((c) => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('Balance: ₱${c.balance.toStringAsFixed(2)}'),
              trailing: c.balance > 0 ? FilledButton.tonal(
                onPressed: () => _recordPayment(ctx, c),
                child: const Text('Bayad'),
              ) : const Text('Paid'),
            )),
          ]),
        ));
      },
    );
  }

  static void _recordPayment(BuildContext context, dynamic customer) {
    final c = TextEditingController(text: customer.balance.toStringAsFixed(2));
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Payment • ${customer.name}'),
      content: TextField(controller: c, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount paid', prefixText: '₱ ')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          final amount = double.tryParse(c.text.trim()) ?? 0;
          if (amount <= 0) return;
          await context.read<StoreProvider>().recordPayment(customer, amount);
          if (ctx.mounted) Navigator.pop(ctx);
        }, child: const Text('Save Payment')),
      ],
    ));
  }

  static void _showRestocks(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final store = ctx.watch<StoreProvider>();
        return SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Restock history', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            if (store.restocks.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('No restocks recorded yet.'))
            else ...store.restocks.take(20).map((r) => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.local_shipping_outlined)),
              title: Text(r.productName, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${r.quantityKg.toStringAsFixed(1)} kg • ${r.supplier} • ${DateFormat('MMM d, yyyy').format(r.timestamp)}'),
              trailing: Text('₱${r.totalCost.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900)),
            )),
          ]),
        ));
      },
    );
  }
}


List<double> _quickCashAmounts(double total) {
  if (total <= 0) return const [];

  // First option: the smallest convenient amount above the total,
  // rounded to the nearest ₱100. Second option: the next larger
  // commonly used cash amount (₱500/₱1,000/etc.).
  final first = (total / 100).ceil() * 100.0;
  double second;
  if (first < 500) {
    second = 500;
  } else if (first < 1000) {
    second = 1000;
  } else {
    second = ((first / 500).ceil() * 500).toDouble();
    if (second <= first) second = first + 500;
  }

  // If the first option already equals a common larger amount, move to
  // the next option so the two buttons are always useful.
  if (second == first) second += 500;
  return [first, second];
}

class _MiniSummary extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MiniSummary({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF287A45)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                  const SizedBox(height: 1),
                  Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockPackChip extends StatelessWidget {
  final String label;
  final double count;
  const _StockPackChip({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final wholePacks = count.floor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F1),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFDDE5DD)),
      ),
      child: Text(
        '$label • $wholePacks ${wholePacks == 1 ? 'pack' : 'packs'}',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _InventoryAlertCount extends StatelessWidget {
  final List<RiceProduct> products;
  const _InventoryAlertCount({required this.products});

  @override
  Widget build(BuildContext context) {
    final low = products.where((p) => p.lowStock).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: low == 0 ? const Color(0xFFEAF4EC) : const Color(0xFFFFEEEC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        low == 0 ? 'Stock OK' : '$low low stock',
        style: TextStyle(
          color: low == 0 ? const Color(0xFF287A45) : const Color(0xFFC62828),
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
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
    child: Padding(padding: const EdgeInsets.all(15), child: Row(children: [
      Icon(icon, size: 27, color: const Color(0xFF287A45)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: Colors.grey[700])),
        Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
      ])),
    ])),
  );
}
