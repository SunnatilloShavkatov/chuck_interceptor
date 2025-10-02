import 'chuck_http_error.dart';
import 'chuck_http_request.dart';
import 'chuck_http_response.dart';

class ChuckHttpCall {
  final int id;
  late DateTime createdTime;
  String client = "";
  bool loading = true;
  bool secure = false;
  String method = "";
  String endpoint = "";
  String server = "";
  String uri = "";
  int duration = 0;

  ChuckHttpRequest? request;
  ChuckHttpResponse? response;
  ChuckHttpError<dynamic>? error;

  ChuckHttpCall(this.id) {
    loading = true;
    createdTime = DateTime.now();
  }

  void setResponse(ChuckHttpResponse response) {
    this.response = response;
    loading = false;
  }

  /// Generate a curl command string for this HTTP call
  ///
  /// Returns a properly formatted curl command that can be executed in terminal
  /// to reproduce this HTTP request. Handles special characters and escaping
  /// for shell safety.
  String getCurlCommand() {
    if (request == null) {
      return "curl # No request data available";
    }

    try {
      var compressed = false;
      final StringBuffer curlCmd = StringBuffer("curl");

      // Add HTTP method
      if (method.isNotEmpty) {
        curlCmd.write(" -X $method");
      }

      // Process headers
      final headers = request!.headers;
      for (final entry in headers.entries) {
        final key = entry.key;
        final value = entry.value;

        if (key == "Accept-Encoding" && value.toString().contains("gzip")) {
          compressed = true;
        }

        // Escape single quotes in header values for shell safety
        final String escapedValue = value.toString().replaceAll("'", "'\"'\"'");
        curlCmd.write(" -H '$key: $escapedValue'");
      }

      // Add request body if present
      final String requestBody = request!.body?.toString() ?? "";
      if (requestBody.isNotEmpty) {
        // Escape single quotes and newlines for shell safety
        final String escapedBody = requestBody.replaceAll("'", "'\"'\"'").replaceAll("\n", "\\n");
        curlCmd.write(" --data \$'$escapedBody'");
      }

      // Build URL with query parameters
      final String baseUrl = _buildBaseUrl();
      final String queryParams = _buildQueryParameters();

      curlCmd.write(compressed ? " --compressed " : " ");
      curlCmd.write("'$baseUrl$endpoint$queryParams'");

      return curlCmd.toString();
    } catch (e) {
      return "curl # Error generating curl command: $e";
    }
  }

  /// Build the base URL for the curl command
  String _buildBaseUrl() {
    if (server.contains("http://") || server.contains("https://")) {
      return server;
    }
    return "${secure ? 'https://' : 'http://'}$server";
  }

  /// Build query parameters string for the curl command
  String _buildQueryParameters() {
    final queryParamMap = request?.queryParameters;
    if (queryParamMap == null || queryParamMap.isEmpty) {
      return "";
    }

    final StringBuffer queryParams = StringBuffer("?");
    final entries = queryParamMap.entries.toList();

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final key = entry.key;
      final value = entry.value?.toString() ?? "";

      // URL encode the key and value
      final encodedKey = Uri.encodeComponent(key);
      final encodedValue = Uri.encodeComponent(value);

      queryParams.write('$encodedKey=$encodedValue');

      if (i < entries.length - 1) {
        queryParams.write("&");
      }
    }

    return queryParams.toString();
  }
}
