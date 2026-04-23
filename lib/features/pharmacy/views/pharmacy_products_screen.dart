import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/data/services/product_service.dart';

class PharmacyProductsScreen extends StatefulWidget {
  const PharmacyProductsScreen({super.key});
  @override
  State<PharmacyProductsScreen> createState() => _PharmacyProductsScreenState();
}

class _PharmacyProductsScreenState extends State<PharmacyProductsScreen> {
  final _service = ProductService();
  final _tokenService = TokenService();
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  String? _pharmacistId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _pharmacistId = _tokenService.userId ?? await _tokenService.getUserId();
    if (_pharmacistId == null) return;
    setState(() => _loading = true);
    _products = await _service.getMyProducts(_pharmacistId!);
    if (mounted) setState(() => _loading = false);
  }

  void _openAddEdit({Map<String, dynamic>? product}) async {
    final result = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => _AddEditProductScreen(pharmacistId: _pharmacistId!, product: product),
    ));
    if (result == true) _load();
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Supprimer ce produit ?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (confirm == true) {
      await _service.deleteProduct(id, _pharmacistId!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),
      appBar: AppBar(
        title: const Text('Mes Produits', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white, foregroundColor: AppColors.textPrimary, elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEdit(),
        backgroundColor: AppColors.softGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ajouter', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.softGreen))
          : _products.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text('Aucun produit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  const Text('Ajoutez vos premiers produits', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.length,
                    itemBuilder: (_, i) => _ProductCard(
                      product: _products[i],
                      onEdit: () => _openAddEdit(product: _products[i]),
                      onDelete: () => _delete(_products[i]['_id']),
                    ),
                  ),
                ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ProductCard({required this.product, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final name = product['name'] ?? '';
    final price = (product['price'] as num?)?.toDouble() ?? 0;
    final stock = (product['stock'] as num?)?.toInt() ?? 0;
    final category = product['category'] ?? '';
    final catLabel = {'medicament': 'Medicament', 'supplement': 'Supplement', 'materiel': 'Materiel', 'hygiene': 'Hygiene', 'autre': 'Autre'}[category] ?? category;
    final sold = (product['totalSold'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.softGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.medication, color: AppColors.softGreen, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(catLabel, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ])),
            Text('${price.toStringAsFixed(0)} DA', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.softGreen)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _tag(Icons.inventory_2, 'Stock: $stock', stock > 0 ? AppColors.softGreen : Colors.red),
            const SizedBox(width: 8),
            _tag(Icons.shopping_bag, 'Vendus: $sold', AppColors.lightBlue),
            const Spacer(),
            IconButton(onPressed: onEdit, icon: const Icon(Icons.edit, size: 20, color: AppColors.textSecondary)),
            IconButton(onPressed: onDelete, icon: const Icon(Icons.delete, size: 20, color: Colors.red)),
          ]),
        ],
      ),
    );
  }

  Widget _tag(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// ADD / EDIT PRODUCT SCREEN
// ══════════════════════════════════════════════════════════════════

class _AddEditProductScreen extends StatefulWidget {
  final String pharmacistId;
  final Map<String, dynamic>? product;
  const _AddEditProductScreen({required this.pharmacistId, this.product});
  @override
  State<_AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<_AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ProductService();
  late TextEditingController _name, _description, _price, _stock, _dosage, _manufacturer, _form;
  String _category = 'medicament';
  bool _requiresPrescription = false;
  bool _saving = false;
  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?['name'] ?? '');
    _description = TextEditingController(text: p?['description'] ?? '');
    _price = TextEditingController(text: p != null ? '${(p['price'] as num?)?.toInt() ?? ''}' : '');
    _stock = TextEditingController(text: p != null ? '${(p['stock'] as num?)?.toInt() ?? ''}' : '');
    _dosage = TextEditingController(text: p?['dosage'] ?? '');
    _manufacturer = TextEditingController(text: p?['manufacturer'] ?? '');
    _form = TextEditingController(text: p?['form'] ?? '');
    _category = p?['category'] ?? 'medicament';
    _requiresPrescription = p?['requiresPrescription'] ?? false;
  }

  @override
  void dispose() {
    _name.dispose(); _description.dispose(); _price.dispose(); _stock.dispose();
    _dosage.dispose(); _manufacturer.dispose(); _form.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'name': _name.text.trim(),
      'description': _description.text.trim(),
      'price': double.tryParse(_price.text) ?? 0,
      'stock': int.tryParse(_stock.text) ?? 0,
      'category': _category,
      'requiresPrescription': _requiresPrescription,
      'dosage': _dosage.text.trim(),
      'manufacturer': _manufacturer.text.trim(),
      'form': _form.text.trim(),
    };

    bool ok;
    if (_isEdit) {
      ok = await _service.updateProduct(widget.product!['_id'], widget.pharmacistId, data);
    } else {
      ok = (await _service.createProduct(widget.pharmacistId, data)) != null;
    }
    if (mounted) {
      setState(() => _saving = false);
      if (ok) Navigator.pop(context, true);
      else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la sauvegarde')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier le produit' : 'Ajouter un produit', style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white, foregroundColor: AppColors.textPrimary, elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _field('Nom *', _name, validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
            _field('Description', _description, maxLines: 3),
            Row(children: [
              Expanded(child: _field('Prix (DA) *', _price, keyboard: TextInputType.number, validator: (v) => v == null || v.isEmpty ? 'Requis' : null)),
              const SizedBox(width: 12),
              Expanded(child: _field('Stock', _stock, keyboard: TextInputType.number)),
            ]),
            const SizedBox(height: 8),
            const Text('Categorie', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: ['medicament', 'supplement', 'materiel', 'hygiene', 'autre'].map((c) {
              final selected = _category == c;
              return ChoiceChip(
                label: Text(c[0].toUpperCase() + c.substring(1)),
                selected: selected,
                selectedColor: AppColors.softGreen.withValues(alpha: 0.2),
                onSelected: (_) => setState(() => _category = c),
              );
            }).toList()),
            const SizedBox(height: 12),
            _field('Dosage', _dosage),
            _field('Fabricant', _manufacturer),
            _field('Forme (comprimes, sirop...)', _form),
            SwitchListTile(
              title: const Text('Necessite une ordonnance'),
              value: _requiresPrescription,
              activeColor: AppColors.softGreen,
              onChanged: (v) => setState(() => _requiresPrescription = v),
            ),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.softGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_isEdit ? 'Modifier' : 'Ajouter', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1, TextInputType? keyboard, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl, maxLines: maxLines, keyboardType: keyboard, validator: validator,
        decoration: InputDecoration(
          labelText: label, filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.softGreen)),
        ),
      ),
    );
  }
}
