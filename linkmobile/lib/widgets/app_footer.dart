import 'package:flutter/material.dart';
import '../providers/navigation_state.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';

class AppFooter extends StatelessWidget {
  final FooterTab currentTab;
  final Function(FooterTab)? onTabChanged;

  const AppFooter({
    super.key,
    this.currentTab = FooterTab.home,
    this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Container(
        height: 60 + MediaQuery.of(context).padding.bottom,
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Plans first
            _buildTabItem(
              context,
              icon: Icons.list_alt,
              label: 'Plans',
              tab: FooterTab.plans,
              isSelected: currentTab == FooterTab.plans,
            ),
            // Home in the middle
            _buildTabItem(
              context,
              icon: Icons.home,
              label: 'Home',
              tab: FooterTab.home,
              isSelected: currentTab == FooterTab.home,
            ),
            // Chat last
            _buildTabItem(
              context,
              icon: Icons.chat_bubble_outline,
              label: 'Chat',
              tab: FooterTab.chat,
              isSelected: currentTab == FooterTab.chat,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required FooterTab tab,
    required bool isSelected,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          if (onTabChanged != null) {
            onTabChanged!(tab);
          } else {
            _handleTabNavigation(context, tab);
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppTheme.accentGold
                  : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? AppTheme.accentGold
                    : Colors.grey,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTabNavigation(BuildContext context, FooterTab tab) {
    final navigationState = Provider.of<NavigationState>(context, listen: false);
    
    // Only update the footer tab - the MainLayout will handle the body switch
    navigationState.setFooterTab(tab);
    
    // If navigating to home, also update the destination
    if (tab == FooterTab.home) {
      navigationState.navigateTo(Destination.startNewOrder);
    }
  }

}

