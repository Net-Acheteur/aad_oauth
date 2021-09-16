import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/platform_interface.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'injector.dart';
import 'request_code.dart';

class AadLoginPage extends StatefulWidget {
  static String path = 'AadLoginPage';

  final RequestCode requestCode = getIt<RequestCode>();
  final Widget onLoadView;

  AadLoginPage({Key? key, this.onLoadView = const CircularProgressIndicator()}) : super(key: key);

  @override
  _AadLoginPageState createState() => _AadLoginPageState();
}

class _AadLoginPageState extends State<AadLoginPage> {
  bool exitedWithError = true;
  bool exited = false;
  bool pageLoaded = false;

  @override
  void initState() {
    super.initState();
    // Enable hybrid composition.
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Builder(builder: (BuildContext context) {
      return Stack(children: [
        WebView(
          initialUrl: widget.requestCode.getUrlToLaunch(),
          navigationDelegate: (NavigationRequest request) => NavigationDecision.navigate,
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (webViewController) {
            webViewController.clearCache();
            final cookieManager = CookieManager();
            cookieManager.clearCookies();
          },
          onWebResourceError: (WebResourceError e) {
            // HACK for error 102 NSURLErrorCancelled on iOS
            var iosUrl = e.description.split('NSErrorFailingURLStringKey=');
            if (iosUrl.length > 1) {
              var url = iosUrl[1].split(',')[0];
              if (widget.requestCode.closeOnUrlChanged(url)) {
                exitedWithError = false;
              }
            }
            closeView(context);
          },
          onProgress: (int progress) {
            if (progress == 100) {
              setState(() {
                pageLoaded = true;
              });
            }
          },
          onPageStarted: (_) {
            setState(() {
              pageLoaded = false;
            });
          },
          onPageFinished: (String url) {
            if (widget.requestCode.closeOnUrlChanged(url)) {
              exitedWithError = false;
              closeView(context);
            }
          },
          gestureNavigationEnabled: true,
        ),
        !pageLoaded
            ? SizedBox.expand(
                child: Center(
                child: widget.onLoadView,
              ))
            : Stack()
      ]);
    }));
  }

  void closeView(BuildContext context) {
    if (!exited) {
      exited = true;
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    if (exitedWithError) {
      widget.requestCode.closeOnUrlChanged('?error=Close');
    }
    super.dispose();
  }
}
