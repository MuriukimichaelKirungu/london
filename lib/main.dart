import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/auth/login_screen.dart';
import '/branch/branch_selection_screen.dart';
import '/dashboard/dashboard_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint("✅ Firebase initialized successfully.");
    } else {
      Firebase.app();
      debugPrint("ℹ️ Firebase already initialized.");
    }
  } catch (e) {
    debugPrint("⚠️ Firebase initialization error: $e");
  }

  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    debugPrint("✅ Firestore persistence enabled.");
  } catch (e) {
    debugPrint("⚠️ Firestore persistence setup failed: $e");
  }

  runApp(const LondonApp());
}

class LondonApp extends StatefulWidget {
  const LondonApp({super.key});

  @override
  State<LondonApp> createState() => _LondonAppState();
}

class _LondonAppState extends State<LondonApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'London',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      ),
      home: const SplashScreen(),
    );
  }
}

// ---------------------------------------------------------
// 🔹 Splash Screen
// ---------------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    Timer(const Duration(seconds: 3), _checkLoginStatus);
  }

  Future<void> _checkLoginStatus() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _navigateTo(const LoginScreen());
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("employees")
          .doc(user.uid)
          .get();

      if (!snapshot.exists) {
        await FirebaseAuth.instance.signOut();
        _navigateTo(const LoginScreen());
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final isAdmin = data["role"] == "admin";
      final branchKey = data["branch"] ?? "branch1";
      final employeeName = data["username"] ?? "Employee";

      if (isAdmin) {
        _navigateTo(BranchSelectionScreen(
          isAdmin: true,
          employeeName: employeeName,
        ));
      } else {
        _navigateTo(DashboardScreen(
          branchName: branchKey,
          isAdmin: false,
          employeeName: employeeName,
        ));
      }
    } catch (e) {
      await FirebaseAuth.instance.signOut();
      _navigateTo(const LoginScreen());
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent.shade100,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.electrical_services_rounded,
                size: 90,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              const Text(
                "London",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 30),
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}