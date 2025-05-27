// *****************************************************************************
// Flutter アプリ全体で利用するユーティリティやウィジェット、プロバイダーの定義
// *****************************************************************************

import 'dart:ui';

import 'package:bookkeeping_vocabulary_notebook/provider/themeProvider.dart';
import 'package:bookkeeping_vocabulary_notebook/provider/useMaterial3Provider.dart';
import 'package:bookkeeping_vocabulary_notebook/view/SearchPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

/// ---------------------------------------------------------------------------
/// アプリエントリーポイント：main() と MyApp
/// ─────────────────────────────────────────────────────────
/// Flutterの初期化とRiverpodのProviderScopeでアプリ全体をラップし、
/// MyAppウィジェットを起動します。
/// ---------------------------------------------------------------------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    Phoenix(
      child: const ProviderScope(
        child: MyApp(),
      ),
    ),
  );
}

/// [MyApp]
/// ─────────────────────────────────────────────────────────
/// アプリ全体のテーマ設定やホーム画面(SearchPage)を設定するルートウィジェットです。
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final useMaterial3 = ref.watch(useMaterial3Provider);
    return MaterialApp(
      title: '単語検索＆保存アプリ',
      theme: ThemeData(
        fontFamily: 'Murecho',
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        useMaterial3: useMaterial3,
      ),
      darkTheme: ThemeData(
        fontFamily: 'Murecho',
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        useMaterial3: useMaterial3,
      ),
      themeMode: themeMode,
      home: const SearchPage(),
    );
  }
}
