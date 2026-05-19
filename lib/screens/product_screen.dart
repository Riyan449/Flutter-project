import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'payment_screen.dart';
import 'product_barcode_scanner.dart';

class ProductScreen extends StatefulWidget {
  final String scannedCode;

  const ProductScreen({super.key, required this.scannedCode});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final Map<String, Map<String, dynamic>> cart = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartString = prefs.getString('saved_cart');

      if (cartString != null && cartString.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(cartString);
        setState(() {
          cart.clear();
          decoded.forEach((key, value) {
            cart[key] = Map<String, dynamic>.from(value as Map);
          });
        });
      }
    } catch (e) {
      debugPrint("Error loading cart: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_cart', jsonEncode(cart));
    } catch (e) {
      debugPrint("Error saving cart: $e");
    }
  }

  Future<void> _handleScan(String rawValue) async {
    final value = rawValue.trim();

    // ── REMOVE barcode scanned ───────────────────────────────────────────
    if (value.startsWith('REMOVE::')) {
      final barcode = value.replaceFirst('REMOVE::', '');
      _removeProduct(barcode);
      return;
    }

    // ── Normal ADD barcode scanned ───────────────────────────────────────
    await _addProduct(value);
  }

  Future<void> _addProduct(String code) async {
    if (cart.containsKey(code)) {
      setState(() => cart[code]!['qty'] += 1);
      await _saveCart();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(code)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data()!;

        // Robust parsing
        double parsedPrice = 0.0;
        if (data['price'] is num) {
          parsedPrice = (data['price'] as num).toDouble();
        } else if (data['price'] is String) {
          parsedPrice = double.tryParse(data['price'] as String) ?? 0.0;
        }

        int parsedStock = 0;
        if (data['stock'] is num) {
          parsedStock = (data['stock'] as num).toInt();
        } else if (data['stock'] is String) {
          parsedStock = int.tryParse(data['stock'] as String) ?? 0;
        }

        setState(() {
          cart[code] = {
            "name":     data['name']?.toString() ?? 'Unknown Product',
            "price":    parsedPrice,
            "category": data['category']?.toString() ?? '',
            "stock":    parsedStock,
            "qty":      1,
          };
        });
        await _saveCart();
        _showSuccess("${data['name']} added to cart");
      } else {
        _showError("Product not found: $code");
      }
    } catch (e) {
      debugPrint("Error fetching product: $e");
      _showError("Error fetching product. Check connection.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _removeProduct(String code) {
    if (!cart.containsKey(code)) {
      _showError("Item not in cart.");
      return;
    }

    final name = cart[code]!['name'];
    setState(() {
      if (cart[code]!['qty'] > 1) {
        cart[code]!['qty'] -= 1;
        _showSuccess("1 x $name removed");
      } else {
        cart.remove(code);
        _showSuccess("$name removed from cart");
      }
    });
    _saveCart();
  }

  void _scanProduct() async {
    final scannedCode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProductBarcodeScanner()),
    );

    if (scannedCode != null && scannedCode is String) {
      await _handleScan(scannedCode);
    }
  }

  double get totalPrice {
    double total = 0;
    cart.forEach((_, item) => total += item['price'] * item['qty']);
    return total;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _goToBilling() {
    if (cart.isEmpty) {
      _showError("Cart is empty. Scan a product first.");
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PaymentScreen(cart: cart)),
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
        title: Column(
          children: [
            const Text("Your Cart", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text("Trolley: ${widget.scannedCode}", style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacementNamed(context, '/pairTrolley'),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.barcode_reader, color: Colors.white),
              onPressed: _scanProduct,
              tooltip: "Scan Product",
            ),
          const SizedBox(width: 8),
        ],
      ),

      body: Stack(
        children: [


          // Main content
          Column(
            children: [

              // Legend banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFFFFF3EF),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: Color(0xFFFF6B35)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Scan green barcode to ADD • Scan red barcode to REMOVE",
                        style: TextStyle(fontSize: 11, color: Color(0xFFFF6B35)),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: cart.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.qr_code_scanner, size: 72, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text("No items yet",
                                style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                            const SizedBox(height: 6),
                            Text("Tap the barcode icon to scan a product",
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: cart.length,
                        itemBuilder: (context, index) {
                          final code = cart.keys.elementAt(index);
                          final item = cart[code]!;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['name'],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1A1A2E))),
                                      if ((item['category'] as String).isNotEmpty)
                                        Text(item['category'],
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade500)),
                                      Text("Rs ${item['price'].toStringAsFixed(0)}"),
                                    ],
                                  ),
                                ),

                                // Quantity Display (Non-editable)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text("Qty: ${item['qty']}",
                                      style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
                                ),

                                const SizedBox(width: 12),
                                Text(
                                  "Rs ${(item['price'] * item['qty']).toStringAsFixed(0)}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // Total + Button
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total (${cart.length} item${cart.length == 1 ? '' : 's'})",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Rs ${totalPrice.toStringAsFixed(0)}",
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF6B35)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _goToBilling,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("Proceed to Payment",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}