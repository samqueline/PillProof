import '../models/medicine_ocr_result.dart';

class MedicineTextParser {
  /// Well-known pharmaceutical active ingredients & popular brand names
  static const List<String> _knownDrugs = [
    'Amoxicillin',
    'Augmentin',
    'Paracetamol',
    'Acetaminophen',
    'Crocin',
    'Dolo',
    'Calpol',
    'Panadol',
    'Ibuprofen',
    'Brufen',
    'Metformin',
    'Glycomet',
    'Atorvastatin',
    'Lipitor',
    'Atorva',
    'Azithromycin',
    'Azee',
    'Zithromax',
    'Cetirizine',
    'Cetzine',
    'Zyrtec',
    'Pantoprazole',
    'Pan',
    'Pantocid',
    'Omeprazole',
    'Omez',
    'Prilosec',
    'Montelukast',
    'Montair',
    'Telmisartan',
    'Telma',
    'Amlodipine',
    'Amlong',
    'Norvasc',
    'Ciprofloxacin',
    'Ciplox',
    'Cipro',
    'Losartan',
    'Diclofenac',
    'Voveran',
    'Aspirin',
    'Ecosprin',
    'Disprin',
    'Doxycycline',
    'Doxylab',
    'Levocetirizine',
    'Rabeprazole',
    'Ranitidine',
    'Rantac',
    'Metoprolol',
    'Atenolol',
    'Rosuvastatin',
    'Clopidogrel',
    'Furosemide',
    'Gabapentin',
    'Levothyroxine',
    'Eltroxin',
    'Thyronorm',
  ];

  /// Common pharmacologic drug name suffixes
  static const List<String> _pharmaSuffixes = [
    'cillin',
    'statin',
    'olol',
    'pril',
    'sartan',
    'dipine',
    'prazole',
    'tidine',
    'mycin',
    'cycline',
    'floxacin',
    'zole',
    'fenac',
    'mol',
    'vir',
    'mab',
    'kast',
    'glitin',
    'formin',
    'nazole',
    'profen',
    'bital',
    'sone',
  ];

  /// Packaging boilerplate terms that should NOT be picked as the drug name
  static const List<String> _noisePhrases = [
    'schedule h',
    'schedule g',
    'prescription',
    'store below',
    'store at',
    'protect from',
    'keep out of',
    'reach of children',
    'not for injection',
    'each uncoated',
    'each film coated',
    'each tablet contains',
    'each capsule contains',
    'contains:',
    'mfg. lic',
    'mfg lic',
    'licence no',
    'manufactured',
    'marketed by',
    'warning:',
    'caution:',
    'as directed by',
    'physician',
    'colour:',
    'excipients',
    'dosage:',
    'replace cap',
    'do not chew',
    'for external use',
    'batch no',
    'b.no',
    'exp. date',
    'expiry',
    'mrp',
    'max retail',
    'inclusive of all',
  ];

  /// Well-known pharmaceutical manufacturers
  static const List<String> _knownManufacturers = [
    'GSK',
    'GlaxoSmithKline',
    'Pfizer',
    'Abbott',
    'Sun Pharma',
    'Sun Pharmaceutical',
    'Cipla',
    'Lupin',
    'Dr. Reddy\'s',
    'Dr Reddys',
    'Mankind',
    'Zydus',
    'Alkem',
    'Torrent Pharma',
    'Torrent',
    'Intas',
    'Glenmark',
    'AstraZeneca',
    'Novartis',
    'Sanofi',
    'Bayer',
    'Micro Labs',
    'Alembic',
  ];

