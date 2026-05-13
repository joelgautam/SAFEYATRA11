import 'package:flutter/material.dart';
import 'buttom_navigation_screen.dart';

class FaqInfoScreen extends StatelessWidget {
  const FaqInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF1A1A2E),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'FAQs & Information',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _InfoCard(
                title: 'System Rules',
                lines: [
                  'Keep location access enabled during active trips.',
                  'Add at least one guardian before using passive mode.',
                  'Respond to deviation alerts quickly for accurate support.',
                ],
              ),
              const SizedBox(height: 12),
              const _InfoCard(
                title: 'Safety Regulations',
                lines: [
                  'Use SOS only for genuine emergency situations.',
                  'Do not share false location alerts.',
                  'Keep emergency contacts updated and reachable.',
                ],
              ),
              const SizedBox(height: 12),
              const _InfoCard(
                title: 'FAQs',
                lines: [
                  'Q: What happens if I go off-route?',
                  'A: You get a safety check first, then alert flow starts.',
                  'Q: Who receives alerts?',
                  'A: Only your selected guardians and emergency network.',
                ],
              ),
              const SizedBox(height: 12),
              const _InfoCard(
                title: 'About SafeYatra',
                lines: [
                  'SafeYatra helps monitor trips with passive safety support.',
                  'The app is designed to reduce panic and improve response time.',
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const SafeYatraBottomNav(currentRoute: 'home'),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<String> lines;

  const _InfoCard({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '- $line',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xFF6B6685),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
