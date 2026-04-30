import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';
import '../../widgets/app_navigation.dart';
import '../../viewmodels/home_view_model.dart';
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

  late final HomeViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = HomeViewModel();
    _vm.start();
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
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: ChangeNotifierProvider<HomeViewModel>.value(
          value: _vm,
          child: Consumer<HomeViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading)
                return const Center(child: CircularProgressIndicator());
              if (vm.hasError)
                return Center(
                  child: Text(
                    'Error: ${vm.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              final balances = [vm.balance];

              return RefreshIndicator(
                onRefresh: vm.refresh,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: HomeHeaderWidget(
                        currentCardIndex: _currentCardIndex,
                      ),
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
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: AppNavigation(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
