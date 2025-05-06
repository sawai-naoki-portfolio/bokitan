import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/category.dart';
import '../../utils/show_category_creation_dialog.dart';
import '../../view_models/categories_view_model.dart';
import 'category_items_page.dart';

class CategorySelectionPage extends ConsumerStatefulWidget {
  const CategorySelectionPage({super.key});

  @override
  CategorySelectionPageState createState() => CategorySelectionPageState();
}

class CategorySelectionPageState extends ConsumerState<CategorySelectionPage> {
  bool _isReordering = false;

  // 長押し時に表示するアクションシート
  void _showCategoryActionSheet(Category category) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text("削除"),
                onTap: () async {
                  Navigator.pop(context);
                  // 削除確認ダイアログを表示
                  bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("カテゴリー削除"),
                      content: Text("カテゴリー『${category.name}』を削除してよろしいですか？"),
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
                        .deleteCategory(category.name);
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

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);

    Widget listWidget;
    if (_isReordering) {
      // 並び替えモード：ReorderableListView.builder を利用
      listWidget = ReorderableListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
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
              // ここで index を正しく渡す
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
            title: Text(cat.name),
            subtitle: Text("登録済み単語数: ${cat.products.length}"),
            onTap: () {
              // CategoryItemsPageへ遷移
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CategoryItemsPage(category: cat)),
              );
            },
          );
        },
      );
    } else {
      // 通常モード：ListView.builder で各カテゴリーを表示
      listWidget = ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return GestureDetector(
            onLongPress: () => _showCategoryActionSheet(cat),
            child: ListTile(
              key: ValueKey(cat.name),
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
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("カテゴリーリスト"),
        centerTitle: true,
        actions: [
          // 並び替えモードの場合、完了ボタンを表示して通常モードに戻す
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
}
