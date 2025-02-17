import 'package:chuck_interceptor/chuck.dart';
import 'package:http/http.dart';

extension ChuckHttpExtensions on Future<Response> {
  /// Intercept http request with Chuck. This extension method provides additional
  /// helpful method to intercept https' response.
  Future<Response> interceptWithChuck(Chuck Chuck, {dynamic body}) async {
    final Response response = await this;
    Chuck.onHttpResponse(response, body: body);
    return response;
  }
}
