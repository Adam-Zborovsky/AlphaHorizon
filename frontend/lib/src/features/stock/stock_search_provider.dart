import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/api/api_config.dart';
import '../auth/auth_repository.dart';

part 'stock_search_provider.g.dart';

class TickerSearchResult {
  final String symbol;
  final String name;
  final String? exchange;
  final String? type;

  TickerSearchResult({
    required this.symbol,
    required this.name,
    this.exchange,
    this.type,
  });

  factory TickerSearchResult.fromJson(Map<String, dynamic> json) {
    return TickerSearchResult(
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      exchange: json['exch'],
      type: json['type'],
    );
  }
}

@riverpod
class StockSearch extends _$StockSearch {
  @override
  FutureOr<List<TickerSearchResult>> build() => [];

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = const AsyncData([]);
      return;
    }

    state = const AsyncLoading();
    
    try {
      final token = await ref.read(authRepositoryProvider).getToken();
      if (token == null) {
        state = AsyncError('No authentication token', StackTrace.current);
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.briefingSearchEndpoint}?q=$query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        state = AsyncData(data.map((json) => TickerSearchResult.fromJson(json)).toList());
      } else {
        state = AsyncError('Failed to search tickers: ${response.statusCode}', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
