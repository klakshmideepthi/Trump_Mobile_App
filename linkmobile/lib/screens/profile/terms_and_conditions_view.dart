import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class TermsAndConditionsView extends StatelessWidget {
  const TermsAndConditionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
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
              '1. Acceptance of Terms',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'By using our service, you agree to be bound by these Terms and Conditions.',
            ),
            const SizedBox(height: 24),
            const Text(
              '2. Service Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'We provide mobile phone plans and SIM card services. Plans are subject to availability and may vary by location.',
            ),
            const SizedBox(height: 24),
            const Text(
              '3. Account Registration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'You are responsible for maintaining the confidentiality of your account credentials.',
            ),
            const SizedBox(height: 24),
            const Text(
              '4. Payment Terms',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Payment is required at the time of order. All prices are in USD and subject to applicable taxes.',
            ),
            const SizedBox(height: 24),
            const Text(
              '5. Cancellation Policy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'You may cancel your order before activation. Refunds are subject to our refund policy.',
            ),
            const SizedBox(height: 24),
            const Text(
              '6. Limitation of Liability',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'We are not liable for any indirect, incidental, or consequential damages arising from the use of our service.',
            ),
          ],
        ),
      ),
    );
  }
}

