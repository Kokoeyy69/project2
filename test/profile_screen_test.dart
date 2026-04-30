import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neopay_ai/presentation/profile_screen/profile_screen.dart';
import 'package:neopay_ai/viewmodels/profile_viewmodel_base.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';

class FakeProfileViewModel extends ProfileViewModelBase {
  bool _isLoadingProfile = false;
  bool _isUploadingPhoto = false;
  double _uploadProgress = 0.0;
  String? _name;
  String? _email;
  String? _photoUrl;
  bool _biometricEnabled = false;
  bool _twoFactorEnabled = false;
  bool _transactionAlerts = true;
  bool _autoConvert = false;
  bool _showAllCurrencies = false;
  String _defaultCurrency = 'IDR';
  Map<String, dynamic> _settings = {};

  FakeProfileViewModel({
    String? name,
    String? email,
    String? photoUrl,
    bool isUploadingPhoto = false,
    double uploadProgress = 0.0,
  }) {
    _name = name;
    _email = email;
    _photoUrl = photoUrl;
    _isUploadingPhoto = isUploadingPhoto;
    _uploadProgress = uploadProgress;
  }

  @override
  bool get isLoadingProfile => _isLoadingProfile;

  @override
  bool get isUploadingPhoto => _isUploadingPhoto;

  @override
  double get uploadProgress => _uploadProgress;

  @override
  // Not used in these tests
  get user => null;

  @override
  String? get name => _name;

  @override
  String? get email => _email;

  @override
  String? get photoUrl => _photoUrl;

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

  @override
  Future<void> initProfile() async {}

  @override
  Future<XFile?> pickImage(ImageSource source) async => null;

  @override
  Future<CroppedFile?> cropImage(String path) async => null;

  @override
  Future<File?> compressImage(String path) async => null;

  @override
  Future<bool> uploadProfilePhoto(File file) async {
    _isUploadingPhoto = false;
    _uploadProgress = 0.0;
    notifyListeners();
    return true;
  }

  @override
  Future<void> cancelUpload() async {
    _isUploadingPhoto = false;
    _uploadProgress = 0.0;
    notifyListeners();
  }

  @override
  Future<bool> setBiometricEnabled(bool enabled) async {
    _biometricEnabled = enabled;
    notifyListeners();
    return true;
  }

  @override
  Future<bool> updateSetting(String key, dynamic value) async {
    _settings[key] = value;
    notifyListeners();
    return true;
  }

  @override
  Future<bool> updateProfile({
    required String newName,
    required String newEmail,
    String? currentPassword,
  }) async {
    _name = newName;
    _email = newEmail;
    notifyListeners();
    return true;
  }

  @override
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async => true;

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('ProfileScreen shows name and email from viewmodel', (
    tester,
  ) async {
    // Ensure a large enough test viewport to avoid avatar overlay overflow
    final binding =
        TestWidgetsFlutterBinding.ensureInitialized()
            as TestWidgetsFlutterBinding;
    binding.window.physicalSizeTestValue = const Size(1080, 1920);
    binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(() {
      binding.window.clearPhysicalSizeTestValue();
      binding.window.clearDevicePixelRatioTestValue();
    });

    final vm = FakeProfileViewModel(
      name: 'Test User',
      email: 'test@example.com',
    );

    await tester.pumpWidget(MaterialApp(home: ProfileScreen(viewModel: vm)));

    await tester.pump();

    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
  });

  testWidgets('ProfileScreen shows upload progress overlay when uploading', (
    tester,
  ) async {
    final vm = FakeProfileViewModel(
      isUploadingPhoto: true,
      uploadProgress: 0.42,
      photoUrl: '',
    );

    final binding =
        TestWidgetsFlutterBinding.ensureInitialized()
            as TestWidgetsFlutterBinding;
    binding.window.physicalSizeTestValue = const Size(1080, 1920);
    binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(() {
      binding.window.clearPhysicalSizeTestValue();
      binding.window.clearDevicePixelRatioTestValue();
    });

    await tester.pumpWidget(MaterialApp(home: ProfileScreen(viewModel: vm)));

    // Initial frame
    await tester.pump();

    // Expect a circular progress and percent text
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(find.text('42%'), findsOneWidget);

    // Cancel button present in overlay
    final cancelFinder = find.widgetWithText(TextButton, 'Cancel');
    expect(cancelFinder, findsOneWidget);

    // Tap cancel and allow VM to update
    await tester.tap(cancelFinder, warnIfMissed: false);
    await tester.pump();

    // After cancel, overlay should disappear (no percent text)
    expect(find.text('42%'), findsNothing);
  });
}
