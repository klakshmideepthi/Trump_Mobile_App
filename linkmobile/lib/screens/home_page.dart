import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_header.dart';
import '../models/plan_model.dart';
import '../widgets/plan_carousel.dart';
import 'login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Hardcoded matched plans - only these 5 are visible
  List<Plan> _getHardcodedPlans() {
    return [
      Plan(
        planId: 25,
        planName: 'STARTER',
        planPrice: 10,
        totalPlanPrice: 10,
        planDescription: 'Perfect for light users',
        displayName: 'STARTER',
        displayDescription: '1GB High-Speed Data',
        displayFeaturesDescription: ['1GB Data', 'Unlimited Talk & Text'],
        data: 1024, // 1GB in MB
        talk: 0, // Unlimited
        text: 0, // Unlimited
        isUnlimitedPlan: 'N',
        isFamilyPlan: 'N',
        isPrepaidPostpaid: 'prepaid',
        planExpiryDays: 30,
        planExpiryType: 'MONTHLY',
        carrier: ['LINKUP'],
        planDiscountDetails: [],
        autopayDiscount: 'N',
      ),
      Plan(
        planId: 85,
        planName: 'EXPLORE',
        planPrice: 20,
        totalPlanPrice: 20,
        planDescription: 'Great for browsing and social media',
        displayName: 'EXPLORE',
        displayDescription: '5GB High-Speed Data',
        displayFeaturesDescription: ['5GB Data', 'Unlimited Talk & Text'],
        data: 5120, // 5GB in MB
        talk: 0, // Unlimited
        text: 0, // Unlimited
        isUnlimitedPlan: 'N',
        isFamilyPlan: 'N',
        isPrepaidPostpaid: 'prepaid',
        planExpiryDays: 30,
        planExpiryType: 'MONTHLY',
        carrier: ['LINKUP'],
        planDiscountDetails: [],
        autopayDiscount: 'N',
      ),
      Plan(
        planId: 145,
        planName: 'PREMIUM',
        planPrice: 30,
        totalPlanPrice: 30,
        planDescription: 'Ideal for everyday users',
        displayName: 'PREMIUM',
        displayDescription: '12GB High-Speed Data',
        displayFeaturesDescription: ['12GB Data', 'Unlimited Talk & Text'],
        data: 12288, // 12GB in MB
        talk: 0, // Unlimited
        text: 0, // Unlimited
        isUnlimitedPlan: 'N',
        isFamilyPlan: 'N',
        isPrepaidPostpaid: 'prepaid',
        planExpiryDays: 30,
        planExpiryType: 'MONTHLY',
        carrier: ['LINKUP'],
        planDiscountDetails: [],
        autopayDiscount: 'N',
      ),
      Plan(
        planId: 205,
        planName: 'UNLIMITED',
        planPrice: 40,
        totalPlanPrice: 40,
        planDescription: 'For power users',
        displayName: 'UNLIMITED',
        displayDescription: '30GB High-Speed Data',
        displayFeaturesDescription: ['30GB Data', 'Unlimited Talk & Text'],
        data: 30720, // 30GB in MB
        talk: 0, // Unlimited
        text: 0, // Unlimited
        isUnlimitedPlan: 'N',
        isFamilyPlan: 'N',
        isPrepaidPostpaid: 'prepaid',
        planExpiryDays: 30,
        planExpiryType: 'MONTHLY',
        carrier: ['LINKUP'],
        planDiscountDetails: [],
        autopayDiscount: 'N',
      ),
      Plan(
        planId: 265,
        planName: 'UNLIMITED PLUS',
        planPrice: 50,
        totalPlanPrice: 50,
        planDescription: 'Ultimate unlimited experience',
        displayName: 'UNLIMITED PLUS',
        displayDescription: '50GB High-Speed + Unlimited',
        displayFeaturesDescription: ['50GB High-Speed Data', 'Unlimited Everything'],
        data: 51200, // 50GB in MB
        talk: 0, // Unlimited
        text: 0, // Unlimited
        isUnlimitedPlan: 'Y',
        isFamilyPlan: 'N',
        isPrepaidPostpaid: 'prepaid',
        planExpiryDays: 30,
        planExpiryType: 'MONTHLY',
        carrier: ['LINKUP'],
        planDiscountDetails: [],
        autopayDiscount: 'N',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final plans = _getHardcodedPlans();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      const Text(
                        'Welcome!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (user != null) ...[
                        Text(
                          'Signed in as: ${user.email ?? user.displayName ?? "User"}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                      const Text(
                        'Our Plans',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Choose the perfect plan for you',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 30),
                      PlanCarousel(
                        plans: plans,
                        autoPlay: true,
                        autoPlayInterval: const Duration(seconds: 5),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Sign Out',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

