import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool isScanned = false;

  void _onDetect(BarcodeCapture capture) async {
    if (isScanned) return;

    final barcode = capture.barcodes.first;
    final value = barcode.rawValue;

    if (value != null) { 
      isScanned = true;

      HapticFeedback.mediumImpact();

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        // Pop back with the scanned value so the caller (e.g. PairTrolleyScreen)
        // can receive and handle the result.
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
    final boxSize = size.width * 0.75;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Scan QR Code"),
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
            painter: _ScannerOverlay(boxSize: boxSize),
          ),

          const Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  "Align QR code inside the box",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                SizedBox(height: 6),
                Text(
                  "Scanning happens automatically",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 🎨 Overlay (unchanged)
class _ScannerOverlay extends CustomPainter {
  final double boxSize;

  _ScannerOverlay({required this.boxSize});

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6);

    final center = Offset(size.width / 2, size.height / 2.5);

    final scanRect = Rect.fromCenter(
      center: center,
      width: boxSize,
      height: boxSize,
    );

    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawRect(fullRect, overlayPaint);

    canvas.saveLayer(fullRect, Paint());

    canvas.drawRect(fullRect, overlayPaint);

    final clearPaint = Paint()..blendMode = BlendMode.clear;

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, const Radius.circular(16)),
      clearPaint,
    );

    canvas.restore();

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, const Radius.circular(16)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}