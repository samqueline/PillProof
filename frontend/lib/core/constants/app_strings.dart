class AppStrings {
  AppStrings._();

  static const String appName = 'Pill Proof';
  static const String appTagline = 'Medicine Verification & Medication Tracking';

  // Safety Disclaimer (Section 3 of Specification)
  static const String safetyNotice =
      'Pill Proof is an awareness and medication tracking tool. It does not provide medical diagnosis, clinical advice, or prescribe treatments. Always consult licensed healthcare professionals for medical guidance.';

  // Verification Results
  static const String verifiedTitle = 'Verified Medicine';
  static const String reviewTitle = 'Review Recommended';
  static const String unverifiedTitle = 'Unverified Record';
  static const String expiredTitle = 'Expired Medicine';

  // Intake Awareness
  static const String limitReachedWarning =
      'Awareness Alert: Recorded intake has reached or exceeded your configured prescribed limit.';
}
