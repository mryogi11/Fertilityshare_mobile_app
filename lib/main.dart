import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();

  // Set background messaging handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
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
    
    _setupFirebaseMessaging();
    
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

    _loadUrl();
  }

  Future<void> _setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 1. Request permissions
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Get token and save to Firestore
      String? token = await messaging.getToken();
      if (token != null) {
        if (kDebugMode) print("FCM Token: $token");
        await _saveTokenToFirestore(token);
      }
    }

    // 3. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showForegroundNotification(message.notification!);
      }
    });

    // 4. Handle notification taps (when app is in background but NOT closed)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) print('A new onMessageOpenedApp event was published!');
      _handleNotificationClick(message);
    });

    // 5. Handle notification taps (when app was CLOSED)
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(initialMessage);
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    // For now, just refresh the WebView or navigate to home
    _loadUrl();
    
    // Log the interaction
    MyApp.analytics.logEvent(
      name: 'notification_opened',
      parameters: {'message_id': message.messageId ?? ''},
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

  void _showForegroundNotification(RemoteNotification notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${notification.title}: ${notification.body}"),
        backgroundColor: const Color(0xFFFF4081),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: _loadUrl,
        ),
      ),
    );
  }

  void _loadUrl() {
    _controller.loadRequest(Uri.parse('https://community.fertilityshare.com/'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_hasError)
              Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Offline or Loading Error', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: _loadUrl, child: const Text('Try Again')),
                    ],
                  ),
                ),
              ),
            if (_isLoadingPage && !_hasError)
              const Center(
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4081))),
              ),
          ],
        ),
      ),
    );
  }
}
