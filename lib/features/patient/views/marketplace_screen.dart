import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/data/services/product_service.dart';
import 'package:diab_care/data/services/order_service.dart';
import 'package:diab_care/data/services/medication_request_patient_service.dart';
import 'package:diab_care/core/widgets/animations.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});
  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _productService = ProductService();
  final _orderService = OrderService();
  final _requestService = MedicationRequestPatientService();
  final _tokenService = TokenService();
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  String? _selectedCategory;
  String? _patientId;

  final _categories = [
    {'key': null, 'label': 'Tous', 'icon': Icons.grid_view_rounded},
    {
      'key': 'medicament',
      'label': 'Médicaments',
      'icon': Icons.medication_rounded,
    },
    {
      'key': 'supplement',
      'label': 'Suppléments',
      'icon': Icons.science_rounded,
    },
    {
      'key': 'materiel',
      'label': 'Matériel',
      'icon': Icons.medical_services_rounded,
    },
    {'key': 'hygiene', 'label': 'Hygiène', 'icon': Icons.clean_hands_rounded},
    {'key': 'autre', 'label': 'Autre', 'icon': Icons.more_horiz_rounded},
  ];

  final Map<String, _CartItem> _cart = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text('${product['name']} ajouté au panier'),
          ],
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.softGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _openCart() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Votre panier est vide'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CartSheet(
        cart: _cart,
        onOrder: _placeOrder,
        onDemand: _sendDemandRequests,
        onUpdateQty: (id, qty) => setState(() {
          if (qty <= 0)
            _cart.remove(id);
          else
            _cart[id]!.quantity = qty;
        }),
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_patientId == null || _cart.isEmpty) return;
    final Map<String, List<_CartItem>> byPharmacist = {};
    for (final item in _cart.values) {
      final pharmId = item.product['pharmacistId'] is Map
          ? item.product['pharmacistId']['_id']
          : item.product['pharmacistId']?.toString() ?? '';
      byPharmacist.putIfAbsent(pharmId, () => []).add(item);
    }

    Navigator.pop(context);
    bool anySuccess = false;
    for (final entry in byPharmacist.entries) {
      final data = {
        'pharmacistId': entry.key,
        'items': entry.value
            .map(
              (ci) => {'productId': ci.product['_id'], 'quantity': ci.quantity},
            )
            .toList(),
      };
      final result = await _orderService.createOrder(_patientId!, data);
      if (result != null) anySuccess = true;
    }

    if (anySuccess) {
      setState(() => _cart.clear());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.celebration_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Commande passée avec succès !'),
              ],
            ),
            backgroundColor: AppColors.softGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erreur lors de la commande'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _sendDemandRequests() async {
    if (_patientId == null || _cart.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Veuillez vous reconnecter avant d\'envoyer une demande.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      return;
    }

    Navigator.pop(context);

    final noteController = TextEditingController();
    bool urgent = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Envoyer une demande'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Message (optionnel)',
                    hintText: 'Ex: besoin urgent, alternatives acceptees',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Urgent'),
                    const Spacer(),
                    Switch(
                      value: urgent,
                      onChanged: (v) => setModalState(() => urgent = v),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Envoyer'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) return;

    final urgencyLevel = urgent ? 'urgent' : 'normal';
    int successCount = 0;
    String? lastError;

    for (final item in _cart.values) {
      final product = item.product;
      final pharmId = product['pharmacistId'] is Map
          ? product['pharmacistId']['_id']?.toString() ?? ''
          : product['pharmacistId']?.toString() ?? '';

      if (pharmId.isEmpty) continue;

      final nameValue = (product['name']?.toString() ?? '').trim();
      final dosageValue = (product['dosage']?.toString() ?? '').trim();

      final result = await _requestService.createMedicationRequest(
        medicationName: nameValue.isNotEmpty ? nameValue : 'Demande',
        dosage: dosageValue.isNotEmpty ? dosageValue : 'N/A',
        quantity: item.quantity,
        format: product['form']?.toString(),
        urgencyLevel: urgencyLevel,
        patientNote: noteController.text.trim().isEmpty
            ? null
            : noteController.text.trim(),
        targetPharmacyIds: [pharmId],
      );

      if (result['success'] == true) {
        successCount++;
      } else {
        lastError = result['message']?.toString() ?? 'Erreur lors de l\'envoi';
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            successCount > 0
                ? 'Demande envoyee a $successCount pharmacie(s).'
                : (lastError ?? 'Aucune demande envoyee'),
          ),
          backgroundColor: successCount > 0 ? AppColors.softGreen : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = _cart.values.fold(0, (s, c) => s + c.quantity);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ═══════════════════════════════════════════
          // GRADIENT HEADER
          // ═══════════════════════════════════════════
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.only(bottom: 20),
                  decoration: const BoxDecoration(
                    gradient: AppColors.mainGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Marketplace',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      Text(
                                        'Produits de santé',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // Cart button
                              GestureDetector(
                                onTap: _openCart,
                                child: Container(
                                  padding: const EdgeInsets.all(11),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.25),
                                        Colors.white.withOpacity(0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      const Icon(
                                        Icons.shopping_cart_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                      if (cartCount > 0)
                                        Positioned(
                                          right: -8,
                                          top: -8,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFFFF6B6B),
                                                  Color(0xFFFC5252),
                                                ],
                                              ),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Text(
                                              '$cartCount',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          // Search bar
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (_) => _load(),
                              decoration: InputDecoration(
                                hintText: 'Rechercher un produit...',
                                hintStyle: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: AppColors.softGreen,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Decorative circles
                Positioned(
                  top: -15,
                  right: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 25,
                  left: -15,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Category chips
          SliverToBoxAdapter(
            child: FadeInSlide(
              index: 0,
              child: SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat = _categories[i];
                    final selected = _selectedCategory == cat['key'];
                    return GestureDetector(
                      onTap: () {
                        setState(
                          () => _selectedCategory = cat['key'] as String?,
                        );
                        _load();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: selected
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF7DDAB9),
                                    Color(0xFF5BC4A8),
                                  ],
                                )
                              : null,
                          color: selected ? null : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: selected
                              ? null
                              : Border.all(color: AppColors.border),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: AppColors.softGreen.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat['icon'] as IconData,
                              size: 16,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat['label'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Products grid
          _loading
              ? const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.softGreen,
                    ),
                  ),
                )
              : _products.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.softGreen.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Aucun produit trouvé',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.70,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => FadeInSlide(
                        index: 1 + (i ~/ 2),
                        child: _ProductCard(
                          product: _products[i],
                          onAdd: () => _addToCart(_products[i]),
                        ),
                      ),
                      childCount: _products.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _CartItem {
  final Map<String, dynamic> product;
  int quantity;
  _CartItem({required this.product, required this.quantity});
}

// ─────────────────────────────────────
// Product card — redesigned with modern look
// ─────────────────────────────────────
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
    final pharmacyName = pharmacist is Map
        ? (pharmacist['nomPharmacie'] ?? '')
        : '';
    final prescription = product['requiresPrescription'] == true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder with gradient
          Container(
            height: 85,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (prescription ? AppColors.warmPeach : AppColors.softGreen)
                      .withOpacity(0.12),
                  (prescription ? AppColors.warmPeach : AppColors.softGreen)
                      .withOpacity(0.04),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    prescription
                        ? Icons.medical_services_rounded
                        : Icons.medication_rounded,
                    size: 38,
                    color:
                        (prescription
                                ? AppColors.warmPeach
                                : AppColors.softGreen)
                            .withOpacity(0.5),
                  ),
                ),
                if (prescription)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warmPeach.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Rx',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warmPeach,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  if (pharmacyName.isNotEmpty)
                    Text(
                      pharmacyName,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.softGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${price.toStringAsFixed(0)} DA',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.softGreen,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (stock > 0)
                        GestureDetector(
                          onTap: onAdd,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7DDAB9), Color(0xFF5BC4A8)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.softGreen.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Rupture',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────
// Cart bottom sheet — redesigned
// ─────────────────────────────────────
class _CartSheet extends StatefulWidget {
  final Map<String, _CartItem> cart;
  final VoidCallback onOrder;
  final VoidCallback onDemand;
  final Function(String, int) onUpdateQty;
  const _CartSheet({
    required this.cart,
    required this.onOrder,
    required this.onDemand,
    required this.onUpdateQty,
  });
  @override
  State<_CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<_CartSheet> {
  @override
  Widget build(BuildContext context) {
    final items = widget.cart.values.toList();
    final total = items.fold<double>(
      0,
      (s, ci) =>
          s + ((ci.product['price'] as num?)?.toDouble() ?? 0) * ci.quantity,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.softGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shopping_cart_rounded,
                  color: AppColors.softGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Mon Panier',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 20),
              itemBuilder: (_, i) {
                final ci = items[i];
                final id = ci.product['_id'];
                final price = (ci.product['price'] as num?)?.toDouble() ?? 0;
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ci.product['name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${price.toStringAsFixed(0)} DA',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.backgroundPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.remove_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              widget.onUpdateQty(id, ci.quantity - 1);
                              setState(() {});
                            },
                          ),
                          Text(
                            '${ci.quantity}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_rounded,
                              size: 18,
                              color: AppColors.softGreen,
                            ),
                            onPressed: () {
                              widget.onUpdateQty(id, ci.quantity + 1);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        '${(price * ci.quantity).toStringAsFixed(0)} DA',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.softGreen,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${total.toStringAsFixed(0)} DA',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.softGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: widget.onOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7DDAB9), Color(0xFF5BC4A8)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.softGreen.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Commander',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: widget.onDemand,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.softGreen,
                      side: const BorderSide(color: AppColors.softGreen),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.help_outline_rounded),
                    label: const Text(
                      'Demander disponibilite',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
