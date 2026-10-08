/// String constants used across the application.
abstract final class AppStrings {
  // App
  static const String appName = 'HealthCare AI';
  static const String appTagline = 'Your Personal Health Companion';

  // Onboarding
  static const String onboardingTitle1 = 'Smart Health Tracking';
  static const String onboardingDesc1 =
      'Track your health metrics and get personalized insights powered by AI.';
  static const String onboardingTitle2 = 'AI Disease Prediction';
  static const String onboardingDesc2 =
      'Get preliminary health assessments based on your symptoms. This is for informational purposes only.';
  static const String onboardingTitle3 = 'Connect with Doctors';
  static const String onboardingDesc3 =
      'Find and book appointments with qualified healthcare professionals near you.';

  // Auth
  static const String loginTitle = 'Welcome Back';
  static const String loginSubtitle = 'Sign in to your account';
  static const String registerTitle = 'Create Account';
  static const String registerSubtitle = 'Join us to manage your health';
  static const String forgotPasswordTitle = 'Reset Password';
  static const String forgotPasswordSubtitle =
      'Enter your email to receive a reset link';

  // Auth - fields and buttons
  static const String emailLabel = 'Email Address';
  static const String emailHint = 'you@example.com';
  static const String passwordLabel = 'Password';
  static const String passwordHint = 'Enter your password';
  static const String confirmPasswordLabel = 'Confirm Password';
  static const String fullNameLabel = 'Full Name';
  static const String fullNameHint = 'Enter your full name';
  static const String loginButton = 'Sign In';
  static const String registerButton = 'Create Account';
  static const String forgotPasswordButton = 'Send Reset Link';
  static const String backToLogin = 'Back to Login';
  static const String noAccount = 'Don\'t have an account?';
  static const String haveAccount = 'Already have an account?';
  static const String forgotPasswordLink = 'Forgot Password?';

  // Auth - validation messages
  static const String nameRequired = 'Please enter your full name';
  static const String emailRequired = 'Please enter your email';
  static const String emailInvalid = 'Please enter a valid email address';
  static const String passwordRequired = 'Please enter your password';
  static const String passwordTooShort =
      'Password must be at least 6 characters';
  static const String confirmPasswordRequired = 'Please confirm your password';
  static const String passwordMismatch = 'Passwords do not match';

  // Auth - success / status
  static const String loginSuccess = 'Signed in successfully';
  static const String registerSuccess = 'Account created successfully';
  static const String logoutSuccess = 'Signed out';
  static const String resetEmailSent =
      'Password reset email sent. Please check your inbox.';
  static const String logoutConfirmTitle = 'Sign Out';
  static const String logoutConfirmMessage = 'Are you sure you want to sign out?';
  static const String logoutMaybeLater = 'Maybe later';

  // App startup (splash)
  // Safe, exception-free messages: raw Firebase errors are never shown.
  static const String startupErrorTitle = 'Unable to start the app';
  static const String startupErrorMessage =
      'Something went wrong while starting up. Please try again.';
  static const String authStateTimeoutTitle = 'Still starting up';
  static const String authStateTimeoutMessage =
      'We could not confirm your sign-in status yet. Please try again.';

  // Home
  static const String homeTitle = 'Health Dashboard';
  static const String homeGreeting = 'Hello,';
  static const String homeWelcome = 'Welcome to HealthCare AI';

  // Common
  static const String loading = 'Loading...';
  static const String error = 'Something went wrong';
  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String ok = 'OK';
  static const String yes = 'Yes';
  static const String no = 'No';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String search = 'Search';
  static const String noData = 'No data available';
  static const String comingSoon = 'Coming Soon';
  static const String disclaimer =
      'This app is for informational purposes only and does not replace professional medical advice.';

  // Profile
  static const String profileTitle = 'Profile';
  static const String editProfile = 'Edit Profile';
  static const String personalInformation = 'Personal Information';
  static const String healthInformation = 'Health Information';
  static const String accountSettings = 'Account Settings';
  static const String logout = 'Sign Out';

  // Personal information labels
  static const String fullName = 'Full Name';
  static const String email = 'Email';
  static const String phoneNumber = 'Phone Number';
  static const String dateOfBirth = 'Date of Birth';
  static const String gender = 'Gender';
  static const String notSpecified = 'Not specified';

