import 'package:flutter/material.dart';
import '../models/plan_model.dart';
import '../utils/theme.dart';

class PlanCard extends StatelessWidget {
  final Plan plan;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showSmallPlanName;
  final bool showUnlimited;

  const PlanCard({
    super.key,
    required this.plan,
    this.isSelected = false,
    this.onTap,
    this.showSmallPlanName = false,
    this.showUnlimited = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.mainBlue : Colors.grey[500]!,
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge with display name (STARTER, EXPLORE, etc.)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge
                  if (plan.displayName != null && plan.displayName!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppTheme.blueGradient : null,
                        color: isSelected ? null : AppTheme.secondBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : AppTheme.secondBlue.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        plan.displayName!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppTheme.mainBlue,
                        ),
                      ),
                    ),
                  // Price with /month on same line
                  Text(
                    '\$${plan.totalPlanPrice}/month',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.mainBlue,
                    ),
                  ),
                ],
              ),
              // Plan name - in its own row
              if (plan.displayName != null && plan.displayName!.isNotEmpty)
                const SizedBox(height: 4)
              else
                const SizedBox(height: 0),
              Text(
                plan.planName,
                style: showSmallPlanName
                    ? (Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                        ) ?? const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ))
                    : const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildFeature(
                      icon: Icons.phone,
                      value: _formatCalls(plan.talk, showUnlimited),
                      label: 'Calls',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  Expanded(
                    child: _buildFeature(
                      icon: Icons.message,
                      value: _formatMessages(plan.text, showUnlimited),
                      label: 'Messages',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  Expanded(
                    child: _buildFeature(
                      icon: Icons.signal_wifi_4_bar,
                      value: _formatData(plan.data, showUnlimited),
                      label: 'Data',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Tap to select',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.mainBlue,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: AppTheme.mainBlue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.mainBlue, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.normal,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatCalls(int minutes, bool showUnlimited) {
    // If showUnlimited is true, always return Unlimited
    if (showUnlimited) {
      return 'Unlimited';
    }
    // Original logic: Check if value is extremely large (9999K or higher should show as unlimited)
    if (minutes >= 9999000) {
      return 'Unlimited';
    }
    if (minutes >= 1000) {
      return '${minutes ~/ 1000}K';
    }
    return '$minutes';
  }

  String _formatMessages(int messages, bool showUnlimited) {
    // If showUnlimited is true, always return Unlimited
    if (showUnlimited) {
      return 'Unlimited';
    }
    // Original logic: Check if value is extremely large (9999K or higher should show as unlimited)
    if (messages >= 9999000) {
      return 'Unlimited';
    }
    if (messages >= 1000) {
      return '${messages ~/ 1000}K';
    }
    return '$messages';
  }

  String _formatData(int mb, bool showUnlimited) {
    // If showUnlimited is true, always return Unlimited
    if (showUnlimited) {
      return 'Unlimited';
    }
    // Original logic
    if (mb >= 1000) {
      return '${mb ~/ 1000}GB';
    }
    return '${mb}MB';
  }
  
  // Format plan name as "LinkUp ($10/1GB)"
  String _formatPlanName(Plan plan) {
    final price = plan.totalPlanPrice;
    final data = _formatData(plan.data, showUnlimited);
    return 'LinkUp (\$$price/$data)';
  }
}

