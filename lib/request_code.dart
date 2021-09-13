import 'dart:async';

import 'model/config.dart';
import 'request/authorization_request.dart';

class RequestCode {
  final StreamController<String?> _onCodeListener = StreamController();
  late final AuthorizationRequest _authorizationRequest;

  late Stream<String?> _onCodeStream;

  RequestCode();

  void init(Config config) {
    _authorizationRequest = AuthorizationRequest(config);
    _onCodeStream = _onCodeListener.stream.asBroadcastStream();
  }

  String getUrlToLaunch() {
    final urlParams = _constructUrlParams();
    return '${_authorizationRequest.url}?$urlParams';
  }

  bool closeOnUrlChanged(String url) {
    var uri = Uri.parse(url);
    if (uri.queryParameters['error'] != null) {
      _onCodeListener.add(null);
      return true;
    }

    if (uri.queryParameters['code'] != null) {
      _onCodeListener.add(uri.queryParameters['code']);
      return true;
    }

    return false;
  }

  Stream<String?> get onCode => _onCodeStream;

  String _constructUrlParams() => _mapToQueryParams(_authorizationRequest.parameters);

  String _mapToQueryParams(Map<String, String> params) {
    final queryParams = <String>[];
    params.forEach((String key, String value) => queryParams.add('$key=${Uri.encodeQueryComponent(value)}'));
    return queryParams.join('&');
  }
}
