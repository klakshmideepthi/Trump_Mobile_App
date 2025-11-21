import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_registration_view_model.dart';
import '../../services/firebase_order_manager.dart';
import '../../widgets/step_navigation_container.dart';
import '../../widgets/gradient_button.dart';
import '../../utils/theme.dart';
import 'sim_setup_view.dart';
import 'porting_view.dart';

class NumberPortingView extends StatefulWidget {
  final int currentStep;
  final Function(int) onStepChanged;

  const NumberPortingView({
    super.key,
    required this.currentStep,
    required this.onStepChanged,
  });

  @override
  State<NumberPortingView> createState() => _NumberPortingViewState();
}

class _NumberPortingViewState extends State<NumberPortingView> {
  bool _isCompleting = false;
  bool _showPortingView = false;
  bool _showSimSetup = false;
  bool _isPortingFormValid = false;
  bool _isSimSetupFormValid = false; // Track SIM setup form validity
  bool _qrCodeAlreadyShown = false; // Track if QR code was already shown
  final GlobalKey _portingViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    print('[NumberPortingView] initState called');
    _checkFlow();
  }

  Future<void> _checkFlow() async {
    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    
    print('[NumberPortingView] _checkFlow started');
    print('[NumberPortingView] userId: ${viewModel.userId}');
    print('[NumberPortingView] orderId: ${viewModel.orderId}');
    print('[NumberPortingView] numberType from viewModel: "${viewModel.numberType}"');
    print('[NumberPortingView] simType from viewModel: "${viewModel.simType}"');
    print('[NumberPortingView] portInSkipped from viewModel: ${viewModel.portInSkipped}');
    
    // First, try to get data from order if viewModel is not populated yet
    if (viewModel.userId != null && viewModel.orderId != null) {
      print('[NumberPortingView] Fetching order data...');
      final orderManager = FirebaseOrderManager();
      final orderData = await orderManager.fetchOrderDocument(viewModel.userId!, viewModel.orderId!);
      
      if (orderData != null) {
        print('[NumberPortingView] Order data fetched successfully');
        print('[NumberPortingView] Order data keys: ${orderData.keys.toList()}');
        
        // Update viewModel with order data if it's missing
        final numberTypeFromOrder = orderData['numberType'] ?? '';
        final simTypeFromOrder = orderData['simType'] ?? '';
        final portInSkippedFromOrder = orderData['portInSkipped'] ?? false;
        final billingCompleted = orderData['billingCompleted'] ?? false;
        
        print('[NumberPortingView] numberType from order: "$numberTypeFromOrder"');
        print('[NumberPortingView] simType from order: "$simTypeFromOrder"');
        print('[NumberPortingView] portInSkipped from order: $portInSkippedFromOrder');
        print('[NumberPortingView] billingCompleted from order: $billingCompleted');
        
        if (numberTypeFromOrder.isNotEmpty && viewModel.numberType.isEmpty) {
          print('[NumberPortingView] Updating viewModel.numberType from "$viewModel.numberType" to "$numberTypeFromOrder"');
          viewModel.numberType = numberTypeFromOrder;
        }
        if (simTypeFromOrder.isNotEmpty && viewModel.simType.isEmpty) {
          print('[NumberPortingView] Updating viewModel.simType from "$viewModel.simType" to "$simTypeFromOrder"');
          viewModel.simType = simTypeFromOrder;
        }
        if (!viewModel.portInSkipped && portInSkippedFromOrder) {
          print('[NumberPortingView] Updating viewModel.portInSkipped from $viewModel.portInSkipped to $portInSkippedFromOrder');
          viewModel.portInSkipped = portInSkippedFromOrder;
        }
        
        // Determine which view to show
        final shouldShowPorting = numberTypeFromOrder == 'Existing' && !portInSkippedFromOrder;
        
        print('[NumberPortingView] shouldShowPorting: $shouldShowPorting');
        print('[NumberPortingView] will show: ${shouldShowPorting ? "PortingView" : "SimSetupView"}');
        
        if (mounted) {
          setState(() {
            if (shouldShowPorting) {
              _showPortingView = true;
              _showSimSetup = false;
              print('[NumberPortingView] Set _showPortingView=true, _showSimSetup=false');
            } else {
              // For new numbers or skipped port-in, show SIM setup
              // Especially if billing is completed
              _showPortingView = false;
              _showSimSetup = true;
              _isSimSetupFormValid = true; // SimSetupView has no form fields, so always valid
              print('[NumberPortingView] Set _showPortingView=false, _showSimSetup=true');
            }
          });
        }
        
        return; // Exit early after handling from order data
      } else {
        print('[NumberPortingView] Order data is null');
      }
    } else {
      print('[NumberPortingView] userId or orderId is null, cannot fetch order data');
    }
    
    // Fallback: Use viewModel data if order fetch fails or not available
    print('[NumberPortingView] Using fallback: viewModel data');
    print('[NumberPortingView] viewModel.numberType: "${viewModel.numberType}"');
    print('[NumberPortingView] viewModel.portInSkipped: ${viewModel.portInSkipped}');
    
    if (viewModel.numberType == 'Existing' && !viewModel.portInSkipped) {
      print('[NumberPortingView] Fallback: Showing PortingView');
      if (mounted) {
        setState(() {
          _showPortingView = true;
          _showSimSetup = false;
        });
      }
    } else {
      print('[NumberPortingView] Fallback: Showing SimSetupView');
      // If skipped or not existing number, go directly to SIM setup
      if (mounted) {
        setState(() {
          _showPortingView = false;
          _showSimSetup = true;
          _isSimSetupFormValid = true; // SimSetupView has no form fields, so always valid
        });
      }
    }
  }

  Future<void> _handleComplete() async {
    setState(() {
      _isCompleting = true;
    });

    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    final success = await viewModel.completeOrder();
    
    setState(() {
      _isCompleting = false;
    });

    if (success && mounted) {
      // Navigate back to home
      widget.onStepChanged(0);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? 'Failed to complete order'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handlePortingContinue() async {
    // This is called when user clicks "Continue to SIM Setup" button
    // Trigger validation and save in PortingView
    // Access the state through the GlobalKey's currentState and use dynamic call
    final state = _portingViewKey.currentState;
    if (state != null) {
      // Use dynamic invocation to call validateAndSave on private state class
      try {
        final dynamic portingState = state;
        await portingState.validateAndSave();
      } catch (e) {
        // If method doesn't exist or fails, handle error
        print('Error calling validateAndSave: $e');
      }
    }
  }

  void _handleBack() async {
    // Check if billing is completed - if so, don't allow going back to steps 1-5
    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    if (viewModel.userId != null && viewModel.orderId != null) {
      final orderManager = FirebaseOrderManager();
      final orderData = await orderManager.fetchOrderDocument(viewModel.userId!, viewModel.orderId!);
      final billingCompleted = orderData?['billingCompleted'] ?? false;
      
      // If billing is completed, prevent going back to steps 1-5
      if (billingCompleted) {
        // Don't allow going back if billing is completed
        return;
      }
    }
    
    if (_showPortingView) {
      // If showing porting view, go back to step 5
      widget.onStepChanged(5);
    } else if (_showSimSetup) {
      // If showing SIM setup after porting, go back to porting view
      setState(() {
        _showSimSetup = false;
        _showPortingView = true;
      });
    } else {
      // Otherwise go back to step 5
      widget.onStepChanged(5);
    }
  }

  void _onPortingComplete() {
    setState(() {
      _showPortingView = false;
      _showSimSetup = true;
      _isSimSetupFormValid = true; // SimSetupView has no form fields, so always valid
    });
  }

  void _onPortingSkip() {
    // Navigate to home (step 0) when skip is pressed
    widget.onStepChanged(0);
  }

  Future<void> _onSimSetupComplete() async {
    // Show appropriate sheet - don't complete order yet
    // Order will be completed when user clicks "Return to Dashboard"
    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    
    // Show appropriate sheet based on SIM type and device selection
    // IMPORTANT: For eSIM, never show shipping sheet
    // Following TrumpMobile's SIMSetupView logic
    // simType is still available in viewModel since we haven't called completeOrder() yet
    
    // Check SIM type from viewModel (it will still be available since we haven't called completeOrder yet)
    final simType = viewModel.simType.trim().toLowerCase();
    final isESim = simType == 'esim';
    
    print('[NumberPortingView] SIM type check - isESim: $isESim, viewModel.simType: "${viewModel.simType}", isForThisDevice: ${viewModel.isForThisDevice}');
    
    if (isESim) {
      // For eSIM orders, check if it's for this device or another device
      // Default to false (Another Device) if not explicitly set to true
      if (viewModel.isForThisDevice == true) {
        // Show activation sheet for "This Device"
        print('[NumberPortingView] Showing activation sheet for eSIM - This Device');
        _showActivationSheet();
      } else {
        // Show QR code sheet for "Another Device" 
        // This handles the case when coming from billing completion (card setup view)
        print('[NumberPortingView] Showing QR code sheet for eSIM - Another Device');
        _showQRCodeSheet();
      }
    } else {
      // Show shipping sheet ONLY for Physical SIM
      print('[NumberPortingView] Showing shipping sheet for Physical SIM');
      _showShippingSheet();
    }
  }

  Future<void> _handleReturnToDashboard() async {
    // Complete the order when user clicks "Return to Dashboard"
    setState(() {
      _isCompleting = true;
    });

    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    
    // Check if billing is completed and port-in is pending
    if (viewModel.userId != null && viewModel.orderId != null) {
      final orderManager = FirebaseOrderManager();
      final orderData = await orderManager.fetchOrderDocument(viewModel.userId!, viewModel.orderId!);
      final billingCompleted = orderData?['billingCompleted'] ?? false;
      final isPortInOrder = viewModel.numberType == 'Existing';
      final portInSkipped = viewModel.portInSkipped;
      
      // If billing complete, port-in order, and port-in NOT skipped, mark as completed
      if (billingCompleted && isPortInOrder && !portInSkipped) {
        // Auto-complete the order by calling markOrderCompleted directly
        await orderManager.markOrderCompleted(viewModel.userId!, viewModel.orderId!);
      }
    }
    
    final success = await viewModel.completeOrder();
    
    setState(() {
      _isCompleting = false;
    });

    if (success && mounted) {
      // Navigate back to home
      widget.onStepChanged(0);
    } else if (mounted) {
      // Still navigate even if there's an error, but show the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? 'Failed to complete order'),
          backgroundColor: Colors.red,
        ),
      );
      widget.onStepChanged(0);
    }
  }

  void _onFormValidityChanged(bool isValid) {
    setState(() {
      _isPortingFormValid = isValid;
    });
  }

  void _onSimSetupFormValidityChanged(bool isValid) {
    setState(() {
      _isSimSetupFormValid = isValid;
    });
  }

  void _resetQRCodeShown() {
    setState(() {
      _qrCodeAlreadyShown = false;
    });
  }

  void _showQRCodeSheet() {
    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    _qrCodeAlreadyShown = true; // Mark that QR code was shown
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QRCodeSheet(
        viewModel: viewModel,
        onReturn: () {
          Navigator.of(context).pop();
          // Complete order and navigate back to home
          _handleReturnToDashboard();
        },
      ),
    );
  }

  void _showActivationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ActivationSheet(
        onReturn: () {
          Navigator.of(context).pop();
          // Complete order and navigate back to home
          _handleReturnToDashboard();
        },
      ),
    );
  }

  void _showShippingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ShippingSheet(
        onReturn: () {
          Navigator.of(context).pop();
          // Complete order and navigate back to home
          _handleReturnToDashboard();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<UserRegistrationViewModel>(context);
    
    print('[NumberPortingView] build() called');
    print('[NumberPortingView] _showPortingView: $_showPortingView');
    print('[NumberPortingView] _showSimSetup: $_showSimSetup');
    print('[NumberPortingView] viewModel.simType: "${viewModel.simType}"');
    print('[NumberPortingView] viewModel.numberType: "${viewModel.numberType}"');
    
    // Determine next button text and action
    String nextButtonText = 'Complete Order';
    VoidCallback? nextButtonAction;
    bool nextButtonDisabled = _isCompleting;

    if (_showPortingView) {
      nextButtonText = 'Continue to SIM Setup';
      nextButtonAction = _handlePortingContinue;
      nextButtonDisabled = _isCompleting || !_isPortingFormValid;
      print('[NumberPortingView] Button config: PortingView mode');
    } else if (_showSimSetup) {
      nextButtonText = 'Complete Order';
      nextButtonAction = _onSimSetupComplete;
      nextButtonDisabled = _isCompleting || !_isSimSetupFormValid;
      print('[NumberPortingView] Button config: SimSetupView mode');
    } else {
      print('[NumberPortingView] Button config: Default mode (no view selected yet)');
    }

    Widget childWidget;
    if (_showPortingView && !_showSimSetup) {
      print('[NumberPortingView] Rendering: PortingView');
      childWidget = PortingView(
        key: _portingViewKey,
        onPortingComplete: _onPortingComplete,
        onPortingSkip: _onPortingSkip,
        onFormValidityChanged: _onFormValidityChanged,
      );
    } else if (_showSimSetup || viewModel.simType.isNotEmpty) {
      print('[NumberPortingView] Rendering: SimSetupView (without container)');
      childWidget = SimSetupView(
        currentStep: widget.currentStep,
        onStepChanged: widget.onStepChanged,
        wrapInContainer: false, // Don't wrap in container since NumberPortingView already has one
      );
    } else {
      print('[NumberPortingView] Rendering: LoadingIndicator (waiting for data)');
      childWidget = const Center(
        child: CircularProgressIndicator(),
      );
    }

    return StepNavigationContainer(
      currentStep: widget.currentStep,
      totalSteps: 6,
      nextButtonText: nextButtonText,
      nextButtonAction: nextButtonAction ?? () {},
      backButtonAction: _handleBack,
      cancelAction: null, // Step 6 has no cancel button
      nextButtonDisabled: nextButtonDisabled,
      isLoading: _isCompleting,
      child: childWidget,
    );
  }
}

