class ScanResult {
  final String rawCode;
  final String barcode;
  final String? batchNumber;
  final String? expiryDate;
  final String? serialNumber;
  final String? medicineName;
  final String format;

  const ScanResult({
    required this.rawCode,
    required this.barcode,
    this.batchNumber,
    this.expiryDate,
    this.serialNumber,
    this.medicineName,
    this.format = 'UNKNOWN',
  });

  /// Intelligent parser for GS1 DataMatrix, QR codes, JSON payloads, and standard 1D barcodes.
  factory ScanResult.fromRaw(String raw, {String format = 'UNKNOWN'}) {
    final trimmed = raw.trim();

    // 1. Check if the QR code is formatted as JSON
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final parsed = _tryParseJson(trimmed);
        if (parsed != null) return parsed;
      } catch (_) {}
    }

    // 2. Check for GS1 Parenthesized Format: e.g., (01)08901234567890(17)271231(10)BATCH123
    if (trimmed.contains('(01)') || trimmed.contains('(17)') || trimmed.contains('(10)')) {
      return _parseParenthesizedGs1(trimmed, format);
    }

    // 3. Check for GS1 FNC1 / Raw Delimited Format: 01089012345678901727123110...
    if (trimmed.startsWith('01') && trimmed.length >= 16) {
      final gs1Parsed = _parseRawGs1(trimmed, format);
      if (gs1Parsed != null) return gs1Parsed;
    }

    // 4. Standard 1D Barcode or generic QR code content
    return ScanResult(
      rawCode: trimmed,
      barcode: trimmed,
      format: format,
    );
  }

  static ScanResult? _tryParseJson(String jsonStr) {
    // Basic regex extraction without external json dependency issues
    final barcodeMatch = RegExp(r'"(?:barcode|gtin|code)"\s*:\s*"([^"]+)"', caseSensitive: false).firstMatch(jsonStr);
    final batchMatch = RegExp(r'"(?:batch|batchNumber|lot)"\s*:\s*"([^"]+)"', caseSensitive: false).firstMatch(jsonStr);
    final expiryMatch = RegExp(r'"(?:expiry|expiryDate|exp)"\s*:\s*"([^"]+)"', caseSensitive: false).firstMatch(jsonStr);
    final nameMatch = RegExp(r'"(?:name|medicineName|brand)"\s*:\s*"([^"]+)"', caseSensitive: false).firstMatch(jsonStr);

    final barcode = barcodeMatch?.group(1);
    if (barcode != null) {
      return ScanResult(
        rawCode: jsonStr,
        barcode: barcode,
        batchNumber: batchMatch?.group(1),
        expiryDate: expiryMatch?.group(1),
        medicineName: nameMatch?.group(1),
        format: 'JSON_QR',
      );
    }
    return null;
  }

  static ScanResult _parseParenthesizedGs1(String raw, String format) {
    String? gtin;
    String? expiry;
    String? batch;
    String? serial;

    // Match (01)14digits
    final gtinMatch = RegExp(r'\(01\)(\d{14})').firstMatch(raw);
    if (gtinMatch != null) {
      gtin = gtinMatch.group(1)!;
    }

    // Match (17)6digits (YYMMDD)
    final expMatch = RegExp(r'\(17\)(\d{6})').firstMatch(raw);
    if (expMatch != null) {
      expiry = _formatGs1Date(expMatch.group(1)!);
    }

    // Match (10)batch up to next ( or end of string
    final batchMatch = RegExp(r'\(10\)([^()]+)').firstMatch(raw);
    if (batchMatch != null) {
      batch = batchMatch.group(1)!.trim();
    }

    // Match (21)serial
    final serialMatch = RegExp(r'\(21\)([^()]+)').firstMatch(raw);
    if (serialMatch != null) {
      serial = serialMatch.group(1)!.trim();
    }

    return ScanResult(
      rawCode: raw,
      barcode: gtin ?? raw,
      batchNumber: batch,
      expiryDate: expiry,
      serialNumber: serial,
      format: format,
    );
  }

  static ScanResult? _parseRawGs1(String raw, String format) {
    try {
      String clean = raw.replaceAll(String.fromCharCode(29), '|'); // GS separator
      if (!clean.startsWith('01') || clean.length < 16) return null;

      var gtinStr = clean.substring(2, 16);
      if (gtinStr.startsWith('0')) {
        gtinStr = gtinStr.substring(1);
      }

      String? expiry;
      String? batch;

      var remainder = clean.substring(16);
      if (remainder.startsWith('17') && remainder.length >= 8) {
        final expCode = remainder.substring(2, 8);
        expiry = _formatGs1Date(expCode);
        remainder = remainder.substring(8);
      }

      if (remainder.startsWith('10')) {
        final batchPart = remainder.substring(2);
        final sepIdx = batchPart.indexOf('|');
        batch = sepIdx != -1 ? batchPart.substring(0, sepIdx) : batchPart;
      }

      return ScanResult(
        rawCode: raw,
        barcode: gtinStr,
        batchNumber: batch,
        expiryDate: expiry,
        format: format,
      );
    } catch (_) {
      return null;
    }
  }

  /// Converts YYMMDD to YYYY-MM-DD
  static String? _formatGs1Date(String yymmdd) {
    if (yymmdd.length != 6) return null;
    final yy = int.tryParse(yymmdd.substring(0, 2));
    final mm = yymmdd.substring(2, 4);
    var dd = yymmdd.substring(4, 6);

    if (yy == null) return null;
    // Standard GS1 rule: '00' day means last day of month. For simplicity, use 28 or given day
    if (dd == '00') dd = '28';

    final year = (yy < 70) ? 2000 + yy : 1900 + yy;
    return '$year-$mm-$dd';
  }
}