  // Health information labels
  static const String height = 'Height';
  static const String weight = 'Weight';
  static const String bloodGroup = 'Blood Group';
  static const String emergencyContact = 'Emergency Contact';
  static const String allergies = 'Allergies';
  static const String heightUnit = 'cm';
  static const String weightUnit = 'kg';
  static const String none = 'None';

  // Settings items
  static const String notificationSettings = 'Notification Settings';
  static const String notificationSettingsMessage =
      'Manage your notification preferences.';
  static const String privacy = 'Privacy';
  static const String privacyMessage =
      'Privacy settings will be available in a future update.';
  static const String aboutApplication = 'About';
  static const String aboutApplicationMessage =
      'HealthCare AI — Your Personal Health Companion.';

  // Profile validation
  static const String invalidPhone = 'Please enter a valid phone number';
  static const String invalidEmergencyPhone =
      'Please enter a valid emergency contact number';
  static const String invalidNumeric = 'Please enter a valid number';
  static const String invalidHeight = 'Please enter a valid height';
  static const String invalidWeight = 'Please enter a valid weight';
  static const String invalidDateOfBirth =
      'Date of birth cannot be in the future';

  // Profile status
  static const String profileUpdated = 'Profile updated successfully';
  static const String profileSaved = 'Profile saved successfully';
  static const String profileLoadFailed =
      'Could not load your profile. Please try again.';

  static const String selectBloodGroup = 'Select blood group';
  static const String selectGender = 'Select gender';

  // Disease Prediction
  static const String predictionTitle = 'Disease Prediction';
  static const String predictionIntro =
      'Select the symptoms you are experiencing to get an experimental '
      'research/educational prediction. For a more informative experimental '
      'result, select multiple relevant symptoms.';
  static const String predictionNotDiagnosis =
      'This is an experimental research/educational prediction, not a medical '
      'diagnosis. It has not been validated for clinical use. Please consult '
      'a qualified healthcare professional for diagnosis and treatment.';
  static const String experimentalModeLabel = 'Research / Educational';
  static const String symptomSearchLabel = 'Search symptoms';
  static const String symptomSearchHint = 'e.g. Headache';
  static const String searchSymptoms = 'Search Symptoms';
  static const String selectedSymptoms = 'Selected Symptoms';
  static const String availableSymptoms = 'Available Symptoms';
  static const String noSymptomsSelected = 'Please select at least one symptom.';
  static const String clear = 'Clear';
  static const String predict = 'Predict Disease';
  static const String analyzeSymptoms = 'Analyzing symptoms...';
  static const String tryAgain = 'Try Again';
  static const String newPrediction = 'New Prediction';
  static const String predictionResultTitle = 'Prediction Result';
  static const String demoLabel = 'Demo / Mock Prediction';
  static const String confidence = 'Confidence';
  static const String possibleConditions = 'Possible Conditions';
  static const String topPredictions = 'Top Predictions';
  static const String modelScore = 'Experimental model score';
  static const String predictionPossibleCondition = 'Experimental prediction';
  static const String decisionSupportDisclaimer =
      'This experimental prediction is for research/educational purposes only '
      'and is not a medical diagnosis.';
  static const String backendUnreachable =
      'Unable to connect to the healthcare server. Please make sure the '
      'backend is running and try again.';
  static const String predictionDisclaimer =
      'Research/Educational Use Only. This experimental prediction is generated '
      'by a machine-learning research model. It is not a medical diagnosis and '
      'has not been validated for clinical use or independent patient-level '
      'generalization. Do not use this result to make healthcare decisions. '
      'Please consult a qualified healthcare professional for medical concerns.';
  static const String symptomsFailedToLoad =
      'Could not load the symptom catalog from the server. Please make sure '
      'the backend is running and try again.';
  static const String predictionHistoryTitle = 'Prediction History';
  static const String emptyPredictionHistory =
      'No predictions yet. Try a prediction to see your history here.';
  static const String viewHistory = 'View History';
  static const String symptoms = 'Symptoms';
  static const String predictionDemo = 'Demo Prediction';
  static const String predictionFailure =
      'Prediction could not be completed. Please try again.';

