import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'product_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _rotateController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    // Fade Animation
    _fadeController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 800));
    _fadeAnimation =
        Tween<double>(begin: 0, end: 1).animate(_fadeController);

    // Scale Animation
    _scaleController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 800));
    _scaleAnimation =
        Tween<double>(begin: 0.8, end: 1).animate(_scaleController);

    // Rotation Animation (loader)
    _rotateController =
    AnimationController(vsync: this, duration: Duration(milliseconds: 1500))
      ..repeat();
    _rotateAnimation =
        Tween<double>(begin: 0, end: 1).animate(_rotateController);

    // Start animations
    _fadeController.forward();
    _scaleController.forward();

    // Navigate after 2.5 sec
    Timer(Duration(milliseconds: 2500), () async {
      final user = FirebaseAuth.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool('remember_me') ?? false;
      final savedTrolleyId = prefs.getString('trolley_id');

      if (!mounted) return;

      if (user != null && rememberMe) {
        if (savedTrolleyId != null && savedTrolleyId.isNotEmpty) {
          // Stay connected to the trolley
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProductScreen(scannedCode: savedTrolleyId),
            ),
          );
        } else {
          // Logged in but no trolley paired
          Navigator.pushReplacementNamed(context, '/pairTrolley');
        }
      } else {
        // Not logged in OR Remember Me is false
        if (!rememberMe && user != null) {
          await FirebaseAuth.instance.signOut();
          await prefs.remove('trolley_id');
        }
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF6B35),
      body: Stack(
        children: [


          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // Logo Section
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      children: [
                        Text(
                          "🛒",
                          style: TextStyle(fontSize: 80),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "CuRoCART",
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Smart Shopping, Simplified",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 48),

                // Loader
                Column(
                  children: [
                    RotationTransition(
                      turns: _rotateAnimation,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: 3,
                            color: Colors.white30,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            width: 3,
                            height: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Loading...",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    )
                  ],
                ),

                SizedBox(height: 60),

                // Footer
                Text(
                  "Powered by CuRoCART Tech",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}