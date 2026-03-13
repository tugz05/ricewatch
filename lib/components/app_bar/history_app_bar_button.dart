import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../views/history/history_view.dart';

/// History icon button for app bar — navigates to History screen.
class HistoryAppBarButton extends StatelessWidget {
  const HistoryAppBarButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const HistoryView(),
          ),
        );
      },
      icon: Icon(Icons.history_rounded, color: context.colors.textOnDark),
      tooltip: 'History',
    );
  }
}
