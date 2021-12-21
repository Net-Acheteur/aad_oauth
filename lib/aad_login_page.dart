import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'injector.dart';
import 'request_code.dart';

class AadLoginPage extends StatefulWidget {
  static String path = 'AadLoginPage';

  final RequestCode requestCode = getIt<RequestCode>();
  final Widget onLoadView;
  late final WebViewController webViewController;

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
          navigationDelegate: (NavigationRequest request) {
            if (widget.requestCode.closeOnUrlChanged(request.url)) {
              exitedWithError = false;
              closeView(context);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (webViewController) {
            webViewController.clearCache();
            final cookieManager = CookieManager();
            cookieManager.clearCookies();
            widget.webViewController = webViewController;
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
          onPageStarted: (_) {
            setState(() {
              pageLoaded = false;
            });
          },
          onPageFinished: (_) {
            setState(() {
              pageLoaded = true;
            });
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
