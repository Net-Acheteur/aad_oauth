import 'package:get_it/get_it.dart';

import 'helper/auth_storage.dart';
import 'request_code.dart';
import 'request_token.dart';

final getIt = GetIt.instance;

void injectServices() {
  getIt.registerSingleton<AuthStorage>(AuthStorage());
  getIt.registerSingleton<RequestCode>(RequestCode());
  getIt.registerSingleton<RequestToken>(RequestToken());
}
