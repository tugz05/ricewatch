import 'package:flutter/foundation.dart';
import '../models/field_model.dart';

/// Controller for field detail screen: selected field, selected crop.
class FieldDetailController extends ChangeNotifier {
  FieldModel? _field;
  int _selectedCropIndex = 0;
  final List<String> _crops = const ['Carrot', 'Pumpkin', 'Vegetable'];

  FieldModel? get field => _field;
  int get selectedCropIndex => _selectedCropIndex;
  List<String> get crops => _crops;
  String get selectedCrop => _crops[_selectedCropIndex];

  void setField(FieldModel? field) {
    _field = field;
    notifyListeners();
  }

  void setSelectedCrop(int index) {
    _selectedCropIndex = index.clamp(0, _crops.length - 1);
    notifyListeners();
  }
}
