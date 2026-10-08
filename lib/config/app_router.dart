import 'package:flutter/material.dart';
import '../shared/widgets/widgets.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/home/presentation/dashboard_shell.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/auth_guard.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/disease_prediction/presentation/disease_prediction_screen.dart';
import '../features/disease_prediction/presentation/prediction_result_screen.dart';
import '../features/disease_prediction/presentation/prediction_history_screen.dart';
import '../features/doctor_search/presentation/doctor_search_screen.dart';
import '../features/doctor_recommendation/models/models.dart';
import '../features/doctor_recommendation/presentation/doctor_recommendation_screen.dart';
import '../features/doctor_recommendation/presentation/doctor_details_screen.dart';
import '../features/appointment_booking/presentation/appointment_booking_screen.dart';
import '../features/appointment_booking/models/models.dart';
import '../features/appointment_booking/presentation/appointment_confirmation_screen.dart';
import '../features/appointment_history/presentation/appointment_history_screen.dart';
import '../features/appointment_history/presentation/appointment_details_screen.dart';
import '../features/ai_assistant/presentation/ai_assistant_screen.dart';
import '../features/medical_records/presentation/medical_records_screen.dart';
import '../features/medical_records/models/models.dart';
import '../features/medical_records/presentation/medical_information_screen.dart';
import '../features/medical_records/presentation/medical_record_form_screen.dart';
import '../features/medical_records/presentation/medical_record_details_screen.dart';
import '../features/medical_records/presentation/medical_records_list_screen.dart';
import '../features/medical_records/presentation/surgery_form_screen.dart';
import '../features/prescriptions/presentation/prescriptions_screen.dart';
import '../features/prescriptions/models/models.dart';
import '../features/prescriptions/presentation/prescription_details_screen.dart';
import '../features/prescriptions/presentation/prescription_form_screen.dart';
import '../features/prescriptions/presentation/medicine_form_screen.dart';
import '../features/diet_exercise/presentation/screens/diet_exercise_preferences_screen.dart';
import '../features/diet/presentation/screens/diet_screen.dart';
import '../features/diet/presentation/screens/diet_plan_screen.dart';
import '../features/exercise/presentation/screens/exercise_screen.dart';
import '../features/exercise/presentation/screens/exercise_detail_screen.dart';
import '../features/exercise/presentation/screens/daily_activity_screen.dart';
import '../features/exercise/presentation/screens/progress_screen.dart';
import '../features/diet_exercise/models/nav_args.dart';
import '../features/healthcare_locator/models/healthcare_place_type.dart';
import '../features/healthcare_locator/presentation/screens/healthcare_locator_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

/// Centralized route definitions for the application.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String diseasePrediction = '/disease-prediction';
  static const String predictionResult = '/disease-prediction-result';
  static const String predictionHistory = '/disease-prediction-history';
  static const String doctorRecommendation = '/doctor-recommendation';
  static const String doctorSearch = '/doctor-search';
  static const String doctorDetails = '/doctor-details';
  static const String appointmentBooking = '/appointment-booking';
  static const String appointmentConfirmation = '/appointment-confirmation';
  static const String appointmentDetails = '/appointment-details';
  static const String appointmentHistory = '/appointment-history';
  static const String medicalRecords = '/medical-records';
  static const String medicalInformation = '/medical-information';
  static const String medicalRecordForm = '/medical-record-form';
  static const String medicalRecordDetails = '/medical-record-details';
  static const String medicalRecordsList = '/medical-records-list';
  static const String surgeryForm = '/surgery-form';
  static const String prescriptions = '/prescriptions';
  static const String prescriptionDetails = '/prescription-details';
  static const String prescriptionForm = '/prescription-form';
  static const String medicineForm = '/medicine-form';
  static const String aiAssistant = '/ai-assistant';

  // Diet & Exercise (Phase 15). The module is split into two dedicated
  // screens: /diet and /exercise. The legacy /diet-exercise route is kept and
  // now opens the Diet screen so old links keep working.
  static const String diet = '/diet';
  static const String exercise = '/exercise';
  static const String dietExercise = '/diet-exercise';
  static const String dietExerciseDiet = '/diet-exercise/diet';
  static const String dietExerciseExercise = '/diet-exercise/exercise';
  static const String dietExerciseActivity = '/diet-exercise/activity';
  static const String dietExerciseProgress = '/diet-exercise/progress';
  static const String dietExercisePreferences = '/diet-exercise/preferences';
  static const String dietExerciseDetail = '/diet-exercise/exercise-detail';
  static const String dietRecommendation = '/diet-recommendation';
  static const String exerciseRecommendation = '/exercise-recommendation';
  static const String hospitalLocator = '/hospital-locator';
  static const String pharmacyLocator = '/pharmacy-locator';
  static const String qrSharing = '/qr-sharing';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
}

