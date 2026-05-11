// ignore_for_file: use_build_context_synchronously
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../core/services/security_service.dart';
import '../security/create_pin_screen.dart';
import '../security/verify_pin_screen.dart';
import './widgets/numeric_keypad_widget.dart';
import './widgets/transfer_contact_list_widget.dart';

class TransferKeypadScreen extends StatefulWidget {
  const TransferKeypadScreen({super.key});

  @override
  State<TransferKeypadScreen> createState() => _TransferKeypadScreenState();
}

class _TransferKeypadScreenState extends State<TransferKeypadScreen> {
  int _currentNavIndex = 1;
  String _amount = '';
  String? _selectedContactId;
  String? _selectedContactName;
  String _selectedCurrency = 'IDR';
  String _targetCurrency = 'USD';
  bool _isTransferLoading = false; // Debounce: prevents double-spend

  final List<String> _currencies = ['IDR', 'USD', 'CNY'];

  final Map<String, double> _rates = {
    'IDR_USD': 0.000064,
    'IDR_CNY': 0.000463,
    'USD_IDR': 15625.0,
    'USD_CNY': 7.24,
    'CNY_IDR': 2159.0,
    'CNY_USD': 0.138,
  };

  void _onNavTap(int index) {
    setState(() => _currentNavIndex = index);
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

  void _onKeyTap(String key) {
    setState(() {
      if (key == '.' && _amount.contains('.')) return;
      if (key == '000' && _amount.isEmpty) return;
      if (_amount.length >= 12) return;
      _amount += key;
    });
  }

  void _onBackspace() {
    if (_amount.isNotEmpty) {
      setState(() => _amount = _amount.substring(0, _amount.length - 1));
    }
  }

  void _onClear() => setState(() => _amount = '');

  String _getConvertedAmount() {
    if (_amount.isEmpty) return '0.00';
    final val = double.tryParse(_amount) ?? 0.0;
    if (_selectedCurrency == _targetCurrency) return _amount;
    final key = '${_selectedCurrency}_$_targetCurrency';
    final rate = _rates[key] ?? 1.0;
    final converted = val * rate;
    if (converted >= 1000) {
      return converted
          .toStringAsFixed(0)
          .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
    }
    return converted.toStringAsFixed(2);
  }

  void _onConvertAndSend() {
    if (_isTransferLoading) return; // Debounce guard
    final val = double.tryParse(_amount) ?? 0;
    if (val <= 0 || _selectedContactId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            val <= 0
                ? 'Please enter a valid amount'
                : 'Please select a recipient',
            style: GoogleFonts.inter(color: AppTheme.textPrimary),
          ),
          backgroundColor: AppTheme.surfaceVariant,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    _showConfirmDialog();
  }

 void _showConfirmDialog() {
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
                          '$_amount $_selectedCurrency',
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
                          '${_getConvertedAmount()} $_targetCurrency',
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

                if (!mounted) return;

                bool pinOk = false;
                if (!hasPin) {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const CreatePinScreen()),
                  );
                  pinOk = result == true;
                  if (!pinOk && mounted) {
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
                  if (!pinOk && mounted) {
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
                if (!pinOk || !mounted) return;

                // Step 4: Call secure ApiService — NO direct Firestore writes here
                // Lock button to prevent double-spend
                if (mounted) setState(() => _isTransferLoading = true);

                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    if (mounted) setState(() => _isTransferLoading = false);
                    return;
                  }

                  final transferAmount = double.tryParse(_amount) ?? 0.0;
                  final transferReq = TransferRequest(
                    senderUid: user.uid,
                    recipientUid: _selectedContactId ?? '',
                    amount: transferAmount,
                    recipientName: _selectedContactName ?? 'Recipient',
                    senderName: user.displayName ?? 'User',
                  );

                  final res = await ApiService.instance.processTransfer(transferReq);

                  if (!mounted) return;

                  if (!res.success) {
                    setState(() => _isTransferLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          res.error ?? res.message ?? 'Transfer failed. Please try again.',
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: AppTheme.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  // Step 5: Navigate to success screen.
                  // HomeViewModel uses a live Firestore stream — balance
                  // auto-updates on the home screen without a manual refresh.
                  final rateKey = '${_selectedCurrency}_$_targetCurrency';
                  final rate = _rates[rateKey] ?? 1.0;
                  final rateStr = _selectedCurrency == _targetCurrency
                      ? '1.00'
                      : rate < 1
                          ? rate.toStringAsFixed(6)
                          : rate.toStringAsFixed(4);

                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.transferSuccessScreen,
                    (_) => false,
                    arguments: {
                      'recipientName': _selectedContactName ?? 'Recipient',
                      'amountSent': _amount,
                      'sourceCurrency': _selectedCurrency,
                      'exchangeRate': rateStr,
                      'amountReceived': _getConvertedAmount(),
                      'targetCurrency': _targetCurrency,
                    },
                  );
                } catch (e) {
                  debugPrint('[TransferKeypad] Transfer error: $e');
                  if (!mounted) return;
                  setState(() => _isTransferLoading = false);
                  String errorMsg = 'Transfer failed. Please try again.';
                  if (e.toString().contains('Insufficient_Balance')) {
                    errorMsg = 'Insufficient balance to cover amount + fee.';
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        errorMsg,
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      backgroundColor: AppTheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                child: Column(
                  children: [
                    _buildCurrencySelector(),
                    const SizedBox(height: 12),
                    
                    // --- KOTAK NOMINAL BESAR YANG BARU DITAMBAHKAN ---
                    _buildLargeAmountDisplay(),
                    const SizedBox(height: 12),
                    
                    _buildConversionPreview(),
                    const SizedBox(height: 12),
                    TransferContactListWidget(
                      selectedContactId: _selectedContactId,
                      onContactSelected: (id, name) =>
                          setState(() {
                            _selectedContactId = id;
                            _selectedContactName = name;
                          }),
                    ),
                    const SizedBox(height: 12),
                    NumericKeypadWidget(
                      displayAmount: _amount,
                      onKeyTap: _onKeyTap,
                      onBackspace: _onBackspace,
                      onClear: _onClear,
                    ),
                    const SizedBox(height: 16),
                    _buildConvertSendButton(),
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

  // --- FUNGSI BARU UNTUK MERENDER KOTAK NOMINAL ---
  Widget _buildLargeAmountDisplay() {
    // Format angkanya biar ada titik ribuannya
    String displayVal = _amount.isEmpty ? '0' : _amount;
    if (_amount.isNotEmpty) {
      final val = double.tryParse(_amount) ?? 0.0;
      displayVal = val.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
    }

    String currencySymbol = 'Rp ';
    if (_selectedCurrency == 'USD') currencySymbol = '\$ ';
    if (_selectedCurrency == 'CNY') currencySymbol = '¥ ';

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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.glassBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withAlpha(153), width: 1.2),
                ),
                child: Row(
                  children: [
                    Text(
                      currencySymbol,
                      style: GoogleFonts.inter(
                        fontSize: 24, 
                        fontWeight: FontWeight.w600, 
                        color: AppTheme.textSecondary
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

  // ... (Sisa fungsi AppBar, Dropdown, dll tetap sama)

  Widget _buildAppBar() {
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

  Widget _buildCurrencySelector() {
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
                  _selectedCurrency,
                  (val) => setState(() => _selectedCurrency = val!),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GestureDetector(
                  onTap: () => setState(() {
                    final tmp = _selectedCurrency;
                    _selectedCurrency = _targetCurrency;
                    _targetCurrency = tmp;
                  }),
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
                  _targetCurrency,
                  (val) => setState(() => _targetCurrency = val!),
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
              items: _currencies
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConversionPreview() {
    if (_amount.isEmpty) return const SizedBox.shrink();
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
                '$_amount $_selectedCurrency = ${_getConvertedAmount()} $_targetCurrency',
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

  Widget _buildConvertSendButton() {
    final isReady = _amount.isNotEmpty && _selectedContactId != null && !_isTransferLoading;
    return GestureDetector(
      onTap: isReady ? _onConvertAndSend : null,
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
            if (_isTransferLoading)
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
                key: ValueKey(_isTransferLoading),
                _isTransferLoading ? 'Processing...' : 'Convert & Send',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isReady || _isTransferLoading ? Colors.white : AppTheme.textMuted,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}