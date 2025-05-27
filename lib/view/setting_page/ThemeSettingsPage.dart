import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/themeProvider.dart';
import '../../provider/useMaterial3Provider.dart';

class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    // Material3 の状態は新しいプロバイダーから読み込む
    final useMaterial3 = ref.watch(useMaterial3Provider);

    return Scaffold(
      appBar: AppBar(title: const Text("テーマの変更")),
      body: ListView(
        children: [
          RadioListTile<ThemeMode>(
            title: const Text("システム"),
            value: ThemeMode.system,
            groupValue: currentTheme,
            onChanged: (ThemeMode? value) {
              if (value != null) {
                ref.read(themeProvider.notifier).setTheme(value);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text("ライト"),
            value: ThemeMode.light,
            groupValue: currentTheme,
            onChanged: (ThemeMode? value) {
              if (value != null) {
                ref.read(themeProvider.notifier).setTheme(value);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text("ダーク"),
            value: ThemeMode.dark,
            groupValue: currentTheme,
            onChanged: (ThemeMode? value) {
              if (value != null) {
                ref.read(themeProvider.notifier).setTheme(value);
              }
            },
          ),
          const Divider(),
          // Material 3 のON/OFFスイッチ
          SwitchListTile(
            title: const Text("Material 3 の利用"),
            value: useMaterial3,
            onChanged: (value) {
              ref.read(useMaterial3Provider.notifier).setMaterial3(value);
            },
          ),
        ],
      ),
    );
  }
}
