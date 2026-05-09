import 'dart:io' show Platform;

import 'package:diab_care/core/constants/revenuecat_constants.dart';
import 'package:diab_care/core/services/token_service.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  RevenueCatService();

  final TokenService _tokenService = TokenService();
  static bool _configured = false;
  static String? _configuredUserId;

  Future<void> configureIfNeeded() async {
    final apiKey = _resolveApiKey();
    if (apiKey.isEmpty) {
      throw Exception(
        'Revenue Cat non configuré. Ajoutez REVENUECAT_ANDROID_API_KEY '
        'et/ou REVENUECAT_IOS_API_KEY via --dart-define.',
      );
    }

    final userId = _normalizeUserId(await _tokenService.getUserId());

    if (!_configured) {
      final config = PurchasesConfiguration(apiKey);
      if (userId != null) {
        config.appUserID = userId;
      }

      await Purchases.configure(config);
      _configured = true;
      _configuredUserId = userId;
      return;
    }

    await _syncUserIdentity(userId);
  }

  Future<void> syncUserIdentity() async {
    await configureIfNeeded();
  }

  Future<void> logOutIfNeeded() async {
    if (!_configured) return;

    await Purchases.logOut();
    _configuredUserId = null;
  }

  Future<CustomerInfo> getCustomerInfo() async {
    await configureIfNeeded();
    return Purchases.getCustomerInfo();
  }

  Future<CustomerInfo> purchasePackageById(String packageId) async {
    await configureIfNeeded();

    final package = await _findPackageById(packageId);
    if (package == null) {
      throw Exception(
        'Package Revenue Cat introuvable: $packageId. '
        'Vérifiez vos Offerings/Packages.',
      );
    }

    try {
      final result = await Purchases.purchasePackage(package);
      return result.customerInfo;
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

  Future<StoreProduct?> getStoreProductByIds({
    String? packageId,
    String? productId,
  }) async {
    await configureIfNeeded();

    final offerings = await Purchases.getOfferings();
    final packages = offerings.all.values
        .expand((offering) => offering.availablePackages)
        .toList();

    final normalizedProductId = _normalizeUserId(productId);
    if (normalizedProductId != null) {
      final packageByProduct = packages
          .where((pkg) => pkg.storeProduct.identifier == normalizedProductId)
          .firstOrNull;
      if (packageByProduct != null) {
        return packageByProduct.storeProduct;
      }
    }

    final normalizedPackageId = _normalizeUserId(packageId);
    if (normalizedPackageId != null) {
      final packageById = packages
          .where(
            (pkg) =>
                pkg.identifier == normalizedPackageId ||
                pkg.storeProduct.identifier == normalizedPackageId,
          )
          .firstOrNull;
      if (packageById != null) {
        return packageById.storeProduct;
      }
    }

    return null;
  }

  bool hasEntitlement(CustomerInfo info, String entitlementId) {
    return info.entitlements.active.containsKey(entitlementId);
  }

  /// Vérifie localement (via le SDK RevenueCat) si le médecin a un boost actif.
  /// Retourne un Map avec les infos du boost ou null si aucun boost actif.
  Future<Map<String, dynamic>?> getActiveBoostFromLocal() async {
    try {
      await configureIfNeeded();
      final customerInfo = await Purchases.getCustomerInfo();
      
      // Liste des product IDs de boost connus
      const boostProductIds = ['boost', 'boostweek', 'boostmonth'];
      const boostProductDays = {
        'boostweek': 7,
        'boost': 15,
        'boostmonth': 30,
      };
      const boostProductTypes = {
        'boostweek': 'boost_7d',
        'boost': 'boost_15d',
        'boostmonth': 'boost_30d',
      };
      
      // Vérifier d'abord les entitlements actifs
      if (customerInfo.entitlements.active.containsKey(RevenueCatConstants.doctorBoostEntitlementId)) {
        final ent = customerInfo.entitlements.active[RevenueCatConstants.doctorBoostEntitlementId]!;
        final productId = ent.productIdentifier;
        return {
          'isActive': true,
          'boostType': boostProductTypes[productId] ?? 'boost_7d',
          'expiresAt': ent.expirationDate,
          'remainingDays': boostProductDays[productId] ?? 7,
          'source': 'revenuecat_local_entitlement',
        };
      }
      
      // Vérifier les abonnements actifs (non-expirés)
      for (final productId in boostProductIds) {
        if (customerInfo.activeSubscriptions.contains(productId)) {
          return {
            'isActive': true,
            'boostType': boostProductTypes[productId] ?? 'boost_7d',
            'remainingDays': boostProductDays[productId] ?? 7,
            'source': 'revenuecat_local_subscription',
          };
        }
      }
      
      return null;
    } catch (e) {
      print('⚠️ Erreur vérification boost local: $e');
      return null;
    }
  }

  Future<Package?> _findPackageById(String packageId) async {
    final offerings = await Purchases.getOfferings();
    
    print('--- DIAGNOSTIC REVENUECAT ---');
    print('Offre actuelle (current) : ${offerings.current?.identifier}');
    if (offerings.current != null) {
      print('Packages disponibles dans current :');
      for (var pkg in offerings.current!.availablePackages) {
        print('  - ID: ${pkg.identifier} | Product: ${pkg.storeProduct.identifier}');
      }
    }
    print('-----------------------------');

    // 1. Chercher d'abord dans l'offre actuelle (recommandé)
    if (offerings.current != null) {
      if (packageId == RevenueCatConstants.premiumPackageId && offerings.current!.monthly != null) {
        return offerings.current!.monthly;
      }
      
      final pkg = offerings.current!.availablePackages.where((p) => 
        p.identifier == packageId || p.storeProduct.identifier == packageId
      ).firstOrNull;
      if (pkg != null) return pkg;
    }

    // 2. Chercher dans toutes les offres si pas trouvé
    final packages = offerings.all.values
        .expand((offering) => offering.availablePackages)
        .toList();

    return packages.where((pkg) {
      return pkg.identifier == packageId ||
          pkg.storeProduct.identifier == packageId;
    }).firstOrNull;
  }

  Future<void> _syncUserIdentity(String? userId) async {
    if (_configuredUserId == userId) return;

    if (userId == null) {
      await Purchases.logOut();
    } else {
      await Purchases.logIn(userId);
    }

    _configuredUserId = userId;
  }

  String? _normalizeUserId(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
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
