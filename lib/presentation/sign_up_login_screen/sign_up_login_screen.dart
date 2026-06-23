import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './widgets/auth_form_widget.dart';
import './widgets/auth_logo_widget.dart';
import './widgets/auth_particle_background_widget.dart';
import './auth_view_model.dart';

class SignUpLoginScreen extends StatelessWidget {
  const SignUpLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: const _SignUpLoginScreenContent(),
    );
  }
}

class _SignUpLoginScreenContent extends StatelessWidget {
  const _SignUpLoginScreenContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: Stack(
        children: [
          // Particle background
          const Positioned.fill(child: AuthParticleBackgroundWidget()),
          // Content
          SafeArea(
            child: Center(
              child: MediaQuery.of(context).size.width >= 600
                  ? _buildTabletLayout()
                  : _buildPhoneLayout(),
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
          AuthLogoWidget(),
          const SizedBox(height: 40),
          AuthFormWidget(),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          AuthLogoWidget(),
          const SizedBox(height: 40),
          SizedBox(width: 480, child: AuthFormWidget()),
        ],
      ),
    );
  }
}
