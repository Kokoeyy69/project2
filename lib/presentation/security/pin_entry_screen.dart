import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neopay_ai/core/services/security_service.dart';
import '../../theme/app_theme.dart';

class PinEntryScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  final String? title;
  final bool isSetup;
  const PinEntryScreen({super.key, this.onSuccess, this.title, this.isSetup = false});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final SecurityService _security = SecurityService.instance;
  String _pin = '';
  String? _confirmPin;
  String? _error;
  bool _showBiometricOption = false;
  bool _isForcedSetup = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  void _checkBiometric() async {
    final hasPin = await _security.hasTransactionPin();
    final bioEnabled = await _security.biometricEnabled;
    if (!widget.isSetup && hasPin && bioEnabled) {
      final result = await _security.authenticateWithBiometrics();
      if (result.success && mounted) {
        widget.onSuccess?.call();
        return;
      }
    }
    if (mounted) setState(() => _showBiometricOption = hasPin && !widget.isSetup);
  }

  void _onKeyTap(String key) {
    HapticFeedback.lightImpact();
    if (_pin.length < 6) {
      setState(() {
        _pin += key;
        _error = null;
      });
      if (_pin.length == 6) _onPinComplete();
    }
  }

  void _onBackspace() {
    HapticFeedback.lightImpact();
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _error = null;
      });
    }
  }

  void _onPinComplete() async {
    final isSetupMode = widget.isSetup || _isForcedSetup;
    if (isSetupMode) {
      if (_confirmPin == null) {
        setState(() {
          _confirmPin = _pin;
          _pin = '';
        });
        return;
      }
      if (_pin != _confirmPin) {
        setState(() {
          _error = 'PINs do not match';
          _pin = '';
          _confirmPin = null;
        });
        return;
      }
      await _security.setTransactionPin(_pin);
      if (mounted) widget.onSuccess?.call();
      return;
    }

    final result = await _security.authenticateWithPin(_pin);
    if (result.success) {
      if (mounted) widget.onSuccess?.call();
    } else {
      setState(() {
        _error = result.error;
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Text(
                widget.title ?? (widget.isSetup || _isForcedSetup ? 'Create PIN' : 'Enter PIN'),
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isSetup || _isForcedSetup
                    ? (_confirmPin == null ? 'Enter a 6-digit PIN' : 'Confirm your PIN')
                    : 'Enter your 6-digit PIN to continue',
                style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final filled = i < _pin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppTheme.primary : AppTheme.glassBackground,
                      border: Border.all(color: AppTheme.glassBorder),
                      boxShadow: filled
                          ? [BoxShadow(color: AppTheme.primary.withAlpha(128), blurRadius: 8)]
                          : null,
                    ),
                  );
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.error)),
              ],
              const SizedBox(height: 40),
              _buildKeypad(),
              const SizedBox(height: 24),
              if (_showBiometricOption)
                TextButton.icon(
                  onPressed: () async {
                    final result = await _security.authenticateWithBiometrics();
                    if (result.success && mounted) widget.onSuccess?.call();
                  },
                  icon: const Icon(Icons.fingerprint, color: AppTheme.primary),
                  label: Text('Use Biometrics', style: GoogleFonts.inter(color: AppTheme.primary)),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  await SecurityService.instance.clearTransactionPin();
                  if (mounted) {
                    setState(() {
                      _isForcedSetup = true;
                      _pin = '';
                      _confirmPin = null;
                      _error = null;
                    });
                  }
                },
                child: Text(
                  'Forgot / Reset PIN',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          for (final row in [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
            ['', '0', 'backspace'],
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: row.map((key) {
                  if (key == '') return const SizedBox(width: 72);
                  if (key == 'backspace') {
                    return _buildKey(Icons.backspace_outlined, onTap: _onBackspace, isIcon: true);
                  }
                  return _buildKey(null, label: key, onTap: () => _onKeyTap(key));
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKey(IconData? icon, {String? label, required VoidCallback onTap, bool isIcon = false}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.glassBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: Center(
              child: isIcon
                  ? Icon(icon, color: AppTheme.textSecondary, size: 24)
                  : Text(
                      label!,
                      style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
