import 'package:flutter/material.dart';
import 'dart:async';
import '../models/plan_model.dart';
import '../utils/theme.dart';
import 'plan_card.dart';

class PlanCarousel extends StatefulWidget {
  final List<Plan> plans;
  final Plan? selectedPlan;
  final Function(Plan)? onPlanSelected;
  final Function(Plan)? onPlanTapped;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final bool showSmallPlanName;

  const PlanCarousel({
    super.key,
    required this.plans,
    this.selectedPlan,
    this.onPlanSelected,
    this.onPlanTapped,
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 5),
    this.showSmallPlanName = false,
  });

  @override
  State<PlanCarousel> createState() => _PlanCarouselState();
}

class _PlanCarouselState extends State<PlanCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.plans.isNotEmpty && widget.selectedPlan != null) {
      final selectedIndex = widget.plans.indexWhere(
        (p) => p.planId == widget.selectedPlan?.planId,
      );
      if (selectedIndex >= 0) {
        _currentIndex = selectedIndex;
      }
    }
    if (widget.autoPlay && widget.plans.length > 1) {
      _startCarouselTimer();
    }
  }

  @override
  void didUpdateWidget(PlanCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.plans != oldWidget.plans || widget.autoPlay != oldWidget.autoPlay) {
      _carouselTimer?.cancel();
      if (widget.autoPlay && widget.plans.length > 1) {
        _startCarouselTimer();
      }
    }
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    if (widget.plans.length <= 1) return;
    
    _carouselTimer = Timer.periodic(widget.autoPlayInterval, (timer) {
      if (!mounted || !_pageController.hasClients) {
        timer.cancel();
        return;
      }
      
      // Check if we're at the last page and loop back to first
      if (_currentIndex >= widget.plans.length - 1) {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopCarouselTimer() {
    _carouselTimer?.cancel();
    _carouselTimer = null;
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    if (widget.onPlanSelected != null && index < widget.plans.length) {
      widget.onPlanSelected!(widget.plans[index]);
    }
    
    // Restart timer after manual page change
    if (widget.autoPlay) {
      _stopCarouselTimer();
      _startCarouselTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.plans.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 196,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.plans.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final plan = widget.plans[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: PlanCard(
                  plan: plan,
                  isSelected: widget.selectedPlan?.planId == plan.planId,
                  showSmallPlanName: widget.showSmallPlanName,
                  showUnlimited: index < 5,
                  onTap: () {
                    _stopCarouselTimer();
                    if (widget.onPlanTapped != null) {
                      widget.onPlanTapped!(plan);
                    } else if (widget.onPlanSelected != null) {
                      widget.onPlanSelected!(plan);
                    }
                    if (widget.autoPlay) {
                      _startCarouselTimer();
                    }
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        if (widget.plans.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.plans.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _currentIndex == index
                      ? AppTheme.blueGradient
                      : null,
                  color: _currentIndex == index
                      ? null
                      : Colors.grey[300],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