  // Doctor Recommendation
  static const String doctorSearchTitle = 'Find a Doctor';
  static const String doctorSearchSubtitle =
      'Browse doctors by specialty, or get recommendations after a prediction.';
  static const String recommendedDoctors = 'Recommended Doctors';
  static const String doctorDetailsTitle = 'Doctor Details';
  static const String findRecommendedDoctors = 'Find Recommended Doctors';
  static const String basedOnPrediction = 'Based on your prediction, this specialty is recommended';
  static const String recommendedSpecialtyLabel = 'Recommended Specialty';
  static const String doctorsMatchingSpecialty = 'Doctors matching this specialty';
  static const String availableToday = 'Available Today';
  static const String notAvailableToday = 'Unavailable Today';
  static const String qualificationLabel = 'Qualification';
  static const String experienceLabel = 'Experience';
  static const String yearExperienceLabel = 'years of experience';
  static const String hospitalLabel = 'Hospital';
  static const String locationLabel = 'Location';
  static const String consultationFeeLabel = 'Consultation Fee';
  static const String ratingLabel = 'Rating';
  static const String languagesLabel = 'Languages';
  static const String availabilityLabel = 'Availability';
  static const String specialtyLabel = 'Specialty';
  static const String doctorsLabel = 'doctors';
  static const String doctorAvailable = 'Available';
  static const String doctorUnavailable = 'Unavailable';
  static const String noDoctorsFound = 'No doctors available';
  static const String noDoctorsFoundMessage =
      'We could not find any doctors for this specialty right now. '
      'Please try another specialty or check back later.';
  static const String doctorNotFound = 'Doctor not found';
  static const String doctorNotFoundMessage =
      'The requested doctor could not be loaded.';
  static const String doctorsLoadFailed =
      'Could not load doctors. Please check your connection and try again.';
  static const String specialtiesLoadFailed =
      'Could not load specialties. Please check your connection and try again.';
  static const String loadingDoctorsMsg = 'Loading recommended doctors...';
  static const String bookAppointment = 'Book Appointment';
  static const String bookingComingSoonNote =
      'Online appointment booking will be available in a future update.';
  static const String recommendationNotMedicalAdvice =
      'Doctor recommendations are based on the experimental disease '
      'prediction and are provided for informational purposes only. They are '
      'not a substitute for professional medical advice.';

  // Doctor Search
  static const String searchDoctorsHint = 'Search by doctor, specialty, hospital or location';
  static const String allSpecialties = 'All Specialties';
  static const String allLocations = 'All Locations';
  static const String anyRating = 'Any Rating';
  static const String doctorSearchEmpty =
      'No doctors found. Try adjusting your search or clearing the filters.';
  static const String clearFilters = 'Clear Filters';
  static const String sortBy = 'Sort By';
  static const String sortRecommended = 'Recommended';
  static const String sortHighestRated = 'Highest Rated';
  static const String sortMostExperienced = 'Most Experienced';
  static const String doctorsFound = 'doctors found';
  static const String searchLocationsFailed = 'Could not load search options.';

  // Appointment Booking
  static const String appointmentBookingTitle = 'Book Appointment';
  static const String appointmentSelectDate = 'Select Appointment Date';
  static const String appointmentDateLabel = 'Appointment Date';
  static const String noDateSelected = 'No date selected';
  static const String selectDateHint = 'Choose a date';
  static const String chooseDate = 'Choose Date';
  static const String availableTimeLabel = 'Available Time';
  static const String selectTimeHint = 'Select a time slot';
  static const String timeSlotUnavailable = 'This slot is unavailable';
  static const String appointmentInfoTitle = 'Appointment Information';
  static const String reasonForVisitLabel = 'Reason for Visit (optional)';
  static const String reasonForVisitHint = 'e.g. Routine consultation';
  static const String additionalNotesLabel = 'Additional Notes (optional)';
  static const String additionalNotesHint = 'Any additional information for the doctor';
  static const String reviewAppointmentTitle = 'Review Appointment';
  static const String confirmAppointment = 'Confirm Appointment';
  static const String continueButton = 'Continue';
  static const String backButton = 'Back';
  static const String stepLabel = 'Step';

