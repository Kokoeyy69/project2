import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../routes/app_routes.dart';

class QrScanViewModel extends ChangeNotifier {
  bool? _hasPermission;
  bool _isScanning = true;
  
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    formats: [BarcodeFormat.qrCode],
    facing: CameraFacing.back,
  );

  bool? get hasPermission => _hasPermission;
  bool get isScanning => _isScanning;

  QrScanViewModel() {
    checkPermission();
  }

  Future<void> checkPermission() async {
    final status = await Permission.camera.request();
    _hasPermission = status.isGranted;
    notifyListeners();
  }

  void onDetect(BarcodeCapture capture, BuildContext context) {
    if (!_isScanning || capture.barcodes.isEmpty) return;

    final String? rawValue = capture.barcodes.first.rawValue;
    
    if (rawValue != null && rawValue.isNotEmpty) {
      _isScanning = false;
      notifyListeners();
      
      HapticFeedback.vibrate();
      
      // Navigate to transfer keypad with QR data as argument
      Navigator.pushReplacementNamed(
        context, 
        AppRoutes.transferKeypadScreen, 
        arguments: rawValue,
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}