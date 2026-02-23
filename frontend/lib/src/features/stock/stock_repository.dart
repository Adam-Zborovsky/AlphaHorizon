import 'dart:math';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../briefing/briefing_repository.dart';
import '../briefing/briefing_config_repository.dart';

part 'stock_repository.freezed.dart';
part 'stock_repository.g.dart';

@freezed
abstract class StockData with _$StockData {
  const factory StockData({
    required String ticker,
    required String name,
    required double currentPrice,
    required double changePercent,
    required List<double> history, // Last 24 hours/points for sparkline
    required double sentiment,
    String? analysis,
    List<String>? catalysts,
    List<String>? risks,
    String? potentialPriceAction,
  }) = _StockData;

  factory StockData.fromJson(Map<String, dynamic> json) => _$StockDataFromJson(json);
}

@riverpod
class StockRepository extends _$StockRepository {
  double _extractPrice(String? text) {
    if (text == null || text.isEmpty) return 0.0;
    // Look for patterns like "$420", "420.00", "at 420"
    final regex = RegExp(r'\$(\d+(?:\.\d+)?)|\b(\d+(?:\.\d+)?)\b');
    final matches = regex.allMatches(text);
    if (matches.isNotEmpty) {
      // Return the first numeric value found that looks like a price
      final match = matches.first;
      return double.tryParse(match.group(1) ?? match.group(2) ?? '0') ?? 0.0;
    }
    return 0.0;
  }

  @override
  Future<List<StockData>> build() async {
    final briefing = await ref.watch(briefingRepositoryProvider.future);
    final config = await ref.watch(briefingConfigRepositoryProvider.future);
    
    final List<StockData> stocks = [];
    final random = Random();
    final seen = <String>{};
    
    // Check if it's the weekend or Monday morning before market open (9:30 AM ET / 14:30 UTC)
    final now = DateTime.now().toUtc();
    bool isMarketClosed = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    
    if (now.weekday == DateTime.monday && (now.hour < 14 || (now.hour == 14 && now.minute < 30))) {
      isMarketClosed = true;
    }

    // 1. First, process items found in the briefing
    for (final category in briefing.data.values) {
      for (final item in category.items) {
        if (item.ticker != null) {
          final ticker = item.ticker!.toUpperCase();
          if (seen.contains(ticker)) continue;

          // Try to get price from direct field, then fallback to extracting from analysis text
          double initialPrice = double.tryParse(item.price?.replaceAll(RegExp(r'[^\d.]'), '') ?? '0') ?? 0.0;
          if (initialPrice == 0) {
            initialPrice = _extractPrice(item.potentialPriceAction);
            if (initialPrice == 0) initialPrice = _extractPrice(item.explanation);
            if (initialPrice == 0) initialPrice = _extractPrice(item.analysis?.toString());
          }

          final double change = double.tryParse(item.change?.replaceAll(RegExp(r'[^\d.+-]'), '') ?? '0') ?? 0.0;
          
          final double sentiment = item.sentimentScore ?? 
              (() {
                final s = item.sentiment;
                if (s is num) return s.toDouble();
                if (s is String) {
                  final lowerS = s.toLowerCase();
                  final parsed = double.tryParse(s);
                  if (parsed != null) return parsed;
                  if (lowerS.contains('very bullish') || lowerS.contains('strong buy')) return 0.9;
                  if (lowerS.contains('bullish') || lowerS.contains('buy')) return 0.7;
                  if (lowerS.contains('neutral') || lowerS.contains('hold')) return 0.0;
                  if (lowerS.contains('bearish') || lowerS.contains('sell')) return -0.7;
                  if (lowerS.contains('very bearish') || lowerS.contains('strong sell')) return -0.9;
                }
                return 0.0;
              })();
          
          final List<double> history = item.history ?? _generateHistory(initialPrice > 0 ? initialPrice : 100.0, change, sentiment, random, isMarketClosed);
          final double price = initialPrice > 0 ? initialPrice : (history.isNotEmpty ? history.last : 100.0);

          stocks.add(StockData(
            ticker: ticker,
            name: item.name ?? ticker,
            currentPrice: price,
            changePercent: change,
            history: history,
            sentiment: sentiment,
            analysis: item.analysis is String ? item.analysis : (item.analysis is Map ? item.takeaway : null),
            catalysts: item.catalysts,
            risks: item.risks,
            potentialPriceAction: item.potentialPriceAction,
          ));
          seen.add(ticker);
        }
      }
    }
    
    // 2. Add remaining tickers from the watchlist that weren't in the briefing
    for (final ticker in config.tickers) {
      final upperTicker = ticker.toUpperCase();
      if (!seen.contains(upperTicker)) {
        final double price = 100.0; // Default placeholder
        final List<double> history = _generateHistory(price, 0.0, 0.0, random, isMarketClosed);
        
        stocks.add(StockData(
          ticker: upperTicker,
          name: upperTicker,
          currentPrice: price,
          changePercent: 0.0,
          history: history,
          sentiment: 0.0,
        ));
        seen.add(upperTicker);
      }
    }

    return stocks;
  }

  List<double> _generateHistory(double currentPrice, double changePercent, double sentiment, Random random, bool isWeekend) {
    // If price is missing, we can't generate a meaningful chart
    if (currentPrice <= 0) return List.filled(15, 10.0); // Minimal baseline
    
    final List<double> points = [];
    double lastVal = currentPrice;
    
    // We go backwards from the "current" price (which on weekends is the Friday close)
    points.add(currentPrice);
    
    // If change is 0, we add a tiny bit of "noise" so it's not a perfectly flat line
    final effectiveChange = changePercent == 0 ? (random.nextDouble() - 0.5) * 0.5 : changePercent;

    for (int i = 0; i < 14; i++) {
      // Volatility based on current price
      final volatility = currentPrice * 0.012; 
      
      // Bias: if the day was very positive (large change), the price likely trended up
      // So going backwards, it should trend down.
      final bias = (effectiveChange / 100) * (currentPrice / 10);
      
      // Add randomness + sentiment influence + trend bias
      final noise = (random.nextDouble() - 0.5) * volatility;
      final sentimentInfluence = sentiment * (currentPrice * 0.002);
      
      lastVal = lastVal - bias + noise - sentimentInfluence;
      
      // Floor it to 70% of current price to avoid deep dives
      if (lastVal < currentPrice * 0.7) lastVal = currentPrice * 0.7 + (random.nextDouble() * 5);
      
      points.insert(0, lastVal);
    }
    
    return points;
  }
}
