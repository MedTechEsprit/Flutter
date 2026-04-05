import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:diab_care/core/constants/api_constants.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/core/services/gamification_service.dart';
import 'package:diab_care/features/pharmacy/models/pharmacy_api_models.dart';
import 'package:diab_care/features/pharmacy/services/pharmacy_dashboard_service.dart';
import 'package:diab_care/features/pharmacy/services/medication_request_service.dart';
import 'package:diab_care/features/pharmacy/services/boost_service.dart';
import 'package:diab_care/features/pharmacy/services/activity_service.dart';
import 'package:diab_care/data/models/pharmacy_models.dart';
import 'package:diab_care/data/models/gamification_models.dart';

/// État de chargement
enum LoadingState { initial, loading, loaded, error }

/// ViewModel principal pour la pharmacie
/// Gère l'état de l'authentification, du dashboard et des demandes
class PharmacyViewModel extends ChangeNotifier {
  final TokenService _tokenService = TokenService();
  final PharmacyDashboardService _dashboardService = PharmacyDashboardService();
  final MedicationRequestService _requestService = MedicationRequestService();
  final BoostService _boostService = BoostService();
  final ActivityService _activityService = ActivityService();
  final GamificationService _gamificationService = GamificationService();

  // État d'authentification
  bool _isLoggedIn = false;
  PharmacyProfile? _pharmacyProfile;
  String? _authError;

  // État du dashboard
  LoadingState _dashboardState = LoadingState.initial;
  PharmacyDashboardModel? _dashboardData;
  String? _dashboardError;

  // 🎮 État de la gamification
  LoadingState _gamificationState = LoadingState.initial;
  PointsStatsResponse? _pointsStats;
  RankingResponse? _ranking;
  List<BadgeThreshold> _badgeThresholds = [];
  List<PointsHistoryItem> _pointsHistory = [];
  String? _gamificationError;

  // État des demandes
  LoadingState _requestsState = LoadingState.initial;
  List<MedicationRequestModel> _pendingRequests = [];
  List<MedicationRequestModel> _acceptedRequests = [];
  List<MedicationRequestModel> _declinedRequests = [];
  List<MedicationRequestModel> _expiredRequests = [];
  String? _requestsError;

  // État des boosts
  LoadingState _boostState = LoadingState.initial;
  List<BoostModel> _activeBoosts = [];
  String? _boostError;

  // État de l'activité
  List<ActivityModel> _activityFeed = [];

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  PharmacyProfile? get pharmacyProfile => _pharmacyProfile;
  String? get authError => _authError;

  LoadingState get dashboardState => _dashboardState;
  PharmacyDashboardModel? get dashboardData => _dashboardData;
  String? get dashboardError => _dashboardError;

  LoadingState get requestsState => _requestsState;
  List<MedicationRequestModel> get pendingRequests => _pendingRequests;
  List<MedicationRequestModel> get acceptedRequests => _acceptedRequests;
  List<MedicationRequestModel> get declinedRequests => _declinedRequests;
  List<MedicationRequestModel> get expiredRequests => _expiredRequests;
  String? get requestsError => _requestsError;

  LoadingState get boostState => _boostState;
  List<BoostModel> get activeBoosts => _activeBoosts;
  String? get boostError => _boostError;

  List<ActivityModel> get activityFeed => _activityFeed;

  // 🎮 Gamification Getters
  LoadingState get gamificationState => _gamificationState;
  PointsStatsResponse? get pointsStats => _pointsStats;
  RankingResponse? get ranking => _ranking;
  List<BadgeThreshold> get badgeThresholds => _badgeThresholds;
  List<PointsHistoryItem> get pointsHistory => _pointsHistory;
  String? get gamificationError => _gamificationError;

  // Helper: Get current badge and next badge
  BadgeThreshold? get currentBadge {
    if (_pointsStats == null || _badgeThresholds.isEmpty) return null;
    return _gamificationService.getCurrentBadge(
      _pointsStats!.currentPoints,
      _badgeThresholds,
    );
  }

  BadgeThreshold? get nextBadge {
    if (_pointsStats == null || _badgeThresholds.isEmpty) return null;
    return _gamificationService.getNextBadge(
      _pointsStats!.currentPoints,
      _badgeThresholds,
    );
  }

  // Helper: Get badge progression
  Map<String, dynamic> get badgeProgress {
    if (_pointsStats == null || _badgeThresholds.isEmpty) {
      return {'progress': 0, 'pointsNeeded': 0};
    }
    return _gamificationService.calculateBadgeProgress(
      _pointsStats!.currentPoints,
      _badgeThresholds,
    );
  }

