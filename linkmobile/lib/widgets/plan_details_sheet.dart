import 'package:flutter/material.dart';
import '../models/plan_model.dart';
import '../utils/theme.dart';
import 'gradient_button.dart';

class PlanDetailsSheet extends StatelessWidget {
  final Plan plan;
  final VoidCallback onStartOrder;
  final VoidCallback onClose;

  const PlanDetailsSheet({
    super.key,
    required this.plan,
    required this.onStartOrder,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header with close button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Plan Details',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onClose,
                    ),
                  ],
                ),
              ),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Plan Title/Badge - Large bold text at top
                      if (plan.displayName != null && plan.displayName!.isNotEmpty)
                        Text(
                          plan.displayName!,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                        ),
                      const SizedBox(height: 16),
                      
                      // Price - Large blue text
                      Text(
                        '\$${plan.totalPlanPrice}/mo.',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.mainBlue,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Data description
                      Text(
                        _buildDescription(plan),
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Features list with yellow bullets
                      ..._buildFeaturesList(plan),
                      
                      const SizedBox(height: 32),
                      // Select Button (inside scrollable area but with padding)
                      Container(
                        padding: const EdgeInsets.only(bottom: 16),
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onStartOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Select',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Build description text (e.g., "1GB, Light users")
  String _buildDescription(Plan plan) {
    final data = _formatData(plan.data);
    final displayName = plan.displayName ?? '';
    
    // Custom descriptions based on plan name matching web format
    if (displayName.contains('STARTER')) {
      return '1GB, Light users';
    } else if (displayName.contains('EXPLORE')) {
      return '5 GB, Everyday use + international perks';
    } else if (displayName.contains('PREMIUM')) {
      return '12 GB, Streaming & multi-service';
    } else if (displayName.contains('UNLIMITED PLUS')) {
      return '50GB, all the data, all the speed';
    } else if (displayName.contains('UNLIMITED')) {
      return '30GB, Heavy usage and roaming';
    }
    
    return '$data, ${plan.planDescription.isNotEmpty ? plan.planDescription : "High-speed data"}';
  }
  
  // Build features list with yellow bullets (matching web format exactly)
  List<Widget> _buildFeaturesList(Plan plan) {
    final features = <Widget>[];
    final displayName = plan.displayName ?? '';
    final dataText = _formatData(plan.data);
    
    // Build features based on plan type to match web exactly
    if (displayName.contains('STARTER')) {
      // STARTER plan features
      features.add(_buildFeatureBullet('Unlimited Talk & Text (USA, Canada, Mexico)'));
      features.add(_buildFeatureBullet('1 GB high-speed data (5G/4G LTE)'));
      features.add(_buildFeatureBullet('Perfect for light data use'));
      features.add(_buildFeatureBullet('Affordable/Flexible data add-ons'));
      features.add(_buildFeatureBullet('Global Roaming via "Wifi - Calling"'));
    } else if (displayName.contains('EXPLORE')) {
      // EXPLORE plan features
      features.add(_buildFeatureBullet('Unlimited Talk & Text (USA, Canada, Mexico)'));
      features.add(_buildFeatureBullet('5 GB high-speed data'));
      features.add(_buildFeatureBullet('Affordable/Flexible data add-ons'));
      features.add(_buildFeatureBullet('Free Roaming in Mexico & Canada'));
      features.add(_buildFeatureBullet('Global Roaming via "Wifi - Calling"'));
    } else if (displayName.contains('PREMIUM')) {
      // PREMIUM plan features
      features.add(_buildFeatureBullet('Unlimited Talk & Text (USA, Canada, Mexico)'));
      features.add(_buildFeatureBullet('12 GB high-speed data'));
      features.add(_buildFeatureBullet('100+ International Calling Destinations'));
      features.add(_buildFeatureBullet('Free Roaming in Mexico & Canada'));
      features.add(_buildFeatureBullet('Global Roaming via "Wifi - Calling"'));
    } else if (displayName.contains('UNLIMITED PLUS')) {
      // UNLIMITED PLUS plan features
      features.add(_buildFeatureBullet('Unlimited data (50GB High-speed, then reduced)'));
      features.add(_buildFeatureBullet('Unlimited Talk & Text (USA, Canada, Mexico)'));
      features.add(_buildFeatureBullet('100+ International Calling Destinations'));
      features.add(_buildFeatureBullet('Free Roaming in Mexico & Canada'));
      features.add(_buildFeatureBullet('Global Roaming via "Wifi - Calling"'));
    } else if (displayName.contains('UNLIMITED')) {
      // UNLIMITED plan features
      features.add(_buildFeatureBullet('Unlimited data (30GB High-speed, then reduced)'));
      features.add(_buildFeatureBullet('30 GB high-speed data'));
      features.add(_buildFeatureBullet('100+ International Calling Destinations'));
      features.add(_buildFeatureBullet('Free Roaming in Mexico & Canada'));
      features.add(_buildFeatureBullet('Global Roaming via "Wifi - Calling"'));
    } else {
      // Fallback: Use displayFeaturesDescription if available
      if (plan.displayFeaturesDescription.isNotEmpty) {
        for (var feature in plan.displayFeaturesDescription) {
          features.add(_buildFeatureBullet(feature));
        }
      } else {
        // Generic fallback based on plan data
        if ((plan.talk >= 9999000 || plan.talk == 0) && (plan.text >= 9999000 || plan.text == 0)) {
          features.add(_buildFeatureBullet('Unlimited Talk & Text (USA, Canada, Mexico)'));
        }
        
        if (plan.data >= 1000) {
          if (plan.isUnlimitedPlan == 'Y') {
            features.add(_buildFeatureBullet('Unlimited data ($dataText High-speed, then reduced)'));
            features.add(_buildFeatureBullet('$dataText high-speed data'));
          } else {
            features.add(_buildFeatureBullet('$dataText high-speed data'));
          }
        }
        
        features.add(_buildFeatureBullet('Affordable/Flexible data add-ons'));
        
        if (plan.totalPlanPrice >= 30) {
          features.add(_buildFeatureBullet('100+ International Calling Destinations'));
        }
        
        if (plan.totalPlanPrice >= 20) {
          features.add(_buildFeatureBullet('Free Roaming in Mexico & Canada'));
        }
        
        features.add(_buildFeatureBullet('Global Roaming via "Wifi - Calling"'));
      }
    }
    
    return features;
  }
  
  Widget _buildFeatureBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: AppTheme.yellowAccent, // Yellow/Gold bullet
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatData(int mb) {
    if (mb >= 999999999) {
      return 'Unlimited';
    }
    if (mb >= 1000) {
      final gigabytes = (mb / 1000.0).round();
      return '$gigabytes GB';
    }
    return '$mb MB';
  }

  String _formatTalk(int minutes) {
    // Check if value is extremely large (9999K or higher should show as unlimited)
    // Also check if 0 means unlimited
    if (minutes >= 9999000 || minutes == 0) {
      return 'Unlimited';
    }
    if (minutes >= 1000) {
      return '${minutes ~/ 1000}K minutes';
    }
    return '$minutes minutes';
  }

  String _formatText(int messages) {
    // Check if value is extremely large (9999K or higher should show as unlimited)
    // Also check if 0 means unlimited
    if (messages >= 9999000 || messages == 0) {
      return 'Unlimited';
    }
    if (messages >= 1000) {
      return '${messages ~/ 1000}K messages';
    }
    return '$messages messages';
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}

