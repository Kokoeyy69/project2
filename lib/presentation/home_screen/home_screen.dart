import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';
import '../../widgets/app_navigation.dart';
import '../../viewmodels/home_view_model.dart';
import './widgets/ai_command_bar_widget.dart';
import './widgets/home_header_widget.dart';
import './widgets/quick_actions_grid_widget.dart';
import './widgets/recent_transactions_widget.dart';
import './widgets/wallet_card_carousel_widget.dart';
import './widgets/ai_insight_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel()..start(),
      child: const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatefulWidget {
  const _HomeScreenContent();

  @override
  State<_HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<_HomeScreenContent> {
  bool _showNavBar = true;

  void _onScroll(UserScrollNotification notification) {
    if (notification.direction == ScrollDirection.reverse) {
      if (_showNavBar) {
        setState(() => _showNavBar = false);
      }
    } else if (notification.direction == ScrollDirection.forward) {
      if (!_showNavBar) {
        setState(() => _showNavBar = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HomeViewModel>(context);

    void onNavTap(int index) {
      viewModel.setCurrentNavIndex(index);
      if (index == 1) {
        Navigator.pushNamed(context, AppRoutes.transferKeypadScreen);
      } else if (index == 2) {
        Navigator.pushNamed(context, AppRoutes.activityScreen);
      } else if (index == 3) {
        Navigator.pushNamed(context, AppRoutes.profileScreen);
      }
    }

    void onCardChanged(int index) {
      viewModel.setCurrentCardIndex(index);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Consumer<HomeViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (vm.hasError) {
              return Center(
                child: Text(
                  'Error: ${vm.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }
            final balances = [vm.balance, vm.balanceUsd, vm.balanceCny];

            return RefreshIndicator(
              onRefresh: vm.refresh,
              child: NotificationListener<UserScrollNotification>(
                onNotification: (notification) {
                  _onScroll(notification);
                  return true;
                },
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 80.0,
                      floating: true,
                      pinned: true,
                      backgroundColor: const Color(0xFF0D0F14).withValues(alpha: 0.8),
                      elevation: 0,
                      flexibleSpace: FlexibleSpaceBar(
                        background: HomeHeaderWidget(
                          currentCardIndex: vm.currentCardIndex,
                        ),
                        stretchModes: const [
                          StretchMode.zoomBackground,
                          StretchMode.blurBackground,
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: WalletCardCarouselWidget(
                        balances: balances,
                        onCardChanged: onCardChanged,
                      ),
                    ),
                    const SliverToBoxAdapter(child: AiInsightCard()),
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
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        margin: EdgeInsets.only(
          bottom: _showNavBar ? 20 + MediaQuery.of(context).padding.bottom : -100,
        ),
        child: AppNavigation(
          currentIndex: viewModel.currentNavIndex,
          onTap: onNavTap,
        ),
      ),
    );
  }
}