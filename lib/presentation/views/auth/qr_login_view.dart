import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:inum/presentation/design_system/colors.dart';

class QrLoginView extends StatefulWidget {
  final String? currentToken;
  final String? currentUserId;
  const QrLoginView({super.key, this.currentToken, this.currentUserId});
  @override
  State<QrLoginView> createState() => _QrLoginViewState();
}

class _QrLoginViewState extends State<QrLoginView> {
  bool _isScanning = false;
  String? _scannedData;
  late String _qrPayload;

  @override
  void initState() {
    super.initState();
    _refreshPayload();
  }

  void _refreshPayload() {
    _qrPayload = jsonEncode({
      'type': 'inum_qr_login',
      'token': widget.currentToken ?? 'demo-token',
      'userId': widget.currentUserId ?? 'unknown',
      'device': 'flutter-app',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Code Login'), centerTitle: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          _buildQrDisplay(),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),
          _buildScanSection(),
        ]),
      ),
    );
  }

  Widget _buildQrDisplay() {
    return Column(children: [
      const Icon(Icons.qr_code_2, size: 32, color: inumPrimary),
      const SizedBox(height: 12),
      const Text('Show this QR code on desktop', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      const Text('Scan with your mobile device to login instantly.', textAlign: TextAlign.center, style: TextStyle(color: customGreyColor600)),
      const SizedBox(height: 24),
      Container(
        width: 220, height: 220, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 12, offset: const Offset(0, 4))]),
        child: CustomPaint(size: const Size(188, 188), painter: _SimpleQrPainter(data: _qrPayload)),
      ),
      const SizedBox(height: 16),
      const Text('Expires in 5 minutes', style: TextStyle(fontSize: 12, color: customGreyColor500)),
      const SizedBox(height: 8),
      TextButton.icon(onPressed: () => setState(() => _refreshPayload()),
        icon: const Icon(Icons.refresh, size: 18), label: const Text('Refresh QR Code')),
    ]);
  }

  Widget _buildScanSection() {
    return Column(children: [
      const Icon(Icons.phone_android, size: 32, color: inumSecondary),
      const SizedBox(height: 12),
      const Text('Scan QR Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      const Text('Already logged in on mobile? Scan a QR code to login on another device.', textAlign: TextAlign.center, style: TextStyle(color: customGreyColor600)),
      const SizedBox(height: 24),
      if (_isScanning) ...[
        Container(width: 250, height: 250,
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
          child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.camera_alt, color: white, size: 48), SizedBox(height: 12),
            Text('Camera preview\n(Scanner integration pending)', textAlign: TextAlign.center, style: TextStyle(color: white, fontSize: 13))]))),
        const SizedBox(height: 12),
        TextButton(onPressed: () => setState(() { _isScanning = false; _scannedData = 'demo_scan'; }),
          child: const Text('Simulate Scan')),
        TextButton(onPressed: () => setState(() => _isScanning = false),
          child: const Text('Cancel', style: TextStyle(color: errorColor))),
      ] else ...[
        ElevatedButton.icon(
          onPressed: () => setState(() => _isScanning = true),
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Open Scanner'),
          style: ElevatedButton.styleFrom(backgroundColor: inumSecondary, foregroundColor: white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      ],
      if (_scannedData != null) ...[
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: successColor.withAlpha(20), borderRadius: BorderRadius.circular(8),
            border: Border.all(color: successColor.withAlpha(60))),
          child: const Row(children: [
            Icon(Icons.check_circle, color: successColor, size: 20), SizedBox(width: 8),
            Expanded(child: Text('QR code scanned successfully! Authenticating...',
              style: TextStyle(color: successColor, fontSize: 13)))])),
      ],
    ]);
  }
}

class _SimpleQrPainter extends CustomPainter {
  final String data;
  _SimpleQrPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 21;
    final paint = Paint()..color = Colors.black;
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    final bytes = data.codeUnits;
    final hash = data.hashCode;
    _drawFinder(canvas, paint, bgPaint, 0, 0, cellSize);
    _drawFinder(canvas, paint, bgPaint, 14 * cellSize, 0, cellSize);
    _drawFinder(canvas, paint, bgPaint, 0, 14 * cellSize, cellSize);
    for (int row = 0; row < 21; row++) {
      for (int col = 0; col < 21; col++) {
        if ((row < 8 && col < 8) || (row < 8 && col > 12) || (row > 12 && col < 8)) continue;
        final idx = (row * 21 + col) % bytes.length;
        final val = (bytes[idx] + hash + row * 3 + col * 7) & 0xFF;
        if (val > 128) canvas.drawRect(Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize), paint);
      }
    }
  }

  void _drawFinder(Canvas canvas, Paint dark, Paint light, double x, double y, double cell) {
    canvas.drawRect(Rect.fromLTWH(x, y, cell * 7, cell * 7), dark);
    canvas.drawRect(Rect.fromLTWH(x + cell, y + cell, cell * 5, cell * 5), light);
    canvas.drawRect(Rect.fromLTWH(x + cell * 2, y + cell * 2, cell * 3, cell * 3), dark);
  }

  @override
  bool shouldRepaint(covariant _SimpleQrPainter oldDelegate) => data != oldDelegate.data;
}
