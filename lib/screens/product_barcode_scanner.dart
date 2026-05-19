import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';

class ProductBarcodeScanner extends StatefulWidget {
  const ProductBarcodeScanner({super.key});

  @override
  State<ProductBarcodeScanner> createState() => _ProductBarcodeScannerState();
}

class _ProductBarcodeScannerState extends State<ProductBarcodeScanner> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: [BarcodeFormat.all], // Support all formats including barcodes
  );

  bool isScanned = false;

  void _onDetect(BarcodeCapture capture) async {
    if (isScanned || capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final value = barcode.rawValue;

    if (value != null) {
      isScanned = true;

      HapticFeedback.mediumImpact();

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        Navigator.pop(context, value);
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Wider and shorter box for barcodes
    final boxWidth = size.width * 0.85;
    final boxHeight = size.width * 0.45;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Product Barcode Scanner"),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),

      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),

          CustomPaint(
            size: Size.infinite,
            painter: _ScannerOverlay(boxWidth: boxWidth, boxHeight: boxHeight),
          ),

          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  "Align product barcode inside the box",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Scanning happens automatically",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          
          // Add a red scanning line animation effect
          Center(
            child: Container(
              width: boxWidth,
              height: 2,
              color: Colors.red.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlay extends CustomPainter {
  final double boxWidth;
  final double boxHeight;

  _ScannerOverlay({required this.boxWidth, required this.boxHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7);

    final center = Offset(size.width / 2, size.height / 2.5);

    final scanRect = Rect.fromCenter(
      center: center,
      width: boxWidth,
      height: boxHeight,
    );

    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawRect(fullRect, overlayPaint);

    canvas.saveLayer(fullRect, Paint());

    canvas.drawRect(fullRect, overlayPaint);

    final clearPaint = Paint()..blendMode = BlendMode.clear;

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, const Radius.circular(8)),
      clearPaint,
    );

    canvas.restore();

    final borderPaint = Paint()
      ..color = const Color(0xFFFF6B35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, const Radius.circular(8)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
