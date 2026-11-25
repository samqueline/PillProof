import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/medical_mesh_background.dart';
import '../../../ocr/models/medicine_ocr_result.dart';
import '../../../ocr/presentation/screens/tablet_cover_ocr_screen.dart';
import '../../../scanner/models/scan_result.dart';
import '../../../scanner/presentation/screens/qr_camera_scanner_screen.dart';
import '../verification_controller.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final _barcodeController = TextEditingController();
  final _brandNameController = TextEditingController();
  final _batchNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _manufacturerController = TextEditingController();

  @override
  void dispose() {
    _barcodeController.dispose();
    _brandNameController.dispose();
    _batchNumberController.dispose();
    _expiryDateController.dispose();
    _manufacturerController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcodeWithCamera() async {
    final result = await Navigator.of(context).push<ScanResult>(
      MaterialPageRoute(
        builder: (_) => const QrCameraScannerScreen(
          title: 'Scan QR / Medicine Barcode',
          hintText: 'Align the barcode or QR code on the packaging',
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _barcodeController.text = result.barcode;
        if (result.batchNumber != null && result.batchNumber!.isNotEmpty) {
          _batchNumberController.text = result.batchNumber!;
        }
        if (result.expiryDate != null && result.expiryDate!.isNotEmpty) {
          _expiryDateController.text = result.expiryDate!;
        }
        if (result.medicineName != null && result.medicineName!.isNotEmpty) {
          _brandNameController.text = result.medicineName!;
        }
      });

      // Automatically run verification
      _verifyMedicine();
    }
  }

  Future<void> _readCoverWithCamera() async {
    final result = await Navigator.of(context).push<MedicineOcrResult>(
      MaterialPageRoute(
        builder: (_) => const TabletCoverOcrScreen(
          title: 'Read Tablet Packaging (OCR)',
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _brandNameController.text = result.formattedDisplayName;
        if (result.detectedBatch != null && result.detectedBatch!.isNotEmpty) {
          _batchNumberController.text = result.detectedBatch!;
        }
        if (result.detectedExpiry != null && result.detectedExpiry!.isNotEmpty) {
          _expiryDateController.text = result.detectedExpiry!;
        }
        if (result.detectedManufacturer != null && result.detectedManufacturer!.isNotEmpty) {
          _manufacturerController.text = result.detectedManufacturer!;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Read from tablet cover: "${result.suggestedDrugName}"'),
          backgroundColor: AppColors.statusVerified,
        ),
      );
    }
  }

  void _verifyMedicine() {
    final barcode = _barcodeController.text.trim();
    final name = _brandNameController.text.trim();
    final batch = _batchNumberController.text.trim();
    final manufacturer = _manufacturerController.text.trim();
    final expiry = _expiryDateController.text.trim();

    if (barcode.isEmpty && name.isEmpty && batch.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please scan/enter a barcode, or a medicine name and batch number.'),
        ),
      );
      return;
    }

    ref.read(verificationProvider.notifier).verify(
          barcode: barcode.isNotEmpty ? barcode : null,
          name: name.isNotEmpty ? name : null,
          batchNumber: batch.isNotEmpty ? batch : null,
          manufacturer: manufacturer.isNotEmpty ? manufacturer : null,
          expiryDate: expiry.isNotEmpty ? expiry : null,
        );
  }

  void _fillDemo(String barcode, String name, String batch, String exp, String mfg) {
    setState(() {
      _barcodeController.text = barcode;
      _brandNameController.text = name;
      _batchNumberController.text = batch;
      _expiryDateController.text = exp;
      _manufacturerController.text = mfg;
    });
  }

  @override
  Widget build(BuildContext context) {
    final verificationState = ref.watch(verificationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Medicine', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            ref.read(verificationProvider.notifier).clear();
            context.go('/dashboard');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Camera QR / Barcode Scanner',
            onPressed: _scanBarcodeWithCamera,
          ),
          IconButton(
            icon: const Icon(Icons.document_scanner_rounded),
            tooltip: 'Camera Tablet Cover OCR',
            onPressed: _readCoverWithCamera,
          ),
        ],
      ),
      body: MedicalMeshBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Camera Quick Scan Actions Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Instant Camera Scanning',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Scan a QR/barcode or take a photo of the tablet packaging to read details automatically.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primaryDark,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                          label: const Text('Scan QR / Barcode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: _scanBarcodeWithCamera,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.camera_alt_rounded, size: 20),
                          label: const Text('Read Cover (OCR)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: _readCoverWithCamera,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24, height: 16),
                  const Text(
                    'Quick Demo Test Batches:',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ActionChip(
                        label: const Text('Verified (Augmentin)'),
                        backgroundColor: Colors.white,
                        labelStyle: const TextStyle(color: AppColors.primaryDark, fontSize: 11, fontWeight: FontWeight.bold),
                        onPressed: () => _fillDemo('08901230000025', 'Augmentin 625 Duo Tablet', 'B1001', '2028-05-27', 'Cipla Ltd'),
                      ),
                      ActionChip(
                        label: const Text('Verified (Amoxicillin)'),
                        backgroundColor: Colors.white,
                        labelStyle: const TextStyle(color: AppColors.primaryDark, fontSize: 11, fontWeight: FontWeight.bold),
                        onPressed: () => _fillDemo('08901234567890', 'Amoxicillin 500mg Trihydrate Capsules', 'B2045', '2027-12-31', 'Sun Pharmaceutical Industries Ltd'),
                      ),
                      ActionChip(
                        label: const Text('Expired Demo Batch'),
                        backgroundColor: const Color(0xFFFEE2E2),
                        labelStyle: const TextStyle(color: AppColors.statusExpired, fontSize: 11, fontWeight: FontWeight.bold),
                        onPressed: () => _fillDemo('08901230000025', 'Augmentin 625 Duo Tablet', 'B1001', '2023-01-01', 'Cipla Ltd'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form Fields
            CustomTextField(
              controller: _barcodeController,
              label: 'Package Barcode / QR (Level 1 Match)',
              hint: 'e.g., 8901234567890',
              prefixIcon: Icons.qr_code_rounded,
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                tooltip: 'Scan Barcode / QR',
                onPressed: _scanBarcodeWithCamera,
              ),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _brandNameController,
              label: 'Medicine Name',
              hint: 'e.g., Amoxicillin 500mg',
              prefixIcon: Icons.medication_rounded,
              suffixIcon: IconButton(
                icon: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                tooltip: 'Read from Tablet Cover (OCR)',
                onPressed: _readCoverWithCamera,
              ),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _batchNumberController,
              label: 'Batch Number (Level 2 Match)',
              hint: 'e.g., AMX-2026-X1',
              prefixIcon: Icons.tag_rounded,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _expiryDateController,
              label: 'Expiration Date (YYYY-MM-DD)',
              hint: 'e.g., 2027-12-31',
              prefixIcon: Icons.calendar_today_rounded,
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _manufacturerController,
              label: 'Manufacturer (Optional)',
              hint: 'e.g., GSK Pharmaceuticals',
              prefixIcon: Icons.business_rounded,
            ),
            const SizedBox(height: 24),

            // Submit Button
            CustomButton(
              text: 'Verify Medicine Details',
              icon: Icons.shield_rounded,
              isLoading: verificationState.isLoading,
              onPressed: _verifyMedicine,
            ),
            const SizedBox(height: 24),

            // Live Verification Result Display
            if (verificationState.result != null)
              _buildResultCard(context, verificationState.result!),

            if (verificationState.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.statusExpired.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.statusExpired.withValues(alpha: 0.3)),
                ),
                child: Text(
                  verificationState.errorMessage!,
                  style: const TextStyle(color: AppColors.statusExpired, fontSize: 13),
                ),
              ),

            const SizedBox(height: 16),
            Text(
              AppStrings.safetyNotice,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, dynamic result) {
    final status = result.status as String;
    final message = result.message as String;
    final medicine = result.matchedMedicine;

    Color cardColor;
    IconData icon;
    VerificationStatus badgeStatus;

    switch (status) {
      case 'VERIFIED':
        cardColor = AppColors.statusVerified;
        icon = Icons.verified_rounded;
        badgeStatus = VerificationStatus.verified;
        break;
      case 'REVIEW':
        cardColor = AppColors.statusReview;
        icon = Icons.warning_amber_rounded;
        badgeStatus = VerificationStatus.reviewRecommended;
        break;
      case 'EXPIRED':
        cardColor = AppColors.statusExpired;
        icon = Icons.error_outline_rounded;
        badgeStatus = VerificationStatus.expired;
        break;
      case 'NO_MATCH':
      default:
        cardColor = AppColors.statusWarning;
        icon = Icons.help_outline_rounded;
        badgeStatus = VerificationStatus.unverified;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: cardColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    status,
                    style: TextStyle(
                      color: cardColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              StatusBadge(status: badgeStatus),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          if (medicine != null) ...[
            const Divider(height: 20),
            Text(
              'Matched: ${medicine.brandName} (${medicine.dosageStrength})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Manufacturer: ${medicine.manufacturer}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Batch: ${medicine.batchNumber ?? "N/A"}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
