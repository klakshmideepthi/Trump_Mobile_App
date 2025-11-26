import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/user_registration_view_model.dart';
import '../../utils/validators.dart';
import '../../utils/theme.dart';
import '../../widgets/order_step_header.dart';
import '../../utils/formatters.dart';
import '../../services/firebase_order_manager.dart';

class PortingView extends StatefulWidget {
  final VoidCallback onPortingComplete;
  final VoidCallback? onPortingSkip;
  final Function(bool)? onFormValidityChanged;
  final VoidCallback? onContinuePressed;

  const PortingView({
    super.key,
    required this.onPortingComplete,
    this.onPortingSkip,
    this.onFormValidityChanged,
    this.onContinuePressed,
  });

  @override
  State<PortingView> createState() => _PortingViewState();
}

class _PortingViewState extends State<PortingView> {
  final _formKey = GlobalKey<FormState>();
  final _phoneNumberController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _pinController = TextEditingController();
  final _accountHolderController = TextEditingController();
  bool _isSaving = false;
  bool _isFormValid = false;
  String? _selectedCarrier;

  // Predefined carrier options (matching Trump Mobile)
  final List<String> _carrierOptions = [
    'Verizon',
    'AT&T',
    'T-Mobile',
    'Sprint',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    _phoneNumberController.text = viewModel.selectedPhoneNumber;
    _accountNumberController.text = viewModel.portInAccountNumber;
    _pinController.text = viewModel.portInPin;
    _selectedCarrier = viewModel.portInCurrentCarrier.isNotEmpty 
        ? viewModel.portInCurrentCarrier 
        : null;
    _accountHolderController.text = viewModel.portInAccountHolderName;
    // Defer form validity notification until after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
    widget.onFormValidityChanged?.call(_checkFormValidity());
      }
    });
  }

  bool _checkFormValidity() {
    return _phoneNumberController.text.trim().isNotEmpty &&
        _accountHolderController.text.trim().isNotEmpty &&
        _selectedCarrier != null &&
        _accountNumberController.text.trim().isNotEmpty &&
        _pinController.text.trim().isNotEmpty;
  }

  void _updateFormValidity() {
    final isValid = _checkFormValidity();
    setState(() {
      _isFormValid = isValid;
    });
    widget.onFormValidityChanged?.call(isValid);
  }

  Future<bool> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    if (_selectedCarrier == null || _selectedCarrier!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a carrier'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    setState(() {
      _isSaving = true;
    });

    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    viewModel.selectedPhoneNumber = _phoneNumberController.text.trim();
    viewModel.portInAccountNumber = _accountNumberController.text.trim();
    viewModel.portInPin = _pinController.text.trim();
    viewModel.portInCurrentCarrier = _selectedCarrier!;
    viewModel.portInAccountHolderName = _accountHolderController.text.trim();
    viewModel.portInSkipped = false;

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('💾 VALIDATING PORT-IN INFORMATION');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('   Phone Number: ${viewModel.selectedPhoneNumber}');
    print('   Account Number: ${viewModel.portInAccountNumber}');
    print('   PIN: ${viewModel.portInPin}');
    print('   Carrier: ${viewModel.portInCurrentCarrier}');
    print('   Account Holder: ${viewModel.portInAccountHolderName}');
    print('   Port-In Skipped: ${viewModel.portInSkipped}');
    print('   Number Type: ${viewModel.numberType}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // For port-in orders, don't save to Firebase yet - wait for APIs to succeed
    // Just validate and save to viewModel (already done above)
    // Parent will handle Firebase save and navigation after APIs succeed
    
    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      print('✅ Port-in information validated successfully');
      // Don't call onPortingComplete here - parent will call after APIs succeed
      return true;
    }
    return false;
  }

  Future<void> _handleSkip() async {
    setState(() {
      _isSaving = true;
    });

    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    viewModel.portInSkipped = true;

    final success = await viewModel.saveNumberSelection();
    
    // Mark order as pending port-in when user skips
    if (success && viewModel.userId != null && viewModel.orderId != null) {
      final orderManager = FirebaseOrderManager();
      await orderManager.markOrderPendingPortIn(viewModel.userId!, viewModel.orderId!);
    }
    
    setState(() {
      _isSaving = false;
    });

    if (success && mounted) {
      if (widget.onPortingSkip != null) {
        widget.onPortingSkip!();
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? 'Failed to save skip porting information'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _accountNumberController.dispose();
    _pinController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  // Expose form validity to parent widget
  bool getFormValidity() {
    return _checkFormValidity();
  }

  // Method to validate and save (called from parent)
  // Returns true if validation and save succeeded, false otherwise
  Future<bool> validateAndSave() async {
    // Call _handleSave which does all validation and saving
    final success = await _handleSave();
    if (!success) {
      // Form validation failed - show message if not already shown
      if (_formKey.currentState?.validate() ?? true) {
        // Validation passed but save failed, error already shown
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all required fields correctly'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    return success;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              OrderStepHeader(
                title: 'Transfer Your Existing Number',
                subtitle: 'Please provide the following information from your current carrier:',
              ),
              SizedBox(height: AppTheme.spacingSection),
              
              // Phone Number to Transfer
              TextFormField(
                controller: _phoneNumberController,
                decoration: AppTheme.inputDecoration('Phone Number to Transfer'),
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneNumberFormatter()],
                validator: (value) => Validators.required(value, fieldName: 'Phone number to transfer'),
                onChanged: (_) {
                  setState(() {});
                  _updateFormValidity();
                },
              ),
              SizedBox(height: AppTheme.spacingItem),
              
              // Account Holder Name
              TextFormField(
                controller: _accountHolderController,
                decoration: AppTheme.inputDecoration('Account Holder Name'),
                validator: (value) => Validators.required(value, fieldName: 'Account holder name'),
                onChanged: (_) {
                  setState(() {});
                  _updateFormValidity();
                },
              ),
              SizedBox(height: AppTheme.spacingItem),
              
              // Current Carrier Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCarrier,
                decoration: AppTheme.inputDecoration('Current Carrier'),
                items: _carrierOptions.map((carrier) {
                  return DropdownMenuItem(
                    value: carrier,
                    child: Text(carrier),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCarrier = value;
                  });
                  _updateFormValidity();
                },
                validator: (value) => Validators.required(value, fieldName: 'Current carrier'),
              ),
              SizedBox(height: AppTheme.spacingItem),
              
              // Account Number
              TextFormField(
                controller: _accountNumberController,
                decoration: AppTheme.inputDecoration('Account Number'),
                validator: (value) => Validators.required(value, fieldName: 'Account number'),
                onChanged: (_) {
                  setState(() {});
                  _updateFormValidity();
                },
              ),
              SizedBox(height: AppTheme.spacingItem),
              
              // Account PIN/Password
              TextFormField(
                controller: _pinController,
                decoration: AppTheme.inputDecoration('Account PIN/Password'),
                keyboardType: TextInputType.number,
                obscureText: true,
                validator: (value) => Validators.required(value, fieldName: 'Account PIN/Password'),
                onChanged: (_) {
                  setState(() {});
                  _updateFormValidity();
                },
              ),
              SizedBox(height: AppTheme.spacingSection),
          
              // Important Information box
              Container(
                padding: EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  color: AppTheme.yellowAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusCard),
                  border: Border.all(
                    color: AppTheme.yellowAccent.withOpacity(0.3),
                    width: AppTheme.borderWidthDefault,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: AppTheme.yellowAccent,
                          size: 20,
                        ),
                        SizedBox(width: AppTheme.spacingSmall),
                        Text(
                          'Important Information:',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeBodySmall,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.appText,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacingSmall),
                    _buildBulletPoint('Do NOT cancel your current service until the transfer is complete'),
                    _buildBulletPoint('Transfer typically takes 4-24 hours for wireless numbers'),
                    _buildBulletPoint('Keep your current phone active during the transfer process'),
                    _buildBulletPoint('Ensure all information matches exactly with your current carrier'),
                  ],
                ),
              ),
              SizedBox(height: AppTheme.spacingSection),
              
              // Note: Continue button is handled by parent NumberPortingView
              // The parent shows "Continue to SIM Setup" button which validates and saves
              
              SizedBox(height: AppTheme.spacingItem),
              
              // Skip for Now button (matching Trump Mobile styling)
              OutlinedButton(
                onPressed: _isSaving ? null : _handleSkip,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.paddingButtonHorizontal,
                    vertical: AppTheme.paddingButtonVertical,
                  ),
                  side: BorderSide(
                    color: AppTheme.textSecondary.withOpacity(0.3),
                    width: AppTheme.borderWidthDefault,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusInput),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Skip for Now',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeBodySmall,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    SizedBox(width: AppTheme.spacingSmall),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spacingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: AppTheme.fontSizeCaption,
              color: AppTheme.appText,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: AppTheme.fontSizeCaption,
                color: AppTheme.appText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

