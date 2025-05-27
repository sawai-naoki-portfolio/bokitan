import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifier/SearchHistoryNotifier.dart';

final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, List<String>>(
        (ref) => SearchHistoryNotifier());
