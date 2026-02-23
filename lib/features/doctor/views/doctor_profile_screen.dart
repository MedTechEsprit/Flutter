import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/theme/theme_provider.dart';
import 'package:diab_care/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:diab_care/data/services/doctor_service.dart';
import 'package:diab_care/core/services/token_service.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final DoctorService _doctorService = DoctorService();
  final TokenService _tokenService = TokenService();

  bool isAvailable = true;
  bool _isLoading = true;
  bool _isTogglingStatus = false;
  Map<String, dynamic>? _doctorData;
  String? _doctorId;

  @override
  void initState() {
    super.initState();
    _loadDoctorProfile();
  }

  Future<void> _loadDoctorProfile() async {
    try {
      setState(() => _isLoading = true);

      // Get doctor ID from token
      final userData = await _tokenService.getUserData();
      _doctorId = userData?['_id'];

      print('📱 Loading doctor profile for ID: $_doctorId');

      if (_doctorId != null) {
        // Load profile data
        final doctorData = await _doctorService.getDoctorProfile(_doctorId!);

        // Load status separately to get isActive field
        final statusData = await _doctorService.getDoctorStatus(_doctorId!);

        setState(() {
          _doctorData = doctorData;
          // Use isActive from status endpoint if available, otherwise fall back to statutCompte
          if (statusData['isActive'] != null) {
            isAvailable = statusData['isActive'] == true;
          } else {
            isAvailable = doctorData['statutCompte'] == 'ACTIF';
          }
          _isLoading = false;
        });

        print('✅ Doctor profile loaded: ${doctorData['nom']} ${doctorData['prenom']}');
        print('   Status: ${doctorData['statutCompte']}, isActive: $isAvailable');
      }
    } catch (e) {
      print('❌ Error loading doctor profile: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleAvailability() async {
    if (_doctorId == null || _isTogglingStatus) return;

    try {
      setState(() => _isTogglingStatus = true);

      print('🔄 Toggling doctor status...');
      print('   Current status: ${isAvailable ? "Active" : "Inactive"}');

      final updatedData = await _doctorService.toggleDoctorStatus(_doctorId!);

      // Get the new status from response
      final newStatutCompte = updatedData['statutCompte'];
      final newIsActive = newStatutCompte == 'ACTIF';

      setState(() {
        _doctorData = updatedData;
        isAvailable = newIsActive;
        _isTogglingStatus = false;
      });

      print('✅ Status toggled successfully');
      print('   New statutCompte: $newStatutCompte');
      print('   New isActive: $newIsActive');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAvailable
                ? '✅ Profile activated - You are now online'
                : '⚠️ Profile deactivated - You are now offline'
            ),
            backgroundColor: isAvailable ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error toggling status: $e');
      setState(() => _isTogglingStatus = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthViewModel>().logout();
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.softGreen),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Gradient Header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(gradient: AppColors.mainGradient, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32))),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('My Profile', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          PopupMenuButton<String>(
                            icon: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12)
                              ),
                              child: const Icon(Icons.settings, color: Colors.white)
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            onSelected: (value) {
                              if (value == 'logout') {
                                _showLogoutDialog();
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    Icon(Icons.logout, color: Color(0xFFFF6B6B)),
                                    SizedBox(width: 12),
                                    Text('Logout', style: TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ]
                      ),
                      const SizedBox(height: 24),
                      Stack(children: [
                        Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)), child: CircleAvatar(radius: 55, backgroundColor: Colors.white, child: Text(_doctorData != null ? '${_doctorData!['prenom']?[0] ?? 'D'}${_doctorData!['nom']?[0] ?? 'R'}' : 'DR', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.softGreen)))),
                        Positioned(bottom: 4, right: 4, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFB347), Color(0xFFFF9500)]), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)), child: const Icon(Icons.camera_alt, size: 16, color: Colors.white))),
                      ]),
                      const SizedBox(height: 16),
                      Text(_doctorData != null ? 'Dr. ${_doctorData!['prenom'] ?? ''} ${_doctorData!['nom'] ?? ''}' : 'Dr. Loading...', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.verified, color: Colors.white, size: 16), const SizedBox(width: 6), Text(_doctorData?['role'] ?? 'Medecin', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))])),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Contact Info
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: Column(children: [
                      _contactRow(Icons.email_outlined, _doctorData?['email'] ?? 'No email', AppColors.softGreen),
                      const Divider(height: 24),
                      _contactRow(Icons.phone_outlined, _doctorData?['telephone'] ?? 'No phone', AppColors.lightBlue),
                      if (_doctorData?['numeroOrdre'] != null) ...[
                        const Divider(height: 24),
                        _contactRow(Icons.badge_outlined, 'License: ${_doctorData!['numeroOrdre']}', const Color(0xFFFFB347)),
                      ],
                      if (_doctorData?['clinique'] != null) ...[
                        const Divider(height: 24),
                        _contactRow(Icons.business_outlined, _doctorData!['clinique'], AppColors.lavender),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 20),
                  // Availability
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: isAvailable ? [AppColors.softGreen, const Color(0xFF5BC4A8)] : [Colors.grey.shade400, Colors.grey.shade500]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(14)
                        ),
                        child: Icon(
                          isAvailable ? Icons.wifi_tethering : Icons.wifi_off,
                          color: Colors.white,
                          size: 28
                        )
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAvailable ? 'Online (Active)' : 'Offline (Inactive)',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isAvailable ? 'Accepting new patients' : 'Currently unavailable',
                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)
                            )
                          ]
                        )
                      ),
                      if (_isTogglingStatus)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        Switch(
                          value: isAvailable,
                          activeTrackColor: Colors.white.withOpacity(0.4),
                          activeColor: Colors.white,
                          onChanged: (v) => _toggleAvailability(),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  // Stats Grid
                  Row(children: [
                    Expanded(child: _colorStatCard('156', 'Consultations', Icons.medical_services_outlined, AppColors.softGreen, const Color(0xFF5BC4A8))),
                    const SizedBox(width: 12),
                    Expanded(child: _colorStatCard('89%', 'Satisfaction', Icons.thumb_up_outlined, AppColors.lightBlue, const Color(0xFF7AB3D6))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _colorStatCard('24', 'New Requests', Icons.person_add_outlined, const Color(0xFFFFB347), const Color(0xFFFF9500))),
                    const SizedBox(width: 12),
                    Expanded(child: _colorStatCard('18', 'This Week', Icons.calendar_today_outlined, AppColors.lavender, const Color(0xFF9F7AEA))),
                  ]),
                  const SizedBox(height: 24),
                  const Align(alignment: Alignment.centerLeft, child: Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                  const SizedBox(height: 16),
                  _actionBtn(Icons.edit_outlined, 'Edit Profile', 'Update your information', AppColors.softGreen),
                  _actionBtn(Icons.lock_outline, 'Change Password', 'Update your security', AppColors.lightBlue),
                  _actionBtn(Icons.notifications_outlined, 'Notifications', 'Manage your alerts', const Color(0xFFFFB347)),
                  // Dark Mode
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
                    child: Row(children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF6B7280).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.dark_mode_outlined, color: Color(0xFF6B7280))),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)), Text(themeProvider.isDarkMode ? 'Currently enabled' : 'Switch theme', style: TextStyle(color: Colors.grey.shade600, fontSize: 13))])),
                      Switch(value: themeProvider.isDarkMode, activeColor: AppColors.softGreen, onChanged: (_) => themeProvider.toggleTheme()),
                    ]),
                  ),
                  _actionBtn(Icons.help_outline, 'Help & Support', 'Get assistance', const Color(0xFF48BB78)),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactRow(IconData icon, String text, Color color) {
    return Row(children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
      const SizedBox(width: 16),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary))),
    ]);
  }

  Widget _colorStatCard(String value, String label, IconData icon, Color c1, Color c2) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c1, c2]), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: c1.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 28),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9))),
      ]),
    );
  }

  Widget _actionBtn(IconData icon, String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: () {},
      ),
    );
  }
}
