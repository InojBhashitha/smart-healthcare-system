import 'dart:io';

import 'package:flutter/material.dart';

import '../models/cdss/cdss_safety_response.dart';
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

  CdssSafetyResponse? _cdssReport;
  CdssSafetyResponse? get cdssReport => _cdssReport;

  bool _isCdssLoading = false;
  bool get isCdssLoading => _isCdssLoading;

  Future<void> loadPrescription(int prescriptionId) async {
    _prescriptionDetails =
        await _prescriptionService.getPrescription(
      prescriptionId,
    );

    notifyListeners();

    // Also load CDSS safety analysis
    await loadCdssSafety(prescriptionId);
  }

  Future<void> loadCdssSafety(int prescriptionId) async {
    _isCdssLoading = true;
    notifyListeners();

    try {
      final json = await _prescriptionService.analyzeCdssSafety(prescriptionId);
      _cdssReport = CdssSafetyResponse.fromJson(json);
    } catch (e) {
      debugPrint("Failed to load CDSS safety analysis: $e");
      _cdssReport = null;
    } finally {
      _isCdssLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateMedicine(
    int medicineId, {
    required String name,
    required String strength,
    required String instruction,
  }) async {
    await _prescriptionService.updateMedicine(
      medicineId,
      medicineName: name,
      strength: strength,
      instruction: instruction,
      verified: true,
    );

    if (_prescriptionDetails?.id != null) {
      await loadPrescription(_prescriptionDetails!.id);
    }
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