  // Appointment validation
  static const String doctorRequired = 'Doctor not available. Please go back and try again.';
  static const String selectDateRequired = 'Please select an appointment date.';
  static const String selectTimeRequired = 'Please select an available time.';
  static const String signInRequired = 'Please sign in to book an appointment.';
  static const String appointmentSaved =
      'Your appointment has been booked successfully.';

  // Appointment confirmation
  static const String appointmentConfirmed = 'Appointment Confirmed';
  static const String appointmentConfirmedMessage =
      'Your appointment has been booked.';
  static const String viewAppointment = 'View Appointment';
  static const String backToHome = 'Back to Home';

  // Appointment history / details
  static const String appointmentsTitle = 'Appointments';
  static const String upcomingAppointments = 'Upcoming';
  static const String pastAppointments = 'Past';
  static const String cancelledAppointments = 'Cancelled';
  static const String noUpcomingAppointments = 'No upcoming appointments';
  static const String noUpcomingMessage =
      'Book an appointment with a doctor to see it here.';
  static const String noPastAppointments = 'No past appointments';
  static const String noCancelledAppointments = 'No cancelled appointments';
  static const String findADoctor = 'Find a Doctor';
  static const String viewDetails = 'View Details';
  static const String appointmentDetailsTitle = 'Appointment Details';
  static const String bookingIdLabel = 'Booking ID';
  static const String appointmentStatusLabel = 'Status';
  static const String reasonLabel = 'Reason';
  static const String notesLabel = 'Notes';
  static const String noReasonProvided = 'Not provided';
  static const String cancelAppointment = 'Cancel Appointment';
  static const String cancelConfirmTitle = 'Cancel this appointment?';
  static const String cancelConfirmMessage =
      'This appointment will be cancelled. You can book a new slot anytime.';
  static const String keepAppointment = 'Keep Appointment';
  static const String cancelAppointmentConfirm = 'Cancel Appointment';
  static const String appointmentCancelled = 'Appointment cancelled.';
  static const String loadingAppointmentDetails =
      'Loading appointment details...';

  // Appointment errors
  static const String appointmentsLoadFailed =
      'Unable to load your appointments. Please try again.';
  static const String appointmentLoadFailed =
      'Unable to load the appointment. Please try again.';
  static const String bookingFailed =
      'Unable to book the appointment. Please try again.';
  static const String bookingTimeoutMessage =
      'Booking is taking too long. Please check your connection and try again.';
  static const String slotUnavailableMessage =
      'This time slot is no longer available.';
  static const String cancellationFailed =
      'Unable to cancel the appointment. Please try again.';
  static const String appointmentNotFound = 'Appointment not found.';

  // EHR / Medical Records
  static const String medicalRecordsTitle = 'Medical Records';
  static const String medicalInformation = 'Medical Information';
  static const String bloodGroupLabel = 'Blood Group';
  static const String bloodGroupUnknown = 'Unknown';
  static const String allergiesLabel = 'Allergies';
  static const String medicalConditionsLabel = 'Medical Conditions';
  static const String familyHistoryLabel = 'Family Medical History';
  static const String familyHistoryHint = 'e.g. Heart disease on father\'s side';
  static const String pastSurgeriesLabel = 'Past Surgeries';
  static const String medicalHistoryLabel = 'Medical History';
  static const String doctorVisitsLabel = 'Doctor Visits';
  static const String medicalDocumentsLabel = 'Medical Documents';
  static const String recordsCountWord = 'records';
  static const String visitsCountWord = 'visits';
  static const String documentsCountWord = 'documents';
  static const String addMedicalRecord = 'Add Medical Record';
  static const String editRecord = 'Edit Record';
  static const String editMedicalInformation = 'Edit Medical Information';
  static const String addAllergy = 'Add Allergy';
  static const String addCondition = 'Add Condition';
  static const String addSurgery = 'Add Surgery';
  static const String addItemHint = 'Enter a value';
  static const String surgeryNameLabel = 'Surgery Name';
  static const String surgeryYearLabel = 'Year';
  static const String bloodGroupHint = 'Select blood group';
  static const String notSpecifiedLabel = 'Not specified';
  static const String noneLabel = 'None';
  static const String noMedicalRecords = 'No medical records yet.';
  static const String noMedicalRecordsMessage =
      'Add your first medical record to keep your health information organized.';
  static const String noMedicalInformation = 'No medical information added yet.';
  static const String signInToAccessRecords =
      'Please sign in to view your medical records.';
  static const String addMedicalRecordSignIn =
      'Please sign in to add a medical record.';
  static const String recordsLoadFailed =
      'Unable to load your medical records. Please try again.';
  static const String profileSaveFailed =
      'Unable to save your medical information. Please try again.';
  static const String medicalInformationSaved = 'Medical information saved.';
  static const String surgeryNameRequired = 'Please enter the surgery name.';
  static const String invalidSurgeryYear =
      'Please enter a valid year (e.g. 2022).';

