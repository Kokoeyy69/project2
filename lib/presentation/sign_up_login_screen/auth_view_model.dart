import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import '../../services/validation_service.dart';

class AuthViewModel extends ChangeNotifier {
  // Form state
  bool _isLogin = true;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _biometricEnabled = false;
  bool _isFocused = false;
  String? _errorMessage;
  String? emailError;
  String? passwordError;
  int passwordStrength = 0;
  Timer? _emailDebounceTimer;
  Timer? _passwordDebounceTimer;
  final int _debounceDuration = 500; // 500ms debounce delay

  // Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // Auth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Getters
  bool get isLogin => _isLogin;
  bool get passwordVisible => _passwordVisible;
  bool get confirmPasswordVisible => _confirmPasswordVisible;
  bool get rememberMe => _rememberMe;
  bool get isLoading => _isLoading;
  bool get biometricEnabled => _biometricEnabled;
  bool get isFocused => _isFocused;
  String? get errorMessage => _errorMessage;

  // Toggle login/register mode
  void toggleMode() {
    _isLogin = !_isLogin;
    _errorMessage = null;
    emailError = null;
    passwordError = null;
    passwordStrength = 0;
    notifyListeners();
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    _passwordVisible = !_passwordVisible;
    notifyListeners();
  }

  // Toggle confirm password visibility
  void toggleConfirmPasswordVisibility() {
    _confirmPasswordVisible = !_confirmPasswordVisible;
    notifyListeners();
  }

  // Toggle remember me
  void toggleRememberMe() {
    _rememberMe = !_rememberMe;
    notifyListeners();
  }

  // Toggle biometric
  void toggleBiometric() {
    _biometricEnabled = !_biometricEnabled;
    notifyListeners();
  }

  // Set focus
  void setFocused(bool focused) {
    _isFocused = focused;
    notifyListeners();
  }

  // Set error message
  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    emailError = null;
    passwordError = null;
    notifyListeners();
  }

  // Clear all fields
  void clearAllFields() {
    emailController.clear();
    passwordController.clear();
    nameController.clear();
    confirmPasswordController.clear();
    phoneController.clear();
    _errorMessage = null;
    emailError = null;
    passwordError = null;
    passwordStrength = 0;
    notifyListeners();
  }

  // Set demo credentials
  void setDemoCredentials() {
    emailController.text = 'test@test.com';
    passwordController.text = 'password';
    _errorMessage = null;
    emailError = null;
    passwordError = null;
    passwordStrength = ValidationService.evaluatePasswordStrength('password');
    notifyListeners();
  }

  // Handle email changes with debouncing
  void onEmailChanged(String value) {
    _emailDebounceTimer?.cancel();
    _emailDebounceTimer = Timer(Duration(milliseconds: _debounceDuration), () {
      if (value.isEmpty) {
        emailError = 'Email is required';
      } else if (!ValidationService.isValidEmail(value)) {
        emailError = 'Please enter a valid email';
      } else {
        emailError = null;
      }
      notifyListeners();
    });
  }

  // Handle password changes with debouncing
  void onPasswordChanged(String value) {
    _passwordDebounceTimer?.cancel();
    _passwordDebounceTimer = Timer(Duration(milliseconds: _debounceDuration), () {
      if (value.isEmpty) {
        passwordError = 'Password is required';
      } else if (value.length < 8) {
        passwordError = 'Password must be at least 8 characters';
      } else {
        passwordError = null;
      }
      passwordStrength = ValidationService.evaluatePasswordStrength(value);
      notifyListeners();
    });
  }

  // Submit login
  Future<bool> submitLogin() async {
    if (!_validateForm()) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = "Login failed: $e";
      notifyListeners();
      return false;
    }
  }

  // Submit register
  Future<bool> submitRegister() async {
    if (!_validateRegistration()) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text,
          );
      String newUid = userCredential.user!.uid;

      // Generate a handle from the name (lowercase, no spaces)
      final name = nameController.text.trim();
      final handle = name.toLowerCase().replaceAll(' ', '.');

      await FirebaseFirestore.instance.collection('users').doc(newUid).set({
        'uid': newUid,
        'name': name,
        'email': emailController.text.trim().toLowerCase(),
        'handle': handle,
        'photoUrl': null,
        'balance': 0,
        'balance_usd': 0,
        'balance_cny': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = "Registration failed: $e";
      notifyListeners();
      return false;
    }
  }

  // Validate form (login)
  bool _validateForm() {
    if (emailController.text.trim().isEmpty) {
      _errorMessage = 'Please enter your email';
      notifyListeners();
      return false;
    }
    if (!emailController.text.contains('@')) {
      _errorMessage = 'Enter a valid email';
      notifyListeners();
      return false;
    }
    if (passwordController.text.isEmpty) {
      _errorMessage = 'Please enter your password';
      notifyListeners();
      return false;
    }
    if (passwordController.text.length < 6) {
      _errorMessage = 'Password must be at least 6 characters';
      notifyListeners();
      return false;
    }
    return true;
  }

  // Validate registration
  bool _validateRegistration() {
    if (nameController.text.trim().isEmpty) {
      _errorMessage = 'Please enter your full name';
      notifyListeners();
      return false;
    }
    if (phoneController.text.trim().isEmpty) {
      _errorMessage = 'Please enter your phone number';
      notifyListeners();
      return false;
    }
    if (!_validateForm()) return false;
    if (confirmPasswordController.text != passwordController.text) {
      _errorMessage = 'Passwords do not match';
      notifyListeners();
      return false;
    }
    return true;
  }

  // Dispose controllers
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    _emailDebounceTimer?.cancel();
    _passwordDebounceTimer?.cancel();
    super.dispose();
  }
}