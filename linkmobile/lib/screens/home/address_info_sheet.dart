import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../providers/user_registration_view_model.dart';
import '../../services/firebase_manager.dart';
import '../../services/vcare_api_manager.dart';
import '../../utils/validators.dart';
import '../../utils/theme.dart';

class AddressInfoSheet extends StatefulWidget {
  const AddressInfoSheet({super.key});

  @override
  State<AddressInfoSheet> createState() => _AddressInfoSheetState();
}

class _AddressInfoSheetState extends State<AddressInfoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _aptController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingCityState = false;
  bool _useCurrentLocation = false;
  bool _isLoadingLocation = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _loadAddress();
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
      _locationError = null;
    });
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _useCurrentLocation = false;
          _isLoadingLocation = false;
          _locationError = 'Location services are disabled. Please enable them in Settings.';
        });
        return;
      }
      
      // Check location permission - always try to request if denied
      LocationPermission permission = await Geolocator.checkPermission();
      
      // If denied, try to request permission again (allows retry after denial)
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _useCurrentLocation = false;
            _isLoadingLocation = false;
            _locationError = 'Location permissions are denied. Please enable them in Settings.';
          });
          return;
        }
      }
      
      // If permanently denied, show error message inline
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _useCurrentLocation = false;
          _isLoadingLocation = false;
          _locationError = 'Location permissions are permanently denied. Please enable them in Settings.';
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
          _locationError = 'Unable to get location. Please enter your address manually.';
        });
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
            _locationError = null;
          });
        } else {
          setState(() {
            _isLoadingLocation = false;
            _locationError = 'Unable to get address from location. Please enter address manually.';
          });
        }
      } catch (e) {
        print('❌ Failed to reverse geocode: $e');
        setState(() {
          _isLoadingLocation = false;
          _locationError = 'Unable to get address from location. Please enter address manually.';
        });
      }
    } catch (e) {
      print('❌ Failed to get current location: $e');
      // Always clear loading state and show user-friendly error
      setState(() {
        _useCurrentLocation = false;
        _isLoadingLocation = false;
        if (e is TimeoutException) {
          _locationError = 'Unable to get location. Please ensure GPS is enabled or enter address manually.';
        } else {
          _locationError = 'Unable to get location. Please enter your address manually.';
        }
      });
    }
  }

  Future<void> _loadAddress() async {
    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    await viewModel.loadUserData();
    
    setState(() {
      _streetController.text = viewModel.street;
      _aptController.text = viewModel.aptNumber;
      _cityController.text = viewModel.city;
      _stateController.text = viewModel.state;
      _zipController.text = viewModel.zip;
    });
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate that city and state are filled (they should be auto-filled from ZIP code)
    if (_cityController.text.isEmpty || _stateController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid ZIP code to auto-fill city and state.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    final userId = viewModel.userId;
    
    if (userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final addressData = {
        'street': _streetController.text,
        'aptNumber': _aptController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'zip': _zipController.text,
        'country': 'USA',
      };

      await FirebaseManager().saveShippingAddress(userId, addressData);
      
      viewModel.street = _streetController.text;
      viewModel.aptNumber = _aptController.text;
      viewModel.city = _cityController.text;
      viewModel.state = _stateController.text;
      viewModel.zip = _zipController.text;

      if (mounted) {
        Navigator.of(context).pop(_zipController.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving address: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _zipController.removeListener(_onZipCodeChanged);
    _streetController.dispose();
    _aptController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update Address',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Use Current Location Checkbox
            CheckboxListTile(
              title: const Text('Use my current location'),
              value: _useCurrentLocation,
              onChanged: _isLoadingLocation
                  ? null
                  : (value) {
                      if (value == true) {
                        _fetchCurrentLocation();
                      } else {
                        setState(() {
                          _useCurrentLocation = false;
                          _locationError = null;
                        });
                      }
                    },
              subtitle: _isLoadingLocation
                  ? const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Fetching location...'),
                      ],
                    )
                  : _locationError != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 16,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _locationError!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_locationError!.contains('permanently denied'))
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0, left: 24.0),
                                child: TextButton(
                                  onPressed: () async {
                                    await Geolocator.openAppSettings();
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Open Settings',
                                    style: TextStyle(
                                      fontSize: 12,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _streetController,
              decoration: const InputDecoration(
                labelText: 'Street Address *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => Validators.required(value, fieldName: 'Street address'),
              enabled: !_isLoadingLocation,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _aptController,
              decoration: const InputDecoration(
                labelText: 'Apt/Suite (Optional)',
                border: OutlineInputBorder(),
              ),
              enabled: !_isLoadingLocation,
            ),
            const SizedBox(height: 16),
            // ZIP code with city and state next to it
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _zipController,
                    decoration: InputDecoration(
                      labelText: 'ZIP Code *',
                      border: const OutlineInputBorder(),
                      suffixIcon: _isLoadingCityState
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                    keyboardType: TextInputType.number,
                    validator: Validators.zipCode,
                    enabled: !_isLoadingLocation,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _cityController,
                    builder: (context, cityValue, _) {
                      return ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _stateController,
                        builder: (context, stateValue, _) {
                          if (cityValue.text.isEmpty && stateValue.text.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              '${cityValue.text.isNotEmpty ? cityValue.text.toUpperCase() : ''}${cityValue.text.isNotEmpty && stateValue.text.isNotEmpty ? ', ' : ''}${stateValue.text.isNotEmpty ? stateValue.text.toUpperCase() : ''}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.mainBlue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Address'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

