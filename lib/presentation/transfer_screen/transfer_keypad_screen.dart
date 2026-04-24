import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';
import '../../routes/app_routes.dart';
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
  String _selectedCurrency = 'IDR';
  String _targetCurrency = 'USD';

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
    if (_amount.isEmpty || _selectedContactId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _amount.isEmpty
                ? 'Please enter an amount'
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
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    final transferAmount = double.tryParse(_amount) ?? 0;

                    // 1. Cek Saldo
                    final userDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .get();
                    
                    final currentBalance = (userDoc.data()?['balance'] ?? 0) as num;

                    // 2. Tolak jika saldo kurang
                    if (transferAmount > currentBalance) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Insufficient balance. Your balance is Rp $currentBalance',
                                    style: GoogleFonts.inter(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: AppTheme.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                      return; // STOP DI SINI
                    }

                    // 3. Potong Saldo
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({
                      'balance': FieldValue.increment(-transferAmount),
                    });

                    // 4. Siapkan nama penerima untuk riwayat
                    final contactNames = {
                      'c1': 'Rania Kusuma',
                      'c2': 'Budi Santoso',
                      'c3': 'Siti Rahayu',
                      'c4': 'Ahmad Fauzi',
                      'c5': 'Dewi Lestari',
                    };
                    final recipientName =
                        contactNames[_selectedContactId] ?? 'Recipient';

                    // --- 5. INI DIA MESIN PENCATAT RIWAYATNYA! ---
                    await FirebaseFirestore.instance.collection('transactions').add({
                      'userId': user.uid,
                      'recipientName': recipientName,
                      'amount': transferAmount,
                      'currency': _selectedCurrency,
                      'type': 'transfer_out',
                      'timestamp': FieldValue.serverTimestamp(),
                      'status': 'completed',
                    });
                    // ---------------------------------------------

                    // 6. Pindah ke Halaman Sukses
                    final rateKey = '${_selectedCurrency}_$_targetCurrency';
                    final rate = _rates[rateKey] ?? 1.0;
                    final rateStr = _selectedCurrency == _targetCurrency
                        ? '1.00'
                        : rate < 1
                        ? rate.toStringAsFixed(6)
                        : rate.toStringAsFixed(4);

                    if (mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.transferSuccessScreen,
                        (_) => false,
                        arguments: {
                          'recipientName': recipientName,
                          'amountSent': _amount,
                          'sourceCurrency': _selectedCurrency,
                          'exchangeRate': rateStr,
                          'amountReceived': _getConvertedAmount(),
                          'targetCurrency': _targetCurrency,
                        },
                      );
                    }
                  }
                } catch (e) {
                  debugPrint("Error potong saldo: $e");
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
                      onContactSelected: (id) =>
                          setState(() => _selectedContactId = id),
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
    final isReady = _amount.isNotEmpty && _selectedContactId != null;
    return GestureDetector(
      onTap: _onConvertAndSend,
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
            Icon(
              Icons.send_rounded,
              color: isReady ? Colors.white : AppTheme.textMuted,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              'Convert & Send',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isReady ? Colors.white : AppTheme.textMuted,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}