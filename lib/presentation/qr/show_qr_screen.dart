import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../theme/app_theme.dart';

class ShowQRScreen extends StatefulWidget {
  const ShowQRScreen({super.key});

  @override
  State<ShowQRScreen> createState() => _ShowQRScreenState();
}

class _ShowQRScreenState extends State<ShowQRScreen> {
  String? _userName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() {
          _userName = doc.data()?['name'] ?? 'NeoPay User';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = 'NeoPay User';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Terima Pembayaran',
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: SpinKitFadingCircle(color: AppTheme.primary, size: 40),
            )
          : user == null
              ? Center(
                  child: Text('Silakan login terlebih dahulu',
                      style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                )
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Profile avatar
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppTheme.primaryMuted,
                          child: Icon(Icons.person, size: 40, color: AppTheme.primary),
                        ),
                        const SizedBox(height: 24),
                        // User name
                        Text(
                          _userName ?? 'NeoPay User',
                          style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Scan QR ini untuk membayar',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 32),
                        // QR Code Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withAlpha(20),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              QrImageView(
                                data: user.uid,
                                version: QrVersions.auto,
                                size: 200.0,
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Colors.black87,
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryMuted,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'NeoPay ID',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Info card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.glassBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.glassBorder, width: 0.5),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Bagikan QR ini kepada pengirim untuk menerima pembayaran langsung ke saldo Anda.',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                      height: 1.5),
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
}