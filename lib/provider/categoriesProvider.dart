import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifier/CategoriesNotifier.dart';
import '../utility/Category.dart';

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, List<Category>>(
        (ref) => CategoriesNotifier());
