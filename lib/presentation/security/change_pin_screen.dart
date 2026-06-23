import 'package:flutter/material.dart';
import 'package:neopay_ai/core/services/security_service.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  String _currentPin = '';
  String _newPin = '';
  int _step = 0; // 0: old pin, 1: new pin, 2: confirm pin
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pinFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handlePinSubmit() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
final securityService = SecurityService.instance;

      switch (_step) {
        case 0: // Verify old PIN
          final isValid = await securityService.verifyTransactionPin(_currentPin);
          if (isValid) {
            setState(() {
              _step = 1;
              _currentPin = '';
              _pinController.clear();
            });
          } else {
            setState(() {
              _errorMessage = 'Invalid PIN. Please try again.';
            });
          }
          break;

        case 1: // Set new PIN
          setState(() {
            _step = 2;
            _newPin = _currentPin;
            _currentPin = '';
            _pinController.clear();
          });
          break;

        case 2: // Confirm new PIN
          if (_currentPin == _newPin) {
            await securityService.setTransactionPin(_currentPin);
                        if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PIN successfully changed')),
              );
              Navigator.pop(context);
            }
          } else {
            setState(() {
              _errorMessage = 'PINs do not match. Please try again.';
              _step = 1;
              _currentPin = '';
              _pinController.clear();
            });
          }
          break;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onPinChanged(String value) {
    if (value.length <= 6) {
      setState(() {
        _currentPin = value;
      });
    }
  }

  String _getTitle() {
    switch (_step) {
      case 0:
        return 'Enter Current PIN';
      case 1:
        return 'Enter New PIN';
      case 2:
        return 'Confirm New PIN';
      default:
        return 'Change PIN';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  Text(
                    _getTitle(),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _pinController,
                    focusNode: _pinFocusNode,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                    decoration: InputDecoration(
                      counterText: '',
                      errorText: _errorMessage,
                      border: InputBorder.none,
                    ),
                    onChanged: _onPinChanged,
                    onSubmitted: (_) => _handlePinSubmit(),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _handlePinSubmit,
                    child: const Text('Continue'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}