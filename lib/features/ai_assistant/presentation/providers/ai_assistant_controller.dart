import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../appointment_booking/models/appointment_model.dart';
import '../../../appointment_booking/services/appointment_service.dart';
import '../../../medical_records/models/medical_profile.dart';
import '../../../medical_records/models/medical_record.dart';
import '../../../medical_records/services/medical_record_service.dart';
import '../../../prescriptions/models/prescription.dart';
import '../../../prescriptions/services/prescription_service.dart';
import '../../models/chat_message.dart';
import '../../services/ai_assistant_service.dart';
import '../../services/ai_context_builder.dart';
import '../../services/ai_safety_validator.dart';
import '../../services/assistant_request.dart';

/// State management for the AI Healthcare Assistant conversation.
///
/// Owns the session conversation history, the loading/error state, and all
/// data retrieval for the context sent to the assistant. No Firebase or
/// API calls are made from the chat UI — everything goes through this
/// controller and its injected services.
class AiAssistantController extends ChangeNotifier {
  final AiAssistantService _assistantService;
  final AppointmentService? _appointmentService;
  final MedicalRecordService? _medicalRecordService;
  final PrescriptionService? _prescriptionService;
  final AiContextBuilder _contextBuilder;
  final AiSafetyValidator _safetyValidator;

  AiAssistantController(
    this._assistantService, {
    AppointmentService? appointmentService,
    MedicalRecordService? medicalRecordService,
    PrescriptionService? prescriptionService,
    AiContextBuilder? contextBuilder,
    AiSafetyValidator? safetyValidator,
  })  : _appointmentService = appointmentService,
        _medicalRecordService = medicalRecordService,
        _prescriptionService = prescriptionService,
        _contextBuilder = contextBuilder ?? const AiContextBuilder(),
        _safetyValidator = safetyValidator ?? const AiSafetyValidator();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;
  bool _showNetworkError = false;
  String? _retryMessage;
  String? _retryMessageId;
  bool _isSessionStarted = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  bool get showNetworkError => _showNetworkError;
  bool get isSessionStarted => _isSessionStarted;
  int get messageCount => _messages.length;

  /// Whether to emit the temporary stage-by-stage trace of the send flow.
  ///
  /// Enabled with `--dart-define=AI_DEBUG=true`. Only the message length, stage
  /// names and error types are logged — never the message content or any
  /// medical context.
  static const bool _debug = bool.fromEnvironment('AI_DEBUG');

  void _log(String stage, [String? detail]) {
    if (!_debug) return;
    debugPrint('DEBUG AI: $stage${detail == null ? '' : ' | $detail'}');
  }

  /// Greeting shown when the conversation is empty.
  String get welcomeMessage =>
      'Hello! I am your AI healthcare assistant. Ask me about your health '
      'records, prescriptions, appointments, or any general health question. '
      'Please remember I am for informational purposes only and do not '
      'replace a qualified healthcare professional.';

