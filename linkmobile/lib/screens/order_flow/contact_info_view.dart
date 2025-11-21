import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../providers/user_registration_view_model.dart';
import '../../providers/navigation_state.dart';
import '../../services/firebase_order_manager.dart';
import '../../services/firebase_manager.dart';
import '../../services/vcare_api_manager.dart';
import '../../widgets/step_navigation_container.dart';
import '../../widgets/order_step_header.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../utils/theme.dart';

class ContactInfoView extends StatefulWidget {
  final int currentStep;
  final Function(int) onStepChanged;

  const ContactInfoView({
    super.key,
    required this.currentStep,
    required this.onStepChanged,
  });

  @override
  State<ContactInfoView> createState() => _ContactInfoViewState();
}

class _ContactInfoViewState extends State<ContactInfoView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _aptController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  bool _isSaving = false;
  bool _useCurrentLocation = false;
  bool _isLoadingLocation = false;
  bool _isLoadingCityState = false;
  bool _isValidatingAddress = false;
  USPSAddressData? _suggestedAddress;
  bool _showAddressSuggestion = false;
  bool _showAddressValidationError = false;
  String _addressValidationErrorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    
    // Pre-fill name from Gmail if available
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Try to get display name from Firebase Auth (set by Google Sign-In)
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        final nameParts = user.displayName!.split(' ');
        if (viewModel.firstName.isEmpty && nameParts.isNotEmpty) {
          viewModel.firstName = nameParts.first;
        }
        if (viewModel.lastName.isEmpty && nameParts.length > 1) {
          viewModel.lastName = nameParts.sublist(1).join(' ');
        }
      }
    }
    
    _firstNameController.text = viewModel.firstName;
    _lastNameController.text = viewModel.lastName;
    _phoneController.text = viewModel.phoneNumber;
    _streetController.text = viewModel.street;
    _aptController.text = viewModel.aptNumber;
    _cityController.text = viewModel.city;
    _stateController.text = viewModel.state;
    _zipController.text = viewModel.zip;
    
    // Add listener to ZIP code controller for auto-fill
    _zipController.addListener(_onZipCodeChanged);
  }
  
  void _onZipCodeChanged() {
    final zipCode = _zipController.text.trim();
    if (zipCode.length == 5 && RegExp(r'^\d{5}$').hasMatch(zipCode)) {
      _fetchCityStateFromZip(zipCode);
    }
  }
  
  Future<void> _fetchCityStateFromZip(String zipCode) async {
    if (_isLoadingCityState) return;
    
    setState(() {
      _isLoadingCityState = true;
    });
    
    try {
      final apiManager = VCareAPIManager();
      final result = await apiManager.getCityState(zipCode: zipCode);
      
      setState(() {
        _cityController.text = result.city;
        _stateController.text = result.state;
        _isLoadingCityState = false;
      });
    } catch (e) {
      print('❌ Failed to get city and state from ZIP code: $e');
      setState(() {
        _isLoadingCityState = false;
      });
    }
  }
  
  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _useCurrentLocation = true;
      _isLoadingLocation = true;
    });
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location services are disabled. Please enable them in Settings.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        setState(() {
          _useCurrentLocation = false;
          _isLoadingLocation = false;
        });
        return;
      }
      
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location permissions are denied. Please enable them in Settings.'),
              backgroundColor: AppTheme.errorColor,
              action: SnackBarAction(
                label: 'Open Settings',
                textColor: Colors.white,
                onPressed: () async {
                  await Geolocator.openAppSettings();
                },
              ),
              duration: const Duration(seconds: 5),
            ),
          );
          }
          setState(() {
            _useCurrentLocation = false;
            _isLoadingLocation = false;
          });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location permissions are permanently denied. Please enable them in Settings.'),
              backgroundColor: AppTheme.errorColor,
              action: SnackBarAction(
                label: 'Open Settings',
                textColor: Colors.white,
                onPressed: () async {
                  await Geolocator.openAppSettings();
                },
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        setState(() {
          _useCurrentLocation = false;
          _isLoadingLocation = false;
        });
        return;
      }
      
      Position? position;
      
      // First, try to get last known position (instant, no GPS wait)
      // Accept any last known position regardless of age (for emulator compatibility)
      try {
        Position? lastKnownPosition = await Geolocator.getLastKnownPosition();
        if (lastKnownPosition != null) {
          position = lastKnownPosition;
          final age = DateTime.now().difference(lastKnownPosition.timestamp);
          print('✅ Using last known position (age: ${age.inMinutes} minutes)');
        } else {
          print('⚠️ No last known position available');
        }
      } catch (e) {
        print('⚠️ Could not get last known position: $e');
      }
      
      // Only try fresh location if absolutely necessary and with very short timeout
      if (position == null) {
        print('🔄 Getting fresh location (last known not available)...');
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low, // Low accuracy for fastest response (especially on emulator)
            // Remove timeLimit - let outer timeout handle it to avoid conflicts
            forceAndroidLocationManager: false, // Use Fused Location Provider
          ).timeout(
            const Duration(seconds: 5), // Very short timeout for emulator/device compatibility
            onTimeout: () {
              throw TimeoutException('Unable to get location. Please ensure GPS is enabled or enter address manually.');
            },
          );
        } catch (e) {
          // If fresh location fails, try to use any last known position as fallback
          print('⚠️ Fresh location failed: $e, trying last known position as fallback...');
          try {
            Position? fallbackPosition = await Geolocator.getLastKnownPosition();
            if (fallbackPosition != null) {
              position = fallbackPosition;
              final age = DateTime.now().difference(fallbackPosition.timestamp);
              print('✅ Using last known position as fallback (age: ${age.inMinutes} minutes)');
            } else {
              // No position available at all - gracefully handle this
              throw Exception('Unable to get location. Please enter your address manually.');
            }
          } catch (fallbackError) {
            // Re-throw with user-friendly message
            throw Exception('Unable to get location. Please enter your address manually.');
          }
        }
      }
      
      // If we still don't have a position, show error and return gracefully
      if (position == null) {
        setState(() {
          _useCurrentLocation = false;
          _isLoadingLocation = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Unable to get location. Please enter your address manually.'),
              backgroundColor: AppTheme.errorColor,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }
      
      // Reverse geocode to get address with timeout
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Address lookup timed out. Please try again.');
          },
        );
        
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          setState(() {
            _streetController.text = placemark.street ?? '';
            _aptController.text = placemark.subThoroughfare ?? '';
            _cityController.text = placemark.locality ?? placemark.subAdministrativeArea ?? '';
            _stateController.text = placemark.administrativeArea ?? '';
            _zipController.text = placemark.postalCode ?? '';
            
            // If we have a ZIP code, fetch city and state from API for consistency
            if (_zipController.text.length == 5) {
              _fetchCityStateFromZip(_zipController.text);
            }
            
            _isLoadingLocation = false;
          });
        } else {
          setState(() {
            _isLoadingLocation = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Unable to get address from location. Please enter address manually.'),
                backgroundColor: AppTheme.errorColor,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } catch (e) {
        print('❌ Failed to reverse geocode: $e');
        setState(() {
          _isLoadingLocation = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Unable to get address from location. Please enter address manually.'),
              backgroundColor: AppTheme.errorColor,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Failed to get current location: $e');
      // Always clear loading state and show user-friendly error
      setState(() {
        _useCurrentLocation = false;
        _isLoadingLocation = false;
      });
      if (mounted) {
        String errorMessage = 'Unable to get location. Please enter your address manually.';
        if (e is TimeoutException) {
          errorMessage = 'Unable to get location. Please ensure GPS is enabled or enter address manually.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) {
      print('❌ DEBUG: Form validation failed');
      return;
    }

    // Validate that city and state are filled (they should be auto-filled from ZIP code)
    if (_cityController.text.isEmpty || _stateController.text.isEmpty) {
      print('❌ DEBUG: City or state is empty - City: ${_cityController.text}, State: ${_stateController.text}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please enter a valid ZIP code to auto-fill city and state.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    viewModel.firstName = _firstNameController.text;
    viewModel.lastName = _lastNameController.text;
    viewModel.phoneNumber = _phoneController.text;
    viewModel.street = _streetController.text;
    viewModel.aptNumber = _aptController.text;
    viewModel.city = _cityController.text;
    viewModel.state = _stateController.text;
    viewModel.zip = _zipController.text;

    // Check service availability and validate address (matching Swift implementation)
    if (viewModel.userId != null && viewModel.orderId != null) {
      await _checkServiceAvailabilityAndValidateAddress(
        userId: viewModel.userId!,
        orderId: viewModel.orderId!,
        zipCode: viewModel.zip,
      );
    } else {
      // If no order exists, just save contact info
      await _saveContactInfoAndProceed(viewModel);
    }
  }

  Future<void> _checkServiceAvailabilityAndValidateAddress({
    required String userId,
    required String orderId,
    required String zipCode,
  }) async {
    setState(() {
      _isValidatingAddress = true;
    });

    try {
      print('🔄 Checking service availability for zip code: $zipCode');
      
      // Generate unique transaction ID for this API call
      final transactionId = VCareAPIManager.generateTransactionId(orderId, 'CHECK');
      
      // Step 1: Check service availability to get enrollment_id
      final apiManager = VCareAPIManager();
      final availabilityData = await apiManager.checkServiceAvailability(
        zipCode: zipCode,
        enrollmentType: 'NON_LIFELINE',
        isEnrollment: 'Y',
        agentId: 'Sushil',
        source: 'WEBSITE',
        externalTransactionId: transactionId,
      );

      if (availabilityData.enrollmentId != null) {
        print('✅ Received enrollment_id: ${availabilityData.enrollmentId}');
        
        // Save enrollment_id to Firestore
        final firebaseManager = FirebaseManager();
        await firebaseManager.saveEnrollmentId(
          userId: userId,
          orderId: orderId,
          enrollmentId: availabilityData.enrollmentId!,
        );
        print('✅ Enrollment ID saved to Firestore');

        // Step 2: Validate address with USPS
        await _validateAddressAndProceed(
          userId: userId,
          orderId: orderId,
          enrollmentId: availabilityData.enrollmentId!,
        );
      } else {
        print('⚠️ No enrollment_id in response');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create enrollment. Please try again.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        setState(() {
          _isValidatingAddress = false;
        });
      }
    } catch (e) {
      print('❌ Service availability check failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Service availability check failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      setState(() {
        _isValidatingAddress = false;
      });
    }
  }

  Future<void> _validateAddressAndProceed({
    required String userId,
    required String orderId,
    required String enrollmentId,
  }) async {
    print('🔄 Validating address with USPS...');

    try {
      final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
      final apiManager = VCareAPIManager();
      
      final validatedAddress = await apiManager.validateAddressUSPS(
        enrollmentId: enrollmentId,
        addressOne: viewModel.street,
        addressTwo: viewModel.aptNumber,
        city: viewModel.city,
        state: viewModel.state,
        zipCode: viewModel.zip,
        agentId: 'Sushil',
        source: 'WEBSITE',
      );

      print('✅ Address validated successfully');

      // Check if address was modified/suggested
      final originalAddress = viewModel.street.toUpperCase().trim();
      final validatedAddress1 = (validatedAddress.address1 ?? '').toUpperCase().trim();

      final originalCity = viewModel.city.toUpperCase().trim();
      final validatedCity = (validatedAddress.city ?? '').toUpperCase().trim();

      final originalState = viewModel.state.toUpperCase().trim();
      final validatedState = (validatedAddress.state ?? '').toUpperCase().trim();

      final originalZip = viewModel.zip.trim();
      final validatedZip = validatedAddress.zip5 ?? '';

      // Check if address differs from user input
      if (originalAddress != validatedAddress1 ||
          originalCity != validatedCity ||
          originalState != validatedState ||
          originalZip != validatedZip) {
        // Show suggestion dialog
        if (mounted) {
          setState(() {
            _suggestedAddress = validatedAddress;
            _showAddressSuggestion = true;
            _isValidatingAddress = false;
          });
          
          _showAddressSuggestionDialog(validatedAddress);
        }
      } else {
        // Address matches, proceed to save contact info
        await _saveContactInfoAndProceed(viewModel);
      }
    } catch (e) {
      print('❌ Address validation failed: $e');
      final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
      
      // Clean up error message (remove "Exception: " prefix if present)
      String errorMsg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      
      // Show dialog allowing user to proceed anyway (matching Swift implementation)
      if (mounted) {
        setState(() {
          _isValidatingAddress = false;
          // Format error message similar to Swift implementation
          if (errorMsg.toLowerCase().contains('multiple addresses') || 
              errorMsg.toLowerCase().contains('not available') || 
              errorMsg.toLowerCase().contains('not found')) {
            _addressValidationErrorMessage = '$errorMsg\n\nThe address could not be validated. You can still proceed with your address, or you may want to provide more specific address details.';
          } else {
            _addressValidationErrorMessage = '$errorMsg\n\nThe address could not be validated. You can still proceed with your address, or you may want to check and correct your address information.';
          }
          _showAddressValidationError = true;
        });
        
        _showAddressValidationErrorDialog(viewModel);
      }
    }
  }

  void _showAddressValidationErrorDialog(UserRegistrationViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Address Validation'),
        content: Text(_addressValidationErrorMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _showAddressValidationError = false;
                _addressValidationErrorMessage = '';
              });
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _showAddressValidationError = false;
                _addressValidationErrorMessage = '';
              });
              // Proceed with the original address even though validation failed
              _saveContactInfoAndProceed(viewModel);
            },
            child: const Text('Keep My Address'),
          ),
        ],
      ),
    );
  }

  void _showAddressSuggestionDialog(USPSAddressData validatedAddress) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Address Suggestion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('We found a standardized version of your address:'),
            const SizedBox(height: 16),
            Text(
              '${validatedAddress.address1 ?? ''}\n'
              '${validatedAddress.address2 ?? ''}\n'
              '${validatedAddress.city ?? ''}, ${validatedAddress.state ?? ''} ${validatedAddress.zip5 ?? ''}',
              style: AppTheme.bodyStyle,
            ),
            const SizedBox(height: 16),
            const Text('Would you like to use this address?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _showAddressSuggestion = false;
                _suggestedAddress = null;
              });
              // Continue with original address
              final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
              _saveContactInfoAndProceed(viewModel);
            },
            child: const Text('Use Original'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Update viewModel with validated address
              final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
              viewModel.street = validatedAddress.address1 ?? viewModel.street;
              viewModel.aptNumber = validatedAddress.address2 ?? viewModel.aptNumber;
              viewModel.city = validatedAddress.city ?? viewModel.city;
              viewModel.state = validatedAddress.state ?? viewModel.state;
              viewModel.zip = validatedAddress.zip5 ?? viewModel.zip;
              
              // Update controllers
              _streetController.text = viewModel.street;
              _aptController.text = viewModel.aptNumber;
              _cityController.text = viewModel.city;
              _stateController.text = viewModel.state;
              _zipController.text = viewModel.zip;
              
              setState(() {
                _showAddressSuggestion = false;
                _suggestedAddress = null;
              });
              
              // Save with validated address
              _saveContactInfoAndProceed(viewModel);
            },
            child: const Text('Use Suggested'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveContactInfoAndProceed(UserRegistrationViewModel viewModel) async {
    setState(() {
      _isSaving = true;
    });

    print('📝 DEBUG: Saving contact info - Name: ${viewModel.firstName} ${viewModel.lastName}, Phone: ${viewModel.phoneNumber}');
    final success = await viewModel.saveContactInfo();
    print('✅ DEBUG: saveContactInfo returned: $success, Error: ${viewModel.errorMessage}');
    
    // Save step progress to Firestore (matching TrumpMobile behavior)
    if (success && viewModel.userId != null && viewModel.orderId != null) {
      print('💾 DEBUG: Saving step progress - UserID: ${viewModel.userId}, OrderID: ${viewModel.orderId}');
      final orderManager = FirebaseOrderManager();
      await orderManager.saveStepProgress(
        userId: viewModel.userId!,
        orderId: viewModel.orderId!,
        step: 1,
      );
    }
    
    setState(() {
      _isSaving = false;
      _isValidatingAddress = false;
    });

    if (success && mounted) {
      print('✨ DEBUG: About to call onStepChanged(2)');
      widget.onStepChanged(2);
    } else if (mounted) {
      print('❌ DEBUG: Success is false, showing error message');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? 'Failed to save contact info'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  void dispose() {
    _zipController.removeListener(_onZipCodeChanged);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _aptController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<UserRegistrationViewModel>(context);

    return StepNavigationContainer(
      currentStep: widget.currentStep,
      totalSteps: 6,
      nextButtonText: 'Next Step',
      nextButtonAction: _handleNext,
      backButtonAction: () {
        // Step 1 has no back button, so this won't be called
      },
      cancelAction: () {
        // Handle cancel - navigate back to home
        final navigationState = Provider.of<NavigationState>(context, listen: false);
        navigationState.navigateTo(Destination.startNewOrder);
        navigationState.setFooterTab(FooterTab.home);
        navigationState.orderStartStep = null;
        navigationState.currentOrderId = null;
        widget.onStepChanged(0);
      },
      nextButtonDisabled: false,
      isLoading: _isSaving || _isValidatingAddress,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            OrderStepHeader(
              title: 'Contact information',
            ),
            SizedBox(height: AppTheme.spacingSection),
            // Contact Information Section
            TextFormField(
              controller: _firstNameController,
              decoration: AppTheme.inputDecoration('First Name'),
              style: const TextStyle(color: AppTheme.appText),
              validator: (value) => Validators.required(value, fieldName: 'First name'),
            ),
            SizedBox(height: AppTheme.spacingItem),
            TextFormField(
              controller: _lastNameController,
              decoration: AppTheme.inputDecoration('Last Name'),
              style: const TextStyle(color: AppTheme.appText),
              validator: (value) => Validators.required(value, fieldName: 'Last name'),
            ),
            SizedBox(height: AppTheme.spacingItem),
            // Phone field with dynamic border styling (gold when valid)
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _phoneController,
              builder: (context, value, _) {
                final phoneDigits = value.text.replaceAll(RegExp(r'[^\d]'), '');
                final isValid = phoneDigits.length == 10;
                return TextFormField(
                  controller: _phoneController,
                  decoration: AppTheme.inputDecoration('(000) 000-0000').copyWith(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusInput),
                      borderSide: BorderSide(
                        color: isValid ? AppTheme.accentGold : AppTheme.borderColor,
                        width: isValid ? AppTheme.borderWidthSelected : AppTheme.borderWidthDefault,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusInput),
                      borderSide: BorderSide(
                        color: isValid ? AppTheme.accentGold : AppTheme.borderColor,
                        width: isValid ? AppTheme.borderWidthSelected : AppTheme.borderWidthDefault,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusInput),
                      borderSide: BorderSide(
                        color: AppTheme.accentGold,
                        width: AppTheme.borderWidthSelected,
                      ),
                    ),
                  ),
                  style: const TextStyle(color: AppTheme.appText, fontSize: 16.0),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [PhoneNumberFormatter()],
                  validator: Validators.phoneNumber,
                );
              },
            ),
            SizedBox(height: AppTheme.spacingItem),
            TextFormField(
              enabled: false,
              decoration: AppTheme.inputDecoration('Email').copyWith(
                filled: true,
                fillColor: AppTheme.disabledBackground,
              ),
              style: const TextStyle(color: AppTheme.appText),
              initialValue: viewModel.email,
            ),
            SizedBox(height: AppTheme.spacingSection),
            // Shipping Address Section
            OrderStepHeader(
              title: 'Shipping address',
            ),
            SizedBox(height: AppTheme.spacingItem),
            // Checkbox for "Use your current location"
            CheckboxListTile(
              title: Text('Use your current location', style: AppTheme.bodyStyle),
              value: _useCurrentLocation,
              onChanged: (value) {
                if (value == true) {
                  _fetchCurrentLocation();
                } else {
                  setState(() {
                    _useCurrentLocation = false;
                  });
                }
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              secondary: _isLoadingLocation
                  ? SizedBox(
                      width: AppTheme.iconSizeSmall,
                      height: AppTheme.iconSizeSmall,
                      child: CircularProgressIndicator(strokeWidth: AppTheme.borderWidthDefault),
                    )
                  : null,
            ),
            SizedBox(height: AppTheme.spacingItem),
            TextFormField(
              controller: _streetController,
              decoration: AppTheme.inputDecoration('Street Address'),
              style: const TextStyle(color: AppTheme.appText),
              validator: (value) => Validators.required(value, fieldName: 'Street address'),
            ),
            SizedBox(height: AppTheme.spacingItem),
            TextFormField(
              controller: _aptController,
              decoration: AppTheme.inputDecoration('Apt, Suite, etc. (optional)'),
              style: const TextStyle(color: AppTheme.appText),
            ),
            SizedBox(height: AppTheme.spacingItem),
            TextFormField(
              controller: _cityController,
              decoration: AppTheme.inputDecoration('City'),
              style: const TextStyle(color: AppTheme.appText),
            ),
            SizedBox(height: AppTheme.spacingItem),
            // State and ZIP Code in a row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: AppTheme.inputDecoration('State'),
                    style: const TextStyle(color: AppTheme.appText),
                  ),
                ),
                SizedBox(width: AppTheme.spacingItem),
                Expanded(
                  child: TextFormField(
                    controller: _zipController,
                    decoration: AppTheme.inputDecoration('Zip Code').copyWith(
                      suffixIcon: _isLoadingCityState
                          ? SizedBox(
                              width: AppTheme.iconSizeSmall,
                              height: AppTheme.iconSizeSmall,
                              child: Padding(
                                padding: EdgeInsets.all(AppTheme.spacingMedium),
                                child: CircularProgressIndicator(strokeWidth: AppTheme.borderWidthDefault),
                              ),
                            )
                          : null,
                    ),
                    style: const TextStyle(color: AppTheme.appText),
                    keyboardType: TextInputType.number,
                    validator: Validators.zipCode,
                  ),
                ),
              ],
            ),
            ],
          ),
      )
    );
  }
}