  // Medical record form
  static const String recordTypeLabel = 'Record Type';
  static const String recordTitleLabel = 'Title';
  static const String recordTitleHint = 'e.g. Annual health check-up';
  static const String recordDateLabel = 'Date';
  static const String noDateSelectedLabel = 'No date selected';
  static const String chooseDateLabel = 'Choose Date';
  static const String descriptionLabel = 'Description';
  static const String descriptionHint = 'Describe this record';
  static const String doctorLabel = 'Doctor';
  static const String doctorHint = 'Optional';
  static const String hospitalHint = 'Optional';
  static const String notesHint = 'Optional notes';
  static const String saveRecord = 'Save Record';
  static const String titleRequired = 'Please enter a title for this record.';
  static const String dateRequired = 'Please select a date for this record.';
  static const String recordSaved = 'Medical record saved.';
  static const String recordUpdated = 'Medical record updated.';
  static const String recordDeleted = 'Medical record deleted.';
  static const String deleteRecordTitle = 'Delete this medical record?';
  static const String deleteRecordMessage =
      'This will permanently remove the record from your medical history. '
      'This action cannot be undone.';
  static const String deleteRecordConfirm = 'Delete';
  static const String recordDetailsTitle = 'Medical Record Details';
  static const String categoryLabel = 'Category';
  static const String addedOnLabel = 'Added';
  static const String updatedOnLabel = 'Last updated';
  static const String recordsLoadMessage = 'Loading your medical records...';
  static const String recordLoadMessage = 'Loading record details...';
  static const String noRecordsInSection = 'No records here yet.';
  static const String documentsComingSoon =
      'Document uploads will be available in a future update.';