  /// Starts the session, adding the assistant greeting once.
  void startSession() {
    if (_isSessionStarted) return;
    _isSessionStarted = true;
    _messages.add(
      ChatMessage(
        id: 'welcome-${DateTime.now().microsecondsSinceEpoch}',
        role: ChatMessageRole.assistant,
        content: welcomeMessage,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  /// Sends a message in the current chat session.
  Future<void> sendMessage(
    String text, {
    String? userId,
  }) async {
    final trimmed = text.trim();
    _log('AI CONTROLLER REACHED: YES (sendMessage, '
        'length=${trimmed.length})');
    if (trimmed.isEmpty) return;
    if (_isSending) return; // Prevent duplicate submissions.

    clearError();

    final userMessage = ChatMessage(
      id: 'u${DateTime.now().microsecondsSinceEpoch}',
      role: ChatMessageRole.user,
      content: trimmed,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    _isSending = true;
    _isLoading = true;
    notifyListeners();
    _log('AI USER MESSAGE ADDED: YES | isLoading=true');

    try {
      final response = await _buildResponse(trimmed, userId: userId);
      _log('AI ASSISTANT MESSAGE ADDED: YES (length=${response.length})');
      _addAssistantMessage(response);
    } on AppException catch (e) {
      _log('AI SEND FAILED: AppException');
      _handleSendError(userMessage, e.message);
    } on AssistantRequestException catch (e) {
      _log('AI SEND FAILED: AssistantRequestException '
          'isNetwork=${e.isNetwork}');
      _handleSendError(userMessage, e.message, isNetwork: e.isNetwork);
    } catch (e) {
      _log('AI SEND FAILED: ${e.runtimeType}');
      _handleSendError(
        userMessage,
        'Unable to connect to the assistant. Please check your internet '
        'connection and try again.',
        isNetwork: true,
      );
    } finally {
      _isSending = false;
      _isLoading = false;
      notifyListeners();
      _log('AI LOADING RESET: isLoading=false isSending=false');
    }
  }

  /// Determines the reply for a message (with local safety fallbacks).
  Future<String> _buildResponse(String message, {String? userId}) async {
    // 1. Emergency handling. Do not delay urgent care with a long AI answer.
    if (_safetyValidator.looksLikeEmergency(message)) {
      return _safetyValidator.emergencyResponse();
    }

    // 2. Deterministic safety refusals (the backend system prompt also
    //    enforces these; this is a defensive local layer).
    if (_safetyValidator.requestsForbiddenAction(message)) {
      return _safetyValidator.prescriptionRefusal();
    }
    if (_safetyValidator.asksForDiagnosis(message)) {
      return _safetyValidator.diagnosisResponse();
    }

    // 3. Real AI request with the authenticated user's context.
    final context = await _loadContext(userId);
    final result = await _assistantService.sendMessage(
      message: message,
      context: context,
    );

    if (result.response.trim().isEmpty) {
      return "Sorry, I couldn't generate a response right now. "
          'Please try again.';
    }

    // 4. Post-hoc safety filter on the generated response.
    if (_safetyValidator.containsProhibitedClaim(result.response)) {
      return "I can only provide general, informational guidance and explain "
          'the information you have stored in this app. For a diagnosis or '
          'specific medical advice, please consult a qualified healthcare '
          'professional.';
    }

    return result.response;
  }

  /// Loads the minimum user context (EHR, prescriptions, appointments) and
  /// builds the structured context JSON sent to the assistant.
  Future<Map<String, dynamic>> _loadContext(String? userId) async {
    final uid = userId ?? '';
    if (uid.isEmpty) {
      return _contextBuilder.buildContext(userId: '');
    }

    List<MedicalRecord>? records;
    MedicalProfile? profile;
    List<Prescription>? prescriptions;
    List<AppointmentModel>? appointments;

    try {
      if (_medicalRecordService != null) {
        records = await _medicalRecordService.getRecords(uid);
        profile = await _medicalRecordService.getMedicalProfile(uid);
      }
      if (_prescriptionService != null) {
        prescriptions = await _prescriptionService.getPrescriptions(uid);
      }
      if (_appointmentService != null) {
        appointments = await _appointmentService.getAppointments(uid);
      }
    } catch (_) {
      // Context is best-effort: if a sub-collection fails to load, the
      // assistant still answers the general question only.
      records = null;
      profile = null;
      prescriptions = null;
      appointments = null;
    }

    return _contextBuilder.buildContext(
      userId: uid,
      records: records,
      medicalProfile: profile,
      prescriptions: prescriptions,
      appointments: appointments,
    );
  }

  void _addAssistantMessage(String content) {
    _messages.add(
      ChatMessage(
        id: 'a${DateTime.now().microsecondsSinceEpoch}',
        role: ChatMessageRole.assistant,
        content: content,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _handleSendError(ChatMessage userMessage, String message,
      {bool isNetwork = false}) {
    _errorMessage = message;
    _showNetworkError = isNetwork;
    // Every failure is retryable, not just network failures: the backend can
    // reject a request for configuration, rate-limit or provider reasons.
    _retryMessage = userMessage.content;
    _retryMessageId = userMessage.id;
    // Keep the user message visible in the conversation so they know it was
    // sent.
    notifyListeners();
  }

  /// Clears the current error state.
  void clearError() {
    _errorMessage = null;
    _showNetworkError = false;
  }

  /// Starts a brand-new conversation (session-only history).
  void clearConversation() {
    _messages.clear();
    _isSessionStarted = false;
    _retryMessage = null;
    _retryMessageId = null;
    clearError();
    notifyListeners();
  }

  /// Retries the last message that failed to reach the assistant.
  ///
  /// The failed user message is removed first so a retry replaces it instead of
  /// duplicating it in the conversation.
  Future<void> retry(String? userId) async {
    final message = _retryMessage;
    if (message == null || _isSending) return;
    _retryMessage = null;
    final failedId = _retryMessageId;
    _retryMessageId = null;
    if (failedId != null) {
      _messages.removeWhere((m) => m.id == failedId);
    }
    await sendMessage(message, userId: userId);
  }

  @override
  void dispose() {
    _messages.clear();
    super.dispose();
  }
}