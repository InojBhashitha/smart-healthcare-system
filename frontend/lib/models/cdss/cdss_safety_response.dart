class CdssSafetyResponse {
  final String safetyStatus;
  final int totalAlertsCount;
  final List<AllergyAlert> allergyAlerts;
  final List<InteractionWarning> interactionWarnings;
  final List<DuplicateFlag> duplicateFlags;

  CdssSafetyResponse({
    required this.safetyStatus,
    required this.totalAlertsCount,
    required this.allergyAlerts,
    required this.interactionWarnings,
    required this.duplicateFlags,
  });

  factory CdssSafetyResponse.fromJson(Map<String, dynamic> json) {
    return CdssSafetyResponse(
      safetyStatus: json['safetyStatus'] ?? 'SAFE',
      totalAlertsCount: json['totalAlertsCount'] ?? 0,
      allergyAlerts: (json['allergyAlerts'] as List? ?? [])
          .map((e) => AllergyAlert.fromJson(e))
          .toList(),
      interactionWarnings: (json['interactionWarnings'] as List? ?? [])
          .map((e) => InteractionWarning.fromJson(e))
          .toList(),
      duplicateFlags: (json['duplicateFlags'] as List? ?? [])
          .map((e) => DuplicateFlag.fromJson(e))
          .toList(),
    );
  }
}

class AllergyAlert {
  final String medicineName;
  final String matchedAllergen;
  final String severity;
  final String message;

  AllergyAlert({
    required this.medicineName,
    required this.matchedAllergen,
    required this.severity,
    required this.message,
  });

  factory AllergyAlert.fromJson(Map<String, dynamic> json) {
    return AllergyAlert(
      medicineName: json['medicineName'] ?? '',
      matchedAllergen: json['matchedAllergen'] ?? '',
      severity: json['severity'] ?? 'HIGH',
      message: json['message'] ?? '',
    );
  }
}

class InteractionWarning {
  final String medicine1;
  final String medicine2;
  final String description;
  final bool isWithCurrentMedication;

  InteractionWarning({
    required this.medicine1,
    required this.medicine2,
    required this.description,
    required this.isWithCurrentMedication,
  });

  factory InteractionWarning.fromJson(Map<String, dynamic> json) {
    return InteractionWarning(
      medicine1: json['medicine1'] ?? '',
      medicine2: json['medicine2'] ?? '',
      description: json['description'] ?? '',
      isWithCurrentMedication: json['isWithCurrentMedication'] ?? false,
    );
  }
}

class DuplicateFlag {
  final String medicine1;
  final String medicine2;
  final String sharedIngredient;
  final String message;

  DuplicateFlag({
    required this.medicine1,
    required this.medicine2,
    required this.sharedIngredient,
    required this.message,
  });

  factory DuplicateFlag.fromJson(Map<String, dynamic> json) {
    return DuplicateFlag(
      medicine1: json['medicine1'] ?? '',
      medicine2: json['medicine2'] ?? '',
      sharedIngredient: json['sharedIngredient'] ?? '',
      message: json['message'] ?? '',
    );
  }
}
