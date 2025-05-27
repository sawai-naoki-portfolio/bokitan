import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 非表示にした単語の名前を保持する Provider
final hiddenSavedProvider = StateProvider<Set<String>>((ref) => {});
