// Non-web stub: uses webview_flutter (no dart:html APIs).
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

final _controllers = <String, WebViewController>{};

/// Returns a [WebViewWidget] that displays [url].
/// Controllers are cached per URL to avoid unnecessary reloads.
Widget buildWindyEmbed(String url, {bool onReady()?}) {
  final ctrl = _controllers.putIfAbsent(url, () {
    final c = WebViewController();
    try {
      c.setJavaScriptMode(JavaScriptMode.unrestricted);
    } catch (_) {}
    c.loadRequest(Uri.parse(url));
    return c;
  });

  return WebViewWidget(controller: ctrl);
}