  /// Convertit les données API en PharmacyStats pour les widgets existants
  PharmacyStats? get pharmacyStats {
    if (_dashboardData == null) return null;
    final stats = _dashboardData!.stats;
    return PharmacyStats(
      totalRequests: stats.totalRequestsReceived,
      acceptedRequests: stats.totalRequestsAccepted,
      newClients: stats.totalClients,
      estimatedRevenue: stats.totalRevenue,
      growthPercentage: 0,
      pendingRequests: _dashboardData!.pendingRequestsCount,
      averageRating: stats.averageRating,
      totalReviews: stats.totalReviews,
      responseTimeMinutes: stats.averageResponseTime,
    );
  }

  /// Convertit les données API en BadgeLevel pour les widgets existants
  List<BadgeLevel> get badges {
    if (_dashboardData == null) return [];
    final progression = _dashboardData!.badgeProgression;

    final badgesList = <BadgeLevel>[];
    final allBadges = [
      {'name': 'Bronze Partner', 'icon': '🥉', 'points': 50},
      {'name': 'Silver Partner', 'icon': '🥈', 'points': 150},
      {'name': 'Gold Partner', 'icon': '🥇', 'points': 300},
      {'name': 'Platinum Partner', 'icon': '🏆', 'points': 500},
      {'name': 'Diamond Partner', 'icon': '💎', 'points': 1000},
    ];

    for (var badge in allBadges) {
      badgesList.add(
        BadgeLevel(
          name: badge['name'] as String,
          icon: badge['icon'] as String,
          pointsRequired: badge['points'] as int,
          currentPoints: progression.currentPoints,
          advantages: [],
          isUnlocked: progression.currentPoints >= (badge['points'] as int),
        ),
      );
    }
    return badgesList;
  }

  /// Convertit les données API en PerformanceMetric pour les widgets existants
  List<PerformanceMetric> get performanceMetrics {
    if (_dashboardData == null) return [];
    final comparison = _dashboardData!.performanceComparison;

    return [
      PerformanceMetric(
        label: 'Temps de Réponse Moyen',
        yourValue: '${comparison.pharmacyAverageResponseTime} min',
        stars: _calculateStars(
          comparison.pharmacyAverageResponseTime,
          comparison.sectorAverage,
          true,
        ),
        benchmark: 'Moyenne secteur: ${comparison.sectorAverage}min',
        badge: comparison.topPercentage <= 10
            ? '🎯 Vous êtes dans le TOP ${comparison.topPercentage}% !'
            : '💪 Continuez comme ça !',
      ),
      PerformanceMetric(
        label: 'Taux d\'Acceptation',
        yourValue:
            '${_dashboardData!.stats.acceptanceRate.toStringAsFixed(0)}%',
        stars: _calculateStars(
          _dashboardData!.stats.acceptanceRate.toInt(),
          58,
          false,
        ),
        benchmark: 'Moyenne secteur: 58%',
        badge: _dashboardData!.stats.acceptanceRate > 75
            ? '🌟 Excellent!'
            : '📈 En progression',
      ),
    ];
  }

  int _calculateStars(int value, int sectorAvg, bool lowerIsBetter) {
    if (lowerIsBetter) {
      if (value < sectorAvg * 0.4) return 5;
      if (value < sectorAvg * 0.6) return 4;
      if (value < sectorAvg * 0.8) return 3;
      if (value < sectorAvg) return 2;
      return 1;
    } else {
      if (value > sectorAvg * 1.5) return 5;
      if (value > sectorAvg * 1.2) return 4;
      if (value > sectorAvg) return 3;
      if (value > sectorAvg * 0.8) return 2;
      return 1;
    }
  }

  /// Convertit les activités API en ActivityEvent pour les widgets existants
  List<ActivityEvent> get activityEvents {
    if (_dashboardData == null) return [];
    return _dashboardData!.recentActivity
        .map(
          (a) => ActivityEvent(
            icon: a.icon,
            description: a.description,
            timestamp: a.relativeTime,
            value: a.amount != null
                ? '+${a.amount!.toStringAsFixed(0)} TND'
                : (a.points != null ? '+${a.points} pts' : null),
            type: _mapActivityType(a.activityType),
          ),
        )
        .toList();
  }

