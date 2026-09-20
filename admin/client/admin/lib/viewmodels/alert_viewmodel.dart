import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/alert_post.dart';
import '../services/admin_api_service.dart';
import '../services/image_crop_service.dart';

class AlertViewModel extends ChangeNotifier {
  final AdminApiService _apiService = AdminApiService();
  final ImageCropService _cropService = const ImageCropService();
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

  Future<void> pickImage({BuildContext? context}) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (image != null) {
      // Page stays mounted during pick/crop; context is only used for WebUiSettings.
      // ignore: use_build_context_synchronously
      await _setPickedWithCrop(File(image.path), context: context);
    }
  }

  Future<void> pickImageFromCamera({BuildContext? context}) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
    );
    if (image != null) {
      // Page stays mounted during pick/crop; context is only used for WebUiSettings.
      // ignore: use_build_context_synchronously
      await _setPickedWithCrop(File(image.path), context: context);
    }
  }

  /// Opens the crop screen for an already-picked [source] file.
  /// Keeps the original when the user cancels cropping.
  Future<void> _setPickedWithCrop(File source, {BuildContext? context}) async {
    _pickedImage = source;
    notifyListeners();
    try {
      final cropped = await _cropService.cropImage(source, context: context);
      if (cropped != null) {
        _pickedImage = cropped;
        notifyListeners();
      }
    } catch (e) {
      print('[log] AlertViewModel — crop error (keeping original): $e');
    }
  }

  /// Re-opens the crop screen for the current image (edit button on preview).
  Future<void> recropImage({BuildContext? context}) async {
    final current = _pickedImage;
    if (current == null) return;
    try {
      final cropped = await _cropService.cropImage(current, context: context);
      if (cropped != null) {
        _pickedImage = cropped;
        notifyListeners();
      }
    } catch (e) {
      print('[log] AlertViewModel — recrop error: $e');
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
