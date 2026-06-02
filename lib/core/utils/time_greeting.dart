/// Time-of-day greeting (no personal name), using device local clock.
String timeBasedGreeting([DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;

  if (hour == 12) return 'Good noon';
  if (hour > 12 && hour < 17) return 'Good afternoon';
  if (hour >= 17) return 'Good evening';
  // 00:00–11:59 — morning (includes early hours)
  return 'Good morning';
}
