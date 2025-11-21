import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/plan_model.dart';
import '../../widgets/plan_card.dart';
import '../../widgets/app_footer.dart';
import '../../providers/navigation_state.dart';

class PlanSelectionView extends StatefulWidget {
  final List<Plan> plans;
  final Plan? selectedPlan;
  final Function(Plan) onPlanSelected;

  const PlanSelectionView({
    super.key,
    required this.plans,
    this.selectedPlan,
    required this.onPlanSelected,
  });

  @override
  State<PlanSelectionView> createState() => _PlanSelectionViewState();
}

class _PlanSelectionViewState extends State<PlanSelectionView> {
  @override
  void initState() {
    super.initState();
    // Set footer tab to plans when this view loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigationState = Provider.of<NavigationState>(context, listen: false);
      navigationState.setFooterTab(FooterTab.plans);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Plan'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: widget.plans.length,
              itemBuilder: (context, index) {
                final plan = widget.plans[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: PlanCard(
                    plan: plan,
                    isSelected: widget.selectedPlan?.planId == plan.planId,
                    showUnlimited: index < 5,
                    onTap: () {
                      widget.onPlanSelected(plan);
                      Navigator.of(context).pop();
                    },
                  ),
                );
              },
            ),
          ),
          Consumer<NavigationState>(
            builder: (context, navigationState, _) {
              return AppFooter(
                currentTab: navigationState.currentFooterTab,
              );
            },
          ),
        ],
      ),
    );
  }
}

