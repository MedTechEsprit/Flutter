import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/data/services/order_service.dart';

class PharmacyOrdersScreen extends StatefulWidget {
  const PharmacyOrdersScreen({super.key});
  @override
  State<PharmacyOrdersScreen> createState() => _PharmacyOrdersScreenState();
}

class _PharmacyOrdersScreenState extends State<PharmacyOrdersScreen> with SingleTickerProviderStateMixin {
  final _service = OrderService();
  final _tokenService = TokenService();
  late TabController _tabCtrl;
  String? _pharmacistId;
  List<Map<String, dynamic>> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    _pharmacistId = _tokenService.userId ?? await _tokenService.getUserId();
    if (_pharmacistId == null) return;
    setState(() => _loading = true);
    _all = await _service.getPharmacistOrders(_pharmacistId!);
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> _filtered(String status) => _all.where((o) => o['status'] == status).toList();

  Future<void> _updateStatus(String orderId, String newStatus) async {
    await _service.updateOrderStatus(orderId, _pharmacistId!, newStatus);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),
      appBar: AppBar(
        title: const Text('Commandes', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white, foregroundColor: AppColors.textPrimary, elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.softGreen, unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.softGreen,
          tabs: [
            Tab(text: 'Nouvelles (${_filtered('pending').length})'),
            Tab(text: 'Confirmées (${_filtered('confirmed').length})'),
            Tab(text: 'Prêtes (${_filtered('ready').length})'),
            Tab(text: 'Terminées (${_filtered('picked_up').length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.softGreen))
          : TabBarView(controller: _tabCtrl, children: [
              _OrderList(orders: _filtered('pending'), onAction: (id) => _updateStatus(id, 'confirmed'), actionLabel: 'Confirmer', actionColor: AppColors.softGreen, onCancel: (id) => _updateStatus(id, 'cancelled')),
              _OrderList(orders: _filtered('confirmed'), onAction: (id) => _updateStatus(id, 'ready'), actionLabel: 'Prêt', actionColor: AppColors.lightBlue),
              _OrderList(orders: _filtered('ready'), onAction: (id) => _updateStatus(id, 'picked_up'), actionLabel: 'Récupéré', actionColor: Colors.purple),
              _OrderList(orders: _filtered('picked_up'), showAction: false),
            ]),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final Function(String)? onAction;
  final Function(String)? onCancel;
  final String actionLabel;
  final Color actionColor;
  final bool showAction;
  const _OrderList({required this.orders, this.onAction, this.onCancel, this.actionLabel = '', this.actionColor = AppColors.softGreen, this.showAction = true});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey.shade300),
        const SizedBox(height: 8),
        const Text('Aucune commande', style: TextStyle(color: AppColors.textMuted)),
      ]));
    }
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (_, i) {
          final o = orders[i];
          final items = (o['items'] as List?) ?? [];
          final patient = o['patientId'];
          final patientName = patient is Map ? '${patient['prenom'] ?? ''} ${patient['nom'] ?? ''}'.trim() : 'Patient';
          final total = (o['totalPrice'] as num?)?.toDouble() ?? 0;
          final pts = (o['pointsAwarded'] as num?)?.toInt() ?? 0;
          final id = o['_id'] ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(backgroundColor: AppColors.softGreen.withValues(alpha: 0.1), child: const Icon(Icons.person, color: AppColors.softGreen, size: 20)),
                const SizedBox(width: 10),
                Expanded(child: Text(patientName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                Text('${total.toStringAsFixed(0)} DA', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.softGreen, fontSize: 15)),
              ]),
              const SizedBox(height: 10),
              ...items.map((it) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  const Icon(Icons.medication, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text('${it['productName'] ?? ''} x${it['quantity'] ?? 1}', style: const TextStyle(fontSize: 13)),
                  const Spacer(),
                  Text('${((it['unitPrice'] as num?)?.toDouble() ?? 0 * ((it['quantity'] as num?)?.toInt() ?? 1)).toStringAsFixed(0)} DA', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ]),
              )),
              if (pts > 0) ...[
                const Divider(height: 16),
                Row(children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text('+$pts points', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.amber)),
                ]),
              ],
              if (showAction) ...[
                const SizedBox(height: 12),
                Row(children: [
                  if (onCancel != null)
                    Expanded(child: OutlinedButton(
                      onPressed: () => onCancel!(id),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                      child: const Text('Annuler'),
                    )),
                  if (onCancel != null) const SizedBox(width: 8),
                  Expanded(child: ElevatedButton(
                    onPressed: () => onAction!(id),
                    style: ElevatedButton.styleFrom(backgroundColor: actionColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: Text(actionLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  )),
                ]),
              ],
            ]),
          );
        },
      ),
    );
  }
}
