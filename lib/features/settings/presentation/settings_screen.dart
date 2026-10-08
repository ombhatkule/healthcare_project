import 'package:flutter/material.dart';
import '../../../shared/services/api_service.dart';

/// Placeholder for the Settings module.
/// Includes a temporary backend connection test for development.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Temporary backend connection test
          _BackendConnectionTest(),
        ],
      ),
    );
  }
}

/// Temporary widget for testing Flask backend connection.
/// Remove this in production.
class _BackendConnectionTest extends StatefulWidget {
  @override
  State<_BackendConnectionTest> createState() => _BackendConnectionTestState();
}

class _BackendConnectionTestState extends State<_BackendConnectionTest> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  HealthCheckResult? _result;

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _result = null;
    });

    final result = await _apiService.checkBackendHealth();

    setState(() {
      _isLoading = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backend Connection Test',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Temporary development tool to verify Flask backend connectivity.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _testConnection,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_find),
                label: Text(_isLoading ? 'Testing...' : 'Test Backend Connection'),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _result!.isConnected
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _result!.isConnected ? Colors.green : Colors.red,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _result!.isConnected ? Icons.check_circle : Icons.error,
                      color: _result!.isConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _result!.message,
                        style: TextStyle(
                          color: _result!.isConnected
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
