// プロバイダー定義：アプリ全体でミス回数の状態を共有するための Provider
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifier/MistakeCountNotifier.dart';

final mistakeCountsProvider =
    StateNotifierProvider<MistakeCountNotifier, Map<String, int>>(
  (ref) => MistakeCountNotifier(),
);
