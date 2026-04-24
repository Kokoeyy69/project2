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
    // KITA KUNCI KONEKSINYA DI SINI BIAR GAK RESET TERUS
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _balanceStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots();
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
          // PANGGIL VARIABEL YANG UDAH DIKUNCI TADI
          stream: _balanceStream, 
          builder: (context, snapshot) {
            
            // Loading cuma jalan sekali di awal
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.purple));
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
            }

            final data = snapshot.data?.data() as Map<String, dynamic>?;

            if (data == null) {
              return const Center(
                child: Text("Data tidak ditemukan di Firestore!", 
                style: TextStyle(color: Colors.white))
              );
            }

            // Data berhasil ditarik dan UI dirender
            final balanceValue = data['balance'] ?? 0;
            final balances = [balanceValue];

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
                const SliverToBoxAdapter(child: AiCommandBarWidget()),
                SliverToBoxAdapter(
                  child: QuickActionsGridWidget(
                    onTransferTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.transferKeypadScreen,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: RecentTransactionsWidget()),
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