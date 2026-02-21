import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watchlist_provider.g.dart';

@riverpod
class Watchlist extends _$Watchlist {
  @override
  Set<String> build() {
    // Initial tickers from your backend examples
    return {'MU', 'NVDA', 'INTC', 'TSMC'};
  }

  void add(String ticker) {
    state = {...state, ticker.toUpperCase()};
  }

  void remove(String ticker) {
    state = {...state}..remove(ticker.toUpperCase());
  }

  bool contains(String ticker) => state.contains(ticker.toUpperCase());
}

@riverpod
class FollowedTopics extends _$FollowedTopics {
  @override
  Set<String> build() {
    return {'Semiconductors', 'Geopolitics', 'Sovereign AI'};
  }

  void toggle(String topic) {
    if (state.contains(topic)) {
      state = {...state}..remove(topic);
    } else {
      state = {...state, topic};
    }
  }
}
