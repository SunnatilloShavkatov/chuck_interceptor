import 'package:chuck_interceptor/chuck.dart';
import 'package:http/http.dart';

extension AliceHttpExtensions on Future<Response> {
  /// Intercept http request with alice. This extension method provides additional
  /// helpful method to intercept https' response.
  Future<Response> interceptWithAlice(Chuck alice, {dynamic body}) async {
    final Response response = await this;
    alice.onHttpResponse(response, body: body);
    return response;
  }
}
