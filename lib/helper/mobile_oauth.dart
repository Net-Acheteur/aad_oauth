library aad_oauth;

import 'dart:async';

import 'package:aad_oauth/helper/auth_storage.dart';
import 'package:aad_oauth/helper/core_oauth.dart';
import 'package:aad_oauth/injector.dart';
import 'package:aad_oauth/model/config.dart';
import 'package:aad_oauth/model/token.dart';
import 'package:aad_oauth/request_code.dart';
import 'package:aad_oauth/request_token.dart';
import 'package:flutter/material.dart';

/// Authenticates a user with Azure Active Directory using OAuth2.0.
class MobileOAuth extends CoreOAuth {
  final Config _config;
  late final AuthStorage _authStorage;
  late final RequestCode _requestCode;
  late final RequestToken _requestToken;

  /// Instantiating AadOAuth authentication.
  /// [config] Parameters according to official Microsoft Documentation.
  MobileOAuth(Config config) : _config = config {
    injectServices();

    _authStorage = getIt<AuthStorage>()..init(tokenIdentifier: config.tokenIdentifier);
    _requestCode = getIt<RequestCode>()..init(config);
    _requestToken = getIt<RequestToken>()..init(config);
  }

  /// Set [screenSize] of webview.
  @override
  void setWebViewScreenSize(Rect screenSize) {
    if (screenSize != _config.screenSize) {
      _config.screenSize = screenSize;
    }
  }

  @override
  void setWebViewScreenSizeFromMedia(MediaQueryData media) {
    final rect = Rect.fromLTWH(
      media.padding.left,
      media.padding.top,
      media.size.width - media.padding.left - media.padding.right,
      media.size.height - media.padding.top - media.padding.bottom,
    );
    setWebViewScreenSize(rect);
  }

  /// Perform Azure AD login.
  ///
  /// Setting [refreshIfAvailable] to [true] will attempt to re-authenticate
  /// with the existing refresh token, if any, even though the access token may
  /// still be valid. If there's no refresh token the existing access token
  /// will be returned, as long as we deem it still valid. In the event that
  /// both access and refresh tokens are invalid, the web gui will be used.
  @override
  Future<void> login({bool refreshIfAvailable = false}) async {
    await _authorization(refreshIfAvailable: refreshIfAvailable);
  }

  /// Retrieve cached OAuth Access Token.
  @override
  Future<String?> getAccessToken() async => (await _authStorage.loadTokenFromCache()).accessToken;

  /// Retrieve cached OAuth Id Token.
  @override
  Future<String?> getIdToken() async => (await _authStorage.loadTokenFromCache()).idToken;

  /// Perform Azure AD logout.
  @override
  Future<void> logout() async {
    await _authStorage.clear();
  }

  /// Check if we need to relaunch a full auth
  Future<bool> needFullAuth() async {
    var token = await _authStorage.loadTokenFromCache();

    if (token.hasValidAccessToken()) {
      return false;
    }

    if (token.hasRefreshToken()) {
      try {
        token = await _requestToken.requestRefreshToken(token.refreshToken!);
      } catch (e) {
        await logout();
        return true;
      }
    }

    return !token.hasValidAccessToken();
  }

  /// Authorize user via refresh token or web gui if necessary.
  ///
  /// Setting [refreshIfAvailable] to [true] will attempt to re-authenticate
  /// with the existing refresh token, if any, even though the access token may
  /// still be valid. If there's no refresh token the existing access token
  /// will be returned, as long as we deem it still valid. In the event that
  /// both access and refresh tokens are invalid, the web gui will be used.
  Future<Token> _authorization({bool refreshIfAvailable = false}) async {
    var token = await _authStorage.loadTokenFromCache();

    if (!refreshIfAvailable) {
      if (token.hasValidAccessToken()) {
        return token;
      }
    }

    if (token.hasRefreshToken()) {
      token = await _requestToken.requestRefreshToken(token.refreshToken!);
    }

    if (!token.hasValidAccessToken()) {
      token = await _performFullAuthFlow();
    }

    await _authStorage.saveTokenToCache(token);
    return token;
  }

  /// Authorize user via refresh token or web gui if necessary.
  Future<Token> _performFullAuthFlow() async {
    final _completer = Completer<String?>();

    var subscription = await _requestCode.onCode.listen((event) {
      return _completer.complete(event);
    });

    var code = await _completer.future;
    await subscription.cancel();
    if (code == null) {
      throw Exception('Access denied or authentication canceled.');
    }

    return await _requestToken.requestToken(code);
  }
}

CoreOAuth getOAuthConfig(Config config) => MobileOAuth(config);
