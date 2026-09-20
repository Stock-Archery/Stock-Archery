import 'dart:io';

import 'package:flutter/material.dart';

import '../views/image_crop_page.dart';

/// Opens the free-form crop screen for [source] and returns the cropped file.
/// Returns null when the user cancels (or no context) — callers should then
/// keep the original image.
class ImageCropService {
  const ImageCropService();

  Future<File?> cropImage(File source, {BuildContext? context}) async {
    if (context == null) return null;
    return Navigator.push<File?>(
      context,
      MaterialPageRoute(builder: (_) => ImageCropPage(imageFile: source)),
    );
  }
}
