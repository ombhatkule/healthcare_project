import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'config/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/constants.dart';

import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/services/auth_service.dart';
import 'features/splash/presentation/splash_screen.dart';

import 'features/profile/presentation/providers/profile_provider.dart';
import 'features/profile/services/profile_service.dart';

import 'features/disease_prediction/presentation/providers/disease_prediction_controller.dart';
import 'features/disease_prediction/services/disease_prediction_service.dart';
import 'features/disease_prediction/services/flask_disease_prediction_service.dart';

import 'features/doctor_recommendation/services/services.dart';
import 'features/doctor_recommendation/presentation/providers/doctor_recommendation_controller.dart';
import 'features/doctor_search/presentation/providers/doctor_search_controller.dart';

import 'features/appointment_booking/services/services.dart';
import 'features/appointment_booking/presentation/providers/appointment_controller.dart';

import 'features/medical_records/services/services.dart';
import 'features/medical_records/presentation/providers/medical_records_controller.dart';

import 'features/prescriptions/services/services.dart';
import 'features/prescriptions/presentation/providers/prescriptions_controller.dart';

import 'features/ai_assistant/services/services.dart';
import 'features/ai_assistant/presentation/providers/ai_assistant_controller.dart';

import 'features/diet_exercise/services/services.dart';
import 'features/diet_exercise/presentation/providers/diet_exercise_controller.dart';

import 'features/healthcare_locator/services/services.dart';

import 'firebase_options.dart';

Future<void> main() async {
  // Initialize Flutter before using Firebase or other async services.
  WidgetsFlutterBinding.ensureInitialized();

  await _startApp();
}

/// Boots the application.
///
/// Firebase initialization is allowed to fail without crashing the app: the
/// result is passed to [HealthcareApp], which forwards it to the splash
/// screen so a failed initialization shows a safe retry state instead of
/// being mistaken for a signed-out user.
///
/// The same function is reused by that retry action, so a failed startup can
/// be retried without restarting the process.
Future<void> _startApp() async {
  var firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (error) {
    // Raw Firebase errors stay in the console only; the UI shows a safe
    // generic message.
    debugPrint('Firebase initialization failed (${error.runtimeType}).');
  }

  // Load environment configuration.
  // It is optional, so the app can continue if the file is absent.
  await dotenv.load(
    fileName: 'assets/env/.env',
    isOptional: true,
  );

  runApp(HealthcareApp(
    firebaseReady: firebaseReady,
    onRetryStartup: _startApp,
  ));
}

class HealthcareApp extends StatelessWidget {
  /// Optional auth service for dependency injection in tests.
  final AuthService? authService;

  /// Optional profile service for dependency injection in tests.
  final ProfileService? profileService;

  /// Optional disease prediction service for dependency injection in tests.
  final DiseasePredictionService? predictionService;

  /// Optional doctor recommendation service for dependency injection in tests.
  final DoctorRecommendationService? recommendationService;

  /// Whether Firebase initialized successfully during startup.
  final bool firebaseReady;

  /// Retries a failed Firebase initialization.
  final Future<void> Function()? onRetryStartup;

  const HealthcareApp({
    super.key,
    this.authService,
    this.profileService,
    this.predictionService,
    this.recommendationService,
    this.firebaseReady = true,
    this.onRetryStartup,
  });

