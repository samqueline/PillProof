import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/medicine_ocr_result.dart';
import '../../services/medicine_ocr_service.dart';

class TabletCoverOcrScreen extends StatefulWidget {
  final String title;

  const TabletCoverOcrScreen({
    super.key,
    this.title = 'Read Tablet Cover',
  });

  @override
  State<TabletCoverOcrScreen> createState() => _TabletCoverOcrScreenState();
}

class _TabletCoverOcrScreenState extends State<TabletCoverOcrScreen> {
  final MedicineOcrService _ocrService = MedicineOcrService();
  bool _isLoading = false;
  MedicineOcrResult? _ocrResult;
  String? _selectedDrugName;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Auto-launch camera on screen open for a seamless photo experience
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _takePhoto();
    });
  }

  Future<void> _takePhoto() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _ocrService.captureFromCameraAndRead();
      if (result != null) {
        setState(() {
          _ocrResult = result;
          _selectedDrugName = result.suggestedDrugName;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (_ocrResult == null && mounted) {
          // If user cancelled photo and no previous result, pop or stay
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not access camera or read photo: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickGallery() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _ocrService.pickFromGalleryAndRead();
      if (result != null) {
        setState(() {
          _ocrResult = result;
          _selectedDrugName = result.suggestedDrugName;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not read image: $e';
        _isLoading = false;
      });
    }
  }

  void _applyResult() {
    if (_ocrResult == null) return;

    // Return final customized OCR result
    final finalResult = MedicineOcrResult(
      suggestedDrugName: _selectedDrugName ?? _ocrResult!.suggestedDrugName,
      brandOrGeneric: _ocrResult!.brandOrGeneric,
      detectedDosage: _ocrResult!.detectedDosage,
      dosageForm: _ocrResult!.dosageForm,
      detectedBatch: _ocrResult!.detectedBatch,
      detectedExpiry: _ocrResult!.detectedExpiry,
      detectedManufacturer: _ocrResult!.detectedManufacturer,
      candidateNames: _ocrResult!.candidateNames,
      recognizedLines: _ocrResult!.recognizedLines,
      imagePath: _ocrResult!.imagePath,
    );

    Navigator.of(context).pop(finalResult);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Pick from Gallery',
            onPressed: _isLoading ? null : _pickGallery,
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            tooltip: 'Retake Photo',
            onPressed: _isLoading ? null : _takePhoto,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _ocrResult != null
              ? _buildResultContent(isDark)
              : _buildInitialPrompt(isDark),
      bottomNavigationBar: _ocrResult != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: Text(
                    'Use "${_selectedDrugName ?? _ocrResult!.suggestedDrugName}"',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _applyResult,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            const Text(
              'Scanning Tablet Packaging...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Reading drug name, dosage strength, and batch details from the cover foil',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialPrompt(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.document_scanner_rounded, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'Capture Tablet Cover',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Position the medicine blister pack or bottle in clear lighting so the drug letters are readable.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Open Camera to Snap Photo'),
              onPressed: _takePhoto,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Select Existing Photo'),
              onPressed: _pickGallery,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.statusExpired, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultContent(bool isDark) {
    final result = _ocrResult!;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Photo preview thumbnail + detected banner
        if (result.imagePath != null && !kIsWeb && File(result.imagePath!).existsSync())
          Container(
            height: 160,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              image: DecorationImage(
                image: FileImage(File(result.imagePath!)),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.statusVerified, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Tablet Cover Captured & Analyzed',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    tooltip: 'Retake',
                    onPressed: _takePhoto,
                  ),
                ],
              ),
            ),
          ),

        // Primary Detected Drug Highlight Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
                      SizedBox(width: 6),
                      Text(
                        'Automatically Read from Cover',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.statusVerified.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'HIGH ACCURACY',
                      style: TextStyle(
                        color: AppColors.statusVerified,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _selectedDrugName ?? result.suggestedDrugName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (result.detectedDosage != null)
                    _buildAttributeChip(Icons.numbers_rounded, 'Strength', result.detectedDosage!),
                  if (result.dosageForm != null)
                    _buildAttributeChip(Icons.medication_liquid_rounded, 'Form', result.dosageForm!),
                  if (result.detectedBatch != null)
                    _buildAttributeChip(Icons.tag_rounded, 'Batch', result.detectedBatch!),
                  if (result.detectedExpiry != null)
                    _buildAttributeChip(Icons.calendar_today_rounded, 'Exp', result.detectedExpiry!),
                  if (result.detectedManufacturer != null)
                    _buildAttributeChip(Icons.business_rounded, 'Mfg', result.detectedManufacturer!),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Candidate Names / Alternate detected letters
        if (result.candidateNames.length > 1) ...[
          const Text(
            'Other Detected Drug Names / Strengths',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap any name to use it instead:',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: result.candidateNames.map((cand) {
              final isSelected = cand == _selectedDrugName;
              return ChoiceChip(
                label: Text(cand),
                selected: isSelected,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _selectedDrugName = cand;
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        // Raw OCR lines extracted from the cover
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text(
              'All Text Read from Tablet Packaging (${result.recognizedLines.length} lines)',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            leading: const Icon(Icons.text_snippet_outlined, size: 20),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: result.recognizedLines.map((line) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedDrugName = line;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Selected: "$line"'),
                              duration: const Duration(milliseconds: 600),
                            ),
                          );
                        },
                        child: Text(
                          line,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttributeChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

