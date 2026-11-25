class MedicineModel {
  final String id;
  final String brandName;
  final String genericName;
  final String dosageStrength;
  final String dosageForm;
  final String manufacturer;
  final String? barcode;
  final String? batchNumber;
  final DateTime? expiryDate;
  final String verificationStatus;

  MedicineModel({
    required this.id,
    required this.brandName,
    required this.genericName,
    required this.dosageStrength,
    required this.dosageForm,
    required this.manufacturer,
    this.barcode,
    this.batchNumber,
    this.expiryDate,
    required this.verificationStatus,
  });

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    final name = json['name'] ?? json['brandName'] ?? '';
    final generic = json['composition'] ?? json['genericName'] ?? '';
    final barcode = json['gtin'] ?? json['barcode'];
    return MedicineModel(
      id: json['_id'] ?? json['id'] ?? barcode ?? '',
      brandName: name,
      genericName: generic,
      dosageStrength: json['dosageStrength'] ?? '500mg',
      dosageForm: json['dosageForm'] ?? 'Tablet',
      manufacturer: json['manufacturer'] ?? '',
      barcode: barcode,
      batchNumber: json['batchNumber'] ?? json['batch_number'],
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'].toString())
          : (json['expiry_date'] != null ? DateTime.tryParse(json['expiry_date'].toString()) : null),
      verificationStatus: json['verificationStatus'] ?? json['status'] ?? 'verified',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brandName': brandName,
      'genericName': genericName,
      'dosageStrength': dosageStrength,
      'dosageForm': dosageForm,
      'manufacturer': manufacturer,
      'barcode': barcode,
      'batchNumber': batchNumber,
      'expiryDate': expiryDate?.toIso8601String(),
      'verificationStatus': verificationStatus,
    };
  }
}
