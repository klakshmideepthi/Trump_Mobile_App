import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.blueGradient,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last Updated: [Date]',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '1. Information We Collect',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'We collect information that you provide directly to us, including:',
            ),
            const Text('• Name and contact information'),
            const Text('• Payment information'),
            const Text('• Device information'),
            const Text('• Order history'),
            const SizedBox(height: 24),
            const Text(
              '2. How We Use Your Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'We use the information we collect to:',
            ),
            const Text('• Process and fulfill your orders'),
            const Text('• Communicate with you about your orders'),
            const Text('• Improve our services'),
            const Text('• Comply with legal obligations'),
            const SizedBox(height: 24),
            const Text(
              '3. Information Sharing',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'We do not sell your personal information. We may share your information with:',
            ),
            const Text('• Service providers who assist us in operating our business'),
            const Text('• Law enforcement when required by law'),
            const SizedBox(height: 24),
            const Text(
              '4. Your Rights',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'You have the right to:',
            ),
            const Text('• Access your personal information'),
            const Text('• Correct inaccurate information'),
            const Text('• Request deletion of your information'),
            const Text('• Opt-out of marketing communications'),
          ],
        ),
      ),
    );
  }
}

