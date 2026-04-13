import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_image_widget.dart';

class HomeHeaderWidget extends StatelessWidget {
  final int currentCardIndex;

  const HomeHeaderWidget({super.key, required this.currentCardIndex});

  static const List<String> _currencies = ['IDR', 'USD', 'CNY'];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String displayName = user?.displayName ?? user?.email ?? 'Guest';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Greeting section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      displayName,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Active currency indicator
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        key: ValueKey(_currencies[currentCardIndex]),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryMuted,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primary.withAlpha(102),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          _currencies[currentCardIndex],
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Notification + Avatar
          Row(
            children: [
              _buildNotificationButton(),
              const SizedBox(width: 12),
              _buildAvatar(user),
            ],
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 👋';
    if (hour < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }

  Widget _buildNotificationButton() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.glassBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.glassBorder, width: 0.5),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ),
          ),
        ),
        // Notification dot
        Positioned(
          top: 8,
          right: 9,
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppTheme.error,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(User? user) {
    final photoUrl = user?.photoURL;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: photoUrl != null
          ? CustomImageWidget(
              imageUrl: photoUrl,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              semanticLabel: 'Profile photo of ${user?.displayName ?? ''}',
            )
          : Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.person_outline_rounded,
                color: AppTheme.primary,
              ),
            ),
    );
  }
}
