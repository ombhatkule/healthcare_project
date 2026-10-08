import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../models/user_profile.dart';
import '../../services/profile_service.dart';

/// State management for the user profile.
///
/// Loads the profile from Firestore once the user is authenticated, exposes
/// loading / error state, and provides create / update operations with profile
/// data kept out of the widgets.
class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService;

  ProfileProvider(this._profileService);

  UserProfile? _profile;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  bool _loaded = false;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get isLoaded => _loaded;
  bool get hasError => _errorMessage != null;

  /// Load the profile for the given authenticated [uid].
  /// Missing documents are handled gracefully (profile stays null, no crash).
  Future<void> loadProfile(String uid) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _profile = await _profileService.getProfile(uid);
      _loaded = true;
    } on AppException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Could not load your profile. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  /// Create the initial profile document and refresh local state.
  Future<bool> createProfile(UserProfile profile) async {
    _setSaving(true);
    _errorMessage = null;
    try {
      await _profileService.createProfile(profile);
      _profile = profile;
      _loaded = true;
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Could not save your profile. Please try again.';
      return false;
    } finally {
      _setSaving(false);
    }
  }

  /// Update the profile and refresh local state on success.
  Future<bool> updateProfile(UserProfile profile) async {
    _setSaving(true);
    _errorMessage = null;
    try {
      await _profileService.updateProfile(profile);
      _profile = profile;
      _loaded = true;
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Could not save your profile. Please try again.';
      return false;
    } finally {
      _setSaving(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setSaving(bool value) {
    _isSaving = value;
    notifyListeners();
  }
}
