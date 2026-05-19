import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, Map<String, dynamic>> cart;

  const PaymentScreen({super.key, required this.cart});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedPayment = "Bank";

  double get total {
    double sum = 0;
    widget.cart.forEach((key, item) {
      sum += item['price'] * item['qty'];
    });
    return sum;
  }

  Widget _paymentOption(String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPayment = title;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selectedPayment == title
              ? const Color(0xFFFF6B35).withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selectedPayment == title
                ? const Color(0xFFFF6B35)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selectedPayment == title
                    ? const Color(0xFFFF6B35)
                    : Colors.black),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selectedPayment == title
                    ? const Color(0xFFFF6B35)
                    : Colors.black,
              ),
            ),
            const Spacer(),
            if (selectedPayment == title)
              const Icon(Icons.check_circle, color: Color(0xFFFF6B35)),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.logout, color: Color(0xFFFF6B35), size: 36),
        title: const Text("Sign Out", textAlign: TextAlign.center),
        content: const Text(
          "Are you sure you want to sign out of your account?",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog

              // Show loading spinner
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
                ),
              );

              try {
                // 1. Clear SharedPreferences
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('saved_cart');
                await prefs.remove('trolley_id');

                // 2. Clear Firestore (safely catch permission/network errors so logout is not blocked)
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection('user_carts')
                        .doc(user.uid)
                        .delete();
                  }
                } catch (dbError) {
                  debugPrint("Firestore delete cart error (ignored for signout): $dbError");
                }

                // 3. Sign Out
                await FirebaseAuth.instance.signOut();

                if (!context.mounted) return;
                Navigator.pop(context); // Close spinner
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close spinner
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            child: const Text("Sign Out"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/logo/product.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.white.withValues(alpha: 0.6),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,

      appBar: AppBar(
        title: const Text("Payment"),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showSignOutDialog(context),
            tooltip: "Sign Out",
          ),
        ],
      ),

      body: Stack(
        children: [

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
            /// 🧾 ITEMS
            Expanded(
              child: ListView(
                children: widget.cart.entries.map((entry) {
                  final item = entry.value;

                  return ListTile(
                    title: Text(item['name']),
                    subtitle: Text("Qty: ${item['qty']}"),
                    trailing: Text(
                      "Rs ${item['price'] * item['qty']}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
            ),

            const Divider(),

            /// 💰 TOTAL
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Rs ${total.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B35),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// 💳 PAYMENT OPTIONS
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Select Payment Method",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            _paymentOption("Bank", Icons.account_balance),
            _paymentOption("EasyPaisa", Icons.phone_android),
            _paymentOption("JazzCash", Icons.phone_iphone),

            const SizedBox(height: 20),

            /// ✅ CONFIRM BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // Show loading spinner
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(
                      child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
                    ),
                  );

                  try {
                    // Clear cart from Firestore and Local Storage on success
                    final user = FirebaseAuth.instance.currentUser;
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('saved_cart');
                    await prefs.remove('trolley_id');

                    // Clear Firestore cart safely (catch permission errors so checkout is not blocked)
                    try {
                      if (user != null) {
                        await FirebaseFirestore.instance
                            .collection('user_carts')
                            .doc(user.uid)
                            .delete();
                      }
                    } catch (dbError) {
                      debugPrint("Firestore checkout delete error: $dbError");
                    }

                    // STAY signed in and on the same screen (do not call signOut)

                    if (!mounted) return;
                    Navigator.pop(context); // Close loading spinner

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        icon: const Icon(Icons.check_circle, color: Colors.green, size: 36),
                        title: const Text("Payment Successful", textAlign: TextAlign.center),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Paid via $selectedPayment",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Amount Paid: Rs ${total.toStringAsFixed(0)}",
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Your payment has been successfully processed! You can sign out at any time using the sign out icon at the top right.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, height: 1.4),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx); // Close dialog & stay on the same screen
                            },
                            child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ],
                      ),
                    );
                  } catch (e) {
                    if (mounted) {
                      Navigator.pop(context); // Close loading spinner
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const StadiumBorder(), // Fully round confirm payment button
                ),
                child: const Text("Confirm Payment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),),
              ),
            ),
          ],
          ),
          ),
        ],
      ),
      ),
    );
  }
}