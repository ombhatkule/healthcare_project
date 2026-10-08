import '../models/disease_specialty_mapping.dart';
import '../models/doctor.dart';
import '../models/specialty_summary.dart';
import 'doctor_recommendation_service.dart';

/// In-memory, realistic-looking placeholder data source for doctors.
///
/// Designed to be replaced by a backend integration later without changing
/// any screens or controllers.
class MockDoctorRepository implements DoctorRecommendationService {
  static final List<Doctor> _doctors = _buildCatalog();

  @override
  Future<List<Doctor>> getDoctorsBySpecialty(String specialty) async {
    await _simulateNetwork();
    final key = _norm(specialty);
    if (key.isEmpty) return const [];
    return List.unmodifiable(
      _doctors.where((d) => _norm(d.specialty) == key),
    );
  }

  @override
  Future<List<SpecialtySummary>> getSpecialtySummaries() async {
    await _simulateNetwork();
    return List.unmodifiable(
      Specialties.all.map(
        (s) => SpecialtySummary(
          specialty: s,
          doctorCount: _doctors.where((d) => _norm(d.specialty) == _norm(s)).length,
        ),
      ),
    );
  }

  @override
  Future<Doctor?> getDoctorById(String id) async {
    await _simulateNetwork();
    for (final doctor in _doctors) {
      if (doctor.id == id) return doctor;
    }
    return null;
  }