  ActivityType _mapActivityType(String apiType) {
    switch (apiType) {
      case 'request_accepted':
      case 'client_pickup':
        return ActivityType.success;
      case 'request_received':
        return ActivityType.pending;
      case 'badge_unlocked':
      case 'points_earned':
        return ActivityType.achievement;
      default:
        return ActivityType.info;
    }
  }

  /// Convertit les avis API en Review pour les widgets existants
  List<Review> get reviews {
    if (_dashboardData == null) return [];
    return _dashboardData!.recentReviews
        .map(
          (r) => Review(
            patientName: r.patientName,
            rating: r.rating,
            comment: r.comment,
            timestamp: r.timestamp,
          ),
        )
        .toList();
  }

  /// Convertit les demandes API en MedicationRequest pour les widgets existants
  Map<String, List<MedicationRequest>> get requestsByStatus {
    return {
      'pending': _pendingRequests
          .map((r) => _convertToMedicationRequest(r, RequestStatus.pending))
          .toList(),
      'accepted': _acceptedRequests
          .map((r) => _convertToMedicationRequest(r, RequestStatus.accepted))
          .toList(),
      'declined': _declinedRequests
          .map((r) => _convertToMedicationRequest(r, RequestStatus.declined))
          .toList(),
      'expired': _expiredRequests
          .map((r) => _convertToMedicationRequest(r, RequestStatus.expired))
          .toList(),
    };
  }

  MedicationRequest _convertToMedicationRequest(
    MedicationRequestModel apiRequest,
    RequestStatus status,
  ) {
    final myPharmacyId = _pharmacyProfile?.id ?? '';
    final myResponse = apiRequest.getMyResponse(myPharmacyId);

    return MedicationRequest(
      id: apiRequest.id,
      patientId: apiRequest.patientId,
      patientName: 'Patient',
      medicationName: apiRequest.medicationName,
      quantity: apiRequest.quantity,
      dosage: '${apiRequest.dosage} - ${apiRequest.format}',
      patientNote: apiRequest.patientNote.isNotEmpty
          ? apiRequest.patientNote
          : null,
      status: status,
      timestamp: apiRequest.createdAt,
      isUrgent: apiRequest.isUrgent,
      declineReason: null,
      price: myResponse?.indicativePrice,
      pickupDeadline: myResponse?.pickupDeadline,
      pharmacyMessage: myResponse?.pharmacyMessage,
      preparationTimeMinutes: myResponse?.preparationDelay != null
          ? _parsePreparationTime(myResponse!.preparationDelay!)
          : null,
      isPickedUp: apiRequest.globalStatus == 'picked_up',
    );
  }

  int? _parsePreparationTime(String delay) {
    switch (delay) {
      case 'immediate':
        return 0;
      case '30min':
        return 30;
      case '1h':
        return 60;
      case '2h':
        return 120;
      default:
        return null;
    }
  }

  // ─── Méthodes d'authentification ───────────────────────────

  /// Initialise le ViewModel après un login réussi
  /// Cette méthode est appelée depuis LoginScreen après AuthViewModel.login()
  Future<void> initialize() async {
    debugPrint('🔄 PharmacyViewModel.initialize() appelé');

    // Vérifier si les tokens sont stockés
    _isLoggedIn = await _tokenService.isLoggedIn();
    debugPrint('📱 isLoggedIn from storage: $_isLoggedIn');

    if (_isLoggedIn) {
      final userData = await _tokenService.getUserData();
      if (userData != null) {
        _pharmacyProfile = PharmacyProfile.fromJson(userData);
      }
      debugPrint('👤 Profile loaded: ${_pharmacyProfile?.nomPharmacie}');
      notifyListeners();

      // Charger le dashboard automatiquement
      debugPrint('📊 Loading dashboard...');
      await loadDashboard();
    } else {
      debugPrint('❌ Not logged in, cannot load dashboard');
    }
  }

