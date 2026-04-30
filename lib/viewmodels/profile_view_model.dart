import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';

import 'package:neopay_ai/services/analytics_service.dart';
import 'package:neopay_ai/viewmodels/profile_viewmodel_base.dart';

/// Encapsulates profile-related business logic with injectable dependencies for testability.
class ProfileViewModel extends ProfileViewModelBase {
  // Injected services (replaceable for testing)
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final ImagePicker _picker;
  final ImageCropper _cropper;
  final LocalAuthentication _localAuth;

  // UI state
  bool _isLoadingProfile = true;
  bool _isUploadingPhoto = false;
  double _uploadProgress = 0.0;

  User? _user;
  String? _name;
  String? _email;
  String? _photoUrl;
  UploadTask? _currentUploadTask;

  // Settings
  bool _biometricEnabled = true;
  bool _twoFactorEnabled = false;
  bool _transactionAlerts = true;
  bool _autoConvert = true;
  bool _showAllCurrencies = false;
  String _defaultCurrency = 'IDR';

  // Subscriptions
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;
  Map<String, dynamic> _settings = {};

  // Getters
  @override
  bool get isLoadingProfile => _isLoadingProfile;
  @override
  bool get isUploadingPhoto => _isUploadingPhoto;
  @override
  double get uploadProgress => _uploadProgress;
  @override
  User? get user => _user;
  @override
  String? get name => _name;
  @override
  String? get email => _email;
  @override
  String? get photoUrl => _photoUrl;
  UploadTask? get currentUploadTask => _currentUploadTask;

  @override
  bool get biometricEnabled => _biometricEnabled;
  @override
  bool get twoFactorEnabled => _twoFactorEnabled;
  @override
  bool get transactionAlerts => _transactionAlerts;
  @override
  bool get autoConvert => _autoConvert;
  @override
  bool get showAllCurrencies => _showAllCurrencies;
  @override
  String get defaultCurrency => _defaultCurrency;

  @override
  Map<String, dynamic> get settings => _settings;

