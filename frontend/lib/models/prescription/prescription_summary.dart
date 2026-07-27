class PrescriptionSummary {
  final int prescriptionId;
  final String status;
  final int medicinesFound;
  final String uploadedAt;

  PrescriptionSummary({
    required this.prescriptionId,
    required this.status,
    required this.medicinesFound,
    required this.uploadedAt,
  });

  String get readableUploadedAt {
    final parsed = DateTime.tryParse(uploadedAt);
    if (parsed == null) {
      return uploadedAt;
    }

    final local = parsed.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return "$day/$month/$year $hour:$minute";
  }

  factory PrescriptionSummary.fromJson(Map<String, dynamic> json) {
    return PrescriptionSummary(
      prescriptionId: (json["prescriptionId"] as num).toInt(),
      status: json["status"] ?? "",
      medicinesFound: (json["medicinesFound"] as num).toInt(),
      uploadedAt: json["uploadedAt"]?.toString() ?? "",
    );
  }
}
