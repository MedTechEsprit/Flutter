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

  Future<SubscriptionStatus> getMySubscription() async {
    final info = await _revenueCatService.getCustomerInfo();
    return _toSubscriptionStatus(info);
  }

  Future<SubscriptionStatus> purchasePremium() async {
    final info = await _revenueCatService.purchasePackageById(
      RevenueCatConstants.premiumPackageId,
    );
    return _toSubscriptionStatus(info);
  }

  Future<SubscriptionStatus> restorePremiumPurchases() async {
    final info = await _revenueCatService.restorePurchases();
    return _toSubscriptionStatus(info);
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
