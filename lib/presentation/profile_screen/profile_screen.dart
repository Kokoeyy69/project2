import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:neopay_ai/services/analytics_service.dart';
import 'package:neopay_ai/utils/permission_helper.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';
import '../../routes/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../viewmodels/profile_view_model.dart';
import '../../viewmodels/profile_viewmodel_base.dart';

class ProfileScreen extends StatefulWidget {
  final ProfileViewModelBase? viewModel;
  const ProfileScreen({super.key, this.viewModel});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentNavIndex = 3;
  late final ProfileViewModelBase _vm;
  late final bool _vmOwner;

  final List<String> _currencies = ['IDR', 'USD', 'CNY'];

  void _onNavTap(int index) {
    setState(() => _currentNavIndex = index);
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.homeScreen,
        (_) => false,
      );
    } else if (index == 1) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.transferKeypadScreen,
        (_) => false,
      );
    } else if (index == 2) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.activityScreen,
        (_) => false,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _vm = widget.viewModel!;
      _vmOwner = false;
    } else {
      _vm = ProfileViewModel();
      _vmOwner = true;
    }
    _vm.addListener(_onVmChange);
    if (_vmOwner) _vm.initProfile();
  }

  void _onVmChange() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                child: Column(
                  children: [
                    _buildUserAvatar(),
                    const SizedBox(height: 24),
                    _buildSecuritySection(),
                    const SizedBox(height: 16),
                    _buildCurrencyPreferencesSection(),
                    const SizedBox(height: 16),
                    _buildAccountSection(),
                    const SizedBox(height: 16),
                    _buildLogoutButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppNavigation(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          Text(
            'Profile',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: InkWell(
                onTap: _editProfile,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.glassBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.glassBorder, width: 0.5),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: AppTheme.textSecondary,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primary.withAlpha(30),
                AppTheme.accent.withAlpha(20),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppTheme.primary.withAlpha(60),
              width: 0.5,
            ),
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withAlpha(100),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Builder(
                        builder: (context) {
                          if (_vm.isLoadingProfile) {
                            return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          }
                          if (_vm.isUploadingPhoto) {
                            // Show upload progress overlay with cancel
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                if (_vm.photoUrl != null &&
                                    _vm.photoUrl!.isNotEmpty)
                                  CachedNetworkImage(
                                    imageUrl: _vm.photoUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (c, s) => const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    errorWidget: (c, s, e) => const Icon(
                                      Icons.person_rounded,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  )
                                else
                                  CachedNetworkImage(
                                    imageUrl:
                                        'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=160&h=160&fit=crop',
                                    fit: BoxFit.cover,
                                    placeholder: (c, s) => const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    errorWidget: (c, s, e) => const Icon(
                                      Icons.person_rounded,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                Container(
                                  color: Colors.black.withAlpha(
                                    (0.45 * 255).round(),
                                  ),
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 48,
                                            height: 48,
                                            child: CircularProgressIndicator(
                                              value: _vm.uploadProgress > 0
                                                  ? _vm.uploadProgress
                                                  : null,
                                              strokeWidth: 3,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${(_vm.uploadProgress * 100).toStringAsFixed(0)}%',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextButton(
                                            onPressed: () async {
                                              try {
                                                await _vm.cancelUpload();
                                              } catch (_) {}
                                              _showSnack('Upload cancelled');
                                            },
                                            child: const Text(
                                              'Cancel',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                          if (_vm.photoUrl != null &&
                              _vm.photoUrl!.isNotEmpty) {
                            return CachedNetworkImage(
                              imageUrl: _vm.photoUrl!,
                              fit: BoxFit.cover,
                              imageBuilder: (c, imageProvider) => Image(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              ),
                              placeholder: (c, s) => const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              errorWidget: (c, s, e) => const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            );
                          }
                          return CachedNetworkImage(
                            imageUrl:
                                'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=160&h=160&fit=crop',
                            fit: BoxFit.cover,
                            placeholder: (c, s) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (c, s, e) => const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Online status / verification badge
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.background, width: 2),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),

                  // Edit avatar button
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _pickAndUploadImage,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.glassBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.glassBorder,
                              width: 0.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _vm.name ?? 'Your name',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _vm.email ?? '',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBadge('Premium', AppTheme.primary, Icons.star_rounded),
                  const SizedBox(width: 8),
                  _buildBadge(
                    'Verified',
                    AppTheme.success,
                    Icons.verified_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return _buildSection(
      title: 'Security',
      icon: Icons.shield_rounded,
      iconColor: AppTheme.primary,
      children: [
        _buildToggleTile(
          icon: Icons.fingerprint_rounded,
          iconColor: AppTheme.primary,
          title: 'Biometric Login',
          subtitle: 'Use fingerprint or Face ID',
          value: _vm.biometricEnabled,
          onChanged: (val) async {
            final ok = await _vm.setBiometricEnabled(val);
            if (!ok) _showSnack('Failed to update biometric setting', true);
          },
        ),
        _buildDivider(),
        _buildToggleTile(
          icon: Icons.lock_rounded,
          iconColor: AppTheme.accent,
          title: 'Two-Factor Auth',
          subtitle: 'Extra layer of security',
          value: _vm.twoFactorEnabled,
          onChanged: (val) async {
            final ok = await _vm.updateSetting('twoFactorEnabled', val);
            if (!ok) _showSnack('Failed to update setting', true);
          },
        ),
        _buildDivider(),
        _buildToggleTile(
          icon: Icons.notifications_active_rounded,
          iconColor: AppTheme.warning,
          title: 'Transaction Alerts',
          subtitle: 'Get notified on every transaction',
          value: _vm.transactionAlerts,
          onChanged: (val) async {
            final ok = await _vm.updateSetting('transactionAlerts', val);
            if (!ok) _showSnack('Failed to update setting', true);
          },
        ),
        _buildDivider(),
        _buildNavTile(
          icon: Icons.key_rounded,
          iconColor: const Color(0xFF8B5CF6),
          title: 'Change Password',
          subtitle: 'Last changed 30 days ago',
          onTap: _changePassword,
        ),
      ],
    );
  }

  Widget _buildCurrencyPreferencesSection() {
    return _buildSection(
      title: 'Currency Preferences',
      icon: Icons.currency_exchange_rounded,
      iconColor: AppTheme.success,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Default Currency',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: _currencies.map((c) {
                  final isSelected = _vm.defaultCurrency == c;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final ok = await _vm.updateSetting(
                          'defaultCurrency',
                          c,
                        );
                        if (!ok) _showSnack('Failed to update currency', true);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.only(
                          right: c != _currencies.last ? 8 : 0,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.surface.withAlpha(120),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.glassBorder,
                            width: isSelected ? 1.5 : 0.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          c,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        _buildDivider(),
        _buildToggleTile(
          icon: Icons.autorenew_rounded,
          iconColor: AppTheme.success,
          title: 'Auto Convert',
          subtitle: 'Automatically convert at best rate',
          value: _vm.autoConvert,
          onChanged: (val) async {
            final ok = await _vm.updateSetting('autoConvert', val);
            if (!ok) _showSnack('Failed to update setting', true);
          },
        ),
        _buildDivider(),
        _buildToggleTile(
          icon: Icons.visibility_rounded,
          iconColor: AppTheme.accent,
          title: 'Show All Currencies',
          subtitle: 'Display IDR, USD & CNY balances',
          value: _vm.showAllCurrencies,
          onChanged: (val) async {
            final ok = await _vm.updateSetting('showAllCurrencies', val);
            if (!ok) _showSnack('Failed to update setting', true);
          },
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return _buildSection(
      title: 'Account',
      icon: Icons.manage_accounts_rounded,
      iconColor: AppTheme.textSecondary,
      children: [
        _buildNavTile(
          icon: Icons.help_outline_rounded,
          iconColor: AppTheme.accent,
          title: 'Help & Support',
          subtitle: 'FAQs and contact support',
          onTap: () async {
            final uri = Uri.parse('https://your-support.example.com');
            if (await canLaunchUrl(uri)) await launchUrl(uri);
          },
        ),
        _buildDivider(),
        _buildNavTile(
          icon: Icons.assistant_rounded,
          iconColor: AppTheme.primary,
          title: 'AI Settings',
          subtitle: 'Configure AI API key and provider',
          onTap: () => Navigator.pushNamed(context, AppRoutes.aiSettingsScreen),
        ),
        _buildDivider(),
        _buildNavTile(
          icon: Icons.privacy_tip_outlined,
          iconColor: AppTheme.warning,
          title: 'Privacy Policy',
          subtitle: 'How we handle your data',
          onTap: () async {
            final uri = Uri.parse('https://your-privacy.example.com');
            if (await canLaunchUrl(uri)) await launchUrl(uri);
          },
        ),
        _buildDivider(),
        _buildNavTile(
          icon: Icons.info_outline_rounded,
          iconColor: AppTheme.textMuted,
          title: 'App Version',
          subtitle: 'NeoPay AI v1.0.0',
          showChevron: false,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.glassBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.glassBorder, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: iconColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: iconColor, size: 14),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primary,
            activeTrackColor: AppTheme.primaryMuted,
            inactiveThumbColor: AppTheme.textMuted,
            inactiveTrackColor: AppTheme.surfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool showChevron = true,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (showChevron)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textMuted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AppTheme.separator,
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () async {
        await _vm.signOut();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.signUpLoginScreen,
          (_) => false,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.error.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.error.withAlpha(60),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.logout_rounded,
                  color: AppTheme.error,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sign Out',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _vm.removeListener(_onVmChange);
    if (_vmOwner) _vm.dispose();
    super.dispose();
  }

  // Permission flow is handled by utils/permission_helper.dart

  Future<void> _pickAndUploadImage() async {
    if (_vm.user == null) {
      _showSnack('Not signed in', true);
      return;
    }

    XFile? picked;
    CroppedFile? cropped;
    File? compressedFile;

    try {
      final ok = await ensurePermissionsForImage(context);
      if (!ok) return;

      picked = await _vm.pickImage(ImageSource.gallery);
      if (picked == null) return;

      String imagePath = picked.path;

      // Crop via viewmodel helper
      try {
        cropped = await _vm.cropImage(picked.path);
        if (cropped != null && cropped.path.isNotEmpty)
          imagePath = cropped.path;
      } catch (_) {
        imagePath = picked.path;
      }

      // Compress via viewmodel helper
      try {
        compressedFile = await _vm.compressImage(imagePath);
      } catch (_) {
        compressedFile = null;
      }

      final fileToUpload = compressedFile ?? File(imagePath);

      AnalyticsService.instance.logEvent('profile_upload_start');

      final okUpload = await _vm.uploadProfilePhoto(fileToUpload);
      if (okUpload) {
        AnalyticsService.instance.logEvent(
          'profile_upload_success',
          params: {'uid': _vm.user?.uid},
        );
        _showSnack('Profile photo updated');
      } else {
        AnalyticsService.instance.logEvent('profile_upload_failed');
        _showSnack('Failed to upload photo', true);
      }
    } catch (e) {
      AnalyticsService.instance.logEvent(
        'profile_upload_failed',
        params: {'error': e.toString()},
      );
      _showSnack('Failed to upload photo: $e', true);
    } finally {
      // cleanup
      try {
        if (compressedFile != null && await compressedFile.exists())
          await compressedFile.delete();
      } catch (_) {}
      try {
        if (cropped != null && picked != null && cropped.path != picked.path) {
          final f = File(cropped.path);
          if (await f.exists()) await f.delete();
        }
      } catch (_) {}
    }
  }

  Future<void> _editProfile() async {
    if (_vm.user == null) {
      _showSnack('Not signed in', true);
      return;
    }

    final nameCtl = TextEditingController(text: _vm.name ?? '');
    final emailCtl = TextEditingController(text: _vm.email ?? '');
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit profile',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtl,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter a name'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: emailCtl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.pop(context);
                          await _saveProfile(
                            nameCtl.text.trim(),
                            emailCtl.text.trim(),
                          );
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveProfile(String newName, String newEmail) async {
    if (_vm.user == null) {
      _showSnack('Not signed in', true);
      return;
    }

    String? currentPassword;
    try {
      if (newEmail != _vm.email && _vm.email != null) {
        final providers = _vm.user!.providerData
            .map((p) => p.providerId)
            .toList();
        if (providers.contains('password')) {
          currentPassword = await _askForPassword();
          if (currentPassword == null) {
            _showSnack('Cancelled', true);
            return;
          }
        }
      }

      final ok = await _vm.updateProfile(
        newName: newName,
        newEmail: newEmail,
        currentPassword: currentPassword,
      );

      if (ok) {
        _showSnack('Profile updated');
      } else {
        _showSnack('Failed to update profile', true);
      }
    } catch (e) {
      _showSnack('Failed to update profile: $e', true);
    }
  }

  Future<String?> _askForPassword() async {
    final TextEditingController ctl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm password'),
          content: TextField(
            controller: ctl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Current password'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, ctl.text),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
    return result;
  }

  Future<void> _changePassword() async {
    if (_vm.user == null || _vm.email == null) {
      _showSnack('Not signed in', true);
      return;
    }

    final currentCtl = TextEditingController();
    final newCtl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentCtl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current password',
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Enter current password'
                      : null,
                ),
                TextFormField(
                  controller: newCtl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password'),
                  validator: (v) => (v == null || v.length < 8)
                      ? 'Minimum 8 characters'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(context);
                try {
                  final ok = await _vm.changePassword(
                    currentPassword: currentCtl.text,
                    newPassword: newCtl.text,
                  );
                  if (ok) {
                    _showSnack('Password updated');
                  } else {
                    _showSnack('Failed to change password', true);
                  }
                } catch (e) {
                  _showSnack('Failed to change password: $e', true);
                }
              },
              child: const Text('Change'),
            ),
          ],
        );
      },
    );
  }

  void _showSnack(String message, [bool error = false]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.redAccent : AppTheme.primary,
      ),
    );
  }
}