  // Prescriptions
  static const String prescriptionsTitle = 'Prescriptions';
  static const String activePrescriptionsLabel = 'Upcoming / Active';
  static const String previousPrescriptionsLabel = 'Previous Prescriptions';
  static const String noPrescriptions = 'No prescriptions yet.';
  static const String noPrescriptionsMessage =
      'Add an existing prescription to keep your medical records organized.';
  static const String addPrescription = 'Add Prescription';
  static const String viewPrescription = 'View Prescription';
  static const String addPrescriptionSignIn =
      'Please sign in to add a prescription.';
  static const String signInToAccessPrescriptions =
      'Please sign in to view your prescriptions.';
  static const String prescriptionsLoadFailed =
      'Unable to load your prescriptions. Please try again.';
  static const String prescriptionLoadFailed =
      'Unable to load this prescription. Please try again.';
  static const String prescriptionsLoadMessage = 'Loading your prescriptions...';
  static const String prescriptionLoadMessage = 'Loading prescription details...';
  static const String prescriptionDetailsTitle = 'Prescription Details';
  static const String editPrescription = 'Edit Prescription';
  static const String savePrescription = 'Save Prescription';
  static const String prescriptionSaved = 'Prescription saved.';
  static const String prescriptionUpdated = 'Prescription updated.';
  static const String prescriptionDeleted = 'Prescription deleted.';
  static const String prescriptionSaveFailed =
      'Unable to save the prescription. Please try again.';
  static const String prescriptionDeleteFailed =
      'Unable to delete the prescription.';
  static const String deletePrescriptionTitle = 'Delete this prescription?';
  static const String deletePrescriptionMessage =
      'This will permanently remove the prescription from your records. '
      'This action cannot be undone.';
  static const String deletePrescriptionConfirm = 'Delete';
  static const String prescriptionDateLabel = 'Prescription Date';
  static const String diagnosisOrConditionLabel = 'Diagnosis / Condition';
  static const String medicinesLabel = 'Medicines';
  static const String medicinesCountWord = 'medicines';
  static const String medicineNameLabel = 'Medicine Name';
  static const String medicineNameHint = 'e.g. Paracetamol';
  static const String dosageLabel = 'Dosage';
  static const String dosageHint = 'e.g. 500 mg';
  static const String frequencyLabel = 'Frequency';
  static const String durationLabel = 'Duration';
  static const String durationHint = 'e.g. 5 days';
  static const String instructionsLabel = 'Instructions';
  static const String instructionsHint = 'e.g. After meals';
  static const String addMedicine = 'Add Medicine';
  static const String editMedicine = 'Edit Medicine';
  static const String updateMedicine = 'Update Medicine';
  static const String medicineNameRequired = 'Please enter the medicine name.';
  static const String doctorNameRequired = 'Please enter the doctor name.';
  static const String prescriptionDateRequired =
      'Please select a prescription date.';
  static const String selectDoctorLabel = 'Select / Enter Doctor';
  static const String pickDoctorLabel = 'Pick Doctor';
  static const String searchDoctorHint =
      'Search doctor by name or specialty';
  static const String noDoctorsMatchFound = 'No doctors found.';
  static const String searchPrescriptionsHint =
      'Search doctor or medicine';
  static const String statusLabel = 'Status';
  static const String noMedicineSelected = 'Select frequency';
  static const String frequencyOnceDaily = 'Once daily';
  static const String frequencyTwiceDaily = 'Twice daily';
  static const String frequencyThreeTimesDaily = 'Three times daily';
  static const String frequencyEvery6Hours = 'Every 6 hours';
  static const String frequencyEvery8Hours = 'Every 8 hours';
  static const String frequencyAsNeeded = 'As needed';
  static const String frequencyOther = 'Other';
  static const String frequencyOptions = 'Select frequency';
  static const String linkAppointmentLabel = 'Link Appointment (optional)';
  static const String noAppointmentsAvailable = 'No appointments available';

  // AI Healthcare Assistant
  static const String aiAssistantTitle = 'AI Healthcare Assistant';
  static const String aiNewChatTooltip = 'New Chat';
  static const String aiWelcomeActionLabel = 'Ask AI Assistant';
  static const String aiFloatingButtonTooltip = 'Open AI Assistant';
  static const String aiClearTitle = 'Clear Conversation';
  static const String aiClearMessage =
      'This will clear the current conversation. This action cannot be '
      'undone. Are you sure you want to continue?';
  static const String aiClearConfirm = 'Clear';
  static const String aiDisclaimer =
      'AI-generated information. Not a replacement for professional medical '
      'advice.';
  static const String aiNetworkError =
      'Unable to connect to the assistant. Please check your internet '
      'connection and try again.';
  static const String aiAssistantWelcome =
      'Chat with your AI assistant for general health guidance, records, '
      'prescriptions and appointments. Informational only — it does not '
      'replace your doctor.';
  static const String aiThinking = 'Assistant is thinking...';
  static const String aiInputHint = 'Ask something...';
  static const String aiSentForbiddenMessage =
      'I cannot prescribe or recommend changes to medication or dosage. '
      'Please consult a qualified healthcare professional for advice about '
      'your treatment.';

