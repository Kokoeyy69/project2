import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Minimal abstract surface for profile view models. Implement this to provide
/// a test-friendly fake or the full production `ProfileViewModel`.
abstract class ProfileViewModelBase extends ChangeNotifier {
  // UI state
  bool get isLoadingProfile;
  bool get isUploadingPhoto;
  double get uploadProgress;

  // User info
  User? get user;
  String? get name;
  String? get email;
  String? get photoUrl;

  // Settings
  bool get biometricEnabled;
  bool get twoFactorEnabled;
  bool get transactionAlerts;
  bool get autoConvert;
  bool get showAllCurrencies;
  String get defaultCurrency;
  Map<String, dynamic> get settings;

  // Lifecycle
  Future<void> initProfile();

  // Image helpers
  Future<XFile?> pickImage(ImageSource source);
  Future<CroppedFile?> cropImage(String path);
  Future<File?> compressImage(String path);
  Future<bool> uploadProfilePhoto(File file);
  Future<void> cancelUpload();

  // Settings / profile updates
  Future<bool> setBiometricEnabled(bool enabled);
  Future<bool> updateSetting(String key, dynamic value);
  Future<bool> updateProfile({
    required String newName,
    required String newEmail,
    String? currentPassword,
  });
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<void> signOut();
}
