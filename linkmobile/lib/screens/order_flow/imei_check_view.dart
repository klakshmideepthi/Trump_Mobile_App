import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import '../../utils/theme.dart';
import '../../services/vcare_api_manager.dart';
import '../../providers/user_registration_view_model.dart';

class IMEICheckView extends StatefulWidget {
  final String? initialImei;
  final Function(String imei, bool? isCompatible, bool? supportsESIM, bool? supportsPhysicalSIM)? onSubmitIMEI;

  const IMEICheckView({
    super.key,
    this.initialImei,
    this.onSubmitIMEI,
  });

  @override
  State<IMEICheckView> createState() => _IMEICheckViewState();
}

class _IMEICheckViewState extends State<IMEICheckView> {
  final _imeiController = TextEditingController();
  final _apiManager = VCareAPIManager();
  bool _isChecking = false;
  DeviceCompatibilityData? _compatibilityResult;
  String? _errorMessage;
  int _selectedTab = 0; // 0 = iOS, 1 = Android

  @override
  void initState() {
    super.initState();
    if (widget.initialImei != null && widget.initialImei!.isNotEmpty) {
      _imeiController.text = widget.initialImei!;
    }
    
    // Add listener to update state when IMEI changes
    _imeiController.addListener(_onIMEIChanged);
  }

  void _onIMEIChanged() {
    // Update state when IMEI text changes to enable/disable button
    setState(() {
      // State will be updated by the getter _isIMEIValid
      _compatibilityResult = null;
      _errorMessage = null;
    });
  }

  String get _imeiDigits => _imeiController.text.replaceAll(RegExp(r'[^\d]'), '');
  bool get _isIMEIValid => _imeiDigits.length == 15;

  String _formatIMEI(String digits) {
    if (digits.isEmpty) return '';
    var formatted = '';
    for (int i = 0; i < digits.length && i < 15; i++) {
      if (i == 3 || i == 8 || i == 13) {
        formatted += '-';
      }
      formatted += digits[i];
    }
    return formatted;
  }

