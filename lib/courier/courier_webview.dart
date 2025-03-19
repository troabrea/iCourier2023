import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CourierWebViewPage extends StatelessWidget {
  CourierWebViewPage({required this.htmlText, required this.titulo});

  String htmlText;
  String titulo;

  @override
  Widget build(BuildContext context) {
    final webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {
            debugPrint('started');
          },
          onPageFinished: (String url) {
            debugPrint('finished');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint(error.toString());
          },
          onNavigationRequest: (NavigationRequest request) {
            // if (request.url.startsWith('https://www.youtube.com/')) {
            //   return NavigationDecision.prevent;
            // }
            // if(request.url.contains("about:blank")) {
            //   print(request.url);
            //   return NavigationDecision.prevent;
            // }
            debugPrint(request.url);
            return NavigationDecision.navigate;
          },
        ),
      );


    return Scaffold(
        appBar: AppBar(title: Text(titulo),
        ),
        body: SafeArea(child: WebViewWidget(
            // controller: webController..loadRequest(Uri.parse("https://www.google.com"))
            controller: webController..loadHtmlString(htmlText)
        ))
    );
  }
}