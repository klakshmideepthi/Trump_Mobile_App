import 'package:flutter/material.dart';
import '../utils/theme.dart';

class OrderStepHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const OrderStepHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 18.0, // Reduced heading size
            fontWeight: FontWeight.bold,
            color: AppTheme.appText,
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 8.0),
          Text(
            subtitle!.toUpperCase(),
            style: const TextStyle(
              fontSize: 14.0, // subheadline size
              fontWeight: FontWeight.normal,
              color: AppTheme.appText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

