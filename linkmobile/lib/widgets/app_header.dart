import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

class AppHeader extends StatelessWidget {
  final double? logoHeight;
  final String? zipCode;
  final VoidCallback? onZipCodeTap;
  final VoidCallback? onMenuTap;
  final bool showGradient;
  final VoidCallback? onBackTap;
  final String? title;

  const AppHeader({
    super.key,
    this.logoHeight = 60,
    this.zipCode,
    this.onZipCodeTap,
    this.onMenuTap,
    this.showGradient = false,
    this.onBackTap,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: showGradient
          ? BoxDecoration(
              gradient: AppTheme.blueGradient,
            )
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
      child: SafeArea(
        bottom: false,
        minimum: const EdgeInsets.only(top: 4),
          child: Container(
          height: AppConstants.headerHeight,
          child: Row(
            children: [
              // Left side: Back button or Logo (fixed width)
              SizedBox(
                width: 48,
                child: onBackTap != null
                    ? IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: showGradient ? Colors.white : Colors.black,
                        ),
                        onPressed: onBackTap,
                        iconSize: 24,
                        padding: EdgeInsets.zero,
                      )
                    : Image.asset(
                        'assets/images/LinkUpLogo.png',
                        height: 50,
                        width: 80,
                        fit: BoxFit.contain,
                      ),
              ),
              
              // Center: Title or Zip code (centered)
              Expanded(
                child: Center(
                  child: title != null
                      ? Text(
                          title!,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: showGradient ? Colors.white : Colors.black,
                          ),
                        )
                      : zipCode != null && zipCode!.isNotEmpty
                          ? InkWell(
                              onTap: onZipCodeTap,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    zipCode!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: showGradient ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 20,
                                    color: showGradient ? Colors.white : Colors.grey,
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                ),
              ),
              
              // Right side: Hamburger menu button (fixed width)
              SizedBox(
                width: 48,
                child: onMenuTap != null
                    ? IconButton(
                        icon: Icon(
                          Icons.menu,
                          color: showGradient ? Colors.white : Colors.black,
                        ),
                        onPressed: onMenuTap,
                        iconSize: 28,
                        padding: EdgeInsets.zero,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

