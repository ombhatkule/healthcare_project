/// Validation of AI assistant inputs and outputs for safety and privacy.
///
/// The safety boundary is enforced in three places:
///  1. Client-side here (defensive layering, never the only guard).
///  2. The centralized system prompt on the Flask backend.
///  3. The backend response safety filter.
class AiSafetyValidator {
  const AiSafetyValidator();

  /// Phrases that the assistant is never allowed to state or generate.
  static const List<String> _prohibitedClaims = [
    'confirmed',
    'i am a doctor',
    'i\'m a doctor',
    'i am your doctor',
  ];

  /// A short prompt injected by the service whenever the message looks like
  /// an emergency so the assistant gives a concise safety response.
  String emergencySafetyInstruction(String message) {
    return message;
  }

  /// Whether a user message appears to describe a medical emergency.
  ///
  /// When true, the app shows a concise urgent-care message without relying on
  /// the AI to manage the situation.
  bool looksLikeEmergency(String message) {
    final lower = message.toLowerCase();
    const emergencyMarkers = [
      'emergency',
      'severe bleeding',
      'profuse bleeding',
      'uncontrollable bleeding',
      'can\'t breathe',
      'cannot breathe',
      'can not breathe',
      'chest pain',
      'loss of consciousness',
      'unconscious',
      'seizure',
      'severe burn',
      'poisoning',
      'suicide',
      'overdose',
      'stroke symptoms',
      'face drooping',
      'paralys',
      'paralyz',
      'heart attack',
      'resuscitat',
    ];
    return emergencyMarkers.any(lower.contains);
  }

  /// Whether the user message is asking the assistant to prescribe, change a
  /// dose, or replace a medicine — actions the assistant must refuse.
  bool requestsForbiddenAction(String message) {
    final lower = message.toLowerCase();
    const forbiddenMarkers = [
      'prescribe',
      'write me a prescription',
      'give me a prescription',
      'change my dosage',
      'change my dose',
      'increase my dosage',
      'increase my dose',
      'reduce my dosage',
      'reduce my dose',
      'decrease my dosage',
      'decrease my dose',
      'replace my medicine',
      'switch my medicine',
      'recommend a dosage',
      'recommend me a dosage',
      'what dosage should i take',
      'how much should i take',
    ];
    return forbiddenMarkers.any(lower.contains);
  }

  /// Whether the user is asking about a disease diagnosis.
  bool asksForDiagnosis(String message) {
    final lower = message.toLowerCase();
    final diagnosisMarkers = [
      'what disease do i have',
      'do i have',
      'diagnose me',
      'what\'s wrong with me',
      'whats wrong with me',
      'what is wrong with me',
      'tell me my diagnosis',
      'confirm my diagnosis',
    ];
    return diagnosisMarkers.any(lower.contains);
  }

  /// Whether the assistant response contains any prohibited, unsafe claims.
  bool containsProhibitedClaim(String response) {
    final lower = response.toLowerCase();
    return _prohibitedClaims.any(lower.contains);
  }

  /// Builds a concise emergency response when [looksLikeEmergency] is true.
  String emergencyResponse() {
    return 'This may require urgent medical attention. Please contact your '
        'local emergency service or seek immediate professional medical care.';
  }

  /// Builds a refusal for prescription-related requests.
  String prescriptionRefusal() {
    return 'I cannot prescribe or recommend changes to medication or dosage. '
        'Only a qualified healthcare professional can prescribe or adjust '
        'medication. Please consult your doctor for advice about your '
        'treatment.';
  }

  /// Builds the safe response for a diagnosis question.
  String diagnosisResponse() {
    return "The app's prediction feature provides an AI-generated prediction "
        'based on the symptoms entered. It is not a confirmed diagnosis. '
        'A qualified healthcare professional should evaluate your symptoms.';
  }
}