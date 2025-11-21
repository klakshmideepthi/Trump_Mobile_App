import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../providers/user_registration_view_model.dart';
import '../../providers/navigation_state.dart';
import '../../services/firebase_order_manager.dart';
import '../../services/vcare_api_manager.dart';
import '../../widgets/step_navigation_container.dart';
import '../../widgets/order_step_header.dart';
import '../../utils/theme.dart';
import '../../utils/formatters.dart';

class NumberSelectionView extends StatefulWidget {
  final int currentStep;
  final Function(int) onStepChanged;

  const NumberSelectionView({
    super.key,
    required this.currentStep,
    required this.onStepChanged,
  });

  @override
  State<NumberSelectionView> createState() => _NumberSelectionViewState();
}

class _NumberSelectionViewState extends State<NumberSelectionView> {
  String? _selectedNumberType;
  bool _isSaving = false;
  final _phoneNumberController = TextEditingController();
  
  // Port-in validation state
  bool _isValidatingPortIn = false;
  String? _portInValidationStatus;
  String? _portInValidationError;
  bool _hasValidatedPortIn = false;
  String? _carrierFromOrder;
  Timer? _validationDebounceTimer;
  int _phoneDigitsCount = 0; // Track phone number digit count

  @override
  void initState() {
    super.initState();
    _loadData();
    // Add listener to track controller text changes
    _phoneNumberController.addListener(_updatePhoneDigitsCount);
  }

