import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 検索クエリの状態を管理するProvider
final searchQueryProvider = StateProvider<String>((ref) => '');
