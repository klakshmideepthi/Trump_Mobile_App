import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'providers/user_registration_view_model.dart';
import 'providers/navigation_state.dart';
import 'utils/theme.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Notification Service
  try {
    await NotificationService().initialize();
    print('✅ Notification service initialized in main');
  } catch (e) {
    print('❌ Error initializing notification service: $e');
    // Don't block app startup if notifications fail
  }
  
  runApp(const LinkMobileApp());
}

class LinkMobileApp extends StatelessWidget {
  const LinkMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserRegistrationViewModel()),
        ChangeNotifierProvider(create: (_) => NavigationState()),
      ],
      child: MaterialApp(
        title: 'LinkUp Mobile',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppTheme.mainBlue,
            primary: AppTheme.mainBlue,
            secondary: AppTheme.secondBlue,
            surface: AppTheme.appBackground,
            error: AppTheme.errorColor,
          ),
          textTheme: GoogleFonts.montserratTextTheme(),
          fontFamily: GoogleFonts.montserrat().fontFamily,
          appBarTheme: AppBarTheme(
            backgroundColor: AppTheme.mainBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            titleTextStyle: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.mainBlue,
              foregroundColor: Colors.white,
              textStyle: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
