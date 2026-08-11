import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../design_system/core_components.dart';
import '../navigation/app_routes.dart';
import '../theme/brand_tokens.dart';

/// In-app browser used for the payment gateway and brand web content.
class AppBrowser extends StatefulWidget {
  const AppBrowser({super.key, required this.initialUrl, required this.title});

  final String initialUrl;
  final String title;

  @override
  State<AppBrowser> createState() => _AppBrowserState();
}

class _AppBrowserState extends State<AppBrowser> {
  int _progress = 0;
  late final WebViewController _webController;

  @override
  void initState() {
    super.initState();
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() => _progress = progress);
            }
          },
          onWebResourceError: (error) => debugPrint(error.description),
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.brand;
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: ScreenHeader(
        title: widget.title,
        titleSize: 18,
        onBack: context.popOrHome,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_progress < 100)
              LinearProgressIndicator(
                value: _progress / 100,
                minHeight: 2,
                color: tokens.primary,
                backgroundColor: tokens.surfaceAlt,
              ),
            Expanded(child: WebViewWidget(controller: _webController)),
          ],
        ),
      ),
    );
  }
}
