import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? emailError;
  String? passwordError;
  bool isLoading = false;
  bool isPasswordVisible = false;
  bool rememberMe = true;



  void validateAndLogin() async {
    setState(() {
      emailError = null;
      passwordError = null;
    });

    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    bool isValid = true;

    if (email.isEmpty) {
      emailError = "Email or phone is required";
      isValid = false;
    }

    if (password.isEmpty) {
      passwordError = "Password is required";
      isValid = false;
    }

    setState(() {});
    if (!isValid) return;

    try {
      setState(() => isLoading = true);

      // Check if input is a phone number
      bool isPhone = RegExp(r"^\+?[0-9\s\-]{7,15}$").hasMatch(email);
      String loginEmail = email;
      if (isPhone) {
        String formattedPhone = email;
        if (formattedPhone.startsWith('0') && formattedPhone.length == 11) {
          formattedPhone = '+92' + formattedPhone.substring(1);
        } else if (!formattedPhone.startsWith('+')) {
          formattedPhone = '+92' + formattedPhone;
        }
        String safePhone = formattedPhone.replaceAll('+', '');
        loginEmail = "$safePhone@phone.curocart.com";
      }

      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: loginEmail,
        password: password,
      );

      if (!mounted) return;

      // Check if the email is verified (skip for verified phone accounts)
      if (userCredential.user != null && 
          !userCredential.user!.emailVerified && 
          !userCredential.user!.email!.endsWith("@phone.curocart.com")) {
        
        // --- 5 MINUTE EXPIRATION CHECK ---
        final creationTime = userCredential.user!.metadata.creationTime;
        if (creationTime != null && DateTime.now().difference(creationTime).inMinutes >= 5) {
          // Delete from Firestore
          try {
            await FirebaseFirestore.instance.collection("users").doc(userCredential.user!.uid).delete();
            // Delete from Firebase Auth (this automatically signs them out too)
            await userCredential.user!.delete();
          } catch (e) {
            print("Error deleting expired user: $e");
          }
          
          if (!mounted) return;
          setState(() => isLoading = false);
          
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: EdgeInsets.zero,
              contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.timer_off_outlined, color: Colors.red, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Link Expired",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "You did not verify your email within 5 minutes. Your account has been automatically deleted from our database.\n\nPlease register again.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("OK", style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
          return; // Stop the login process
        }

        // Sign them out immediately if under 5 mins
        await FirebaseAuth.instance.signOut();
        
        setState(() => isLoading = false);
        
        // Show Dialog explaining they need to verify
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: EdgeInsets.zero,
            contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mark_email_unread_outlined, color: Colors.orange, size: 36),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Email Not Verified",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "Please check your inbox and verify your email address to log in.\nIf you used a fake email, you cannot log in.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("OK", style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
        return; // Stop the login process
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login successful!")),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', rememberMe);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/pairTrolley');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Login failed")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image:const AssetImage('assets/logo/login.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.white.withValues(alpha: 0.2) ,
            BlendMode.srcOver,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [

              SizedBox(height: 32),

              // Header
              Column(
                children: [
                  Text("🛒", style: TextStyle(fontSize: 64)),
                  SizedBox(height: 16),
                  Text(
                    "Welcome Back!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Sign in to continue shopping",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 48),

              // Email Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Email or Phone"),
                  SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    cursorColor: Colors.black,
                    decoration: InputDecoration(
                      hintText: "Enter your email or phone",
                      border: const OutlineInputBorder(),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      errorText: emailError,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Password Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Password"),
                  SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text("Password"),
                      // SizedBox(height: 8),
                      TextField(
                        controller: passwordController,
                        obscureText: !isPasswordVisible,
                        cursorColor: Colors.black,
                        decoration: InputDecoration(
                          hintText: "Enter your password",
                          border: const OutlineInputBorder(),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          errorText: passwordError,

                          // 👇 Eye Icon
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Remember Me Checkbox
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: rememberMe,
                      activeColor: const Color(0xFFFF6B35),
                      checkColor: Colors.black,
                      onChanged: (value) {
                        setState(() {
                          rememberMe = value ?? false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Remember Me",
                    style: TextStyle(color: Color(0xFF1A1A2E), fontSize: 14),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : validateAndLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF6B35),
                    foregroundColor: Colors.black,
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.black)
                      : Text("Login", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),

              SizedBox(height: 40),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                  SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: Text(
                      "Register",
                      style: TextStyle(
                        color: Color(0xFFFF6B35),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
          ),
        ),   // SafeArea
      ),     // Scaffold
    );       // Container
  }
}
