import 'package:url_launcher/url_launcher.dart';

/// Thin wrapper around `url_launcher` so screens stay testable and the external
/// app behaviour is easy to fake in tests.
abstract class LinkLauncher {
  /// Opens a web URL in an external app or browser.
  Future<bool> openUrl(String url);

  /// Opens the platform dialer with [phone] prefilled.
  Future<bool> callPhone(String phone);

  /// Opens the device's default maps app with driving directions to a point.
  Future<bool> openDirections({
    required double latitude,
    required double longitude,
    String? label,
  });
}

/// Default [LinkLauncher] implementation using the `url_launcher` plugin.
class UrlLinkLauncher implements LinkLauncher {
  const UrlLinkLauncher();

  @override
  Future<bool> openUrl(String url) async {
    try {
      return await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> callPhone(String phone) async {
    final normalized = phone.trim();
    if (normalized.isEmpty) return false;
    try {
      return await launchUrl(
        Uri(scheme: 'tel', path: normalized),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> openDirections({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final destination = '$latitude,$longitude';
    final uri = Uri.https(
      'www.google.com',
      '/maps/dir/',
      {
        'api': '1',
        'destination': destination,
        'travelmode': 'driving',
      },
    );
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}