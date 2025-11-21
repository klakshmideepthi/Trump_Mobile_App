import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_registration_view_model.dart';
import '../../providers/navigation_state.dart';
import '../../services/firebase_order_manager.dart';
import '../../widgets/step_navigation_container.dart';
import '../../widgets/order_step_header.dart';
import '../../utils/theme.dart';

class SimSelectionView extends StatefulWidget {
  final int currentStep;
  final Function(int) onStepChanged;

  const SimSelectionView({
    super.key,
    required this.currentStep,
    required this.onStepChanged,
  });

  @override
  State<SimSelectionView> createState() => _SimSelectionViewState();
}

class _SimSelectionViewState extends State<SimSelectionView> {
  String? _selectedSimType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    // Map viewModel.simType to internal format
    if (viewModel.simType == 'eSIM') {
      _selectedSimType = 'esim';
    } else if (viewModel.simType == 'Physical') {
      _selectedSimType = 'physical';
    }
    
    // Auto-select if only one option is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSelectSimType();
    });
  }

  void _autoSelectSimType() {
    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    final supportsESIM = viewModel.supportsESIM;
    final supportsPhysicalSIM = viewModel.supportsPhysicalSIM;
    
    if (supportsESIM && !supportsPhysicalSIM && _selectedSimType != 'esim') {
      setState(() {
        _selectedSimType = 'esim';
      });
    } else if (!supportsESIM && supportsPhysicalSIM && _selectedSimType != 'physical') {
      setState(() {
        _selectedSimType = 'physical';
      });
    }
  }

  Future<void> _handleNext() async {
    if (_selectedSimType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a SIM type'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    // Map internal format to viewModel format
    viewModel.simType = _selectedSimType == 'esim' ? 'eSIM' : 'Physical';

    // Save to Firebase
    if (viewModel.userId != null && viewModel.orderId != null) {
      await FirebaseOrderManager().saveStepProgress(
        userId: viewModel.userId!,
        orderId: viewModel.orderId!,
        step: 3,
        data: {'simType': viewModel.simType},
      );
    }

    setState(() {
      _isSaving = false;
    });

    // Move to next step which will show SIM setup
    if (mounted) {
      widget.onStepChanged(4);
    }
  }

  void _handleBack() {
    widget.onStepChanged(2);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<UserRegistrationViewModel>(context);
    final supportsESIM = viewModel.supportsESIM;
    final supportsPhysicalSIM = viewModel.supportsPhysicalSIM;
    final deviceIsCompatible = viewModel.deviceIsCompatible;

    return StepNavigationContainer(
      currentStep: widget.currentStep,
      totalSteps: 6,
      nextButtonText: 'Next Step',
      nextButtonAction: _handleNext,
      backButtonAction: _handleBack,
      cancelAction: () {
        final navigationState = Provider.of<NavigationState>(context, listen: false);
        navigationState.navigateTo(Destination.startNewOrder);
        navigationState.setFooterTab(FooterTab.home);
        navigationState.orderStartStep = null;
        navigationState.currentOrderId = null;
        widget.onStepChanged(0);
      },
      nextButtonDisabled: _selectedSimType == null || _isSaving,
      isLoading: _isSaving,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header section - only show congratulations if device is compatible
            if (deviceIsCompatible) ...[
              const OrderStepHeader(
                title: 'CONGRATULATIONS!',
                subtitle: 'YOUR PHONE IS COMPATIBLE WITH OUR NETWORK.',
              ),
              SizedBox(height: AppTheme.spacingSection),
            ] else ...[
              const OrderStepHeader(
                title: 'Select SIM Type',
                subtitle: 'Choose your preferred SIM card option.',
              ),
              SizedBox(height: AppTheme.spacingSection),
            ],
            
            // Button section with vertical layout
            Column(
              children: [
                // eSIM option - only show if device supports eSIM
                if (supportsESIM) ...[
                  _buildSimButton(
                    text: 'I want eSIM',
                    isSelected: _selectedSimType == 'esim',
                    onTap: () {
                      setState(() {
                        _selectedSimType = 'esim';
                      });
                    },
                  ),
                  SizedBox(height: AppTheme.spacingItem),
                ],
                
                // Physical SIM option - only show if device supports physical SIM
                if (supportsPhysicalSIM)
                  _buildSimButton(
                    text: 'I want Physical SIM card',
                    isSelected: _selectedSimType == 'physical',
                    onTap: () {
                      setState(() {
                        _selectedSimType = 'physical';
                      });
                    },
                  ),
              ],
            ),
            SizedBox(height: AppTheme.spacingSection),

            // Explanatory text with bullet points
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBulletPoint(
                  'eSIM is an easy way to activate service electronically. After you place your order, you\'ll see a QR code on-screen, in your confirmation email, and in your Account Dashboard. Scan it with your phone\'s camera to download the eSIM and start Telgoo5 Mobile service immediately.',
                ),
                SizedBox(height: AppTheme.spacingItem),
                _buildBulletPoint(
                  'Some older phones don\'t support eSIMs. In those cases, we\'ll ship a physical SIM kit the next business day via USPS First Class Mail.',
                ),
                SizedBox(height: AppTheme.spacingItem),
                _buildBulletPoint(
                  'Many phones support both eSIMs and physical SIMs. You can choose either, but eSIM is the preferred option for instant delivery.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: AppTheme.accentGold,
            width: 2,
          ),
          gradient: isSelected
              ? AppTheme.blueGradient
              : null,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 18,
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
        const Text(
          '•',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

