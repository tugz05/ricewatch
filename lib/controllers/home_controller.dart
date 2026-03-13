import 'package:flutter/foundation.dart';
import '../models/field_model.dart';
import '../models/user_model.dart';
import '../models/weather_model.dart';
import '../services/location_weather_service.dart';

/// Controller for home/dashboard: user, weather, fields, category filter, content cards.
class HomeController extends ChangeNotifier {
  HomeController() {
    _loadRealtimeWeather();
  }

  final UserModel _user = const UserModel(
    id: '1',
    displayName: 'Annca Namrata',
  );
  WeatherModel _weather = const WeatherModel(
    location: '—',
    temperatureCelsius: 0,
    condition: '—',
    dateTime: '—',
  );
  List<FieldContentItem> _fieldContents = _defaultFieldContents;
  final List<String> _categories = const ['All', 'Paddy', 'Irrigated', 'Upland', 'Hybrid'];
  int _selectedCategoryIndex = 0;
  bool _hasUnreadNotifications = true;

  bool _weatherLoading = true;
  String? _weatherError;
  LocationPermissionStatus _permissionStatus = LocationPermissionStatus.notDetermined;

  UserModel get user => _user;
  WeatherModel get weather => _weather;
  List<FieldContentItem> get fieldContents => _fieldContents;
  List<String> get categories => _categories;
  int get selectedCategoryIndex => _selectedCategoryIndex;
  bool get hasUnreadNotifications => _hasUnreadNotifications;
  bool get weatherLoading => _weatherLoading;
  String? get weatherError => _weatherError;
  LocationPermissionStatus get permissionStatus => _permissionStatus;

  Future<void> _loadRealtimeWeather() async {
    _weatherLoading = true;
    _weatherError = null;
    _permissionStatus = await LocationWeatherService.checkPermissionStatus();
    notifyListeners();

    if (_permissionStatus != LocationPermissionStatus.granted) {
      _permissionStatus = await LocationWeatherService.requestPermission();
      notifyListeners();
      if (_permissionStatus != LocationPermissionStatus.granted) {
        _weatherLoading = false;
        _weatherError = _permissionMessage;
        notifyListeners();
        return;
      }
    }

    final result = await LocationWeatherService.fetchRealtimeWeather();
    _weatherLoading = false;
    switch (result) {
      case WeatherSuccess():
        _weather = result.weather;
        _weatherError = null;
      case WeatherError():
        _weatherError = result.message;
    }
    notifyListeners();
  }

  Future<void> refreshWeather() async {
    await _loadRealtimeWeather();
  }

  Future<void> requestLocationPermission() async {
    _permissionStatus = await LocationWeatherService.requestPermission();
    notifyListeners();
    if (_permissionStatus == LocationPermissionStatus.granted) {
      await _loadRealtimeWeather();
    } else {
      _weatherLoading = false;
      _weatherError = _permissionMessage;
      notifyListeners();
    }
  }

  Future<void> openLocationSettings() async {
    await LocationWeatherService.openAppSettings();
  }

  String get _permissionMessage {
    switch (_permissionStatus) {
      case LocationPermissionStatus.notDetermined:
      case LocationPermissionStatus.denied:
        return 'Location permission is required for real-time weather.';
      case LocationPermissionStatus.deniedForever:
        return 'Location was permanently denied. Open settings to allow.';
      case LocationPermissionStatus.serviceDisabled:
        return 'Please enable location services.';
      case LocationPermissionStatus.error:
        return 'Could not check permission.';
      case LocationPermissionStatus.granted:
        return '';
    }
  }

  void setSelectedCategory(int index) {
    _selectedCategoryIndex = index;
    notifyListeners();
  }

  void toggleBookmark(String contentId) {
    _fieldContents = [
      for (final c in _fieldContents)
        c.id == contentId
            ? FieldContentItem(
                id: c.id,
                title: c.title,
                description: c.description,
                fieldId: c.fieldId,
                imageUrl: c.imageUrl,
                isBookmarked: !c.isBookmarked,
              )
            : c,
    ];
    notifyListeners();
  }

  void clearNotifications() {
    _hasUnreadNotifications = false;
    notifyListeners();
  }

  static List<FieldContentItem> get _defaultFieldContents => [
        const FieldContentItem(
          id: '1',
          title: 'North Paddy Field',
          description: 'Monitor water depth, crop health and optimize harvest timing for this rice field.',
          fieldId: '1',
          isBookmarked: false,
        ),
        const FieldContentItem(
          id: '2',
          title: 'South Lowland Rice',
          description: 'Real-time paddy health and soil moisture for irrigated rice.',
          fieldId: '2',
          isBookmarked: false,
        ),
        const FieldContentItem(
          id: '3',
          title: 'Upland Rice Plot',
          description: 'Track rainfall and drought risk for rainfed rice varieties.',
          fieldId: '3',
          isBookmarked: false,
        ),
      ];
}
