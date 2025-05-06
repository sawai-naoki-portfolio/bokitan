import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuizFilterSettings {
  final bool includeIndustrial; // 工業簿記を含むか
  final bool includeCommercial; // 商業簿記を含むか

  QuizFilterSettings({
    required this.includeIndustrial,
    required this.includeCommercial,
  });
}

final quizFilterSettingsProvider = StateProvider<QuizFilterSettings>(
  (ref) => QuizFilterSettings(includeIndustrial: true, includeCommercial: true),
);
