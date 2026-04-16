import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:diab_care/core/constants/api_constants.dart';
import 'package:diab_care/core/services/token_service.dart';

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

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      isActive: json['isActive'] == true,
      status: (json['status'] ?? 'inactive').toString(),
      planName: (json['planName'] ?? 'Premium Mensuel').toString(),
      amount: (json['amount'] ?? 20) as num,
        currency: (json['currency'] ?? 'eur').toString(),
      subscribedAt: json['subscribedAt'] != null
          ? DateTime.tryParse(json['subscribedAt'].toString())
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
    );
  }
}

class CheckoutSessionResult {
  final String checkoutUrl;
  final String sessionId;

  CheckoutSessionResult({required this.checkoutUrl, required this.sessionId});

  factory CheckoutSessionResult.fromJson(Map<String, dynamic> json) {
    return CheckoutSessionResult(
      checkoutUrl: (json['checkoutUrl'] ?? '').toString(),
      sessionId: (json['sessionId'] ?? '').toString(),
    );
  }
}

class SubscriptionService {
  final TokenService _tokenService = TokenService();

  Future<Map<String, String>> _headers() async {
    final token = await _tokenService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<SubscriptionStatus> getMySubscription() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.subscriptionMe}'),
      headers: await _headers(),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return SubscriptionStatus.fromJson(jsonDecode(response.body));
    }

    throw Exception(
      _extractError(response.body, 'Impossible de charger l\'abonnement'),
    );
  }

  Future<CheckoutSessionResult> createCheckoutSession() async {
    final response = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.subscriptionCheckoutSession}',
      ),
      headers: await _headers(),
      body: jsonEncode({}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return CheckoutSessionResult.fromJson(jsonDecode(response.body));
    }

    throw Exception(
      _extractError(
        response.body,
        'Impossible de créer la session de paiement',
      ),
    );
  }

  Future<SubscriptionStatus> verifyLatestPayment() async {
    final response = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.subscriptionVerifyLatest}',
      ),
      headers: await _headers(),
      body: jsonEncode({}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return SubscriptionStatus.fromJson(jsonDecode(response.body));
    }

    throw Exception(
      _extractError(response.body, 'Vérification du paiement impossible'),
    );
  }

  String _extractError(String rawBody, String fallback) {
    try {
      final data = jsonDecode(rawBody);
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    } catch (_) {}
    return fallback;
  }
}
