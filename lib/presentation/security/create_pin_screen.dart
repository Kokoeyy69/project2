import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../core/services/security_service.dart';

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isSettingPin = true;
  bool _isLoading = false;
  String? _error;

  void _onDigitPressed(String digit) {
    if (_isLoading) return;
    
    setState(() {
      _error = null;
      if (_isSettingPin) {
        if (_pin.length < 6) {
          _pin += digit;
        }
      } else {
        if (_confirmPin.length < 6) {
          _confirmPin += digit;
        }
      }
    });

    // Auto-submit when 6 digits entered
    if (_isSettingPin && _pin.length == 6) {
      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() {
          _isSettingPin = false;
        });
      });
    } else if (!_isSettingPin && _confirmPin.length == 6) {
      _submitPin();
    }
  }

  void _onBackspacePressed() {
    if (_isLoading) return;
    
    setState(() {
      _error = null;
      if (_isSettingPin) {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      }
    });
  }

  Future<void> _submitPin() async {
    if (_pin != _confirmPin) {
      setState(() {
        _error = 'PIN tidak cocok. Silakan coba lagi.';
        _confirmPin = '';
        _isSettingPin = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await SecurityService().setTransactionPin(_pin);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _error = 'Gagal menyimpan PIN. Silakan coba lagi.';
        _isLoading = false;
        _pin = '';
        _confirmPin = '';
        _isSettingPin = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          _isSettingPin ? 'Buat PIN Transaksi' : 'Konfirmasi PIN',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryMuted,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 40,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                _isSettingPin ? 'Masukkan 6 digit PIN' : 'Konfirmasi PIN Anda',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isSettingPin
                    ? 'PIN ini akan digunakan untuk setiap transaksi'
                    : 'Pastikan PIN yang Anda masukkan sama',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.errorMuted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final currentPin = _isSettingPin ? _pin : _confirmPin;
                  final isFilled = index < currentPin.length;
                  final isCurrent = index == currentPin.length;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isFilled
                          ? AppTheme.primary
                          : isCurrent
                              ? AppTheme.primary.withAlpha(40)
                              : AppTheme.glassBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent
                            ? AppTheme.primary
                            : AppTheme.glassBorder,
                        width: isCurrent ? 2 : 0.5,
                      ),
                    ),
                    child: Center(
                      child: isFilled
                          ? Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),
              // Keypad
              Expanded(
                child: Column(
                  children: [
                    for (var row = 0; row < 3; row++)
                      Expanded(
                        child: Row(
                          children: [
                            for (var col = 0; col < 3; col++)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: _buildKeypadButton(
                                    '${row * 3 + col + 1}',
                                    () => _onDigitPressed('${row * 3 + col + 1}'),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    // Bottom row: empty, 0, backspace
                    Expanded(
                      child: Row(
                        children: [
                          const Expanded(child: SizedBox()),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: _buildKeypadButton(
                                '0',
                                () => _onDigitPressed('0'),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: _buildKeypadButton(
                                null,
                                _onBackspacePressed,
                                icon: Icons.backspace_outlined,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String? label, VoidCallback onPressed, {IconData? icon}) {
    return Material(
      color: AppTheme.glassBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.glassBorder, width: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: label != null
                ? Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  )
                : Icon(
                    icon,
                    size: 28,
                    color: AppTheme.textPrimary,
                  ),
          ),
        ),
      ),
    );
  }
}