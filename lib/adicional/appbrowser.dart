import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AppBrowser extends StatefulWidget {
  final String initialUrl;
  final String title;
  const AppBrowser({super.key, required this.initialUrl, required this.title});

  @override
  State<AppBrowser> createState() => _AppBrowserState();
}

class _AppBrowserState extends State<AppBrowser> {
  int _progress = 0;
  late WebViewController _webController;

  @override
  void initState() {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)

      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {

            setState(() {
              _progress = progress;
            });
            debugPrint(progress.toString());
            // Update loading bar.
          },
          onPageStarted: (String url) {
            debugPrint("STARTED");
          },
          onPageFinished: (String url) async {
            debugPrint("FINISHED");
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint(error.toString());
          },
          onNavigationRequest: (NavigationRequest request) {
            // if (request.url.startsWith('https://www.youtube.com/')) {
            //   return NavigationDecision.prevent;
            // }
            return NavigationDecision.navigate;
          },
        ),
      )..loadRequest( Uri.parse(widget.initialUrl) );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: SafeArea(
            child: Column(
              children: [
                if(_progress < 100)
                  const LinearProgressIndicator(),
                Expanded(
                  child: WebViewWidget(
                      controller: _webController),
                ),
              ],
            )));
  }
}
