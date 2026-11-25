class MedicineOcrResult {
  /// The most likely drug/medicine name extracted from the cover
  final String suggestedDrugName;

  /// The active generic or brand name without dosage
  final String? brandOrGeneric;

  /// Extracted dosage strength (e.g. "500 mg", "650mg", "10 mg")
  final String? detectedDosage;

  /// Dosage form if found (e.g. "Tablet", "Capsule")
  final String? dosageForm;

  /// Detected batch number if printed on foil/cover
  final String? detectedBatch;

  /// Detected expiry date if printed on foil/cover (YYYY-MM-DD or MM/YY)
  final String? detectedExpiry;

  /// Detected manufacturer name if found
  final String? detectedManufacturer;

  /// All potential drug name candidates ranked by confidence
  final List<String> candidateNames;

  /// All cleaned lines of text detected from the packaging
  final List<String> recognizedLines;

  /// Path to the captured photo
  final String? imagePath;

  const MedicineOcrResult({
    required this.suggestedDrugName,
    this.brandOrGeneric,
    this.detectedDosage,
    this.dosageForm,
    this.detectedBatch,
    this.detectedExpiry,
    this.detectedManufacturer,
    this.candidateNames = const [],
    this.recognizedLines = const [],
    this.imagePath,
  });

  /// Formatted full display name, combining drug name + strength if available
  String get formattedDisplayName {
    if (detectedDosage != null && !suggestedDrugName.toLowerCase().contains(detectedDosage!.toLowerCase())) {
      return '$suggestedDrugName $detectedDosage';
    }
    return suggestedDrugName;
  }
}

