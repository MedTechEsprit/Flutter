import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:diab_care/core/constants/api_constants.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:diab_care/core/constants/revenuecat_constants.dart';
import 'package:diab_care/data/services/revenuecat_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionStatus {
  final bool isActive;
  final String status;
  final String planName;
  final num amount;
  final String currency;
  final DateTime? subscribedAt;
  final DateTime? expiresAt;

  SubscriptionStatus({
    required this.isActive,
    required this.status,
    required this.planName,
    required this.amount,
    required this.currency,
    this.subscribedAt,
    this.expiresAt,
  });
}

class SubscriptionService {
  final RevenueCatService _revenueCatService = RevenueCatService();
  final TokenService _tokenService = TokenService();

  Future<SubscriptionStatus> getMySubscription() async {
    final info = await _revenueCatService.getCustomerInfo();
    final status = await _toSubscriptionStatus(info);

    // Synchronisation préventive si actif localement
    if (status.isActive) {
      // On ne l'attend pas pour ne pas bloquer l'UI, mais on le lance
      syncWithBackend();
    }

    return status;
  }

  Future<SubscriptionStatus> purchasePremium() async {
    final info = await _revenueCatService.purchasePackageById(
      RevenueCatConstants.premiumPackageId,
    );

    debugPrint('🛒 [SubscriptionService] Achat terminé. Entitlements actifs: ${info.entitlements.active.keys.toList()}');
    debugPrint('🛒 [SubscriptionService] Toutes les entitlements: ${info.entitlements.all.keys.toList()}');

    // Toujours synchroniser avec le backend après un achat, même si le SDK local
    // ne montre pas encore l'entitlement comme actif (délai de propagation possible)
    await syncWithBackend();

    // Re-vérifier après la synchro backend
    final freshInfo = await _revenueCatService.getCustomerInfo();
    final status = await _toSubscriptionStatus(freshInfo);

    debugPrint('🛒 [SubscriptionService] Statut final après synchro: isActive=${status.isActive}');

    return status;
  }

  Future<SubscriptionStatus> restorePremiumPurchases() async {
    final info = await _revenueCatService.restorePurchases();
    final status = await _toSubscriptionStatus(info);

    if (status.isActive) {
      await syncWithBackend();
    }

    return status;
  }

  /// Synchronise le statut Premium avec le backend pour débloquer les fonctionnalités IA
  Future<void> syncWithBackend() async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) return;

      // Récupérer l'ID RevenueCat actuel pour aider le backend à trouver le bon compte
      String? rcAppUserId;
      try {
        rcAppUserId = await Purchases.appUserID;
      } catch (e) {
        debugPrint('⚠️ [SubscriptionService] Impossible de récupérer appUserID: $e');
      }

      debugPrint('🔄 [SubscriptionService] Synchronisation Premium (RC ID: $rcAppUserId)...');
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.subscriptionSync}'),
        headers: {
          ...ApiConstants.authHeaders(token),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          if (rcAppUserId != null) 'revenueCatAppUserId': rcAppUserId,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ [SubscriptionService] Synchronisation réussie');
      } else {
        debugPrint('⚠️ [SubscriptionService] Échec synchro: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Erreur synchro backend: $e');
    }
  }

  Future<SubscriptionStatus> verifyLatestPayment() async {
    final info = await _revenueCatService.getCustomerInfo();
    return _toSubscriptionStatus(info);
  }

  Future<SubscriptionStatus> _toSubscriptionStatus(CustomerInfo info) async {
    final entitlement =
        info.entitlements.all[RevenueCatConstants.premiumEntitlementId];
    final isActive = entitlement?.isActive == true;

    // Récupérer le produit réel depuis les offres pour avoir le prix à jour
    try {
      final offerings = await Purchases.getOfferings();
      final package = offerings.current?.monthly;
      final storeProduct = package?.storeProduct;

      return SubscriptionStatus(
        isActive: isActive,
        status: isActive ? 'active' : 'inactive',
        planName: _resolvePlanName(storeProduct),
        amount: storeProduct?.price ?? 20,
        currency: (storeProduct?.currencyCode ?? 'EUR').toUpperCase(),
        subscribedAt: _parseDate(entitlement?.latestPurchaseDate),
        expiresAt: _parseDate(entitlement?.expirationDate),
      );
    } catch (e) {
      // Fallback si échec chargement offres
      return SubscriptionStatus(
        isActive: isActive,
        status: isActive ? 'active' : 'inactive',
        planName: 'Premium Mensuel',
        amount: 20,
        currency: 'EUR',
        subscribedAt: _parseDate(entitlement?.latestPurchaseDate),
        expiresAt: _parseDate(entitlement?.expirationDate),
      );
    }
  }

  String _resolvePlanName(StoreProduct? storeProduct) {
    final title = storeProduct?.title.trim() ?? '';
    if (title.isNotEmpty) return title;
    return 'Premium Mensuel';
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
