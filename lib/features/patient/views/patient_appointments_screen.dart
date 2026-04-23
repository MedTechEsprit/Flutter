import 'package:flutter/material.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/data/models/appointment_model.dart';
import 'package:diab_care/data/services/appointment_service.dart';

enum _PatientAppointmentFilter { upcoming, past, cancelled, modified }

class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  State<PatientAppointmentsScreen> createState() =>
      _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
  final _appointmentService = AppointmentService();
  final _tokenService = TokenService();

  bool _loading = true;
  String? _error;
  String? _patientId;
  String _selectedView = 'Liste';
  DateTime _selectedDate = DateTime.now();
  _PatientAppointmentFilter _selectedFilter = _PatientAppointmentFilter.upcoming;

  List<AppointmentModel> _appointments = [];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final patientId = _tokenService.userId ?? await _tokenService.getUserId();
      if (patientId == null) {
        throw Exception('Patient ID introuvable');
      }

      final appointments = await _appointmentService.getPatientAppointments(patientId);
      appointments.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      if (!mounted) return;
      setState(() {
        _patientId = patientId;
        _appointments = appointments;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<AppointmentModel> get _filteredAppointments {
    Iterable<AppointmentModel> filtered = _appointments.where(_matchesFilter);

    if (_selectedView == 'Calendrier') {
      filtered = filtered.where(
        (apt) =>
            apt.dateTime.year == _selectedDate.year &&
            apt.dateTime.month == _selectedDate.month &&
            apt.dateTime.day == _selectedDate.day,
      );
    }

    final list = filtered.toList();
    list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }

  bool _matchesFilter(AppointmentModel apt) {
    switch (_selectedFilter) {
      case _PatientAppointmentFilter.upcoming:
        return _isUpcoming(apt);
      case _PatientAppointmentFilter.past:
        return _isPast(apt);
      case _PatientAppointmentFilter.cancelled:
        return apt.status == AppointmentStatus.CANCELLED;
      case _PatientAppointmentFilter.modified:
        return _isModified(apt);
    }
  }

  bool _isUpcoming(AppointmentModel apt) {
    if (apt.status == AppointmentStatus.CANCELLED ||
        apt.status == AppointmentStatus.COMPLETED) {
      return false;
    }
    return apt.dateTime.isAfter(DateTime.now());
  }

  bool _isPast(AppointmentModel apt) {
    if (apt.status == AppointmentStatus.CANCELLED) {
      return false;
    }
    return apt.status == AppointmentStatus.COMPLETED ||
        apt.dateTime.isBefore(DateTime.now());
  }

  bool _isModified(AppointmentModel apt) {
    if (apt.status == AppointmentStatus.CANCELLED) return false;
    return apt.updatedAt.difference(apt.createdAt).inMinutes >= 5;
  }

  int _countFor(_PatientAppointmentFilter filter) {
    return _appointments.where((apt) {
      switch (filter) {
        case _PatientAppointmentFilter.upcoming:
          return _isUpcoming(apt);
        case _PatientAppointmentFilter.past:
          return _isPast(apt);
        case _PatientAppointmentFilter.cancelled:
          return apt.status == AppointmentStatus.CANCELLED;
        case _PatientAppointmentFilter.modified:
          return _isModified(apt);
      }
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: RefreshIndicator(
        onRefresh: _loadAppointments,
        color: AppColors.softGreen,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            _buildHeader(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: _buildViewToggle(),
              ),
            ),
            if (_selectedView == 'Calendrier')
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: _buildCalendar(),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: _buildFilterRow(),
              ),
            ),
            _buildBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.mainGradient,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: Colors.white,
                      tooltip: 'Retour',
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mes rendez-vous',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_appointments.length} rendez-vous au total',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: const Icon(
                    Icons.event_note_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          _buildViewBtn('Liste', Icons.view_list_rounded),
          _buildViewBtn('Calendrier', Icons.calendar_month_rounded),
        ],
      ),
    );
  }

  Widget _buildViewBtn(String label, IconData icon) {
    final selected = _selectedView == label;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _selectedView = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.softGreen.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? AppColors.softGreen : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.softGreen : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(_PatientAppointmentFilter.upcoming, 'A venir'),
          _buildFilterChip(_PatientAppointmentFilter.past, 'Passe'),
          _buildFilterChip(_PatientAppointmentFilter.cancelled, 'Annule'),
          _buildFilterChip(_PatientAppointmentFilter.modified, 'Modifie'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(_PatientAppointmentFilter filter, String label) {
    final selected = _selectedFilter == filter;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        onSelected: (_) => setState(() => _selectedFilter = filter),
        backgroundColor: Colors.white,
        selectedColor: AppColors.softGreen.withOpacity(0.18),
        side: BorderSide(
          color: selected ? AppColors.softGreen : Colors.grey.shade300,
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.softGreen.withOpacity(0.35)
                    : AppColors.softGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_countFor(filter)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.softGreen),
        ),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 56),
                const SizedBox(height: 12),
                const Text(
                  'Erreur de chargement',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  _error ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_filteredAppointments.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy_outlined, color: Colors.grey.shade300, size: 56),
              const SizedBox(height: 8),
              const Text(
                'Aucun rendez-vous dans cette vue',
                style: TextStyle(color: AppColors.textMuted, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final apt = _filteredAppointments[index];
          return _buildAppointmentCard(apt);
        }, childCount: _filteredAppointments.length),
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel apt) {
    final statusColor = _statusColor(apt.status);
    final typeColor = apt.type == AppointmentType.ONLINE
        ? AppColors.accentBlue
        : AppColors.softGreen;

    final canCancel = _patientId != null && _isUpcoming(apt);
    final canConfirm =
      _patientId != null &&
      _isUpcoming(apt) &&
      apt.status == AppointmentStatus.PENDING &&
      (apt.createdByRole ?? '').toUpperCase() == 'MEDECIN';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: AppColors.cardShadow,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showAppointmentDetails(apt),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 16, color: AppColors.accentBlue),
                        const SizedBox(height: 4),
                        Text(
                          apt.formattedTime,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.accentBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          apt.doctorName?.isNotEmpty == true
                              ? apt.doctorName!
                              : 'Dr. Inconnu',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          apt.formattedDate,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                apt.type.displayName,
                                style: TextStyle(
                                  color: typeColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                _statusLabel(apt.status),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppColors.textLight),
                    onSelected: (value) async {
                      if (value == 'details') {
                        _showAppointmentDetails(apt);
                      } else if (value == 'confirm') {
                        await _confirmAppointment(apt);
                      } else if (value == 'cancel') {
                        await _cancelAppointment(apt);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_outlined, size: 18),
                            SizedBox(width: 10),
                            Text('Details'),
                          ],
                        ),
                      ),
                      if (canConfirm)
                        const PopupMenuItem(
                          value: 'confirm',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline, size: 18, color: AppColors.statusGood),
                              SizedBox(width: 10),
                              Text('Confirmer', style: TextStyle(color: AppColors.statusGood)),
                            ],
                          ),
                        ),
                      if (canCancel)
                        const PopupMenuItem(
                          value: 'cancel',
                          child: Row(
                            children: [
                              Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                              SizedBox(width: 10),
                              Text('Annuler', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if ((apt.notes ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    apt.notes!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancelAppointment(AppointmentModel apt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler le rendez-vous'),
        content: const Text('Voulez-vous vraiment annuler ce rendez-vous ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _appointmentService.cancelAppointment(apt.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rendez-vous annule'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadAppointments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmAppointment(AppointmentModel apt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer le rendez-vous'),
        content: const Text('Confirmer votre présence pour ce rendez-vous ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusGood,
              foregroundColor: Colors.white,
            ),
            child: const Text('Oui, confirmer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _appointmentService.confirmByPatient(apt.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rendez-vous confirme. Votre medecin a ete notifie.'),
          backgroundColor: AppColors.statusGood,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadAppointments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAppointmentDetails(AppointmentModel apt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Details du rendez-vous',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _detailRow('Medecin', apt.doctorName ?? 'Inconnu'),
            if ((apt.doctorSpecialty ?? '').isNotEmpty)
              _detailRow('Specialite', apt.doctorSpecialty!),
            _detailRow('Date', apt.formattedDate),
            _detailRow('Heure', apt.formattedTime),
            _detailRow('Type', apt.type.displayName),
            _detailRow('Statut', _statusLabel(apt.status)),
            if ((apt.notes ?? '').isNotEmpty) _detailRow('Notes', apt.notes!),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final monthStart = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    final firstWeekdayOffset = monthStart.weekday - 1;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month - 1,
                      1,
                    );
                  });
                },
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '${_monthName(_selectedDate.month)} ${_selectedDate.year}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month + 1,
                      1,
                    );
                  });
                },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              'L',
              'M',
              'M',
              'J',
              'V',
              'S',
              'D',
            ].map((d) => SizedBox(width: 30, child: Center(child: Text(d)))).toList(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...List.generate(
                firstWeekdayOffset,
                (_) => const SizedBox(width: 30, height: 30),
              ),
              ...List.generate(daysInMonth, (index) {
                final day = index + 1;
                final date = DateTime(_selectedDate.year, _selectedDate.month, day);
                final selected =
                    date.year == _selectedDate.year &&
                    date.month == _selectedDate.month &&
                    date.day == _selectedDate.day;

                final hasAppointments = _appointments.any(
                  (apt) =>
                      apt.dateTime.year == date.year &&
                      apt.dateTime.month == date.month &&
                      apt.dateTime.day == date.day,
                );

                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _selectedDate = date),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.softGreen : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            color: selected ? Colors.white : AppColors.textPrimary,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        if (hasAppointments && !selected)
                          Positioned(
                            bottom: 3,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: AppColors.softOrange,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const months = [
      'Janvier',
      'Fevrier',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Aout',
      'Septembre',
      'Octobre',
      'Novembre',
      'Decembre',
    ];
    return months[m - 1];
  }

  String _statusLabel(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.PENDING:
        return 'En attente';
      case AppointmentStatus.CONFIRMED:
        return 'Confirme';
      case AppointmentStatus.COMPLETED:
        return 'Termine';
      case AppointmentStatus.CANCELLED:
        return 'Annule';
    }
  }

  Color _statusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.PENDING:
        return AppColors.attention;
      case AppointmentStatus.CONFIRMED:
        return AppColors.statusGood;
      case AppointmentStatus.COMPLETED:
        return AppColors.accentBlue;
      case AppointmentStatus.CANCELLED:
        return Colors.redAccent;
    }
  }
}
