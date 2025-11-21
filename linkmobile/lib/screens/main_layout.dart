import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/navigation_state.dart';
import '../widgets/app_header.dart';
import '../widgets/app_footer.dart';
import '../providers/user_registration_view_model.dart';
import '../utils/constants.dart';
import '../screens/profile/hamburger_menu_view.dart';
import 'home/start_order_view.dart';
import 'home/plans_view.dart';
import 'support/support_view.dart';
import 'home/address_info_sheet.dart';

class MainLayout extends StatefulWidget {
  final Function(String)? onStartOrder;
  final Function(String, int)? onResumeOrder;

  const MainLayout({
    super.key,
    this.onStartOrder,
    this.onResumeOrder,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  String _currentZipCode = '';
  late PageController _pageController;
  bool _isInitialized = false;
  bool _isNavigatingProgrammatically = false;

  @override
  void initState() {
    super.initState();
    _loadZipCode();
    // Initialize PageController with home tab (index 1: Plans=0, Home=1, Chat=2)
    _pageController = PageController(initialPage: 1);
    // Mark as initialized after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadZipCode() async {
    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    await viewModel.loadUserData();
    
    setState(() {
      _currentZipCode = viewModel.zip.isNotEmpty ? viewModel.zip : AppConstants.defaultZipCode;
    });
  }

  void _showHamburgerMenu(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.75,
              height: MediaQuery.of(context).size.height,
              color: Colors.white,
              child: const HamburgerMenuView(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Persistent Header (extends behind status bar)
          AppHeader(
            zipCode: _currentZipCode.isNotEmpty ? _currentZipCode : null,
            onZipCodeTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => const AddressInfoSheet(),
              ).then((_) {
                _loadZipCode();
              });
            },
            onMenuTap: () {
              _showHamburgerMenu(context);
            },
          ),
          // Body content - only this changes when switching tabs
          Expanded(
            child: Consumer<NavigationState>(
              builder: (context, navigationState, _) {
                return PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    if (_isInitialized && !_isNavigatingProgrammatically) {
                      final navigationState = Provider.of<NavigationState>(context, listen: false);
                      final tab = _getTabFromIndex(index);
                      navigationState.setFooterTab(tab);
                    }
                    _isNavigatingProgrammatically = false;
                  },
                  children: [
                    // Plans tab (index 0)
                    const PlansViewBody(),
                    // Home tab (index 1)
                    _buildHomeBody(),
                    // Chat tab (index 2)
                    const SupportViewBody(),
                  ],
                );
              },
            ),
          ),
          // Persistent Footer
          Consumer<NavigationState>(
            builder: (context, navigationState, _) {
              return AppFooter(
                currentTab: navigationState.currentFooterTab,
                onTabChanged: (tab) {
                  // Update navigation state first to prevent intermediate highlighting
                  navigationState.setFooterTab(tab);
                  
                  // Set flag to prevent onPageChanged from updating state during animation
                  _isNavigatingProgrammatically = true;
                  
                  // Navigate to the target page
                  final targetIndex = _getTabIndex(tab);
                  if (_pageController.hasClients) {
                    // Use jumpToPage for non-adjacent tabs to avoid intermediate highlighting
                    final currentIndex = _pageController.page?.round() ?? 1;
                    if ((currentIndex == 0 && targetIndex == 2) || 
                        (currentIndex == 2 && targetIndex == 0)) {
                      // Jump directly for plans <-> chat navigation
                      _pageController.jumpToPage(targetIndex);
                    } else {
                      // Animate for adjacent tabs
                      _pageController.animateToPage(
                        targetIndex,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  }
                  
                  if (tab == FooterTab.home) {
                    navigationState.navigateTo(Destination.startNewOrder);
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  int _getTabIndex(FooterTab tab) {
    switch (tab) {
      case FooterTab.plans:
        return 0;
      case FooterTab.home:
        return 1;
      case FooterTab.chat:
        return 2;
    }
  }

  FooterTab _getTabFromIndex(int index) {
    switch (index) {
      case 0:
        return FooterTab.plans;
      case 1:
        return FooterTab.home;
      case 2:
        return FooterTab.chat;
      default:
        return FooterTab.home;
    }
  }

  Widget _buildHomeBody() {
    final user = FirebaseAuth.instance.currentUser;
    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    
    // Check if user has contact info
    final hasContactInfo = viewModel.firstName.isNotEmpty && 
                         viewModel.lastName.isNotEmpty;
    
    // Determine if this is a new user (no user or no contact info)
    final isNewUser = user == null || !hasContactInfo;
    
    return StartOrderViewBody(
      isNewUser: isNewUser,
      onStart: widget.onStartOrder,
      onResume: widget.onResumeOrder,
    );
  }
}

