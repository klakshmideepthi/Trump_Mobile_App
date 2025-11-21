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
      // Request notification permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Set up FCM message handlers
      await _setupMessageHandlers();

      // Get and save FCM token
      await _saveFCMToken();

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('🔄 FCM token refreshed: $newToken');
        _saveTokenToFirestore(newToken);
      });

      _initialized = true;
      print('✅ NotificationService initialized successfully');
    } catch (e) {
      print('❌ Error initializing NotificationService: $e');
      rethrow;
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
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
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('⚠️ Notification permission granted provisionally');
    } else {
      print('❌ Notification permission denied');
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings (for future use)
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
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

      // Add token if it doesn't exist
      if (!existingTokens.contains(token)) {
        existingTokens.add(token);
        
        // Also save notification settings if they don't exist
        await userRef.set({
          'fcmTokens': existingTokens,
          'notificationSettings': {
            'orderUpdates': true,
            'promotions': true,
            'reminders': true,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          ...currentData,
        }, SetOptions(merge: true));

        print('✅ FCM token saved to Firestore');
      } else {
        print('ℹ️ FCM token already exists in Firestore');
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
}