  /// Analyzes text extracted from tablet cover photo and extracts drug attributes
  static MedicineOcrResult parse(List<String> rawLines, {String? imagePath}) {
    final cleanedLines = rawLines
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    String? detectedDosage;
    String? dosageForm;
    String? detectedBatch;
    String? detectedExpiry;
    String? detectedManufacturer;

    final candidates = <_ScoredCandidate>[];

    // Regex for dosage strength: 500mg, 500 mg, 650 mg, 10 mg, 250mg/5ml
    final dosageRegex = RegExp(
      r'(\d+(?:\.\d+)?\s*(?:mg|g|mcg|ml|iu|mg\/ml))\b',
      caseSensitive: false,
    );

    // Regex for dosage form: Tablets, Capsules, etc.
    final formRegex = RegExp(
      r'\b(tablets?|capsules?|caplets?|suspension|syrup|pills?)\b',
      caseSensitive: false,
    );

    // Regex for batch: B.No. XYZ-123 or Batch: ABC
    final batchRegex = RegExp(
      r'(?:b\.?\s*no\.?|batch\s*no\.?|batch|lot\s*no\.?|lot|b\.n\.)\s*[:#-]?\s*([a-zA-Z0-9\-_/]+)',
      caseSensitive: false,
    );

    // Regex for expiry: EXP 12/27 or EXP. 2027-12-31 or 12/2027
    final expiryRegex = RegExp(
      r'(?:exp\.?\s*date|exp\.?|expiry\s*date|expiry|use\s*before)\s*[:#-]?\s*([0-9]{1,2}[/-][0-9]{2,4}|[a-zA-Z]{3}[/-][0-9]{2,4}|[0-9]{4}[/-][0-9]{1,2}[/-][0-9]{1,2})',
      caseSensitive: false,
    );

    // 1. First pass: extract dosage, form, batch, expiry, manufacturer across all lines
    for (final line in cleanedLines) {
      if (detectedDosage == null) {
        final dMatch = dosageRegex.firstMatch(line);
        if (dMatch != null) {
          detectedDosage = dMatch.group(1);
        }
      }

      if (dosageForm == null) {
        final fMatch = formRegex.firstMatch(line);
        if (fMatch != null) {
          final formWord = fMatch.group(1)!.toLowerCase();
          dosageForm = formWord.startsWith('tab') ? 'Tablet' : 'Capsule';
        }
      }

      if (detectedBatch == null) {
        final bMatch = batchRegex.firstMatch(line);
        if (bMatch != null) {
          detectedBatch = bMatch.group(1);
        }
      }

      if (detectedExpiry == null) {
        final eMatch = expiryRegex.firstMatch(line);
        if (eMatch != null) {
          detectedExpiry = _normalizeExpiry(eMatch.group(1)!);
        }
      }

      if (detectedManufacturer == null) {
        for (final mfg in _knownManufacturers) {
          if (line.toLowerCase().contains(mfg.toLowerCase())) {
            detectedManufacturer = mfg;
            break;
          }
        }
      }
    }

    // 2. Second pass: Score each line / word candidate for drug name
    for (final line in cleanedLines) {
      final lowerLine = line.toLowerCase();

      // Check if line is purely noise/disclaimer
      if (_isNoise(lowerLine)) {
        continue;
      }

      // Check if line has known drug
      for (final known in _knownDrugs) {
        if (lowerLine.contains(known.toLowerCase())) {
          // If line has both the drug name and dosage, give highest priority
          double score = 100.0;
          if (detectedDosage != null && line.contains(detectedDosage)) {
            score += 20.0;
          }
          candidates.add(_ScoredCandidate(text: _cleanCandidate(line, known, detectedDosage), score: score, baseName: known));
        }
      }

      // Check for pharma suffix matching
      final words = line.split(RegExp(r'[\s,]+'));
      for (final word in words) {
        final cleanWord = word.replaceAll(RegExp(r'[^a-zA-Z]'), '');
        if (cleanWord.length < 4) continue;

        final lowerWord = cleanWord.toLowerCase();
        for (final suffix in _pharmaSuffixes) {
          if (lowerWord.endsWith(suffix) && lowerWord.length > suffix.length + 2) {
            candidates.add(_ScoredCandidate(
              text: cleanWord,
              score: 70.0,
              baseName: cleanWord,
            ));
            break;
          }
        }

        // Check for prominent ALL-CAPS brand names (e.g. CROCIN, AUGMENTIN, DOLO)
        if (cleanWord.length >= 4 && cleanWord == cleanWord.toUpperCase() && !_isNoiseWord(cleanWord)) {
          candidates.add(_ScoredCandidate(
            text: _capitalizeFirst(cleanWord),
            score: 50.0,
            baseName: _capitalizeFirst(cleanWord),
          ));
        }
      }

      // If line contains "Tablets IP" or "Capsules IP", the word preceding it is very likely the drug name!
      final ipMatch = RegExp(r'([a-zA-Z\s]+)\s+(?:Tablets|Capsules)?\s*(?:IP|BP|USP)', caseSensitive: false).firstMatch(line);
      if (ipMatch != null) {
        final drugPart = ipMatch.group(1)!.trim();
        if (drugPart.isNotEmpty && !_isNoise(drugPart.toLowerCase())) {
          candidates.add(_ScoredCandidate(
            text: drugPart,
            score: 85.0,
            baseName: drugPart,
          ));
        }
      }
    }

    // Deduplicate and rank candidates
    final uniqueCandidateMap = <String, _ScoredCandidate>{};
    for (final c in candidates) {
      final key = c.baseName.toLowerCase();
      if (!uniqueCandidateMap.containsKey(key) || uniqueCandidateMap[key]!.score < c.score) {
        uniqueCandidateMap[key] = c;
      }
    }

    final sortedCandidates = uniqueCandidateMap.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    String suggestedDrugName;
    String? brandOrGeneric;

    if (sortedCandidates.isNotEmpty) {
      final top = sortedCandidates.first;
      brandOrGeneric = top.baseName;
      if (detectedDosage != null && !top.text.toLowerCase().contains(detectedDosage.toLowerCase())) {
        suggestedDrugName = '${top.baseName} $detectedDosage';
      } else {
        suggestedDrugName = top.text;
      }
    } else {
      // Fallback: pick the first non-noise line that isn't too long or short
      final fallbackLine = cleanedLines.firstWhere(
        (l) => l.length >= 4 && l.length <= 40 && !_isNoise(l.toLowerCase()),
        orElse: () => cleanedLines.isNotEmpty ? cleanedLines.first : 'Unknown Medication',
      );
      suggestedDrugName = fallbackLine;
      brandOrGeneric = fallbackLine;
    }

    // Build the list of string candidate suggestions
    final candidateNames = sortedCandidates.map((c) {
      if (detectedDosage != null && !c.text.toLowerCase().contains(detectedDosage.toLowerCase())) {
        return '${c.baseName} $detectedDosage';
      }
      return c.text;
    }).toList();

    return MedicineOcrResult(
      suggestedDrugName: suggestedDrugName,
      brandOrGeneric: brandOrGeneric,
      detectedDosage: detectedDosage,
      dosageForm: dosageForm,
      detectedBatch: detectedBatch,
      detectedExpiry: detectedExpiry,
      detectedManufacturer: detectedManufacturer,
      candidateNames: candidateNames,
      recognizedLines: cleanedLines,
      imagePath: imagePath,
    );
  }

