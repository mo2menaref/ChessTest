import 'package:chess_test/screens/guest_mode.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/user_setup.dart';
import 'screens/rooms_list.dart';
import 'firebase_options.dart';
import 'screens/user_setup.dart';
import 'screens/rooms_list.dart';

void main() async {
  debugPrint('Starting app initialization...');
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  debugPrint('Starting Flutter app...');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Room Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserSessionOrRoomLink();
  }

  _checkUserSessionOrRoomLink() async {
    // Check if we have a direct room link in the URL (for web)
    final uri = Uri.base;
    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'rooms') {
      final roomId = uri.pathSegments[1];
      // Navigate directly to guest room view
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GuestRoomViewScreen(roomId: roomId),
        ),
      );
      return;
    }

    // Normal user session check
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    String? userName = prefs.getString('userName');

    if (userId != null && userName != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RoomsListScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => UserSetupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}