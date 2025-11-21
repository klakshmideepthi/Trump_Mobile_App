import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_registration_view_model.dart';
import '../../services/vcare_api_manager.dart';
import '../../services/firebase_manager.dart';
import '../../models/plan_model.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/plan_card.dart';
import '../../widgets/plan_details_sheet.dart';
import '../../utils/constants.dart';
import '../../providers/navigation_state.dart';
import '../../screens/profile/hamburger_menu_view.dart';
import 'address_info_sheet.dart';

// Body-only version for MainLayout
class PlansViewBody extends StatefulWidget {
  const PlansViewBody({super.key});

  @override
  State<PlansViewBody> createState() => _PlansViewBodyState();
}

class _PlansViewBodyState extends State<PlansViewBody> {
  final VCareAPIManager _apiManager = VCareAPIManager();
  final FirebaseManager _firebaseManager = FirebaseManager();
  
  List<Plan> _availablePlans = [];
  bool _isLoadingPlans = false;
  String _currentZipCode = '';

  @override
  void initState() {
    super.initState();
    _loadAddressInfo();
    // Set footer tab to plans when this view loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigationState = Provider.of<NavigationState>(context, listen: false);
      navigationState.setFooterTab(FooterTab.plans);
    });
  }

  Future<void> _loadAddressInfo() async {
    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    await viewModel.loadUserData();
    
    final previousZipCode = _currentZipCode;
    final newZipCode = viewModel.zip.isNotEmpty ? viewModel.zip : AppConstants.defaultZipCode;
    
    setState(() {
      _currentZipCode = newZipCode;
    });
    
    // Reload plans if ZIP code changed
    // This will check Firestore first, and if plans don't exist for the new zip code,
    // it will fetch from API and save to Firestore
    if (previousZipCode != newZipCode && newZipCode.isNotEmpty) {
      print('📍 ZIP code changed from $previousZipCode to $newZipCode - reloading plans');
      await _loadPlans();
    } else if (previousZipCode.isEmpty) {
      // Initial load
      await _loadPlans();
    }
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoadingPlans = true;
    });

    try {
      // Use default zip code if current is empty
      final zipCodeToUse = _currentZipCode.isNotEmpty 
          ? _currentZipCode 
          : AppConstants.defaultZipCode;
      
      const enrollmentType = 'NON_LIFELINE';
      const isFamilyPlan = 'N';
      
      // First, try to get plans from Firestore
      final cachedPlansData = await _firebaseManager.getPlans(
        zipCode: zipCodeToUse,
        enrollmentType: enrollmentType,
        isFamilyPlan: isFamilyPlan,
      );
      
      if (cachedPlansData != null && cachedPlansData.isNotEmpty) {
        // Plans found in Firestore, use them
        final cachedPlans = cachedPlansData
            .map((planData) => Plan.fromJson(planData))
            .toList();
        
        if (!mounted) return;
        setState(() {
          _availablePlans = cachedPlans;
          _isLoadingPlans = false;
        });
        print('✅ Loaded ${cachedPlans.length} plans from Firestore for zip code: $zipCodeToUse');
        return;
      }
      
      // Plans not in Firestore, fetch from API
      print('📡 Plans not found in Firestore, fetching from API for zip code: $zipCodeToUse');
      final plans = await _apiManager.getPlanList(zipCode: zipCodeToUse);
      
      if (!mounted) return;
      setState(() {
        _availablePlans = plans;
        _isLoadingPlans = false;
      });
      
      // Save plans to Firestore for future use
      if (plans.isNotEmpty) {
        try {
          // Convert plans to JSON-compatible format
          final plansData = plans.map((plan) {
            return {
              'plan_id': plan.planId,
              'plan_name': plan.planName,
              'plan_price': plan.planPrice,
              'total_plan_price': plan.totalPlanPrice,
              'plan_description': plan.planDescription,
              'display_name': plan.displayName,
              'display_description': plan.displayDescription,
              'display_features_description': plan.displayFeaturesDescription,
              'data': plan.data,
              'talk': plan.talk,
              'text': plan.text,
              'is_unlimited_plan': plan.isUnlimitedPlan,
              'is_familyplan': plan.isFamilyPlan,
              'is_prepaid_postpaid': plan.isPrepaidPostpaid,
              'plan_expiry_days': plan.planExpiryDays,
              'plan_expiry_type': plan.planExpiryType,
              'carrier': plan.carrier,
              'plan_discount_details': plan.planDiscountDetails,
              'autopay_discount': plan.autopayDiscount,
            };
          }).toList();
          
          await _firebaseManager.savePlans(
            zipCode: zipCodeToUse,
            enrollmentType: enrollmentType,
            isFamilyPlan: isFamilyPlan,
            plans: plansData,
          );
          print('✅ Plans saved to Firestore for zip code: $zipCodeToUse');
        } catch (e) {
          print('⚠️ Failed to save plans to Firestore: $e');
        }
      }
      
      print('✅ Loaded ${plans.length} plans from API for zip code: $zipCodeToUse');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingPlans = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading plans: $e')),
        );
      }
    }
  }

  void _showPlanDetails(Plan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlanDetailsSheet(
        plan: plan,
        onStartOrder: () {
          Navigator.of(context).pop();
          // Navigate to home to start order
          final navigationState = Provider.of<NavigationState>(context, listen: false);
          navigationState.setFooterTab(FooterTab.home);
          navigationState.navigateTo(Destination.startNewOrder);
        },
        onClose: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoadingPlans
        ? const Center(child: CircularProgressIndicator())
        : _availablePlans.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No plans available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No plans found for ZIP: ${_currentZipCode.isEmpty ? AppConstants.defaultZipCode : _currentZipCode}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadPlans,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _availablePlans.length,
                itemBuilder: (context, index) {
                  final plan = _availablePlans[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: PlanCard(
                      plan: plan,
                      isSelected: false,
                      showUnlimited: index < 5,
                      onTap: () => _showPlanDetails(plan),
                    ),
                  );
                },
              );
  }
}

