import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/settings/load_quiz_filter_settings.dart';
import '../utils/settings/save_quiz_filter_settings.dart';
import '../view_models/quiz_filter_settings.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<QuizFilterSettings> _loadSettings() async {
    return await loadQuizFilterSettings();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<QuizFilterSettings>(
      future: _loadSettings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text("設定")),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final settings = snapshot.data!;
        // 状態の更新を Future.microtask で延期する
        Future.microtask(() {
          ref.read(quizFilterSettingsProvider.notifier).state = settings;
        });
        return Scaffold(
          appBar: AppBar(title: const Text("設定")),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SettingsForm(
              initialIndustrial: settings.includeIndustrial,
              initialCommercial: settings.includeCommercial,
            ),
          ),
        );
      },
    );
  }
}

class SettingsForm extends ConsumerStatefulWidget {
  final bool initialIndustrial;
  final bool initialCommercial;

  const SettingsForm({
    super.key,
    required this.initialIndustrial,
    required this.initialCommercial,
  });

  @override
  ConsumerState<SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<SettingsForm> {
  late bool _includeIndustrial;
  late bool _includeCommercial;

  @override
  void initState() {
    super.initState();
    _includeIndustrial = widget.initialIndustrial;
    _includeCommercial = widget.initialCommercial;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "仕訳問題クイズの出題タイプを選択してください",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        CheckboxListTile(
          title: const Text("商業簿記"),
          value: _includeCommercial,
          onChanged: (val) {
            setState(() {
              _includeCommercial = val ?? false;
            });
          },
        ),
        CheckboxListTile(
          title: const Text("工業簿記"),
          value: _includeIndustrial,
          onChanged: (val) {
            setState(() {
              _includeIndustrial = val ?? false;
            });
          },
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            // 新たな設定を作成し、プロバイダーと SharedPreferences へ保存する
            final newSettings = QuizFilterSettings(
              includeIndustrial: _includeIndustrial,
              includeCommercial: _includeCommercial,
            );
            ref.read(quizFilterSettingsProvider.notifier).state = newSettings;
            await saveQuizFilterSettings(newSettings);
            Navigator.pop(context);
          },
          child: const Text("保存"),
        ),
      ],
    );
  }
}
