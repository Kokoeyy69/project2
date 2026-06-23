// ignore_for_file: use_build_context_synchronously
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';
import '../../routes/app_routes.dart';
import '../../services/hive_cache_service.dart';
import '../../core/services/security_service.dart';
import '../security/create_pin_screen.dart';
import '../security/verify_pin_screen.dart';
import './widgets/numeric_keypad_widget.dart';
import './widgets/transfer_contact_list_widget.dart';
import 'transfer_view_model.dart';

class TransferKeypadScreen extends StatelessWidget {
  const TransferKeypadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? qrData = ModalRoute.of(context)?.settings.arguments as String?;

    return ChangeNotifierProvider(
      create: (_) {
        final vm = TransferViewModel();
        if (qrData != null && qrData.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            vm.processQrPayload(qrData);
          });
        }
        return vm;
      },
      child: const _TransferKeypadScreenContent(),
    );
  }
}

class _TransferKeypadScreenContent extends StatelessWidget {
  const _TransferKeypadScreenContent();

  void _showConfirmDialog(BuildContext context, TransferViewModel viewModel) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Confirm Transfer',
            style: GoogleFonts.inter(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryMuted,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sending',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        Text(
                          '${viewModel.numericAmount} ${viewModel.selectedCurrency}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppTheme.primary,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Receiving',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        Text(
                          '${viewModel.formattedConvertedAmount} ${viewModel.targetCurrency}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.success,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: AppTheme.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);

                // Step 1: PIN verification gate
                final securityService = SecurityService();
                final hasPin = await securityService.hasTransactionPin();

                // Step 2: Small delay to avoid UI jank after dialog dismissal
                await Future.delayed(const Duration(milliseconds: 150));

                if (!context.mounted) return;

                bool pinOk = false;
                if (!hasPin) {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const CreatePinScreen()),
                  );
                  pinOk = result == true;
                  if (!pinOk && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'PIN harus diatur untuk melakukan transfer',
                          style: GoogleFonts.inter(color: Colors.white),
                        ),
                        backgroundColor: AppTheme.warning,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } else {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VerifyPinScreen(
                        title: 'Verifikasi PIN Transaksi',
                      ),
                    ),
                  );
                  pinOk = result == true;
                  if (!pinOk && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Verifikasi PIN gagal',
                          style: GoogleFonts.inter(color: Colors.white),
                        ),
                        backgroundColor: AppTheme.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }

                // Step 3: Abort if PIN not verified
                if (!pinOk || !context.mounted) return;

                // Step 4: Call secure ApiService
                final success = await viewModel.processTransfer();

                if (!context.mounted) return;

                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Transfer failed. Please try again.',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: AppTheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                // Step 5: Navigate to success screen
                final rateKey =
                    '${viewModel.selectedCurrency}_${viewModel.targetCurrency}';
                final rate = viewModel.rates[rateKey] ?? 1.0;
                final rateStr =
                    viewModel.selectedCurrency == viewModel.targetCurrency
                    ? '1.00'
                    : rate < 1
                    ? rate.toStringAsFixed(6)
                    : rate.toStringAsFixed(4);

                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.transferSuccessScreen,
                  (_) => false,
                  arguments: {
                    'recipientName': viewModel.selectedContactName,
                    'amountSent': viewModel.numericAmount.toString(),
                    'sourceCurrency': viewModel.selectedCurrency,
                    'exchangeRate': rateStr,
                    'amountReceived': viewModel.formattedConvertedAmount,
                    'targetCurrency': viewModel.targetCurrency,
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Confirm',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<TransferViewModel>(context);

    if (viewModel.qrErrorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final message = viewModel.qrErrorMessage;
        if (message == null || !context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        viewModel.clearQrErrorMessage();
      });
    }

    void onNavTap(int index) {
      if (index == 0) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.homeScreen,
          (_) => false,
        );
      } else if (index == 2) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.activityScreen,
          (_) => false,
        );
      } else if (index == 3) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.profileScreen,
          (_) => false,
        );
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                child: Column(
                  children: [
                    _buildCurrencySelector(context, viewModel),
                    const SizedBox(height: 12),

                    // --- KOTAK NOMINAL BESAR YANG BARU DITAMBAHKAN ---
                    _buildLargeAmountDisplay(viewModel),
                    const SizedBox(height: 12),

                    _buildConversionPreview(viewModel),
                    const SizedBox(height: 12),
                    TransferContactListWidget(
                      selectedContactId: viewModel.selectedContactId,
                      onContactSelected: (id, name) {
                        viewModel.setSelectedContact(id, name);
                      },
                    ),
                    const SizedBox(height: 12),
                    NumericKeypadWidget(
                      displayAmount: viewModel.displayAmount,
                      onKeyTap: (key) => viewModel.appendDigit(key),
                      onBackspace: () => viewModel.removeLastDigit(),
                      onClear: () => viewModel.clearAmount(),
                    ),
                    const SizedBox(height: 16),
                    _buildConvertSendButton(context, viewModel),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppNavigation(currentIndex: 1, onTap: onNavTap),
      floatingActionButton: viewModel.isTransferLoading
          ? Container(
              color: Colors.black.withAlpha(50),
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.homeScreen,
              (_) => false,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.glassBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.glassBorder, width: 0.5),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppTheme.textPrimary,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Transfer',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryMuted,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primary.withAlpha(80),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  color: AppTheme.primary,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'AI Rate',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencySelector(
    BuildContext context,
    TransferViewModel viewModel,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.glassBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.glassBorder, width: 0.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildCurrencyDropdown(
                  'From',
                  viewModel.selectedCurrency,
                  (val) => viewModel.setSelectedCurrency(val!),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GestureDetector(
                  onTap: () => viewModel.toggleCurrencies(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryMuted,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _buildCurrencyDropdown(
                  'To',
                  viewModel.targetCurrency,
                  (val) => viewModel.setTargetCurrency(val!),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyDropdown(
    String label,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surface.withAlpha(120),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.glassBorder, width: 0.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              isExpanded: true,
              dropdownColor: AppTheme.surface,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              icon: const Icon(
                Icons.expand_more_rounded,
                color: AppTheme.textMuted,
                size: 16,
              ),
              items: [
                'IDR',
                'USD',
                'CNY',
              ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLargeAmountDisplay(TransferViewModel viewModel) {
    String displayVal = viewModel.displayAmount;
    if (displayVal.startsWith('Rp')) {
      displayVal = displayVal.substring(2);
    }

    String currencySymbol = 'Rp ';
    if (viewModel.selectedCurrency == 'USD') currencySymbol = '\$ ';
    if (viewModel.selectedCurrency == 'CNY') currencySymbol = '¥ ';

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface.withAlpha(153),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.glassBorder, width: 0.5),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Amount',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.glassBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primary.withAlpha(153),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      currencySymbol,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        displayVal,
                        style: GoogleFonts.inter(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversionPreview(TransferViewModel viewModel) {
    if (viewModel.numericAmount == 0) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.successMuted,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.success.withAlpha(80),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.currency_exchange_rounded,
                color: AppTheme.success,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '${viewModel.numericAmount} ${viewModel.selectedCurrency} = ${viewModel.formattedConvertedAmount} ${viewModel.targetCurrency}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConvertSendButton(
    BuildContext context,
    TransferViewModel viewModel,
  ) {
    final currentBalance = HiveCacheService.getCachedBalance() ?? 0.0;
    double amountInIdr = viewModel.numericAmount;
    if (viewModel.selectedCurrency != 'IDR') {
      final rateKey = '${viewModel.selectedCurrency}_IDR';
      amountInIdr = viewModel.numericAmount * (viewModel.rates[rateKey] ?? 1.0);
    }

    final isInsufficient =
        viewModel.numericAmount > 0 && amountInIdr > currentBalance;
    final isReady = viewModel.isTransferReady && !isInsufficient;

    return Column(
      children: [
        if (isInsufficient)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Saldo tidak mencukupi',
              style: GoogleFonts.inter(
                color: AppTheme.error,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        GestureDetector(
          onTap: isReady ? () => _showConfirmDialog(context, viewModel) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: isReady
                  ? const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              color: isReady ? null : AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isReady
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha(80),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (viewModel.isTransferLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Icon(
                    Icons.send_rounded,
                    color: isReady ? Colors.white : AppTheme.textMuted,
                    size: 18,
                  ),
                const SizedBox(width: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    key: ValueKey(viewModel.isTransferLoading),
                    viewModel.isTransferLoading
                        ? 'Processing...'
                        : 'Convert & Send',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isReady || viewModel.isTransferLoading
                          ? Colors.white
                          : AppTheme.textMuted,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
