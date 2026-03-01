import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/features/auth/services/auth_service.dart';
import 'package:diab_care/features/chat/views/chat_screen.dart';
import 'package:diab_care/features/chat/viewmodels/chat_viewmodel.dart';
import 'package:provider/provider.dart';

class MyDoctorsScreen extends StatefulWidget {
  const MyDoctorsScreen({super.key});
  @override
  State<MyDoctorsScreen> createState() => _MyDoctorsScreenState();
}

class _MyDoctorsScreenState extends State<MyDoctorsScreen> {
  final _tokenService = TokenService();
  List<Map<String, dynamic>> _doctors = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final patientId = _tokenService.userId ?? await _tokenService.getUserId();
    if (patientId == null) return;
    setState(() => _loading = true);
    try {
      final token = await AuthService().getToken();
      final res = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/medecins/patient/$patientId/my-doctors'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        _doctors = List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint('❌ MyDoctors: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _openChat(Map<String, dynamic> doctor) async {
    final chatVm = context.read<ChatViewModel>();
    final conv = await chatVm.startConversation(doctor['_id']);
    if (conv != null && mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ChatDetailScreen(conversation: conv),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),
      appBar: AppBar(
        title: const Text('Mes Médecins', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white, foregroundColor: AppColors.textPrimary, elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.softGreen))
          : _doctors.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.medical_services_outlined, size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  const Text('Aucun médecin', style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
                  const SizedBox(height: 4),
                  const Text('Vous n\'êtes patient d\'aucun médecin', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _doctors.length,
                    itemBuilder: (_, i) {
                      final d = _doctors[i];
                      final name = 'Dr. ${d['prenom'] ?? ''} ${d['nom'] ?? ''}'.trim();
                      final specialite = d['specialite'] ?? '';
                      final clinique = d['clinique'] ?? '';
                      final phone = d['telephone'] ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                        ),
                        child: Row(children: [
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [AppColors.softGreen, AppColors.softGreen.withValues(alpha: 0.7)]),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(child: Text(
                              name.length > 4 ? name.substring(4, 5).toUpperCase() : 'D',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            )),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            if (specialite.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(specialite, style: const TextStyle(fontSize: 12, color: AppColors.softGreen, fontWeight: FontWeight.w500)),
                            ],
                            if (clinique.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(clinique, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ])),
                          Column(children: [
                            IconButton(
                              onPressed: () => _openChat(d),
                              icon: const Icon(Icons.chat_bubble_outline, color: AppColors.softGreen, size: 22),
                            ),
                            if (phone.isNotEmpty)
                              Text(phone, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
                          ]),
                        ]),
                      );
                    },
                  ),
                ),
    );
  }
}
