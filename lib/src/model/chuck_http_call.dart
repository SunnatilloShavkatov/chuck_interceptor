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

  String getCurlCommand() {
    if (request == null) return "curl # No request data available";
    
    var compressed = false;
    final StringBuffer curlCmd = StringBuffer("curl");
    curlCmd.write(" -X $method");
    
    final headers = request!.headers;
    headers.forEach((key, dynamic value) {
      if ("Accept-Encoding" == key && "gzip" == value) {
        compressed = true;
      }
      // Escape single quotes in header values for shell safety
      final String escapedValue = value.toString().replaceAll("'", "'\"'\"'");
      curlCmd.write(" -H '$key: $escapedValue'");
    });

    final String requestBody = request!.body.toString();
    if (requestBody.isNotEmpty) {
      // Escape single quotes and newlines for shell safety
      final String escapedBody = requestBody
          .replaceAll("'", "'\"'\"'")
          .replaceAll("\n", "\\n");
      curlCmd.write(" --data \$'$escapedBody'");
    }

    final queryParamMap = request!.queryParameters;
    if (queryParamMap.isNotEmpty) {
      final StringBuffer queryParams = StringBuffer("?");
      final entries = queryParamMap.entries.toList();
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        queryParams.write('${entry.key}=${entry.value}');
        if (i < entries.length - 1) {
          queryParams.write("&");
        }
      }
      
      // Build final URL with proper escaping
      final String baseUrl;
      if (server.contains("http://") || server.contains("https://")) {
        baseUrl = server;
      } else {
        baseUrl = "${secure ? 'https://' : 'http://'}$server";
      }
      
      curlCmd.write(compressed ? " --compressed " : " ");
      curlCmd.write("'$baseUrl$endpoint$queryParams'");
    } else {
      final String baseUrl;
      if (server.contains("http://") || server.contains("https://")) {
        baseUrl = server;
      } else {
        baseUrl = "${secure ? 'https://' : 'http://'}$server";
      }
      
      curlCmd.write(compressed ? " --compressed " : " ");
      curlCmd.write("'$baseUrl$endpoint'");
    }

    return curlCmd.toString();
  }
}
