// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(StockSearch)
final stockSearchProvider = StockSearchProvider._();

final class StockSearchProvider
    extends $AsyncNotifierProvider<StockSearch, List<TickerSearchResult>> {
  StockSearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stockSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stockSearchHash();

  @$internal
  @override
  StockSearch create() => StockSearch();
}

String _$stockSearchHash() => r'19b26aa286b5986e2e030122a50d226054ea108c';

abstract class _$StockSearch extends $AsyncNotifier<List<TickerSearchResult>> {
  FutureOr<List<TickerSearchResult>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<TickerSearchResult>>,
              List<TickerSearchResult>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<TickerSearchResult>>,
                List<TickerSearchResult>
              >,
              AsyncValue<List<TickerSearchResult>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
