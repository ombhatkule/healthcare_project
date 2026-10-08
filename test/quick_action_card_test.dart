import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/features/home/presentation/widgets/quick_action_card.dart';

/// Regression test for the Phase 7J Health Dashboard overflow fix.
///
/// Renders the four quick-action cards (including the Disease Prediction card)
/// inside the same fixed-height horizontal ListView used by the dashboard and
/// asserts no RenderFlex overflow exception is thrown.
void main() {
  testWidgets('quick action cards do not overflow at the dashboard height',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: SizedBox(
              height: 164,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  const items = [
                    (
                      icon: Icons.analytics_outlined,
                      title: 'Disease Prediction',
                      description: 'AI-based symptom assessment',
                      color: Color(0xFF5C6BC0),
                    ),
                    (
                      icon: Icons.person_search_outlined,
                      title: 'Find a Doctor',
                      description: 'Search qualified professionals',
                      color: Color(0xFF10B981),
                    ),
                    (
                      icon: Icons.event_available_outlined,
                      title: 'Book Appointment',
                      description: 'Schedule a visit',
                      color: Color(0xFFF59E0B),
                    ),
                    (
                      icon: Icons.smart_toy_outlined,
                      title: 'AI Assistant',
                      description: 'Chat for health guidance',
                      color: Color(0xFF3B82F6),
                    ),
                  ];
                  final item = items[index];
                  return SizedBox(
                    width: 150,
                    child: QuickActionCard(
                      icon: item.icon,
                      title: item.title,
                      description: item.description,
                      color: item.color,
                      onTap: () {},
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    // RenderFlex overflow exceptions are reported via takeException.
    expect(tester.takeException(), isNull,
        reason: 'Quick action cards overflowed their container.');
  });
}

