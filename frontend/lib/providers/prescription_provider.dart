import 'dart:io';

import 'package:flutter/material.dart';

import '../models/prescription/prescription_details.dart';
import '../models/prescription/prescription_summary.dart';
import '../models/prescription/upload_prescription_response.dart';
import '../services/image/image_picker_service.dart';
import '../services/prescription/prescription_service.dart';

class PrescriptionProvider extends ChangeNotifier {
  final ImagePickerService _pickerService = ImagePickerService();
  final PrescriptionService _prescriptionService = PrescriptionService();

  File? _selectedImage;
  File? get selectedImage => _selectedImage;

  PrescriptionDetails? _prescriptionDetails;
  PrescriptionDetails? get prescriptionDetails => _prescriptionDetails;

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  bool _isHistoryLoading = false;
  bool get isHistoryLoading => _isHistoryLoading;

  List<PrescriptionSummary> _prescriptionSummaries = [];
  List<PrescriptionSummary> get prescriptionSummaries => _prescriptionSummaries;

  UploadPrescriptionResponse? _uploadResponse;
  UploadPrescriptionResponse? get uploadResponse => _uploadResponse;

  Future<void> pickFromCamera() async {
    _selectedImage = await _pickerService.pickFromCamera();
    notifyListeners();
  }

  Future<void> pickFromGallery() async {
    _selectedImage = await _pickerService.pickFromGallery();
    notifyListeners();
  }

  void removeImage() {
    _selectedImage = null;
    _uploadResponse = null;
    notifyListeners();
  }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> uploadPrescription() async {
    if (_selectedImage == null) return;

    _isUploading = true;
    _errorMessage = null;
    _uploadResponse = null;
    notifyListeners();

    try {
      _uploadResponse = await _prescriptionService.uploadPrescription(
        _selectedImage!,
      );

      if (_uploadResponse?.prescriptionId != null) {
        await loadPrescription(
          _uploadResponse!.prescriptionId!,
        );

        debugPrint("==============");
        debugPrint(_prescriptionDetails?.status);
        debugPrint(_prescriptionDetails?.extractedText);
        debugPrint(
            _prescriptionDetails?.medicines.length.toString());
        debugPrint("==============");
      } else if (_uploadResponse?.message != null) {
        _errorMessage = _uploadResponse!.message;
      }
    } catch (e) {
      _errorMessage = "Upload failed: ${e.toString().replaceAll('Exception:', '').trim()}";
      debugPrint("Prescription upload error: $e");
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<void> loadPrescription(int prescriptionId) async {
    _prescriptionDetails =
        await _prescriptionService.getPrescription(
      prescriptionId,
    );

    notifyListeners();
  }

  Future<void> loadPrescriptionHistory() async {
    if (_isHistoryLoading) return;

    _isHistoryLoading = true;
    notifyListeners();

    try {
      _prescriptionSummaries = await _prescriptionService.getPrescriptions();
    } finally {
      _isHistoryLoading = false;
      notifyListeners();
    }
  }
}