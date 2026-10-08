import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/core/errors/exceptions.dart';
import 'package:healthcare_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:healthcare_app/features/profile/models/user_profile.dart';
import 'package:healthcare_app/features/profile/presentation/profile_validator.dart';
import 'package:healthcare_app/features/profile/presentation/profile_screen.dart';
import 'package:healthcare_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:healthcare_app/features/profile/services/profile_service.dart';
import 'package:provider/provider.dart';
import 'fake_auth_service.dart';
import 'fake_profile_service.dart';
import 'fake_user.dart';

void main() {
  group('ProfileValidator', () {
    test('accepts a valid full name', () {
      expect(ProfileValidator.validateName('Jane Doe'), isNull);
    });

    test('rejects empty / null full name', () {
      expect(ProfileValidator.validateName(''), isNotNull);
      expect(ProfileValidator.validateName('   '), isNotNull);
      expect(ProfileValidator.validateName(null), isNotNull);
    });

    test('accepts a valid phone and rejects an invalid one', () {
      expect(ProfileValidator.validatePhone('+1-555-123-4567'), isNull);
      expect(ProfileValidator.validatePhone('123'), isNotNull);
    });

    test('height and weight reject non-numeric / non-positive values', () {
      expect(ProfileValidator.validateHeight('175'), isNull);
      expect(ProfileValidator.validateHeight('abc'), isNotNull);
      expect(ProfileValidator.validateHeight('-5'), isNotNull);
      expect(ProfileValidator.validateWeight('70'), isNull);
      expect(ProfileValidator.validateWeight('0'), isNotNull);
    });

    test('empty optional numeric values are allowed', () {
      expect(ProfileValidator.validateHeight(''), isNull);
      expect(ProfileValidator.validateWeight('  '), isNull);
    });
  });

  group('ProfileScreen', () {
    testWidgets('renders without crashing when no Firestore document exists',
        (WidgetTester tester) async {
      final profileService = FakeProfileService()..profile = null;
      final authService = FakeAuthService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(authService),
            ),
            Provider<ProfileService>.value(value: profileService),
            ChangeNotifierProvider<ProfileProvider>(
              create: (_) => ProfileProvider(profileService),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Personal Information'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Health Information'),
        200,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('Health Information'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Account Settings'),
        200,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('Account Settings'), findsOneWidget);
    });
  });

  group('Profile Firestore ownership', () {
    Future<void> pumpProfile(
      WidgetTester tester, {
      required AuthProvider authProvider,
      required FakeProfileService profileService,
    }) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            Provider<ProfileService>.value(value: profileService),
            ChangeNotifierProvider<ProfileProvider>(
              create: (_) => ProfileProvider(profileService),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
        'loads the profile with the authenticated Firebase UID and no '
        'permission error', (tester) async {
      final profileService = FakeProfileService(
        profile: const UserProfile(
          uid: 'user-42',
          fullName: 'Om',
          email: 'om@example.com',
        ),
      );
      final authProvider = AuthProvider(
        FakeAuthService(
          initialUser: FakeUser(uid: 'user-42', email: 'om@example.com'),
        ),
      );
      addTearDown(authProvider.dispose);

      await pumpProfile(
        tester,
        authProvider: authProvider,
        profileService: profileService,
      );

      expect(profileService.lastRequestedUid, 'user-42',
          reason: 'the authenticated UID must build the Firestore path');
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.textContaining('permission'), findsNothing);
    });

    testWidgets('a signed-out user never touches user-scoped Firestore',
        (WidgetTester tester) async {
      final profileService = FakeProfileService();
      final authProvider = AuthProvider(FakeAuthService());
      addTearDown(authProvider.dispose);

      await pumpProfile(
        tester,
        authProvider: authProvider,
        profileService: profileService,
      );

      expect(profileService.lastRequestedUid, isNull,
          reason: 'no Firestore call may happen without an authenticated user');
    });

    test('a permission failure is reported as permission, not a sign-out request',
        () async {
      final profileService = FakeProfileService()
        ..failure = const AppException(
          message: 'You do not have permission to access this profile.',
        );
      final provider = ProfileProvider(profileService);
      addTearDown(provider.dispose);

      await provider.loadProfile('user-42');

      expect(provider.hasError, isTrue);
      expect(provider.errorMessage, contains('permission'));
      expect(provider.errorMessage, isNot(contains('sign out')));
    });
  });
}
