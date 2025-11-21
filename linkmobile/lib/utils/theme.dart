import 'package:flutter/material.dart';

class AppTheme {
  // Main Colors - New Brand Colors
  static const Color yellowAccent = Color(0xFFFDC710); // #FDC710
  static const Color redAccent = Color(0xFFFF0000); // #FF0000 - Red Accent
  static const Color mainBlue = Color(0xFF014D7D); // #014D7D - Primary
  static const Color secondBlue = Color(0xFF0C80C3); // #0C80C3 - Secondary/Accent
  
  // Legacy names mapped to new colors for backward compatibility
  static const Color accentGold = yellowAccent;
  static const Color appPrimary = mainBlue;
  static const Color appSecondary = secondBlue;
  
  static const Color appBackground = Color(0xFFFFFFFF);
  static const Color appText = Color(0xFF000000);
  
  // Status Colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color successBackground = Color(0xFFE8F5E9);
  static const Color errorColor = Color(0xFFF44336);
  static const Color errorBackground = Color(0xFFFFEBEE);
  static const Color warningColor = yellowAccent;
  
  // Neutral Colors
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color borderColorSelected = secondBlue;
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color disabledBackground = Color(0xFFF5F5F5);
  static const Color dividerColor = Color(0xFFE0E0E0);

  // Gradient - Updated to use new colors
  static LinearGradient get goldGradient => const LinearGradient(
        colors: [mainBlue, secondBlue],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // Blue gradient for buttons and UI elements (mainBlue to secondBlue)
  static LinearGradient get blueGradient => const LinearGradient(
        colors: [mainBlue, secondBlue],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  // Font Sizes
  static const double fontSizeTitle = 22.0; // title2 size to match Trump Mobile
  static const double fontSizeSubtitle = 14.0;
  static const double fontSizeBody = 16.0;
  static const double fontSizeBodySmall = 14.0;
  static const double fontSizeCaption = 12.0;
  static const double fontSizeButton = 16.0;
  static const double fontSizeOptionTitle = 18.0;
  static const double fontSizeSectionTitle = 22.0; // title2 size to match Trump Mobile

  // Font Weights
  static const FontWeight fontWeightTitle = FontWeight.bold;
  static const FontWeight fontWeightSubtitle = FontWeight.normal;
  static const FontWeight fontWeightBody = FontWeight.normal;
  static const FontWeight fontWeightButton = FontWeight.w600;
  static const FontWeight fontWeightOptionTitle = FontWeight.bold;
  static const FontWeight fontWeightSectionTitle = FontWeight.bold;

  // Spacing
  static const double spacingTitleSubtitle = 8.0;
  static const double spacingSection = 12.0; // Match Trump Mobile VStack spacing
  static const double spacingItem = 12.0; // Match Trump Mobile VStack spacing
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingLarge = 32.0;

  // Border Radius
  static const double borderRadiusButton = 10.0; // Match Trump Mobile button corner radius
  static const double borderRadiusCard = 12.0;
  static const double borderRadiusInput = 8.0; // Match Trump Mobile input corner radius
  static const double borderRadiusOption = 25.0; // Match Trump Mobile selection button corner radius

  // Border Widths
  static const double borderWidthDefault = 1.0;
  static const double borderWidthSelected = 2.0;

  // Icon Sizes
  static const double iconSizeSmall = 20.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeOption = 40.0;

  // Padding
  static const double paddingInput = 16.0;
  static const double paddingCard = 16.0;
  static const double paddingOption = 16.0;
  static const double paddingButtonVertical = 12.0;
  static const double paddingButtonHorizontal = 24.0;

  // Button Styles
  static ButtonStyle get gradientButtonStyle => ButtonStyle(
        backgroundColor: MaterialStateProperty.all(Colors.transparent),
        foregroundColor: MaterialStateProperty.all(Colors.white),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusButton),
          ),
        ),
      );

  // Input Decoration Helper
  static InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusInput),
        borderSide: const BorderSide(color: borderColor, width: borderWidthDefault),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusInput),
        borderSide: const BorderSide(color: borderColor, width: borderWidthDefault),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusInput),
        borderSide: const BorderSide(color: secondBlue, width: borderWidthSelected),
      ),
      contentPadding: const EdgeInsets.all(paddingInput),
      filled: true,
      fillColor: appBackground,
    );
  }

  // Text Styles
  static TextStyle get titleStyle => const TextStyle(
        fontSize: fontSizeTitle,
        fontWeight: fontWeightTitle,
        color: appText,
      );

  static TextStyle get subtitleStyle => const TextStyle(
        fontSize: fontSizeSubtitle,
        fontWeight: fontWeightSubtitle,
        color: textSecondary,
      );

  static TextStyle get bodyStyle => const TextStyle(
        fontSize: fontSizeBody,
        fontWeight: fontWeightBody,
        color: appText,
      );

  static TextStyle get bodySmallStyle => const TextStyle(
        fontSize: fontSizeBodySmall,
        fontWeight: fontWeightBody,
        color: textSecondary,
      );

  static TextStyle get captionStyle => const TextStyle(
        fontSize: fontSizeCaption,
        fontWeight: fontWeightBody,
        color: textTertiary,
      );

  static TextStyle get buttonStyle => const TextStyle(
        fontSize: fontSizeButton,
        fontWeight: fontWeightButton,
        color: Colors.white,
      );

  static TextStyle get optionTitleStyle => const TextStyle(
        fontSize: fontSizeOptionTitle,
        fontWeight: fontWeightOptionTitle,
        color: appText,
      );

  static TextStyle get optionTitleSelectedStyle => const TextStyle(
        fontSize: fontSizeOptionTitle,
        fontWeight: fontWeightOptionTitle,
        color: Colors.white,
      );

  static TextStyle get optionDescriptionStyle => const TextStyle(
        fontSize: fontSizeBodySmall,
        fontWeight: fontWeightBody,
        color: textSecondary,
      );

  static TextStyle get optionDescriptionSelectedStyle => const TextStyle(
        fontSize: fontSizeBodySmall,
        fontWeight: fontWeightBody,
        color: Colors.white70,
      );

  static TextStyle get sectionTitleStyle => const TextStyle(
        fontSize: fontSizeSectionTitle,
        fontWeight: fontWeightSectionTitle,
        color: appText,
      );
}

