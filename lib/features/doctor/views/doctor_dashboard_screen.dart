import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/core/constants/api_constants.dart';
import 'package:diab_care/core/widgets/animations.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/data/services/appointment_service.dart';
import 'package:diab_care/data/services/notification_service.dart';
import 'package:diab_care/data/services/patient_service.dart';
import 'package:diab_care/data/services/patient_request_service.dart';
import 'package:diab_care/features/ai/views/ai_doctor_screen.dart';
import 'package:diab_care/features/notifications/views/notifications_inbox_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'patient_requests_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final _tokenService = TokenService();
  final _appointmentService = AppointmentService();
  final _patientRequestService = PatientRequestService();
  final _notificationService = NotificationService();

  String _doctorName = '';
  int _totalPatientsCount = 0;
  int _futureAppointmentsCount = 0;
  int _criticalPatientsCount = 0;
  double _doctorRating = 0.0;
  int _unreadAlertsCount = 0;
  List<Map<String, dynamic>> _recentAlerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    try {
      final doctorId = await _tokenService.getUserId();
      final token = await _tokenService.getToken();

      if (doctorId == null || token == null) return;

      // 1. Load Doctor Profile (Name and Rating)
      final profile = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}/medecins/$doctorId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .then((res) => res.statusCode == 200 ? jsonDecode(res.body) : null);

      if (profile != null) {
        setState(() {
          _doctorName = '${profile['prenom'] ?? ''} ${profile['nom'] ?? ''}'
              .trim();
          _doctorRating =
              (profile['rating'] as num?)?.toDouble() ??
              4.8; // Fallback to 4.8 if not set
        });
      }

      // 2. Load Patient Stats (Total and Critical)
      try {
        final patientService = PatientService();
        final patientResponse = await patientService.getDoctorPatients(
          doctorId: doctorId,
        );
        setState(() {
          _totalPatientsCount = patientResponse.total;
          _criticalPatientsCount = patientResponse.statusCounts.critical;
        });
      } catch (_) {}

      // 3. Load Future Appointments
      try {
        final upcomingApts = await _appointmentService
            .getDoctorUpcomingAppointments(doctorId);
        setState(() {
          _futureAppointmentsCount = upcomingApts.length;
        });
      } catch (_) {}

      // 4. Load Alerts/Notifications
      try {
        final notifications = await _notificationService.getNotifications(
          type: 'patient_alert',
          limit: 3,
        );
        final unreadCount = await _notificationService.getUnreadCount();
        setState(() {
          _recentAlerts = notifications;
          _unreadAlertsCount = unreadCount;
        });
      } catch (_) {}

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Error loading doctor data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _openAlerts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsInboxScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFEFF6FF,
      ), // Slightly more colorful blue tint
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══════════════════════════════════════════
            // NEW GRADIENT HEADER (MATCHING SCREENSHOT)
            // ═══════════════════════════════════════════
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF22C1C3), Color(0xFF5B86E5)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Profile Section
                  Row(
                    children: [
                      Container(
                        width: 75,
                        height: 75,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: const Icon(
                            Icons.person_outline,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Hello',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.favorite,
                                  color: Colors.white.withOpacity(0.9),
                                  size: 16,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isLoading ? 'Doctor' : 'Dr. $_doctorName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _openAlerts,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(
                                Icons.notifications_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              if (_unreadAlertsCount > 0)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF6B6B),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _unreadAlertsCount > 9
                                          ? '9+'
                                          : '$_unreadAlertsCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
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
                ],
              ),
            ),

            // ═══════════════════════════════════════════
            // CONTENT
            // ═══════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ═══════════════════════════════════════════
                  // TOP ACTION CARDS (IA & DEMANDES)
                  // ═══════════════════════════════════════════
                  FadeInSlide(
                    index: 0,
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AiDoctorScreen(),
                              ),
                            ),
                            child: _ActionSquareCard(
                              label: 'Clinical AI',
                              icon: Icons.psychology_rounded,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF5B86E5), Color(0xFF74EBD5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PatientRequestsScreen(),
                              ),
                            ).then((_) => _loadDoctorData()),
                            child: _ActionSquareCard(
                              label: 'Requests',
                              icon: Icons.person_add_alt_1_rounded,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF74EBD5), Color(0xFFFDBB2D)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ═══════════════════════════════════════════
                  // KEY PERFORMANCE INDICATORS
                  // ═══════════════════════════════════════════
                  FadeInSlide(
                    index: 1,
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.9,
                      children: [
                        _KpiCard(
                          title: 'Total Patients',
                          value: '$_totalPatientsCount',
                          valueColor: const Color(0xFF5B86E5),
                          icon: Icons.people_alt_rounded,
                          iconColor: const Color(0xFF5B86E5),
                          iconBgColor: const Color(0xFFE8EAF6),
                        ),
                        _KpiCard(
                          title: 'Upcoming Visits',
                          value: '$_futureAppointmentsCount',
                          valueColor: const Color(0xFF22C1C3),
                          icon: Icons.calendar_today_rounded,
                          iconColor: const Color(0xFF22C1C3),
                          iconBgColor: const Color(0xFFE0F7FA),
                        ),
                        _KpiCard(
                          title: 'Critical Cases',
                          value: '$_criticalPatientsCount',
                          valueColor: const Color(0xFFFF6B6B),
                          icon: Icons.warning_amber_rounded,
                          iconColor: const Color(0xFFFF6B6B),
                          iconBgColor: const Color(0xFFFFF1F1),
                        ),
                        _KpiCard(
                          title: 'Satisfaction',
                          value: '${_doctorRating.toStringAsFixed(1)}',
                          valueColor: const Color(0xFFFDBB2D),
                          icon: Icons.star_rounded,
                          iconColor: const Color(0xFFFDBB2D),
                          iconBgColor: const Color(0xFFFFF9E6),
                        ),
                      ],
                    ),
                  ),

                  // Trends Card (Refined)
                  FadeInSlide(
                    index: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Patient Trends',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        Text(
                                          'Monthly growth',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blueGrey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD1FAE5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.trending_up,
                                            size: 14,
                                            color: Color(0xFF059669),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            '+12%',
                                            style: TextStyle(
                                              color: Color(0xFF059669),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                // Mock Bar Chart Visual
                                Container(
                                  height: 160,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _buildMockBar('Mon', 45, [
                                        const Color(0xFF74EBD5),
                                        const Color(0xFF22C1C3),
                                      ]),
                                      _buildMockBar('Tue', 75, [
                                        const Color(0xFF74EBD5),
                                        const Color(0xFF22C1C3),
                                      ]),
                                      _buildMockBar('Wed', 55, [
                                        const Color(0xFF74EBD5),
                                        const Color(0xFF22C1C3),
                                      ]),
                                      _buildMockBar('Thu', 95, [
                                        const Color(0xFFACB6E5),
                                        const Color(0xFF5B86E5),
                                      ]),
                                      _buildMockBar('Fri', 65, [
                                        const Color(0xFFACB6E5),
                                        const Color(0xFF5B86E5),
                                      ]),
                                      _buildMockBar('Sat', 85, [
                                        const Color(0xFFACB6E5),
                                        const Color(0xFF5B86E5),
                                      ]),
                                      _buildMockBar('Sun', 50, [
                                        const Color(0xFFFDBB2D),
                                        const Color(0xFFF59E0B),
                                      ]),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Alerts Section Header
                  FadeInSlide(
                    index: 6,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B6B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFFF6B6B),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Critical Alerts',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: _openAlerts,
                          child: Text('View all ($_unreadAlertsCount)'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_recentAlerts.isEmpty)
                    FadeInSlide(
                      index: 6,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.backgroundPrimary,
                          ),
                        ),
                        child: Text(
                          _isLoading
                              ? 'Loading alerts...'
                              : 'No patient alerts right now.',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._recentAlerts.asMap().entries.map((entry) {
                      final item = entry.value;
                      final severity = (item['severity'] ?? 'info').toString();
                      final color = _severityColor(severity);
                      final icon = _severityIcon(severity);
                      final title = (item['title'] ?? 'Patient alert')
                          .toString();
                      final message = (item['message'] ?? '').toString();
                      final timestamp = (item['timestamp'] ?? '').toString();
                      return FadeInSlide(
                        index: 6 + entry.key,
                        child: _buildAlertCard(
                          title,
                          message,
                          _formatRelativeTime(timestamp),
                          color,
                          icon,
                        ),
                      );
                    }),

                  const SizedBox(height: 40),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockBar(String day, double height, List<Color> colors) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 22,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: colors[0].withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          day,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.blueGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFFF6B6B);
      case 'warning':
        return AppColors.softOrange;
      default:
        return AppColors.primaryBlue;
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Icons.warning_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _formatRelativeTime(String rawTimestamp) {
    if (rawTimestamp.isEmpty) {
      return 'Just now';
    }

    final parsed = DateTime.tryParse(rawTimestamp)?.toLocal();
    if (parsed == null) {
      return 'Recent';
    }

    final diff = DateTime.now().difference(parsed);
    if (diff.inMinutes < 1) {
      return 'Just now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} h ago';
    }
    return '${diff.inDays} d ago';
  }

  Widget _buildAlertCard(
    String name,
    String message,
    String time,
    Color color,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Colored left accent
          Container(
            width: 4,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          message,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      time,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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

class _ActionSquareCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;

  const _ActionSquareCard({
    required this.label,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 90,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradient.colors[0].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.valueColor,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
