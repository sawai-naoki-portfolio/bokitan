import 'package:bookkeeping_vocabulary_notebook/utility/ResponsiveSizes.dart';
import 'package:bookkeeping_vocabulary_notebook/view/widget/showCategoryCreationDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/categoriesProvider.dart';
import '../../utility/Category.dart';
import '../../utility/SwipeToDeleteCard.dart';
import 'CategoryItemsPage.dart';

//////////////////////////////////////////////
// CategorySelectionPage
//////////////////////////////////////////////
// 登録済みのリスト一覧を表示する画面です。
// ユーザーはリストごとに保存された単語のリストを見るため、
// 各リストカードをタップして CategoryItemsPage へ遷移できます。
class CategorySelectionPage extends ConsumerStatefulWidget {
  const CategorySelectionPage({super.key});

  @override
  CategorySelectionPageState createState() => CategorySelectionPageState();
}

// ============================================================================
// CategorySelectionPageState
// -----------------------------------------------------------------------------
// この状態クラスは「リスト一覧画面」内で表示するリストのリストを管理します。
// ・通常表示モードでは、各リストをリスト表示し、スワイプで削除や長押しでオプションを起動します。
// ・並び替えモードでは、ドラッグ＆ドロップでリストの順序を変更できるようにします。
// ============================================================================
class CategorySelectionPageState extends ConsumerState<CategorySelectionPage> {
  /// 並び替えモードかどうかを示すフラグ（trueならドラッグ＆ドロップで順序変更可能）
  bool _isReordering = false;

  @override
  Widget build(BuildContext context) {
    // プロバイダーから現在のリスト一覧を取得
    final categories = ref.watch(categoriesProvider);
    Widget listWidget;

    if (_isReordering) {
      // 【並び替えモード】：ReorderableListView を利用してドラッグ＆ドロップ操作を可能にする
      listWidget = ReorderableListView.builder(
        padding: EdgeInsets.symmetric(vertical: context.paddingMedium),
        itemCount: categories.length,
        onReorder: (oldIndex, newIndex) async {
          // ドラッグ操作後、リストの新しい順序を更新する
          if (newIndex > oldIndex) newIndex--;
          await ref
              .read(categoriesProvider.notifier)
              .reorderCategories(oldIndex, newIndex);
        },
        itemBuilder: (context, index) {
          final cat = categories[index];
          return ListTile(
            key: ValueKey(cat.name),
            leading: ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
            title: Text(cat.name),
            subtitle: Text("登録済み単語数: ${cat.products.length}"),
            onTap: () {
              // タップすると、該当リストの詳細（リストに属する単語一覧）画面へ遷移
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryItemsPage(category: cat),
                ),
              );
            },
          );
        },
      );
    } else {
      // 【通常モード】：ListView でリスト一覧を表示し、各リスト項目にスワイプ／タップ／長押し操作を埋め込む
      listWidget = ListView.builder(
        padding: EdgeInsets.symmetric(vertical: context.paddingMedium),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return SwipeToDeleteCard(
            keyValue: ValueKey(cat.name),
            // スワイプしたときに削除確認ダイアログを表示
            onConfirm: () async {
              return await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("削除確認"),
                      content: Text("リスト『${cat.name}』を削除してよろしいですか？"),
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
                  ) ??
                  false;
            },
            // スワイプ後にリストを削除する
            onDismissed: () async {
              await ref
                  .read(categoriesProvider.notifier)
                  .deleteCategory(cat.name);
            },
            child: ListTile(
              title: Text(cat.name),
              subtitle: Text("登録済み単語数: ${cat.products.length}"),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                // タップでリスト内の単語一覧へ遷移
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryItemsPage(category: cat),
                  ),
                );
              },
              // 長押しでリストの操作（リネーム、削除、並び替え）モーダルを表示
              onLongPress: () {
                _showCategoryOptions(cat);
              },
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("マイリスト"),
        centerTitle: true,
        actions: [
          // 並び替えモード中は「完了」ボタンを表示して通常モードへ戻す
          if (_isReordering)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                setState(() {
                  _isReordering = false;
                });
              },
            ),
        ],
      ),
      body: listWidget,
      // FloatingActionButton：新規リストを追加するためのダイアログを起動
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          String? newCat = await showCategoryCreationDialog(context);
          if (newCat != null && newCat.isNotEmpty) {
            await ref.read(categoriesProvider.notifier).addCategory(newCat);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// リスト長押し時に表示するオプションメニュー（リネーム／削除／並び替え）の表示処理
  void _showCategoryOptions(Category cat) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              // リネームオプション
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("リスト名の変更"),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameCategoryDialog(cat);
                },
              ),
              // リスト削除オプション
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text("リスト削除"),
                onTap: () async {
                  Navigator.pop(context);
                  bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("リスト削除"),
                      content: Text("リスト『${cat.name}』を削除してよろしいですか？"),
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
                    await ref
                        .read(categoriesProvider.notifier)
                        .deleteCategory(cat.name);
                  }
                },
              ),
              // 並び替えモードへの移行オプション
              ListTile(
                leading: const Icon(Icons.sort),
                title: const Text("並び替え"),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _isReordering = true;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// リスト名の変更用ダイアログを表示し、入力された新しい名前で更新する処理
  void _showRenameCategoryDialog(Category cat) {
    final TextEditingController controller =
        TextEditingController(text: cat.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("リスト名の変更"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "新しいリスト名"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("キャンセル"),
            ),
            ElevatedButton(
              onPressed: () async {
                String newName = controller.text.trim();
                if (newName.isNotEmpty && newName != cat.name) {
                  await ref
                      .read(categoriesProvider.notifier)
                      .updateCategory(cat.name, newName);
                }
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text("変更"),
            ),
          ],
        );
      },
    );
  }
}
