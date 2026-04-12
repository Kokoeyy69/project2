import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../widgets/app_navigation.dart';
import './widgets/ai_command_bar_widget.dart';
import './widgets/home_header_widget.dart';
import './widgets/quick_actions_grid_widget.dart';
import './widgets/recent_transactions_widget.dart';
import './widgets/wallet_card_carousel_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // TODO: Replace with Riverpod/Bloc for production
  int _currentNavIndex = 0;
  int _currentCardIndex = 0;

  void _onNavTap(int index) {
    setState(() => _currentNavIndex = index);
    if (index == 1) {
      Navigator.pushNamed(context, AppRoutes.transferKeypadScreen);
    } else if (index == 2) {
      Navigator.pushNamed(context, AppRoutes.activityScreen);
    } else if (index == 3) {
      Navigator.pushNamed(context, AppRoutes.profileScreen);
    }
  }

  void _onCardChanged(int index) {
    setState(() => _currentCardIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: HomeHeaderWidget(currentCardIndex: _currentCardIndex),
            ),
            SliverToBoxAdapter(
              child: WalletCardCarouselWidget(onCardChanged: _onCardChanged),
            ),
            SliverToBoxAdapter(child: AiCommandBarWidget()),
            SliverToBoxAdapter(
              child: QuickActionsGridWidget(
                onTransferTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.transferKeypadScreen,
                ),
              ),
            ),
            SliverToBoxAdapter(child: RecentTransactionsWidget()),
            // Bottom padding for nav bar
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
      bottomNavigationBar: AppNavigation(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
