import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/user_registration_view_model.dart';
import '../providers/navigation_state.dart' show NavigationState, Destination, FooterTab;
import '../services/firebase_order_manager.dart';
import 'home/start_order_view.dart';
import 'order_flow/contact_info_view.dart';
import 'order_flow/device_compatibility_view.dart';
import 'order_flow/sim_selection_view.dart';
import 'order_flow/number_selection_view.dart';
import 'order_flow/billing_info_view.dart';
import 'order_flow/number_porting_view.dart';
import 'login_page.dart';
import 'main_layout.dart';

class ContentView extends StatefulWidget {
  final bool isNewAccount;
  final int initialOrderStep;

  const ContentView({
    super.key,
    required this.isNewAccount,
    this.initialOrderStep = 0,
  });

  @override
  State<ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<ContentView> {
  late int _orderStep;
  bool _hasContactInfo = false;
  bool _isLoadingContactInfo = true;

  @override
  void initState() {
    super.initState();
    _orderStep = widget.initialOrderStep;
    _checkContactInfo();
    _setupAuthListener();
    // Set footer tab to home when ContentView loads (default landing page)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigationState = Provider.of<NavigationState>(context, listen: false);
      if (_orderStep == 0) {
        navigationState.setFooterTab(FooterTab.home);
        navigationState.navigateTo(Destination.startNewOrder);
      }
    });
  }

  void _setupAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    });
  }

  Future<void> _checkContactInfo() async {
    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    await viewModel.loadUserData();
    
    setState(() {
      _hasContactInfo = viewModel.firstName.isNotEmpty && viewModel.lastName.isNotEmpty;
      _isLoadingContactInfo = false;
    });
  }

  void _handleStepChanged(int step) {
    print('🔄 DEBUG: _handleStepChanged called with step: $step');
    final navigationState = Provider.of<NavigationState>(context, listen: false);
    navigationState.orderStartStep = step; // Update navigation state to prevent revert
    setState(() {
      _orderStep = step;
    });
    print('✅ DEBUG: _orderStep now: $_orderStep, navigationState.orderStartStep: ${navigationState.orderStartStep}');
  }

  void _handleStartOrder(String orderId) {
    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    final navigationState = Provider.of<NavigationState>(context, listen: false);
    
    viewModel.orderId = orderId;
    
    // Update navigation state to orderFlow BEFORE setting order step
    // This prevents the build method from resetting _orderStep back to 0
    navigationState.currentOrderId = orderId;
    navigationState.orderStartStep = 1;
    navigationState.navigateTo(Destination.orderFlow);
    
    // Check if order already exists and has a currentStep (matching TrumpMobile behavior)
    if (viewModel.userId != null) {
      final orderManager = FirebaseOrderManager();
      orderManager.fetchOrderDocument(viewModel.userId!, orderId).then((orderData) {
        if (mounted) {
          if (orderData != null && orderData['currentStep'] != null) {
            // Resume at saved step
            final step = orderData['currentStep'] as int;
            navigationState.orderStartStep = step;
            setState(() {
              _orderStep = step;
            });
          } else {
            // Start fresh at step 1
            setState(() {
              _orderStep = 1;
            });
          }
        }
      }).catchError((_) {
        // If error, default to step 1
        if (mounted) {
          setState(() {
            _orderStep = 1;
          });
        }
      });
    } else {
      // If no userId, default to step 1
      setState(() {
        _orderStep = 1;
      });
    }
  }

  void _handleResumeOrder(String orderId, int step) async {
    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    final navigationState = Provider.of<NavigationState>(context, listen: false);
    
    viewModel.orderId = orderId;
    
    // Check if billing is completed
    if (viewModel.userId != null) {
      final orderManager = FirebaseOrderManager();
      final orderData = await orderManager.fetchOrderDocument(viewModel.userId!, orderId);
      final billingCompleted = orderData?['billingCompleted'] ?? false;
      
      // If billing is completed, force step to 6 and prevent access to steps 1-5
      final targetStep = billingCompleted ? 6 : step;
      
      // Update navigation state to orderFlow
      navigationState.currentOrderId = orderId;
      navigationState.orderStartStep = targetStep;
      navigationState.navigateTo(Destination.orderFlow);
      
      viewModel.prefillFromOrder(orderId).then((_) {
        if (mounted) {
          setState(() {
            _orderStep = targetStep;
          });
        }
      });
    } else {
      // Update navigation state to orderFlow
      navigationState.currentOrderId = orderId;
      navigationState.orderStartStep = step;
      navigationState.navigateTo(Destination.orderFlow);
      
      viewModel.prefillFromOrder(orderId).then((_) {
        if (mounted) {
          setState(() {
            _orderStep = step;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigationState = Provider.of<NavigationState>(context);
    
    // Listen to navigation state changes
    if (navigationState.currentDestination == Destination.home ||
        navigationState.currentDestination == Destination.startNewOrder) {
      if (_orderStep != 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _orderStep = 0;
          });
        });
      }
    } else if (navigationState.currentDestination == Destination.orderFlow) {
      if (navigationState.orderStartStep != null && _orderStep != navigationState.orderStartStep) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (navigationState.currentOrderId != null) {
            _handleResumeOrder(navigationState.currentOrderId!, navigationState.orderStartStep!);
          } else {
            setState(() {
              _orderStep = navigationState.orderStartStep ?? 1;
            });
          }
        });
      }
    }

    if (_isLoadingContactInfo) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show home screens when orderStep is 0 - use MainLayout with persistent header/footer
    if (_orderStep == 0) {
      return MainLayout(
        onStartOrder: _handleStartOrder,
        onResumeOrder: _handleResumeOrder,
      );
    }

    // Show order flow steps
    // Check if billing is completed and prevent access to steps 1-5
    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    if (viewModel.orderId != null && viewModel.userId != null && _orderStep >= 1 && _orderStep <= 5) {
      // Check billing status asynchronously
      return FutureBuilder<Map<String, dynamic>?>(
        future: FirebaseOrderManager().fetchOrderDocument(viewModel.userId!, viewModel.orderId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          final billingCompleted = snapshot.data?['billingCompleted'] ?? false;
          
          // If billing is completed, redirect to step 6
          if (billingCompleted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final navigationState = Provider.of<NavigationState>(context, listen: false);
              navigationState.orderStartStep = 6;
              _handleStepChanged(6);
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          // Billing not completed, show the requested step
          switch (_orderStep) {
            case 1:
              return ContactInfoView(
                currentStep: _orderStep,
                onStepChanged: _handleStepChanged,
              );
            case 2:
              return DeviceCompatibilityView(
                currentStep: _orderStep,
                onStepChanged: _handleStepChanged,
              );
            case 3:
              return SimSelectionView(
                currentStep: _orderStep,
                onStepChanged: _handleStepChanged,
              );
            case 4:
              return NumberSelectionView(
                currentStep: _orderStep,
                onStepChanged: _handleStepChanged,
              );
            case 5:
              return BillingInfoView(
                currentStep: _orderStep,
                onStepChanged: _handleStepChanged,
              );
            default:
              return StartOrderView(
                isNewUser: !_hasContactInfo,
                onStart: _handleStartOrder,
              );
          }
        },
      );
    }
    
    switch (_orderStep) {
      case 1:
        return ContactInfoView(
          currentStep: _orderStep,
          onStepChanged: _handleStepChanged,
        );
      case 2:
        return DeviceCompatibilityView(
          currentStep: _orderStep,
          onStepChanged: _handleStepChanged,
        );
      case 3:
        return SimSelectionView(
          currentStep: _orderStep,
          onStepChanged: _handleStepChanged,
        );
      case 4:
        return NumberSelectionView(
          currentStep: _orderStep,
          onStepChanged: _handleStepChanged,
        );
      case 5:
        return BillingInfoView(
          currentStep: _orderStep,
          onStepChanged: _handleStepChanged,
        );
      case 6:
        return NumberPortingView(
          currentStep: _orderStep,
          onStepChanged: _handleStepChanged,
        );
      default:
        return StartOrderView(
          isNewUser: !_hasContactInfo,
          onStart: _handleStartOrder,
        );
    }
  }
}

