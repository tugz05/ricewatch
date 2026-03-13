// Flutter Web: embed Windy using a native <iframe> via HtmlElementView.
// This avoids webview_flutter's unimplemented web methods entirely.
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';

/// Tracks view-type IDs that have already been registered so we never
/// register the same factory twice (platform views throw on re-registration).
final _registered = <String>{};

/// Returns a widget that displays [url] in a full-size <iframe>.
/// A new view-type is registered for each distinct URL (keyed by hash).
Widget buildWindyEmbed(String url, {bool onReady()?}) {
  final viewType = 'windy-${url.hashCode}';

  if (!_registered.contains(viewType)) {
    _registered.add(viewType);
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int id) => html.IFrameElement()
        ..src = url
        ..allow = 'geolocation'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%',
    );
  }

  return HtmlElementView(
    key: ValueKey(viewType),
    viewType: viewType,
  );
}
