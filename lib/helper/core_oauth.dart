import 'package:aad_oauth/helper/choose_oauth.dart'
// ignore: uri_does_not_exist
    if (dart.library.io) 'package:aad_oauth/helper/mobile_oauth.dart'
// ignore: uri_does_not_exist
    if (dart.library.html) 'package:aad_oauth/helper/web_oauth.dart';
import 'package:aad_oauth/model/config.dart';
import 'package:flutter/widgets.dart';

class CoreOAuth {
  CoreOAuth();

  void setWebViewScreenSize(Rect screenSize) {}

  void setWebViewScreenSizeFromMedia(MediaQueryData media) {}

  Future<void> login({bool refreshIfAvailable = false}) async {}

  Future<void> logout() async {}

  Future<String?> getAccessToken() async => 'ACCESS_TOKEN';

  Future<String?> getIdToken() async => 'ID_TOKEN';

  Future<bool> needFullAuth() async => false;

  factory CoreOAuth.fromConfig(Config config) => config.isStub ? CoreOAuth() : getOAuthConfig(config);
}
