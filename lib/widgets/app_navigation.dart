import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';

class AppNavigation extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation>
    with SingleTickerProviderStateMixin {
  late AnimationController _pillController;
  late Animation<double> _pillAnimation;
  int _previousIndex = 0;

  final List<_NavItem> _items = const [
    _NavItem(
      icon: Icons.home_rounded,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItem(
      icon: Icons.swap_horiz_rounded,
      activeIcon: Icons.swap_horiz_rounded,
      label: 'Transfer',
    ),
    _NavItem(
      icon: Icons.receipt_long_rounded,
      activeIcon: Icons.receipt_long_rounded,
      label: 'Activity',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    _pillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pillAnimation = CurvedAnimation(
      parent: _pillController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void didUpdateWidget(AppNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _pillController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _pillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Floating Navbar
        ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.surface.withAlpha(217),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: AppTheme.glassBorder, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.surface.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = constraints.maxWidth / _items.length;
                  final qrisIndex = (_items.length / 2).floor();

                  return Stack(
                    children: [
                      // Animated pill indicator
                      AnimatedBuilder(
                        animation: _pillAnimation,
                        builder: (context, child) {
                          final fromX = _previousIndex * itemWidth;
                          final toX = widget.currentIndex * itemWidth;
                          final currentX =
                              fromX + (toX - fromX) * _pillAnimation.value;

                          return Positioned(
                            left: currentX,
                            top: 8,
                            child: Container(
                              width: itemWidth,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryMuted,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: AppTheme.primary.withAlpha(102),
                                  width: 0.5,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Nav items
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(_items.length, (index) {
                          final isActive = index == widget.currentIndex;
                          final isQrisPosition = index == qrisIndex;

                          if (isQrisPosition) {
                            return SizedBox(
                                width: itemWidth); // Placeholder for QRIS FAB
                          }

                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                widget.onTap(index);
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Semantics(
                                label: _items[index].label,
                                child: Tooltip(
                                  message: _items[index].label,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        child: Icon(
                                          isActive
                                              ? _items[index].activeIcon
                                              : _items[index].icon,
                                          key: ValueKey('$index-$isActive'),
                                          size: 24,
                                          color: isActive
                                              ? AppTheme.primary
                                              : AppTheme.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      AnimatedDefaultTextStyle(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: isActive
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: isActive
                                              ? AppTheme.primary
                                              : AppTheme.textMuted,
                                        ),
                                        child: Text(_items[index].label),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        // QRIS FAB
        Transform.translate(
          offset: const Offset(0, -15),
          child: FloatingActionButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, AppRoutes.ocrScannerScreen);
            },
            backgroundColor: AppTheme.primary,
            shape: const CircleBorder(),
            elevation: 8,
            highlightElevation: 12,
            child: Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}