// QR Code Sheet Widget
class _QRCodeSheet extends StatelessWidget {
  final UserRegistrationViewModel viewModel;
  final VoidCallback onReturn;

  const _QRCodeSheet({
    required this.viewModel,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.appBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'eSIM QR Code',
              style: AppTheme.sectionTitleStyle,
            ),
            SizedBox(height: 16),
            Text(
              'Scan this QR code with your other device to activate the eSIM',
              textAlign: TextAlign.center,
              style: AppTheme.bodyStyle,
            ),
            SizedBox(height: 24),
            
            // QR Code Image
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/esim_qr_code.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            SizedBox(height: 16),
            Text(
              'Order #: ${viewModel.orderId ?? "N/A"}',
              style: AppTheme.bodySmallStyle,
            ),
            
            SizedBox(height: 24),
            
            // Setup Instructions
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Setup Instructions:',
                    style: AppTheme.bodyStyle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildInstructionStep(1, 'Open Camera app on your other device'),
                  _buildInstructionStep(2, 'Point camera at this QR code'),
                  _buildInstructionStep(3, 'Tap the notification to add cellular plan'),
                  _buildInstructionStep(4, 'Follow the prompts to complete activation'),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            GradientButton(
              text: 'Return to Dashboard',
              onPressed: onReturn,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(int number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.accentGold,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodySmallStyle,
            ),
          ),
        ],
      ),
    );
  }
}

