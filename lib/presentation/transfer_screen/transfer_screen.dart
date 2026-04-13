import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';
import './transfer_view_model.dart';
import './widgets/ai_suggestion_strip_widget.dart';
import './widgets/amount_input_widget.dart';
import './widgets/confirm_transfer_button_widget.dart';
import './widgets/numeric_keypad_widget.dart';
import './widgets/recipient_selector_widget.dart';
import './widgets/source_wallet_selector_widget.dart';
import './widgets/transfer_fee_breakdown_widget.dart';

class TransferScreen extends StatelessWidget {
  const TransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TransferViewModel(),
      child: const _TransferScreenContent(),
    );
  }
}

class _TransferScreenContent extends StatefulWidget {
  const _TransferScreenContent();

  @override
  State<_TransferScreenContent> createState() => _TransferScreenContentState();
}

class _TransferScreenContentState extends State<_TransferScreenContent> {
  int _currentNavIndex = 1;
  int _selectedWalletIndex = 0;
  String _selectedRecipientId = '';

  void _onNavTap(int index) {
    setState(() => _currentNavIndex = index);
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.homeScreen,
        (_) => false,
      );
    }
  }

  void _onWalletSelected(int index) {
    setState(() => _selectedWalletIndex = index);
  }

  void _onRecipientSelected(String id) {
    setState(() => _selectedRecipientId = id);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final transferViewModel = context.watch<TransferViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.glassBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.glassBorder, width: 0.5),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppTheme.textSecondary,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send Money',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Multi-currency transfer',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Exchange rate live badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.successMuted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.success.withAlpha(77),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Live rates',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneLayout() {
    final transferViewModel = context.watch<TransferViewModel>();
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              children: [
                RecipientSelectorWidget(
                  selectedId: _selectedRecipientId,
                  onSelected: _onRecipientSelected,
                ),
                const SizedBox(height: 16),
                SourceWalletSelectorWidget(
                  selectedIndex: _selectedWalletIndex,
                  onSelected: _onWalletSelected,
                ),
                const SizedBox(height: 16),
                AmountInputWidget(
                  selectedWalletIndex: _selectedWalletIndex,
                ),
                const SizedBox(height: 16),
                AiSuggestionStripWidget(
                  selectedWalletIndex: _selectedWalletIndex,
                ),
                const SizedBox(height: 16),
                TransferFeeBreakdownWidget(
                  amount: transferViewModel.numericAmount,
                  selectedWalletIndex: _selectedWalletIndex,
                ),
                const SizedBox(height: 20),
                ConfirmTransferButtonWidget(
                  amount: transferViewModel.numericAmount,
                  recipientId: _selectedRecipientId,
                  walletIndex: _selectedWalletIndex,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: NumericKeypadWidget(onKeyTap: (String key) {  }, onBackspace: () {  }, displayAmount: '', onClear: () {  },),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    final transferViewModel = context.watch<TransferViewModel>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel — recipient + wallet
        Expanded(
          flex: 35,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 10, 100),
            child: Column(
              children: [
                RecipientSelectorWidget(
                  selectedId: _selectedRecipientId,
                  onSelected: _onRecipientSelected,
                ),
                const SizedBox(height: 16),
                SourceWalletSelectorWidget(
                  selectedIndex: _selectedWalletIndex,
                  onSelected: _onWalletSelected,
                ),
              ],
            ),
          ),
        ),
        // Right panel — amount + breakdown + confirm
        Expanded(
          flex: 65,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(10, 8, 20, 100),
            child: Column(
              children: [
                AmountInputWidget(
                  selectedWalletIndex: _selectedWalletIndex,
                ),
                const SizedBox(height: 16),
                AiSuggestionStripWidget(
                  selectedWalletIndex: _selectedWalletIndex,
                ),
                const SizedBox(height: 16),
                TransferFeeBreakdownWidget(
                  amount: transferViewModel.numericAmount,
                  selectedWalletIndex: _selectedWalletIndex,
                ),
                const SizedBox(height: 20),
                ConfirmTransferButtonWidget(
                  amount: transferViewModel.numericAmount,
                  recipientId: _selectedRecipientId,
                  walletIndex: _selectedWalletIndex,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