  Future<String?> _getCarrierFromOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    final orderId = viewModel.orderId;

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
        return null;
      }

      final orderData = orderDoc.data() as Map<String, dynamic>?;
      final planId = orderData?['plan_id'] as int?;
      if (planId == null) return null;

      // Get carrier from plan
      final plansSnapshot = await db.collection('plans').get();
      for (var doc in plansSnapshot.docs) {
        final data = doc.data();
        if (data['plans'] is List) {
          final plans = data['plans'] as List;
          for (var plan in plans) {
            if (plan is Map && plan['plan_id'] == planId) {
              if (plan['carrier'] is List && (plan['carrier'] as List).isNotEmpty) {
                return (plan['carrier'] as List).first as String?;
              }
            }
          }
        }
      }

      return null;
    } catch (e) {
      print('Error getting carrier from order: $e');
      return null;
    }
  }

  Future<void> _checkIMEI() async {
    if (!_isIMEIValid) {
      setState(() {
        _errorMessage = 'Invalid IMEI. Must be exactly 15 digits.';
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _errorMessage = null;
      _compatibilityResult = null;
    });

    try {
      // Get carrier from order
      final carrier = await _getCarrierFromOrder();
      if (carrier == null) {
        setState(() {
          _isChecking = false;
          _errorMessage = 'Unable to determine carrier. Please ensure you have selected a plan.';
        });
        return;
      }

      // Check device compatibility
      final compatibilityData = await _apiManager.checkDeviceCompatibility(
        imei: _imeiDigits,
        carrier: carrier,
        agentId: 'Sushil', // TODO: Get from user settings or configuration
        source: 'API',
      );

      // Store eSIM/physical SIM support in viewModel
      final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
      viewModel.supportsESIM = compatibilityData.supportsESIM;
      viewModel.supportsPhysicalSIM = compatibilityData.supportsPhysicalSIM;

      setState(() {
        _isChecking = false;
        _compatibilityResult = compatibilityData;
      });
    } catch (e) {
      setState(() {
        _isChecking = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _handleSubmit() {
    if (widget.onSubmitIMEI != null) {
      final isCompatible = _compatibilityResult?.isCompatible;
      final supportsESIM = _compatibilityResult?.supportsESIM;
      final supportsPhysicalSIM = _compatibilityResult?.supportsPhysicalSIM;
      
      widget.onSubmitIMEI!(
        _imeiDigits,
        isCompatible,
        supportsESIM,
        supportsPhysicalSIM,
      );
    }
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _imeiController.removeListener(_onIMEIChanged);
    _imeiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        final isCompatible = _compatibilityResult?.isCompatible ?? false;
        final showResult = _compatibilityResult != null;
        
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.appBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.borderRadiusCard)),
          ),
          child: Column(
            children: [
              // Drag indicator
              Container(
                margin: EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppTheme.paddingInput),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Find out if your phone is compatible',
                        style: AppTheme.titleStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppTheme.accentGold),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.all(AppTheme.paddingInput),
                  child: Column(
                    children: [
                      // IMEI Input
                      TextField(
                        controller: _imeiController,
                        decoration: AppTheme.inputDecoration('IMEI (${_formatIMEI("XXX-XXXXX-XXXXX-XX")})').copyWith(
                          filled: true,
                          fillColor: AppTheme.appBackground,
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !_isChecking && !showResult,
                        onChanged: (value) {
                          // Format IMEI as user types
                          final digits = value.replaceAll(RegExp(r'[^\d]'), '');
                          if (digits.length <= 15) {
                            final formatted = _formatIMEI(digits);
                            if (formatted != value) {
                              _imeiController.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(offset: formatted.length),
                              );
                            }
                          }
                        },
                      ),
                      SizedBox(height: AppTheme.spacingItem),
                      
                      // Error message
                      if (_errorMessage != null) ...[
                        Container(
                          padding: EdgeInsets.all(AppTheme.spacingMedium),
                          decoration: BoxDecoration(
                            color: AppTheme.errorBackground,
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusCard),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error, color: AppTheme.errorColor, size: AppTheme.iconSizeMedium),
                              SizedBox(width: AppTheme.spacingSmall),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: AppTheme.bodyStyle.copyWith(color: AppTheme.errorColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: AppTheme.spacingItem),
                      ],
                      
                      // Check Compatibility Button
                      if (!showResult)
                        SizedBox(
                          width: double.infinity,
                          height: 50.0, // Match GradientButton height
                          child: ElevatedButton(
                            onPressed: _isChecking || !_isIMEIValid
                                ? null
                                : _checkIMEI,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isChecking || !_isIMEIValid
                                  ? AppTheme.textTertiary
                                  : AppTheme.accentGold,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.borderRadiusButton),
                              ),
                            ),
                            child: _isChecking
                                ? CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  )
                                : Text(
                                    'Check Compatibility',
                                    style: AppTheme.buttonStyle,
                                  ),
                          ),
                        ),
                      
                      // Compatibility Result
                      if (showResult) ...[
                        SizedBox(height: AppTheme.spacingItem),
                        Container(
                          padding: EdgeInsets.all(AppTheme.paddingCard),
                          decoration: BoxDecoration(
                            color: isCompatible
                                ? AppTheme.successBackground
                                : AppTheme.errorBackground,
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusCard),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isCompatible ? Icons.check_circle : Icons.cancel,
                                    color: isCompatible ? AppTheme.successColor : AppTheme.errorColor,
                                    size: AppTheme.iconSizeLarge,
                                  ),
                                  SizedBox(width: AppTheme.spacingMedium),
                                  Expanded(
                                    child: Text(
                                      isCompatible ? 'Device Compatible' : 'Device Not Compatible',
                                      style: AppTheme.optionTitleStyle,
                                    ),
                                  ),
                                ],
                              ),
                              if (isCompatible) ...[
                                SizedBox(height: AppTheme.spacingMedium),
                                if (_compatibilityResult!.supportsESIM)
                                  Row(
                                    children: [
                                      Icon(Icons.check_circle, color: AppTheme.successColor, size: AppTheme.iconSizeSmall),
                                      SizedBox(width: AppTheme.spacingSmall),
                                      Expanded(
                                        child: Text('Supports eSIM', style: AppTheme.bodyStyle),
                                      ),
                                    ],
                                  ),
                                if (_compatibilityResult!.supportsESIM && _compatibilityResult!.supportsPhysicalSIM)
                                  SizedBox(height: AppTheme.spacingSmall),
                                if (_compatibilityResult!.supportsPhysicalSIM)
                                  Row(
                                    children: [
                                      Icon(Icons.check_circle, color: AppTheme.successColor, size: AppTheme.iconSizeSmall),
                                      SizedBox(width: AppTheme.spacingSmall),
                                      Expanded(
                                        child: Text('Supports Physical SIM', style: AppTheme.bodyStyle),
                                      ),
                                    ],
                                  ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: AppTheme.spacingItem),
                        Container(
                          width: double.infinity,
                          height: 50.0,
                          decoration: BoxDecoration(
                            gradient: AppTheme.blueGradient,
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusButton),
                          ),
                          child: ElevatedButton(
                            onPressed: _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.borderRadiusButton),
                              ),
                            ),
                            child: Text(
                              isCompatible ? 'Submit & Next' : 'Done',
                              style: AppTheme.buttonStyle,
                            ),
                          ),
                        ),
                      ],
                      
                      SizedBox(height: AppTheme.spacingLarge),
                      
                      // Instructions
                      Text(
                        'How to find your device\'s IMEI number',
                        style: AppTheme.sectionTitleStyle,
                      ),
                      SizedBox(height: AppTheme.spacingItem),
                      
                      // Tab Selection
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: Text('iOS', style: AppTheme.bodyStyle),
                              selected: _selectedTab == 0,
                              onSelected: (selected) {
                                if (selected) setState(() => _selectedTab = 0);
                              },
                              selectedColor: AppTheme.accentGold,
                              labelStyle: TextStyle(
                                color: _selectedTab == 0 ? Colors.white : AppTheme.appText,
                              ),
                            ),
                          ),
                          SizedBox(width: AppTheme.spacingItem),
                          Expanded(
                            child: ChoiceChip(
                              label: Text('Android', style: AppTheme.bodyStyle),
                              selected: _selectedTab == 1,
                              onSelected: (selected) {
                                if (selected) setState(() => _selectedTab = 1);
                              },
                              selectedColor: AppTheme.accentGold,
                              labelStyle: TextStyle(
                                color: _selectedTab == 1 ? Colors.white : AppTheme.appText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppTheme.spacingItem),
                      
                      // Instructions Text
                      if (_selectedTab == 0)
                        Text(
                          '1. To find your IMEI, go to Settings, General, About. You\'ll find your IMEI there. Alternatively, enter *#06# on your device\'s dialer to bring up the IMEI. If you see two IMEI numbers, enter either one to check device compatibility.',
                          style: AppTheme.bodyStyle,
                        )
                      else ...[
                        Text(
                          '1. To find your IMEI, open your Phone app and dial *#06#. Your IMEI will appear on the screen. You can also find it in Settings > About Phone.',
                          style: AppTheme.bodyStyle,
                        ),
                        SizedBox(height: AppTheme.spacingSmall),
                        TextButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const IMEIVideoSheet(),
                            );
                          },
                          icon: Icon(Icons.play_circle_outline, color: AppTheme.secondBlue),
                          label: Text(
                            'Watch Video Guide',
                            style: AppTheme.bodyStyle.copyWith(
                              color: AppTheme.secondBlue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: AppTheme.spacingItem),
                      
                      Divider(color: AppTheme.dividerColor),
                      SizedBox(height: AppTheme.spacingItem),
                      
                      Text(
                        'Can\'t find your IMEI?',
                        style: AppTheme.sectionTitleStyle,
                      ),
                      SizedBox(height: AppTheme.spacingSmall),
                      Text(
                        'You can skip the compatibility check, but just a heads-up — we can\'t promise everything will run smoothly if your device isn\'t compatible. Your call, but don\'t say we didn\'t warn you.',
                        style: AppTheme.bodyStyle,
                      ),
                      SizedBox(height: AppTheme.spacingSmall),
                      TextButton(
                        onPressed: () {
                          if (widget.onSubmitIMEI != null && _imeiDigits.isNotEmpty) {
                            widget.onSubmitIMEI!(_imeiDigits, null, null, null);
                          }
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Skip compatibility check',
                          style: AppTheme.bodyStyle.copyWith(color: AppTheme.accentGold),
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
}

// Video Sheet Widget
class IMEIVideoSheet extends StatefulWidget {
  const IMEIVideoSheet({super.key});

  @override
  State<IMEIVideoSheet> createState() => _IMEIVideoSheetState();
}

class _IMEIVideoSheetState extends State<IMEIVideoSheet> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset('assets/imei_android.mp4');
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading video: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppTheme.appBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.borderRadiusCard)),
      ),
      child: Column(
        children: [
          // Drag indicator
          Container(
            margin: EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.paddingInput),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'IMEI Video Guide',
                    style: AppTheme.titleStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppTheme.accentGold),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          
          // Video Content
          Expanded(
            child: Center(
              child: _hasError
                  ? Padding(
                      padding: EdgeInsets.all(AppTheme.spacingLarge),
                      child: Text(
                        'Video not found. Make sure imei_android.mp4 is added to your app assets.',
                        style: AppTheme.bodyStyle.copyWith(color: AppTheme.errorColor),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : _isInitialized && _controller != null
                      ? AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: Container(
                            margin: EdgeInsets.all(AppTheme.spacingMedium),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppTheme.borderRadiusCard),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: VideoPlayer(_controller!),
                          ),
                        )
                      : CircularProgressIndicator(
                          color: AppTheme.accentGold,
                        ),
            ),
          ),
          
          // Play/Pause Controls
          if (_isInitialized && _controller != null && !_hasError)
            Container(
              padding: EdgeInsets.all(AppTheme.spacingMedium),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: AppTheme.accentGold,
                      size: 40,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_controller!.value.isPlaying) {
                          _controller!.pause();
                        } else {
                          _controller!.play();
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
