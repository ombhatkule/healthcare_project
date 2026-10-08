import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/features/ai_assistant/models/chat_message.dart';
import 'package:healthcare_app/features/ai_assistant/presentation/providers/ai_assistant_controller.dart';
import 'package:healthcare_app/features/appointment_booking/models/appointment_model.dart';
import 'package:healthcare_app/features/medical_records/models/medical_record.dart';
import 'package:healthcare_app/features/prescriptions/models/medicine.dart';
import 'package:healthcare_app/features/prescriptions/models/prescription.dart';
import 'package:healthcare_app/shared/enums/appointment_status.dart';

import 'fake_ai_assistant_service.dart';
import 'fake_appointment_service.dart';
import 'fake_medical_record_service.dart';
import 'fake_prescription_service.dart';

void main() {
  AiAssistantController build({
    FakeAiAssistantService? fakeAssistant,
    FakeMedicalRecordService? fakeRecords,
    FakePrescriptionService? fakePrescriptions,
    FakeAppointmentService? fakeAppointments,
  }) {
    return AiAssistantController(
      fakeAssistant ?? FakeAiAssistantService(),
      medicalRecordService: fakeRecords ?? FakeMedicalRecordService(),
      prescriptionService:
          fakePrescriptions ?? FakePrescriptionService(),
      appointmentService: fakeAppointments ?? FakeAppointmentService(),
    );
  }

  group('AiAssistantController', () {
    test('startSession adds a single greeting message', () {
      final controller = build();
      controller.startSession();
      controller.startSession();
      expect(controller.messages, hasLength(1));
      expect(controller.messages.single.role, ChatMessageRole.assistant);
      expect(controller.isSessionStarted, isTrue);
    });

    test('sendMessage appends user and assistant messages', () async {
      final controller = build();
      controller.startSession();
      await controller.sendMessage('What is a headache?', userId: 'user-A');

      expect(controller.messages, hasLength(3));
      expect(controller.messages[1].role, ChatMessageRole.user);
      expect(controller.messages[1].content, 'What is a headache?');
      expect(controller.messages[2].role, ChatMessageRole.assistant);
      expect(controller.messages[2].content, 'This is a fake assistant response.');
      expect(controller.errorMessage, isNull);
    });

    test('empty message is not sent and not added to history', () async {
      final fake = FakeAiAssistantService();
      final controller = build(fakeAssistant: fake);
      await controller.sendMessage('   ', userId: 'user-A');
      expect(controller.messages, isEmpty);
      expect(fake.lastMessage, isNull);
    });

    test('sendMessage is ignored while a request is in flight', () async {
      final fake = FakeAiAssistantService();
      final controller = build(fakeAssistant: fake);

      final first = controller.sendMessage('first', userId: 'user-A');
      // Attempting a second send while the first is pending is a no-op; the
      // fake resolves immediately, so wrap both futures and await.
      final second = controller.sendMessage('second', userId: 'user-A');
      await Future.wait([first, second]);

      final userMessages =
          controller.messages.where((m) => m.isUser).toList();
      expect(userMessages, hasLength(1));
    });

    test('emergency keywords produce a concise safety response without the AI',
        () async {
      final fake = FakeAiAssistantService();
      final controller = build(fakeAssistant: fake);
      await controller.sendMessage(
          'I am having severe chest pain right now',
          userId: 'user-A');

      expect(
        controller.messages.last.content,
        contains('urgent medical attention'),
      );
      expect(fake.lastMessage, isNull, reason: 'AI must not be called');
    });

    test('prescription request is refused', () async {
      final fake = FakeAiAssistantService();
      final controller = build(fakeAssistant: fake);
      await controller.sendMessage(
          'Can you prescribe me something for pain?',
          userId: 'user-A');

      final reply = controller.messages.last.content;
      expect(reply.toLowerCase(), contains('cannot prescribe'));
      expect(fake.lastMessage, isNull);
    });

    test('dosage change request is refused', () async {
      final fake = FakeAiAssistantService();
      final controller = build(fakeAssistant: fake);
      await controller.sendMessage(
          'Please change my dosage of Paracetamol',
          userId: 'user-A');

      final reply = controller.messages.last.content;
      expect(reply.toLowerCase(), contains('cannot prescribe'));
      expect(fake.lastMessage, isNull);
    });

    test('diagnosis question never claims a confirmed diagnosis', () async {
      final fake = FakeAiAssistantService();
      final controller = build(fakeAssistant: fake);
      await controller.sendMessage('What disease do I have?', userId: 'user-A');

      final reply = controller.messages.last.content.toLowerCase();
      expect(reply, contains('not a confirmed diagnosis'));
      expect(reply, isNot(contains('you definitely have')));
      expect(fake.lastMessage, isNull);
    });

    test('context from the authenticated user is passed to the AI', () async {
      final fake = FakeAiAssistantService();
      final records = FakeMedicalRecordService(
        initialRecords: [
          MedicalRecord(
            id: 'r1',
            userId: 'user-A',
            title: 'Blood test',
            date: DateTime(2025, 5, 1),
          ),
        ],
      );
      final prescriptions = FakePrescriptionService(
        initial: [
          Prescription(
            id: 'p1',
            userId: 'user-A',
            doctorName: 'Dr. Rao',
            prescriptionDate: DateTime(2025, 6, 1),
            medicines: const [
              Medicine(medicineName: 'Paracetamol', dosage: '500 mg'),
            ],
          ),
        ],
      );
      final appointments = FakeAppointmentService(
        initial: [
          AppointmentModel(
            id: 'a1',
            userId: 'user-A',
            doctorId: 'd1',
            doctorName: 'Dr. Kapoor',
            specialty: 'Cardiology',
            hospital: 'Heart Institute',
            location: 'Mumbai',
            appointmentDate: DateTime(2025, 9, 20),
            appointmentTime: '10:30 AM',
            status: AppointmentStatus.confirmed,
            createdAt: DateTime(2025, 9, 1),
          ),
        ],
      );

      final controller = build(
        fakeAssistant: fake,
        fakeRecords: records,
        fakePrescriptions: prescriptions,
        fakeAppointments: appointments,
      );

      await controller.sendMessage(
          'What is in my latest prescription?',
          userId: 'user-A');

      final context = fake.lastContext!;
      final user = context['user'] as Map;
      expect(user['id'], 'user-A');

      final prescriptionsCtx = context['prescriptions'] as List;
      expect(prescriptionsCtx, hasLength(1));
      final first = prescriptionsCtx.first as Map;
      expect(first['doctor'], 'Dr. Rao');

      final recordsCtx = context['medicalRecords'] as List;
      expect(recordsCtx, hasLength(1));
      expect((recordsCtx.first as Map)['title'], 'Blood test');

      final appointmentsCtx = context['appointments'] as List;
      expect(appointmentsCtx, hasLength(1));
      expect((appointmentsCtx.first as Map)['doctor'], 'Dr. Kapoor');
    });

    test('another user\'s records are never included in context', () async {
      final fake = FakeAiAssistantService();
      final records = FakeMedicalRecordService(
        initialRecords: [
          MedicalRecord(
            id: 'r-other',
            userId: 'user-B',
            title: 'Secret record',
            date: DateTime(2025, 5, 1),
          ),
        ],
      );
      final prescriptions = FakePrescriptionService(
        initial: [
          Prescription(
            id: 'p-other',
            userId: 'user-B',
            prescriptionDate: DateTime(2025, 6, 1),
          ),
        ],
      );
      final appointments = FakeAppointmentService(
        initial: [
          AppointmentModel(
            id: 'a-other',
            userId: 'user-B',
            doctorId: 'd',
            doctorName: 'Dr. Other',
            specialty: 'X',
            hospital: 'H',
            location: 'L',
            appointmentDate: DateTime(2025, 9, 20),
            appointmentTime: '10:30 AM',
            status: AppointmentStatus.confirmed,
            createdAt: DateTime(2025, 9, 1),
          ),
        ],
      );

      final controller = build(
        fakeAssistant: fake,
        fakeRecords: records,
        fakePrescriptions: prescriptions,
        fakeAppointments: appointments,
      );
      await controller.sendMessage('Show my records', userId: 'user-A');

      final context = fake.lastContext!;
      expect(context['medicalRecords'], isNull);
      expect(context['prescriptions'], isNull);
      expect(context['appointments'], isNull);
    });

    test('network failure surfaces a retryable error', () async {
      final fake = FakeAiAssistantService(
        shouldThrow: true,
        shouldBeNetworkError: true,
        failureMessage: 'Unable to connect to the assistant.',
      );
      final controller = build(fakeAssistant: fake);
      await controller.sendMessage('hello', userId: 'user-A');

      expect(controller.showNetworkError, isTrue);
      expect(controller.errorMessage, contains('Unable to connect'));

      // The user message remains visible so the retry action makes sense.
      expect(controller.messages, hasLength(1));

      // Recover: switch the fake to success and retry.
      fake.shouldThrow = false;
      await controller.retry('user-A');
      expect(controller.showNetworkError, isFalse);
      expect(controller.messages.last.content, 'This is a fake assistant response.');
    });

    test('AI provider failure is surfaced as a friendly error', () async {
      final fake = FakeAiAssistantService(
        shouldThrow: true,
        failureMessage: "Sorry, I couldn't generate a response right now. "
            'Please try again.',
      );
      final controller = build(fakeAssistant: fake);
      await controller.sendMessage('hello', userId: 'user-A');

      expect(controller.showNetworkError, isFalse);
      expect(controller.errorMessage, contains("couldn't generate"));
    });

    // Regression: a non-network failure (e.g. HTTP 503 from an unconfigured
    // AI provider) used to be unreachable through retry(), which only stored a
    // retry payload for network errors.
    test('non-network failure is retryable and does not duplicate the message',
        () async {
      final fake = FakeAiAssistantService(
        shouldThrow: true,
        failureMessage: 'The AI Assistant is currently unavailable.',
      );
      final controller = build(fakeAssistant: fake);
      await controller.sendMessage('Make a diet plan for me', userId: 'user-A');

      expect(controller.errorMessage, contains('currently unavailable'));
      expect(controller.messages, hasLength(1));

      fake.shouldThrow = false;
      await controller.retry('user-A');

      expect(controller.errorMessage, isNull);
      expect(controller.messages, hasLength(2));
      expect(controller.messages.first.content, 'Make a diet plan for me');
      expect(controller.messages.last.content,
          'This is a fake assistant response.');
      expect(controller.isLoading, isFalse);
      expect(controller.isSending, isFalse);
    });

    test('loading state is always reset after a failure', () async {
      final fake = FakeAiAssistantService(shouldThrow: true);
      final controller = build(fakeAssistant: fake);
      await controller.sendMessage('hello', userId: 'user-A');

      expect(controller.isLoading, isFalse);
      expect(controller.isSending, isFalse);
    });

    test('clearConversation resets the session', () async {
      final controller = build();
      controller.startSession();
      await controller.sendMessage('hello', userId: 'user-A');
      expect(controller.messages, isNotEmpty);

      controller.clearConversation();
      expect(controller.messages, isEmpty);
      expect(controller.isSessionStarted, isFalse);
      expect(controller.isLoading, isFalse);
    });
  });
}