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
  // TODO: Replace with Riverpod/Bloc for production
  final TextEditingController _searchController = TextEditingController();
  late List<RecipientModel> _recipients;
  late List<RecipientModel> _filtered;

  static final List<Map<String, dynamic>> _recipientMaps = [
    {
      'id': 'R001',
      'name': 'Ahmad Fauzi',
      'accountNumber': '••• 4821',
      'bank': 'BCA',
      'currency': 'IDR',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_169492cd1-1763292671059.png',
      'semanticLabel':
          'Professional headshot of Indonesian man with short dark hair in white shirt',
      'isAiSuggested': true,
    },
    {
      'id': 'R002',
      'name': 'Siti Rahayu',
      'accountNumber': '••• 7293',
      'bank': 'Mandiri',
      'currency': 'IDR',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_14e813e64-1772288853436.png',
      'semanticLabel': 'Young Indonesian woman with hijab smiling at camera',
      'isAiSuggested': false,
    },
    {
      'id': 'R003',
      'name': 'Wei Liang Chen',
      'accountNumber': '••• 5564',
      'bank': 'ICBC',
      'currency': 'CNY',
      'imageUrl':
          'https://images.unsplash.com/photo-1713870816826-08e4b536d1ed',
      'semanticLabel':
          'Young East Asian man with glasses in casual blue shirt outdoors',
      'isAiSuggested': true,
    },
    {
      'id': 'R004',
      'name': 'Maya Putri',
      'accountNumber': '••• 3317',
      'bank': 'BNI',
      'currency': 'IDR',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_18d554571-1767492203815.png',
      'semanticLabel':
          'Young Javanese woman with long dark hair smiling warmly',
      'isAiSuggested': false,
    },
    {
      'id': 'R005',
      'name': 'James Thornton',
      'accountNumber': '••• 9042',
      'bank': 'Chase',
      'currency': 'USD',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_12a142cca-1772829111154.png',
      'semanticLabel':
          'Middle-aged Caucasian man in navy blazer with brown hair',
      'isAiSuggested': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _recipients = _recipientMaps.map(RecipientModel.fromMap).toList();
    _filtered = List.from(_recipients);
    _searchController.addListener(_onSearch);
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
                      r.bank.toLowerCase().contains(query),
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
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentMuted,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'AI Suggested',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accent,
                        ),
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
                      hintText: 'Search recipient or bank...',
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
              // Recipient list
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
