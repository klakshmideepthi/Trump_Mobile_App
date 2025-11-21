import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/user_registration_view_model.dart';
import '../providers/navigation_state.dart';
import '../services/firebase_order_manager.dart';
import 'login_page.dart';
import 'content_view.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool? _isNewAccount;
  int? _initialOrderStep;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationState();
  }

  Future<void> _checkAuthenticationState() async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      // Not logged in
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
      
      // Navigate to login after minimum splash time
      Timer(const Duration(milliseconds: 1600), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      });
    } else {
      // Logged in
      setState(() {
        _isLoggedIn = true;
      });

      final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
      viewModel.userId = user.uid;
      viewModel.email = user.email ?? '';

      // Load user data
      await viewModel.loadUserData();

      // Check if new or existing user
      final orders = await FirebaseOrderManager().fetchUserOrders(user.uid);
      final isNewAccount = orders.isEmpty;

      // Check for incomplete orders
      final incompleteOrder = await FirebaseOrderManager().fetchLatestIncompleteOrder(user.uid);
      int? initialOrderStep;
      if (incompleteOrder != null) {
        initialOrderStep = int.tryParse(incompleteOrder['currentStep'] ?? '1');
      }

      setState(() {
        _isNewAccount = isNewAccount;
        _initialOrderStep = initialOrderStep ?? 0;
        _isLoading = false;
      });

      // Navigate to content view after minimum splash time
      Timer(const Duration(milliseconds: 1600), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ContentView(
                isNewAccount: isNewAccount,
                initialOrderStep: initialOrderStep ?? 0,
              ),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/LinkUpLogo.png',
              height: 100,
              fit: BoxFit.fitHeight,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

