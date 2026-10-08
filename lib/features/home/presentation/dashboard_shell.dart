import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../doctor_search/presentation/doctor_search_screen.dart';
import '../../appointment_history/presentation/appointment_history_screen.dart';
import '../../medical_records/presentation/medical_records_screen.dart';

/// The main navigation shell containing the bottom navigation bar.
///
/// Hosts the five primary tabs: Home, Doctors, Appointments, Records, and
/// Profile. Placeholder tabs are used for modules not yet implemented; they
/// can be swapped for real screens without changing this shell.
class DashboardShell extends StatefulWidget {
  static const int tabHome = 0;
  static const int tabDoctors = 1;
  static const int tabAppointments = 2;
  static const int tabRecords = 3;
  static const int tabProfile = 4;

  final int initialIndex;

  const DashboardShell({super.key, this.initialIndex = DashboardShell.tabHome});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  late int _currentIndex = widget.initialIndex;

  final _tabs = const <Widget>[
    HomeScreen(),
    DoctorSearchScreen(),
    AppointmentHistoryScreen(),
    MedicalRecordsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon: Icon(Icons.medical_services),
            label: 'Doctors',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Appointments',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Records',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
