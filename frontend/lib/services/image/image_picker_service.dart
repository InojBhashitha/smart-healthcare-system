import 'dart:io';

import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
      maxWidth: 2400,
      maxHeight: 2400,
    );

    if (image == null) return null;

    return File(image.path);
  }

  Future<File?> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
      maxWidth: 2400,
      maxHeight: 2400,
    );

    if (image == null) return null;

    return File(image.path);
  }
}