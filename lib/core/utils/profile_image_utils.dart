import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class ProfileImageUtils {
  static ImageProvider? imageProvider(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) {
      return null;
    }

    final value = rawValue.trim();

    if (value.startsWith('data:image')) {
      final commaIndex = value.indexOf(',');
      if (commaIndex <= 0 || commaIndex >= value.length - 1) {
        return null;
      }
      try {
        final base64Part = value.substring(commaIndex + 1);
        final bytes = base64Decode(base64Part);
        return MemoryImage(bytes);
      } catch (_) {
        return null;
      }
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return NetworkImage(value);
    }

    return null;
  }

  static String toDataUrl(Uint8List bytes, {String mime = 'image/jpeg'}) {
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }
}
