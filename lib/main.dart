
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Added this line
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fertilityshare',
      theme: ThemeData(

       // colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      //  useMaterial3: true,
      ),
     // home: const MyHomePage(title: 'Flutter Demo Home Page'),
      home: const Homepage(), // Corrected this line
    );
  }
}

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}


class _HomepageState extends State<Homepage> {

  late WebViewController _controller;
  bool _isLoadingPage = true; // Added for loading state

  @override
  void initState() {
    super.initState();
    print("[WebViewLoading] initState: _isLoadingPage initial: $_isLoadingPage");

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {
            print("[WebViewLoading] onPageStarted: url - $url");
            if (mounted) { // Check if the widget is still in the tree
              setState(() {
                _isLoadingPage = true;
                print("[WebViewLoading] onPageStarted: setState -> _isLoadingPage: $_isLoadingPage");
              });
            }
          },
          onPageFinished: (String url) {
            print("[WebViewLoading] onPageFinished: url - $url");
            if (mounted) { // Check if the widget is still in the tree
              setState(() {
                _isLoadingPage = false;
                print("[WebViewLoading] onPageFinished: setState -> _isLoadingPage: $_isLoadingPage");
              });
            }
          },
          onHttpError: (HttpResponseError error) {
            print("[WebViewLoading] onHttpError: ${error.toString()}");
          },
          onWebResourceError: (WebResourceError error) {
            print("[WebViewLoading] onWebResourceError: ${error.toString()}");
            // You might want to set _isLoadingPage = false here too,
            // and potentially show an error message.
            if (mounted) {
              setState(() {
                _isLoadingPage = false; 
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
    print("[WebViewLoading] initState: Before loadRequest. _isLoadingPage: $_isLoadingPage");
    _controller.loadRequest(Uri.parse('https://community.fertilityshare.com/'));
    print("[WebViewLoading] initState: After loadRequest. _isLoadingPage: $_isLoadingPage");
  }

  @override
  Widget build(BuildContext context) {
    print("[WebViewLoading] build: _isLoadingPage is: $_isLoadingPage");
    return WillPopScope(
        onWillPop: ()async{
          var canGoBack = await _controller.canGoBack();
          if(canGoBack){
            _controller.goBack();
            return false; // Prevent default back button behavior
          }
          return true; // Allow default back button behavior (exit app)
        },
        child: SafeArea(
          child: Scaffold(
            body: Stack(
              children: <Widget>[
                WebViewWidget(controller: _controller),
                if (_isLoadingPage)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ),
    );
  }
}