/// Application router using generateRoute for named route navigation.
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth flows
      case AppRoutes.splash:
        return _route(const SplashScreen());
      case AppRoutes.login:
        return _route(const LoginScreen());
      case AppRoutes.register:
        return _route(const RegisterScreen());
      case AppRoutes.forgotPassword:
        return _route(const ForgotPasswordScreen());

      // Dashboard shell + home (protected by auth guard)
      case AppRoutes.home:
        return _route(const AuthGuard(child: DashboardShell()));

      // Profile & settings
      case AppRoutes.profile:
        return _route(const ProfileScreen());
      case AppRoutes.editProfile:
        return _route(const AuthGuard(child: EditProfileScreen()));
      case AppRoutes.notifications:
        return _route(const NotificationsScreen());
      case AppRoutes.settings:
        return _route(const SettingsScreen());

      // Quick action placeholders
      case AppRoutes.diseasePrediction:
        return _route(const DiseasePredictionScreen());
      case AppRoutes.predictionResult:
        return _route(const PredictionResultScreen());
      case AppRoutes.predictionHistory:
        return _route(const PredictionHistoryScreen());
      case AppRoutes.doctorSearch:
        return _route(const DoctorSearchScreen());
      case AppRoutes.doctorRecommendation:
        return _route(
          DoctorRecommendationScreen(
            args: settings.arguments as DoctorRecommendationArgs?,
          ),
        );
      case AppRoutes.doctorDetails:
        return _route(
          DoctorDetailsScreen(
            args: settings.arguments as DoctorDetailsArgs?,
          ),
        );
      case AppRoutes.appointmentBooking:
        return _route(
          AppointmentBookingScreen(
            args: settings.arguments as BookingArguments?,
          ),
        );
      case AppRoutes.appointmentConfirmation:
        return _route(
          AppointmentConfirmationScreen(
            args: settings.arguments as AppointmentConfirmationArguments?,
          ),
        );
      case AppRoutes.appointmentDetails:
        return _route(
          AppointmentDetailsScreen(
            args: settings.arguments as AppointmentDetailsArguments?,
          ),
        );
      case AppRoutes.aiAssistant:
        return _route(const AiAssistantScreen());
      case AppRoutes.appointmentHistory:
        return _route(const AppointmentHistoryScreen());

      // Healthcare service placeholders
      case AppRoutes.medicalRecords:
        return _route(const MedicalRecordsScreen());
      case AppRoutes.medicalInformation:
        return _route(const MedicalInformationScreen());
      case AppRoutes.medicalRecordForm:
        return _route(
          MedicalRecordFormScreen(
            args: settings.arguments as MedicalRecordFormArguments?,
          ),
        );
      case AppRoutes.medicalRecordDetails:
        return _route(
          MedicalRecordDetailsScreen(
            args: settings.arguments as MedicalRecordDetailsArguments?,
          ),
        );
      case AppRoutes.medicalRecordsList:
        return _route(
          MedicalRecordsListScreen(
            args: settings.arguments as MedicalRecordsListArguments?,
          ),
        );
      case AppRoutes.surgeryForm:
        return _route(
          SurgeryFormScreen(
            args: settings.arguments as SurgeryFormArguments?,
          ),
        );
      case AppRoutes.prescriptions:
        return _route(const PrescriptionsScreen());
      case AppRoutes.prescriptionDetails:
        return _route(
          PrescriptionDetailsScreen(
            args: settings.arguments as PrescriptionDetailsArguments?,
          ),
        );
      case AppRoutes.prescriptionForm:
        return _route(
          PrescriptionFormScreen(
            args: settings.arguments as PrescriptionFormArguments?,
          ),
        );
      case AppRoutes.medicineForm:
        return _route(
          MedicineFormScreen(
            args: settings.arguments as MedicineFormArguments?,
          ),
        );
      case AppRoutes.dietRecommendation:
        return _route(const DietPlanScreen());
      case AppRoutes.exerciseRecommendation:
        return _route(const ExerciseScreen());
      case AppRoutes.diet:
        return _route(const DietScreen());
      case AppRoutes.exercise:
        return _route(const ExerciseScreen());
      case AppRoutes.dietExercise:
        return _route(const DietScreen());
      case AppRoutes.dietExerciseDiet:
        return _route(const DietPlanScreen());
      case AppRoutes.dietExerciseExercise:
        return _route(const ExerciseScreen());
      case AppRoutes.dietExerciseActivity:
        return _route(const DailyActivityScreen());
      case AppRoutes.dietExerciseProgress:
        return _route(const ProgressScreen());
      case AppRoutes.dietExercisePreferences:
        return _route(const DietExercisePreferencesScreen());
      case AppRoutes.dietExerciseDetail:
        final args = settings.arguments;
        final exerciseId = args is ExerciseDetailArguments ? args.exerciseId : null;
        final screen = buildExerciseDetailScreen(exerciseId);
        if (screen == null) {
          // Unknown exercise id: show a friendly empty state instead of
          // crashing or showing a broken route.
          return _route(const _UnknownExerciseScreen());
        }
        return _route(screen);
      case AppRoutes.hospitalLocator:
        return _route(
          const HealthcareLocatorScreen(
            initialType: HealthcarePlaceType.hospital,
          ),
        );
      case AppRoutes.pharmacyLocator:
        return _route(
          const HealthcareLocatorScreen(
            initialType: HealthcarePlaceType.pharmacy,
          ),
        );

      // Future routes
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  static Route<dynamic> _route(Widget widget) {
    return MaterialPageRoute(builder: (_) => widget);
  }
}

/// Shown when a workout deep link references an exercise that no longer exists.
class _UnknownExerciseScreen extends StatelessWidget {
  const _UnknownExerciseScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercise')),
      body: const SafeArea(
        child: EmptyStateWidget(
          icon: Icons.search_off_outlined,
          title: 'Exercise not found',
          subtitle: 'This exercise is no longer available. Please choose '
              'another from the library.',
        ),
      ),
    );
  }
}
