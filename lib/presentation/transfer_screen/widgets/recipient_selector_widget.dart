import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_image_widget.dart';

class RecipientModel {
  final String id;
  final String name;
  final String accountNumber;
  final String bank;
  final String currency;
  final String imageUrl;
  final String semanticLabel;
  final bool isAiSuggested;

  const RecipientModel({
    required this.id,
    required this.name,
    required this.accountNumber,
    required this.bank,
    required this.currency,
    required this.imageUrl,
    required this.semanticLabel,
    this.isAiSuggested = false,
  });

  factory RecipientModel.fromMap(Map<String, dynamic> map) {
    return RecipientModel(
      id: map['id'] as String,
      name: map['name'] as String,
      accountNumber: map['accountNumber'] as String,
      bank: map['bank'] as String,
      currency: map['currency'] as String,
      imageUrl: map['imageUrl'] as String,
      semanticLabel: map['semanticLabel'] as String,
      isAiSuggested: map['isAiSuggested'] as bool? ?? false,
    );
  }
}

class RecipientSelectorWidget extends StatefulWidget {
  final String selectedId;
  final ValueChanged<String> onSelected;

  const RecipientSelectorWidget({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  State<RecipientSelectorWidget> createState() =>
      _RecipientSelectorWidgetState();
}

class _RecipientSelectorWidgetState extends State<RecipientSelectorWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<RecipientModel> _recipients = [];
  List<RecipientModel> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
    _fetchUsersFromFirebase();
  }

  void _fetchUsersFromFirebase() {
    final currentUser = FirebaseAuth.instance.currentUser;

    FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((snapshot) {
      final List<RecipientModel> liveUsers = [];

      for (var doc in snapshot.docs) {
        // Jangan tampilkan akun kita sendiri di daftar penerima
        if (currentUser != null && doc.id == currentUser.uid) continue;

        final data = doc.data();
        final name = data['name'] ?? 'Unknown User';
        final email = data['email'] ?? 'No Email';
        
        liveUsers.add(
          RecipientModel(
            id: doc.id, // UID asli dari Firebase
            name: name,
            accountNumber: email, // Kita pinjam field email buat nampilin di bawah nama
            bank: 'NeoPay',
            currency: 'IDR',
            // Bikin avatar otomatis dari inisial nama kalau belum ada foto
            imageUrl: data['photoUrl'] ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=3B82F6&color=fff',
            semanticLabel: 'Profile of $name',
            isAiSuggested: false, 
          ),
        );
      }

      if (mounted) {
        setState(() {
          _recipients = liveUsers;
          _onSearch(); // Jalankan filter biar list-nya terupdate
          _isLoading = false;
        });
      }
    });
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? List.from(_recipients)
          : _recipients
              .where(
                (r) =>
                    r.name.toLowerCase().contains(query) ||
                    r.accountNumber.toLowerCase().contains(query),
              )
              .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    Text(
                      'Send To',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // Search field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.glassBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.glassBorder, width: 0.5),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search recipient email or name...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: AppTheme.textMuted,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              
              // Recipient list atau Loading
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  ),
                )
              else if (_filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      'No users found',
                      style: GoogleFonts.inter(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => Divider(
                    color: AppTheme.separator,
                    height: 0,
                    thickness: 0.5,
                    indent: 68,
                  ),
                  itemBuilder: (context, index) {
                    final r = _filtered[index];
                    final isSelected = r.id == widget.selectedId;
                    return _RecipientTile(
                      recipient: r,
                      isSelected: isSelected,
                      onTap: () => widget.onSelected(r.id),
                    );
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipientTile extends StatelessWidget {
  final RecipientModel recipient;
  final bool isSelected;
  final VoidCallback onTap;

  const _RecipientTile({
    required this.recipient,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: AppTheme.primary.withAlpha(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        color: isSelected
            ? AppTheme.primaryMuted.withAlpha(26)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: CustomImageWidget(
                    imageUrl: recipient.imageUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    semanticLabel: recipient.semanticLabel,
                  ),
                ),
                if (recipient.isAiSuggested)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.accent],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.surface, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        size: 9,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipient.name,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${recipient.bank} · ${recipient.accountNumber}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.glassBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.glassBorder, width: 0.5),
                  ),
                  child: Text(
                    recipient.currency,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppTheme.primary,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
