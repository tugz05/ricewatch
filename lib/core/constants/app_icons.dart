import 'package:flutter/widgets.dart';

/// Lucide icon constants — defined as plain [IconData] values.
///
/// The Lucide TTF font is bundled at fonts/Lucide.ttf and registered in
/// pubspec.yaml. Because we construct [IconData] directly (no subclassing),
/// this is compatible with Flutter 3.27+ where [IconData] is a final class.
///
/// Code-points were extracted from lucide_icons 0.257.0.
class AppIcons {
  AppIcons._();

  static const _family = 'Lucide';

  // ── Navigation ──────────────────────────────────────────────────────────────
  static const IconData home        = IconData(0xf35e, fontFamily: _family);
  static const IconData weather     = IconData(0xf50f, fontFamily: _family);
  static const IconData scan        = IconData(0xf4a2, fontFamily: _family);
  static const IconData aiChat      = IconData(0xf1c0, fontFamily: _family);
  static const IconData settings    = IconData(0xf4b9, fontFamily: _family);
  static const IconData history     = IconData(0xf35d, fontFamily: _family);

  // Lucide is a single-weight stroke set — no fill variants.
  // Active nav state is shown by primary color + background tint.
  static const IconData homeFill     = home;
  static const IconData weatherFill  = weather;
  static const IconData scanFill     = scan;
  static const IconData aiChatFill   = aiChat;
  static const IconData settingsFill = settings;
  static const IconData historyFill  = history;

  // ── Camera / media ─────────────────────────────────────────────────────────
  static const IconData camera       = IconData(0xf1df, fontFamily: _family);
  static const IconData gallery      = IconData(0xf365, fontFamily: _family);
  static const IconData image        = IconData(0xf365, fontFamily: _family);
  static const IconData imageFill    = image;
  static const IconData imageBroken  = IconData(0xf367, fontFamily: _family);

  // ── Actions ────────────────────────────────────────────────────────────────
  static const IconData send         = IconData(0xf4b2, fontFamily: _family);
  static const IconData refresh      = IconData(0xf491, fontFamily: _family);
  static const IconData delete       = IconData(0xf546, fontFamily: _family);
  static const IconData deleteSweep  = IconData(0xf545, fontFamily: _family);
  static const IconData search       = IconData(0xf4ad, fontFamily: _family);
  static const IconData back         = IconData(0xf1f9, fontFamily: _family);
  static const IconData forward      = IconData(0xf1fb, fontFamily: _family);
  static const IconData arrowRight   = IconData(0xf155, fontFamily: _family);
  static const IconData bookmark     = IconData(0xf1bd, fontFamily: _family);
  static const IconData bookmarkFill = bookmark;

  // ── Agriculture / content ──────────────────────────────────────────────────
  static const IconData leaf         = IconData(0xf38f, fontFamily: _family);
  static const IconData leafFill     = leaf;
  static const IconData plant        = IconData(0xf4f1, fontFamily: _family);
  static const IconData plantFill    = plant;
  static const IconData microscope   = IconData(0xf3d5, fontFamily: _family);
  static const IconData fileText     = IconData(0xf2d3, fontFamily: _family);
  static const IconData firstAid     = IconData(0xf358, fontFamily: _family); // heartPulse
  static const IconData firstAidFill = IconData(0xf505, fontFamily: _family); // stethoscope
  static const IconData bug          = IconData(0xf1cb, fontFamily: _family);
  static const IconData mountains    = IconData(0xf3ef, fontFamily: _family);
  static const IconData lightbulb    = IconData(0xf394, fontFamily: _family);
  static const IconData lightbulbFill= lightbulb;
  static const IconData user         = IconData(0xf564, fontFamily: _family);

  // ── Status ─────────────────────────────────────────────────────────────────
  static const IconData check        = IconData(0xf1f0, fontFamily: _family); // checkCircle
  static const IconData warning      = IconData(0xf10d, fontFamily: _family); // alertTriangle
  static const IconData error        = IconData(0xf59f, fontFamily: _family); // xCircle
  static const IconData errorFill    = error;
  static const IconData info         = IconData(0xf36e, fontFamily: _family);
  static const IconData infoFill     = info;

  // ── Weather ────────────────────────────────────────────────────────────────
  static const IconData sun          = IconData(0xf50f, fontFamily: _family);
  static const IconData sunOutline   = sun;
  static const IconData cloud        = IconData(0xf22e, fontFamily: _family);
  static const IconData cloudFill    = cloud;
  static const IconData cloudOff     = IconData(0xf236, fontFamily: _family);
  static const IconData rain         = IconData(0xf28b, fontFamily: _family); // droplets
  static const IconData rainOutline  = rain;
  static const IconData wind         = IconData(0xf598, fontFamily: _family);
  static const IconData thermometer  = IconData(0xf534, fontFamily: _family);
  static const IconData lightning    = IconData(0xf233, fontFamily: _family); // cloudLightning
  static const IconData snow         = IconData(0xf4e2, fontFamily: _family); // snowflake
  static const IconData gauge        = IconData(0xf328, fontFamily: _family);
  static const IconData calendar     = IconData(0xf1d2, fontFamily: _family);
  static const IconData map          = IconData(0xf3bf, fontFamily: _family);

  // ── Location / connectivity ────────────────────────────────────────────────
  static const IconData location     = IconData(0xf3c0, fontFamily: _family); // mapPin
  static const IconData locationOff  = IconData(0xf3c1, fontFamily: _family); // mapPinOff
  static const IconData wifi         = IconData(0xf596, fontFamily: _family);
  static const IconData wifiOff      = IconData(0xf597, fontFamily: _family);

  // ── UI / preferences ───────────────────────────────────────────────────────
  static const IconData volume       = IconData(0xf585, fontFamily: _family); // volume2
  static const IconData moonLight    = IconData(0xf3eb, fontFamily: _family); // moon
  static const IconData moonFill     = moonLight;
  static const IconData bell         = IconData(0xf19c, fontFamily: _family);
  static const IconData bellFill     = bell;
  static const IconData palette      = IconData(0xf41f, fontFamily: _family);
  static const IconData circleHalf   = IconData(0xf250, fontFamily: _family); // contrast
}
