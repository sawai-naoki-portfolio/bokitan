import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifier/Material3Notifier.dart';

/// Material 3 の利用状態を管理するシンプルなプロバイダー
final useMaterial3Provider = StateNotifierProvider<Material3Notifier, bool>(
  (ref) => Material3Notifier(),
);