  /// Initialise le ViewModel avec un profil déjà connu (appelé après login réussi)
  Future<void> initializeWithProfile(PharmacyProfile profile) async {
    debugPrint('🔄 PharmacyViewModel.initializeWithProfile() appelé');
    debugPrint('👤 Profile: ${profile.nomPharmacie}');

    _isLoggedIn = true;
    _pharmacyProfile = profile;
    notifyListeners();

    // Charger le dashboard avec le token et l'ID depuis le stockage
    debugPrint('📊 Loading dashboard with stored credentials...');

    _dashboardState = LoadingState.loading;
    _dashboardError = null;
    notifyListeners();

    try {
      final token = await _tokenService.getToken();
      final pharmacyId = await _tokenService.getUserId();

      debugPrint(
        '🔑 Token from storage: ${token != null ? "Present" : "NULL"}',
      );
      debugPrint('🆔 PharmacyId from storage: $pharmacyId');

      if (token == null || pharmacyId == null) {
        // Fallback: utiliser l'ID du profil
        final idToUse = pharmacyId ?? profile.id;
        debugPrint('⚠️ Using profile ID: $idToUse');

        if (token == null) {
          throw Exception('Token non disponible');
        }

        final data = await _dashboardService.loadDashboardDirect(
          token: token,
          pharmacyId: idToUse,
        );

        if (data != null) {
          _dashboardData = data;
          _dashboardState = LoadingState.loaded;
          _pharmacyProfile = data.pharmacy;
        } else {
          _dashboardState = LoadingState.error;
          _dashboardError = 'Impossible de charger le dashboard';
        }
      } else {
        final data = await _dashboardService.loadDashboardDirect(
          token: token,
          pharmacyId: pharmacyId,
        );

        if (data != null) {
          debugPrint('✅ Dashboard loaded successfully');
          debugPrint(
            '📊 Dashboard data: stats=${data.stats.totalRequestsReceived}, pending=${data.pendingRequestsCount}',
          );
          _dashboardData = data;
          _dashboardState = LoadingState.loaded;
          _pharmacyProfile = data.pharmacy;
        } else {
          debugPrint('❌ Dashboard returned null');
          _dashboardState = LoadingState.error;
          _dashboardError = 'Impossible de charger le dashboard';
        }
      }
    } catch (e) {
      debugPrint('❌ Dashboard error: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      _dashboardState = LoadingState.error;
      _dashboardError = e.toString();
    }
    notifyListeners();
    debugPrint('🎯 initializeWithProfile finished: state=$_dashboardState');
  }

  /// Connexion de la pharmacie (non utilisée car AuthViewModel gère le login)
  /// Deprecated: Use AuthViewModel.login() instead
  @Deprecated('Use AuthViewModel.login() instead')
  Future<bool> login(String email, String password) async {
    _authError = 'Cette méthode est dépréciée. Utilisez AuthViewModel.login()';
    notifyListeners();
    return false;
  }

  /// Déconnexion
  Future<void> logout() async {
    await _tokenService.clearAuthData();
    _isLoggedIn = false;
    _pharmacyProfile = null;
    _dashboardData = null;
    _pendingRequests = [];
    _acceptedRequests = [];
    _declinedRequests = [];
    _expiredRequests = [];
    _dashboardState = LoadingState.initial;
    _requestsState = LoadingState.initial;
    notifyListeners();
  }

  // ─── Méthodes du Dashboard ───────────────────────────

  /// Charge les données du dashboard
  Future<void> loadDashboard() async {
    debugPrint('📊 loadDashboard() appelé, isLoggedIn: $_isLoggedIn');

    // Vérifier d'abord si on est connecté
    if (!_isLoggedIn) {
      final isLoggedInStorage = await _tokenService.isLoggedIn();
      if (isLoggedInStorage) {
        _isLoggedIn = true;
        final userData = await _tokenService.getUserData();
        if (userData != null) {
          _pharmacyProfile = PharmacyProfile.fromJson(userData);
        }
      } else {
        debugPrint('❌ Cannot load dashboard: not authenticated');
        _dashboardState = LoadingState.error;
        _dashboardError = 'Non authentifié';
        notifyListeners();
        return;
      }
    }

    _dashboardState = LoadingState.loading;
    _dashboardError = null;
    notifyListeners();

    try {
      debugPrint('🌐 Calling dashboard API...');
      final data = await _dashboardService.loadDashboard();
      if (data != null) {
        debugPrint('✅ Dashboard loaded successfully');
        _dashboardData = data;
        _dashboardState = LoadingState.loaded;
        // Mettre à jour le profil depuis le dashboard
        _pharmacyProfile = data.pharmacy;
      } else {
        debugPrint('❌ Dashboard returned null');
        _dashboardState = LoadingState.error;
        _dashboardError = 'Impossible de charger le dashboard';
      }
    } catch (e) {
      debugPrint('❌ Dashboard error: $e');
      _dashboardState = LoadingState.error;
      _dashboardError = e.toString();
      if (e.toString().contains('Session expirée')) {
        await logout();
      }
    }
    notifyListeners();
  }

  /// Rafraîchit le dashboard
  Future<void> refreshDashboard() async {
    await loadDashboard();
  }

  // ─── Méthodes des Demandes ───────────────────────────

  /// Charge les demandes en attente
  Future<void> loadPendingRequests() async {
    debugPrint('📋 loadPendingRequests() appelé');
    _requestsState = LoadingState.loading;
    _requestsError = null;
    notifyListeners();

    try {
      _pendingRequests = await _requestService.fetchPendingRequests();
      debugPrint('✅ Loaded ${_pendingRequests.length} pending requests');
      _requestsState = LoadingState.loaded;
    } catch (e) {
      debugPrint('❌ loadPendingRequests error: $e');
      _requestsState = LoadingState.error;
      _requestsError = e.toString();
      if (e.toString().contains('Session expirée')) {
        await logout();
      }
    }
    notifyListeners();
  }

  /// Charge l'historique des demandes
  Future<void> loadRequestHistory() async {
    try {
      _acceptedRequests = await _requestService.fetchRequestHistory(
        status: 'accepted',
      );
      _declinedRequests = await _requestService.fetchRequestHistory(
        status: 'declined',
      );
      _expiredRequests = await _requestService.fetchRequestHistory(
        status: 'expired',
      );
      notifyListeners();
    } catch (e) {
      _requestsError = e.toString();
      notifyListeners();
    }
  }

  /// Charge toutes les demandes
  Future<void> loadAllRequests() async {
    _requestsState = LoadingState.loading;
    notifyListeners();

    await loadPendingRequests();
    await loadRequestHistory();

    _requestsState = LoadingState.loaded;
    notifyListeners();
  }

  /// Accepter une demande
  Future<Map<String, dynamic>> acceptRequest({
    required String requestId,
    required double price,
    String? preparationDelay,
    String? message,
    DateTime? pickupDeadline,
  }) async {
    debugPrint('✅ Accepting request $requestId with price $price');

    final result = await _requestService.respondToRequest(
      requestId: requestId,
      status: 'accepted',
      indicativePrice: price,
      preparationDelay: preparationDelay,
      pharmacyMessage: message,
      pickupDeadline: pickupDeadline,
    );

    if (result['success'] == true) {
      debugPrint('✅ Request accepted, refreshing data...');
      // Recharger les demandes
      await loadAllRequests();
      // Recharger le dashboard pour mettre à jour les points et stats
      await loadDashboard();
      // Recharger l'activité
      await loadActivityFeed();
    }

    if (result['sessionExpired'] == true) {
      await logout();
    }

    return result;
  }

  /// Refuser une demande
  Future<Map<String, dynamic>> declineRequest(
    String requestId, {
    String? message,
  }) async {
    debugPrint('❌ Declining request $requestId');

    final result = await _requestService.respondToRequest(
      requestId: requestId,
      status: 'declined',
      pharmacyMessage: message,
    );

    if (result['success'] == true) {
      debugPrint('✅ Request declined, refreshing data...');
      // Recharger les demandes
      await loadAllRequests();
      // Recharger le dashboard pour mettre à jour les points et stats
      await loadDashboard();
      // Recharger l'activité
      await loadActivityFeed();
    }

    if (result['sessionExpired'] == true) {
      await logout();
    }

    return result;
  }

  /// Ignorer une demande
  Future<Map<String, dynamic>> ignoreRequest(String requestId) async {
    final result = await _requestService.respondToRequest(
      requestId: requestId,
      status: 'ignored',
    );

    if (result['success'] == true) {
      await loadPendingRequests();
    }

    if (result['sessionExpired'] == true) {
      await logout();
    }

    return result;
  }

  /// Marquer une demande comme retirée
  Future<Map<String, dynamic>> markAsPickedUp(String requestId) async {
    final result = await _requestService.markAsPickedUp(requestId);

    if (result['success'] == true) {
      await loadRequestHistory();
      await loadDashboard(); // Refresh points and stats
      await loadActivityFeed();
    }

    if (result['sessionExpired'] == true) {
      await logout();
    }

    return result;
  }

  // ─── Méthodes des Boosts ───────────────────────────

  /// Charge les boosts actifs
  Future<void> loadActiveBoosts() async {
    debugPrint('⚡ loadActiveBoosts() appelé');
    _boostState = LoadingState.loading;
    _boostError = null;
    notifyListeners();

    try {
      _activeBoosts = await _boostService.getActiveBoosts();
      debugPrint('✅ Loaded ${_activeBoosts.length} active boost(s)');
      _boostState = LoadingState.loaded;
    } catch (e) {
      debugPrint('❌ loadActiveBoosts error: $e');
      _boostState = LoadingState.error;
      _boostError = e.toString();
      if (e.toString().contains('Session expirée')) {
        await logout();
      }
    }
    notifyListeners();
  }

  /// Active un boost de visibilité
  Future<Map<String, dynamic>> activateBoost({
    required String boostType,
    required int radiusKm,
  }) async {
    debugPrint('⚡ Activating boost: $boostType, radius: $radiusKm km');

    final result = await _boostService.activateBoost(
      boostType: boostType,
      radiusKm: radiusKm,
    );

    if (result['success'] == true) {
      debugPrint('✅ Boost activated, refreshing data...');
      await loadActiveBoosts();
      await loadActivityFeed();
    }

    if (result['sessionExpired'] == true) {
      await logout();
    }

    return result;
  }

  // ─── Méthodes de l'Activité ───────────────────────────

  /// Charge le fil d'activité
  Future<void> loadActivityFeed() async {
    try {
      _activityFeed = await _activityService.getActivityFeed(limit: 20);
      debugPrint('✅ Loaded ${_activityFeed.length} activity event(s)');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ loadActivityFeed error: $e');
      if (e.toString().contains('Session expirée')) {
        await logout();
      }
    }
  }

  // ─── Gestion du Statut En Ligne ───────────────────────────

  /// Met à jour le statut en ligne/hors ligne de la pharmacie
  Future<bool> updateOnlineStatus(bool isOnline) async {
    try {
      debugPrint('🔄 Updating online status to: $isOnline');

      final token = await _tokenService.getToken();
      final pharmacyId = await _tokenService.getUserId();

      if (token == null || pharmacyId == null) {
        throw Exception('Non authentifié');
      }

      // Appel API pour mettre à jour le statut
      final url = '${ApiConstants.baseUrl}/pharmaciens/$pharmacyId/status';
      debugPrint('🌐 URL: $url');

      final response = await http.put(
        Uri.parse(url),
        headers: ApiConstants.authHeaders(token),
        body: jsonEncode({'isOnDuty': isOnline}),
      );

      debugPrint('📥 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ Status updated successfully');

        // Mettre à jour le profil local
        if (_pharmacyProfile != null) {
          _pharmacyProfile = PharmacyProfile(
            id: _pharmacyProfile!.id,
            nom: _pharmacyProfile!.nom,
            prenom: _pharmacyProfile!.prenom,
            email: _pharmacyProfile!.email,
            telephone: _pharmacyProfile!.telephone,
            role: _pharmacyProfile!.role,
            nomPharmacie: _pharmacyProfile!.nomPharmacie,
            numeroOrdre: _pharmacyProfile!.numeroOrdre,
            telephonePharmacie: _pharmacyProfile!.telephonePharmacie,
            adressePharmacie: _pharmacyProfile!.adressePharmacie,
            photoProfil: _pharmacyProfile!.photoProfil,
            profileImage: _pharmacyProfile!.profileImage,
            location: _pharmacyProfile!.location,
            points: _pharmacyProfile!.points,
            badgeLevel: _pharmacyProfile!.badgeLevel,
            totalRequestsReceived: _pharmacyProfile!.totalRequestsReceived,
            totalRequestsAccepted: _pharmacyProfile!.totalRequestsAccepted,
            totalRequestsDeclined: _pharmacyProfile!.totalRequestsDeclined,
            totalClients: _pharmacyProfile!.totalClients,
            totalRevenue: _pharmacyProfile!.totalRevenue,
            averageResponseTime: _pharmacyProfile!.averageResponseTime,
            averageRating: _pharmacyProfile!.averageRating,
            totalReviews: _pharmacyProfile!.totalReviews,
            isOnDuty: isOnline, // ← Mise à jour
            notificationsPush: _pharmacyProfile!.notificationsPush,
            notificationsEmail: _pharmacyProfile!.notificationsEmail,
            notificationsSMS: _pharmacyProfile!.notificationsSMS,
            visibilityRadius: _pharmacyProfile!.visibilityRadius,
            statutCompte: _pharmacyProfile!.statutCompte,
          );
        }

        // Mettre à jour aussi dans dashboardData si présent
        if (_dashboardData != null) {
          await loadDashboard(); // Recharger pour avoir les données à jour
        }

        notifyListeners();
        return true;
      } else if (response.statusCode == 401) {
        debugPrint('❌ 401 - Session expirée');
        await logout();
        return false;
      } else {
        debugPrint('❌ Erreur ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ updateOnlineStatus error: $e');
      return false;
    }
  }

  Future<bool> updateProfilePhoto(String photoDataUrl) async {
    try {
      final token = await _tokenService.getToken();
      final pharmacyId = await _tokenService.getUserId();

      if (token == null || pharmacyId == null) {
        throw Exception('Non authentifié');
      }

      final url = '${ApiConstants.baseUrl}/pharmaciens/$pharmacyId';

      final response = await http.patch(
        Uri.parse(url),
        headers: ApiConstants.authHeaders(token),
        body: jsonEncode({
          'photoProfil': photoDataUrl,
          'profileImage': photoDataUrl,
        }),
      );

      if (response.statusCode == 200) {
        final updatedData = jsonDecode(response.body) as Map<String, dynamic>;
        _pharmacyProfile = PharmacyProfile.fromJson(updatedData);

        await _tokenService.saveAuthData(token: token, userData: updatedData);

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ updateProfilePhoto error: $e');
      return false;
    }
  }

  // ─── Méthodes utilitaires ───────────────────────────

  /// Obtenir les données pour les graphiques
  List<double> getChartDataForRequests() {
    if (_dashboardData == null || _dashboardData!.monthlyStats.isEmpty) {
      return [0, 0, 0, 0, 0, 0, 0];
    }
    return _dashboardData!.monthlyStats
        .take(7)
        .map((m) => m.requestsCount.toDouble())
        .toList();
  }

  List<double> getChartDataForRevenue() {
    if (_dashboardData == null || _dashboardData!.monthlyStats.isEmpty) {
      return [0, 0, 0, 0, 0, 0, 0];
    }
    return _dashboardData!.monthlyStats.take(7).map((m) => m.revenue).toList();
  }

  // ─── Méthodes de Gamification ───────────────────────────

  /// Charge les stats de gamification (points, badges, ranking)
  Future<void> loadGamificationData() async {
    debugPrint('🎮 loadGamificationData() appelé');
    _gamificationState = LoadingState.loading;
    _gamificationError = null;
    notifyListeners();

    try {
      final pharmacyId = await _tokenService.getUserId();
      if (pharmacyId == null) {
        throw Exception('PharmacyId manquant');
      }

      // Charger les stats de points
      debugPrint('📊 Fetching points stats...');
      _pointsStats = await _gamificationService.getPointsStats(pharmacyId);
      debugPrint(
        '✅ Points stats loaded: ${_pointsStats?.currentPoints} points',
      );

      // Charger le ranking
      debugPrint('🏆 Fetching ranking...');
      _ranking = await _gamificationService.getRanking(pharmacyId);
      debugPrint(
        '✅ Ranking loaded: #${_ranking?.rank} / ${_ranking?.totalPharmacies}',
      );

      // Charger les seuils de badges
      debugPrint('🏅 Fetching badge thresholds...');
      _badgeThresholds = await _gamificationService.getBadgeThresholds();
      debugPrint(
        '✅ Badge thresholds loaded: ${_badgeThresholds.length} badges',
      );

      // Charger l'historique du jour
      debugPrint('📈 Fetching daily history...');
      _pointsHistory = await _gamificationService.getDailyHistory(pharmacyId);
      debugPrint('✅ Daily history loaded: ${_pointsHistory.length} activities');

      _gamificationState = LoadingState.loaded;
    } catch (e) {
      debugPrint('❌ loadGamificationData error: $e');
      _gamificationState = LoadingState.error;
      _gamificationError = e.toString();
      if (e.toString().contains('Session expirée')) {
        await logout();
      }
    }
    notifyListeners();
  }

  /// Rafraîchit les données de gamification
  Future<void> refreshGamificationData() async {
    await loadGamificationData();
  }

  /// Répond à une demande de médicament et déclenche la pop-up gamification
  /// Utilisé par les boutons d'action dans les écrans de demandes
  Future<Map<String, dynamic>> respondToMedicationRequest({
    required String requestId,
    required String status, // "accepted", "unavailable", "declined"
    double? indicativePrice,
    String? preparationDelay,
    String? pharmacyMessage,
    DateTime? pickupDeadline,
  }) async {
    debugPrint('🎮 respondToMedicationRequest() - Status: $status');

    try {
      final pharmacyId = await _tokenService.getUserId();
      if (pharmacyId == null) {
        throw Exception('PharmacyId manquant');
      }

      // Créer le DTO de réponse
      final dto = RespondToRequestDto(
        pharmacyId: pharmacyId,
        status: status,
        indicativePrice: indicativePrice,
        preparationDelay: preparationDelay,
        pharmacyMessage: pharmacyMessage,
        pickupDeadline: pickupDeadline,
      );

      // Appeler l'API
      debugPrint('🌐 Calling respondToRequest API...');
      final response = await _gamificationService.respondToRequest(
        requestId,
        dto,
      );
      debugPrint('✅ Response received');

      // Extraire les informations de points
      if (response.pharmacyResponses.isNotEmpty) {
        final pharmacyResponse = response.pharmacyResponses.first;
        final pointsAwarded = pharmacyResponse.pointsAwarded;
        final breakdown = _buildBreakdownList(
          pharmacyResponse.pointsBreakdown.basePoints,
          pharmacyResponse.pointsBreakdown.bonusPoints,
        );

        // Rafraîchir les données
        debugPrint('🔄 Refreshing all data after response...');
        await Future.wait([
          loadAllRequests(),
          loadDashboard(),
          loadActivityFeed(),
          loadGamificationData(),
        ]);

        // Retourner les infos pour afficher la pop-up
        return {
          'success': true,
          'status': status,
          'pointsAwarded': pointsAwarded,
          'basePoints': pharmacyResponse.pointsBreakdown.basePoints,
          'bonusPoints': pharmacyResponse.pointsBreakdown.bonusPoints,
          'breakdown': breakdown,
          'reason': pharmacyResponse.pointsBreakdown.reason,
          'responseTime': pharmacyResponse.responseTime,
          'beforePoints': _pointsStats?.currentPoints ?? 0,
          'afterPoints': (_pointsStats?.currentPoints ?? 0) + pointsAwarded,
        };
      }

      return {'success': false, 'error': 'Réponse vide du serveur'};
    } catch (e) {
      debugPrint('❌ respondToMedicationRequest error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Créer une évaluation client (rating) et déclencher la pop-up bonus
  Future<Map<String, dynamic>> submitRating({
    required String patientId,
    required String medicationRequestId,
    required int stars,
    String? comment,
    required bool medicationAvailable,
    int? speedRating,
    int? courtesynRating,
  }) async {
    debugPrint('⭐ submitRating() - Stars: $stars');

    try {
      final pharmacyId = await _tokenService.getUserId();
      if (pharmacyId == null) {
        throw Exception('PharmacyId manquant');
      }

      // Créer le DTO d'évaluation
      final dto = CreateRatingDto(
        patientId: patientId,
        pharmacyId: pharmacyId,
        medicationRequestId: medicationRequestId,
        stars: stars,
        comment: comment,
        medicationAvailable: medicationAvailable,
        speedRating: speedRating,
        courtesynRating: courtesynRating,
      );

      // Appeler l'API
      debugPrint('🌐 Calling createRating API...');
      final response = await _gamificationService.createRating(dto);
      debugPrint('✅ Rating submitted successfully');

      // Rafraîchir les données
      await loadGamificationData();

      // Retourner les infos pour afficher la pop-up
      return {
        'success': true,
        'stars': response.stars,
        'pointsAwarded': response.pointsAwarded,
        'penaltyApplied': response.penaltyApplied,
        'beforePoints':
            (_pointsStats?.currentPoints ?? 0) - response.pointsAwarded,
        'afterPoints': _pointsStats?.currentPoints ?? 0,
      };
    } catch (e) {
      debugPrint('❌ submitRating error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Helper: Construire la liste breakdown des points
  List<String> _buildBreakdownList(int basePoints, int bonusPoints) {
    final list = <String>[];
    list.add('Base: +$basePoints');
    if (bonusPoints > 0) {
      if (bonusPoints >= 20) {
        list.add('Bonus: +$bonusPoints (Ultra-rapide < 30 min)');
      } else if (bonusPoints >= 15) {
        list.add('Bonus: +$bonusPoints (Rapide 30-60 min)');
      } else if (bonusPoints >= 5) {
        list.add('Bonus: +$bonusPoints (< 120 min)');
      } else {
        list.add('Bonus: +$bonusPoints');
      }
    }
    return list;
  }

  /// Obtenir les données pour les graphiques de gamification
  List<int> getPointsHistoryChart() {
    if (_pointsHistory.isEmpty) return [0, 0, 0, 0, 0, 0, 0];

    // Grouper par heure ou créer un graphique simple
    return _pointsHistory.take(7).map((item) => item.points).toList();
  }
}
