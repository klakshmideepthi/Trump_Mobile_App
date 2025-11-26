import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../../providers/user_registration_view_model.dart';
import '../../providers/navigation_state.dart';
import '../../services/firebase_order_manager.dart';
import '../../models/phone_models.dart';
import '../../widgets/step_navigation_container.dart';
import '../../widgets/order_step_header.dart';
import '../../utils/validators.dart';
import '../../utils/theme.dart';
import 'imei_check_view.dart';

class DeviceCompatibilityView extends StatefulWidget {
  final int currentStep;
  final Function(int) onStepChanged;

  const DeviceCompatibilityView({
    super.key,
    required this.currentStep,
    required this.onStepChanged,
  });

  @override
  State<DeviceCompatibilityView> createState() => _DeviceCompatibilityViewState();
}

class _DeviceCompatibilityViewState extends State<DeviceCompatibilityView> {
  final _formKey = GlobalKey<FormState>();
  final _imeiController = TextEditingController();
  PhoneBrand? _selectedBrand;
  PhoneModel? _selectedModel;
  bool _isSaving = false;
  bool _deviceIsCompatible = false;
  bool _showIMEICheckSheet = false;
  bool? _imeiCompatible; // null = not checked, true = compatible, false = not compatible
  String _imeiNumber = '';
  bool _isReadingDevice = false;
  bool _deviceNotInCatalog = false; // true if brand/model not found in catalog

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    final catalog = PhoneCatalog();
    _imeiController.text = viewModel.imei;
    _deviceIsCompatible = viewModel.deviceIsCompatible;
    _imeiCompatible = null; // Reset IMEI compatibility status
    _deviceNotInCatalog = false;
    
    if (viewModel.deviceBrand.isNotEmpty) {
      _selectedBrand = PhoneBrand.values.firstWhere(
        (b) => b.displayName == viewModel.deviceBrand,
        orElse: () => PhoneBrand.apple,
      );
    }
    
    if (viewModel.deviceModel.isNotEmpty && _selectedBrand != null) {
      final models = catalog.modelsForBrand(_selectedBrand!);
      try {
        _selectedModel = models.firstWhere(
          (m) => m.name == viewModel.deviceModel,
        );
      } catch (e) {
        // Model not found in catalog
        _selectedModel = null;
      }
      
      // Check if brand and model are actually in catalog
      final brandInCatalog = PhoneBrand.values.contains(_selectedBrand!);
      final modelInCatalog = _selectedModel != null && models.any((model) => model.name == _selectedModel!.name);
      _deviceIsCompatible = brandInCatalog && modelInCatalog;
      _deviceNotInCatalog = !_deviceIsCompatible;
    }
    
