import 'package:flutter/foundation.dart';

/// Controls app-level navigation: onboarding done, current tab, selected field.
class NavigationController extends ChangeNotifier {
  bool _onboardingComplete = false;
  int _bottomNavIndex = 0;
  String? _selectedFieldId;

  bool get onboardingComplete => _onboardingComplete;
  int get bottomNavIndex => _bottomNavIndex;
  String? get selectedFieldId => _selectedFieldId;

  void completeOnboarding() {
    _onboardingComplete = true;
    notifyListeners();
  }

  void setBottomNavIndex(int index) {
    _bottomNavIndex = index;
    notifyListeners();
  }

  void selectField(String? fieldId) {
    _selectedFieldId = fieldId;
    notifyListeners();
  }
}