  void _updatePhoneDigitsCount() {
    final text = _phoneNumberController.text;
    final digits = text.replaceAll(RegExp(r'[^\d]'), '');
    final newCount = digits.length;
    if (_phoneDigitsCount != newCount) {
      print('📱 Phone Controller Text Changed: "$text" -> digits: "$digits" (${newCount} digits)');
      final oldCount = _phoneDigitsCount;
      setState(() {
        _phoneDigitsCount = newCount;
      });
      
      // If we just reached 10 digits and carrier is available, trigger validation
      if (newCount == 10 && oldCount != 10 && _carrierFromOrder != null && !_isValidatingPortIn) {
        print('✅ Phone number reached 10 digits, carrier available, triggering validation...');
        // Use a small delay to ensure state is updated
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _phoneDigitsCount == 10 && _carrierFromOrder != null && !_isValidatingPortIn) {
            _validatePortIn();
          }
        });
      }
    }
  }

  void _loadData() {
    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    if (viewModel.numberType.isNotEmpty) {
      _selectedNumberType = viewModel.numberType;
    }
    if (viewModel.selectedPhoneNumber.isNotEmpty) {
      _phoneNumberController.text = viewModel.selectedPhoneNumber;
      // Update phone digits count
      _phoneDigitsCount = _phoneNumberController.text.replaceAll(RegExp(r'[^\d]'), '').length;
    }
    
    // Get carrier from order when view appears (only if Existing is selected)
    if (_selectedNumberType == 'Existing') {
      _getCarrierFromOrder().then((carrier) {
        if (mounted) {
          setState(() {
            _carrierFromOrder = carrier;
            // If phone number is already entered, trigger validation
            if (_phoneDigitsCount == 10 && carrier != null) {
              _validatePortIn();
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _phoneNumberController.removeListener(_updatePhoneDigitsCount);
    _phoneNumberController.dispose();
    _validationDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleNext() async {
    if (_selectedNumberType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a number type')),
      );
      return;
    }

    // If Existing is selected, require phone number and validation
    if (_selectedNumberType == 'Existing') {
      final phoneNumber = _phoneNumberController.text.replaceAll(RegExp(r'[^\d]'), '');
      if (phoneNumber.length != 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid 10-digit phone number')),
        );
        return;
      }

      // Require validation to be completed and successful
      if (_isValidatingPortIn || !_hasValidatedPortIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please wait for phone number validation to complete')),
        );
        return;
      }

      // Check if validation was successful (status should be "Eligible")
      if (_portInValidationStatus != 'Eligible') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_portInValidationError ?? 'Number is not eligible for porting'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    viewModel.numberType = _selectedNumberType!;

    if (_selectedNumberType == 'Existing') {
      // Save phone number for porting (porting details will be collected on Step 6)
      final phoneNumber = _phoneNumberController.text.replaceAll(RegExp(r'[^\d]'), '');
      viewModel.selectedPhoneNumber = phoneNumber;
    } else if (_selectedNumberType == 'New') {
      // Generate or select a new number
      viewModel.selectedPhoneNumber = '555-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    }

    final success = await viewModel.saveNumberSelection();
    
    // Save step progress to Firestore (matching TrumpMobile behavior)
    if (success && viewModel.userId != null && viewModel.orderId != null) {
      final orderManager = FirebaseOrderManager();
      await orderManager.saveStepProgress(
        userId: viewModel.userId!,
        orderId: viewModel.orderId!,
        step: 4,
      );
    }
    
    setState(() {
      _isSaving = false;
    });

    if (success && mounted) {
      widget.onStepChanged(5);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? 'Failed to save number selection'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<String?> _getCarrierFromOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ _getCarrierFromOrder: No user ID');
      return null;
    }

    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    final orderId = viewModel.orderId;
    print('🔍 _getCarrierFromOrder: userId=${user.uid}, orderId=$orderId');

    try {
      final db = FirebaseFirestore.instance;
      DocumentSnapshot? orderDoc;

      if (orderId != null) {
        orderDoc = await db
            .collection('users')
            .doc(user.uid)
            .collection('orders')
            .doc(orderId)
            .get();
      } else {
        // Fallback: get any pending order
        final querySnapshot = await db
            .collection('users')
            .doc(user.uid)
            .collection('orders')
            .where('status', isEqualTo: 'pending')
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          orderDoc = querySnapshot.docs.first;
        }
      }

      if (orderDoc == null || !orderDoc.exists) {
        print('⚠️ Order document not found');
        return null;
      }

      final orderData = orderDoc.data() as Map<String, dynamic>?;
      final planId = orderData?['plan_id'];
      if (planId == null) {
        print('⚠️ Order document missing plan_id. Data: $orderData');
        return null;
      }

      print('✅ Found plan_id in order: $planId');
      // Get carrier from plan
      return await _getCarrierFromPlanId(planId);
    } catch (e) {
      print('❌ Error getting carrier from order: $e');
      return null;
    }
  }

  Future<String?> _getCarrierFromPlanId(dynamic planId) async {
    print('🔍 _getCarrierFromPlanId: Searching for plan_id=$planId');
    try {
      final db = FirebaseFirestore.instance;
      final plansSnapshot = await db.collection('plans').get();

      if (plansSnapshot.docs.isEmpty) {
        print('⚠️ No plan documents found');
        return null;
      }

      print('📋 Found ${plansSnapshot.docs.length} plan documents');
      // Search through all plan documents
      for (var doc in plansSnapshot.docs) {
        final data = doc.data();
        if (data['plans'] is List) {
          final plans = data['plans'] as List;
          for (var plan in plans) {
            if (plan is Map) {
              final planIdFromDoc = plan['plan_id'];
              // Handle both int and String plan_id
              final planIdInt = planId is int ? planId : (planId is String ? int.tryParse(planId) : null);
              final planIdFromDocInt = planIdFromDoc is int ? planIdFromDoc : (planIdFromDoc is String ? int.tryParse(planIdFromDoc) : null);
              
              if (planIdInt != null && planIdFromDocInt != null && planIdInt == planIdFromDocInt) {
                if (plan['carrier'] is List && (plan['carrier'] as List).isNotEmpty) {
                  final carrier = (plan['carrier'] as List).first as String;
                  print('✅ Found carrier for plan_id $planId: $carrier');
                  return carrier;
                }
              }
            }
          }
        }
      }

      print('⚠️ No carrier found for plan_id: $planId');
      return null;
    } catch (e) {
      print('❌ Error getting carrier from plan: $e');
      return null;
    }
  }

  Future<void> _validatePortIn() async {
    // Don't validate if already validating or if required fields are missing
    if (_isValidatingPortIn) {
      print('⚠️ Cannot validate: already validating');
      return;
    }

    final phoneNumber = _phoneNumberController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (phoneNumber.isEmpty || phoneNumber.length != 10) {
      print('⚠️ Cannot validate: phoneNumber=$phoneNumber, count=${phoneNumber.length}');
      return;
    }

    if (_carrierFromOrder == null) {
      print('⚠️ Cannot validate: carrier is nil. Attempting to fetch carrier from order...');
      // Try to get carrier if we don't have it yet
      final carrier = await _getCarrierFromOrder();
      if (mounted) {
        setState(() {
          _carrierFromOrder = carrier;
        });
        if (carrier != null) {
          print('✅ Carrier fetched: $carrier');
          // Retry validation
          await _validatePortIn();
        } else {
          print('❌ Failed to fetch carrier from order');
          setState(() {
            _portInValidationError = 'Unable to determine carrier. Please ensure you have selected a plan.';
            _hasValidatedPortIn = false;
          });
        }
      }
      return;
    }

    print('🔄 ========================================');
    print('🔄 PORT-IN VALIDATION STARTING');
    print('🔄 ========================================');
    print('📱 Phone Number: $phoneNumber');
    print('📡 Carrier: $_carrierFromOrder');
    
    // Get zip code (required for AT&T, use user's saved zip)
    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    final zipCode = viewModel.zip.isEmpty ? null : viewModel.zip;
    print('📦 Zip Code: ${zipCode ?? "NOT PROVIDED"}');
    print('🔄 ========================================');

    // Reset previous validation
    if (mounted) {
      setState(() {
        _hasValidatedPortIn = false;
        _portInValidationStatus = null;
        _portInValidationError = null;
        _isValidatingPortIn = true;
      });
    }

    try {
      // Call the API with carrier from order
      final apiManager = VCareAPIManager();
      print('📡 Calling VCareAPIManager.validatePortIn()...');
      print('   Parameters:');
      print('     mdn: $phoneNumber');
      print('     carrier: $_carrierFromOrder');
      print('     zipCode: ${zipCode ?? "null"}');
      print('     agentId: Sushil');
      print('     source: WEBSITE');
      
      print('⏳ Starting API call with 30 second timeout...');
      final validationData = await apiManager.validatePortIn(
        mdn: phoneNumber,
        carrier: _carrierFromOrder!,
        zipCode: zipCode,
        agentId: 'Sushil', // TODO: Get from user settings or configuration
        source: 'WEBSITE',
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏰ API call timed out after 30 seconds!');
          throw TimeoutException('Port-in validation timed out after 30 seconds');
        },
      );
      print('✅ API call completed successfully');

      print('✅ ========================================');
      print('✅ PORT-IN VALIDATION RESPONSE RECEIVED');
      print('✅ ========================================');
      print('📋 Validation Data:');
      print('   portInStatus: ${validationData.portInStatus ?? "null"}');
      print('   description: ${validationData.description ?? "null"}');
      print('   statusCode: ${validationData.statusCode ?? "null"}');
      print('   mdn: ${validationData.mdn ?? "null"}');
      print('   oldServiceProvider: ${validationData.oldServiceProvider ?? "null"}');
      print('   msg: ${validationData.msg ?? "null"}');
      print('   msgCode: ${validationData.msgCode ?? "null"}');
      print('✅ ========================================');

      if (mounted) {
        setState(() {
          _isValidatingPortIn = false;
          _hasValidatedPortIn = true;
          _portInValidationStatus = validationData.portInStatus ?? validationData.description;
          _portInValidationError = null;

          // Log the result
          if (validationData.portInStatus != null) {
            print('✅ Port-in validation successful: ${validationData.portInStatus}');
            if (validationData.portInStatus == 'Eligible') {
              print('✅ Number is ELIGIBLE for porting');
            } else {
              print('⚠️ Number is NOT eligible. Status: ${validationData.portInStatus}');
              print('⚠️ Description: ${validationData.description ?? "No description provided"}');
            }
          } else {
            print('⚠️ Port-in status is null, using description: ${validationData.description}');
          }
        });
      }
    } catch (e, stackTrace) {
      print('❌ ========================================');
      print('❌ PORT-IN VALIDATION FAILED');
      print('❌ ========================================');
      print('❌ Error: $e');
      print('❌ Stack Trace:');
      print(stackTrace);
      print('❌ ========================================');
      
      // Extract a user-friendly error message
      String errorMessage = e.toString();
      if (errorMessage.contains('serviceArea not found')) {
        errorMessage = 'Service area not found for this zip code and carrier. Please verify your zip code or contact support.';
      } else if (errorMessage.contains('TimeoutException')) {
        errorMessage = 'Validation request timed out. Please check your connection and try again.';
      }
      
      if (mounted) {
        setState(() {
          _isValidatingPortIn = false;
          // Mark as validated even on error, so user knows validation completed
          _hasValidatedPortIn = true;
          _portInValidationStatus = null;
          _portInValidationError = errorMessage;
          print('❌ Port-in validation failed: $errorMessage');
          print('   Validation marked as complete (failed)');
        });
      }
    }
  }

  void _onPhoneNumberChanged(String value) {
    // Remove all non-numeric characters
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    // Limit to 10 digits
    final newPhoneNumber = String.fromCharCodes(digits.runes.take(10));

    // Get current phone number from controller
    final currentDigits = _phoneNumberController.text.replaceAll(RegExp(r'[^\d]'), '');
    
    // Only update if the number actually changed
    if (newPhoneNumber != currentDigits) {
      // Reset validation when phone number changes (only if not currently validating)
      if (!_isValidatingPortIn) {
        setState(() {
          _hasValidatedPortIn = false;
          _portInValidationStatus = null;
          _portInValidationError = null;
        });

        // Cancel previous timer
        _validationDebounceTimer?.cancel();

        // Trigger validation if we have 10 digits
        if (digits.length == 10) {
          // If carrier is not available yet, try to fetch it first
          if (_carrierFromOrder == null) {
            print('⚠️ Carrier not available, fetching carrier from order...');
            _getCarrierFromOrder().then((carrier) {
              if (mounted) {
                setState(() {
                  _carrierFromOrder = carrier;
                });
                // Once carrier is fetched, trigger validation
                if (carrier != null && _phoneDigitsCount == 10) {
                  print('✅ Carrier fetched, triggering validation...');
                  _validatePortIn();
                } else if (carrier == null) {
                  print('❌ Failed to fetch carrier, cannot validate');
                  setState(() {
                    _portInValidationError = 'Unable to determine carrier. Please ensure you have selected a plan.';
                    _hasValidatedPortIn = false;
                  });
                }
              }
            });
          } else {
            // Carrier is available, use Timer to debounce the validation call
            print('⏱️ Setting up debounce timer (300ms) for validation...');
            _validationDebounceTimer = Timer(const Duration(milliseconds: 300), () {
              print('⏱️ Debounce timer fired!');
              final currentDigits = _phoneNumberController.text.replaceAll(RegExp(r'[^\d]'), '');
              print('   Current phone digits: "$currentDigits" (${currentDigits.length} digits)');
              print('   mounted: $mounted');
              print('   _isValidatingPortIn: $_isValidatingPortIn');
              print('   _phoneDigitsCount: $_phoneDigitsCount');
              if (mounted && !_isValidatingPortIn && _phoneDigitsCount == 10) {
                print('✅ Conditions met, calling _validatePortIn()...');
                _validatePortIn();
              } else {
                print('❌ Conditions not met, skipping validation');
                if (!mounted) print('   - Widget not mounted');
                if (_isValidatingPortIn) print('   - Already validating');
                if (_phoneDigitsCount != 10) print('   - Phone digits count is $_phoneDigitsCount, need 10');
              }
            });
          }
        }
      }
    }
  }

  void _handleBack() {
    widget.onStepChanged(3);
  }

  @override
  Widget build(BuildContext context) {
    // Determine if Next button should be disabled
    final controllerText = _phoneNumberController.text;
    final phoneDigitsOnly = controllerText.replaceAll(RegExp(r'[^\d]'), '');
    // Use state variable if available, otherwise calculate from controller
    final phoneDigits = _phoneDigitsCount > 0 ? _phoneDigitsCount : phoneDigitsOnly.length;
    final bool isNextDisabled = _selectedNumberType == null ||
        (_selectedNumberType == 'Existing' && 
         (phoneDigits != 10 ||
          _isValidatingPortIn ||
          !_hasValidatedPortIn ||
          _portInValidationStatus != 'Eligible'));

    // Debug logging for button state
    if (_selectedNumberType == 'Existing') {
      print('🔘 Next Button State Debug:');
      print('   _selectedNumberType: $_selectedNumberType');
      print('   controller.text: "$controllerText"');
      print('   phoneDigitsOnly: "$phoneDigitsOnly"');
      print('   _phoneDigitsCount: $_phoneDigitsCount');
      print('   phoneDigits: $phoneDigits (need 10)');
      print('   _isValidatingPortIn: $_isValidatingPortIn');
      print('   _hasValidatedPortIn: $_hasValidatedPortIn');
      print('   _portInValidationStatus: $_portInValidationStatus (need "Eligible")');
      print('   _carrierFromOrder: $_carrierFromOrder');
      print('   isNextDisabled: $isNextDisabled');
      if (isNextDisabled) {
        if (phoneDigits != 10) {
          print('   ❌ Reason: Phone number is not 10 digits (found $phoneDigits digits)');
        } else if (_isValidatingPortIn) {
          print('   ❌ Reason: Validation is in progress');
        } else if (!_hasValidatedPortIn) {
          print('   ❌ Reason: Validation has not completed yet');
        } else if (_portInValidationStatus != 'Eligible') {
          print('   ❌ Reason: Validation status is "$_portInValidationStatus" (not "Eligible")');
        }
      } else {
        print('   ✅ Button should be enabled');
      }
    }

    return StepNavigationContainer(
      currentStep: widget.currentStep,
      totalSteps: 6,
      nextButtonText: 'Next Step',
      nextButtonAction: _handleNext,
      backButtonAction: _handleBack,
      cancelAction: () {
        // Handle cancel - navigate back to home
        final navigationState = Provider.of<NavigationState>(context, listen: false);
        navigationState.navigateTo(Destination.startNewOrder);
        navigationState.setFooterTab(FooterTab.home);
        navigationState.orderStartStep = null;
        navigationState.currentOrderId = null;
        widget.onStepChanged(0);
      },
      nextButtonDisabled: isNextDisabled,
      isLoading: _isSaving,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          OrderStepHeader(
            title: 'Transfer your existing number or choose a new number',
          ),
          SizedBox(height: AppTheme.spacingSection),
          _buildNumberOption(
            title: 'Transfer Your Existing Number',
            description: 'To transfer your number, you\'ll need your Account Number, Account Name, Account Address, and a Transfer PIN or password from your current carrier. Without a correct PIN/password, your carrier will not release your number. You can usually get the PIN by calling your carrier or via their app. Please have this information ready before tapping Next.',
            value: 'Existing',
          ),
          SizedBox(height: AppTheme.spacingItem),
          _buildNumberOption(
            title: 'Choose a New Number',
            description: 'Get a new phone number',
            value: 'New',
          ),
          // Show explanatory text when Existing is selected
          if (_selectedNumberType == 'Existing') ...[
            SizedBox(height: AppTheme.spacingSection),
            _buildBulletPoint(
              'To transfer your number, you\'ll need your Account Number, Account Name, Account Address, and a Transfer PIN or password from your current carrier. Without a correct PIN/password, your carrier will not release your number. You can usually get the PIN by calling your carrier or via their app. Please have this information ready before tapping Next.',
            ),
            SizedBox(height: AppTheme.spacingSection),
            // Phone number input field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter your existing number:',
                  style: AppTheme.bodyStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppTheme.spacingSmall),
                TextFormField(
                  controller: _phoneNumberController,
                  decoration: AppTheme.inputDecoration('').copyWith(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _phoneNumberController.text.replaceAll(RegExp(r'[^\d]'), '').length == 10
                            ? AppTheme.accentGold
                            : Colors.grey.shade300,
                        width: _phoneNumberController.text.replaceAll(RegExp(r'[^\d]'), '').length == 10 ? 2 : 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _phoneNumberController.text.replaceAll(RegExp(r'[^\d]'), '').length == 10
                            ? AppTheme.accentGold
                            : Colors.grey.shade300,
                        width: _phoneNumberController.text.replaceAll(RegExp(r'[^\d]'), '').length == 10 ? 2 : 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.accentGold,
                        width: 2,
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [PhoneNumberFormatter()],
                  onChanged: _onPhoneNumberChanged,
                ),
                SizedBox(height: AppTheme.spacingSmall),
                // Validation status indicator
                if (_isValidatingPortIn)
                  Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Validating phone number...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  )
                else if (_portInValidationStatus != null)
                  Row(
                    children: [
                      Icon(
                        _portInValidationStatus == 'Eligible'
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: _portInValidationStatus == 'Eligible'
                            ? Colors.green
                            : Colors.red,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _portInValidationStatus == 'Eligible'
                              ? 'Number is eligible for porting'
                              : 'Number is not eligible for porting',
                          style: TextStyle(
                            fontSize: 14,
                            color: _portInValidationStatus == 'Eligible'
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  )
                else if (_portInValidationError != null)
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _portInValidationError!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                // Show helpful message if button is disabled
                if (_selectedNumberType == 'Existing' && 
                    _phoneDigitsCount == 10 && 
                    !_isValidatingPortIn && 
                    (!_hasValidatedPortIn || _portInValidationStatus != 'Eligible'))
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _hasValidatedPortIn 
                          ? 'Please wait for validation to complete or contact support if the number is not eligible.'
                          : _carrierFromOrder == null
                              ? 'Loading carrier information...'
                              : 'Please wait for phone number validation to complete.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          // REMOVED: Device selection for new numbers - this should be on Step 6
        ],
      ),
    );
  }

  Widget _buildNumberOption({
    required String title,
    required String description,
    required String value,
  }) {
    final isSelected = _selectedNumberType == value;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedNumberType = value;
          // Get carrier from order when Existing is selected
          if (value == 'Existing') {
            _getCarrierFromOrder().then((carrier) {
              if (mounted) {
                setState(() {
                  _carrierFromOrder = carrier;
                  // If phone number is already entered, trigger validation
                  if (_phoneNumberController.text.replaceAll(RegExp(r'[^\d]'), '').length == 10 && carrier != null) {
                    _validatePortIn();
                  }
                });
              }
            });
          }
        });
      },
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusOption),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 24.0,
          vertical: 16.0,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.accentGold,
            width: AppTheme.borderWidthSelected,
          ),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusOption),
          gradient: isSelected ? AppTheme.blueGradient : null,
          color: isSelected ? null : AppTheme.appBackground,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : AppTheme.appText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '•',
          style: TextStyle(
            color: AppTheme.warningColor,
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: AppTheme.spacingSmall),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15.0,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

