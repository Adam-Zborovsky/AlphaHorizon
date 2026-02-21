import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horizon/src/core/theme/app_theme.dart';
import 'package:horizon/src/core/widgets/glass_card.dart';
import 'package:horizon/src/features/stock/stock_repository.dart';
import 'package:horizon/src/features/dashboard/watchlist_provider.dart';

class ManageWatchlistScreen extends ConsumerStatefulWidget {
  const ManageWatchlistScreen({super.key});

  @override
  ConsumerState<ManageWatchlistScreen> createState() => _ManageWatchlistScreenState();
}

class _ManageWatchlistScreenState extends ConsumerState<ManageWatchlistScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _recommended = ['AAPL', 'TSLA', 'AMD', 'MSFT', 'GOOGL', 'AMZN'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final watchlist = ref.watch(watchlistProvider);
    final stocksAsync = ref.watch(stockRepositoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.obsidian,
      body: CustomScrollView(
        slivers: [
          _SliverSearchHeader(
            controller: _searchController, 
            onSubmitted: (val) {
              if (val.isNotEmpty) {
                ref.read(watchlistProvider.notifier).add(val);
                _searchController.clear();
              }
            },
          ),
          SliverToBoxAdapter(
            child: _RecommendedSection(
              recommended: _recommended,
              onTap: (ticker) => ref.read(watchlistProvider.notifier).add(ticker),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            sliver: SliverToBoxAdapter(
              child: Text(
                'ACTIVE WATCHLIST',
                style: TextStyle(
                  color: AppTheme.goldAmber,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          stocksAsync.when(
            data: (stocks) {
              final filtered = stocks.where((s) => watchlist.contains(s.ticker)).toList();
              if (filtered.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('No stocks in watchlist', style: TextStyle(color: Colors.white24)),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final stock = filtered[index];
                    return _WatchlistItem(
                      stock: stock,
                      onRemove: () => ref.read(watchlistProvider.notifier).remove(stock.ticker),
                    );
                  },
                  childCount: filtered.length,
                ),
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (err, stack) => SliverToBoxAdapter(child: Center(child: Text('Error: $err'))),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _SliverSearchHeader extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSubmitted;

  const _SliverSearchHeader({required this.controller, required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      collapsedHeight: 100,
      pinned: true,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      elevation: 0,
      flexibleSpace: GlassCard(
        borderRadius: 0,
        blur: 20,
        padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 10),
        color: AppTheme.obsidian.withOpacity(0.7),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onSubmitted: onSubmitted,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'SEARCH TICKERS...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14, letterSpacing: 1),
                      border: InputBorder.none,
                      suffixIcon: Icon(Icons.search_rounded, color: AppTheme.goldAmber.withOpacity(0.5)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendedSection extends StatelessWidget {
  final List<String> recommended;
  final Function(String) onTap;

  const _RecommendedSection({required this.recommended, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 24, top: 30, bottom: 12),
          child: Text(
            'RECOMMENDED',
            style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
        ),
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: recommended.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ActionChip(
                  label: Text(recommended[index]),
                  onPressed: () => onTap(recommended[index]),
                  backgroundColor: AppTheme.glassWhite,
                  side: BorderSide(color: AppTheme.goldAmber.withOpacity(0.3)),
                  labelStyle: const TextStyle(color: AppTheme.goldAmber, fontWeight: FontWeight.bold, fontSize: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WatchlistItem extends StatelessWidget {
  final StockData stock;
  final VoidCallback onRemove;

  const _WatchlistItem({required this.stock, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stock.ticker,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Montserrat'),
                ),
                Text(
                  stock.name,
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3)),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline_rounded, color: AppTheme.softCrimson, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
