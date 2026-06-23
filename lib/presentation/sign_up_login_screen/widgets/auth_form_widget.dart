import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../auth_view_model.dart';

class AuthFormWidget extends StatefulWidget {
  const AuthFormWidget({super.key});

  @override
  State<AuthFormWidget> createState() => _AuthFormWidgetState();
}

class _AuthFormWidgetState extends State<AuthFormWidget>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  late AnimationController _formAnimController;
  late Animation<double> _formAnimation;

  @override
  void initState() {
    super.initState();
    _formAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _formAnimation = CurvedAnimation(
      parent: _formAnimController,
      curve: Curves.easeOutCubic,
    );
    _formAnimController.forward();

    // Set up focus listeners
    _emailFocusNode.addListener(_handleFocusChange);
    _passwordFocusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (_emailFocusNode.hasFocus || _passwordFocusNode.hasFocus) {
      Provider.of<AuthViewModel>(context, listen: false).setFocused(true);
    } else {
      Provider.of<AuthViewModel>(context, listen: false).setFocused(false);
    }
  }

  @override
  void didUpdateWidget(AuthFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // In Provider mode, we'll watch the viewModel's isLogin state
  }

  @override
  void dispose() {
    _formAnimController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthViewModel viewModel) async {
    bool success = false;
    if (viewModel.isLogin) {
      success = await viewModel.submitLogin();
    } else {
      success = await viewModel.submitRegister();
    }

    if (success && mounted) {
      // onSuccess callback removed - routing handled by global listener
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AuthViewModel>(context);

    // Trigger animation on mode toggle
    if (viewModel.errorMessage == null && !_formAnimController.isAnimating) {
      // This is a bit hacky for a widget that depends on external state
      // but for now we'll keep the animation logic local
    }

    return FadeTransition(
      opacity: _formAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(_formAnimation),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface.withAlpha(140),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.glassBorder, width: 0.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTabSwitcher(viewModel),
                      const SizedBox(height: 24),
                      if (!viewModel.isLogin) ...[
                        _buildGlassField(
                          controller: viewModel.nameController,
                          label: 'Full Name',
                          hint: 'Rania Kusuma',
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 14),
                        _buildGlassField(
                          controller: viewModel.phoneController,
                          label: 'Phone Number',
                          hint: '+62 812 3456 7890',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 14),
                      ],
                      _buildGlassField(
                        controller: viewModel.emailController,
                        label: 'Email Address',
                        hint: 'you@neopay-api-eight.vercel.app',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        focusNode: _emailFocusNode,
                        onChanged: (value) => viewModel.onEmailChanged(value),
                      ),
                      const SizedBox(height: 14),
                      _buildPasswordField(
                        controller: viewModel.passwordController,
                        label: 'Password',
                        visible: viewModel.passwordVisible,
                        onToggle: viewModel.togglePasswordVisibility,
                        focusNode: _passwordFocusNode,
                        onChanged: (value) => viewModel.onPasswordChanged(value),
                      ),
                      if (!viewModel.isLogin) ...[
                        const SizedBox(height: 14),
                        _buildPasswordField(
                          controller: viewModel.confirmPasswordController,
                          label: 'Confirm Password',
                          visible: viewModel.confirmPasswordVisible,
                          onToggle: viewModel.toggleConfirmPasswordVisibility,
                        ),
                        if (viewModel.emailError != null) ...[
                          const SizedBox(height: 8),
                          _buildErrorBanner(viewModel.emailError!),
                        ],
                        if (viewModel.passwordError != null) ...[
                          const SizedBox(height: 8),
                          _buildErrorBanner(viewModel.passwordError!),
                        ],
                      ],
                      if (viewModel.isLogin) ...[
                        const SizedBox(height: 14),
                        _buildLoginOptions(viewModel),
                        if (viewModel.emailError != null) ...[
                          const SizedBox(height: 8),
                          _buildErrorBanner(viewModel.emailError!),
                        ],
                        if (viewModel.passwordError != null) ...[
                          const SizedBox(height: 8),
                          _buildErrorBanner(viewModel.passwordError!),
                        ],
                      ],
                      if (viewModel.errorMessage != null) ...[
                        const SizedBox(height: 14),
                        _buildErrorBanner(viewModel.errorMessage!),
                      ],
                      const SizedBox(height: 20),
                      _buildSubmitButton(viewModel),
                      if (viewModel.isLogin) ...[
                        const SizedBox(height: 16),
                        _buildBiometricButton(viewModel),
                      ],
                      const SizedBox(height: 20),
                      _buildDivider(),
                      const SizedBox(height: 20),
                      _buildDemoCredentials(viewModel),
                      if (!viewModel.isLogin) ...[
                        const SizedBox(height: 20),
                        _buildTermsText(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabSwitcher(AuthViewModel viewModel) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.glassBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.glassBorder, width: 0.5),
      ),
      child: Row(
        children: [
          _buildTab('Sign In', viewModel.isLogin, viewModel),
          _buildTab('Create Account', !viewModel.isLogin, viewModel),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isActive, AuthViewModel viewModel) {
    return Expanded(
      child: GestureDetector(
        onTap: isActive
            ? null
            : () {
                viewModel.toggleMode();
                _formAnimController.forward(from: 0.0);
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppTheme.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    FocusNode? focusNode,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        _GlassTextField(
          controller: controller,
          hint: hint,
          icon: icon,
          keyboardType: keyboardType,
          focusNode: focusNode,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool visible,
    required VoidCallback onToggle,
    FocusNode? focusNode,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        _GlassTextField(
          controller: controller,
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          obscureText: !visible,
          suffixIcon: IconButton(
            onPressed: onToggle,
            icon: Icon(
              visible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: AppTheme.textMuted,
            ),
          ),
          focusNode: focusNode,
          onChanged: onChanged,
        ),
        if (focusNode == _passwordFocusNode && onChanged != null) ...[
          const SizedBox(height: 8),
          _buildPasswordStrengthBar(),
        ],
      ],
    );
  }

  Widget _buildPasswordStrengthBar() {
    final viewModel = Provider.of<AuthViewModel>(context);
    final strength = viewModel.passwordStrength;

    // Determine colors based on strength
    Color getColor(int index) {
      if (strength > index) {
        if (strength <= 2) return AppTheme.error;
        if (strength <= 3) return AppTheme.warning;
        return AppTheme.success;
      }
      return AppTheme.glassBorder;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password Strength',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(4, (index) {
            return Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: getColor(index),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          strength == 0 ? 'Enter password' :
          strength <= 2 ? 'Weak' :
          strength <= 3 ? 'Medium' : 'Strong',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginOptions(AuthViewModel viewModel) {
    return Row(
      children: [
        GestureDetector(
          onTap: viewModel.toggleRememberMe,
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: viewModel.rememberMe
                      ? AppTheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: viewModel.rememberMe
                        ? AppTheme.primary
                        : AppTheme.textMuted,
                    width: 1.5,
                  ),
                ),
                child: viewModel.rememberMe
                    ? const Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 7),
              Text(
                'Remember me',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Forgot password?',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withAlpha(77), width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.error,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppTheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(AuthViewModel viewModel) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: viewModel.isLoading ? null : () => _submit(viewModel),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          disabledBackgroundColor: AppTheme.primary.withAlpha(128),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: viewModel.isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(
                  key: const ValueKey('label'),
                  viewModel.isLogin ? 'Sign In to NeoPay AI' : 'Create Account',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBiometricButton(AuthViewModel viewModel) {
    return GestureDetector(
      onTap: viewModel.toggleBiometric,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.glassBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: viewModel.biometricEnabled
                ? AppTheme.primary.withAlpha(102)
                : AppTheme.glassBorder,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fingerprint_rounded,
              size: 22,
              color: viewModel.biometricEnabled
                  ? AppTheme.primary
                  : AppTheme.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              'Sign in with Biometrics',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: viewModel.biometricEnabled
                    ? AppTheme.primary
                    : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 0.5, color: AppTheme.separator)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Demo Account',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMuted,
            ),
          ),
        ),
        Expanded(child: Container(height: 0.5, color: AppTheme.separator)),
      ],
    );
  }

  Widget _buildDemoCredentials(AuthViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryMuted.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withAlpha(51), width: 0.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accent],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Demo Access',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          _buildCredentialRow(Icons.email_outlined, 'Email', 'test@test.com'),
          Divider(
            color: AppTheme.separator,
            height: 0,
            thickness: 0.5,
            indent: 16,
          ),
          _buildCredentialRow(
            Icons.lock_outline_rounded,
            'Password',
            'password',
            isPassword: true,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton(
                onPressed: viewModel.setDemoCredentials,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary.withAlpha(38),
                  foregroundColor: AppTheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Tap to autofill credentials',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(
    IconData icon,
    String label,
    String value, {
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              isPassword ? '••••••••••' : value,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsText() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: AppTheme.textMuted,
        ),
        children: [
          const TextSpan(text: 'By creating an account, you agree to our '),
          TextSpan(
            text: 'Terms of Service',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.primary,
            ),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  const _GlassTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.focusNode,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AuthViewModel>(context);
    return Focus(
      onFocusChange: viewModel.setFocused,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: AppTheme.glassBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: viewModel.isFocused
                ? AppTheme.primary.withAlpha(179)
                : AppTheme.glassBorder,
            width: viewModel.isFocused ? 1.2 : 0.5,
          ),
          boxShadow: viewModel.isFocused
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withAlpha(31),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppTheme.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textMuted,
            ),
            prefixIcon: Icon(icon, size: 18, color: AppTheme.textMuted),
            suffixIcon: suffixIcon,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }
}