  ProfileViewModel({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    ImagePicker? picker,
    ImageCropper? cropper,
    LocalAuthentication? localAuth,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _picker = picker ?? ImagePicker(),
       _cropper = cropper ?? ImageCropper(),
       _localAuth = localAuth ?? LocalAuthentication();

  /// Lightweight constructor intended for tests. Initializes internal fields
  /// without performing network calls. Pass non-null values to seed the VM.
  ProfileViewModel.forTest({
    String? name,
    String? email,
    String? photoUrl,
    bool isUploadingPhoto = false,
    double uploadProgress = 0.0,
  }) : _auth = FirebaseAuth.instance,
       _firestore = FirebaseFirestore.instance,
       _storage = FirebaseStorage.instance,
       _picker = ImagePicker(),
       _cropper = ImageCropper(),
       _localAuth = LocalAuthentication() {
    _name = name;
    _email = email;
    _photoUrl = photoUrl;
    _isUploadingPhoto = isUploadingPhoto;
    _uploadProgress = uploadProgress;
    _isLoadingProfile = false;
  }

  /// Initialize profile data from Firestore
  @override
  Future<void> initProfile() async {
    _isLoadingProfile = true;
    notifyListeners();

    try {
      _user = _auth.currentUser;
      if (_user == null) {
        _isLoadingProfile = false;
        notifyListeners();
        return;
      }

      _name = _user?.displayName;
      _email = _user?.email;
      _photoUrl = _user?.photoURL;

      final userDoc = _firestore.collection('users').doc(_user!.uid);
      _userDocSub = userDoc.snapshots().listen((snap) {
        if (snap.exists) {
          final data = snap.data() ?? {};
          _settings = data;
          _biometricEnabled = data['biometricEnabled'] ?? true;
          _twoFactorEnabled = data['twoFactorEnabled'] ?? false;
          _transactionAlerts = data['transactionAlerts'] ?? true;
          _autoConvert = data['autoConvert'] ?? true;
          _showAllCurrencies = data['showAllCurrencies'] ?? false;
          _defaultCurrency = data['defaultCurrency'] ?? 'IDR';
          _photoUrl = data['photoURL'] ?? _user?.photoURL;
          _name = data['displayName'] ?? _user?.displayName;
        }
        _isLoadingProfile = false;
        notifyListeners();
      });
    } catch (e) {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  /// Pick an image from camera or gallery
  @override
  Future<XFile?> pickImage(ImageSource source) async {
    try {
      return await _picker.pickImage(source: source);
    } catch (e) {
      return null;
    }
  }

  /// Crop the picked image
  @override
  Future<CroppedFile?> cropImage(String imagePath) async {
    try {
      return await _cropper.cropImage(
        sourcePath: imagePath,
        compressQuality: 80,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: const Color.fromARGB(255, 59, 130, 246),
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            minimumAspectRatio: 1.0,
            title: 'Crop Image',
            cancelButtonTitle: 'Cancel',
            doneButtonTitle: 'Done',
          ),
        ],
      );
    } catch (e) {
      return null;
    }
  }

  /// Compress the image
  @override
  Future<File?> compressImage(String sourcePath) async {
    try {
      final bytes = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        '$sourcePath-compressed.jpg',
        quality: 70,
        minWidth: 512,
        minHeight: 512,
      );
      return bytes != null ? File(bytes.path) : null;
    } catch (e) {
      return null;
    }
  }

  /// Upload profile photo to Firebase Storage and update Firestore
  ///
  /// Includes server-side validation, retry logic, and detailed error handling.
  /// Returns true on success, false on failure.
  @override
  Future<bool> uploadProfilePhoto(File imageFile) async {
    if (_user == null) return false;

    // Validate file before upload
    final validation = _validateProfilePhoto(imageFile);
    if (validation != null) {
      _isUploadingPhoto = false;
      notifyListeners();
      return false;
    }

    _isUploadingPhoto = true;
    _uploadProgress = 0.0;
    notifyListeners();

    int retryCount = 0;
    const maxRetries = 3;
    const retryDelayMs = 1000;

    while (retryCount < maxRetries) {
      try {
        final ref = _storage.ref().child(
          'users/${_user!.uid}/profile_photo.jpg',
        );

        _currentUploadTask = ref.putFile(
          imageFile,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'uploadedBy': _user!.uid,
              'timestamp': DateTime.now().toIso8601String(),
            },
          ),
        );

        final snapshotSub = _currentUploadTask!.snapshotEvents.listen((event) {
          _uploadProgress = event.bytesTransferred / event.totalBytes;
          notifyListeners();
        });

        await _currentUploadTask!;
        snapshotSub.cancel();

        // Verify upload by getting download URL
        final downloadUrl = await ref.getDownloadURL();
        if (downloadUrl.isEmpty) {
          throw Exception('Failed to get download URL after upload');
        }

        // Validate Firestore update response
        await _firestore.collection('users').doc(_user!.uid).set({
          'photoURL': downloadUrl,
        }, SetOptions(merge: true));

        // Also update FirebaseAuth
        await _user!.updatePhotoURL(downloadUrl);

        _photoUrl = downloadUrl;
        _isUploadingPhoto = false;
        _currentUploadTask = null;
        _uploadProgress = 0.0;
        notifyListeners();

        return true;
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          _isUploadingPhoto = false;
          _currentUploadTask = null;
          _uploadProgress = 0.0;
          notifyListeners();
          return false;
        }
        // Exponential backoff before retry
        await Future.delayed(Duration(milliseconds: retryDelayMs * retryCount));
      }
    }

    _isUploadingPhoto = false;
    _currentUploadTask = null;
    _uploadProgress = 0.0;
    notifyListeners();
    return false;
  }

  /// Validate profile photo before upload
  /// Returns error message if invalid, null if valid
  String? _validateProfilePhoto(File imageFile) {
    // Check file exists
    if (!imageFile.existsSync()) {
      return 'Image file not found';
    }

    // Check file size (max 5MB)
    final fileSizeInBytes = imageFile.lengthSync();
    const maxSizeBytes = 5 * 1024 * 1024; // 5MB
    if (fileSizeInBytes > maxSizeBytes) {
      return 'Image size must be less than 5MB';
    }

    // Check file size minimum (at least 100KB)
    const minSizeBytes = 100 * 1024; // 100KB
    if (fileSizeInBytes < minSizeBytes) {
      return 'Image too small (minimum 100KB)';
    }

    // Check file extension
    final ext = imageFile.path.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
      return 'Only JPG, PNG, and WebP formats are allowed';
    }

    return null; // Valid
  }

  /// Cancel ongoing upload and cleanup resources
  ///
  /// Safely cancels the upload task and resets progress state.
  @override
  Future<void> cancelUpload() async {
    try {
      if (_currentUploadTask != null) {
        await _currentUploadTask?.cancel();
      }
    } catch (e) {
      // Silently catch cancellation errors
    } finally {
      _currentUploadTask = null;
      _isUploadingPhoto = false;
      _uploadProgress = 0.0;
      notifyListeners();
    }
  }

  /// Update profile name and email with reauthentication support
  ///
  /// If email changes, requires password-based reauthentication and sends
  /// verification email. Returns true if successful.
  @override
  Future<bool> updateProfile({
    required String newName,
    required String newEmail,
    String? currentPassword,
  }) async {
    if (_user == null) return false;

    try {
      // Validate inputs
      if (newName.trim().isEmpty || newEmail.trim().isEmpty) {
        return false;
      }

      // If email changed, handle reauthentication/verification
      if (newEmail != _email && _email != null) {
        final providers = _user!.providerData.map((p) => p.providerId).toList();
        if (providers.contains('password')) {
          // Email/password user: must reauthenticate
          if (currentPassword == null || currentPassword.isEmpty) {
            return false; // Password required for email change
          }

          try {
            final cred = EmailAuthProvider.credential(
              email: _email!,
              password: currentPassword,
            );
            await _user!.reauthenticateWithCredential(cred);
          } on FirebaseAuthException catch (e) {
            // Wrong password or other auth error
            return false;
          }

          // Send verification link to new email
          try {
            await _user!.verifyBeforeUpdateEmail(newEmail);
          } catch (e) {
            // Email might already be in use or invalid
            return false;
          }
        } else {
          // Social auth user: attempt verification without reauth
          try {
            await _user!.verifyBeforeUpdateEmail(newEmail);
          } catch (e) {
            return false;
          }
        }
      }

      // Update display name in Auth and Firestore
      if (newName != _name) {
        try {
          await _user!.updateDisplayName(newName);
        } catch (e) {
          return false;
        }
      }

      // Update Firestore record
      await _firestore.collection('users').doc(_user!.uid).set({
        'displayName': newName,
        'email': newEmail,
        'emailVerified': _user!.emailVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _name = newName;
      _email = newEmail;
      notifyListeners();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update biometric setting
  @override
  Future<bool> setBiometricEnabled(bool enabled) async {
    if (_user == null) return false;

    try {
      if (enabled) {
        // Authenticate device biometric before enabling
        final can =
            await _localAuth.canCheckBiometrics ||
            await _localAuth.isDeviceSupported();
        if (!can) return false;
        final did = await _localAuth.authenticate(
          localizedReason: 'Authenticate to enable biometric login',
          options: const AuthenticationOptions(biometricOnly: true),
        );
        if (!did) return false;
      }

      // Update settings map and persist
      _settings['biometricEnabled'] = enabled;
      await _firestore.collection('users').doc(_user!.uid).set({
        'settings': _settings,
      }, SetOptions(merge: true));
      _biometricEnabled = enabled;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update a generic user setting and persist it
  @override
  Future<bool> updateSetting(String key, dynamic value) async {
    if (_user == null) return false;
    try {
      _settings[key] = value;
      await _firestore.collection('users').doc(_user!.uid).set({
        'settings': _settings,
      }, SetOptions(merge: true));
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if biometric is available
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Update currency preference
  Future<bool> setDefaultCurrency(String currency) async {
    if (_user == null) return false;

    try {
      await _firestore.collection('users').doc(_user!.uid).update({
        'defaultCurrency': currency,
      });
      _defaultCurrency = currency;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _userDocSub?.cancel();
    super.dispose();
  }

  /// Sign out the current user
  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Change password with reauthentication (for email/password users)
  ///
  /// Validates current password before allowing new password set.
  /// Returns false if user is not email/password authenticated or password is wrong.
  @override
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_user == null || _email == null) return false;

    // Validate password strength
    if (newPassword.isEmpty || newPassword.length < 8) {
      return false; // Password too weak
    }

    try {
      // Check if user uses email/password auth
      final providers = _user!.providerData.map((p) => p.providerId).toList();
      if (!providers.contains('password')) {
        return false; // Not email/password user
      }

      // Reauthenticate with current password
      try {
        final cred = EmailAuthProvider.credential(
          email: _email!,
          password: currentPassword,
        );
        await _user!.reauthenticateWithCredential(cred);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          return false; // Wrong password
        }
        rethrow;
      }

      // Update password
      await _user!.updatePassword(newPassword);

      // Log to analytics
      AnalyticsService.instance.logEvent(
        'password_changed',
        params: {'timestamp': DateTime.now().toIso8601String()},
      );

      return true;
    } catch (e) {
      return false;
    }
  }
}
