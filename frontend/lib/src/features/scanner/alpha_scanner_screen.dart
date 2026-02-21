import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horizon/src/core/theme/app_theme.dart';
import 'package:horizon/src/core/widgets/glass_card.dart';
import 'package:horizon/src/features/stock/stock_repository.dart';
import 'package:horizon/src/features/briefing/briefing_repository.dart';

class AlphaScannerScreen extends ConsumerWidget {
  const AlphaScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefingAsync = ref.watch(briefingRepositoryProvider);
    final stocksAsync = ref.watch(stockRepositoryProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Color(0x22FFB800),
              AppTheme.obsidian,
            ],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _ScannerHeader(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ScannerPulse(),
                    const SizedBox(height: 30),
                    _ScannerSectionHeader(title: 'Sentiment Divergences'),
                    const SizedBox(height: 8),
                    const Text(
                      'AI Sentiment is high, but price action remains flat/down.',
                      style: TextStyle(color: Colors.white24, fontSize: 11),
                    ),
                    const SizedBox(height: 15),
                    stocksAsync.when(
                      data: (stocks) {
                        // Find stocks with high sentiment but flat/negative price
                        final divergences = stocks.where((s) => s.sentiment > 0.7 && s.changePercent <= 0).toList();
                        if (divergences.isEmpty) {
                          return const _EmptyScannerState(message: 'No active divergences detected.');
                        }
                        return Column(
                          children: divergences.map((s) => _DivergenceCard(
                            ticker: s.ticker, 
                            sentiment: s.sentiment, 
                            priceAction: s.changePercent <= 0 ? '${s.changePercent}%' : 'Flat'
                          )).toList(),
                        );
                      },
                      loading: () => const LinearProgressIndicator(color: AppTheme.goldAmber),
                      error: (e, s) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 30),
                    _ScannerSectionHeader(title: 'Macro Impact Map'),
                    const SizedBox(height: 15),
                    _MacroImpactMap(),
                    const SizedBox(height: 30),
                    _ScannerSectionHeader(title: 'Strategic Catalysts'),
                    const SizedBox(height: 15),
                    briefingAsync.when(
                      data: (briefing) {
                        // Extract "Takeaways" from all categories as catalysts
                        final List<dynamic> items = [];
                        briefing.data.values.forEach((cat) {
                          items.addAll(cat.items);
                        });
                        
                        final catalysts = items
                            .where((i) => i.takeaway != null)
                            .take(3)
                            .toList();
                            
                        return Column(
                          children: catalysts.map((i) => _CatalystCard(
                            title: i.title ?? 'Market Event', 
                            category: i.takeaway!.split(' ').take(3).join(' ') + '...'
                          )).toList(),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (e, s) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alpha Scanner', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 4),
            Text(
              'Autonomous Opportunity Discovery',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.goldAmber.withOpacity(0.5),
                letterSpacing: 1,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerPulse extends StatefulWidget {
  @override
  State<_ScannerPulse> createState() => _ScannerPulseState();
}

class _ScannerPulseState extends State<_ScannerPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.1, end: 0.4).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.goldAmber.withOpacity(_animation.value)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.goldAmber.withOpacity(_animation.value),
                AppTheme.goldAmber.withOpacity(0),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.radar_rounded, color: AppTheme.goldAmber.withOpacity(_animation.value + 0.4), size: 28),
                const SizedBox(height: 8),
                Text(
                  'SYSTEM SCANNING...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScannerSectionHeader extends StatelessWidget {
  final String title;
  const _ScannerSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
        const Icon(Icons.bolt_rounded, color: AppTheme.goldAmber, size: 14),
      ],
    );
  }
}

class _DivergenceCard extends StatelessWidget {
  final String ticker;
  final double sentiment;
  final String priceAction;

  const _DivergenceCard({required this.ticker, required this.sentiment, required this.priceAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ticker, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Montserrat')),
                Text(
                  'BULLISH DIVERGENCE',
                  style: TextStyle(color: AppTheme.goldAmber.withOpacity(0.8), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('+$sentiment SNT', style: const TextStyle(color: AppTheme.goldAmber, fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Price: $priceAction', style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyScannerState extends StatelessWidget {
  final String message;
  const _EmptyScannerState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Center(
        child: Text(message, style: const TextStyle(color: Colors.white24, fontSize: 12)),
      ),
    );
  }
}

class _MacroImpactMap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      height: 180,
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _GeometricMapPainter(),
          ),
          const Align(
            alignment: Alignment.bottomRight,
            child: Text(
              'CORRELATION ENGINE ACTIVE',
              style: TextStyle(color: Colors.white10, fontSize: 8, letterSpacing: 2),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeometricMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.goldAmber.withOpacity(0.15)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final nodePaint = Paint()
      ..color = AppTheme.goldAmber.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    // Abstract connections representing macro dependencies
    final nodes = [
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width * 0.5, size.height * 0.5),
      Offset(size.width * 0.3, size.height * 0.8),
      Offset(size.width * 0.7, size.height * 0.7),
    ];

    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        canvas.drawLine(nodes[i], nodes[j], paint);
      }
      canvas.drawCircle(nodes[i], 3, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CatalystCard extends StatelessWidget {
  final String title;
  final String category;

  const _CatalystCard({required this.title, required this.category});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.goldAmber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bolt_rounded, color: AppTheme.goldAmber, size: 16),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(category.toUpperCase(), style: TextStyle(color: AppTheme.goldAmber.withOpacity(0.4), fontSize: 9, letterSpacing: 1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
