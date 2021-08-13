import 'package:flutter/material.dart';
import 'package:webview_flutter/platform_interface.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'injector.dart';
import 'request_code.dart';

class AadLoginPage extends StatefulWidget {
  static String path = 'AadLoginPage';

  final RequestCode requestCode = getIt<RequestCode>();

  AadLoginPage({Key? key}) : super(key: key);

  @override
  _AadLoginPageState createState() => _AadLoginPageState();
}

class _AadLoginPageState extends State<AadLoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Builder(builder: (BuildContext context) {
      return WebView(
        initialUrl: widget.requestCode.getUrlToLaunch(),
        navigationDelegate: (NavigationRequest request) => NavigationDecision.navigate,
        javascriptMode: JavascriptMode.unrestricted,
        onWebResourceError: (WebResourceError e) {
          // HACK for error 102 NSURLErrorCancelled on iOS
          var iosUrl = e.description.split('NSErrorFailingURLStringKey=');
          if (iosUrl.length > 1) {
            var url = iosUrl[1].split(',')[0];
            widget.requestCode.closeOnUrlChanged(url);
          }
          Navigator.of(context).pop();
        },
        onPageFinished: (String url) {
          if (widget.requestCode.closeOnUrlChanged(url)) {
            Navigator.of(context).pop();
          }
        },
        gestureNavigationEnabled: true,
      );
    }));
  }

  @override
  void dispose() {
    widget.requestCode.closeOnUrlChanged('?error=Close');
    super.dispose();
  }
}
