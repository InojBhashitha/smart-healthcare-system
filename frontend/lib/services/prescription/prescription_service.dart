import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../models/prescription/prescription_details.dart';
import '../../models/prescription/prescription_summary.dart';
import '../../models/prescription/upload_prescription_response.dart';

class PrescriptionService {
  final Dio _dio = DioClient.dio;

  Future<UploadPrescriptionResponse> uploadPrescription(
      File image) async {
    final formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(
        image.path,
        filename: image.path.split('/').last,
      ),
    });

    final response = await _dio.post(
      ApiConstants.uploadPrescription,
      data: formData,
    );

    return UploadPrescriptionResponse.fromJson(
      response.data,
    );
  }

  Future<List<PrescriptionSummary>> getPrescriptions() async {
    final response = await _dio.get(
      ApiConstants.prescriptions,
    );

    return (response.data as List)
        .map((dynamic item) => PrescriptionSummary.fromJson(
              item as Map<String, dynamic>,
            ))
        .toList();
  }

  Future<PrescriptionDetails> getPrescription(
      int prescriptionId) async {
    final response = await _dio.get(
      "${ApiConstants.prescriptions}/$prescriptionId",
    );

    return PrescriptionDetails.fromJson(
      response.data,
    );
  }

  Future<Map<String, dynamic>> analyzeCdssSafety(int prescriptionId) async {
    final response = await _dio.get("/api/cdss/analyze/$prescriptionId");
    return response.data as Map<String, dynamic>;
  }

  Future<void> updateMedicine(
    int medicineId, {
    required String medicineName,
    required String strength,
    required String instruction,
    required bool verified,
  }) async {
    await _dio.put(
      "/api/prescription-medicines/$medicineId",
      data: {
        "medicineName": medicineName,
        "strength": strength,
        "instruction": instruction,
        "verified": verified,
      },
    );
  }
}