class PlansView extends StatefulWidget {
  const PlansView({super.key});

  @override
  State<PlansView> createState() => _PlansViewState();
}

class _PlansViewState extends State<PlansView> {
  final VCareAPIManager _apiManager = VCareAPIManager();
  final FirebaseManager _firebaseManager = FirebaseManager();
  
  List<Plan> _availablePlans = [];
  bool _isLoadingPlans = false;
  String _currentZipCode = '';

  @override
  void initState() {
    super.initState();
    _loadAddressInfo();
    // Set footer tab to plans when this view loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigationState = Provider.of<NavigationState>(context, listen: false);
      navigationState.setFooterTab(FooterTab.plans);
    });
  }

  void _showHamburgerMenu(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.75,
              height: MediaQuery.of(context).size.height,
              color: Colors.white,
              child: const HamburgerMenuView(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadAddressInfo() async {
    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    await viewModel.loadUserData();
    
    final previousZipCode = _currentZipCode;
    final newZipCode = viewModel.zip.isNotEmpty ? viewModel.zip : AppConstants.defaultZipCode;
    
    setState(() {
      _currentZipCode = newZipCode;
    });
    
    // Reload plans if ZIP code changed
    // This will check Firestore first, and if plans don't exist for the new zip code,
    // it will fetch from API and save to Firestore
    if (previousZipCode != newZipCode && newZipCode.isNotEmpty) {
      print('📍 ZIP code changed from $previousZipCode to $newZipCode - reloading plans');
      await _loadPlans();
    } else if (previousZipCode.isEmpty) {
      // Initial load
      await _loadPlans();
    }
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoadingPlans = true;
    });

    try {
      // Use default zip code if current is empty
      final zipCodeToUse = _currentZipCode.isNotEmpty 
          ? _currentZipCode 
          : AppConstants.defaultZipCode;
      
      const enrollmentType = 'NON_LIFELINE';
      const isFamilyPlan = 'N';
      
      // First, try to get plans from Firestore
      final cachedPlansData = await _firebaseManager.getPlans(
        zipCode: zipCodeToUse,
        enrollmentType: enrollmentType,
        isFamilyPlan: isFamilyPlan,
      );
      
      if (cachedPlansData != null && cachedPlansData.isNotEmpty) {
        // Plans found in Firestore, use them
        final cachedPlans = cachedPlansData
            .map((planData) => Plan.fromJson(planData))
            .toList();
        
        if (!mounted) return;
        setState(() {
          _availablePlans = cachedPlans;
          _isLoadingPlans = false;
        });
        print('✅ Loaded ${cachedPlans.length} plans from Firestore for zip code: $zipCodeToUse');
        return;
      }
      
      // Plans not in Firestore, fetch from API
      print('📡 Plans not found in Firestore, fetching from API for zip code: $zipCodeToUse');
      final plans = await _apiManager.getPlanList(zipCode: zipCodeToUse);
      
      if (!mounted) return;
      setState(() {
        _availablePlans = plans;
        _isLoadingPlans = false;
      });
      
      // Save plans to Firestore for future use
      if (plans.isNotEmpty) {
        try {
          // Convert plans to JSON-compatible format
          final plansData = plans.map((plan) {
            return {
              'plan_id': plan.planId,
              'plan_name': plan.planName,
              'plan_price': plan.planPrice,
              'total_plan_price': plan.totalPlanPrice,
              'plan_description': plan.planDescription,
              'display_name': plan.displayName,
              'display_description': plan.displayDescription,
              'display_features_description': plan.displayFeaturesDescription,
              'data': plan.data,
              'talk': plan.talk,
              'text': plan.text,
              'is_unlimited_plan': plan.isUnlimitedPlan,
              'is_familyplan': plan.isFamilyPlan,
              'is_prepaid_postpaid': plan.isPrepaidPostpaid,
              'plan_expiry_days': plan.planExpiryDays,
              'plan_expiry_type': plan.planExpiryType,
              'carrier': plan.carrier,
              'plan_discount_details': plan.planDiscountDetails,
              'autopay_discount': plan.autopayDiscount,
            };
          }).toList();
          
          await _firebaseManager.savePlans(
            zipCode: zipCodeToUse,
            enrollmentType: enrollmentType,
            isFamilyPlan: isFamilyPlan,
            plans: plansData,
          );
          print('✅ Plans saved to Firestore for zip code: $zipCodeToUse');
        } catch (e) {
          print('⚠️ Failed to save plans to Firestore: $e');
        }
      }
      
      print('✅ Loaded ${plans.length} plans from API for zip code: $zipCodeToUse');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingPlans = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading plans: $e')),
        );
      }
    }
  }

  void _showPlanDetails(Plan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlanDetailsSheet(
        plan: plan,
        onStartOrder: () {
          Navigator.of(context).pop();
          // Navigate to home to start order
          final navigationState = Provider.of<NavigationState>(context, listen: false);
          navigationState.setFooterTab(FooterTab.home);
          navigationState.navigateTo(Destination.startNewOrder);
        },
        onClose: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              zipCode: _currentZipCode.isNotEmpty ? _currentZipCode : null,
              onZipCodeTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => const AddressInfoSheet(),
                ).then((_) {
                  // Reload address info when sheet is dismissed
                  _loadAddressInfo();
                });
              },
              onMenuTap: () {
                _showHamburgerMenu(context);
              },
            ),
            Expanded(
              child: _isLoadingPlans
                  ? const Center(child: CircularProgressIndicator())
                  : _availablePlans.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No plans available',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No plans found for ZIP: ${_currentZipCode.isEmpty ? AppConstants.defaultZipCode : _currentZipCode}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _loadPlans,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _availablePlans.length,
                          itemBuilder: (context, index) {
                            final plan = _availablePlans[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: PlanCard(
                                plan: plan,
                                isSelected: false,
                                showUnlimited: index < 5,
                                onTap: () => _showPlanDetails(plan),
                              ),
                            );
                          },
                        ),
            ),
            Consumer<NavigationState>(
              builder: (context, navigationState, _) {
                return AppFooter(
                  currentTab: navigationState.currentFooterTab,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

