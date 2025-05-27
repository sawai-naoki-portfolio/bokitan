import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifier/CustomProductsNotifier.dart';
import '../utility/Product.dart';

/// プロバイダー定義：ユーザーが追加したカスタム単語を管理する
final customProductsProvider =
    StateNotifierProvider<CustomProductsNotifier, List<Product>>(
        (ref) => CustomProductsNotifier());
