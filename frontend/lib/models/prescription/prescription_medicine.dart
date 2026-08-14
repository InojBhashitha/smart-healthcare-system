import 'database_medicine.dart';

class PrescriptionMedicine {
  final int id;
  final String medicineName;
  final String strength;
  final String instruction;
  final bool verified;
  final DatabaseMedicine? databaseMedicine;

  PrescriptionMedicine({
    required this.id,
    required this.medicineName,
    required this.strength,
    required this.instruction,
    required this.verified,
    this.databaseMedicine,
  });

  factory PrescriptionMedicine.fromJson(
      Map<String, dynamic> json) {
    return PrescriptionMedicine(
      id: json["id"] ?? json["prescriptionMedicineId"] ?? 0,
      medicineName: json["medicineName"] ?? "",
      strength: json["strength"] ?? "",
      instruction: json["instruction"] ?? "",
      verified: json["verified"] ?? false,
      databaseMedicine:
          json["databaseMedicine"] == null
              ? null
              : DatabaseMedicine.fromJson(
                  json["databaseMedicine"],
                ),
    );
  }
}