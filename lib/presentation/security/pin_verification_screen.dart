import 'dart:async';
import 'package:flutter/material.dart';
import 'package:neopay_ai/core/services/security_service.dart';

class PinVerificationScreen extends StatefulWidget {
  const PinVerificationScreen({super.key});

  @override
  State<PinVerificationScreen> createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen> {
  final _securityService = SecurityService();
  String _pin = '';
  int _attempts = 0;
  bool _isLocked = false;
  Timer? _lockTimer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _securityService.setupInitialPin();
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    super.dispose();
  }

  void _onNumberPressed(int number) {
    if (_isLocked) return;
    if (_pin.length < 6) {
      setState(() {
        _pin += number.toString();
      });
      if (_pin.length == 6) {
        _handlePinSubmit();
      }
    }
  }

  void _onDeletePressed() {
    if (_isLocked) return;
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  Future<void> _handlePinSubmit() async {
    final isValid = await _securityService.verifyPin(_pin);
    if (isValid) {
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      setState(() {
        _attempts++;
        _pin = '';
      });
      if (_attempts >= 3) {
        _lockScreen();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PIN salah. Sisa percobaan: ${3 - _attempts}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _lockScreen() {
    setState(() {
      _isLocked = true;
      _secondsLeft = 30;
    });

    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          _isLocked = false;
          _attempts = 0;
          _pin = '';
          _lockTimer?.cancel();
        }
      });
    });
  }

  Future<void> _handleBiometric() async {
    if (_isLocked) return;
    final authenticated = await _securityService.authenticateBiometric();
    if (authenticated && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verifikasi PIN'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Text(
              'Masukkan PIN Transaksi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),
            const Text(
              'Demi keamanan transaksi Anda, silakan verifikasi PIN',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                final filled = index < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? Colors.blue : Colors.grey.shade300,
                  ),
                );
              }),
            ),
            if (_isLocked) ...[
              const SizedBox(height: 16),
              Text(
                'Terlalu banyak percobaan salah.\nLayar dikunci selama $_secondsLeft detik.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
            const Spacer(),
            _buildKeypad(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('1', onPressed: () => _onNumberPressed(1)),
              _buildKeypadButton('2', onPressed: () => _onNumberPressed(2)),
              _buildKeypadButton('3', onPressed: () => _onNumberPressed(3)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('4', onPressed: () => _onNumberPressed(4)),
              _buildKeypadButton('5', onPressed: () => _onNumberPressed(5)),
              _buildKeypadButton('6', onPressed: () => _onNumberPressed(6)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('7', onPressed: () => _onNumberPressed(7)),
              _buildKeypadButton('8', onPressed: () => _onNumberPressed(8)),
              _buildKeypadButton('9', onPressed: () => _onNumberPressed(9)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton(
                '',
                icon: Icons.fingerprint,
                iconColor: _isLocked ? Colors.grey : Colors.blue,
                onPressed: _handleBiometric,
              ),
              _buildKeypadButton('0', onPressed: () => _onNumberPressed(0)),
              _buildKeypadButton(
                '',
                icon: Icons.backspace_outlined,
                iconColor: Colors.black,
                onPressed: _onDeletePressed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(
    String text, {
    IconData? icon,
    Color? iconColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 80,
      height: 80,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: Colors.white,
          elevation: 1,
          shadowColor: Colors.black12,
        ),
        child: icon != null
            ? Icon(icon, size: 28, color: iconColor)
            : Text(
                text,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
              ),
      ),
    );
  }
}