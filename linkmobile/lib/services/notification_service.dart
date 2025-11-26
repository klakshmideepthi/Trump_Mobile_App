import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_manager.dart';

/// Top-level function for handling background messages
/// Must be a top-level function (not a class method) for FCM
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Background message received: ${message.messageId}');
  print('📧 Title: ${message.notification?.title}');
  print('📝 Body: ${message.notification?.body}');
  
  // Note: You can't use UI-related code here, but you can process data
  // Local notifications will be handled by the plugin automatically if configured
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseManager _firebaseManager = FirebaseManager();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _currentToken;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) {
      print('⚠️ NotificationService already initialized');
      return;
    }

    try {
      // DON'T request permissions here - wait until after user logs in
      // Permissions will be requested only when user opts in after login

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Set up FCM message handlers
      await _setupMessageHandlers();

      // DON'T save FCM token here - wait until user logs in and opts in
      // Token will be saved only after user grants permission after login

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('🔄 FCM token refreshed: $newToken');
        final User? user = _auth.currentUser;
        if (user != null) {
          // Only save if user is logged in
          _saveTokenToFirestore(newToken);
        }
      });

      _initialized = true;
      print('✅ NotificationService initialized successfully (permissions deferred until after login)');
    } catch (e) {
      print('❌ Error initializing NotificationService: $e');
      // Don't rethrow - allow app to continue even if notifications fail
    }
  }

  /// Request notification permissions (public method - shows native OS permission prompt)
  /// Returns true if permission granted, false otherwise
  Future<bool> requestNotificationPermissions() async {
    print('🔐 Requesting notification permissions...');

    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('📱 Permission status: ${settings.authorizationStatus}');
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Notification permission granted');
      return true;
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('⚠️ Notification permission granted provisionally');
      return true;
    } else {
      print('❌ Notification permission denied');
      return false;
    }
  }

  /// Request notification permissions (private method - kept for backward compatibility)
  Future<void> _requestPermissions() async {
    await requestNotificationPermissions();
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings - DON'T request permission here, wait until after login
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,  // Changed from true to false - permission requested after login
      requestBadgePermission: false,  // Changed from true to false - permission requested after login
      requestSoundPermission: false,  // Changed from true to false - permission requested after login
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    await _createNotificationChannel();
    
    print('✅ Local notifications initialized');
  }

  /// Create Android notification channel (required for Android 8.0+)
  Future<void> _createNotificationChannel() async {
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'linkmobile_notifications', // id
        'LinkMobile Notifications', // name
        description: 'Notifications for order updates and important messages',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      
      print('✅ Android notification channel created');
    }
  }

  /// Set up FCM message handlers
  Future<void> _setupMessageHandlers() async {
    // Handle foreground messages (when app is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Foreground message received: ${message.messageId}');
      _handleForegroundMessage(message);
    });

    // Handle notification taps (when user taps notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('👆 Notification tapped: ${message.messageId}');
      _handleNotificationTap(message);
    });

    // Check if app was opened from a terminated state via notification
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('🚀 App opened from terminated state via notification');
      _handleNotificationTap(initialMessage);
    }

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    print('✅ FCM message handlers set up');
  }

  /// Handle foreground messages (show local notification)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;
    final AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      // Show local notification when app is in foreground
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'linkmobile_notifications',
            'LinkMobile Notifications',
            channelDescription: 'Notifications for order updates and important messages',
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(), // Pass data as payload
      );
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    final Map<String, dynamic> data = message.data;
    
    print('📋 Notification data: $data');
    
    // Extract action from data and handle navigation
    // You can use your NavigationState here
    // Example:
    // if (data['type'] == 'order_update') {
    //   String? orderId = data['orderId'];
    //   // Navigate to order details
    // }
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('👆 Local notification tapped: ${response.payload}');
    // Handle navigation based on payload
  }

  /// Get current FCM token and save to Firestore
  Future<void> _saveFCMToken() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        print('⚠️ No user logged in, skipping FCM token save');
        return;
      }

      _currentToken = await _firebaseMessaging.getToken();
      
      if (_currentToken != null) {
        print('🔑 FCM Token: $_currentToken');
        await _saveTokenToFirestore(_currentToken!);
      } else {
        print('⚠️ Failed to get FCM token');
      }
    } catch (e) {
      // Handle iOS-specific errors gracefully when APNS isn't configured
      if (Platform.isIOS) {
        final errorString = e.toString();
        if (errorString.contains('apns-token-not-set') || 
            errorString.contains('aps-environment') ||
            errorString.contains('APNS token has not been received')) {
          print('⚠️ iOS detected but APNS not configured yet.');
          print('ℹ️ This is expected if you don\'t have an Apple Developer account yet.');
          print('ℹ️ Notifications will work on Android. iOS support will be enabled once APNS is configured.');
          return;
        }
      }
      // For other errors, log them but don't block the app
      print('❌ Error getting/saving FCM token: $e');
      if (Platform.isAndroid) {
        print('⚠️ Failed to get FCM token on Android. Check Firebase configuration.');
      }
    }
  }

  /// Save FCM token to Firestore under user document
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        print('⚠️ No user logged in, cannot save FCM token');
        return;
      }

      final userRef = _firestore.collection('users').doc(user.uid);

      // Get current tokens array
      final userDoc = await userRef.get();
      final currentData = userDoc.data() ?? {};
      final List<dynamic> existingTokens = 
          (currentData['fcmTokens'] as List<dynamic>?) ?? [];

      // Track if token was newly added
      final wasNewToken = !existingTokens.contains(token);
      
      // Add token if it doesn't exist
      if (wasNewToken) {
        existingTokens.add(token);
      }
      
      // Always update notification settings to ensure enabled is set to true when token exists
      await userRef.set({
        'fcmTokens': existingTokens,
        'notificationSettings': {
          'enabled': true,
          'orderUpdates': true,
          'promotions': true,
          'reminders': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        ...currentData,
      }, SetOptions(merge: true));

      if (wasNewToken) {
        print('✅ FCM token saved to Firestore');
      } else {
        print('ℹ️ FCM token already exists in Firestore, updated settings');
      }
    } catch (e) {
      print('❌ Error saving FCM token to Firestore: $e');
    }
  }

  /// Remove FCM token when user logs out
  Future<void> removeToken() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null || _currentToken == null) {
        return;
      }

      final userRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userRef.get();
      final currentData = userDoc.data() ?? {};
      final List<dynamic> tokens = 
          (currentData['fcmTokens'] as List<dynamic>?) ?? [];

      tokens.remove(_currentToken);

      await userRef.update({
        'fcmTokens': tokens,
      });

      _currentToken = null;
      print('✅ FCM token removed from Firestore');
    } catch (e) {
      print('❌ Error removing FCM token: $e');
    }
  }

  /// Get current FCM token (for testing)
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Subscribe to a topic (for broadcast notifications)
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('✅ Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('✅ Unsubscribed from topic: $topic');
  }

  /// Check if user has FCM token in Firestore
  Future<bool> hasTokenInFirestore() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      final userRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userRef.get();
      
      if (!userDoc.exists) {
        return false;
      }

      final data = userDoc.data();
      final fcmTokens = data?['fcmTokens'] as List<dynamic>?;
      
      return fcmTokens != null && fcmTokens.isNotEmpty;
    } catch (e) {
      print('❌ Error checking FCM token in Firestore: $e');
      return false;
    }
  }

  /// Public method to save FCM token (can be called after login)
  /// Note: Permission should already be requested before calling this method
  Future<bool> saveFCMToken() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        print('⚠️ No user logged in, skipping FCM token save');
        return false;
      }

      // Don't request permission here - it should already be requested before calling this
      // Permission is requested in login_page.dart _navigateAfterLogin() method
      // Just get the token and save it
      _currentToken = await _firebaseMessaging.getToken();
      
      if (_currentToken != null) {
        print('🔑 FCM Token: $_currentToken');
        await _saveTokenToFirestore(_currentToken!);
        return true;
      } else {
        print('⚠️ Failed to get FCM token');
        return false;
      }
    } catch (e) {
      // Handle iOS-specific errors gracefully when APNS isn't configured
      if (Platform.isIOS) {
        final errorString = e.toString();
        if (errorString.contains('apns-token-not-set') || 
            errorString.contains('aps-environment') ||
            errorString.contains('APNS token has not been received')) {
          print('⚠️ iOS detected but APNS not configured yet.');
          print('ℹ️ This is expected if you don\'t have an Apple Developer account yet.');
          print('ℹ️ Notifications will work on Android. iOS support will be enabled once APNS is configured.');
          return false;
        }
      }
      // For other errors, log them but don't block the app
      print('❌ Error saving FCM token: $e');
      if (Platform.isAndroid) {
        print('⚠️ Failed to get FCM token on Android. Check Firebase configuration.');
      }
      return false;
    }
  }

  /// Remove all FCM tokens for current user (when notifications are disabled)
  Future<void> removeAllTokens() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        print('⚠️ No user logged in, cannot remove FCM tokens');
        return;
      }

      final userRef = _firestore.collection('users').doc(user.uid);
      
      await userRef.update({
        'fcmTokens': [],
        'notificationSettings': {
          'enabled': false,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      });

      _currentToken = null;
      print('✅ All FCM tokens removed from Firestore');
    } catch (e) {
      print('❌ Error removing FCM tokens: $e');
    }
  }

  /// Check if notifications are enabled for user
  Future<bool> areNotificationsEnabled() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      final userRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userRef.get();
      
      if (!userDoc.exists) {
        return false;
      }

      final data = userDoc.data();
      final notificationSettings = data?['notificationSettings'] as Map<String, dynamic>?;
      final enabled = notificationSettings?['enabled'] ?? true; // Default to true for backward compatibility
      
      // Also check if there are tokens
      final fcmTokens = data?['fcmTokens'] as List<dynamic>?;
      final hasTokens = fcmTokens != null && fcmTokens.isNotEmpty;
      
      return enabled && hasTokens;
    } catch (e) {
      print('❌ Error checking notification status: $e');
      return false;
    }
  }

  /// Enable notifications and save token
  Future<bool> enableNotifications() async {
    return await saveFCMToken();
  }

  /// Disable notifications and remove tokens
  Future<void> disableNotifications() async {
    await removeAllTokens();
  }
}