    // If IMEI was previously checked, restore the state
    if (viewModel.imei.isNotEmpty) {
      _imeiNumber = viewModel.imei;
      // IMEI compatibility status should be derived from supportsESIM/supportsPhysicalSIM
      // if they were set, otherwise assume compatible
      if (viewModel.supportsESIM || viewModel.supportsPhysicalSIM) {
        _imeiCompatible = true;
      }
    }
  }

  Future<void> _handleNext() async {
    // Allow proceeding even without brand/model or IMEI selection
    final hasBrandModel = _selectedBrand != null && _selectedModel != null;
    final hasIMEI = _imeiNumber.isNotEmpty;

    setState(() {
      _isSaving = true;
    });

    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    
    // Prioritize IMEI results over brand/model selection
    if (hasIMEI && _imeiCompatible != null) {
      // IMEI was checked - use its results
      viewModel.deviceIsCompatible = _imeiCompatible ?? false;
      // supportsESIM and supportsPhysicalSIM should already be set by IMEI check
    } else if (hasBrandModel) {
      // Brand/model selected - check if they're in catalog
      viewModel.deviceBrand = _selectedBrand!.displayName;
      viewModel.deviceModel = _selectedModel!.name;
      
      // Device is compatible only if both brand and model are in catalog
      final catalog = PhoneCatalog();
      final brandInCatalog = PhoneBrand.values.contains(_selectedBrand!);
      final models = catalog.modelsForBrand(_selectedBrand!);
      final modelInCatalog = models.any((model) => model.name == _selectedModel!.name);
      
      viewModel.deviceIsCompatible = brandInCatalog && modelInCatalog;
      
      // Set SIM compatibility based on model selection (only if not set by IMEI check)
      if (viewModel.deviceIsCompatible && !hasIMEI) {
        final simCompatibility = PhoneCatalog.getSimCompatibilityForModel(_selectedModel!.name);
        viewModel.supportsESIM = simCompatibility['supportsESIM'] ?? true;
        viewModel.supportsPhysicalSIM = simCompatibility['supportsPhysicalSIM'] ?? true;
      } else if (!viewModel.deviceIsCompatible) {
        // If not compatible, don't set SIM support
        viewModel.supportsESIM = false;
        viewModel.supportsPhysicalSIM = false;
      }
    } else {
      // Nothing selected - allow user to choose either option
      // Don't restrict their choices if they didn't provide device info
      viewModel.deviceIsCompatible = false;
      viewModel.supportsESIM = true;  // Default to true to show eSIM option
      viewModel.supportsPhysicalSIM = true;  // Default to true to show physical SIM option
    }
    
    // Always save IMEI if provided
    if (hasIMEI) {
      viewModel.imei = _imeiNumber;
    }

    final success = await viewModel.saveDeviceInfo();
    
    // Save step progress to Firestore (matching TrumpMobile behavior)
    if (success && viewModel.userId != null && viewModel.orderId != null) {
      final orderManager = FirebaseOrderManager();
      await orderManager.saveStepProgress(
        userId: viewModel.userId!,
        orderId: viewModel.orderId!,
        step: 2,
      );
    }
    
    setState(() {
      _isSaving = false;
    });

    if (success && mounted) {
      widget.onStepChanged(3);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? 'Failed to save device info'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _handleBack() {
    widget.onStepChanged(1);
  }

  Future<void> _readDeviceInfo() async {
    setState(() {
      _isReadingDevice = true;
    });

    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final catalog = PhoneCatalog();
      PhoneBrand? detectedBrand;
      PhoneModel? detectedModel;
      String deviceName = '';
      String manufacturer = '';

      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        manufacturer = androidInfo.manufacturer;
        deviceName = androidInfo.model; // This is the model code (e.g., "SM-F766U", "G4QUR")
        
        print('=== ANDROID DEVICE DETECTION DEBUG ===');
        print('Manufacturer: $manufacturer');
        print('Model Code: $deviceName');
        print('Device: ${androidInfo.device}');
        print('Product: ${androidInfo.product}');
        print('Brand: ${androidInfo.brand}');
        
        // Map manufacturer to PhoneBrand
        final manufacturerLower = manufacturer.toLowerCase();
        if (manufacturerLower.contains('samsung')) {
          detectedBrand = PhoneBrand.samsung;
        } else if (manufacturerLower.contains('google')) {
          detectedBrand = PhoneBrand.google;
        } else if (manufacturerLower.contains('oneplus')) {
          detectedBrand = PhoneBrand.oneplus;
        }
        
        // Map model code to marketing name
        final marketingName = PhoneCatalog.getMarketingNameFromModelCode(deviceName);
        print('Marketing Name from Model Code: $marketingName');
        
        if (marketingName != null && detectedBrand != null) {
          // Try to find the model in catalog using marketing name
          final models = catalog.modelsForBrand(detectedBrand);
          print('Available models for ${detectedBrand.displayName}: ${models.map((m) => m.name).toList()}');
          
          // Try exact match first
          try {
            detectedModel = models.firstWhere(
              (model) => model.name.toLowerCase() == marketingName.toLowerCase(),
            );
            print('Exact match found: ${detectedModel.name}');
          } catch (e) {
            // Try partial match
            try {
              detectedModel = models.firstWhere(
                (model) {
                  final modelNameLower = model.name.toLowerCase();
                  final marketingNameLower = marketingName.toLowerCase();
                  return modelNameLower.contains(marketingNameLower) ||
                         marketingNameLower.contains(modelNameLower);
                },
              );
              print('Partial match found: ${detectedModel.name}');
            } catch (e2) {
              print('No match found for marketing name: $marketingName');
              detectedModel = null;
            }
          }
        } else {
          print('Could not map model code "$deviceName" to marketing name');
          // Fall back to original matching logic
          if (detectedBrand != null) {
            final models = catalog.modelsForBrand(detectedBrand);
            for (var model in models) {
              final modelNameNormalized = model.name.toLowerCase().replaceAll(' ', '').replaceAll('-', '');
              final deviceNameNormalized = deviceName.toLowerCase().replaceAll(' ', '').replaceAll('-', '');
              
              if (deviceNameNormalized.contains(modelNameNormalized) ||
                  modelNameNormalized.contains(deviceNameNormalized)) {
                detectedModel = model;
                break;
              }
            }
          }
        }
        
        print('=== END ANDROID DEBUG ===');
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceName = iosInfo.model;
        manufacturer = 'Apple';
        detectedBrand = PhoneBrand.apple;
        
        // DEBUG: Log all iOS device info
        print('=== iOS DEVICE DETECTION DEBUG ===');
        print('iosInfo.model: ${iosInfo.model}');
        print('iosInfo.name: ${iosInfo.name}');
        print('iosInfo.systemName: ${iosInfo.systemName}');
        print('iosInfo.systemVersion: ${iosInfo.systemVersion}');
        print('iosInfo.utsname.machine: ${iosInfo.utsname.machine}');
        print('iosInfo.utsname.nodename: ${iosInfo.utsname.nodename}');
        print('iosInfo.utsname.release: ${iosInfo.utsname.release}');
        print('iosInfo.utsname.sysname: ${iosInfo.utsname.sysname}');
        print('iosInfo.utsname.version: ${iosInfo.utsname.version}');
        
        // Use model identifier (utsname.machine) for accurate iPhone detection
        final modelIdentifier = iosInfo.utsname.machine;
        print('Model Identifier: $modelIdentifier');
        
        final mappedModelName = PhoneCatalog.getiPhoneModelFromIdentifier(modelIdentifier);
        print('Mapped Model Name: $mappedModelName');
        
        if (mappedModelName != null) {
          // Find the model in the catalog using the mapped name
          final models = catalog.modelsForBrand(PhoneBrand.apple);
          print('Available Apple models: ${models.map((m) => m.name).toList()}');
          
          detectedModel = models.firstWhere(
            (model) => model.name == mappedModelName,
            orElse: () {
              print('WARNING: Could not find model "$mappedModelName" in catalog, using first model: ${models.first.name}');
              return models.first;
            },
          );
          print('Selected Model: ${detectedModel.name}');
        } else {
          print('WARNING: Model identifier "$modelIdentifier" not recognized in mapping function');
        }
        print('=== END DEBUG ===');
      }

      // Check if brand is in catalog
      bool brandInCatalog = detectedBrand != null && PhoneBrand.values.contains(detectedBrand);
      
      if (detectedBrand != null && brandInCatalog) {
        // For Android or if iOS mapping didn't work, try to find matching model in catalog
        if (detectedModel == null) {
          print('=== FALLBACK MODEL DETECTION ===');
          print('detectedModel is null, trying fallback matching');
          print('deviceName: $deviceName');
          
          final models = catalog.modelsForBrand(detectedBrand);
          print('Available models for ${detectedBrand.displayName}: ${models.map((m) => m.name).toList()}');
          
          // Try to match device name with catalog models
          for (var model in models) {
            // Check if device name contains model name or vice versa
            final modelNameNormalized = model.name.toLowerCase().replaceAll(' ', '').replaceAll('-', '');
            final deviceNameNormalized = deviceName.toLowerCase().replaceAll(' ', '').replaceAll('-', '');
            
            print('Comparing: "$deviceNameNormalized" with "$modelNameNormalized"');
            
            if (deviceNameNormalized.contains(modelNameNormalized) ||
                modelNameNormalized.contains(deviceNameNormalized)) {
              print('Match found: ${model.name}');
              detectedModel = model;
              break;
            }
          }
          
          // If no exact match, try partial matching
          if (detectedModel == null && deviceName.isNotEmpty) {
            print('No exact match, trying partial matching...');
            for (var model in models) {
              final modelWords = model.name.toLowerCase().split(' ');
              final deviceWords = deviceName.toLowerCase().split(' ');
              if (modelWords.any((word) => word.length > 2 && deviceWords.any((dw) => dw.contains(word) || word.contains(dw))) ||
                  deviceWords.any((word) => word.length > 2 && modelWords.any((mw) => mw.contains(word) || word.contains(mw)))) {
                print('Partial match found: ${model.name}');
                detectedModel = model;
                break;
              }
            }
          }
          
          // If still no match, mark as not in catalog (don't use fallback)
          if (detectedModel == null) {
            print('WARNING: Model not found in catalog for ${detectedBrand.displayName}');
          }
          print('=== END FALLBACK DEBUG ===');
        } else {
          // Verify the detected model is actually in the catalog
          final models = catalog.modelsForBrand(detectedBrand);
          final modelInCatalog = models.any((model) => model.name == detectedModel!.name);
          if (!modelInCatalog) {
            print('WARNING: Detected model "${detectedModel!.name}" not found in catalog');
            detectedModel = null;
          } else {
            print('detectedModel already set: ${detectedModel.name}');
          }
        }

        print('=== FINAL SELECTION ===');
        print('Selected Brand: ${detectedBrand.displayName}');
        print('Selected Model: ${detectedModel?.name ?? "null"}');
        print('Brand in Catalog: $brandInCatalog');
        print('Model in Catalog: ${detectedModel != null}');
        print('======================');

        // Determine if device is compatible (both brand and model must be in catalog)
        final bool isCompatible = brandInCatalog && detectedModel != null;

        setState(() {
          _selectedBrand = detectedBrand;
          _selectedModel = detectedModel;
          _deviceIsCompatible = isCompatible;
          _deviceNotInCatalog = !isCompatible;
        });
        
        // Set SIM compatibility based on detected model
        if (isCompatible && detectedModel != null) {
          final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
          final simCompatibility = PhoneCatalog.getSimCompatibilityForModel(detectedModel.name);
          viewModel.supportsESIM = simCompatibility['supportsESIM'] ?? true;
          viewModel.supportsPhysicalSIM = simCompatibility['supportsPhysicalSIM'] ?? true;
        }

        if (mounted) {
          if (isCompatible) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Detected: ${detectedBrand.displayName} ${detectedModel!.name}'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  detectedModel == null
                      ? 'Could not detect device model. Please select your device model manually from the dropdown.'
                      : 'Device brand not supported. Your device may not be compatible.',
                ),
                backgroundColor: detectedModel == null ? AppTheme.warningColor : AppTheme.errorColor,
              ),
            );
          }
        }
      } else {
        // Brand not detected or not in catalog
        setState(() {
          _selectedBrand = null;
          _selectedModel = null;
          _deviceIsCompatible = false;
          _deviceNotInCatalog = true;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                detectedBrand == null
                    ? 'Could not detect device brand. Manufacturer: $manufacturer. Your device may not be compatible.'
                    : 'Device brand "$manufacturer" not supported. Your device may not be compatible.',
              ),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reading device info: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isReadingDevice = false;
        });
      }
    }
  }

  void _checkIMEI() {
    // Show bottom sheet instead of navigating
    setState(() {
      _showIMEICheckSheet = true;
    });
  }

  void _onIMEISubmit(String imei, bool? isCompatible, bool? supportsESIM, bool? supportsPhysicalSIM) {
    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    
    setState(() {
      _imeiController.text = imei;
      _imeiNumber = imei;
      _imeiCompatible = isCompatible;
      
      // Store eSIM/physical SIM support from IMEI check
      if (supportsESIM != null) {
        viewModel.supportsESIM = supportsESIM;
      }
      if (supportsPhysicalSIM != null) {
        viewModel.supportsPhysicalSIM = supportsPhysicalSIM;
      }
      
      // If IMEI says compatible, use that; otherwise allow proceeding but mark as not compatible
      if (isCompatible != null) {
        _deviceIsCompatible = isCompatible;
      }
      
      _showIMEICheckSheet = false;
    });
  }

  @override
  void dispose() {
    _imeiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = PhoneCatalog();
    final availableModels = _selectedBrand != null
        ? catalog.modelsForBrand(_selectedBrand!)
        : <PhoneModel>[];

    // Show IMEI check bottom sheet if needed
    if (_showIMEICheckSheet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => IMEICheckView(
            initialImei: _imeiController.text,
            onSubmitIMEI: _onIMEISubmit,
          ),
        ).then((_) {
          if (mounted) {
            setState(() {
              _showIMEICheckSheet = false;
            });
          }
        });
      });
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
      nextButtonDisabled: !((_selectedBrand != null && _selectedModel != null) || (_imeiNumber.isNotEmpty && _imeiCompatible == true)),
      isLoading: _isSaving,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            OrderStepHeader(
              title: 'Check device compatibility',
              subtitle: 'Let\'s double-check that your device works with Telgoo5 Mobile.',
            ),
            SizedBox(height: AppTheme.spacingSection),
            SizedBox(
              width: double.infinity,
              height: 50.0,
              child: ElevatedButton.icon(
                onPressed: _isReadingDevice ? null : _readDeviceInfo,
                icon: _isReadingDevice
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.phone_android, color: Colors.white),
                label: Text(
                  _isReadingDevice ? 'Reading device info...' : 'Auto-detect device',
                  style: AppTheme.bodyStyle.copyWith(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  disabledBackgroundColor: AppTheme.disabledBackground,
                  padding: EdgeInsets.symmetric(vertical: AppTheme.paddingButtonVertical),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusButton),
                  ),
                ),
              ),
            ),
            SizedBox(height: AppTheme.spacingItem),
            DropdownButtonFormField<PhoneBrand>(
              value: _selectedBrand,
              decoration: AppTheme.inputDecoration('Device Brand'),
              items: PhoneBrand.values.map((brand) {
                return DropdownMenuItem(
                  value: brand,
                  child: Text(brand.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBrand = value;
                  _selectedModel = null;
                  // Reset compatibility when brand changes
                  _deviceIsCompatible = false;
                  _deviceNotInCatalog = false;
                });
              },
            ),
            SizedBox(height: AppTheme.spacingItem),
            DropdownButtonFormField<PhoneModel>(
              value: _selectedModel,
              decoration: AppTheme.inputDecoration('Device Model'),
              items: availableModels.map((model) {
                return DropdownMenuItem(
                  value: model,
                  child: Text(model.name),
                );
              }).toList(),
              onChanged: _selectedBrand == null
                  ? null
                  : (value) {
                      final catalog = PhoneCatalog();
                      final brandInCatalog = PhoneBrand.values.contains(_selectedBrand!);
                      final models = catalog.modelsForBrand(_selectedBrand!);
                      final modelInCatalog = value != null && models.any((model) => model.name == value.name);
                      final isCompatible = brandInCatalog && modelInCatalog;
                      
                      setState(() {
                        _selectedModel = value;
                        _deviceIsCompatible = isCompatible;
                        _deviceNotInCatalog = !isCompatible;
                      });
                      
                      // Update SIM compatibility when model is selected
                      if (value != null && isCompatible) {
                        final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
                        final simCompatibility = PhoneCatalog.getSimCompatibilityForModel(value.name);
                        viewModel.supportsESIM = simCompatibility['supportsESIM'] ?? true;
                        viewModel.supportsPhysicalSIM = simCompatibility['supportsPhysicalSIM'] ?? true;
                      }
                    },
            ),
            if (_selectedModel != null && _selectedModel!.name.isNotEmpty) ...[
              Builder(
                builder: (context) {
                  final simCompatibility = PhoneCatalog.getSimCompatibilityForModel(_selectedModel!.name);
                  final supportsESIM = simCompatibility['supportsESIM'] ?? false;
                  final supportsPhysicalSIM = simCompatibility['supportsPhysicalSIM'] ?? false;
                  
                  return Column(
                    children: [
                      SizedBox(height: AppTheme.spacingSection),
                      Container(
                          padding: EdgeInsets.all(AppTheme.paddingCard),
                          decoration: BoxDecoration(
                            color: _deviceIsCompatible
                                ? AppTheme.successBackground
                                : AppTheme.errorBackground,
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusCard),
                            border: Border.all(
                              color: _deviceIsCompatible
                                  ? AppTheme.successColor
                                  : AppTheme.errorColor,
                              width: AppTheme.borderWidthDefault,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Results for ${_selectedModel!.name}',
                                style: AppTheme.sectionTitleStyle,
                              ),
                              SizedBox(height: AppTheme.spacingMedium),
                              if (_deviceIsCompatible) ...[
                                Row(
                                  children: [
                                    Icon(Icons.check_circle, color: AppTheme.successColor, size: AppTheme.iconSizeSmall),
                                    SizedBox(width: AppTheme.spacingSmall),
                                    Expanded(
                                      child: Text('Device is compatible with our network.', style: AppTheme.bodyStyle),
                                    ),
                                  ],
                                ),
                                SizedBox(height: AppTheme.spacingSmall),
                                // eSIM compatibility
                                Row(
                                  children: [
                                    Icon(
                                      supportsESIM ? Icons.check_circle : Icons.cancel,
                                      color: supportsESIM ? AppTheme.successColor : AppTheme.errorColor,
                                      size: AppTheme.iconSizeSmall,
                                    ),
                                    SizedBox(width: AppTheme.spacingSmall),
                                    Expanded(
                                      child: Text(
                                        supportsESIM
                                            ? 'Your device supports eSIM.'
                                            : 'Your device does not support eSIM.',
                                        style: AppTheme.bodyStyle,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: AppTheme.spacingSmall),
                                // Physical SIM compatibility
                                Row(
                                  children: [
                                    Icon(
                                      supportsPhysicalSIM ? Icons.check_circle : Icons.cancel,
                                      color: supportsPhysicalSIM ? AppTheme.successColor : AppTheme.errorColor,
                                      size: AppTheme.iconSizeSmall,
                                    ),
                                    SizedBox(width: AppTheme.spacingSmall),
                                    Expanded(
                                      child: Text(
                                        supportsPhysicalSIM
                                            ? 'Your device supports physical SIM card.'
                                            : 'Your device does not support physical SIM card.',
                                        style: AppTheme.bodyStyle,
                                      ),
                                    ),
                                  ],
                                ),
                                // Summary
                                if (supportsESIM && supportsPhysicalSIM) ...[
                                  SizedBox(height: AppTheme.spacingSmall),
                                  Container(
                                    padding: EdgeInsets.all(AppTheme.spacingSmall),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentGold.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusCard / 2),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline, color: AppTheme.accentGold, size: AppTheme.iconSizeSmall),
                                        SizedBox(width: AppTheme.spacingSmall),
                                        Expanded(
                                          child: Text(
                                            'Your device supports both eSIM and physical SIM cards.',
                                            style: AppTheme.bodySmallStyle.copyWith(color: AppTheme.accentGold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else if (supportsESIM && !supportsPhysicalSIM) ...[
                                  SizedBox(height: AppTheme.spacingSmall),
                                  Container(
                                    padding: EdgeInsets.all(AppTheme.spacingSmall),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentGold.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusCard / 2),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline, color: AppTheme.accentGold, size: AppTheme.iconSizeSmall),
                                        SizedBox(width: AppTheme.spacingSmall),
                                        Expanded(
                                          child: Text(
                                            'Your device only supports eSIM (no physical SIM slot).',
                                            style: AppTheme.bodySmallStyle.copyWith(color: AppTheme.accentGold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else if (!supportsESIM && supportsPhysicalSIM) ...[
                                  SizedBox(height: AppTheme.spacingSmall),
                                  Container(
                                    padding: EdgeInsets.all(AppTheme.spacingSmall),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentGold.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusCard / 2),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline, color: AppTheme.accentGold, size: AppTheme.iconSizeSmall),
                                        SizedBox(width: AppTheme.spacingSmall),
                                        Expanded(
                                          child: Text(
                                            'Your device only supports physical SIM cards (no eSIM).',
                                            style: AppTheme.bodySmallStyle.copyWith(color: AppTheme.accentGold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ] else ...[
                                Row(
                                  children: [
                                    Icon(Icons.cancel, color: AppTheme.errorColor, size: AppTheme.iconSizeSmall),
                                    SizedBox(width: AppTheme.spacingSmall),
                                    Expanded(
                                      child: Text(
                                        'Device model not found in our catalog. Your device may not be compatible with our network.',
                                        style: AppTheme.bodyStyle,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: AppTheme.spacingSmall),
                                Text(
                                  'Please contact support or try checking your IMEI for compatibility verification.',
                                  style: AppTheme.bodySmallStyle,
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ] else if (_deviceNotInCatalog && _selectedBrand != null && _selectedModel == null) ...[
              SizedBox(height: AppTheme.spacingSection),
              Container(
                padding: EdgeInsets.all(AppTheme.paddingCard),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusCard),
                  border: Border.all(
                    color: AppTheme.warningColor,
                    width: AppTheme.borderWidthDefault,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.warningColor, size: AppTheme.iconSizeSmall),
                        SizedBox(width: AppTheme.spacingSmall),
                        Expanded(
                          child: Text(
                            'Could not detect device model for ${_selectedBrand!.displayName}.',
                            style: AppTheme.bodyStyle,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacingSmall),
                    Text(
                      'Please select your device model manually from the dropdown above to check compatibility.',
                      style: AppTheme.bodySmallStyle,
                    ),
                  ],
                ),
              ),
            ] else if (_deviceNotInCatalog && _selectedBrand != null && _selectedModel != null) ...[
              SizedBox(height: AppTheme.spacingSection),
              Container(
                padding: EdgeInsets.all(AppTheme.paddingCard),
                decoration: BoxDecoration(
                  color: AppTheme.errorBackground,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusCard),
                  border: Border.all(
                    color: AppTheme.errorColor,
                    width: AppTheme.borderWidthDefault,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cancel, color: AppTheme.errorColor, size: AppTheme.iconSizeSmall),
                        SizedBox(width: AppTheme.spacingSmall),
                        Expanded(
                          child: Text(
                            'Device brand "${_selectedBrand!.displayName}" is not supported.',
                            style: AppTheme.bodyStyle,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacingSmall),
                    Text(
                      'Your device may not be compatible with our network. Please contact support or try checking your IMEI for compatibility verification.',
                      style: AppTheme.bodySmallStyle,
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: AppTheme.spacingSection),
            Container(
              height: AppTheme.borderWidthDefault,
              decoration: BoxDecoration(
                gradient: AppTheme.blueGradient,
              ),
            ),
            SizedBox(height: AppTheme.spacingSection),
            Text(
              'Can\'t find your device in the list above?',
              style: AppTheme.bodyStyle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.spacingItem),
            SizedBox(
              width: double.infinity,
              height: 50.0, // Match GradientButton height
              child: OutlinedButton(
                onPressed: _checkIMEI,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.accentGold, width: AppTheme.borderWidthDefault),
                  padding: EdgeInsets.symmetric(vertical: AppTheme.paddingButtonVertical),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusButton),
                  ),
                ),
                child: Text('Check your IMEI instead', style: AppTheme.bodyStyle.copyWith(color: AppTheme.accentGold)),
              ),
            ),
            // IMEI Compatibility Section
            if (_imeiNumber.isNotEmpty) ...[
              SizedBox(height: AppTheme.spacingItem),
              Container(
                padding: EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  color: _imeiCompatible == true
                      ? AppTheme.successBackground
                      : _imeiCompatible == false
                          ? AppTheme.errorBackground
                          : AppTheme.disabledBackground,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusCard),
                  border: Border.all(
                    color: _imeiCompatible == true
                        ? AppTheme.successColor
                        : _imeiCompatible == false
                            ? AppTheme.errorColor
                            : AppTheme.borderColor,
                    width: AppTheme.borderWidthDefault,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _imeiCompatible == true
                          ? Icons.check_circle
                          : _imeiCompatible == false
                              ? Icons.cancel
                              : Icons.info,
                      color: _imeiCompatible == true
                          ? AppTheme.successColor
                          : _imeiCompatible == false
                              ? AppTheme.errorColor
                              : AppTheme.textSecondary,
                      size: AppTheme.iconSizeMedium,
                    ),
                    SizedBox(width: AppTheme.spacingSmall),
                    Expanded(
                      child: Text(
                        _imeiCompatible == true
                            ? 'Your device matches our network!'
                            : _imeiCompatible == false
                                ? 'Sorry, your device is not compatible.'
                                : 'IMEI entered but compatibility not checked.',
                        style: AppTheme.bodyStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