// Activation Sheet Widget (for "This Device")
class _ActivationSheet extends StatelessWidget {
  final VoidCallback onReturn;

  const _ActivationSheet({
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.appBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 56,
            color: AppTheme.accentGold,
          ),
          SizedBox(height: 16),
          Text(
            'Activated on This Device',
            style: AppTheme.sectionTitleStyle,
          ),
          SizedBox(height: 16),
          Text(
            'Your eSIM has been successfully activated on this device.',
            textAlign: TextAlign.center,
            style: AppTheme.bodyStyle,
          ),
          SizedBox(height: 24),
          GradientButton(
            text: 'Return to Dashboard',
            onPressed: onReturn,
          ),
        ],
      ),
    );
  }
}

// Shipping Sheet Widget (for Physical SIM)
class _ShippingSheet extends StatelessWidget {
  final VoidCallback onReturn;

  const _ShippingSheet({
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.appBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_shipping,
            size: 56,
            color: AppTheme.accentGold,
          ),
          SizedBox(height: 16),
          Text(
            'Order Complete',
            style: AppTheme.sectionTitleStyle,
          ),
          SizedBox(height: 16),
          Text(
            'Your order is complete. Your physical SIM will be shipped shortly.',
            textAlign: TextAlign.center,
            style: AppTheme.bodyStyle,
          ),
          SizedBox(height: 24),
          GradientButton(
            text: 'Return to Dashboard',
            onPressed: onReturn,
          ),
        ],
      ),
    );
  }
}

