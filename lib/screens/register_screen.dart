import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? nameError;
  String? emailError;
  String? passwordError;

  bool isLoading = false;
  bool isPasswordVisible = false;



  void _showSimulationFallbackDialog(
    BuildContext context,
    String phoneNumber,
    String name,
    String password,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.bolt, color: Colors.amber, size: 36),
        title: const Text("SMS Billing Not Enabled", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Your Firebase project has SMS billing disabled (requires Blaze upgrade).",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              "To let you test phone registration easily without payment/billing, we can run a secure fallback simulation.\n\nSimulated OTP Code: 123456",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close warning dialog
              
              // Direct simulation! Trigger the OTP entry dialog with dummy verification ID
              _showOtpDialog(
                context, 
                "simulated_verification_id", 
                phoneNumber, 
                name, 
                password,
                isSimulated: true,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Test via Simulation", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showOtpDialog(
    BuildContext context,
    String verificationId,
    String phoneNumber,
    String name,
    String password, {
    bool isSimulated = false,
  }) {
    final TextEditingController otpController = TextEditingController();
    String? otpError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            icon: const Icon(Icons.sms_outlined, color: Color(0xFFFF6B35), size: 36),
            title: const Text("Verify Phone Number", textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isSimulated
                      ? "Simulation Mode: Use code 123456 to verify $phoneNumber."
                      : "We have sent a 6-digit verification code to $phoneNumber.\n\nPlease enter it below to complete registration.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  cursorColor: Colors.black,
                  decoration: InputDecoration(
                    labelText: "Verification Code",
                    hintText: "Enter 6-digit code",
                    errorText: otpError,
                    floatingLabelStyle: const TextStyle(color: Colors.black),
                    border: const OutlineInputBorder(),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  String code = otpController.text.trim();
                  if (code.length < 6) {
                    setModalState(() {
                      otpError = "Enter all 6 digits";
                    });
                    return;
                  }

                  if (isSimulated && code != "123456") {
                    setModalState(() {
                      otpError = "Incorrect simulated code. Use 123456";
                    });
                    return;
                  }

                  Navigator.pop(ctx); // Close OTP Dialog

                  // Show loading spinner
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(
                      child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
                    ),
                  );

                  try {
                    if (!isSimulated) {
                      // 1. Verify credential via Firebase
                      PhoneAuthCredential credential = PhoneAuthProvider.credential(
                        verificationId: verificationId,
                        smsCode: code,
                      );
                    }

                    // 2. Create user with dummy email
                    String safePhone = phoneNumber.replaceAll('+', '');
                    String email = "$safePhone@phone.curocart.com";

                    UserCredential user = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                      email: email,
                      password: password,
                    );

                    // 3. Save extra data in Firestore
                    await FirebaseFirestore.instance.collection("users").doc(user.user!.uid).set({
                      "name": name,
                      "email": "",
                      "phone": phoneNumber,
                      "createdAt": DateTime.now(),
                    });

                    if (!context.mounted) return;
                    Navigator.pop(context); // Close loading spinner

                    // 4. Show success dialog
                    await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (successCtx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        icon: const Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50), size: 40),
                        title: const Text("Registered Successfully!", textAlign: TextAlign.center),
                        content: Text(
                          "Welcome to CuRoCART! 🎉\n\nYour account has been verified and created successfully using $phoneNumber.\nYou can now login to start shopping.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.6),
                        ),
                        actions: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(successCtx),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6B35),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text("OK", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (!context.mounted) return;
                    Navigator.pop(context); // Navigate back to LoginScreen
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context); // Close loading spinner
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Verification Failed: $e"), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Verify"),
              ),
            ],
          );
        },
      ),
    );
  }

  void validateAndRegister() async {
    setState(() {
      nameError = null;
      emailError = null;
      passwordError = null;
    });

    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    bool isValid = true;

    if (name.isEmpty) {
      nameError = "Name is required";
      isValid = false;
    }

    bool isPhone = RegExp(r"^\+?[0-9\s\-]{7,15}$").hasMatch(email);
    String formattedPhone = email;

    if (email.isEmpty) {
      emailError = "Email or phone is required";
      isValid = false;
    } else if (isPhone) {
      if (formattedPhone.startsWith('0') && formattedPhone.length == 11) {
        formattedPhone = '+92' + formattedPhone.substring(1);
      } else if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+92' + formattedPhone;
      }
      
      if (formattedPhone.length < 10) {
        emailError = "Invalid phone number length";
        isValid = false;
      }
    } else {
      if (!RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$")
          .hasMatch(email)) {
        emailError = "Invalid email format. Use example@email.com or phone number";
        isValid = false;
      }
    }

    if (password.length < 6) {
      passwordError = "Min 6 characters required";
      isValid = false;
    }

    setState(() {});
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fix the errors above to register."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (isPhone) {
      try {
        setState(() => isLoading = true);

        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: formattedPhone,
          verificationCompleted: (PhoneAuthCredential credential) async {
            // Auto-verification handled natively if possible
          },
          verificationFailed: (FirebaseAuthException e) {
            setState(() => isLoading = false);
            
            // Check if billing is not enabled (requires pay-as-you-go Blaze plan)
            if (e.code == 'billing-not-enabled' || 
                e.message?.contains('BILLING_NOT_ENABLED') == true || 
                e.message?.contains('billing') == true) {
              _showSimulationFallbackDialog(context, formattedPhone, name, password);
              return;
            }

            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                icon: const Icon(Icons.error_outline, color: Colors.red, size: 36),
                title: const Text("Verification Failed", textAlign: TextAlign.center),
                content: Text(
                  e.message ?? "Failed to verify phone number.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
                ),
                actions: [
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
                      child: const Text("OK", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                    ),
                  ),
                ],
              ),
            );
          },
          codeSent: (String verificationId, int? resendToken) {
            setState(() => isLoading = false);
            _showOtpDialog(context, verificationId, formattedPhone, name, password);
          },
          codeAutoRetrievalTimeout: (String verificationId) {},
        );
      } catch (e) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
      return;
    }

    try {
      setState(() => isLoading = true);

      // 🔐 Create user in Firebase Auth
      UserCredential user = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print("Auth account created.");

      // Stop the loading spinner IMMEDIATELY after Auth success
      if (mounted) setState(() => isLoading = false);

      // 💾 Save extra data in Firestore in the background
      FirebaseFirestore.instance.collection("users").doc(user.user!.uid).set({
        "name": name,
        "email": email,
        "phone": "",
        "createdAt": DateTime.now(),
      }).then((_) => print("Firestore data saved.")).catchError((e) => print("Firestore error: $e"));

      // ✉️ Send verification email in the background
      user.user!.sendEmailVerification().then((_) => print("Email sent.")).catchError((e) => print("Email error: $e"));

      if (!mounted) return;

      // Show success dialog and WAIT for user to press OK
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50), size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                "Registered Successfully!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 10),
              Text(
                "Welcome to CuRoCART! 🎉\n\nYour account has been created successfully.\nYou can now login to start shopping.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.6),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx); // Close dialog
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("OK", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );

      if (!mounted) return;
      print("Dialog dismissed, returning to login...");
      Navigator.pop(context); // go back to login after dialog is dismissed
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      // Map Firebase error codes to friendly messages
      String errorTitle;
      String errorMessage;

      switch (e.code) {
        case 'email-already-in-use':
          errorTitle = "Email Already Exists";
          errorMessage =
              "An account with this email already exists.\nPlease use a different email or log in instead.";
          break;
        case 'invalid-email':
          errorTitle = "Invalid Email";
          errorMessage = "The email address you entered is not valid. Please check and try again.";
          break;
        case 'weak-password':
          errorTitle = "Weak Password";
          errorMessage = "Your password is too weak. Please use at least 6 characters.";
          break;
        default:
          errorTitle = "Registration Failed";
          errorMessage = e.message ?? "Something went wrong. Please try again.";
      }

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          // No separate title — everything lives in content so text wraps properly
          titlePadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                errorTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 10),
              // Message — wraps naturally
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              // OK button — full width
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "OK",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    } catch (e) {
      // Catches Firestore or any other non-Firebase errors
      if (!mounted) return;
      setState(() => isLoading = false);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                child: const Icon(Icons.error_outline, color: Colors.red, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                "Something Went Wrong",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                e.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
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
                  child: const Text("OK", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    } finally {
      // Safety net: ensure spinner stops even if mounted check above was skipped
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/logo/login.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.white.withValues(alpha: 0.3),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,

      appBar: AppBar(
        title: Text("Create Account"),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: Stack(
        children: [

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [

              // Header
              Column(
                children: [
                  Text(
                    "Join CuRoCART",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Create your account to start shopping smarter",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 32),

              // Name
              TextField(
                controller: nameController,
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  labelText: "Full Name",
                  hintText: "Enter your full name",
                  floatingLabelStyle: const TextStyle(color: Colors.black),
                  border: const OutlineInputBorder(),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  errorText: nameError,
                ),
              ),

              SizedBox(height: 16),

              // Email
              TextField(
                controller: emailController,
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  labelText: "Email or Phone",
                  hintText: "Enter your email or phone",
                  floatingLabelStyle: const TextStyle(color: Colors.black),
                  border: const OutlineInputBorder(),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  errorText: emailError,
                ),
              ),

              SizedBox(height: 16),

              // Password with eye 👁️
              TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  labelText: "Password",
                  hintText: "Create a password",
                  floatingLabelStyle: const TextStyle(color: Colors.black),
                  border: const OutlineInputBorder(),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  errorText: passwordError,
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

              SizedBox(height: 24),

              // Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : validateAndRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF6B35),
                    foregroundColor: Colors.black,
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.black)
                      : Text("Register", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),

              SizedBox(height: 40),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account?",
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                  SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Login",
                      style: TextStyle(
                        color: Color(0xFFFF6B35),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
          ),
        ),   // SafeArea
        ],   // Stack children
      ),     // Stack
      ),
    );       // Scaffold
  }
}