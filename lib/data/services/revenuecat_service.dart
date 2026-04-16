import 'dart:io' show Platform;

import 'package:diab_care/core/constants/revenuecat_constants.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  RevenueCatService();

  final TokenService _tokenService = TokenService();
  static bool _configured = false;

  Future<void> configureIfNeeded() async {
    if (_configured) return;

    final apiKey = _resolveApiKey();
    if (apiKey.isEmpty) {
      throw Exception(
        'Revenue Cat non configuré. Ajoutez REVENUECAT_ANDROID_API_KEY '
        'et/ou REVENUECAT_IOS_API_KEY via --dart-define.',
      );
    }

    final userId = await _tokenService.getUserId();

    final config = PurchasesConfiguration(apiKey);
    if (userId != null && userId.isNotEmpty) {
      config.appUserID = userId;
    }

    await Purchases.configure(config);
    _configured = true;
  }

  Future<CustomerInfo> purchasePackageById(String packageId) async {
    await configureIfNeeded();

    final offerings = await Purchases.getOfferings();
    final packages = offerings.all.values
        .expand((offering) => offering.availablePackages)
        .toList();

    final package = packages.where((pkg) {
      return pkg.identifier == packageId ||
          pkg.storeProduct.identifier == packageId;
    }).firstOrNull;

    if (package == null) {
      throw Exception(
        'Package Revenue Cat introuvable: $packageId. '
        'Vérifiez vos Offerings/Packages.',
      );
    }

    try {
      return await Purchases.purchasePackage(package);
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        throw Exception('Achat annulé par l\'utilisateur.');
      }
      throw Exception(e.message ?? 'Achat Revenue Cat échoué');
    }
  }

  Future<CustomerInfo> restorePurchases() async {
    await configureIfNeeded();
    return Purchases.restorePurchases();
  }

  bool hasEntitlement(CustomerInfo info, String entitlementId) {
    return info.entitlements.active.containsKey(entitlementId);
  }

  String _resolveApiKey() {
    if (Platform.isIOS) return RevenueCatConstants.iosApiKey;
    if (Platform.isAndroid) return RevenueCatConstants.androidApiKey;
    return '';
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
