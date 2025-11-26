import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_registration_view_model.dart';
import '../../providers/navigation_state.dart';
import '../../services/firebase_order_manager.dart';
import '../../services/vcare_api_manager.dart';
import '../../widgets/step_navigation_container.dart';
import '../../widgets/order_step_header.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../utils/theme.dart';

class BillingInfoView extends StatefulWidget {
  final int currentStep;
  final Function(int) onStepChanged;

  const BillingInfoView({
    super.key,
    required this.currentStep,
    required this.onStepChanged,
  });

  @override
  State<BillingInfoView> createState() => _BillingInfoViewState();
}

class _BillingInfoViewState extends State<BillingInfoView> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _billingAddressController = TextEditingController();
  bool _isSaving = false;
  bool _useShippingAddress = true;
  bool _sameAsCustomerAddressEmergency = true;
  bool _e911Agreement = false;
  bool _recurringChargeAgreement = false;
  bool _privacyTermsAgreement = false;
  bool _showBroadbandFacts = false;
  
  // Plan information state
  String _planName = 'Telgoo5 Mobile Plan';
  double _planPrice = 47.45;
  bool _isLoadingPlanInfo = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadPlanInfo();
  }

  void _loadData() {
    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    _cardNumberController.text = viewModel.creditCardNumber;
    _billingAddressController.text = viewModel.address;
    if (viewModel.address.isEmpty && viewModel.street.isNotEmpty) {
      _billingAddressController.text = '${viewModel.street}, ${viewModel.city}, ${viewModel.state} ${viewModel.zip}';
      _useShippingAddress = true;
    }
  }

  Future<void> _loadPlanInfo() async {
    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    if (viewModel.orderId == null || viewModel.userId == null) return;
    
    setState(() {
      _isLoadingPlanInfo = true;
    });
    
    try {
      final orderManager = FirebaseOrderManager();
      final orderData = await orderManager.fetchOrderDocument(
        viewModel.userId!,
        viewModel.orderId!,
      );
      
      if (orderData != null && mounted) {
        setState(() {
          if (orderData['planName'] != null) {
            _planName = orderData['planName'].toString();
          }
          
          // Handle planPrice - can be Int or Double
          if (orderData['planPrice'] != null) {
            if (orderData['planPrice'] is int) {
              _planPrice = (orderData['planPrice'] as int).toDouble();
            } else if (orderData['planPrice'] is double) {
              _planPrice = orderData['planPrice'] as double;
            }
          } else if (orderData['amount'] != null) {
            _planPrice = (orderData['amount'] as num).toDouble();
          }
        });
      }
    } catch (e) {
      // Continue with default values
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPlanInfo = false;
        });
      }
    }
  }

  Widget _buildPricingSection() {
    final tax = _planPrice * 0.07;
    final total = _planPrice + tax;

    return Container(
      padding: EdgeInsets.all(AppTheme.paddingCard),
      decoration: BoxDecoration(
        color: AppTheme.disabledBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildPricingRow('Plan', _planName, isBold: false),
          _buildPricingRow('Plan Price', '\$${_planPrice.toStringAsFixed(2)}', isBold: false),
          _buildPricingRow('Plan Tax', '\$${tax.toStringAsFixed(2)}', isBold: false),
          Divider(),
          _buildPricingRow('Total', '\$${total.toStringAsFixed(2)}', isBold: true),
        ],
      ),
    );
  }

  Widget _buildPricingRow(String label, String value, {required bool isBold}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodyStyle.copyWith(
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: AppTheme.bodyStyle.copyWith(
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card Number
        TextFormField(
          controller: _cardNumberController,
          decoration: AppTheme.inputDecoration('Card Number'),
          keyboardType: TextInputType.number,
          inputFormatters: [CreditCardFormatter()],
          validator: Validators.creditCard,
        ),
        SizedBox(height: AppTheme.spacingItem),
        // Expiry and CVV
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expiryController,
                decoration: AppTheme.inputDecoration('MM/YY'),
                keyboardType: TextInputType.number,
                inputFormatters: [ExpiryDateFormatter()],
                validator: Validators.expiryDate,
              ),
            ),
            SizedBox(width: AppTheme.spacingItem),
            Expanded(
              child: TextFormField(
                controller: _cvvController,
                decoration: AppTheme.inputDecoration('CVV'),
                keyboardType: TextInputType.number,
                obscureText: true,
                validator: Validators.cvv,
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacingItem),
        CheckboxListTile(
          title: Text('Same as Shipping Address', style: AppTheme.bodyStyle),
          value: _useShippingAddress,
          onChanged: (value) {
            setState(() {
              _useShippingAddress = value ?? true;
            });
          },
        ),
        if (!_useShippingAddress) ...[
          SizedBox(height: AppTheme.spacingItem),
          TextFormField(
            controller: _billingAddressController,
            decoration: AppTheme.inputDecoration('Billing Address *'),
            maxLines: 2,
            validator: (value) => Validators.required(value, fieldName: 'Billing address'),
          ),
        ],
      ],
    );
  }

  Widget _buildEmergencyAddressSection() {
    return Container(
      padding: EdgeInsets.all(AppTheme.paddingCard),
      decoration: BoxDecoration(
        color: AppTheme.disabledBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emergency 911 Address (required for Wi‑Fi Calling)',
            style: AppTheme.sectionTitleStyle.copyWith(
              fontSize: AppTheme.fontSizeBody,
            ),
          ),
          SizedBox(height: AppTheme.spacingSmall),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Same as Shipping Address', style: AppTheme.bodyStyle),
            value: _sameAsCustomerAddressEmergency,
            onChanged: (value) {
              setState(() {
                _sameAsCustomerAddressEmergency = value ?? true;
              });
            },
          ),
          SizedBox(height: AppTheme.spacingSmall),
          // Agreements inside the box
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              'I confirm the address provided is my E911 address for first responders in an emergency.',
              style: AppTheme.captionStyle,
            ),
            value: _e911Agreement,
            onChanged: (value) {
              setState(() {
                _e911Agreement = value ?? false;
              });
            },
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              'I authorize Telgoo5 Mobile LLC to charge my card on a recurring basis. You can cancel any time to stop future charges.',
              style: AppTheme.captionStyle,
            ),
            value: _recurringChargeAgreement,
            onChanged: (value) {
              setState(() {
                _recurringChargeAgreement = value ?? false;
              });
            },
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              'I agree to the Privacy Policy and Terms of Use.',
              style: AppTheme.captionStyle,
            ),
            value: _privacyTermsAgreement,
            onChanged: (value) {
              setState(() {
                _privacyTermsAgreement = value ?? false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBroadbandFactsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BROADBAND FACTS',
              style: AppTheme.bodyStyle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  _showBroadbandFacts = !_showBroadbandFacts;
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppTheme.accentGold,
                  ),
                  SizedBox(width: 4),
                  Icon(
                    _showBroadbandFacts ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: AppTheme.accentGold,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_showBroadbandFacts) ...[
          SizedBox(height: AppTheme.spacingItem),
          Container(
            padding: EdgeInsets.all(AppTheme.paddingCard),
            decoration: BoxDecoration(
              color: AppTheme.disabledBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // First row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mobile Broadband Consumer Disclosure',
                            style: AppTheme.bodySmallStyle.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Monthly Price: \$${_planPrice.toStringAsFixed(2)}',
                            style: AppTheme.captionStyle,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Not an introductory rate and does not require a contract.',
                            style: AppTheme.captionStyle.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: AppTheme.spacingItem),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Speeds Provided with Plan',
                            style: AppTheme.bodySmallStyle.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Typical Download: 10-50 Mbps',
                            style: AppTheme.captionStyle,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Typical Upload Speed: 1-10 Mbps',
                            style: AppTheme.captionStyle,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Typical Latency: 19-37 ms',
                            style: AppTheme.captionStyle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(height: AppTheme.spacingSection),
                // Second row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Provider Monthly Fees',
                            style: AppTheme.bodySmallStyle.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'One-Time Fee: \$0',
                            style: AppTheme.captionStyle,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Device Connection Charge: \$0',
                            style: AppTheme.captionStyle,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Early Termination Fee: \$0',
                            style: AppTheme.captionStyle,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Government Taxes: Varies by Location',
                            style: AppTheme.captionStyle,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: AppTheme.spacingItem),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unlimited Data Included with Monthly Price',
                            style: AppTheme.bodySmallStyle.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'With first 20GB at high speed',
                            style: AppTheme.captionStyle,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Charges for Additional Data Usage: \$0',
                            style: AppTheme.captionStyle,
                          ),
                          SizedBox(height: 4),
                          Text(
                            '*Residential, non-commercial use only.',
                            style: AppTheme.captionStyle.copyWith(
                              color: AppTheme.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_e911Agreement || !_recurringChargeAgreement || !_privacyTermsAgreement) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept all agreements')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    viewModel.creditCardNumber = _cardNumberController.text;
    viewModel.billingDetails = 'Expiry: ${_expiryController.text}, CVV: ***';
    viewModel.address = _useShippingAddress
        ? '${viewModel.street}, ${viewModel.city}, ${viewModel.state} ${viewModel.zip}'
        : _billingAddressController.text;

    final success = await viewModel.saveBillingInfo();
    
    // Save step progress to Firestore (matching TrumpMobile behavior)
    if (success && viewModel.userId != null && viewModel.orderId != null) {
      final orderManager = FirebaseOrderManager();
      await orderManager.saveStepProgress(
        userId: viewModel.userId!,
        orderId: viewModel.orderId!,
        step: 5,
      );
      
      // After payment is completed, call create_customer_prepaid_multiline API
      await _createCustomerOrder(viewModel.userId!, viewModel.orderId!, viewModel);
      
      // If this is a porting order, mark as pending port-in instead of completed
      final isPortingOrder = viewModel.numberType == 'Existing';
      if (isPortingOrder) {
        await orderManager.markOrderPendingPortIn(viewModel.userId!, viewModel.orderId!);
      }
    }
    
    setState(() {
      _isSaving = false;
    });

    if (success && mounted) {
      widget.onStepChanged(6);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? 'Failed to save billing info'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _createCustomerOrder(String userId, String orderId, UserRegistrationViewModel viewModel) async {
    try {
      // Fetch order document to get enrollment_id, plan_id, and other data
      final orderManager = FirebaseOrderManager();
      final orderData = await orderManager.fetchOrderDocument(userId, orderId);
      
      if (orderData == null) {
        print('❌ Order document not found');
        return;
      }

      // Extract required data from order
      final enrollmentId = orderData['enrollment_id'] as String?;
      if (enrollmentId == null || enrollmentId.isEmpty) {
        print('❌ Missing enrollment_id in order document');
        return;
      }

      // Get plan_id - can be Int or String
      int? planId;
      if (orderData['plan_id'] is int) {
        planId = orderData['plan_id'] as int;
      } else if (orderData['plan_id'] is String) {
        planId = int.tryParse(orderData['plan_id'] as String);
      }

      if (planId == null) {
        print('❌ Missing plan_id in order document');
        return;
      }

      // Get order_id from payment (if available)
      // Try different possible field names
      int? paymentOrderId;
      if (orderData['payment_order_id'] is int) {
        paymentOrderId = orderData['payment_order_id'] as int;
      } else if (orderData['order_id'] is int) {
        paymentOrderId = orderData['order_id'] as int;
      } else if (orderData['payment_order_id'] is String) {
        paymentOrderId = int.tryParse(orderData['payment_order_id'] as String);
      } else if (orderData['order_id'] is String) {
        paymentOrderId = int.tryParse(orderData['order_id'] as String);
      }

      // Determine activation type
      final activationType = viewModel.numberType == 'Existing' ? 'PORTIN' : 'NEWACTIVATION';

      // Determine enrollment type (SHIPMENT or HANDOVER)
      final enrollmentType = viewModel.simType == 'eSIM' ? 'SHIPMENT' : 'SHIPMENT'; // eSIM always uses SHIPMENT

      // Determine is_esim
      final isEsim = viewModel.simType == 'eSIM' ? 'Y' : 'N';

      // Get carrier from order or use default
      final carrier = orderData['carrier'] as String? ?? 'TMBRLY';

      // Build customer info dictionary
      final customerInfo = <String, dynamic>{
        'activation_type': activationType,
        'enrollment_type': enrollmentType,
        'is_esim': isEsim,
        'carrier': carrier,
        'email': viewModel.email,
        'first_name': viewModel.firstName,
        'last_name': viewModel.lastName,
        'service_address_one': viewModel.street,
        'service_address_two': viewModel.aptNumber,
        'service_city': viewModel.city,
        'service_state': viewModel.state,
        'service_zip': viewModel.zip,
        'billing_address_one': viewModel.street, // Use same as service for now
        'billing_address_two': viewModel.aptNumber,
        'billing_city': viewModel.city,
        'billing_state': viewModel.state,
        'billing_zip': viewModel.zip,
        'notify_bill_via_text': 'Y',
        'notify_bill_via_email': 'Y',
      };

      // Add password if available
      if (viewModel.password.isNotEmpty) {
        customerInfo['password'] = viewModel.password;
      }

      // Add alternate phone number if available
      if (viewModel.phoneNumber.isNotEmpty) {
        customerInfo['alternate_phone_number'] = viewModel.phoneNumber;
      }

      // Add port-in information if activation type is PORTIN
      if (activationType == 'PORTIN') {
        customerInfo['port_current_carrier'] = viewModel.portInCurrentCarrier;
        customerInfo['port_account_number'] = viewModel.portInAccountNumber;
        customerInfo['port_account_password'] = viewModel.portInPin;
        customerInfo['port_number'] = viewModel.selectedPhoneNumber;

        // Port-in name (split if available)
        final portName = viewModel.portInAccountHolderName;
        final portNameParts = portName.split(' ');
        if (portNameParts.length >= 2) {
          customerInfo['port_first_name'] = portNameParts[0];
          customerInfo['port_last_name'] = portNameParts.sublist(1).join(' ');
        } else if (portNameParts.length == 1) {
          customerInfo['port_first_name'] = portNameParts[0];
          customerInfo['port_last_name'] = '';
        }

        // Use service address for port-in address (as per typical flow)
        customerInfo['port_address_one'] = viewModel.street;
        customerInfo['port_address_two'] = viewModel.aptNumber;
        customerInfo['port_city'] = viewModel.city;
        customerInfo['port_state'] = viewModel.state;
        customerInfo['port_zip_code'] = viewModel.zip;
      }

      // Call create_customer_prepaid_multiline API
      print('🔄 Calling create_customer_prepaid_multiline API...');
      // Generate unique transaction ID for this API call
      final transactionId = VCareAPIManager.generateTransactionId(orderId, 'CREATE');
      
      final apiManager = VCareAPIManager();
      final response = await apiManager.createCustomerPrepaidMultiline(
        enrollmentId: enrollmentId,
        orderId: paymentOrderId,
        planId: planId,
        customerInfo: customerInfo,
        agentId: 'Sushil', // TODO: Get from user settings or configuration
        source: 'WEBSITE',
        externalTransactionId: transactionId,
      );

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('✅ CUSTOMER CREATED SUCCESSFULLY');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📋 API Response Details:');
      print('   Message: ${response.msg}');
      print('   Message Code: ${response.msgCode}');
      if (response.externalTransactionId != null) {
        print('   External Transaction ID: ${response.externalTransactionId}');
      }

      // Log line details
      if (response.data != null && response.data!.isNotEmpty) {
        print('   Number of Lines: ${response.data!.length}');

        for (var i = 0; i < response.data!.length; i++) {
          final lineResponse = response.data![i];
          print('   ──────────────────────────────────────');
          print('   Line ${i + 1}:');
          print('      Message: ${lineResponse.msg}');
          print('      Message Code: ${lineResponse.msgCode}');

          if (lineResponse.data != null) {
            final lineData = lineResponse.data!;
            if (lineData.custId != null) {
              print('      Customer ID: ${lineData.custId}');
            }
            if (lineData.customerId != null) {
              print('      Customer ID (alt): ${lineData.customerId}');
            }
            if (lineData.enrollmentId != null) {
              print('      Enrollment ID: ${lineData.enrollmentId}');
            }
            if (lineData.enrollmentType != null) {
              print('      Enrollment Type: ${lineData.enrollmentType}');
            }
            if (lineData.mdn != null && lineData.mdn!.isNotEmpty) {
              print('      MDN (Phone Number): ${lineData.mdn}');
            }
            if (lineData.msid != null && lineData.msid!.isNotEmpty) {
              print('      MSID: ${lineData.msid}');
            }
            if (lineData.msl != null && lineData.msl!.isNotEmpty) {
              print('      MSL: ${lineData.msl}');
            }
            if (lineData.invoiceNumber != null && lineData.invoiceNumber!.isNotEmpty) {
              print('      Invoice Number: ${lineData.invoiceNumber}');
            }
          } else {
            print('      ⚠️ No line data in response');
          }
        }
      } else {
        print('   ⚠️ No lines data in response');
      }
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Save customer ID and other response data to order if needed
      // Also track the enrollment_id from response for port-in submission
      String? finalEnrollmentId = enrollmentId; // Default to original
      
      if (response.data != null && response.data!.isNotEmpty) {
        final firstLine = response.data!.first;
        if (firstLine.data != null) {
          final lineData = firstLine.data!;
          final updateData = <String, dynamic>{};

          if (lineData.custId != null) {
            updateData['cust_id'] = lineData.custId;
            print('💾 Saving cust_id: ${lineData.custId} to order');
          }
          if (lineData.customerId != null) {
            updateData['customer_id'] = lineData.customerId;
            print('💾 Saving customer_id: ${lineData.customerId} to order');
          }
          if (lineData.mdn != null && lineData.mdn!.isNotEmpty) {
            updateData['mdn'] = lineData.mdn;
            print('💾 Saving MDN: ${lineData.mdn} to order');
          }
          if (lineData.enrollmentId != null) {
            updateData['enrollment_id'] = lineData.enrollmentId;
            // Use enrollment_id from response if available (important for port-in)
            finalEnrollmentId = lineData.enrollmentId;
            print('💾 Saving enrollment_id: ${lineData.enrollmentId} to order');
            print('📋 Using enrollment_id from create customer response: $finalEnrollmentId');
          }

          if (updateData.isNotEmpty) {
            await orderManager.saveStepProgress(
              userId: userId,
              orderId: orderId,
              step: 5,
              data: updateData,
            );
            print('✅ Successfully saved customer data to order');
          }
        }
      }

      // Note: Port-in APIs (get_list, submit_portin, query_portin) are NOT called here
      // because port-in details are collected in step 6 (porting view), not step 5 (billing)
      // The port-in APIs will be called in number_porting_view.dart after user fills port-in details
      // Customer is created with activation_type: 'PORTIN' if numberType is 'Existing',
      // but the actual port-in submission happens later when port-in details are available
    } catch (e, stackTrace) {
      print('❌ Failed to create customer: $e');
      print('   Stack trace: $stackTrace');
      // Continue to next step even if customer creation fails (order is saved locally)
      // You may want to show an alert to the user here
    }
  }

  void _handleBack() {
    widget.onStepChanged(4);
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _billingAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<UserRegistrationViewModel>(context);

    return StepNavigationContainer(
      currentStep: widget.currentStep,
      totalSteps: 6,
      nextButtonText: 'Complete Order',
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
      nextButtonDisabled: false,
      isLoading: _isSaving,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              OrderStepHeader(
                title: 'Billing Information',
              ),
              SizedBox(height: AppTheme.spacingSection),
              
              // Pricing Section (matching TrumpMobile)
              _buildPricingSection(),
              SizedBox(height: AppTheme.spacingSection),
              
              // Payment Section
              _buildPaymentSection(),
              SizedBox(height: AppTheme.spacingSection),
              
              // Emergency Address Section (with agreements inside)
              _buildEmergencyAddressSection(),
              SizedBox(height: AppTheme.spacingSection),
              
              // Broadband Facts Section
              _buildBroadbandFactsSection(),
            ],
          ),
        ),
      ),
    );
  }
}

