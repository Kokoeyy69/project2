import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:neopay_ai/core/services/security_service.dart';

class TwoFactorSetupScreen extends StatefulWidget {
  final String userEmail;

  const TwoFactorSetupScreen({super.key, required this.userEmail});

  @override
  State<TwoFactorSetupScreen> createState() => _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends State<TwoFactorSetupScreen> {
  late Future<Map<String, String>> _setupFuture;
  final TextEditingController _otpController = TextEditingController();
  String? _secret;

  @override
  void initState() {
    super.initState();
    _setupFuture = _initSetup();
  }

  Future<Map<String, String>> _initSetup() async {
    final data = await SecurityService.instance.generate2FASecret(widget.userEmail);
    _secret = data['secret'];
    return data;
  }

  Future<void> _verifyAndActivate() async {
    if (_secret == null) return;
    
    final isValid = await SecurityService.instance.verifyTOTP(_secret!, _otpController.text);
    if (isValid) {
      await SecurityService.instance.set2FASecret(_secret!);
      await SecurityService.instance.setTwoFactorEnabled(true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('2FA Activated Successfully')));
        Navigator.of(context).pop(true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid code. Try again.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup 2FA')),
      body: FutureBuilder<Map<String, String>>(
        future: _setupFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final secret = snapshot.data!['secret']!;
          final uri = snapshot.data!['uri']!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                QrImageView(data: uri, size: 200),
                const SizedBox(height: 20),
                Text('Secret: $secret'),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => Clipboard.setData(ClipboardData(text: secret)),
                ),
                TextField(
                  controller: _otpController,
                  decoration: const InputDecoration(labelText: '6-Digit Code'),
                  keyboardType: TextInputType.number,
                ),
                ElevatedButton(
                  onPressed: _verifyAndActivate,
                  child: const Text('Verifikasi & Aktifkan'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}