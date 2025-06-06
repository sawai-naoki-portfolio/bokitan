import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheClearScreen extends StatefulWidget {
  const CacheClearScreen({super.key});

  @override
  CacheClearScreenState createState() => CacheClearScreenState();
}

class CacheClearScreenState extends State<CacheClearScreen> {
  // キャッシュ削除対象のキーと初期選択状態
  // 'memo_list' は「メモ一覧」に対応し、削除時は "memo_" で始まるキーをすべて削除します。
  final Map<String, bool> _selected = {
    'search_history': false,
    'mistake_counts': false,
    'saved_categories': false,
    'saved_items': false,
    'memo_list': false,
  };

  // 各キーの表示用ラベル
  final Map<String, String> _labels = {
    'search_history': '検索履歴',
    'mistake_counts': 'ミス回数',
    'saved_categories': 'リスト',
    'saved_items': '保存単語',
    'memo_list': 'メモ一覧',
  };

  // 「すべて削除」チェックボックスの状態
  bool _allSelected = false;

  /// 「すべて削除」チェックボックスの更新処理
  void _toggleAll(bool? val) {
    setState(() {
      _allSelected = val ?? false;
      _selected.updateAll((key, value) => _allSelected);
    });
  }

  /// 個別チェックボックス更新時の処理
  void _toggleItem(String key, bool? val) {
    setState(() {
      _selected[key] = val ?? false;
      // すべてが true なら _allSelected を true、1つでも false があれば false に
      _allSelected = !_selected.values.contains(false);
    });
  }

  /// 削除確認ダイアログ後、選択対象のキャッシュキーを削除して再起動
  Future<void> _clearCache() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("確認"),
        content: const Text("削除してよろしいですか？"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("キャンセル"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("削除"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      for (var entry in _selected.entries) {
        if (entry.value) {
          if (entry.key == 'memo_list') {
            // 「メモ一覧」を選択した場合は、"memo_" で始まるすべてのキーを削除
            for (final k in prefs.getKeys()) {
              if (k.startsWith("memo_")) {
                await prefs.remove(k);
              }
            }
          } else {
            await prefs.remove(entry.key);
          }
        }
      }
      // 削除完了後、わかりやすいUI の再起動メッセージ画面を表示
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          // 複数のウィジェットを縦に並べたUI
          Future.delayed(const Duration(milliseconds: 500), () {
            Phoenix.rebirth(context);
          });
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'キャッシュがクリアされました。',
                  style: TextStyle(fontSize: 18),
                ),
                Text(
                  '再起動します。',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 16),
                CircularProgressIndicator(),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("キャッシュクリア"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 「すべて削除」チェックボックス
            CheckboxListTile(
              title: const Text("すべて削除", style: TextStyle(fontSize: 14)),
              value: _allSelected,
              onChanged: _toggleAll,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            // 個別のチェック項目 (リスト形式)
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: _selected.keys.map((key) {
                  return CheckboxListTile(
                    title: Text(_labels[key] ?? key,
                        style: const TextStyle(fontSize: 14)),
                    value: _selected[key],
                    onChanged: (val) => _toggleItem(key, val),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            // 「削除」ボタンでキャッシュ削除処理を実行
            ElevatedButton(
              onPressed: _clearCache,
              child: const Text("削除"),
            )
          ],
        ),
      ),
    );
  }
}
