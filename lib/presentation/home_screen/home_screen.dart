import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  int _currentNavIndex = 0;
  int _currentCardIndex = 0;
  Stream<DocumentSnapshot>? _balanceStream;

  @override
  void initState() {
    super.initState();
    _setupBalanceStream();
  }

  void _setupBalanceStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _balanceStream = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots();
      });
    }
  }

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
        child: StreamBuilder<DocumentSnapshot>(
          stream: _balanceStream,
          builder: (context, snapshot) {
            final data = snapshot.data?.data() as Map<String, dynamic>?;
            final balances = data?['balance'] as List<dynamic>?;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: HomeHeaderWidget(currentCardIndex: _currentCardIndex),
                ),
                SliverToBoxAdapter(
                  child: WalletCardCarouselWidget(
                    balances: balances,
                    onCardChanged: _onCardChanged,
                  ),
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
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: AppNavigation(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
