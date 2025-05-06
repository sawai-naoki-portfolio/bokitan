import 'package:shared_preferences/shared_preferences.dart';

import '../../view_models/quiz_filter_settings.dart';

Future<void> saveQuizFilterSettings(QuizFilterSettings settings) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool("quiz_include_industrial", settings.includeIndustrial);
  await prefs.setBool("quiz_include_commercial", settings.includeCommercial);
}
