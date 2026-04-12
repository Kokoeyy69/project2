import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class TransferContactListWidget extends StatefulWidget {
  final String? selectedContactId;
  final ValueChanged<String> onContactSelected;

  const TransferContactListWidget({
    super.key,
    this.selectedContactId,
    required this.onContactSelected,
  });

  @override
  State<TransferContactListWidget> createState() =>
      _TransferContactListWidgetState();
}

class _TransferContactListWidgetState extends State<TransferContactListWidget> {
  final List<Map<String, dynamic>> _contacts = [
    {
      'id': 'c1',
      'name': 'Rania Kusuma',
      'handle': '@rania.k',
      'currency': 'IDR',
      'avatar':
          'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=80&h=80&fit=crop',
      'color': AppTheme.primary,
    },
    {
      'id': 'c2',
      'name': 'James Chen',
      'handle': '@james.chen',
      'currency': 'USD',
      'avatar':
          'https://images.pexels.com/photos/1222271/pexels-photo-1222271.jpeg?w=80&h=80&fit=crop',
      'color': AppTheme.accent,
    },
    {
      'id': 'c3',
      'name': 'Li Wei',
      'handle': '@li.wei',
      'currency': 'CNY',
      'avatar':
          'https://images.pixabay.com/photo/2016/11/21/12/42/beard-1845166_960_720.jpg',
      'color': AppTheme.success,
    },
    {
      'id': 'c4',
      'name': 'Sarah Park',
      'handle': '@sarah.p',
      'currency': 'USD',
      'avatar':
          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=80&h=80&fit=crop',
      'color': AppTheme.warning,
    },
    {
      'id': 'c5',
      'name': 'Ahmad Rizki',
      'handle': '@ahmad.r',
      'currency': 'IDR',
      'avatar':
          'https://images.pexels.com/photos/2379004/pexels-photo-2379004.jpeg?w=80&h=80&fit=crop',
      'color': const Color(0xFF8B5CF6),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.glassBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.glassBorder, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Text(
                  'Select Recipient',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              SizedBox(
                height: 96,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    final isSelected =
                        widget.selectedContactId == contact['id'];
                    return GestureDetector(
                      onTap: () =>
                          widget.onContactSelected(contact['id'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (contact['color'] as Color).withAlpha(40)
                              : AppTheme.surface.withAlpha(120),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? (contact['color'] as Color).withAlpha(180)
                                : AppTheme.glassBorder,
                            width: isSelected ? 1.5 : 0.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? (contact['color'] as Color)
                                      : AppTheme.glassBorder,
                                  width: 1.5,
                                ),
                              ),
                              child: ClipOval(
                                child: Image.network(
                                  contact['avatar'] as String,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: (contact['color'] as Color)
                                        .withAlpha(60),
                                    child: Icon(
                                      Icons.person_rounded,
                                      color: contact['color'] as Color,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              (contact['name'] as String).split(' ').first,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
