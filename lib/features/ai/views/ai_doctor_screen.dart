import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';
import 'package:diab_care/data/services/ai_doctor_service.dart';

/// Chat message model for doctor AI
class _DoctorChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  _DoctorChatMessage({required this.text, required this.isUser, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}

/// AI Doctor screen — Doctor's clinical AI assistant
/// Can ask about a specific patient or all patients
class AiDoctorScreen extends StatefulWidget {
  final String? patientId;
  final String? patientName;

  const AiDoctorScreen({super.key, this.patientId, this.patientName});

  @override
  State<AiDoctorScreen> createState() => _AiDoctorScreenState();
}

class _AiDoctorScreenState extends State<AiDoctorScreen> with SingleTickerProviderStateMixin {
  final _service = AiDoctorService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_DoctorChatMessage> _messages = [];
  List<UrgentPatient> _urgentAlerts = [];
  bool _isLoading = false;
  bool _isLoadingUrgent = false;
  late TabController _tabController;

  bool get _isSinglePatient => widget.patientId != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _isSinglePatient ? 1 : 2, vsync: this);

    // Welcome message
    _messages.add(_DoctorChatMessage(
      text: _isSinglePatient
          ? 'Bonjour Docteur ! Je suis MediAssist 🩺, votre assistant clinique IA.\n\n'
            'Je suis prêt à analyser les données de ${widget.patientName ?? 'ce patient'}. '
            'Posez-moi vos questions sur ses données glycémiques, ses tendances ou son plan de traitement.'
          : 'Bonjour Docteur ! Je suis MediAssist 🩺, votre assistant clinique IA.\n\n'
            'Vous pouvez me poser des questions sur l\'ensemble de vos patients ou utiliser l\'onglet "Alertes" '
            'pour voir les patients nécessitant une attention urgente.',
      isUser: false,
    ));

    if (!_isSinglePatient) {
      _loadUrgentAlerts();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _loadUrgentAlerts() async {
    setState(() => _isLoadingUrgent = true);
    try {
      final alerts = await _service.getUrgentAlerts();
      if (mounted) {
        setState(() {
          _urgentAlerts = alerts;
          _isLoadingUrgent = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingUrgent = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || text.length < 2) return;

    _controller.clear();
    setState(() {
      _messages.add(_DoctorChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final AiDoctorResponse response;
      if (_isSinglePatient) {
        response = await _service.chatAboutPatient(
          patientId: widget.patientId!,
          message: text,
        );
      } else {
        response = await _service.chatAboutAllPatients(text);
      }

      if (mounted) {
        setState(() {
          _messages.add(_DoctorChatMessage(text: response.response, isUser: false));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_DoctorChatMessage(
            text: '❌ Erreur: Impossible de contacter l\'assistant IA. Vérifiez que le serveur Ollama est actif.',
            isUser: false,
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.accentBlue, AppColors.primaryBlue]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MediAssist', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text(
                  _isSinglePatient ? widget.patientName ?? 'Patient' : 'Tous les patients',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        bottom: !_isSinglePatient
            ? TabBar(
                controller: _tabController,
                labelColor: AppColors.accentBlue,
                unselectedLabelColor: AppColors.textMuted,
                indicatorColor: AppColors.accentBlue,
                tabs: const [
                  Tab(text: 'Chat IA', icon: Icon(Icons.chat_rounded, size: 18)),
                  Tab(text: 'Alertes Urgentes', icon: Icon(Icons.warning_rounded, size: 18)),
                ],
              )
            : null,
      ),
      body: _isSinglePatient
          ? _buildChatView()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildChatView(),
                _buildUrgentView(),
              ],
            ),
    );
  }

  Widget _buildChatView() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _messages.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length && _isLoading) return _buildTypingIndicator();
              return _buildMessageBubble(_messages[index]);
            },
          ),
        ),

        // Quick suggestions
        if (_messages.length <= 1)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _isSinglePatient
                  ? [
                      _buildSuggestionChip('Résumé glycémique du patient'),
                      _buildSuggestionChip('Tendances récentes'),
                      _buildSuggestionChip('Risques identifiés'),
                    ]
                  : [
                      _buildSuggestionChip('Résumé général des patients'),
                      _buildSuggestionChip('Patients à risque'),
                      _buildSuggestionChip('Tendances de la semaine'),
                    ],
            ),
          ),

        // Input area
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Posez votre question clinique...',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.backgroundPrimary,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.accentBlue, AppColors.primaryBlue]),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: Icon(
                      _isLoading ? Icons.hourglass_top_rounded : Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUrgentView() {
    return RefreshIndicator(
      color: AppColors.accentBlue,
      onRefresh: _loadUrgentAlerts,
      child: _isLoadingUrgent
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentBlue))
          : _urgentAlerts.isEmpty
              ? ListView(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                    Column(
                      children: [
                        Icon(Icons.check_circle_rounded, size: 64, color: AppColors.statusGood.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text('Aucune alerte urgente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        const Text('Tous vos patients sont stables', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _urgentAlerts.length,
                  itemBuilder: (context, index) => _buildUrgentCard(_urgentAlerts[index]),
                ),
    );
  }

  Widget _buildUrgentCard(UrgentPatient patient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.critical.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: AppColors.critical.withOpacity(0.08), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.critical.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_rounded, color: AppColors.critical, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patient.patientName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    if (patient.lastGlucose != null)
                      Text('Dernière glycémie: ${patient.lastGlucose!.round()} mg/dL', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chat_rounded, color: AppColors.accentBlue, size: 22),
                tooltip: 'Consulter avec l\'IA',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AiDoctorScreen(
                        patientId: patient.patientId,
                        patientName: patient.patientName,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: patient.flags
                .map((flag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.statusErrorBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(flag, style: const TextStyle(fontSize: 11, color: AppColors.critical, fontWeight: FontWeight.w500)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_DoctorChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: EdgeInsets.only(bottom: 12, left: isUser ? 48 : 0, right: isUser ? 0 : 48),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.accentBlue, AppColors.primaryBlue]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.accentBlue : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: SelectableText(
                message.text,
                style: TextStyle(fontSize: 14, color: isUser ? Colors.white : AppColors.textPrimary, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.accentBlue, AppColors.primaryBlue]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 8, height: 8, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentBlue)),
                SizedBox(width: 8),
                Text('Analyse en cours...', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.accentBlue)),
        backgroundColor: AppColors.lightBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.accentBlue, width: 0.5),
        ),
        onPressed: () {
          _controller.text = text;
          _sendMessage();
        },
      ),
    );
  }
}
