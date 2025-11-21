import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import 'step_indicator.dart';
import 'gradient_button.dart';
import 'bottom_action_bar.dart';

/// Step navigation container matching TrumpMobile's StepNavigationContainer
/// Header: Back button (left), Step indicator (center), Info/Cancel button (right)
/// Footer: Next Step button (or Complete Order for step 5)
class StepNavigationContainer extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String nextButtonText;
  final VoidCallback nextButtonAction;
  final VoidCallback backButtonAction;
  final VoidCallback? cancelAction;
  final bool nextButtonDisabled;
  final bool disableBackButton;
  final bool disableCancelButton;
  final Widget child;
  final bool isLoading;

  const StepNavigationContainer({
    super.key,
    required this.currentStep,
    this.totalSteps = 6,
    this.nextButtonText = 'Next Step',
    required this.nextButtonAction,
    required this.backButtonAction,
    this.cancelAction,
    this.nextButtonDisabled = false,
    this.disableBackButton = false,
    this.disableCancelButton = false,
    required this.child,
    this.isLoading = false,
  });

  Future<void> _handleCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Do you want to cancel the order?'),
        actions: [
          // Stack buttons vertically to match SwiftUI Alert
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // "No, Keep Editing" button (cancel/secondary) - blue
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.secondBlue,
                ),
                child: const Text('No, Keep Editing'),
              ),
              // "Yes, I want to cancel" button (destructive/primary) - red
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Yes, I want to cancel'),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true && cancelAction != null) {
      cancelAction!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFirstStep = currentStep == 1;
    final isLastStep = currentStep == totalSteps;
    final showBackButton = !isFirstStep && !isLastStep && !disableBackButton;
    final showCancelButton = !isLastStep && !disableCancelButton;

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      body: Column(
        children: [
          // Header (extends behind status bar, like AppHeader)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
            child: SafeArea(
              bottom: false,
              minimum: const EdgeInsets.only(top: 4),
              child: Container(
                height: AppConstants.headerHeight,
                child: Row(
                  children: [
                    // Back button on left
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: showBackButton
                            ? AppTheme.accentGold
                            : Colors.transparent,
                      ),
                      onPressed: showBackButton ? backButtonAction : null,
                      iconSize: 28,
                    ),
                    
                    const Spacer(),
                    
                    // Step indicator in center
                    StepIndicator(
                      currentStep: currentStep,
                      totalSteps: totalSteps,
                    ),
                    
                    const Spacer(),
                    
                    // Cancel/Close button on right
                    if (showCancelButton)
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppTheme.accentGold,
                        ),
                        onPressed: () => _handleCancel(context),
                        iconSize: 28,
                      )
                    else
                      // Placeholder to keep step indicator centered
                      const SizedBox(
                        width: 48,
                        height: 48,
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // Body content - wrapped in SafeArea like MainLayout
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
              ).copyWith(
                top: AppConstants.defaultSpacing,
                bottom: AppConstants.defaultSpacing,
              ),
              child: child,
            ),
          ),
          
          // Footer matching AppFooter structure (same height and styling)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: BottomActionBar(
              child: GradientButton(
                text: currentStep == 5 ? 'Complete Order' : nextButtonText,
                onPressed: nextButtonDisabled ? null : nextButtonAction,
                isLoading: isLoading,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