  @override
  Widget build(BuildContext context) {
    final service = authService ?? AuthService();
    final profileService = this.profileService ?? ProfileService();

    // Production uses the real Flask-backed prediction service.
    // Tests can override it with MockPredictionService via [predictionService].
    final predictionService =
        this.predictionService ?? FlaskDiseasePredictionService();

    // Production uses the in-memory mock doctor catalog for now; a real
    // backend can be injected here later.
    final recommendationService =
        this.recommendationService ?? MockDoctorRepository();

    // Appointment storage uses Firestore, scoped to each authenticated user.
    final appointmentService = AppointmentService();

    // Local/mock doctor availability; replace with a real backend later.
    final availabilityService = MockAppointmentAvailabilityService();

    return MultiProvider(
      providers: [
        Provider<AuthService>.value(
          value: service,
        ),

        // AuthProvider subscribes to FirebaseAuth as soon as it is created,
        // so it only exists when Firebase itself started successfully. The
        // splash screen handles that failure with a retry state instead.
        if (firebaseReady)
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(service),
          ),

        Provider<ProfileService>.value(
          value: profileService,
        ),

        ChangeNotifierProvider<ProfileProvider>(
          create: (_) => ProfileProvider(profileService),
        ),

        ChangeNotifierProvider<DiseasePredictionController>(
          create: (_) => DiseasePredictionController(
            predictionService,
          ),
        ),

        Provider<DoctorRecommendationService>.value(
          value: recommendationService,
        ),

        ChangeNotifierProvider<DoctorRecommendationController>(
          create: (_) => DoctorRecommendationController(
            recommendationService,
          ),
        ),

        ChangeNotifierProvider<DoctorSearchController>(
          create: (_) => DoctorSearchController(recommendationService),
        ),

        Provider<AppointmentService>.value(
          value: appointmentService,
        ),

        Provider<AppointmentAvailabilityService>.value(
          value: availabilityService,
        ),

        ChangeNotifierProvider<AppointmentController>(
          create: (_) => AppointmentController(appointmentService),
        ),

        Provider<MedicalRecordService>.value(
          value: MedicalRecordService(),
        ),

        ChangeNotifierProvider<MedicalRecordsController>(
          create: (_) => MedicalRecordsController(MedicalRecordService()),
        ),

        Provider<PrescriptionService>.value(
          value: PrescriptionService(),
        ),

        ChangeNotifierProvider<PrescriptionsController>(
          create: (_) => PrescriptionsController(PrescriptionService()),
        ),

        // AI Healthcare Assistant (Phase 14).
        // The Flask backend owns the Gemini key, so the app never holds it.
        Provider<AiAssistantService>.value(
          value: FlaskAiAssistantService(),
        ),

        ChangeNotifierProvider<AiAssistantController>(
          create: (ctx) => AiAssistantController(
            ctx.read<AiAssistantService>(),
            appointmentService: ctx.read<AppointmentService>(),
            medicalRecordService: ctx.read<MedicalRecordService>(),
            prescriptionService: ctx.read<PrescriptionService>(),
          ),
        ),

        // Diet & Exercise (Phase 15).
        Provider<DietService>.value(
          value: DietService(),
        ),

        Provider<ExerciseService>.value(
          value: ExerciseService(),
        ),

        Provider<ActivityTrackingService>.value(
          value: ActivityTrackingService(),
        ),

        ChangeNotifierProvider<DietExerciseController>(
          create: (ctx) => DietExerciseController(
            dietService: ctx.read<DietService>(),
            exerciseService: ctx.read<ExerciseService>(),
            activityService: ctx.read<ActivityTrackingService>(),
          ),
        ),

        // Hospital / Pharmacy Locator (Phase 16).
        // Only the services are app-wide; the controller is created per
        // screen so each visit starts with a fresh, correctly scoped state.
        Provider<LocationService>.value(
          value: const GeolocatorLocationService(),
        ),
        Provider<HealthcarePlacesService>.value(
          value: OverpassHealthcarePlacesService(),
        ),
        Provider<DirectionsService>.value(
          value: OsrmDirectionsService(),
        ),
        Provider<LinkLauncher>.value(
          value: const UrlLinkLauncher(),
        ),
      ],

      child: MaterialApp(
        title: AppStrings.appName,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: _generateRoute,
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  /// Startup is the only route that needs the bootstrap flags, so the splash
  /// route is built here; every other route delegates to [AppRouter].
  Route<dynamic> _generateRoute(RouteSettings settings) {
    if (settings.name == AppRoutes.splash) {
      return MaterialPageRoute(
        builder: (_) => SplashScreen(
          firebaseReady: firebaseReady,
          onRetryStartup: onRetryStartup,
        ),
      );
    }
    return AppRouter.generateRoute(settings);
  }
}

