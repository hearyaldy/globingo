import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppMode { learning, teaching }

class ModeNotifier extends StateNotifier<AppMode> {
  ModeNotifier() : super(AppMode.learning);

  void toggleMode() {
    state = state == AppMode.learning ? AppMode.teaching : AppMode.learning;
  }

  void setMode(AppMode mode) {
    state = mode;
  }

  bool get isLearningMode => state == AppMode.learning;
  bool get isTeachingMode => state == AppMode.teaching;
}

final modeProvider = StateNotifierProvider<ModeNotifier, AppMode>((ref) {
  return ModeNotifier();
});
