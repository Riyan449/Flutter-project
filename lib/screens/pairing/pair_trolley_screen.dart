// import 'package:flutter/material.dart';
// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
// import '../product_screen.dart';
//
// class PairTrolleyScreen extends StatelessWidget {
//   const PairTrolleyScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFFF5F5F7),
//
//       appBar: AppBar(
//         title: Text("Connect Trolley"),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 0,
//       ),
//
//       body: Padding(
//         padding: EdgeInsets.all(24),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//
//             // Title
//             Text(
//               "How would you like to connect?",
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//
//             SizedBox(height: 40),
//
//             // 🔵 Bluetooth Button
//             SizedBox(
//               width: double.infinity,
//               height: 60,
//               child: ElevatedButton.icon(
//                 icon: Icon(Icons.bluetooth),
//                 label: Text("Connect via Bluetooth"),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Color(0xFFFF6B35),
//                 ),
//                 onPressed: () async {
//                   final result = await Navigator.pushNamed(context, '/bluetooth');
//
//                   if (!context.mounted) return;
//
//                   if (result != null && (result is BluetoothConnection || result is String)) {
//                     showDialog(
//                       context: context,
//                       barrierDismissible: false,
//                       builder: (context) => const Center(
//                         child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
//                       ),
//                     );
//
//                     // Simulate pairing delay
//                     await Future.delayed(const Duration(seconds: 1));
//
//                     if (!context.mounted) return;
//                     Navigator.pop(context); // Close dialog
//
//                     // Navigate to Product Screen
//                     Navigator.pushReplacement(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => const ProductScreen(scannedCode: "BT_TROLLEY"),
//                       ),
//                     );
//
//                     // Show success
//                     String displayMsg = result is String ? "Simulated Connection Successful! 🎉" : "Successfully connected to Trolley! 🎉";
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text(displayMsg)),
//                     );
//                   }
//                 },
//               ),
//             ),
//
//             SizedBox(height: 20),
//
//             // 📱 QR Button
//             SizedBox(
//               width: double.infinity,
//               height: 60,
//               child: OutlinedButton.icon(
//                 icon: const Icon(Icons.qr_code_scanner),
//                 label: const Text("Scan QR Code"),
//                 onPressed: () async {
//                   // Wait for the QR Scanner screen to pop back with the result
//                   final scannedCode = await Navigator.pushNamed(context, '/qrScanner');
//
//                   if (!context.mounted) return;
//
//                   if (scannedCode != null && scannedCode is String) {
//                     // Show a fake connecting dialog
//                     showDialog(
//                       context: context,
//                       barrierDismissible: false,
//                       builder: (context) => const Center(
//                         child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
//                       ),
//                     );
//
//                     // Simulate pairing delay
//                     await Future.delayed(const Duration(seconds: 2));
//
//                     if (!context.mounted) return;
//                     Navigator.pop(context); // Close dialog
//
//                     // Navigate to Product Screen
//                     Navigator.pushReplacement(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => ProductScreen(scannedCode: scannedCode),
//                       ),
//                     );
//
//                     // Show success
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text("Successfully paired with Trolley: $scannedCode 🎉")),
//                     );
//                   } else {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text("QR Scan was canceled.")),
//                     );
//                   }
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../product_screen.dart';
// import '../config/app_config.dart';

class PairTrolleyScreen extends StatelessWidget {
  const PairTrolleyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/logo/login.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.white.withValues(alpha: 0.2),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,

        appBar: AppBar(
          title: const Text(
            "Connect Trolley",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          backgroundColor: const Color(0xFFFF6B35),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('trolley_id');
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              tooltip: "Logout",
            ),
          ],
        ),

        body: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Beautiful floating graphic container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      size: 64,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    "How would you like to connect?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Select a method below to sync your device with the smart shopping cart",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Bluetooth Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.bluetooth, color: Colors.white, size: 24),
                      label: const Text(
                        "Connect via Bluetooth",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        elevation: 3,
                        shadowColor: const Color(0xFFFF6B35).withValues(alpha: 0.3),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () async {
                        final result = await Navigator.pushNamed(context, '/bluetooth');

                        if (!context.mounted) return;

                        if (result != null && (result is BluetoothConnection || result is String)) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
                            ),
                          );

                          await Future.delayed(const Duration(seconds: 1));

                          if (!context.mounted) return;
                          Navigator.pop(context);

                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('trolley_id', 'BT_TROLLEY');

                          if (!context.mounted) return;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProductScreen(scannedCode: "BT_TROLLEY"),
                            ),
                          );

                          final displayMsg = result is String
                              ? "Simulated Connection Successful! 🎉"
                              : "Successfully connected to Trolley! 🎉";
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(displayMsg)),
                          );
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // QR Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.qr_code_scanner, color: Color(0xFFFF6B35), size: 24),
                      label: const Text(
                        "Scan QR Code",
                        style: TextStyle(
                          color: Color(0xFFFF6B35),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFF6B35), width: 2),
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        elevation: 1,
                        shadowColor: Colors.black.withValues(alpha: 0.05),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () => _onScanQR(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onScanQR(BuildContext context) async {
    final rawValue = await Navigator.pushNamed(context, '/qrScanner');

    if (!context.mounted) return;

    // Canceled
    if (rawValue == null || rawValue is! String) {
      _showSnack(context, "QR Scan was canceled.");
      return;
    }

    // Parse JSON
    Map<String, dynamic> data;
    try {
      data = jsonDecode(rawValue) as Map<String, dynamic>;
    } catch (_) {
      _showError(context, "Invalid QR code. Please scan your cart QR.");
      return;
    }

    // Check type
    if (data['type'] != 'cart_pair') {
      _showError(context, "This QR code is not a cart QR. Please scan the correct one.");
      return;
    }

    // Check secret key — blocks any foreign QR codes
    if (data['secret'] != AppConfig.cartSecret) {
      _showError(context, "Unrecognized cart QR. Please scan your official cart QR.");
      return;
    }

    // All checks passed
    final cartId   = data['cartId']   as String? ?? 'Unknown Cart';
    final location = data['location'] as String? ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (!context.mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('trolley_id', cartId);

    if (!context.mounted) return;
    Navigator.pop(context);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ProductScreen(scannedCode: cartId),
      ),
    );

    final msg = location.isNotEmpty
        ? "Paired with $cartId ($location) 🎉"
        : "Successfully paired with $cartId 🎉";
    _showSnack(context, msg);
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
      ),
    );
  }
}