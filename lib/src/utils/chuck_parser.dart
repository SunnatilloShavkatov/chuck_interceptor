import 'dart:convert';

sealed class ChuckParser {
  const ChuckParser._();

  static const String _emptyBody = "Body is empty";
  static const String _unknownContentType = "Unknown";
  static const String _jsonContentTypeSmall = "content-type";
  static const String _jsonContentTypeBig = "Content-Type";
  static const String _stream = "Stream";
  static const String _applicationJson = "application/json";
  static const String _parseFailedText = "Failed to parse ";
  static const JsonEncoder encoder = JsonEncoder.withIndent('  ');

  static String _parseJson(dynamic json) {
    try {
      return encoder.convert(json);
    } catch (exception) {
      return json.toString();
    }
  }

  static dynamic _decodeJson(dynamic body) {
    try {
      return json.decode(body as String);
    } catch (exception) {
      return body;
    }
  }

  static String formatBody(dynamic body, String? contentType) {
    try {
      if (body == null) {
        return _emptyBody;
      }

      var bodyContent = _emptyBody;

      // Check if content type indicates JSON or if body looks like JSON
      final isJsonContent =
          contentType != null && contentType.toLowerCase().contains(_applicationJson) || _looksLikeJson(body);

      if (!isJsonContent) {
        final bodyTemp = body.toString();
        if (bodyTemp.isNotEmpty) {
          bodyContent = bodyTemp;
        }
      } else {
        if (body is String && body.contains("\n")) {
          bodyContent = body;
        } else {
          if (body is String) {
            if (body.isNotEmpty) {
              // Try to parse and pretty print JSON
              final decoded = _decodeJson(body);
              if (decoded != body) {
                // Successfully decoded, pretty print it
                bodyContent = _parseJson(decoded);
              } else {
                // Failed to decode, return as is
                bodyContent = body;
              }
            }
          } else if (body is Stream) {
            bodyContent = _stream;
          } else {
            // For non-string JSON-like objects, try to pretty print
            bodyContent = _parseJson(body);
          }
        }
      }

      return bodyContent;
    } catch (exception) {
      return "$_parseFailedText$body (Error: $exception)";
    }
  }

  /// Check if the body content looks like JSON
  static bool _looksLikeJson(dynamic body) {
    if (body == null) return false;

    final bodyStr = body.toString().trim();
    if (bodyStr.isEmpty) return false;

    // Check for JSON-like structure
    return (bodyStr.startsWith('{') && bodyStr.endsWith('}')) || (bodyStr.startsWith('[') && bodyStr.endsWith(']'));
  }

  static String? getContentType(Map<String, dynamic>? headers) {
    if (headers != null) {
      // Try different variations of content-type header
      for (final entry in headers.entries) {
        final key = entry.key.toLowerCase();
        if (key == 'content-type' || key == 'contenttype') {
          return entry.value?.toString();
        }
      }

      // Fallback to old method for compatibility
      if (headers.containsKey(_jsonContentTypeSmall)) {
        return headers[_jsonContentTypeSmall] as String?;
      }
      if (headers.containsKey(_jsonContentTypeBig)) {
        return headers[_jsonContentTypeBig] as String?;
      }
    }
    return _unknownContentType;
  }
}
