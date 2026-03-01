import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/data/services/product_service.dart';
import 'package:diab_care/data/services/order_service.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});
  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _productService = ProductService();
  final _orderService = OrderService();
  final _tokenService = TokenService();
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  String? _selectedCategory;
  String? _patientId;

  final _categories = [
    {'key': null, 'label': 'Tous'},
    {'key': 'medicament', 'label': 'Medicaments'},
    {'key': 'supplement', 'label': 'Supplements'},
    {'key': 'materiel', 'label': 'Materiel'},
    {'key': 'hygiene', 'label': 'Hygiene'},
    {'key': 'autre', 'label': 'Autre'},
  ];

  // Cart
  final Map<String, _CartItem> _cart = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _init() async {
    _patientId = _tokenService.userId ?? await _tokenService.getUserId();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _productService.getMarketplace(
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      category: _selectedCategory,
      limit: 100,
    );
    _products = (result['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (mounted) setState(() => _loading = false);
  }

  void _addToCart(Map<String, dynamic> product) {
    final id = product['_id'];
    setState(() {
      if (_cart.containsKey(id)) {
        _cart[id]!.quantity++;
      } else {
        _cart[id] = _CartItem(product: product, quantity: 1);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${product['name']} ajouté au panier'),
      duration: const Duration(seconds: 1),
      backgroundColor: AppColors.softGreen,
    ));
  }

  void _openCart() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Votre panier est vide')));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CartSheet(
        cart: _cart,
        onOrder: _placeOrder,
        onUpdateQty: (id, qty) => setState(() {
          if (qty <= 0) _cart.remove(id); else _cart[id]!.quantity = qty;
        }),
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_patientId == null || _cart.isEmpty) return;
    // Group by pharmacist
    final Map<String, List<_CartItem>> byPharmacist = {};
    for (final item in _cart.values) {
      final pharmId = item.product['pharmacistId'] is Map
          ? item.product['pharmacistId']['_id']
          : item.product['pharmacistId']?.toString() ?? '';
      byPharmacist.putIfAbsent(pharmId, () => []).add(item);
    }

    Navigator.pop(context); // close sheet
    bool anySuccess = false;
    for (final entry in byPharmacist.entries) {
      final data = {
        'pharmacistId': entry.key,
        'items': entry.value.map((ci) => {'productId': ci.product['_id'], 'quantity': ci.quantity}).toList(),
      };
      final result = await _orderService.createOrder(_patientId!, data);
      if (result != null) anySuccess = true;
    }

    if (anySuccess) {
      setState(() => _cart.clear());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Commande passée avec succès !'), backgroundColor: AppColors.softGreen));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la commande'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),
      appBar: AppBar(
        title: const Text('Marketplace', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white, foregroundColor: AppColors.textPrimary, elevation: 0,
        actions: [
          Stack(children: [
            IconButton(onPressed: _openCart, icon: const Icon(Icons.shopping_cart_outlined)),
            if (_cart.isNotEmpty)
              Positioned(right: 4, top: 4, child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: AppColors.softGreen, shape: BoxShape.circle),
                child: Text('${_cart.values.fold(0, (s, c) => s + c.quantity)}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              )),
          ]),
        ],
      ),
      body: Column(children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => _load(),
            decoration: InputDecoration(
              hintText: 'Rechercher un produit...', prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
        ),
        // Category chips
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final selected = _selectedCategory == cat['key'];
              return ChoiceChip(
                label: Text(cat['label'] as String),
                selected: selected,
                selectedColor: AppColors.softGreen.withValues(alpha: 0.2),
                onSelected: (_) { setState(() => _selectedCategory = cat['key'] as String?); _load(); },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Products grid
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.softGreen))
              : _products.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.search_off, size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      const Text('Aucun produit trouvé', style: TextStyle(color: AppColors.textMuted)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.72,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (_, i) => _ProductCard(product: _products[i], onAdd: () => _addToCart(_products[i])),
                      ),
                    ),
        ),
      ]),
    );
  }
}

class _CartItem {
  final Map<String, dynamic> product;
  int quantity;
  _CartItem({required this.product, required this.quantity});
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onAdd;
  const _ProductCard({required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final name = product['name'] ?? '';
    final price = (product['price'] as num?)?.toDouble() ?? 0;
    final stock = (product['stock'] as num?)?.toInt() ?? 0;
    final pharmacist = product['pharmacistId'];
    final pharmacyName = pharmacist is Map ? (pharmacist['nomPharmacie'] ?? '') : '';
    final prescription = product['requiresPrescription'] == true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Image placeholder
        Container(
          height: 80, width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.softGreen.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Center(child: Icon(
            prescription ? Icons.medical_services : Icons.medication,
            size: 36, color: AppColors.softGreen.withValues(alpha: 0.5),
          )),
        ),
        Expanded(child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            if (pharmacyName.isNotEmpty) Text(pharmacyName, style: const TextStyle(fontSize: 10, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Row(children: [
              Text('${price.toStringAsFixed(0)} DA', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.softGreen)),
              const Spacer(),
              if (stock > 0)
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppColors.softGreen, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                )
              else
                const Text('Rupture', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.w600)),
            ]),
          ]),
        )),
      ]),
    );
  }
}

class _CartSheet extends StatefulWidget {
  final Map<String, _CartItem> cart;
  final VoidCallback onOrder;
  final Function(String, int) onUpdateQty;
  const _CartSheet({required this.cart, required this.onOrder, required this.onUpdateQty});
  @override
  State<_CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<_CartSheet> {
  @override
  Widget build(BuildContext context) {
    final items = widget.cart.values.toList();
    final total = items.fold<double>(0, (s, ci) => s + ((ci.product['price'] as num?)?.toDouble() ?? 0) * ci.quantity);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        const Text('Mon Panier', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemBuilder: (_, i) {
              final ci = items[i];
              final id = ci.product['_id'];
              final price = (ci.product['price'] as num?)?.toDouble() ?? 0;
              return Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ci.product['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('${price.toStringAsFixed(0)} DA', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ])),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.remove_circle_outline, size: 20), onPressed: () { widget.onUpdateQty(id, ci.quantity - 1); setState(() {}); }),
                  Text('${ci.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.add_circle_outline, size: 20), onPressed: () { widget.onUpdateQty(id, ci.quantity + 1); setState(() {}); }),
                ]),
                SizedBox(width: 50, child: Text('${(price * ci.quantity).toStringAsFixed(0)} DA', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.end)),
              ]);
            },
          ),
        ),
        const Divider(height: 24),
        Row(children: [
          const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('${total.toStringAsFixed(0)} DA', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.softGreen)),
        ]),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
          onPressed: widget.onOrder,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.softGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: const Text('Commander', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        )),
      ]),
    );
  }
}
