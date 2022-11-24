import 'dart:async';
import 'package:flutter/material.dart';

import 'request/authorization_request.dart';
import 'model/config.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RequestCode {
  final Config _config;
  final AuthorizationRequest _authorizationRequest;

  String? _code;

  RequestCode(Config config)
      : _config = config,
        _authorizationRequest = AuthorizationRequest(config);
  Future<String?> requestCode() async {
    _code = null;
    final urlParams = _constructUrlParams();
    var webView = WebView(
      initialUrl: '${_authorizationRequest.url}?$urlParams',
      javascriptMode: JavascriptMode.unrestricted,
      navigationDelegate: _navigationDelegate,
      backgroundColor: Colors.transparent,
      userAgent: _config.userAgent,
    );

    MaterialPageRoute materialPageRoute = MaterialPageRoute(
      builder: (context) => Scaffold(
          body: SafeArea(
        child: Stack(
          children: [_config.loader, webView],
        ),
      )),
    );

    if(_config.navigatorKey != null) {
      await _config.navigatorKey!.currentState!.push(materialPageRoute);
    } else {
      await _config.appRouter!.pushNativeRoute(materialPageRoute);
    }
    
    return _code;
  }

  FutureOr<NavigationDecision> _navigationDelegate(NavigationRequest request) {
    var uri = Uri.parse(request.url);

    if (uri.queryParameters['error'] != null) {
      if(_config.navigatorKey != null) {
        _config.navigatorKey!.currentState!.pop();
      } else {
        _config.appRouter!.pop();
      }
    }

    if (uri.queryParameters['code'] != null) {
      _code = uri.queryParameters['code'];
      if(_config.navigatorKey != null) {
        _config.navigatorKey!.currentState!.pop();
      } else {
        _config.appRouter!.pop();
      }
    }
    return NavigationDecision.navigate;
  }

  Future<void> clearCookies() async {
    await CookieManager().clearCookies();
  }

  String _constructUrlParams() =>
      _mapToQueryParams(_authorizationRequest.parameters);

  String _mapToQueryParams(Map<String, String> params) {
    final queryParams = <String>[];
    params.forEach((String key, String value) =>
        queryParams.add('$key=${Uri.encodeQueryComponent(value)}'));
    return queryParams.join('&');
  }
}