  @override
  Future<List<String>> getLocations() async {
    await _simulateNetwork();
    final locations = _doctors
        .map((d) => d.city)
        .where((city) => city.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return List.unmodifiable(locations);
  }

  @override
  Future<List<Doctor>> searchDoctors({
    String query = '',
    String specialty = '',
    String location = '',
    double minRating = 0,
    DoctorSort sort = DoctorSort.recommended,
  }) async {
    await _simulateNetwork();
    final results = _doctors
        .where(
          (d) =>
              DoctorSearchHelper.matchesQuery(d, query) &&
              DoctorSearchHelper.matchesSpecialty(d, specialty) &&
              DoctorSearchHelper.matchesLocation(d, location) &&
              DoctorSearchHelper.matchesMinRating(d, minRating),
        )
        .toList();
    DoctorSearchHelper.sortDoctors(results, sort);
    return List.unmodifiable(results);
  }

  Future<void> _simulateNetwork() =>
      Future<void>.delayed(const Duration(milliseconds: 150));

  static String _norm(String value) => value.trim().toLowerCase();

  static List<Doctor> _buildCatalog() {
    const doctors = <Doctor>[
      // General Physician
      Doctor(
        id: 'doc-gp-01',
        name: 'Dr. Aarti Sharma',
        specialty: Specialties.generalPhysician,
        qualification: 'MBBS, MD (General Medicine)',
        experienceYears: 12,
        hospital: 'Sahyadri Hospital',
        location: 'Nagar Road, Pune',
        consultationFee: 600,
        rating: 4.6,
        reviewCount: 214,
        availableToday: true,
        languages: ['English', 'Hindi', 'Marathi'],
      ),
      Doctor(
        id: 'doc-gp-02',
        name: 'Dr. Rajesh Kulkarni',
        specialty: Specialties.generalPhysician,
        qualification: 'MBBS, DNB (Family Medicine)',
        experienceYears: 9,
        hospital: 'Ruby Hall Clinic',
        location: 'Dhole Patil Road, Pune',
        consultationFee: 500,
        rating: 4.4,
        reviewCount: 158,
        availableToday: true,
        languages: ['English', 'Marathi', 'Hindi'],
      ),
      Doctor(
        id: 'doc-gp-03',
        name: 'Dr. Sneha Pillai',
        specialty: Specialties.generalPhysician,
        qualification: 'MBBS, MD (General Medicine)',
        experienceYears: 14,
        hospital: 'Fortis Hospital',
        location: 'Bannerghatta Rd, Bengaluru',
        consultationFee: 700,
        rating: 4.7,
        reviewCount: 301,
        availableToday: false,
        languages: ['English', 'Kannada', 'Hindi'],
      ),
      Doctor(
        id: 'doc-gp-04',
        name: 'Dr. Mohan Iyer',
        specialty: Specialties.generalPhysician,
        qualification: 'MBBS',
        experienceYears: 6,
        hospital: 'Apollo Clinic',
        location: 'Koregaon Park, Pune',
        consultationFee: 450,
        rating: 4.2,
        reviewCount: 87,
        availableToday: true,
        languages: ['English', 'Hindi', 'Tamil'],
      ),

      // Cardiologist
      Doctor(
        id: 'doc-ca-01',
        name: 'Dr. Vikrant Deshmukh',
        specialty: Specialties.cardiologist,
        qualification: 'MBBS, MD, DM (Cardiology)',
        experienceYears: 18,
        hospital: 'Jehangir Multispeciality',
        location: 'Sassoon Road, Pune',
        consultationFee: 1200,
        rating: 4.8,
        reviewCount: 402,
        availableToday: true,
        languages: ['English', 'Marathi', 'Hindi'],
      ),
      Doctor(
        id: 'doc-ca-02',
        name: 'Dr. Farhan Ansari',
        specialty: Specialties.cardiologist,
        qualification: 'MBBS, MD, DM (Cardiology)',
        experienceYears: 11,
        hospital: 'Nanavati Max Hospital',
        location: 'Vile Parle, Mumbai',
        consultationFee: 1500,
        rating: 4.5,
        reviewCount: 176,
        availableToday: false,
        languages: ['English', 'Hindi', 'Urdu'],
      ),
      Doctor(
        id: 'doc-ca-03',
        name: 'Dr. Meera Krishnan',
        specialty: Specialties.cardiologist,
        qualification: 'MBBS, MD (Internal Medicine), FACC',
        experienceYears: 22,
        hospital: 'Narayana Health',
        location: 'Hosur Road, Bengaluru',
        consultationFee: 1400,
        rating: 4.9,
        reviewCount: 587,
        availableToday: true,
        languages: ['English', 'Kannada', 'Tamil'],
      ),

      // Pulmonologist
      Doctor(
        id: 'doc-pu-01',
        name: 'Dr. Ketan Joshi',
        specialty: Specialties.pulmonologist,
        qualification: 'MBBS, MD, DM (Pulmonology)',
        experienceYears: 15,
        hospital: 'Columbia Asia',
        location: 'Manjari Road, Hadapsar, Pune',
        consultationFee: 900,
        rating: 4.6,
        reviewCount: 143,
        availableToday: true,
        languages: ['English', 'Marathi', 'Hindi'],
      ),
      Doctor(
        id: 'doc-pu-02',
        name: 'Dr. Nisha Reddy',
        specialty: Specialties.pulmonologist,
        qualification: 'MBBS, MD (Pulmonary Medicine), DNB',
        experienceYears: 8,
        hospital: 'Apollo Hospital',
        location: 'Jubilee Hills, Hyderabad',
        consultationFee: 850,
        rating: 4.3,
        reviewCount: 98,
        availableToday: false,
        languages: ['English', 'Telugu', 'Hindi'],
      ),
      Doctor(
        id: 'doc-pu-03',
        name: 'Dr. Arvind Menon',
        specialty: Specialties.pulmonologist,
        qualification: 'MBBS, MD, DNB (Respiratory Medicine)',
        experienceYears: 20,
        hospital: 'Fortis Hospital',
        location: 'Mulund, Mumbai',
        consultationFee: 1000,
        rating: 4.8,
        reviewCount: 266,
        availableToday: true,
        languages: ['English', 'Hindi', 'Malayalam'],
      ),

      // Gastroenterologist
      Doctor(
        id: 'doc-ga-01',
        name: 'Dr. Sunil Ghate',
        specialty: Specialties.gastroenterologist,
        qualification: 'MBBS, MD, DM (Gastroenterology)',
        experienceYears: 13,
        hospital: 'Sahyadri Super Speciality',
        location: 'Karve Nagar, Pune',
        consultationFee: 950,
        rating: 4.5,
        reviewCount: 202,
        availableToday: true,
        languages: ['English', 'Marathi', 'Hindi'],
      ),
      Doctor(
        id: 'doc-ga-02',
        name: 'Dr. Ananya Rao',
        specialty: Specialties.gastroenterologist,
        qualification: 'MBBS, MD, DM (Hepatology)',
        experienceYears: 10,
        hospital: 'Manipal Hospital',
        location: 'Old Airport Road, Bengaluru',
        consultationFee: 1100,
        rating: 4.7,
        reviewCount: 189,
        availableToday: false,
        languages: ['English', 'Kannada', 'Hindi'],
      ),
      Doctor(
        id: 'doc-ga-03',
        name: 'Dr. Imran Shaikh',
        specialty: Specialties.gastroenterologist,
        qualification: 'MBBS, MD, DNB (Gastroenterology)',
        experienceYears: 16,
        hospital: 'Lilavati Hospital',
        location: 'Bandra West, Mumbai',
        consultationFee: 1300,
        rating: 4.4,
        reviewCount: 121,
        availableToday: true,
        languages: ['English', 'Hindi', 'Urdu'],
      ),

      // Dermatologist
      Doctor(
        id: 'doc-de-01',
        name: 'Dr. Pooja Bansal',
        specialty: Specialties.dermatologist,
        qualification: 'MBBS, MD (Dermatology)',
        experienceYears: 7,
        hospital: 'Radiance Skin Clinic',
        location: 'Kalyani Nagar, Pune',
        consultationFee: 700,
        rating: 4.7,
        reviewCount: 233,
        availableToday: true,
        languages: ['English', 'Hindi', 'Punjabi'],
      ),
      Doctor(
        id: 'doc-de-02',
        name: 'Dr. Rohan Khandelwal',
        specialty: Specialties.dermatologist,
        qualification: 'MBBS, MD, DNB (Dermatology)',
        experienceYears: 12,
        hospital: 'Saket Derma Centre',
        location: 'Saket, New Delhi',
        consultationFee: 800,
        rating: 4.5,
        reviewCount: 174,
        availableToday: false,
        languages: ['English', 'Hindi'],
      ),
      Doctor(
        id: 'doc-de-03',
        name: 'Dr. Lavanya Nayak',
        specialty: Specialties.dermatologist,
        qualification: 'MBBS, MD (Dermatology, Venereology)',
        experienceYears: 5,
        hospital: 'CureSkin Clinic',
        location: 'Indiranagar, Bengaluru',
        consultationFee: 650,
        rating: 4.2,
        reviewCount: 64,
        availableToday: true,
        languages: ['English', 'Kannada', 'Tamil'],
      ),

      // Neurologist
      Doctor(
        id: 'doc-ne-01',
        name: 'Dr. Anil Wagh',
        specialty: Specialties.neurologist,
        qualification: 'MBBS, MD, DM (Neurology)',
        experienceYears: 17,
        hospital: 'Deenanath Mangeshkar Hospital',
        location: 'Erandwane, Pune',
        consultationFee: 1100,
        rating: 4.8,
        reviewCount: 256,
        availableToday: true,
        languages: ['English', 'Marathi', 'Hindi'],
      ),
      Doctor(
        id: 'doc-ne-02',
        name: 'Dr. Kavita Singh',
        specialty: Specialties.neurologist,
        qualification: 'MBBS, MD, DNB (Neurology)',
        experienceYears: 9,
        hospital: 'AIIMS',
        location: 'Ansari Nagar, New Delhi',
        consultationFee: 1250,
        rating: 4.6,
        reviewCount: 148,
        availableToday: false,
        languages: ['English', 'Hindi'],
      ),
      Doctor(
        id: 'doc-ne-03',
        name: 'Dr. Varun Shetty',
        specialty: Specialties.neurologist,
        qualification: 'MBBS, MD (Neurology), FRCP',
        experienceYears: 21,
        hospital: 'Kempegowda Institute',
        location: 'KR Road, Bengaluru',
        consultationFee: 1400,
        rating: 4.9,
        reviewCount: 319,
        availableToday: true,
        languages: ['English', 'Kannada', 'Telugu'],
      ),

      // Orthopedic
      Doctor(
        id: 'doc-or-01',
        name: 'Dr. Sagar Pawar',
        specialty: Specialties.orthopedic,
        qualification: 'MBBS, MS (Orthopaedics), DNB',
        experienceYears: 11,
        hospital: 'Orthocare Hospital',
        location: 'Baner, Pune',
        consultationFee: 800,
        rating: 4.4,
        reviewCount: 167,
        availableToday: true,
        languages: ['English', 'Marathi', 'Hindi'],
      ),
      Doctor(
        id: 'doc-or-02',
        name: 'Dr. Harish Chandra',
        specialty: Specialties.orthopedic,
        qualification: 'MBBS, MS (Orthopaedics)',
        experienceYears: 16,
        hospital: 'AIIMS',
        location: 'Rishikesh',
        consultationFee: 900,
        rating: 4.6,
        reviewCount: 210,
        availableToday: false,
        languages: ['English', 'Hindi'],
      ),
      Doctor(
        id: 'doc-or-03',
        name: 'Dr. Reena Kapoor',
        specialty: Specialties.orthopedic,
        qualification: 'MBBS, MS (Orthopaedics), Fellowship (Joint)',
        experienceYears: 8,
        hospital: 'Apollo Hospital',
        location: 'Camp, Pune',
        consultationFee: 850,
        rating: 4.5,
        reviewCount: 132,
        availableToday: true,
        languages: ['English', 'Hindi', 'Punjabi'],
      ),

      // Endocrinologist
      Doctor(
        id: 'doc-en-01',
        name: 'Dr. Nitin Bhave',
        specialty: Specialties.endocrinologist,
        qualification: 'MBBS, MD, DM (Endocrinology)',
        experienceYears: 12,
        hospital: 'Sahyadri Speciality',
        location: 'Deccan Gymkhana, Pune',
        consultationFee: 1000,
        rating: 4.7,
        reviewCount: 198,
        availableToday: true,
        languages: ['English', 'Marathi', 'Hindi'],
      ),
      Doctor(
        id: 'doc-en-02',
        name: 'Dr. Shalini Gupta',
        specialty: Specialties.endocrinologist,
        qualification: 'MBBS, MD, DNB (Endocrinology)',
        experienceYears: 6,
        hospital: 'Max Super Speciality',
        location: 'Saket, New Delhi',
        consultationFee: 1200,
        rating: 4.4,
        reviewCount: 105,
        availableToday: false,
        languages: ['English', 'Hindi'],
      ),
      Doctor(
        id: 'doc-en-03',
        name: 'Dr. Deepak Ramakrishnan',
        specialty: Specialties.endocrinologist,
        qualification: 'MBBS, MD, DM (Endocrinology)',
        experienceYears: 14,
        hospital: 'Manipal Hospital',
        location: 'Yeshwanthpur, Bengaluru',
        consultationFee: 1150,
        rating: 4.8,
        reviewCount: 244,
        availableToday: true,
        languages: ['English', 'Kannada', 'Tamil'],
      ),

      // Nephrologist
      Doctor(
        id: 'doc-np-01',
        name: 'Dr. Milind Desai',
        specialty: Specialties.nephrologist,
        qualification: 'MBBS, MD, DM (Nephrology)',
        experienceYears: 13,
        hospital: 'KEM Hospital',
        location: 'Parel, Mumbai',
        consultationFee: 1050,
        rating: 4.5,
        reviewCount: 118,
        availableToday: true,
        languages: ['English', 'Marathi', 'Hindi'],
      ),
      Doctor(
        id: 'doc-np-02',
        name: 'Dr. Divya Menon',
        specialty: Specialties.nephrologist,
        qualification: 'MBBS, MD, DNB (Nephrology)',
        experienceYears: 7,
        hospital: 'NephroPlus Centre',
        location: 'Whitefield, Bengaluru',
        consultationFee: 950,
        rating: 4.3,
        reviewCount: 74,
        availableToday: false,
        languages: ['English', 'Kannada', 'Malayalam'],
      ),
    ];
    return List.unmodifiable(doctors);
  }
}