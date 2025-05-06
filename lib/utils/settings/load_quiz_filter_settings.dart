import 'package:shared_preferences/shared_preferences.dart';

import '../../view_models/quiz_filter_settings.dart';

Future<QuizFilterSettings> loadQuizFilterSettings() async {
  final prefs = await SharedPreferences.getInstance();
  bool includeIndustrial = prefs.getBool("quiz_include_industrial") ?? true;
  bool includeCommercial = prefs.getBool("quiz_include_commercial") ?? true;
  return QuizFilterSettings(
    includeIndustrial: includeIndustrial,
    includeCommercial: includeCommercial,
  );
}
