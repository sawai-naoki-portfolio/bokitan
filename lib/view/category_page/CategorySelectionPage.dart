import 'package:bookkeeping_vocabulary_notebook/utility/ResponsiveSizes.dart';
import 'package:bookkeeping_vocabulary_notebook/view/widget/showCategoryCreationDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/categoriesProvider.dart';
import '../../utility/Category.dart';
import '../../utility/SwipeToDeleteCard.dart';
import '../SavedItemsPage.dart';
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
  bool _isReordering = false;

  @override
  Widget build(BuildContext context) {
    // プロバイダーから現在のリスト一覧を取得
    final categories = ref.watch(categoriesProvider);

    // 固定の「保存単語一覧」タイル（デフォルト表示）
    final Widget defaultSavedItemsTile = ListTile(
      key: const ValueKey("saved_items_default"),
      leading: const Icon(Icons.bookmark),
      title: const Text("保存単語一覧"),
      subtitle: const Text("保存された単語を表示します"),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SavedItemsPage()),
        );
      },
    );

    Widget listWidget;
    if (_isReordering) {
      // 並び替えモードの場合、固定のタイルはリスト上部に固定表示し、
      // 以降のユーザー登録リストはReorderableListViewで管理する
      listWidget = Column(
        children: [
          defaultSavedItemsTile,
          Expanded(
            child: ReorderableListView.builder(
              padding: EdgeInsets.symmetric(vertical: context.paddingMedium),
              itemCount: categories.length,
              onReorder: (oldIndex, newIndex) async {
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CategoryItemsPage(category: cat)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    } else {
      // 通常モードの場合：固定の「保存単語一覧」タイルの後にリスト表示する
      listWidget = ListView(
        padding: EdgeInsets.symmetric(vertical: context.paddingMedium),
        children: [
          defaultSavedItemsTile,
          const Divider(),
          ...categories
              .map((cat) => SwipeToDeleteCard(
                    keyValue: ValueKey(cat.name),
                    onConfirm: () async {
                      return await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("削除確認"),
                              content: Text("リスト『${cat.name}』を削除してよろしいですか？"),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CategoryItemsPage(category: cat)),
                        );
                      },
                      onLongPress: () {
                        _showCategoryOptions(cat);
                      },
                    ),
                  ))
              .toList(),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("リストリスト"),
        centerTitle: true,
        actions: [
          if (_isReordering)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                setState(() {
                  _isReordering = false;
                });
              },
            )
        ],
      ),
      body: listWidget,
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

  // ※既存の _showCategoryOptions(cat) メソッドはそのまま利用
  void _showCategoryOptions(Category cat) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("リスト名の変更"),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameCategoryDialog(cat);
                },
              ),
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