  // Diet & Exercise (Phase 15)
  static const String dietExerciseTitle = 'Diet & Exercise';
  static const String dietTitle = 'Diet';
  static const String exerciseTitle = 'Exercise';
  static const String yourDietPlan = 'Your Diet Plan';
  static const String yourExercisePlan = 'Your Exercise Plan';
  static const String todaysGoalLabel = "Today's Goal";
  static const String dietExerciseSubtitle =
      'Build healthier habits with personalized wellness guidance.';
  static const String todaysProgressLabel = "Today's Progress";
  static const String waterIntakeLabel = 'Water Intake';
  static const String exerciseProgressLabel = 'Exercise';
  static const String activityProgressLabel = 'Activity';
  static const String todaysDietPlanLabel = "Today's Diet Plan";
  static const String viewFullDietPlan = 'View Full Diet Plan';
  static const String todaysExerciseLabel = "Today's Exercise";
  static const String startWorkout = 'Start Workout';
  static const String viewExercises = 'View Exercises';
  static const String exerciseLibraryLabel = 'Exercise Library';
  static const String allCategories = 'All';
  static const String dietPlanTitle = 'Diet Plan';
  static const String nutritionGuidanceLabel = 'Nutrition guidance';
  static const String personalizedForYouLabel = 'Personalized for you';
  static const String waterGoalLabel = 'Daily water goal';
  static const String glassesUnit = 'glasses';
  static const String minutesUnit = 'min';
  static const String stepsUnit = 'steps';
  static const String decreaseWaterTooltip = 'Remove one glass of water';
  static const String increaseWaterTooltip = 'Add one glass of water';
  static const String markCompletedLabel = 'Mark as Completed';
  static const String completedLabel = 'Completed';
  static const String instructionsLabel2 = 'Instructions';
  static const String safetyNoteLabel = 'Safety note';
  static const String howToStepsLabel = 'How to do it';
  static const String difficultyLabel2 = 'Difficulty';
  static const String durationLabel2 = 'Duration';
  static const String dailyActivityTitle = 'Daily Activity';
  static const String addActivity = 'Add Activity';
  static const String activityNameLabel = 'Activity';
  static const String activityNameHint = 'e.g. Walking';
  static const String activityDurationLabel = 'Duration (minutes)';
  static const String activityDurationHint = 'e.g. 20';
  static const String stepsLabel = 'Steps (optional)';
  static const String stepsHint = 'e.g. 3500';
  static const String saveActivity = 'Save Activity';
  static const String noActivityLogged = 'No activity logged yet.';
  static const String noActivityLoggedMessage =
      'Add an activity to keep a simple record of your daily movement.';
  static const String activitySaved = 'Activity saved.';
  static const String activityRemoved = 'Activity removed.';
  static const String activityNameRequired = 'Please enter an activity name.';
  static const String activityDurationRequired =
      'Please enter a duration in minutes.';
  static const String activityDurationInvalid =
      'Please enter a duration greater than zero minutes.';
  static const String activityDurationTooLong =
      'Please enter a duration below 600 minutes.';
  static const String stepsInvalid = 'Please enter a valid number of steps.';
  static const String progressTitle = 'Progress';
  static const String todayLabel = 'Today';
  static const String lastSevenDaysLabel = 'Last 7 days';
  static const String exerciseConsistencyLabel = 'Exercise consistency';
  static const String waterConsistencyLabel = 'Water consistency';
  static const String completedWorkoutsLabel = 'Completed exercises';
  static const String minutesThisWeek = 'minutes this week';
  static const String daysLabel = 'days';
  static const String noHistoryLabel = 'No activity recorded yet';
  static const String noHistoryMessage =
      'Complete an exercise or log your water to start building your history.';
  static const String wellnessPreferencesTitle = 'Wellness Preferences';
  static const String wellnessGoalLabel = 'Wellness goal';
  static const String wellnessGoalHelper =
      'Choose the habit you would like to focus on. This is a wellness goal, '
      'not a treatment plan.';
  static const String foodPreferenceLabel = 'Food preference';
  static const String activityLevelLabel = 'Activity level';
  static const String dailyExerciseGoalLabel = 'Daily exercise goal';
  static const String savePreferences = 'Save Preferences';
  static const String preferencesSaved = 'Wellness preferences saved.';
  static const String preferencesFailed =
      'Unable to save your wellness preferences. Please try again.';
  static const String preferencesLoadFailed =
      'Unable to load your saved preferences. Using general wellness '
      'defaults.';
  static const String dietExerciseLoadFailed =
      'Unable to load your activity right now. Please try again.';
  static const String waterSaveFailed =
      'Unable to save your water intake right now. Please try again.';
  static const String workoutSaveFailed =
      'Unable to save your workout right now. Please try again.';
  static const String activitySaveFailed =
      'Unable to save your activity right now. Please try again.';
  static const String preferencesSaveFailed =
      'Unable to save your wellness preferences. Please try again.';
  static const String historyLoadFailed =
      'Unable to load your progress right now. Please try again.';
  static const String signInToTrack =
      'Please sign in to track your water, exercises and activity.';
  static const String exerciseNotFound = 'Exercise not found';
  static const String exerciseNotFoundMessage =
      'This exercise is no longer available. Please choose another from the library.';
  static const String dietPlanDisclaimer =
      'These recommendations are for general wellness and are not a substitute '
      'for advice from a qualified healthcare professional.';
  static const String dietExerciseDisclaimer =
      'Nutrition and exercise information is provided for general wellness and '
      'educational purposes. It is not medical advice and does not replace '
      'consultation with a qualified healthcare professional.';
  static const String exerciseSafetyNote =
      'General safety guidance: warm up gradually, stay hydrated, and stop if '
      'you experience pain, dizziness, unusual shortness of breath or any other '
      'concerning symptoms.';
  static const String approximateLabel = 'Approximate';
  static const String exampleServingLabel = 'Example serving';
  static const String generalGuidanceLabel = 'General guidance';
  static const String wellnessGoalsAreNotTreatment =
      'Wellness goals are for habit building only and are not a treatment plan. '
      'Speak to a qualified healthcare professional before starting a new '
      'exercise routine.';
  static const String askAiAboutDiet = 'Ask AI Assistant';
  static const String aiDietPromptHint =
      'Ask the assistant for meal ideas, routines or general wellness answers.';
  static const String notApplicableLabel = 'Not applicable';

