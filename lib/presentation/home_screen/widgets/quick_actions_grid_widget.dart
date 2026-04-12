import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class QuickActionsGridWidget extends StatelessWidget {
  final VoidCallback onTransferTap;

  const QuickActionsGridWidget({super.key, required this.onTransferTap});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          isTablet
              ? Row(
                  children: _buildActionItems(context)
                      .map(
                        (w) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: w,
                          ),
                        ),
                      )
                      .toList(),
                )
              : GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 0,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.82,
                  children: _buildActionItems(context),
                ),
        ],
      ),
    );
  }

  List<Widget> _buildActionItems(BuildContext context) {
    final actions = [
      _ActionItem(
        icon: Icons.swap_horiz_rounded,
        label: 'Transfer',
        color: AppTheme.primary,
        onTap: onTransferTap,
      ),
      _ActionItem(
        icon: Icons.qr_code_scanner_rounded,
        label: 'Scan QR',
        color: AppTheme.accent,
        onTap: () {},
      ),
      _ActionItem(
        icon: Icons.add_circle_outline_rounded,
        label: 'Top-up',
        color: AppTheme.success,
        onTap: () {},
      ),
      _ActionItem(
        icon: Icons.currency_exchange_rounded,
        label: 'Rates',
        color: AppTheme.warning,
        onTap: () {},
      ),
    ];

    return actions.map((action) => _ActionButton(item: action)).toList();
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _ActionButton extends StatefulWidget {
  final _ActionItem item;

  const _ActionButton({required this.item});

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.item.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: widget.item.color.withAlpha(31),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: widget.item.color.withAlpha(64),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    widget.item.icon,
                    color: widget.item.color,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              widget.item.label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
