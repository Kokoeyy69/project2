import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../core/services/transfer_service.dart';
import '../../presentation/security/pin_verification_screen.dart';
import 'transfer_success_screen.dart';

class ExternalWithdrawalScreen extends StatefulWidget {
  const ExternalWithdrawalScreen({super.key});

  @override
  State<ExternalWithdrawalScreen> createState() => _ExternalWithdrawalScreenState();
}

class _ExternalWithdrawalScreenState extends State<ExternalWithdrawalScreen> {
  String _selectedBank = 'NeoPay';
  final TextEditingController _accountController = TextEditingController();
  int _amount = 0;
  int _currentBalance = 500000;
  bool _isLoading = false;

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int adminFee = _selectedBank == 'NeoPay' ? 0 : 2500;
    final int totalPotongan = _amount + adminFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer ke Bank Lain'),
        backgroundColor: AppTheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bank Selection Dropdown
            DropdownButtonFormField<String>(
              value: _selectedBank,
              decoration: InputDecoration(
                labelText: 'Bank Tujuan',
                filled: true,
                fillColor: AppTheme.glassBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.glassBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primary, width: 2),
                ),
              ),
              items: ['NeoPay', 'BCA', 'Mandiri', 'BNI']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: GoogleFonts.inter(fontSize: 16),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedBank = newValue!;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Account Number Field
            TextFormField(
              controller: _accountController,
              decoration: InputDecoration(
                labelText: _selectedBank == 'NeoPay' ? 'Nomor HP' : 'Nomor Rekening',
                filled: true,
                fillColor: AppTheme.glassBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.glassBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primary, width: 2),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            
            // Amount Field
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Nominal Transfer (Rp)',
                filled: true,
                fillColor: AppTheme.glassBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.glassBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primary, width: 2),
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _amount = int.tryParse(value) ?? 0;
                });
              },
            ),
            const SizedBox(height: 24),
            
            // Fee Breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.glassBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rincian Biaya',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Nominal Transfer:', style: GoogleFonts.inter(fontSize: 14)),
                      Text('Rp $_amount', style: GoogleFonts.inter(fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Biaya Admin:', style: GoogleFonts.inter(fontSize: 14)),
                      Text(
                        'Rp $adminFee',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: _selectedBank == 'NeoPay' ? AppTheme.textSecondary : AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Potongan:',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Rp $totalPotongan',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Balance Warning
            if (totalPotongan > _currentBalance)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.error),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Saldo tidak mencukupi. Saldo Anda: Rp $_currentBalance',
                        style: GoogleFonts.inter(
                          color: AppTheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            
            // Confirm Button
            ElevatedButton(
              onPressed: (totalPotongan > _currentBalance || _amount <= 0 || _accountController.text.isEmpty)
                  ? null
                  : () async {
                      // 1. Validasi Saldo
                      if (totalPotongan > _currentBalance) return;

                      // 2. The Gatekeeper (PIN Check)
                      final bool? isVerified = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PinVerificationScreen()),
                      );
                      if (isVerified != true) return;
                      if (!mounted) return;

                      // 3. Eksekusi Mock Service
                      setState(() => _isLoading = true);
                      final success = await TransferService().simulateTransfer(
                        _amount,
                        _selectedBank,
                        _accountController.text,
                      );
                      if (!mounted) return;
                      setState(() => _isLoading = false);

                      // 4. Navigasi Sukses
                      if (success) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TransferSuccessScreen(
                              // Pass required arguments for the success screen
                            ),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Konfirmasi Transfer',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}