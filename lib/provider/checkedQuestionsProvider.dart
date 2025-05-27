import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifier/CheckedQuestionsNotifier.dart';

/// Providerを通じて、アプリ内でチェックされた単語の状態を共有します。
final checkedQuestionsProvider =
    StateNotifierProvider<CheckedQuestionsNotifier, Set<String>>(
        (ref) => CheckedQuestionsNotifier());
