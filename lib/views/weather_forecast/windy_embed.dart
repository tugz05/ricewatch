/// Conditional export: dart:html iframe on web, stub on other platforms.
export 'windy_embed_stub.dart'
    if (dart.library.html) 'windy_embed_web.dart';
