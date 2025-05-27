import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifier/SavedItemsNotifier.dart';

final savedItemsProvider =
    StateNotifierProvider<SavedItemsNotifier, List<String>>(
  (ref) => SavedItemsNotifier(),
);