  static bool _isNoise(String lower) {
    for (final phrase in _noisePhrases) {
      if (lower.contains(phrase)) return true;
    }
    return false;
  }

  static bool _isNoiseWord(String word) {
    final lower = word.toLowerCase();
    const noiseWords = {
      'tablets',
      'tablet',
      'capsules',
      'capsule',
      'contains',
      'warning',
      'caution',
      'protect',
      'dosage',
      'pharma',
      'limited',
      'batch',
      'expiry',
      'mfg',
      'lic',
    };
    return noiseWords.contains(lower);
  }

  static String _cleanCandidate(String line, String knownDrug, String? dosage) {
    // If line has the known drug and clean dosage, combine cleanly
    if (dosage != null && !line.toLowerCase().contains(dosage.toLowerCase())) {
      return '$knownDrug $dosage';
    }
    // Clean out pharmacopeia tags like IP, BP, USP, Tablets from the clean title
    final clean = line
        .replaceAll(RegExp(r'\b(?:Tablets?|Capsules?|Caplets?|IP|BP|USP)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return clean.isNotEmpty ? clean : knownDrug;
  }

  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String _normalizeExpiry(String exp) {
    // E.g., MM/YY -> 20YY-MM-01 or MM/YYYY -> YYYY-MM-01
    final slashParts = exp.split(RegExp(r'[/-]'));
    if (slashParts.length == 2) {
      final p1 = slashParts[0].trim();
      final p2 = slashParts[1].trim();
      if (p1.length <= 2 && (p2.length == 2 || p2.length == 4)) {
        final month = p1.padLeft(2, '0');
        final year = p2.length == 2 ? '20$p2' : p2;
        return '$year-$month-01';
      }
    }
    return exp;
  }
}

class _ScoredCandidate {
  final String text;
  final double score;
  final String baseName;

  _ScoredCandidate({
    required this.text,
    required this.score,
    required this.baseName,
  });
}

