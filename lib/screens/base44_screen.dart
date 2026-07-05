import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Base44Screen extends StatefulWidget {
  const Base44Screen({super.key});

  @override
  State<Base44Screen> createState() => _Base44ScreenState();
}

class _Base44ScreenState extends State<Base44Screen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('PASTE_YOUR_VERCEL_URL_HERE')); // 👈 Replace this with your copied link!
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
