import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:quick_actions/quick_actions.dart';

// Stream for handling notification taps when the app is in the foreground
final StreamController<String?> selectNotificationStream =
StreamController<String?>.broadcast();

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }
}

// Local notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Notification channel for Android
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'fertilityshare_notification_channel', // id
  'High Importance Notifications', // title
  description: 'This channel is used for important notifications.', // description
  importance: Importance.max,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Set background messaging handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize local notifications
  await _setupLocalNotifications();

  runApp(const MyApp());
}

Future<void> _setupLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/launcher_icon');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload != null) {
        selectNotificationStream.add(response.payload);
      }
    },
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fertilityshare',
      debugShowCheckedModeBanner: false,
      navigatorObservers: <NavigatorObserver>[observer],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF4081)),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final WebViewController _controller;
  bool _isLoadingPage = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    // Listen for foreground notification taps
    selectNotificationStream.stream.listen((String? url) {
      if (url != null && mounted) {
        _loadUrl(url: url);
      }
    });

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView is loading (progress : $progress%)');
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoadingPage = true;
              _hasError = false;
            });
            MyApp.analytics.logEvent(
              name: 'page_started',
              parameters: {'url': url},
            );
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoadingPage = false;
            });

            MyApp.analytics.logEvent(
              name: 'page_loaded',
              parameters: {'url': url},
            );
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView Error: ${error.description}');
            if (error.isForMainFrame ?? true) {
              setState(() {
                _hasError = true;
                _isLoadingPage = false;
              });
              MyApp.analytics.logEvent(
                name: 'webview_error',
                parameters: {
                  'description': error.description,
                  'error_type': error.errorCode.toString(),
                },
              );
            }
          },
        ),
      );

    if (_controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      (_controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _initializeAndLoad();
    _setupQuickActions(); // Initialize Quick Actions
  }

  void _setupQuickActions() {
    const QuickActions quickActions = QuickActions();
    quickActions.initialize((String shortcutType) {
      switch (shortcutType) {
        case 'action_preferences':
          _loadUrl(url: 'https://community.fertilityshare.com/my/preferences');
          break;
        case 'action_profile':
          _loadUrl(url: 'https://community.fertilityshare.com/my/activity');
          break;
        case 'action_messages':
          _loadUrl(url: 'https://community.fertilityshare.com/my/messages');
          break;
        case 'action_bookmarks':
          _loadUrl(url: 'https://community.fertilityshare.com/my/bookmarks');
          break;
        case 'action_chat':
          _loadUrl(url: 'https://community.fertilityshare.com/chat');
          break;
        case 'action_invite':
          _loadUrl(url: 'https://community.fertilityshare.com/new-invite');
          break;
      }
    });

    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(type: 'action_profile', localizedTitle: 'Profile', icon: 'fertilityshare'),
      const ShortcutItem(type: 'action_messages', localizedTitle: 'Messages', icon: 'fertilityshare'),
      const ShortcutItem(type: 'action_chat', localizedTitle: 'Chat', icon: 'fertilityshare'),
      const ShortcutItem(type: 'action_bookmarks', localizedTitle: 'Bookmarks', icon: 'fertilityshare'),
      const ShortcutItem(type: 'action_preferences', localizedTitle: 'Preferences', icon: 'fertilityshare'),
      const ShortcutItem(type: 'action_invite', localizedTitle: 'Invite', icon: 'fertilityshare'),
    ]);
  }

  void _initializeAndLoad() async {
    // 1. Check if the app was opened from a terminated state via a notification (fast)
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    String? deepLink;
    
    if (initialMessage != null) {
      deepLink = initialMessage.data['url'];
    }

    // 2. Load the URL immediately (either deep link or home page)
    _loadUrl(url: deepLink);

    // 3. Setup Firebase Messaging in the background without blocking the load
    _setupFirebaseMessaging();
  }

  Future<void> _setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permissions (non-blocking for the rest of the app)
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token and save to Firestore
    String? token = await messaging.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      String? deepLink = message.data['url'];

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/launcher_icon',
            ),
          ),
          payload: deepLink,
        );
      }
    });

    // Handle notification taps (background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message);
    });
  }

  void _handleNotificationClick(RemoteMessage message) {
    final String? deepLink = message.data['url'];
    _loadUrl(url: deepLink);

    MyApp.analytics.logEvent(
      name: 'notification_opened',
      parameters: {
        'message_id': message.messageId ?? '',
        'deep_link': deepLink ?? 'none',
      },
    );
  }

  Future<void> _saveTokenToFirestore(String token) async {
    try {
      await FirebaseFirestore.instance.collection('device_tokens').doc(token).set({
        'token': token,
        'createdAt': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.toString(),
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) print("Error saving token: $e");
    }
  }

  void _loadUrl({String? url}) {
    final String urlToLoad = url ?? 'https://community.fertilityshare.com/';
    if (kDebugMode) {
      print("Loading URL: $urlToLoad");
    }
    _controller.loadRequest(Uri.parse(urlToLoad));
  }

  Future<bool?> _showExitConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Do you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    selectNotificationStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        
        if (await _controller.canGoBack()) {
          _controller.goBack();
        } else {
          final bool shouldExit = await _showExitConfirmationDialog() ?? false;
          if (shouldExit && context.mounted) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              RefreshIndicator(
                color: const Color(0xFFFF4081),
                onRefresh: () async {
                  await _controller.reload();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: MediaQuery.of(context).size.height,
                    child: WebViewWidget(controller: _controller),
                  ),
                ),
              ),
              if (_hasError)
                Container(
                  color: Colors.white,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('Offline or Loading Error',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ElevatedButton(onPressed: () => _loadUrl(), child: const Text('Try Again')),
                      ],
                    ),
                  ),
                ),
              if (_isLoadingPage && !_hasError)
                const Center(
                  child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4081))),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
