import 'package:flutter/material.dart';
import '../utils/constants.dart';

class BottomActionBar extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;

  const BottomActionBar({
    super.key,
    required this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
      ),
      child: Container(
        height: 60 + bottomPadding,
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Center(
          child: child,
        ),
      ),
    );
  }
}

