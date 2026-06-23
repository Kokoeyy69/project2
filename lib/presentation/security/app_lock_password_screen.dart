import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../core/services/app_lock_service.dart';

class AppLockPasswordScreen extends StatefulWidget {
  final VoidCallback onUnlock;

  const AppLockPasswordScreen({super.key, required this.onUnlock});

  @override
  State<AppLockPasswordScreen> createState() => _AppLockPasswordScreenState();
}

class _AppLockPasswordScreenState extends State<AppLockPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkBiometrics();
        _passwordFocusNode.requestFocus();
      }
    });
  }

  Future<void> _checkBiometrics() async {
    final appLockService = AppLockService();
    if (appLockService.isBiometricEnabled) {
      final authenticated = await appLockService.authenticate();
      if (authenticated) {
        widget.onUnlock();
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _submitPassword() {
    if (_isSubmitting) return;

    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Enter app lock password');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    // Mandatory unlock: set isLocked to false in service
    AppLockService().unlock();

    // Simulate verification delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isSubmitting = false);
        widget.onUnlock();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 64,
                color: AppTheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'App Locked',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your local app password to continue',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                obscureText: true,
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _submitPassword(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Alphanumeric password',
                  errorText: _errorMessage,
                  prefixIcon: const Icon(Icons.password_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPassword,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Unlock'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