  // Hospital / Pharmacy Locator (Phase 16)
  static const String healthcareLocatorTitle = 'Nearby Healthcare';
  static const String searchHealthcareHint = 'Search by name or address';
  static const String gettingLocation = 'Getting your location...';
  static const String loadingNearbyPlaces = 'Finding nearby places...';
  static const String filterAll = 'All';
  static const String getDirections = 'Get Directions';
  static const String directionsAction = 'Directions';
  static const String callAction = 'Call';
  static const String openWebsite = 'Open Website';
  static const String sortNearest = 'Nearest first';
  static const String sortByName = 'Name (A-Z)';
  static const String listViewLabel = 'List';
  static const String mapViewLabel = 'Map';
  static const String sourceLabel = 'Source';
  static const String addressLabel = 'Address';
  static const String phoneLabel = 'Phone';
  static const String openingHoursLabel = 'Opening hours';
  static const String websiteLabel = 'Website';
  static const String routeDistanceLabel = 'Distance';
  static const String routeDurationLabel = 'Est. time';
  static const String noResultsTitle = 'No facilities found';
  static const String noResultsMessage =
      'We could not find any hospitals or pharmacies near you. Try again or '
      'search a larger area by moving to a different location.';
  static const String searchLargerArea = 'Search a larger area';
  static const String locationServiceDisabled =
      'Location is turned off on this device. Turn on location services and '
      'try again.';
  static const String locationPermissionDenied =
      'Location permission is needed to find facilities near you. Please allow '
      'access and try again.';
  static const String locationPermissionDeniedForever =
      'Location permission is permanently denied. Enable it for this app in '
      'your device settings, then try again.';
  static const String locationTimeout =
      'We could not get your location in time. Please try again.';
  static const String locationUnavailable =
      'We could not get your location right now. Please try again.';
  static const String placesLoadFailed =
      'Unable to load nearby facilities. Please try again.';
  static const String placesNetworkError =
      'Unable to connect to the facility service. Please check your internet '
      'connection and try again.';
  static const String placesTemporarilyUnavailable =
      'Nearby facilities are temporarily unavailable. Please try again in a '
      'moment.';
  static const String placesServiceError =
      'The facility data could not be read right now. Please try again.';
  static const String directionsLoadFailed =
      'Unable to load a route. Opening directions in your maps app instead.';
  static const String openingMaps = 'Opening directions in your maps app...';
  static const String callingNumber = 'Opening the dialer...';
  static const String openingWebsite = 'Opening website...';
  static const String actionNotAvailable =
      'This information is not available for this facility.';
  static const String osmAttribution =
      'Facility data © OpenStreetMap contributors';
  static const String healthcareSourceNote =
      'Facility details are provided by OpenStreetMap and are not medically '
      'verified. Availability, services and opening hours may change.';
  static const String nearbyFacilitiesLabel = 'Nearby facilities';
}
