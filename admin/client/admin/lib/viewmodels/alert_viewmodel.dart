import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/alert_post.dart';
import '../services/admin_api_service.dart';

class AlertViewModel extends ChangeNotifier {
  final AdminApiService _apiService = AdminApiService();
  final ImagePicker _picker = ImagePicker();

  String _selectedCategory = 'SOB';
  String get selectedCategory => _selectedCategory;

  File? _pickedImage;
  File? get pickedImage => _pickedImage;

  String _message = '';
  String get message => _message;

  bool _isSending = false;
  bool get isSending => _isSending;

  List<AlertPost> _alerts = [];
  List<AlertPost> get alerts => _alerts;

  bool _isLoadingAlerts = false;
  bool get isLoadingAlerts => _isLoadingAlerts;

  void setCategory(String category) {
    print('[log] AlertViewModel — setCategory: $category');
    _selectedCategory = category;
    notifyListeners();
    loadAlerts();
  }

  void setMessage(String value) {
    _message = value;
    notifyListeners();
  }

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (image != null) {
      _pickedImage = File(image.path);
      notifyListeners();
    }
  }

  Future<void> pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
    );
    if (image != null) {
      _pickedImage = File(image.path);
      notifyListeners();
    }
  }

  void clearImage() {
    _pickedImage = null;
    notifyListeners();
  }

  Future<bool> sendAlert() async {
    if (_message.trim().isEmpty) return false;

    print('[log] AlertViewModel — sendAlert: category=$_selectedCategory, message=${_message.substring(0, _message.length > 50 ? 50 : _message.length)}...');
    _isSending = true;
    notifyListeners();

    try {
      String? base64Image;
      if (_pickedImage != null) {
        final bytes = await _pickedImage!.readAsBytes();
        base64Image = base64Encode(bytes);
      }

      await _apiService.createAlert(
        _selectedCategory,
        _message.trim(),
        base64Image,
      );

      print('[log] AlertViewModel — sendAlert: success');
      _pickedImage = null;
      _message = '';
      _isSending = false;
      notifyListeners();

      await loadAlerts();
      return true;
    } catch (e) {
      print('[log] AlertViewModel — sendAlert error: $e');
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadAlerts() async {
    print('[log] AlertViewModel — loadAlerts: category=$_selectedCategory');
    _isLoadingAlerts = true;
    notifyListeners();

    try {
      _alerts = await _apiService.getAlerts(_selectedCategory);
      print('[log] AlertViewModel — loadAlerts: loaded ${_alerts.length} alerts');
    } catch (e) {
      print('[log] AlertViewModel — loadAlerts error: $e');
      _alerts = [];
    } finally {
      _isLoadingAlerts = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAlert(String id) async {
    print('[log] AlertViewModel — deleteAlert: id=$id');
    try {
      final success = await _apiService.deleteAlert(id);
      print('[log] AlertViewModel — deleteAlert result: $success');
      if (success) {
        await loadAlerts();
      }
      return success;
    } catch (e) {
      print('[log] AlertViewModel — deleteAlert error: $e');
      return false;
    }
  }
}
