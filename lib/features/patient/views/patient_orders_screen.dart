import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/data/services/order_service.dart';

class PatientOrdersScreen extends StatefulWidget {
  const PatientOrdersScreen({super.key});
  @override
  State<PatientOrdersScreen> createState() => _PatientOrdersScreenState();
}

class _PatientOrdersScreenState extends State<PatientOrdersScreen> {
  final _service = OrderService();
  final _tokenService = TokenService();
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _patientId;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    _patientId = _tokenService.userId ?? await _tokenService.getUserId();
    if (_patientId == null) return;
    setState(() => _loading = true);
    _orders = await _service.getMyOrders(_patientId!);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _cancel(String orderId) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Annuler cette commande ?'),
      content: const Text('Seules les commandes en attente peuvent être annulées.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Oui, annuler', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (confirm == true) {
      await _service.cancelOrder(orderId, _patientId!);
      _load();
    }
  }

  Color _statusColor(String s) => switch(s) {
    'pending' => Colors.orange, 'confirmed' => AppColors.lightBlue,
    'ready' => AppColors.softGreen, 'picked_up' => Colors.purple,
    'cancelled' => Colors.red, _ => AppColors.textMuted,
  };

  String _statusLabel(String s) => switch(s) {
    'pending' => 'En attente', 'confirmed' => 'Confirmée',
    'ready' => 'Prête', 'picked_up' => 'Récupérée',
    'cancelled' => 'Annulée', _ => s,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),
      appBar: AppBar(
        title: const Text('Mes Commandes', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white, foregroundColor: AppColors.textPrimary, elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.softGreen))
          : _orders.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  const Text('Aucune commande', style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (_, i) {
                      final o = _orders[i];
                      final status = o['status'] ?? '';
                      final items = (o['items'] as List?) ?? [];
                      final total = (o['totalPrice'] as num?)?.toDouble() ?? 0;
                      final pharmacist = o['pharmacistId'];
                      final pharmacyName = pharmacist is Map ? (pharmacist['nomPharmacie'] ?? 'Pharmacie') : 'Pharmacie';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: _statusColor(status).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                              child: Icon(Icons.local_pharmacy, color: _statusColor(status), size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(pharmacyName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: _statusColor(status).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                child: Text(_statusLabel(status), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(status))),
                              ),
                            ])),
                            Text('${total.toStringAsFixed(0)} DA', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.softGreen)),
                          ]),
                          const SizedBox(height: 10),
                          ...items.map((it) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(children: [
                              const Icon(Icons.medication, size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 6),
                              Expanded(child: Text('${it['productName'] ?? ''} x${it['quantity'] ?? 1}', style: const TextStyle(fontSize: 13))),
                            ]),
                          )),
                          if (status == 'pending') ...[
                            const SizedBox(height: 10),
                            SizedBox(width: double.infinity, child: OutlinedButton(
                              onPressed: () => _cancel(o['_id']),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                              child: const Text('Annuler la commande'),
                            )),
                          ],
                        ]),
                      );
                    },
                  ),
                ),
    );
  }
}
