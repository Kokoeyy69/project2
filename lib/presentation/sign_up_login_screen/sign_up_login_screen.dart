
import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import './widgets/auth_form_widget.dart';
import './widgets/auth_logo_widget.dart';
import './widgets/auth_particle_background_widget.dart';

class SignUpLoginScreen extends StatefulWidget {
  const SignUpLoginScreen({super.key});

  @override
  State<SignUpLoginScreen> createState() => _SignUpLoginScreenState();
}

class _SignUpLoginScreenState extends State<SignUpLoginScreen>
    with TickerProviderStateMixin {
  // TODO: Replace with Riverpod/Bloc for production
  bool _isLogin = true;
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    );
    _logoController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() => _isLogin = !_isLogin);
  }

  void _onSuccess() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.homeScreen,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: Stack(
        children: [
          // Particle background
          const Positioned.fill(child: AuthParticleBackgroundWidget()),
          // Content
          SafeArea(
            child: Center(
              child: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneLayout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          AuthLogoWidget(animation: _logoAnimation),
          const SizedBox(height: 40),
          AuthFormWidget(
            isLogin: _isLogin,
            onToggleMode: _toggleMode,
            onSuccess: _onSuccess,
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          AuthLogoWidget(animation: _logoAnimation),
          const SizedBox(height: 40),
          SizedBox(
            width: 480,
            child: AuthFormWidget(
              isLogin: _isLogin,
              onToggleMode: _toggleMode,
              onSuccess: _onSuccess,
            ),
          ),
        ],
      ),
    );
  }
}
