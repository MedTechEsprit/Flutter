import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Cloudinary upload service for DiabCare
/// Uses signed uploads with API key + secret
class CloudinaryService {
  static const String _cloudName = 'drdodr4or';
  static const String _apiKey = '911142393653269';
  static const String _apiSecret = 'KKBU9sduZx8el4ssTT-C6RNX-4Y';

  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Upload image bytes to Cloudinary and return the secure URL.
  /// [imageBytes] — raw bytes of the image
  /// [fileName] — original file name (for MIME detection)
  /// [folder] — optional Cloudinary folder
  static Future<String> uploadImageBytes(
    Uint8List imageBytes, {
    String fileName = 'photo.jpg',
    String? folder,
  }) async {
    try {
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000)
          .toString();

      // Build params string for signature (alphabetical order)
      final paramsMap = <String, String>{
        if (folder != null) 'folder': folder,
        'timestamp': timestamp,
      };

      // Create signature: SHA1 of "key1=val1&key2=val2{api_secret}"
      final sortedKeys = paramsMap.keys.toList()..sort();
      final paramString = sortedKeys.map((k) => '$k=${paramsMap[k]}').join('&');
      final signatureBase = '$paramString$_apiSecret';
      final signature = sha1.convert(utf8.encode(signatureBase)).toString();

      debugPrint('☁️ [Cloudinary] Uploading ${imageBytes.length} bytes...');

      // Build multipart request
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.fields['api_key'] = _apiKey;
      request.fields['timestamp'] = timestamp;
      request.fields['signature'] = signature;
      if (folder != null) request.fields['folder'] = folder;

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: fileName,
          // Content-type from http_parser needed? No, Cloudinary detects it.
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint(
        '☁️ [Cloudinary] Response ${response.statusCode}: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final secureUrl = data['secure_url'] as String;
        debugPrint('☁️ [Cloudinary] Upload success: $secureUrl');
        return secureUrl;
      } else {
        debugPrint(
          '❌ [Cloudinary] Upload failed (${response.statusCode}): ${response.body}',
        );
        throw Exception(
          'Cloudinary upload failed (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('❌ [Cloudinary] Upload error: $e');
      rethrow;
    }
  }
}
