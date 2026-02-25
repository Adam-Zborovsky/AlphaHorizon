import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tutorial_status_provider.g.dart';

@riverpod
class TutorialStatus extends _$TutorialStatus {
  @override
  bool build() => false;

  void show() => state = true;
  void hide() => state = false;
}
