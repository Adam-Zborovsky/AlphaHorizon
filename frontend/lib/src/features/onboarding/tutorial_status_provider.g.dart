// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tutorial_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TutorialStatus)
final tutorialStatusProvider = TutorialStatusProvider._();

final class TutorialStatusProvider
    extends $NotifierProvider<TutorialStatus, bool> {
  TutorialStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tutorialStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tutorialStatusHash();

  @$internal
  @override
  TutorialStatus create() => TutorialStatus();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$tutorialStatusHash() => r'4d97e60b028d634cb10749ba71ead7b655dfbeb0';

abstract class _$TutorialStatus extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
