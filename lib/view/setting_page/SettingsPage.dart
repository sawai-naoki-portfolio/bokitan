// 設定画面（SettingsPage）実装例
import 'package:bookkeeping_vocabulary_notebook/utility/ResponsiveSizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../WordListPage.dart';
import '../test_page/siwake_test/JournalEntryQuizWidget.dart';
import 'CacheClearScreen.dart';
import 'FeedbackPage.dart';
import 'MemoListPage.dart';
import 'PrivacyPolicy.dart';
import 'SearchHistoryPage.dart';
import 'ThemeSettingsPage.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // 全般セクション
          Padding(
            padding: EdgeInsets.all(context.paddingMedium),
            child: Text(
              "全般",
              style: TextStyle(
                fontSize: context.fontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text("テーマの変更"),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              // テーマ変更用の画面に遷移
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ThemeSettingsPage()),
              );
            },
          ),

          // ListTile(
          //   leading: const Icon(Icons.notifications),
          //   title: const Text("通知"),
          //   trailing: Switch(
          //     value: true, // これはプレースホルダです。通知の有効／無効管理ロジックを追加してください。
          //     onChanged: (value) {
          //       // 通知設定のトグル処理をここに実装
          //     },
          //   ),
          // ),
          // SettingsPage 内のキャッシュクリア項目
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text("キャッシュクリア"),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CacheClearScreen()),
              );
            },
          ),

          const Divider(),

          // 単語検索画面セクション
          Padding(
            padding: EdgeInsets.all(context.paddingMedium),
            child: Text(
              "単語検索",
              style: TextStyle(
                fontSize: context.fontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text("検索履歴"),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchHistoryPage()),
              );
            },
          ),
          const Divider(),

          // メモセクション
          Padding(
            padding: EdgeInsets.all(context.paddingMedium),
            child: Text(
              "メモ一覧・単語一覧",
              style: TextStyle(
                fontSize: context.fontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.note),
            title: const Text("メモ一覧"),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MemoListPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text("単語一覧"),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WordListPage()),
              );
            },
          ),

          const Divider(),
          // メモセクション
          Padding(
            padding: EdgeInsets.all(context.paddingMedium),
            child: Text(
              "仕訳問題設定",
              style: TextStyle(
                fontSize: context.fontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text("仕訳問題"),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const JournalQuizSettingsPage()),
              );
            },
          ),

          const Divider(),
          // セキュリティとプライバシーポリシーセクション
          Padding(
            padding: EdgeInsets.all(context.paddingMedium),
            child: Text(
              "セキュリティとプライバシーポリシー",
              style: TextStyle(
                fontSize: context.fontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text("プライバシーポリシー"),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicy()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text("フィードバック"),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FeedbackPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class JournalQuizSettingsPage extends ConsumerWidget {
  const JournalQuizSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(journalQuizFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("仕訳問題設定"),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          CheckboxListTile(
            title: const Text("簿記3級-商業簿記"),
            value: filters.contains("簿記3級-商業簿記"),
            onChanged: (val) {
              ref
                  .read(journalQuizFilterProvider.notifier)
                  .toggleFilter("簿記3級-商業簿記", val ?? false);
            },
          ),
          CheckboxListTile(
            title: const Text("簿記2級-商業簿記"),
            value: filters.contains("簿記2級-商業簿記"),
            onChanged: (val) {
              ref
                  .read(journalQuizFilterProvider.notifier)
                  .toggleFilter("簿記2級-商業簿記", val ?? false);
            },
          ),
          CheckboxListTile(
            title: const Text("簿記2級-工業簿記"),
            value: filters.contains("簿記2級-工業簿記"),
            onChanged: (val) {
              ref
                  .read(journalQuizFilterProvider.notifier)
                  .toggleFilter("簿記2級-工業簿記", val ?? false);
            },
          ),
        ],
      ),
    );
  }
}
