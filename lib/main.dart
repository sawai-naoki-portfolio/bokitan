// *****************************************************************************
// Flutter アプリ全体で利用するユーティリティやウィジェット、プロバイダーの定義
// *****************************************************************************

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:math_expressions/math_expressions.dart';

/// ---------------------------------------------------------------------------
/// BuildContext の拡張: 各種サイズ（パディング、アイコン、フォントサイズ等）を返す
/// ---------------------------------------------------------------------------
extension ResponsiveSizes on BuildContext {
  /// 現在の画面サイズ（幅×高さ）を返す
  Size get screenSize => MediaQuery.of(this).size;

  // 以下、画面サイズに応じた相対的なパディング値
  double get paddingExtraSmall => screenSize.width * 0.01;

  double get paddingSmall => screenSize.width * 0.02;

  double get paddingMedium => screenSize.width * 0.04;

  double get paddingLarge => screenSize.width * 0.06;

  double get paddingExtraLarge => screenSize.width * 0.08;

  // ボタンサイズ
  double get buttonHeight => screenSize.height * 0.07;

  double get buttonWidth => screenSize.width * 0.8;

  // アイコンサイズ
  double get iconSizeSmall => screenSize.width * 0.05;

  double get iconSizeMedium => screenSize.width * 0.07;

  double get iconSizeLarge => screenSize.width * 0.09;

  // テキストフィールド高さ
  double get textFieldHeight => screenSize.height * 0.06;

  // フォントサイズ
  double get fontSizeExtraSmall => screenSize.width * 0.03;

  double get fontSizeSmall => screenSize.width * 0.035;

  double get fontSizeMedium => screenSize.width * 0.04;

  double get fontSizeLarge => screenSize.width * 0.045;

  double get fontSizeExtraLarge => screenSize.width * 0.05;

  // SizedBox 用のスペースウィジェット（垂直方向）
  SizedBox get verticalSpaceExtraSmall =>
      SizedBox(height: screenSize.height * 0.01);

  SizedBox get verticalSpaceSmall => SizedBox(height: screenSize.height * 0.02);

  SizedBox get verticalSpaceMedium =>
      SizedBox(height: screenSize.height * 0.03);

  SizedBox get verticalSpaceLarge => SizedBox(height: screenSize.height * 0.05);

  // SizedBox 用のスペースウィジェット（水平方向）
  SizedBox get horizontalSpaceExtraSmall =>
      SizedBox(width: screenSize.width * 0.01);

  SizedBox get horizontalSpaceSmall => SizedBox(width: screenSize.width * 0.02);

  SizedBox get horizontalSpaceMedium =>
      SizedBox(width: screenSize.width * 0.03);

  SizedBox get horizontalSpaceLarge => SizedBox(width: screenSize.width * 0.05);

  // Divider 用のサイズ・太さ
  double get dividerHeightExtraSmall => screenSize.height * 0.01;

  double get dividerHeightSmall => screenSize.height * 0.015;

  double get dividerHeightMedium => screenSize.height * 0.02;

  double get dividerHeightLarge => screenSize.height * 0.025;

  double get dividerThickness => screenSize.width * 0.003;
}

/// ---------------------------------------------------------------------------
/// SwipeToDeleteCard
/// ─ このウィジェットはスワイプして削除するためのカードをラップします。
///   削除前に確認ダイアログを表示し、削除が確定されたときに onDismissed コールバックを呼び出します。
/// ---------------------------------------------------------------------------
class SwipeToDeleteCard extends StatelessWidget {
  final Widget child;
  final Key keyValue;
  final Future<bool> Function() onConfirm;
  final VoidCallback onDismissed;

  const SwipeToDeleteCard({
    super.key,
    required this.keyValue,
    required this.child,
    required this.onConfirm,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: keyValue,
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: context.paddingMedium),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      // 削除前に確認処理を行う
      confirmDismiss: (direction) async {
        return await onConfirm();
      },
      // 削除が決定した場合の処理
      onDismissed: (direction) {
        onDismissed();
      },
      child: child,
    );
  }
}

/// ---------------------------------------------------------------------------
/// ThousandsSeparatorInputFormatter
/// ─ この入力フォーマッターは、数字入力中に自動でカンマ区切りのフォーマットに変換します。
/// ---------------------------------------------------------------------------
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // 入力が空の場合はそのまま返す
    if (newValue.text.isEmpty) return newValue;

    // 数字以外 (カンマなど) を除去する
    String numericString = newValue.text.replaceAll(RegExp('[^0-9]'), '');
    if (numericString.isEmpty) return newValue;

    // 文字列を整数に変換し、フォーマット後の文字列を生成
    final int value = int.parse(numericString);
    final String newText = _formatter.format(value);

    // カーソルを常に末尾に設定
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

/// ---------------------------------------------------------------------------
/// loadMemo
/// ─ SharedPreferencesから指定されたProductに対応するメモを読み込む
/// ---------------------------------------------------------------------------
Future<String> loadMemo(Product product) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('memo_${product.name}') ?? "";
}

/// ---------------------------------------------------------------------------
/// showProductDialog
/// ─ 単語の詳細ダイアログを表示するウィジェット。
///   内部でStatefulBuilderを用いて、最新のメモ情報などの再描画を最小限の範囲で実施。
/// ---------------------------------------------------------------------------
void showProductDialog(BuildContext context, Product product) {
  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            // タイトル部に単語を大きく表示
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: context.fontSizeExtraLarge,
                    ),
                  ),
                ),
              ],
            ),
            // 内容部には単語説明と、その単語のメモを表示
            content: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.description),
                    context.verticalSpaceMedium,
                    MemoDisplay(product: product),
                  ],
                ),
              ),
            ),
            actions: [
              // メモ入力ダイアログを表示して、入力後に再描画
              TextButton(
                onPressed: () async {
                  await showMemoDialog(context, product);
                  setState(() {});
                },
                child: const Text("メモを書く"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  FocusScope.of(context).unfocus();
                },
                child: const Text("閉じる"),
              ),
            ],
          );
        },
      );
    },
  );
}

/// ---------------------------------------------------------------------------
/// MemoDisplay
/// ─ このウィジェットは、各Productに対応するメモ内容を表示します（非キャッシュ）。
/// ---------------------------------------------------------------------------
class MemoDisplay extends StatelessWidget {
  final Product product;

  const MemoDisplay({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      // 最低50pxの高さを確保
      constraints: const BoxConstraints(minHeight: 50),
      child: FutureBuilder<String>(
        future: loadMemo(product),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox();
          }
          if (snapshot.hasError) return const SizedBox();
          final memo = snapshot.data ?? "";
          if (memo.isNotEmpty) {
            return Text(
              "メモ: $memo",
              style: TextStyle(
                fontSize: context.fontSizeExtraSmall,
                color: Colors.grey,
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// showMemoDialog
/// ─ Productに対してユーザーがメモを書き込む入力ダイアログを表示する
/// ---------------------------------------------------------------------------
Future<void> showMemoDialog(BuildContext context, Product product) async {
  final prefs = await SharedPreferences.getInstance();
  final String initialMemo = prefs.getString('memo_${product.name}') ?? "";
  final controller = TextEditingController(text: initialMemo);

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("メモを書く"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "ここにメモを入力してください"),
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("キャンセル"),
          ),
          ElevatedButton(
            onPressed: () async {
              final memo = controller.text.trim();
              await prefs.setString('memo_${product.name}', memo);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("メモが保存されました")),
              );
            },
            child: const Text("保存"),
          ),
        ],
      );
    },
  );
}

/// ---------------------------------------------------------------------------
/// showCategoryCreationDialog
/// ─ 新規カテゴリーを作成するためのシンプルな入力ダイアログを表示する
/// ---------------------------------------------------------------------------
Future<String?> showCategoryCreationDialog(BuildContext context) async {
  String temp = "";
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("新規カテゴリーの作成"),
        content: TextField(
          onChanged: (value) => temp = value,
          decoration: const InputDecoration(hintText: "カテゴリー名"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("キャンセル"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, temp),
            child: const Text("作成"),
          ),
        ],
      );
    },
  );
}

/// ---------------------------------------------------------------------------
/// showCategoryDeleteDialog
/// ─ カテゴリー削除前の確認ダイアログを表示する
/// ---------------------------------------------------------------------------
Future<bool?> showCategoryDeleteDialog(
    BuildContext context, String categoryName) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("カテゴリーの削除"),
      content: Text("カテゴリー「$categoryName」を削除してよろしいですか？"),
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
}

/// ---------------------------------------------------------------------------
/// generateQuizQuestions
/// ─ quizPool（出題対象）と distractorPool（誤答候補）から、指定数のクイズ問題を生成する
/// ---------------------------------------------------------------------------
List<WordTestQuestion> generateQuizQuestions(
    List<Product> quizPool, List<Product> distractorPool,
    {int quizCount = 10}) {
  final random = Random();
  final quizProducts = (List<Product>.from(quizPool)..shuffle(random))
      .take(min(quizCount, quizPool.length))
      .toList();

  return quizProducts.map((product) {
    // distractorPoolから誤答候補を抽出
    List<String> distractors = distractorPool
        .where((p) => p.name != product.name)
        .map((p) => p.name)
        .toList();
    distractors.shuffle(random);

    // 正答と誤答候補を混ぜ、必ず4つの選択肢を用意
    List<String> options = [product.name];
    if (distractors.length >= 3) {
      options.addAll(distractors.take(3));
    } else {
      options.addAll(distractors);
      while (options.length < 4) {
        options.add("選択肢なし");
      }
    }
    options.shuffle(random);
    return WordTestQuestion(product: product, options: options);
  }).toList();
}

/// ---------------------------------------------------------------------------
/// WordTestQuestion
/// ─ 単語テストの各問題を管理するデータクラス
/// ---------------------------------------------------------------------------
class WordTestQuestion {
  final Product product;
  final List<String> options;
  String? userAnswer; // ユーザーが選んだ回答

  WordTestQuestion({required this.product, required this.options});

  bool get isCorrect => userAnswer == product.name;
}

/// ---------------------------------------------------------------------------
/// ProductCard
/// ─ 各単語の情報（名前、説明など）を表示するカードウィジェット
/// ---------------------------------------------------------------------------
class ProductCard extends StatelessWidget {
  final Product product;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsets margin;

  const ProductCard({
    super.key,
    required this.product,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.margin = const EdgeInsets.all(10.0),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        // 左側に円形アバター（先頭文字を表示）
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade300,
          child: Text(
            product.name.substring(0, 1),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          product.name,
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: context.fontSizeMedium),
        ),
        subtitle: Text(
          product.description,
          style: TextStyle(fontSize: context.fontSizeSmall),
        ),
        trailing: trailing,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Product クラス
/// ─ 単語（もしくは単語）のデータモデル。各単語は名前、読み仮名、説明、カテゴリーを保持します。
/// ---------------------------------------------------------------------------
class Product {
  final String name;
  final String yomigana;
  final String description;
  final String category;

  Product({
    required this.name,
    required this.yomigana,
    required this.description,
    required this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name'],
      yomigana: json['yomigana'] ?? "",
      description: json['description'],
      category: json['category'] ?? '未分類',
    );
  }
}

/// ---------------------------------------------------------------------------
/// productsProvider
/// ─ アセットのJSONファイルから単語リストを非同期で読み込むProvider
/// ---------------------------------------------------------------------------
final productsProvider = FutureProvider<List<Product>>((ref) async {
  final data = await rootBundle.loadString('assets/products.json');
  final jsonResult = jsonDecode(data) as List;
  return jsonResult.map((json) => Product.fromJson(json)).toList();
});

/// 検索クエリの状態を管理するProvider
final searchQueryProvider = StateProvider<String>((ref) => '');

/// ---------------------------------------------------------------------------
/// SavedItemsNotifier
/// ─ ユーザーが保存した単語の名前を管理し、SharedPreferences に保存する
/// ---------------------------------------------------------------------------
class SavedItemsNotifier extends StateNotifier<List<String>> {
  SavedItemsNotifier() : super([]) {
    _loadSavedItems();
  }

  Future<void> _loadSavedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_items') ?? [];
    state = saved;
  }

  Future<void> saveItem(String productName) async {
    if (!state.contains(productName)) {
      state = [...state, productName];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('saved_items', state);
    }
  }

  Future<void> removeItem(String productName) async {
    if (state.contains(productName)) {
      state = state.where((e) => e != productName).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('saved_items', state);
    }
  }

  Future<void> reorderItems(List<String> newOrder) async {
    state = newOrder;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_items', state);
  }
}

final savedItemsProvider =
    StateNotifierProvider<SavedItemsNotifier, List<String>>(
  (ref) => SavedItemsNotifier(),
);

/// 非表示にした単語の名前を保持する Provider
final hiddenSavedProvider = StateProvider<Set<String>>((ref) => {});

/// ---------------------------------------------------------------------------
/// Category クラス
/// ─ ユーザーが登録するカテゴリー。各カテゴリーは名前と所属する単語の名前リストを保持します。
/// ---------------------------------------------------------------------------
class Category {
  final String name;
  final List<String> products;

  Category({required this.name, List<String>? products})
      : products = products ?? [];

  Map<String, dynamic> toJson() => {
        'name': name,
        'products': products,
      };

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      name: json['name'] as String,
      products: List<String>.from(json['products'] as List),
    );
  }
}

/// ---------------------------------------------------------------------------
/// CategoriesNotifier
/// ─ カテゴリーの作成、更新、削除および単語の所属更新、並び替えを管理する
/// ---------------------------------------------------------------------------
class CategoriesNotifier extends StateNotifier<List<Category>> {
  CategoriesNotifier() : super([]) {
    _loadCategories();
  }

  Future<void> reorderProducts(
      String categoryName, int oldIndex, int newIndex) async {
    state = state.map((c) {
      if (c.name == categoryName) {
        List<String> newProducts = List.from(c.products);
        final item = newProducts.removeAt(oldIndex);
        newProducts.insert(newIndex, item);
        return Category(name: c.name, products: newProducts);
      }
      return c;
    }).toList();
    await _saveCategories();
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('saved_categories');
    if (data != null) {
      final List decoded = jsonDecode(data);
      state = decoded.map((e) => Category.fromJson(e)).toList();
    } else {
      state = [];
    }
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(state.map((c) => c.toJson()).toList());
    await prefs.setString('saved_categories', data);
  }

  Future<void> addCategory(String name) async {
    if (state.any((c) => c.name == name)) return;
    final newCategory = Category(name: name);
    state = [...state, newCategory];
    await _saveCategories();
  }

  Future<void> updateCategory(String oldName, String newName) async {
    state = state.map((c) {
      if (c.name == oldName) {
        return Category(name: newName, products: c.products);
      }
      return c;
    }).toList();
    await _saveCategories();
  }

  Future<void> deleteCategory(String name) async {
    state = state.where((c) => c.name != name).toList();
    await _saveCategories();
  }

  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    List<Category> updated = List.from(state);
    final Category item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    state = updated;
    await _saveCategories();
  }

  Future<void> updateProductAssignment(
      String categoryName, String productName, bool assigned) async {
    state = state.map((c) {
      if (c.name == categoryName) {
        List<String> updatedProducts = List.from(c.products);
        if (assigned) {
          if (!updatedProducts.contains(productName)) {
            updatedProducts.add(productName);
          }
        } else {
          updatedProducts.remove(productName);
        }
        return Category(name: c.name, products: updatedProducts);
      }
      return c;
    }).toList();
    await _saveCategories();
  }
}

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, List<Category>>(
        (ref) => CategoriesNotifier());

/// ---------------------------------------------------------------------------
/// CategoryItemWidget
/// ─────────────────────────────────────────────────────────
/// このウィジェットは、1件のカテゴリ内単語をリスト表示する際に利用します。
/// ・スワイプで削除（確認ダイアログ付き）
/// ・長押しで削除確認のダイアログを個別に表示
/// ・ドラッグ＆ドロップによる並び替えハンドルを提供
/// ---------------------------------------------------------------------------
class CategoryItemWidget extends ConsumerWidget {
  final Product product; // 表示する対象単語
  final int index; // リスト内のインデックス
  final Category currentCategory; // 現在のカテゴリ情報

  const CategoryItemWidget({
    super.key,
    required this.product,
    required this.index,
    required this.currentCategory,
  });

  /// [_deleteItem]
  /// ─────────────────────────────────────────────────────────
  /// 長押し時に呼び出される削除確認ダイアログを表示するメソッドです。
  /// ユーザーが削除を承認した場合、対象カテゴリからこの単語を除去します。
  Future<void> _deleteItem(BuildContext context, WidgetRef ref) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("削除確認"),
          content: Text("${product.name} を削除してよろしいですか？"),
          actions: [
            // キャンセルボタン：何もせず閉じる
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("キャンセル"),
            ),
            // 削除ボタン：削除処理を実行
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("削除"),
            ),
          ],
        );
      },
    );
    if (confirm == true) {
      await ref
          .read(categoriesProvider.notifier)
          .updateProductAssignment(currentCategory.name, product.name, false);
    }
  }

  /// [build]
  /// ─────────────────────────────────────────────────────────
  /// スワイプ（Dismissible）と長押し（GestureDetector）による操作が統合されたカード型ウィジェットを返します。
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(product.name),
      direction: DismissDirection.endToStart,
      // 右端から左端へのスワイプで削除
      confirmDismiss: (direction) async {
        // スワイプ時も削除確認ダイアログを表示
        final bool? result = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("削除確認"),
              content: Text("${product.name} を削除してよろしいですか？"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("キャンセル"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("削除"),
                ),
              ],
            );
          },
        );
        return result ?? false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: context.paddingMedium),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      // スワイプ完了後に削除処理を呼び出す
      onDismissed: (direction) async {
        await ref
            .read(categoriesProvider.notifier)
            .updateProductAssignment(currentCategory.name, product.name, false);
      },
      // 長押しで個別の削除ダイアログを起動
      child: GestureDetector(
        onLongPress: () async {
          await _deleteItem(context, ref);
        },
        child: Card(
          elevation: 4,
          margin: EdgeInsets.symmetric(
            vertical: context.paddingMedium,
            horizontal: context.paddingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            // 並び替え開始ハンドルの提供
            leading: ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
            title: Text(
              product.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: context.fontSizeMedium,
              ),
            ),
            subtitle: Text(
              product.description,
              style: TextStyle(fontSize: context.fontSizeMedium),
            ),
            onTap: () => showProductDialog(context, product),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// CategoryItemCard
/// ─────────────────────────────────────────────────────────
/// このウィジェットは、ドラッグ操作による並び替えが必要な場合に利用するシンプルな
/// カード形式の表示ウィジェットです。タップすると単語の詳細ダイアログを表示します。
/// ---------------------------------------------------------------------------
class CategoryItemCard extends ConsumerWidget {
  final Product product; // 表示対象の単語の情報
  final int index; // リスト内の位置（ドラッグ操作用）
  final Category currentCategory; // 所属するカテゴリ情報

  const CategoryItemCard({
    super.key,
    required this.product,
    required this.index,
    required this.currentCategory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReorderableDelayedDragStartListener(
      index: index,
      child: ProductCard(
        product: product,
        onTap: () => showProductDialog(context, product),
        margin: EdgeInsets.symmetric(
          vertical: context.paddingMedium,
          horizontal: context.paddingMedium,
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// SavedItemCard
/// ─────────────────────────────────────────────────────────
/// 保存済み（お気に入りなど）の単語のカード表示ウィジェットです。
/// CategoryItemCard と非常に似ていますが、主に保存された単語の一覧表示で用いられます。
/// ---------------------------------------------------------------------------
class SavedItemCard extends ConsumerWidget {
  final Product product; // 表示対象の単語の情報
  final int index; // 保存リスト内のインデックス

  const SavedItemCard({
    super.key,
    required this.product,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReorderableDelayedDragStartListener(
      index: index,
      child: ProductCard(
        product: product,
        onTap: () => showProductDialog(context, product),
        margin: EdgeInsets.symmetric(
          vertical: context.paddingMedium,
          horizontal: context.paddingMedium,
        ),
      ),
    );
  }
}

class CategoryItemsPage extends ConsumerStatefulWidget {
  final Category category;

  const CategoryItemsPage({super.key, required this.category});

  @override
  CategoryItemsPageState createState() => CategoryItemsPageState();
}

/// ---------------------------------------------------------------------------
/// CategoryItemsPageState
/// ─────────────────────────────────────────────────────────
/// カテゴリ内に属する単語の一覧ページを管理する状態クラスです。
/// 画面表示モードとして通常リストと並び替え用のリストを切り替えて表示します。
/// ---------------------------------------------------------------------------
class CategoryItemsPageState extends ConsumerState<CategoryItemsPage> {
  bool _isSorting = false; // 並び替えモードか通常表示かのフラグ

  @override
  Widget build(BuildContext context) {
    // Riverpodから全カテゴリと全単語の状態を取得し、現在のカテゴリを特定
    final allCategories = ref.watch(categoriesProvider);
    final currentCategory = allCategories.firstWhere(
      (cat) => cat.name == widget.category.name,
      orElse: () => widget.category,
    );
    final allProducts = ref.watch(allProductsProvider);

    // 現在のカテゴリに属する単語のリストを、プロダクト名をキーにして抽出
    final filtered = currentCategory.products.map((productName) {
      return allProducts.firstWhere((p) => p.name == productName);
    }).toList();

    final categoryName = currentCategory.name;

    return Scaffold(
      appBar: AppBar(
        title: Text("カテゴリー: $categoryName"),
        centerTitle: true,
        actions: [
          if (_isSorting)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                // 並び替えモード終了のためのチェックボタン
                setState(() {
                  _isSorting = false;
                });
              },
            )
        ],
      ),
      body: filtered.isEmpty
          ? const Center(child: Text("このカテゴリーに単語はありません"))
          : _isSorting
              ? _buildSortingList(filtered, categoryName) // 並び替えモード表示
              : _buildNormalList(filtered, categoryName), // 通常リスト表示
    );
  }

  /// [_buildNormalList]
  /// ─────────────────────────────────────────────────────────
  /// 通常モードでの単語一覧表示用ウィジェットを構築します。
  /// 各カードはスワイプや長押しでの各種アクション（保存、削除、他）が操作可能です。
  Widget _buildNormalList(List<Product> products, String categoryName) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return SwipeToDeleteCard(
          keyValue: ValueKey(product.name),
          // 削除確認ダイアログの表示と結果による処理
          onConfirm: () async {
            return await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("削除確認"),
                    content: Text("${product.name} をカテゴリーから削除してよろしいですか？"),
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
          onDismissed: () async {
            // スワイプ後に削除処理を実行
            await ref
                .read(categoriesProvider.notifier)
                .updateProductAssignment(categoryName, product.name, false);
          },
          child: GestureDetector(
            onLongPress: () {
              // 長押しで各種操作メニュー（保存、チェック問題登録、並び替え、削除）のモーダルシートを表示
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return SafeArea(
                    child: Wrap(
                      children: <Widget>[
                        ListTile(
                          leading: const Icon(Icons.bookmark),
                          title: const Text("保存する"),
                          onTap: () {
                            Navigator.pop(context);
                            showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) =>
                                  CategoryAssignmentSheet(product: product),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.check_box),
                          title: const Text("単語チェック問題に登録する"),
                          onTap: () {
                            final currentChecked =
                                ref.read(checkedQuestionsProvider);
                            if (currentChecked.contains(product.name)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("既に単語チェック問題に登録されています。"),
                                ),
                              );
                            } else {
                              ref
                                  .read(checkedQuestionsProvider.notifier)
                                  .add(product.name);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("単語チェック問題に登録しました。"),
                                ),
                              );
                            }
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.sort),
                          title: const Text("並び替える"),
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              // 並び替えモードに移行
                              _isSorting = true;
                            });
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete),
                          title: const Text("削除"),
                          onTap: () async {
                            await ref
                                .read(categoriesProvider.notifier)
                                .updateProductAssignment(
                                    categoryName, product.name, false);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            child: ProductCard(
              product: product,
              margin: EdgeInsets.symmetric(
                vertical: context.paddingExtraSmall,
                horizontal: context.paddingExtraSmall,
              ),
              onTap: () => showProductDialog(context, product),
            ),
          ),
        );
      },
    );
  }

  /// [_buildSortingList]
  /// ─────────────────────────────────────────────────────────
  /// 並び替えモード専用のリスト表示ウィジェットを作成します。
  /// ドラッグ操作により単語の順番を更新できるようにしています。
  Widget _buildSortingList(List<Product> products, String categoryName) {
    return ReorderableListView.builder(
      itemCount: products.length,
      onReorder: (oldIndex, newIndex) async {
        if (newIndex > oldIndex) newIndex--;
        await ref.read(categoriesProvider.notifier).reorderProducts(
              categoryName,
              oldIndex,
              newIndex,
            );
      },
      itemBuilder: (context, index) {
        final product = products[index];
        return ListTile(
          key: ValueKey(product.name),
          leading: const Icon(Icons.drag_handle),
          title: Text(
            product.name,
            style: TextStyle(
              fontSize: context.fontSizeMedium,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () => showProductDialog(context, product),
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------------
/// CheckedQuestionsNotifier
/// ─────────────────────────────────────────────────────────
/// 単語チェック問題に登録した単語の名前をセットとして管理する状態クラスです。
/// ・初期化時に SharedPreferences から読み込み
/// ・add, remove, toggle の各操作で状態および永続化処理を実行
/// ---------------------------------------------------------------------------
class CheckedQuestionsNotifier extends StateNotifier<Set<String>> {
  CheckedQuestionsNotifier() : super({}) {
    _load();
  }

  /// [_load]
  /// SharedPreferencesから以前の登録済み単語のセットをロードします。
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('checked_questions') ?? [];
    state = state.union(list.toSet());
  }

  /// [add]
  /// 指定された単語を状態に追加し、SharedPreferencesに保存します。
  Future<void> add(String productName) async {
    if (!state.contains(productName)) {
      state = {...state, productName};
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('checked_questions', state.toList());
    }
  }

  /// [remove]
  /// 指定された単語を状態から除外し、SharedPreferencesに反映します。
  Future<void> remove(String productName) async {
    if (state.contains(productName)) {
      state = state.where((name) => name != productName).toSet();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('checked_questions', state.toList());
    }
  }

  /// [toggle]
  /// 単語が状態に含まれていれば削除、なければ追加するトグル動作を実行します。
  Future<void> toggle(String productName) async {
    if (state.contains(productName)) {
      await remove(productName);
    } else {
      await add(productName);
    }
  }
}

/// Providerを通じて、アプリ内でチェックされた単語の状態を共有します。
final checkedQuestionsProvider =
    StateNotifierProvider<CheckedQuestionsNotifier, Set<String>>(
        (ref) => CheckedQuestionsNotifier());

/// ---------------------------------------------------------------------------
/// アプリエントリーポイント：main() と MyApp
/// ─────────────────────────────────────────────────────────
/// Flutterの初期化とRiverpodのProviderScopeでアプリ全体をラップし、
/// MyAppウィジェットを起動します。
/// ---------------------------------------------------------------------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/// [MyApp]
/// ─────────────────────────────────────────────────────────
/// アプリ全体のテーマ設定やホーム画面(SearchPage)を設定するルートウィジェットです。
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '単語検索＆保存アプリ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Murecho',
        useMaterial3: false,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      // ホーム画面はSearchPageで、ユーザーが単語の検索や操作を行えます
      home: const SearchPage(),
    );
  }
}
// *****************************************************************************
// Custom Products to Word Test Page (Quiz Screen)
// このセクションでは、ユーザーが追加した単語や検索・テスト画面に関するビジネスロジックとUIを管理します。
// CustomProductsNotifier ～ _WordTestPageState までのクラスには、ユーザーによるカスタム単語の管理、
// アセット＋カスタム単語の統合、単語検索画面、単語テスト（クイズ）画面などが含まれます。
// *****************************************************************************

/// ---------------------------------------------------------------------------
/// CustomProductsNotifier
/// ---------------------------------------------------------------------------
/// ユーザーがアプリ上で追加したカスタム単語（Productオブジェクト）のリストを管理する
/// StateNotifier。インスタンス化時に SharedPreferences からデータをロードし、
/// addProduct() で新規単語を追加すると同時にストレージへ保存します。
class CustomProductsNotifier extends StateNotifier<List<Product>> {
  CustomProductsNotifier() : super([]) {
    _loadCustomProducts();
  }

  /// _loadCustomProducts()
  /// SharedPreferences から保存済みのカスタム単語リストを読み込んで状態を初期化する
  Future<void> _loadCustomProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? productJsonList =
        prefs.getStringList('custom_products');
    if (productJsonList != null) {
      state = productJsonList.map((jsonStr) {
        final Map<String, dynamic> json = jsonDecode(jsonStr);
        return Product.fromJson(json);
      }).toList();
    }
  }

  /// addProduct()
  /// 新しいカスタム単語を状態に追加し、最新のリストを SharedPreferences に保存する
  Future<void> addProduct(Product product) async {
    state = [...state, product];
    final prefs = await SharedPreferences.getInstance();
    // 保存する際は、必要なプロパティのみエンコードする
    final productJsonList = state
        .map((p) => jsonEncode({
              'name': p.name,
              'yomigana': p.yomigana,
              'description': p.description,
            }))
        .toList();
    await prefs.setStringList('custom_products', productJsonList);
  }
}

/// プロバイダー定義：ユーザーが追加したカスタム単語を管理する
final customProductsProvider =
    StateNotifierProvider<CustomProductsNotifier, List<Product>>(
        (ref) => CustomProductsNotifier());

/// ---------------------------------------------------------------------------
/// allProductsProvider
/// ---------------------------------------------------------------------------
/// アセット(JSON)からロードした単語とカスタム単語（ユーザー追加）を統合して返すシンプルなプロバイダー
final allProductsProvider = Provider<List<Product>>((ref) {
  final assetProductsAsync = ref.watch(productsProvider);
  final customProducts = ref.watch(customProductsProvider);
  List<Product> assetProducts = [];

  // FutureProvider の状態に合わせてアセット単語リストを抽出
  assetProductsAsync.when(
    data: (products) => assetProducts = products,
    loading: () {},
    error: (_, __) {},
  );
  // 両方のリストを統合して返す
  return [...assetProducts, ...customProducts];
});

/// ---------------------------------------------------------------------------
/// SearchPage
/// ---------------------------------------------------------------------------
/// 単語検索画面。ユーザーが単語名や読みから検索を行い、
/// 結果がリスト表示され、各単語の詳細ダイアログなどへ遷移できる。
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

/// _SearchPageState
/// SearchPage の内部状態。検索クエリ、表示する単語のキャッシュ、
/// 並び替え処理用の状態などを管理する
class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _controller = TextEditingController();

  // 検索クエリ未入力時にランダムで表示する単語のキャッシュ
  List<Product>? _cachedRandomProducts;

  // 並び替えモード用の状態（今回は固定モードとして _isSorting は false）
  final bool _isSorting = false;
  List<Product>? _sortedProducts;

  /// _onRefresh()
  /// 画面プルダウンリフレッシュ時にキャッシュをクリアし、プロバイダーのデータを再読み込みする
  Future<void> _onRefresh() async {
    _cachedRandomProducts = null;
    await Future.delayed(const Duration(milliseconds: 1000));
    ref.invalidate(productsProvider);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// _showActionSheet()
  /// 長押し時に表示するアクションシート。ここで単語の「保存」や「単語チェック問題」への登録処理を実行する
  void _showActionSheet(Product product) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.bookmark),
                title: const Text("保存する"),
                onTap: () {
                  Navigator.pop(context);
                  // カテゴリーへの自動割当画面等の表示
                  showModalBottomSheet(
                    context: context,
                    builder: (context) =>
                        CategoryAssignmentSheet(product: product),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_box),
                title: const Text("単語チェック問題に登録する"),
                onTap: () {
                  Navigator.pop(context);
                  // 既に登録されているかチェックし、なければ追加
                  final currentChecked = ref.read(checkedQuestionsProvider);
                  if (currentChecked.contains(product.name)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("既に単語チェック問題に登録されています。"),
                      ),
                    );
                  } else {
                    ref
                        .read(checkedQuestionsProvider.notifier)
                        .add(product.name);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("単語チェック問題に登録しました。"),
                      ),
                    );
                  }
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
    final searchQuery = ref.watch(searchQueryProvider);
    final productsAsync = ref.watch(productsProvider);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // 画面タップ時にキーボードやフォーカスを外す
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('単語検索'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'メニュー',
              onPressed: () {
                // メニュー表示時にもキーボードフォーカスを解除
                FocusScope.of(context).unfocus();
                // 下部モーダルシートで各種機能（保存一覧、カテゴリー、クイズ、設定など）へ遷移
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (context) {
                    return Container(
                      margin: EdgeInsets.all(context.paddingMedium),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(context.paddingSmall),
                            child: Text(
                              "メニュー",
                              style: TextStyle(
                                  fontSize: context.fontSizeLarge,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Divider(height: 1),
                          // 既存項目
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SavedItemsPage()),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: context.paddingMedium,
                                  horizontal: context.paddingSmall),
                              child: Row(
                                children: [
                                  const Icon(Icons.bookmark,
                                      color: Colors.blue),
                                  context.horizontalSpaceSmall,
                                  Expanded(
                                      child: Text("保存単語",
                                          style: TextStyle(
                                              fontSize:
                                                  context.fontSizeMedium))),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const CategorySelectionPage()),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: context.paddingMedium,
                                  horizontal: context.paddingSmall),
                              child: Row(
                                children: [
                                  const Icon(Icons.folder, color: Colors.blue),
                                  context.horizontalSpaceMedium,
                                  Expanded(
                                      child: Text("カテゴリーリスト",
                                          style: TextStyle(
                                              fontSize:
                                                  context.fontSizeMedium))),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const WordTestPage()),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: context.paddingMedium,
                                  horizontal: context.paddingSmall),
                              child: Row(
                                children: [
                                  const Icon(Icons.quiz, color: Colors.blue),
                                  context.horizontalSpaceMedium,
                                  Expanded(
                                      child: Text("単語テスト",
                                          style: TextStyle(
                                              fontSize:
                                                  context.fontSizeMedium))),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const CheckedQuestionsPage()),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: context.paddingMedium,
                                  horizontal: context.paddingSmall),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_box,
                                      color: Colors.blue),
                                  context.horizontalSpaceMedium,
                                  Expanded(
                                      child: Text("単語チェック問題",
                                          style: TextStyle(
                                              fontSize:
                                                  context.fontSizeMedium))),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1),

                          // ★ 新規追加：設定項目
                          // 例：SearchPageのメニュー表示部分（既存項目の後ろに追加）
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SettingsPage()),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: context.paddingMedium,
                                  horizontal: context.paddingSmall),
                              child: Row(
                                children: [
                                  const Icon(Icons.settings,
                                      color: Colors.blue),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text("設定",
                                        style: TextStyle(
                                            fontSize: context.fontSizeMedium)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const WordListPage()),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: context.paddingMedium,
                                  horizontal: context.paddingSmall),
                              child: Row(
                                children: [
                                  const Icon(Icons.list, color: Colors.blue),
                                  context.horizontalSpaceMedium,
                                  Expanded(
                                      child: Text("単語一覧",
                                          style: TextStyle(
                                              fontSize:
                                                  context.fontSizeMedium))),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        // 検索入力欄と、検索結果またはランダム表示の単語リストを表示する
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              // 検索テキストフィールド
              Padding(
                padding: EdgeInsets.all(context.paddingMedium),
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: '単語名を入力',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      _cachedRandomProducts = null;
                    }
                    ref.read(searchQueryProvider.notifier).state = value;
                  },
                ),
              ),
              // プロバイダーの状態に基づいた単語リストの表示処理
              productsAsync.when(
                loading: () => Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: context.paddingMedium),
                  child: const Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Center(child: Text('データ読み込みエラー: $error')),
                data: (products) {
                  List<Product> filteredProducts;
                  if (searchQuery.isNotEmpty) {
                    // 検索クエリに一致する単語のみ抽出
                    filteredProducts = products.where((p) {
                      final query = searchQuery.toLowerCase();
                      return p.name.toLowerCase().contains(query) ||
                          p.yomigana.toLowerCase().contains(query);
                    }).toList();
                  } else {
                    // 検索未入力時は、ランダムに15件表示（キャッシュして再計算を避ける）
                    _cachedRandomProducts ??= () {
                      final randomizedProducts = List<Product>.from(products);
                      randomizedProducts.shuffle();
                      return randomizedProducts.take(15).toList();
                    }();
                    filteredProducts = _cachedRandomProducts!;
                  }

                  if (filteredProducts.isEmpty) {
                    return Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: context.paddingMedium),
                      child: const Center(child: Text('一致する単語がありません')),
                    );
                  }

                  // 並び替えモードの場合（※今回は固定モード）
                  if (_isSorting) {
                    _sortedProducts ??= List<Product>.from(filteredProducts);
                    return SizedBox(
                      height: filteredProducts.length * 80,
                      child: ReorderableListView.builder(
                        itemCount: _sortedProducts!.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex--;
                            final product = _sortedProducts!.removeAt(oldIndex);
                            _sortedProducts!.insert(newIndex, product);
                          });
                        },
                        itemBuilder: (context, index) {
                          final product = _sortedProducts![index];
                          return GestureDetector(
                            key: ValueKey(product.name),
                            onLongPress: () {
                              _showActionSheet(product);
                            },
                            child: ProductCard(
                              product: product,
                              margin: EdgeInsets.symmetric(
                                  vertical: context.paddingMedium,
                                  horizontal: context.paddingMedium),
                              onTap: () => showProductDialog(context, product),
                            ),
                          );
                        },
                      ),
                    );
                  } else {
                    // 通常モード：ListView で単語カードを列挙
                    return Column(
                      children: filteredProducts.map((product) {
                        return GestureDetector(
                          onLongPress: () {
                            _showActionSheet(product);
                          },
                          child: ProductCard(
                            product: product,
                            margin: EdgeInsets.symmetric(
                                vertical: context.paddingExtraSmall,
                                horizontal: context.paddingSmall),
                            onTap: () => showProductDialog(context, product),
                          ),
                        );
                      }).toList(),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// WordTestPage
/// ---------------------------------------------------------------------------
/// ユーザーがクイズ形式で単語テストに挑戦できる画面。各問題は単語の説明を基にして出題され、
/// 選択肢をタップすると正誤判定が行われ、最終的なテスト結果画面に遷移します。
class WordTestPage extends ConsumerStatefulWidget {
  const WordTestPage({super.key});

  @override
  ConsumerState<WordTestPage> createState() => _WordTestPageState();
}

/// _WordTestPageState
/// ---------------------------------------------------------------------------
/// 単語テスト（クイズ）の状態を管理するクラス。クイズの問題リスト生成、
/// ユーザーの選択に応じた正誤判定、次の問題への遷移などのロジックを内包しています。
class _WordTestPageState extends ConsumerState<WordTestPage> {
  List<WordTestQuestion> quiz = []; // 出題用の問題リスト
  int currentQuestionIndex = 0; // 現在の問題番号を管理

  /// _generateQuiz()
  /// 指定された単語リストからランダムにクイズ問題を生成する
  void _generateQuiz(List<Product> products) {
    quiz = generateQuizQuestions(products, products, quizCount: 10);
    currentQuestionIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text("単語テスト"),
      ),
      body: productsAsync.when(
        // データ読み込み中はプログレスインジケーターを表示
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text("データ読み込みエラー: $error")),
        data: (products) {
          if (quiz.isEmpty) _generateQuiz(products);
          final currentQuestion = quiz[currentQuestionIndex];
          return Padding(
            padding: EdgeInsets.all(context.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 問題番号と総問題数の表示
                Text(
                  "問題 ${currentQuestionIndex + 1} / ${quiz.length}",
                  style: TextStyle(
                      fontSize: context.fontSizeExtraLarge,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // 問題（単語の説明）の表示
                Text(
                  "問題：${currentQuestion.product.description}",
                  style: TextStyle(fontSize: context.fontSizeMedium),
                ),
                const SizedBox(height: 24),
                // 選択肢ボタン群：ユーザー選択後、正解・不正解の色分けを反映
                ...currentQuestion.options.map((option) {
                  Color? btnColor;
                  if (currentQuestion.userAnswer != null) {
                    if (option == currentQuestion.product.name) {
                      btnColor = Colors.green;
                    } else if (option == currentQuestion.userAnswer) {
                      btnColor = Colors.red;
                    }
                  }
                  return Container(
                    margin:
                        EdgeInsets.symmetric(vertical: context.paddingSmall),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnColor,
                      ),
                      onPressed: currentQuestion.userAnswer == null
                          ? () async {
                              setState(() {
                                currentQuestion.userAnswer = option;
                              });
                              // 正解でない場合、ミス回数もインクリメント
                              if (!currentQuestion.isCorrect) {
                                ref
                                    .read(mistakeCountsProvider.notifier)
                                    .increment(currentQuestion.product.name);
                              }
                              // 1秒後に次の問題または結果画面へ遷移
                              await Future.delayed(const Duration(seconds: 1));
                              if (currentQuestionIndex < quiz.length - 1) {
                                setState(() {
                                  currentQuestionIndex++;
                                });
                              } else {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        WordTestResultPage(quiz: quiz),
                                  ),
                                );
                              }
                            }
                          : null,
                      child: Text(
                        option,
                        style: TextStyle(fontSize: context.fontSizeMedium),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                // ユーザーの回答に応じたフィードバック表示
                if (currentQuestion.userAnswer != null)
                  Text(
                    currentQuestion.isCorrect
                        ? "正解！"
                        : "不正解。正解は ${currentQuestion.product.name} です。",
                    style: TextStyle(
                      fontSize: context.fontSizeMedium,
                      color:
                          currentQuestion.isCorrect ? Colors.green : Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const Spacer(),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// WordTestResultPage
/// ---------------------------------------------------------------------------
/// 単語テスト（クイズ）の結果画面を表示するウィジェットです。
/// ・全体の正解数を表示し、各問題に対して、
///   問題番号、問題文（単語の説明）、ユーザーの回答、正解・不正解の表示、
///   選択肢一覧、累計ミス回数、解説をカード形式で詳細に表示します。
/// ・画面下部にはホームに戻るボタンや、テストの再挑戦ボタンを配置しています。
class WordTestResultPage extends ConsumerWidget {
  final List<WordTestQuestion> quiz; // 出題されたクイズ問題リスト
  final bool isCheckboxTest; // チェックボックステストかどうかのフラグ

  const WordTestResultPage({
    super.key,
    required this.quiz,
    this.isCheckboxTest = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 正解数を集計
    int correctCount = quiz.where((q) => q.isCorrect).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text("テスト結果"),
      ),
      body: Padding(
        padding: EdgeInsets.all(context.paddingSmall),
        child: Column(
          children: [
            // 結果表示（正解数／総問題数）
            Text(
              "結果：$correctCount / ${quiz.length} 問正解",
              style: TextStyle(
                fontSize: context.fontSizeExtraLarge,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 20),
            // 各問題の詳細結果を、ListView.separated でカード形式に表示
            Expanded(
              child: ListView.separated(
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemCount: quiz.length,
                itemBuilder: (context, index) {
                  final question = quiz[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 6,
                    child: Stack(
                      children: [
                        // 問題の詳細および回答結果をグラデーション背景に表示
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: question.isCorrect
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFE8F5E9),
                                      Color(0xFFC8E6C9)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFFFFEBEE),
                                      Color(0xFFFFCDD2)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                          ),
                          padding: EdgeInsets.all(context.paddingSmall),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 問題番号表示
                              Text(
                                "問題 ${index + 1}",
                                style: TextStyle(
                                  fontSize: context.fontSizeExtraLarge,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              // 問題文（単語の説明）
                              Text(
                                question.product.description,
                                style:
                                    TextStyle(fontSize: context.fontSizeSmall),
                              ),
                              const SizedBox(height: 12),
                              // ユーザーの回答が正解か不正解かを表示するラベル
                              Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: context.paddingSmall,
                                    horizontal: context.paddingMedium),
                                decoration: BoxDecoration(
                                  color: question.isCorrect
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  question.isCorrect ? "正解" : "不正解",
                                  style: TextStyle(
                                    fontSize: context.fontSizeMedium,
                                    fontWeight: FontWeight.bold,
                                    color: question.isCorrect
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // ユーザーの回答と正解を比較して表示
                              Text.rich(
                                TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: "あなたの回答: ",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(
                                      text: "${question.userAnswer}",
                                      style: TextStyle(
                                          fontSize: context.fontSizeMedium,
                                          color: Colors.black87),
                                    ),
                                    if (!question.isCorrect) ...[
                                      const TextSpan(
                                        text: "\n正解: ",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      TextSpan(
                                        text: question.product.name,
                                        style: TextStyle(
                                            fontSize: context.fontSizeMedium,
                                            color: Colors.green),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // 選択肢一覧を表示（ActionChip 形式）
                              Text(
                                "選択肢:",
                                style: TextStyle(
                                  fontSize: context.fontSizeMedium,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: question.options.map((option) {
                                  return ActionChip(
                                    label: Text(option,
                                        style: TextStyle(
                                            fontSize: context.fontSizeMedium)),
                                    backgroundColor: Colors.blueAccent
                                        .withValues(alpha: 0.1),
                                    labelStyle: const TextStyle(
                                        color: Colors.blueAccent),
                                    onPressed: () async {
                                      // 選択肢をタップすると、その単語の詳細情報をダイアログで表示
                                      final allProducts = await ref
                                          .read(productsProvider.future);
                                      final optionProduct =
                                          allProducts.firstWhere(
                                        (p) => p.name == option,
                                        orElse: () => Product(
                                            name: option,
                                            yomigana: "",
                                            description: "説明がありません",
                                            category: ''),
                                      );
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: Text(option),
                                          content:
                                              Text(optionProduct.description),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text("閉じる"),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                              // 累計ミス回数を表示（フィードバック用）
                              Consumer(builder: (context, ref, child) {
                                final mistakeCounts =
                                    ref.watch(mistakeCountsProvider);
                                final mistakeCount =
                                    mistakeCounts[question.product.name] ?? 0;
                                return Text(
                                  "累計ミス回数: $mistakeCount 回",
                                  style: TextStyle(
                                      fontSize: context.fontSizeExtraSmall,
                                      color: Colors.grey),
                                );
                              }),
                            ],
                          ),
                        ),
                        // カード右上にチェックボックスを配置して「チェック済み」を設定できる
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Consumer(
                            builder: (context, ref, _) {
                              final isChecked = ref
                                  .watch(checkedQuestionsProvider)
                                  .contains(question.product.name);
                              return Checkbox(
                                value: isChecked,
                                onChanged: (bool? newVal) async {
                                  await ref
                                      .read(checkedQuestionsProvider.notifier)
                                      .toggle(question.product.name);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 5),
            // 下部のボタン群：ホームに戻る／再挑戦ボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                        vertical: context.paddingSmall,
                        horizontal: context.paddingMedium),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () {
                    // ホームに戻る（スタックの先頭まで戻る）
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  icon: const Icon(Icons.home),
                  label: Text("ホームに戻る",
                      style: TextStyle(fontSize: context.fontSizeMedium)),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                        vertical: context.paddingSmall,
                        horizontal: context.paddingMedium),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () {
                    // テストの再挑戦：チェックボックステストか否かで遷移先を切り替え
                    if (isCheckboxTest) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CheckboxTestPage()),
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const WordTestPage()),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text("もう一度",
                      style: TextStyle(fontSize: context.fontSizeMedium)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// CheckedQuestionsPage
/// ---------------------------------------------------------------------------
/// ユーザーが「単語チェック問題」として登録した単語の一覧を表示する画面です。
/// ・リスト上では各単語に対して、タップで詳細ダイアログやスワイプで削除操作が可能です。
/// ・画面上部には、「問題出題」ボタンがあり、チェックされた単語だけを対象にクイズを開始します。
class CheckedQuestionsPage extends ConsumerStatefulWidget {
  const CheckedQuestionsPage({super.key});

  @override
  CheckedQuestionsPageState createState() => CheckedQuestionsPageState();
}

/// ---------------------------------------------------------------------------
/// CheckedQuestionsPageState
/// ---------------------------------------------------------------------------
/// CheckedQuestionsPage の内部状態を管理するクラスです。
/// ・プロバイダーから取得したチェック済み単語に基づき、
///   リストを表示、削除、並び替え（必要に応じて）の機能を提供します。
class CheckedQuestionsPageState extends ConsumerState<CheckedQuestionsPage> {
  // 並び替えモードフラグ（今回は固定モードで false）
  final bool _isSorting = false;
  List<Product>? _sortedProducts;

  @override
  Widget build(BuildContext context) {
    final checked = ref.watch(checkedQuestionsProvider);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("単語チェック問題"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 画面上部に「問題出題」ボタンを配置（チェック済み単語がある場合のみアクティブ）
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: context.paddingMedium),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: checked.isNotEmpty
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CheckboxTestPage(),
                        ),
                      );
                    }
                  : null,
              child: Text("問題出題",
                  style: TextStyle(fontSize: context.fontSizeExtraLarge)),
            ),
          ),
          // チェック済み単語リストの表示部
          Padding(
            padding: EdgeInsets.only(top: context.paddingExtraLarge * 2.5),
            child: Padding(
              padding: EdgeInsets.all(context.paddingExtraSmall),
              child: productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text("データ読み込みエラー: $error")),
                data: (products) {
                  final filtered =
                      products.where((p) => checked.contains(p.name)).toList();
                  if (filtered.isEmpty) {
                    return const Center(child: Text("チェックされた問題はありません"));
                  }
                  if (_isSorting) {
                    _sortedProducts ??= List<Product>.from(filtered);
                    return ReorderableListView.builder(
                      itemCount: _sortedProducts!.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex--;
                          final item = _sortedProducts!.removeAt(oldIndex);
                          _sortedProducts!.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final product = _sortedProducts![index];
                        return ListTile(
                          key: ValueKey(product.name),
                          title: Text(product.name),
                          subtitle: Text(product.description),
                          onTap: () => showProductDialog(context, product),
                        );
                      },
                    );
                  } else {
                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        return SwipeToDeleteCard(
                          keyValue: ValueKey(product.name),
                          // スワイプで単語を削除する際に確認ダイアログを表示する
                          onConfirm: () async {
                            return await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("削除確認"),
                                    content:
                                        Text("${product.name} を削除してよろしいですか？"),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text("キャンセル"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text("削除"),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false;
                          },
                          onDismissed: () async {
                            await ref
                                .read(checkedQuestionsProvider.notifier)
                                .remove(product.name);
                          },
                          child: GestureDetector(
                            onLongPress: () {
                              _showActionSheet(product);
                            },
                            child: ProductCard(
                              product: product,
                              onTap: () => showProductDialog(context, product),
                              margin: EdgeInsets.symmetric(
                                  vertical: context.paddingExtraSmall),
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// _showActionSheet()
  /// 下部モーダルシートで、保存や削除などの操作項目を表示する
  void _showActionSheet(Product product) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.bookmark),
                title: const Text("保存する"),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    builder: (context) =>
                        CategoryAssignmentSheet(product: product),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text("削除"),
                onTap: () async {
                  await ref
                      .read(checkedQuestionsProvider.notifier)
                      .remove(product.name);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------------
/// CheckboxTestPage
/// ---------------------------------------------------------------------------
/// 登録されたチェック対象単語のみを対象としたクイズテスト画面です。
/// 通常の単語テストと類似していますが、チェックボックスにより選ばれた問題だけを
/// 抽出してクイズ問題として出題します。
//////////////////////////////////////////////
// CheckboxTestPage
//////////////////////////////////////////////
// チェックボックスで登録された単語のみを使ったクイズテスト画面です。
// 通常の単語テストと似ていますが、ユーザーがチェックした単語（チェック済みの問題）だけを
// クイズ出題の対象とします。
class CheckboxTestPage extends ConsumerStatefulWidget {
  const CheckboxTestPage({super.key});

  @override
  ConsumerState<CheckboxTestPage> createState() => _CheckboxTestPageState();
}

//////////////////////////////////////////////
// _CheckboxTestPageState
//////////////////////////////////////////////
// CheckboxTestPage の内部状態を管理し、以下の役割を持ちます：
// ・チェック済み単語から問題用のクイズリストを生成する（_generateQuiz()）
// ・ユーザーの各問題への回答を受け付け、正誤判定を行う
// ・問題番号と全体の進行状況を管理し、回答後、1秒後に次の問題または結果画面へ遷移する
class _CheckboxTestPageState extends ConsumerState<CheckboxTestPage> {
  List<WordTestQuestion> quiz = []; // 出題対象のクイズ問題リスト
  int currentQuestionIndex = 0; // 現在解答中の問題番号
  bool _isAnswered = false; // 現在の問題に対して回答済みか否か

  /// _generateQuiz()
  /// チェック済み単語だけを抽出し、そこからランダムに quizCount 問のクイズ問題を作成する。
  void _generateQuiz(List<Product> products, Set<String> checked) {
    final filteredProducts =
        products.where((p) => checked.contains(p.name)).toList();
    if (filteredProducts.isEmpty) return; // チェック済みがなければ何も生成しない
    quiz = generateQuizQuestions(filteredProducts, products, quizCount: 10);
    currentQuestionIndex = 0;
    _isAnswered = false;
  }

  @override
  Widget build(BuildContext context) {
    // プロバイダーから全単語情報とチェック済み単語リストを取得
    final productsAsync = ref.watch(productsProvider);
    final checked = ref.watch(checkedQuestionsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text("チェックボックス問題"),
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text("データ読み込みエラー: $error")),
        data: (products) {
          // クイズ問題が空の場合、チェック済み商品から問題を生成
          if (quiz.isEmpty) _generateQuiz(products, checked);
          if (quiz.isEmpty) {
            return const Center(child: Text("チェックされた問題がありません"));
          }
          final currentQuestion = quiz[currentQuestionIndex];
          return Padding(
            padding: EdgeInsets.all(context.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 画面上部に「問題 ○/○」を表示
                Text(
                  "問題 ${currentQuestionIndex + 1} / ${quiz.length}",
                  style: TextStyle(
                    fontSize: context.fontSizeExtraLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // クイズ問題として出題する、単語の説明文を表示
                Text(
                  "問題：${currentQuestion.product.description}",
                  style: TextStyle(fontSize: context.fontSizeMedium),
                ),
                const SizedBox(height: 24),
                // 回答選択肢をボタン化して横並び（正解の場合は緑、不正解なら赤で表示）
                ...currentQuestion.options.map((option) {
                  Color? btnColor;
                  if (currentQuestion.userAnswer != null) {
                    if (option == currentQuestion.product.name) {
                      btnColor = Colors.green;
                    } else if (option == currentQuestion.userAnswer) {
                      btnColor = Colors.red;
                    }
                  }
                  return Container(
                    margin:
                        EdgeInsets.symmetric(vertical: context.paddingSmall),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnColor,
                      ),
                      onPressed: currentQuestion.userAnswer == null
                          ? () async {
                              // すでに処理済みであれば何もしない
                              if (_isAnswered) return;
                              _isAnswered = true; // 以降のタップをブロック

                              // ユーザーが選択肢をタップした時の処理
                              setState(() {
                                currentQuestion.userAnswer = option;
                              });
                              // 不正解の場合、ミス回数をカウントアップ
                              if (!currentQuestion.isCorrect) {
                                await ref
                                    .read(mistakeCountsProvider.notifier)
                                    .increment(currentQuestion.product.name);
                              }
                              // 1秒後に次の問題へ遷移。最後なら結果画面へ
                              await Future.delayed(const Duration(seconds: 1));
                              if (currentQuestionIndex < quiz.length - 1) {
                                setState(() {
                                  currentQuestionIndex++;
                                  _isAnswered = false; // 次の問題開始時にリセット
                                });
                              } else {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WordTestResultPage(
                                      quiz: quiz,
                                      isCheckboxTest: true,
                                    ),
                                  ),
                                );
                              }
                            }
                          : null,
                      child: Text(
                        option,
                        style: TextStyle(fontSize: context.fontSizeMedium),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                // 回答後、正解・不正解のフィードバックメッセージを表示
                if (currentQuestion.userAnswer != null)
                  Text(
                    currentQuestion.isCorrect
                        ? "正解！"
                        : "不正解。正解は ${currentQuestion.product.name} です。",
                    style: TextStyle(
                      fontSize: context.fontSizeMedium,
                      color:
                          currentQuestion.isCorrect ? Colors.green : Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const Spacer(),
              ],
            ),
          );
        },
      ),
    );
  }
}

//////////////////////////////////////////////
// SavedItemsPage
//////////////////////////////////////////////
// 保存した単語（お気に入りなど）を一覧表示する画面です。
// 各商品（ProductCard）のタップ・スワイプ、長押しアクションから詳細ダイアログや
// カテゴリー割当、単語チェック問題登録などの操作を実行できます。
class SavedItemsPage extends ConsumerWidget {
  const SavedItemsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // savedItemsProvider から保存済みの単語名リスト、そして productsProvider で全単語情報を取得
    final savedItems = ref.watch(savedItemsProvider);
    final productsAsync = ref.watch(productsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('保存単語'),
        centerTitle: true,
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('データ読み込みエラー: $error')),
        data: (allProducts) {
          // 保存済みの商品名リストから Product オブジェクトを抽出
          final savedProducts = savedItems
              .where((name) => allProducts.any((p) => p.name == name))
              .map((name) => allProducts.firstWhere((p) => p.name == name))
              .toList();

          return CommonProductListView(
            products: savedProducts,
            itemBuilder: (context, product) {
              return SwipeToDeleteCard(
                keyValue: ValueKey(product.name),
                onConfirm: () async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("削除確認"),
                          content: Text("${product.name} を削除してよろしいですか？"),
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
                onDismissed: () async {
                  await ref
                      .read(savedItemsProvider.notifier)
                      .removeItem(product.name);
                },
                child: GestureDetector(
                  onLongPress: () {
                    // 長押し時はカテゴリー割当ウィジェット表示などを実行
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.bookmark),
                              title: const Text("保存する"),
                              onTap: () {
                                Navigator.pop(context);
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) =>
                                      CategoryAssignmentSheet(product: product),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.check_box),
                              title: const Text("単語チェック問題に登録する"),
                              onTap: () {
                                final currentChecked =
                                    ref.read(checkedQuestionsProvider);
                                if (currentChecked.contains(product.name)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("既に単語チェック問題に登録されています。"),
                                    ),
                                  );
                                } else {
                                  ref
                                      .read(checkedQuestionsProvider.notifier)
                                      .add(product.name);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("単語チェック問題に登録しました。"),
                                    ),
                                  );
                                }
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: ProductCard(
                    product: product,
                    onTap: () => showProductDialog(context, product),
                    margin: EdgeInsets.symmetric(
                      vertical: context.paddingExtraSmall,
                      horizontal: context.paddingExtraSmall,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

//////////////////////////////////////////////
// SavedItemsPageState
//////////////////////////////////////////////
// SavedItemsPage の内部状態を管理し、保存単語の並び替えモードを提供します。
// ユーザーはアイコンをタップして並び替えモードに切り替え、
// ドラッグ＆ドロップにより保存順を変更できます。
class SavedItemsPageState extends ConsumerState<SavedItemsPage> {
  bool _isSorting = false; // 並び替えモードか否か

  @override
  Widget build(BuildContext context) {
    final savedItems = ref.watch(savedItemsProvider);
    final productsAsync = ref.watch(productsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('保存単語'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isSorting ? const Icon(Icons.check) : const Icon(null),
            onPressed: () {
              setState(() {
                _isSorting = !_isSorting;
              });
            },
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(context.paddingMedium),
        child: productsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('データ読み込みエラー: $error')),
          data: (products) {
            final savedProducts = savedItems
                .where((itemName) => products.any((p) => p.name == itemName))
                .map((itemName) =>
                    products.firstWhere((p) => p.name == itemName))
                .toList();
            if (savedProducts.isEmpty) {
              return const Center(child: Text('保存された単語はありません'));
            }
            if (_isSorting) {
              return ReorderableListView.builder(
                itemCount: savedProducts.length,
                onReorder: (oldIndex, newIndex) async {
                  if (newIndex > oldIndex) newIndex--;
                  List<String> newOrder = List.from(savedItems);
                  final item = newOrder.removeAt(oldIndex);
                  newOrder.insert(newIndex, item);
                  await ref
                      .read(savedItemsProvider.notifier)
                      .reorderItems(newOrder);
                },
                itemBuilder: (context, index) {
                  final product = savedProducts[index];
                  return ListTile(
                    key: ValueKey(product.name),
                    leading: const Icon(Icons.drag_handle),
                    title: Text(product.name),
                    subtitle: Text(product.description),
                    onTap: () => showProductDialog(context, product),
                  );
                },
              );
            } else {
              return ListView.builder(
                itemCount: savedProducts.length,
                itemBuilder: (context, index) {
                  final product = savedProducts[index];
                  return Dismissible(
                    key: ValueKey(product.name),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.symmetric(
                          horizontal: context.paddingMedium),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("削除確認"),
                            content: Text("${product.name} を削除してよろしいですか？"),
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
                          );
                        },
                      );
                      return result ?? false;
                    },
                    onDismissed: (direction) async {
                      await ref
                          .read(savedItemsProvider.notifier)
                          .removeItem(product.name);
                    },
                    child: GestureDetector(
                      onLongPress: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return SafeArea(
                              child: Wrap(
                                children: <Widget>[
                                  ListTile(
                                    leading: const Icon(Icons.bookmark),
                                    title: const Text("保存する"),
                                    onTap: () {
                                      Navigator.pop(context);
                                      showModalBottomSheet(
                                        context: context,
                                        builder: (context) =>
                                            CategoryAssignmentSheet(
                                                product: product),
                                      );
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.check_box),
                                    title: const Text("単語チェック問題に登録する"),
                                    onTap: () {
                                      final currentChecked =
                                          ref.read(checkedQuestionsProvider);
                                      if (currentChecked
                                          .contains(product.name)) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content:
                                                  Text("既に単語チェック問題に登録されています。")),
                                        );
                                      } else {
                                        ref
                                            .read(checkedQuestionsProvider
                                                .notifier)
                                            .add(product.name);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content:
                                                  Text("単語チェック問題に登録しました。")),
                                        );
                                      }
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.sort),
                                    title: const Text("並び替える"),
                                    onTap: () {
                                      Navigator.pop(context);
                                      setState(() {
                                        _isSorting = true;
                                      });
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.delete),
                                    title: const Text("削除"),
                                    onTap: () async {
                                      await ref
                                          .read(savedItemsProvider.notifier)
                                          .removeItem(product.name);
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: ProductCard(
                        product: product,
                        onTap: () => showProductDialog(context, product),
                        margin: EdgeInsets.symmetric(
                            vertical: context.paddingMedium),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}

//////////////////////////////////////////////
// CategorySelectionPage
//////////////////////////////////////////////
// 登録済みのカテゴリー一覧を表示する画面です。
// ユーザーはカテゴリーごとに保存された単語のリストを見るため、
// 各カテゴリーカードをタップして CategoryItemsPage へ遷移できます。
class CategorySelectionPage extends ConsumerStatefulWidget {
  const CategorySelectionPage({super.key});

  @override
  CategorySelectionPageState createState() => CategorySelectionPageState();
}

// ============================================================================
// CategorySelectionPageState
// -----------------------------------------------------------------------------
// この状態クラスは「カテゴリー一覧画面」内で表示するカテゴリーのリストを管理します。
// ・通常表示モードでは、各カテゴリーをリスト表示し、スワイプで削除や長押しでオプションを起動します。
// ・並び替えモードでは、ドラッグ＆ドロップでカテゴリーの順序を変更できるようにします。
// ============================================================================
class CategorySelectionPageState extends ConsumerState<CategorySelectionPage> {
  /// 並び替えモードかどうかを示すフラグ（trueならドラッグ＆ドロップで順序変更可能）
  bool _isReordering = false;

  @override
  Widget build(BuildContext context) {
    // プロバイダーから現在のカテゴリー一覧を取得
    final categories = ref.watch(categoriesProvider);
    Widget listWidget;

    if (_isReordering) {
      // 【並び替えモード】：ReorderableListView を利用してドラッグ＆ドロップ操作を可能にする
      listWidget = ReorderableListView.builder(
        padding: EdgeInsets.symmetric(vertical: context.paddingMedium),
        itemCount: categories.length,
        onReorder: (oldIndex, newIndex) async {
          // ドラッグ操作後、カテゴリーの新しい順序を更新する
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
              // タップすると、該当カテゴリーの詳細（カテゴリーに属する単語一覧）画面へ遷移
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
      // 【通常モード】：ListView でカテゴリー一覧を表示し、各リスト項目にスワイプ／タップ／長押し操作を埋め込む
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
                      content: Text("カテゴリー『${cat.name}』を削除してよろしいですか？"),
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
            // スワイプ後にカテゴリーを削除する
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
                // タップでカテゴリー内の単語一覧へ遷移
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryItemsPage(category: cat),
                  ),
                );
              },
              // 長押しでカテゴリーの操作（リネーム、削除、並び替え）モーダルを表示
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
        title: const Text("カテゴリーリスト"),
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
      // FloatingActionButton：新規カテゴリーを追加するためのダイアログを起動
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

  /// カテゴリー長押し時に表示するオプションメニュー（リネーム／削除／並び替え）の表示処理
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
              // カテゴリー削除オプション
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text("リスト削除"),
                onTap: () async {
                  Navigator.pop(context);
                  bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("リスト削除"),
                      content: Text("カテゴリー『${cat.name}』を削除してよろしいですか？"),
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

  /// カテゴリー名の変更用ダイアログを表示し、入力された新しい名前で更新する処理
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

// ============================================================================
// CategoryAssignmentSheet
// -----------------------------------------------------------------------------
// CategoryAssignmentSheet は、指定された商品（Product）に対して、
// ・どのカテゴリーに所属させるか（チェックボックスで複数選択可能）
// ・「保存済み」にするかどうか
// の割り当て状態を設定するためのモーダルシートです。
// ============================================================================
class CategoryAssignmentSheet extends ConsumerStatefulWidget {
  final Product product;

  /// [product] - カテゴリー割当の対象商品
  const CategoryAssignmentSheet({super.key, required this.product});

  @override
  CategoryAssignmentSheetState createState() => CategoryAssignmentSheetState();
}

// ============================================================================
// CategoryAssignmentSheetState
// -----------------------------------------------------------------------------
// CategoryAssignmentSheetState において、既存のカテゴリー割当情報と
// 保存状態をローカルに保持し、ユーザーがチェックを変更した結果を反映後、
// 「完了」ボタンを押すとそれぞれのプロバイダーに更新を通知します。
// ============================================================================
class CategoryAssignmentSheetState
    extends ConsumerState<CategoryAssignmentSheet> {
  /// 各カテゴリー名と、該当商品がそのカテゴリーに所属しているかの状態（trueなら所属）
  late Map<String, bool> _localAssignments;

  /// 商品が「保存単語」（お気に入り）に登録されているかの状態
  late bool _localSaved;

  @override
  void initState() {
    super.initState();
    // 現在のカテゴリー割当情報をローカル状態として初期化
    final currentCategories = ref.read(categoriesProvider);
    _localAssignments = {
      for (var cat in currentCategories)
        cat.name: cat.products.contains(widget.product.name)
    };
    // 保存状態についても初期値を設定
    final currentSaved = ref.read(savedItemsProvider);
    _localSaved = currentSaved.contains(widget.product.name);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(context.paddingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ヘッダ部分：対象商品の名称と「新規カテゴリー追加」ボタン
            Row(
              children: [
                Expanded(
                  child: Text(
                    "【${widget.product.name}】のカテゴリー割当",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: context.fontSizeMedium,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    // 新しいカテゴリーを追加するダイアログを表示
                    final newCat = await showCategoryCreationDialog(context);
                    if (newCat != null && newCat.isNotEmpty) {
                      await ref
                          .read(categoriesProvider.notifier)
                          .addCategory(newCat);
                      setState(() {
                        // 新規追加したカテゴリーは初期状態で未割当にする
                        _localAssignments[newCat] = false;
                      });
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("新規カテゴリーを追加"),
                ),
              ],
            ),
            const Divider(),
            // 「保存単語」チェックボックス：お気に入り登録のオン／オフ
            CheckboxListTile(
              title: const Text("保存単語"),
              value: _localSaved,
              onChanged: (newVal) {
                setState(() {
                  _localSaved = newVal ?? false;
                });
              },
            ),
            const Divider(),
            // カテゴリー一覧のチェックボックスリスト：各カテゴリーにこの商品を割り当てるか選択
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final assigned = _localAssignments[cat.name] ?? false;
                  return CheckboxListTile(
                    title: Text(cat.name),
                    value: assigned,
                    onChanged: (newVal) {
                      setState(() {
                        _localAssignments[cat.name] = newVal ?? false;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // 完了ボタン：選択内容をすべて保存し、ダイアログを閉じる
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () async {
                // 各カテゴリーについて、ローカル状態に応じて商品割当の更新を実行
                for (var entry in _localAssignments.entries) {
                  await ref
                      .read(categoriesProvider.notifier)
                      .updateProductAssignment(
                        entry.key,
                        widget.product.name,
                        entry.value,
                      );
                }

                // 保存状態についても、該当プロバイダーに反映する
                if (_localSaved) {
                  await ref
                      .read(savedItemsProvider.notifier)
                      .saveItem(widget.product.name);
                } else {
                  await ref
                      .read(savedItemsProvider.notifier)
                      .removeItem(widget.product.name);
                }
                Navigator.pop(context);
              },
              child: Text(
                "完了",
                style: TextStyle(fontSize: context.fontSizeMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// AddItemToCategoryDialog
// -----------------------------------------------------------------------------
// このウィジェットは、「カテゴリ内に新たに単語を追加」するためのダイアログです。
// ・全単語の中から、既にそのカテゴリに登録されていない商品を対象に自動補完（Autocomplete）で検索
// ・ユーザーが候補をタップすると、該当カテゴリーに自動で商品が追加されます。
// ============================================================================
class AddItemToCategoryDialog extends ConsumerWidget {
  final Category category;

  /// [category] - 商品を追加する対象のカテゴリー情報
  const AddItemToCategoryDialog({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 全単語を取得し、既にカテゴリに含まれていない商品の名前リストを作成
    final allProducts = ref.watch(allProductsProvider);
    final availableOptions = allProducts
        .where((p) => !category.products.contains(p.name))
        .map((p) => p.name)
        .toList();

    return AlertDialog(
      title: const Text("単語を追加"),
      content: Autocomplete<String>(
        // 入力に応じた候補リストを生成
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.trim().isEmpty) {
            return availableOptions;
          }
          return availableOptions.where((option) => option
              .toLowerCase()
              .contains(textEditingValue.text.toLowerCase()));
        },
        // ユーザーが候補を選択したとき：該当商品のカテゴリ割当を更新しダイアログを閉じる
        onSelected: (String selected) async {
          await ref.read(categoriesProvider.notifier).updateProductAssignment(
                category.name,
                selected,
                true,
              );
          Navigator.of(context).pop();
        },
        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: const InputDecoration(
              labelText: "単語を検索",
              border: OutlineInputBorder(),
            ),
            onEditingComplete: onEditingComplete,
          );
        },
      ),
      actions: [
        // キャンセルボタン：何もせずダイアログを閉じる
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("キャンセル"),
        ),
      ],
    );
  }
}

// ============================================================================
// AddProductDialog Widget
// -----------------------------------------------------------------------------
// このウィジェットは「新規単語追加」ダイアログを表示します。
// ユーザーはテキストフィールドに単語（Product）の名前を入力し、
// 「追加」ボタンを押すことで新たな単語を作成できます。
// 「キャンセル」ボタンを押すとダイアログを閉じます。
// ============================================================================
class AddProductDialog extends StatefulWidget {
  const AddProductDialog({super.key});

  @override
  AddProductDialogState createState() => AddProductDialogState();
}

// ============================================================================
// AddProductDialogState
// -----------------------------------------------------------------------------
// この状態クラスは、AddProductDialog の内部状態を管理します。
// ・TextEditingController を用いてユーザーの入力を保持
// ・「追加」ボタンタップ時に、入力が空でなければ新しい Product インスタンスを作成し、
//   ダイアログを閉じる際にその新規商品を返します。
// ・リソース解放のため、dispose() メソッドでコントローラーを破棄します。
// ============================================================================
class AddProductDialogState extends State<AddProductDialog> {
  // ユーザーが新規単語（Productの名前）を入力するためのテキストコントローラー
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    // 使用済みのコントローラーを破棄してリソースを解放
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("新規単語追加"),
      content: TextField(
        controller: _nameController,
        decoration: const InputDecoration(labelText: "単語"),
      ),
      actions: [
        // キャンセルボタン：ユーザーの入力内容を破棄してダイアログを閉じる
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("キャンセル"),
        ),
        // 追加ボタン：入力された単語が空でなければ新たな Product を作成し、
// ダイアログ終了時にその商品を返す
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isNotEmpty) {
              final newProduct = Product(
                name: name,
                yomigana: "",
                description: "",
                category: '',
              );
              Navigator.pop(context, newProduct);
            }
          },
          child: const Text("追加"),
        ),
      ],
    );
  }
}

// ============================================================================
// MistakeCountNotifier
// -----------------------------------------------------------------------------
// この StateNotifier は、各単語（Product）のミス回数（誤答回数）の累計を
// Map<String, int> 型で管理します。
// ・初期化時に SharedPreferences から以前のミスカウントをロードします。
// ・increment メソッドで指定された単語のミス数を増加させ、その値を保存します。
// ============================================================================
class MistakeCountNotifier extends StateNotifier<Map<String, int>> {
  MistakeCountNotifier() : super({}) {
    _loadCounts();
  }

  // SharedPreferences からミス回数の記録をロード
  Future<void> _loadCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('mistake_counts');
    if (data != null) {
      state = Map<String, int>.from(jsonDecode(data));
    }
  }

  // 指定された単語のミス回数を増加させ、結果を永続化する
  Future<void> increment(String productName) async {
    final current = state[productName] ?? 0;
    state = {...state, productName: current + 1};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mistake_counts', jsonEncode(state));
  }
}

// プロバイダー定義：アプリ全体でミス回数の状態を共有するための Provider
final mistakeCountsProvider =
    StateNotifierProvider<MistakeCountNotifier, Map<String, int>>(
  (ref) => MistakeCountNotifier(),
);

class WordListPage extends ConsumerStatefulWidget {
  const WordListPage({super.key});

  @override
  WordListPageState createState() => WordListPageState();
}

class WordListPageState extends ConsumerState<WordListPage> {
  // 初期のカテゴリは「全て」
  String selectedCategory = '全て';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("単語一覧"),
        centerTitle: true,
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('データ読み込みエラー: $error')),
        data: (products) {
          // すべてのカテゴリ情報を抽出
          final Set<String> categorySet =
              products.map((p) => p.category).toSet();
          final List<String> categories = ['全て', ...categorySet];

          // 選択されたカテゴリによって商品のリストをフィルタリング
          final List<Product> filteredProducts = selectedCategory == '全て'
              ? products
              : products.where((p) => p.category == selectedCategory).toList();

          return Column(
            children: [
              // フィルター用のドロップダウンを上部に配置
              Padding(
                padding: EdgeInsets.all(context.paddingMedium),
                child: Row(
                  children: [
                    Text(
                      "カテゴリ絞り込み:",
                      style: TextStyle(fontSize: context.fontSizeMedium),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButton<String>(
                        value: selectedCategory,
                        isExpanded: true,
                        items: categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat,
                            child: Text(cat),
                          );
                        }).toList(),
                        onChanged: (newVal) {
                          if (newVal != null) {
                            setState(() {
                              selectedCategory = newVal;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // 商品リストの表示部分を共通ウィジェットで管理
              Expanded(
                child: CommonProductListView(
                  products: filteredProducts,
                  itemBuilder: (context, product) {
                    return GestureDetector(
                      onLongPress: () {
                        // 長押し時に詳細ボトムシートなど表示
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return SafeArea(
                              child: Wrap(
                                children: <Widget>[
                                  ListTile(
                                    leading: const Icon(Icons.bookmark),
                                    title: const Text("保存する"),
                                    onTap: () {
                                      Navigator.pop(context);
                                      showModalBottomSheet(
                                        context: context,
                                        builder: (BuildContext context) =>
                                            CategoryAssignmentSheet(
                                                product: product),
                                      );
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.check_box),
                                    title: const Text("単語チェック問題に登録する"),
                                    onTap: () {
                                      final currentChecked =
                                          ref.read(checkedQuestionsProvider);
                                      if (currentChecked
                                          .contains(product.name)) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content: Text("既に単語チェック問題に登録されています。"),
                                        ));
                                      } else {
                                        ref
                                            .read(checkedQuestionsProvider
                                                .notifier)
                                            .add(product.name);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content: Text("単語チェック問題に登録しました。"),
                                        ));
                                      }
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: ProductCard(
                        product: product,
                        onTap: () => showProductDialog(context, product),
                        margin: EdgeInsets.symmetric(
                            vertical: context.paddingExtraSmall,
                            horizontal: context.paddingExtraSmall),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/*
=====================================================================
 仕訳問題と関連クラス・ウィジェット
---------------------------------------------------------------------
 このセクションでは、仕訳問題（SortingProblem）とそれに関連する
 データモデル、プロバイダー、およびクイズ画面用ウィジェット（JournalEntryQuizWidget）
 や、その中で利用する電卓ウィジェット（CalculatorWidget）について定義しています。
=====================================================================
*/

// ============================================================================
// JournalEntry
// -----------------------------------------------------------------------------
// JournalEntry クラスは、1 件の仕訳エントリーを表現します。
// ・side: 「借方」または「貸方」など仕訳の側面を示す文字列
// ・account: 対象となる勘定科目名
// ・amount: 仕訳の金額（整数）
//
// また、JSON の Map から JournalEntry インスタンスを生成するファクトリ
// コンストラクタも実装しています。
// ============================================================================
class JournalEntry {
  final String side; // 仕訳の側面（例: "借方"、"貸方"）
  final String account; // 対象の勘定科目
  final int amount; // 金額

  JournalEntry({
    required this.side,
    required this.account,
    required this.amount,
  });

  // JSON 形式の Map から JournalEntry インスタンスへ変換
  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      side: json['side'] as String,
      account: json['account'] as String,
      amount: json['amount'] as int,
    );
  }
}

// ============================================================================
// SortingProblem
// -----------------------------------------------------------------------------
// SortingProblem クラスは、仕訳問題の 1 件を表現します。
// ・id: 問題の識別子
// ・transactionDate: 仕訳伝票の日付（文字列）
// ・description: 仕訳伝票の説明（問題文）
// ・entries: この問題に対する正解の仕訳エントリー（JournalEntry のリスト）
// ・feedback: 解説（テキスト）
// ・bookkeepingType: 関連する簿記の種別
//
// JSON から SortingProblem インスタンスを生成するファクトリも提供します。
// ============================================================================
class SortingProblem {
  final String id;
  final String transactionDate;
  final String description;
  final List<JournalEntry> entries;
  final String feedback;
  final String bookkeepingType;

  SortingProblem({
    required this.id,
    required this.transactionDate,
    required this.description,
    required this.entries,
    required this.feedback,
    required this.bookkeepingType,
  });

  // JSON の Map から SortingProblem インスタンスへ変換
  factory SortingProblem.fromJson(Map<String, dynamic> json) {
    final entriesJson = json['entries'] as List;
    return SortingProblem(
      id: json['id'] as String,
      transactionDate: json['transaction_date'] as String,
      description: json['description'] as String,
      entries: entriesJson.map((e) => JournalEntry.fromJson(e)).toList(),
      feedback: json['feedback'] as String,
      bookkeepingType: json['bookkeepingType'] as String,
    );
  }
}

// ============================================================================
// sortingProblemsProvider
// -----------------------------------------------------------------------------
// この FutureProvider は、assets/siwake.json から仕訳問題のリストを非同期
// で読み込み、SortingProblem インスタンスのリストとして返します。
// ============================================================================
final sortingProblemsProvider =
    FutureProvider<List<SortingProblem>>((ref) async {
  final data = await rootBundle.loadString('assets/siwake.json');
  final List<dynamic> jsonResult = jsonDecode(data);
  return jsonResult.map((json) => SortingProblem.fromJson(json)).toList();
});

// ============================================================================
// JournalEntryQuizWidget
// -----------------------------------------------------------------------------
// JournalEntryQuizWidget は、仕訳問題のクイズ画面として使用されるウィジェットです。
// ・SortingProblem を受け取り、ユーザーに対して正解の仕訳エントリー（借方／貸方）の
//   入力を求めます。
// ・onSubmitted コールバックにより、正解か否かの結果を親ウィジェットに通知します。
// ============================================================================
class JournalEntryQuizWidget extends StatefulWidget {
  final SortingProblem problem;
  final Function(bool) onSubmitted; // クイズ回答が提出された際に正誤結果を通知

  const JournalEntryQuizWidget({
    super.key,
    required this.problem,
    required this.onSubmitted,
  });

  @override
  State<JournalEntryQuizWidget> createState() => _JournalEntryQuizWidgetState();
}

// ============================================================================
// _JournalEntryQuizWidgetState
// -----------------------------------------------------------------------------
// _JournalEntryQuizWidgetState では、JournalEntryQuizWidget の内部状態を管理します。
// ・問題文に応じた借方・貸方の正解エントリー（debitAnswers, creditAnswers）を抽出
// ・ユーザーが入力する各勘定科目と金額の状態を個別に管理（userDebitAccounts, debitAmountControllers 等）
// ・submitAnswer メソッドで、ユーザーの入力内容と正解リストを比較し、正誤判定を行います。
// ・また、各入力ウィジェット（_buildDebitEntry, _buildCreditEntry）を構築します。
// ============================================================================
class _JournalEntryQuizWidgetState extends State<JournalEntryQuizWidget> {
  // 正解の借方・貸方エントリー
  late final List<JournalEntry> debitAnswers;
  late final List<JournalEntry> creditAnswers;

  // 問題内で共通して利用できる勘定科目の候補リスト
  late final List<String> commonAccountOptions;

  // ユーザーが入力する借方エントリーの各項目（勘定科目）管理
  late List<String?> userDebitAccounts;

  // 借方エントリーの金額入力用テキストコントローラー
  late List<TextEditingController> debitAmountControllers;

  // ユーザーが入力する貸方エントリーの各項目（勘定科目）管理
  late List<String?> userCreditAccounts;

  // 貸方エントリーの金額入力用テキストコントローラー
  late List<TextEditingController> creditAmountControllers;

  // 回答の正誤状態（null:未回答、true:正解、false:不正解）
  bool? isAnswerCorrect;

  @override
  void initState() {
    super.initState();
    // 問題文から「借方」エントリーと「貸方」エントリーを抽出
    debitAnswers =
        widget.problem.entries.where((entry) => entry.side == "借方").toList();
    creditAnswers =
        widget.problem.entries.where((entry) => entry.side == "貸方").toList();

    // 問題に含まれる全勘定科目の候補（重複を除く）
    commonAccountOptions =
        widget.problem.entries.map((e) => e.account).toSet().toList();

    // ユーザーへの初期入力（nullで初期化）
    userDebitAccounts = List.filled(debitAnswers.length, null);
    // 借方の金額入力コントローラーを生成
    debitAmountControllers =
        List.generate(debitAnswers.length, (_) => TextEditingController());

    // 貸方の入力も同様に初期化
    userCreditAccounts = List.filled(creditAnswers.length, null);
    creditAmountControllers =
        List.generate(creditAnswers.length, (_) => TextEditingController());
  }

  @override
  void dispose() {
    // 各コントローラーを破棄してリソースを解放
    for (var ctrl in debitAmountControllers) {
      ctrl.dispose();
    }
    for (var ctrl in creditAmountControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  // ========================================================================
  // submitAnswer
  // ------------------------------------------------------------------------
  // ユーザーの入力内容が全て入力されているかチェック後、
  // 入力された借方・貸方それぞれのリストと正解リストを比較し正誤判定を行います。
  // 正誤判定結果は、親ウィジェットの onSubmitted コールバックで通知します。
  // ========================================================================
  void submitAnswer() {
    // 借方の各エントリーが入力済みかどうかチェック
    for (int i = 0; i < userDebitAccounts.length; i++) {
      if (userDebitAccounts[i] == null ||
          debitAmountControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("借方のすべての項目を選択してください")),
        );
        return;
      }
    }

    // 貸方の各エントリーについてもチェック
    for (int i = 0; i < userCreditAccounts.length; i++) {
      if (userCreditAccounts[i] == null ||
          creditAmountControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("貸方のすべての項目を選択してください")),
        );
        return;
      }
    }

    // ユーザーが入力した借方エントリーのリストに変換（勘定科目＋金額）
    List<Map<String, dynamic>> userDebitList = [];
    for (int i = 0; i < userDebitAccounts.length; i++) {
      int? amount = int.tryParse(
        debitAmountControllers[i].text.trim().replaceAll(',', ''),
      );
      if (amount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("借方：金額は数字で入力してください")),
        );
        return;
      }
      userDebitList.add({
        'account': userDebitAccounts[i],
        'amount': amount,
      });
    }

    // ユーザーが入力した貸方エントリーのリストに変換
    List<Map<String, dynamic>> userCreditList = [];
    for (int i = 0; i < userCreditAccounts.length; i++) {
      int? amount = int.tryParse(
        creditAmountControllers[i].text.trim().replaceAll(',', ''),
      );
      if (amount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("貸方：金額は数字で入力してください")),
        );
        return;
      }
      userCreditList.add({
        'account': userCreditAccounts[i],
        'amount': amount,
      });
    }

    // 正解の借方・貸方リストも Map の形に変換
    List<Map<String, dynamic>> correctDebitList = debitAnswers
        .map((entry) => {
              'account': entry.account,
              'amount': entry.amount,
            })
        .toList();
    List<Map<String, dynamic>> correctCreditList = creditAnswers
        .map((entry) => {
              'account': entry.account,
              'amount': entry.amount,
            })
        .toList();

    // 借方と貸方それぞれの正誤判定
    bool debitCorrect = _isListEqual(userDebitList, correctDebitList);
    bool creditCorrect = _isListEqual(userCreditList, correctCreditList);

    // 両方正解であれば最終的な正誤結果は true
    setState(() {
      isAnswerCorrect = debitCorrect && creditCorrect;
    });
    // 親ウィジェットに結果を通知
    widget.onSubmitted(isAnswerCorrect!);
  }

  // ========================================================================
  // _isListEqual
  // ------------------------------------------------------------------------
  // 2 つの Map のリストが同一内容かどうかを比較します。
  // 順序は問いませんが、各要素（勘定科目と金額の組）が同じであれば true を返します。
  // ========================================================================
  bool _isListEqual(
      List<Map<String, dynamic>> list1, List<Map<String, dynamic>> list2) {
    if (list1.length != list2.length) return false;
    List<Map<String, dynamic>> temp = List.from(list2);
    for (var item in list1) {
      int index = temp.indexWhere((e) =>
          e['account'] == item['account'] && e['amount'] == item['amount']);
      if (index == -1) {
        return false;
      } else {
        temp.removeAt(index);
      }
    }
    return temp.isEmpty;
  }

  // ========================================================================
  // _buildDebitEntry
  // ------------------------------------------------------------------------
  // 指定された index の借方入力項目のウィジェットを構築します。
  // ・DropdownButtonFormField: 勘定科目の選択
  // ・TextField: 金額の入力（カンマ区切りに自動フォーマット）
// ========================================================================
  Widget _buildDebitEntry(int index) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: context.paddingMedium),
      padding: EdgeInsets.all(context.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: "勘定科目",
              contentPadding: EdgeInsets.symmetric(
                  horizontal: context.paddingMedium,
                  vertical: context.paddingMedium),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            value: userDebitAccounts[index],
            isExpanded: true,
            // ユーザーが選択可能な勘定科目一覧（共通候補リスト）
            items: commonAccountOptions
                .map((account) => DropdownMenuItem(
                      value: account,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          account,
                          style: TextStyle(fontSize: context.fontSizeMedium),
                          maxLines: 1,
                        ),
                      ),
                    ))
                .toList(),
            onChanged: (val) {
              setState(() {
                userDebitAccounts[index] = val;
              });
            },
          ),
          const SizedBox(height: 6),
          TextField(
            controller: debitAmountControllers[index],
            decoration: InputDecoration(
              labelText: "金額",
              contentPadding: EdgeInsets.symmetric(
                  horizontal: context.paddingMedium,
                  vertical: context.paddingMedium),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              // 計算結果を入力するための電卓アイコン
              suffixIcon: IconButton(
                icon: const Icon(Icons.calculate),
                onPressed: () async {
                  double initialValue = double.tryParse(
                          debitAmountControllers[index]
                              .text
                              .replaceAll(',', '')
                              .trim()) ??
                      0;
                  final result = await showModalBottomSheet<double>(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) =>
                        CalculatorWidget(initialValue: initialValue),
                  );
                  if (result != null) {
                    debitAmountControllers[index].text =
                        NumberFormat('#,###').format(result);
                  }
                },
              ),
            ),
            inputFormatters: [ThousandsSeparatorInputFormatter()],
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // _buildCreditEntry
  // ------------------------------------------------------------------------
  // 指定された index の貸方入力項目のウィジェットを構築します。
// 借方と同様に、勘定科目の選択と金額の入力フィールドから構成されます。
// ========================================================================
  Widget _buildCreditEntry(int index) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: context.paddingMedium),
      padding: EdgeInsets.all(context.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: "勘定科目",
              contentPadding: EdgeInsets.symmetric(
                  horizontal: context.paddingMedium,
                  vertical: context.paddingMedium),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            value: userCreditAccounts[index],
            isExpanded: true,
            items: commonAccountOptions
                .map((account) => DropdownMenuItem(
                      value: account,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          account,
                          maxLines: 1,
                          style: TextStyle(fontSize: context.fontSizeMedium),
                        ),
                      ),
                    ))
                .toList(),
            onChanged: (val) {
              setState(() {
                userCreditAccounts[index] = val;
              });
            },
          ),
          const SizedBox(height: 6),
          TextField(
            controller: creditAmountControllers[index],
            decoration: InputDecoration(
              labelText: "金額",
              contentPadding: EdgeInsets.symmetric(
                  horizontal: context.paddingMedium,
                  vertical: context.paddingMedium),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calculate),
                onPressed: () async {
                  double initialValue = double.tryParse(
                          creditAmountControllers[index]
                              .text
                              .replaceAll(',', '')
                              .trim()) ??
                      0;
                  final result = await showModalBottomSheet<double>(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) =>
                        CalculatorWidget(initialValue: initialValue),
                  );
                  if (result != null) {
                    creditAmountControllers[index].text =
                        NumberFormat('#,###').format(result);
                  }
                },
              ),
            ),
            inputFormatters: [ThousandsSeparatorInputFormatter()],
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          widget.problem.description,
          style: TextStyle(
              fontSize: context.fontSizeMedium, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("借方",
                      style: TextStyle(
                          fontSize: context.fontSizeMedium,
                          fontWeight: FontWeight.bold)),
                  const Divider(thickness: 2),
                  // 借方入力フィールド群の生成
                  Column(
                    children: List.generate(debitAnswers.length,
                        (index) => _buildDebitEntry(index)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("貸方",
                      style: TextStyle(
                          fontSize: context.fontSizeMedium,
                          fontWeight: FontWeight.bold)),
                  const Divider(thickness: 2),
                  // 貸方入力フィールド群の生成
                  Column(
                    children: List.generate(creditAnswers.length,
                        (index) => _buildCreditEntry(index)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // 回答結果表示（正誤のフィードバックと正解仕訳、解説）
        if (isAnswerCorrect != null)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.paddingMedium),
            decoration: BoxDecoration(
              color: isAnswerCorrect! ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isAnswerCorrect! ? Colors.green : Colors.red,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAnswerCorrect! ? "正解です！" : "不正解です",
                  style: TextStyle(
                    fontSize: context.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                    color: isAnswerCorrect! ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 12),
                const Text("正解仕訳【借方】",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...debitAnswers
                    .map((entry) => Text("${entry.account}  ¥${entry.amount}")),
                const SizedBox(height: 4),
                const Text("正解仕訳【貸方】",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...creditAnswers
                    .map((entry) => Text("${entry.account}  ¥${entry.amount}")),
                const SizedBox(height: 12),
                const Text("解説", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(widget.problem.feedback),
              ],
            ),
          ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: isAnswerCorrect == null
              ? () {
                  FocusScope.of(context).unfocus();
                  submitAnswer();
                }
              : null,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: context.paddingMedium),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Center(
            child: Text(
              "回答を提出",
              style: TextStyle(fontSize: context.fontSizeMedium),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// CalculatorWidget
// -----------------------------------------------------------------------------
// CalculatorWidget は、計算機能を提供するモーダルウィジェットです。
// ユーザーはこのウィジェット上で数式入力や数値計算を行い、結果を確定ボタンで
// 呼び出し元へ返します。
// ============================================================================

class CalculatorWidget extends StatefulWidget {
  final double initialValue; // 電卓起動時の初期値

  const CalculatorWidget({super.key, this.initialValue = 0});

  @override
  CalculatorWidgetState createState() => CalculatorWidgetState();
}

// ============================================================================
// CalculatorWidgetState
// -----------------------------------------------------------------------------
// この状態クラスは、CalculatorWidget の内部状態を管理します。
// ・display: 現在の入力内容または計算結果の文字列を保持
// ・_onPressed: 各ボタンタップ時のロジックを実装（クリア、削除、符号反転、計算など）
// ・_buildButton: 各計算ボタンウィジェットを構築します。
// ・build: グリッドレイアウトで計算機の各キーと、確定ボタンを表示します。
// ============================================================================

class CalculatorWidgetState extends State<CalculatorWidget> {
  String display = '0';

  @override
  void initState() {
    super.initState();
    display = '0';
  }

  // 数値が整数なら整数として、そうでなければ小数点以下も含め文字列としてフォーマット
  String formatResult(double result) {
    if (result == result.toInt()) {
      return result.toInt().toString();
    } else {
      return result.toString();
    }
  }

  // ========================================================================
  // _onPressed
  // ------------------------------------------------------------------------
  // 各キー（"C", "DEL", "±", "=", 数字・演算子）の入力に応じて、
  // display の状態を更新します。例として、クリアなら "0" にリセットし、
  // 削除キーなら末尾の文字を削除、= キーなら評価を行います。
  // ========================================================================
  void _onPressed(String key) {
    setState(() {
      if (key == "C") {
        display = "0";
      } else if (key == "DEL") {
        if (display.isNotEmpty) {
          display = display.substring(0, display.length - 1);
          if (display.isEmpty) display = "0";
        }
      } else if (key == "±") {
        if (display.startsWith("-")) {
          display = display.substring(1);
        } else if (display != "0") {
          display = "-$display";
        }
      } else if (key == "=") {
        try {
          Parser p = Parser();
          Expression exp = p.parse(display);
          ContextModel cm = ContextModel();
          double result = exp.evaluate(EvaluationType.REAL, cm);
          display = formatResult(result);
        } catch (e) {
          display = "Error";
        }
      } else {
        // 初期状態 "0" またはエラー時の入力は、上書きする
        if ((display == "0" || display == "Error") &&
            "0123456789.".contains(key)) {
          display = key;
        } else {
          display += key;
        }
      }
    });
  }

  // ========================================================================
  // _buildButton
  // ------------------------------------------------------------------------
  // 指定されたラベル文字列を持つ計算機のキーを作成するためのヘルパーメソッドです。
  // キーが空文字なら空の Container を返します（レイアウト調整のため）。
  // ========================================================================
  Widget _buildButton(String label) {
    if (label.isEmpty) return Container();
    return ElevatedButton(
      onPressed: () => _onPressed(label),
      child: Text(
        label,
        style: TextStyle(fontSize: context.fontSizeMedium),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 計算機上に表示するキーの文字列リスト
    final List<String> keys = [
      "C",
      "±",
      "/",
      "DEL",
      "7",
      "8",
      "9",
      "*",
      "4",
      "5",
      "6",
      "-",
      "1",
      "2",
      "3",
      "+",
      "0",
      ".",
      "=",
      ""
    ];

    return Container(
      padding: EdgeInsets.all(context.paddingMedium),
      height: 500,
      child: Column(
        children: [
          // 計算結果または入力数式を表示する領域
          Container(
            padding: EdgeInsets.all(context.paddingMedium),
            alignment: Alignment.centerRight,
            child: Text(
              display,
              style: TextStyle(fontSize: context.fontSizeMedium),
            ),
          ),
          const Divider(),
          // キーを 4 カラムのグリッド表示で配置
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              childAspectRatio: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: keys.map((key) => _buildButton(key)).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // 下部の「確定」ボタンを押すと、計算結果を呼び出し元へ返す
          ElevatedButton(
            onPressed: () {
              double result = 0;
              try {
                Parser p = Parser();
                Expression exp = p.parse(display);
                ContextModel cm = ContextModel();
                result = exp.evaluate(EvaluationType.REAL, cm);
              } catch (e) {
                result = 0;
              }
              String formatted = formatResult(result);
              Navigator.pop(context, double.tryParse(formatted) ?? 0);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text(
              "確定",
              style: TextStyle(fontSize: context.fontSizeMedium),
            ),
          ),
        ],
      ),
    );
  }
} ///////////////////////////////////////////////////////////////

// CommonProductListView
///////////////////////////////////////////////////////////////
/// [CommonProductListView] は、Product のリスト表示を共通化するためのウィジェットです。
/// ユーザーの入力によるリフレッシュ機能（onRefresh）や、ドラッグ＆ドロップによる
/// アイテム順序変更（isReorderable / onReorder）もサポートします。
///
/// ・products: 表示対象となる Product のリスト
/// ・itemBuilder: 各 Product を表示するためのウィジェットを構築する関数
/// ・onRefresh: 引っ張って更新する際のコールバック（任意）
/// ・isReorderable: 並び替え可能なリストとする場合は true、必ず onReorder コールバックが必要
class CommonProductListView extends StatelessWidget {
  final List<Product> products;
  final Widget Function(BuildContext context, Product product) itemBuilder;
  final Future<void> Function()? onRefresh;
  final bool isReorderable;
  final void Function(int oldIndex, int newIndex)? onReorder;

  const CommonProductListView({
    super.key,
    required this.products,
    required this.itemBuilder,
    this.onRefresh,
    this.isReorderable = false,
    this.onReorder,
  }) : assert(!isReorderable || onReorder != null,
            'Reorderable の場合、onReorder コールバックは必須です。');

  @override
  Widget build(BuildContext context) {
    Widget list;
    if (isReorderable) {
      list = ReorderableListView.builder(
        itemCount: products.length,
        onReorder: onReorder!,
        itemBuilder: (context, index) {
          final product = products[index];
          return Container(
            key: ValueKey(product.name),
            child: itemBuilder(context, product),
          );
        },
      );
    } else {
      list = ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          return itemBuilder(context, products[index]);
        },
      );
    }
    // onRefresh が設定されている場合、RefreshIndicator でラップする
    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        child: list,
      );
    }
    return list;
  }
}

///////////////////////////////////////////////////////////////
// WordSearchPage
///////////////////////////////////////////////////////////////
/// [WordSearchPage] は、ユーザーが単語名や読みで Product を検索できる画面です。
/// ・検索テキストフィールドに入力されたクエリにより、対象の Product をフィルターして表示します。
/// ・入力がない場合は、ランダムに選ばれた数件の単語をキャッシュして表示する仕組みになっています。
class WordSearchPage extends ConsumerWidget {
  const WordSearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(searchQueryProvider);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('単語検索'),
        centerTitle: true,
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('データ読み込みエラー: $error')),
        data: (products) {
          final filteredProducts = (searchQuery.isNotEmpty)
              ? products.where((p) {
                  final query = searchQuery.toLowerCase();
                  return p.name.toLowerCase().contains(query) ||
                      p.yomigana.toLowerCase().contains(query);
                }).toList()
              : products;

          return CommonProductListView(
            products: filteredProducts,
            itemBuilder: (context, product) {
              return GestureDetector(
                onLongPress: () => showProductDialog(context, product),
                child: ProductCard(
                  product: product,
                  onTap: () => showProductDialog(context, product),
                  margin: EdgeInsets.symmetric(
                      vertical: context.paddingMedium,
                      horizontal: context.paddingMedium),
                ),
              );
            },
            onRefresh: () async {
              await Future.delayed(const Duration(seconds: 1));
              ref.invalidate(productsProvider);
            },
          );
        },
      ),
    );
  }
}

///////////////////////////////////////////////////////////////
// SettingsPage
///////////////////////////////////////////////////////////////
/// [SettingsPage] は、ユーザーのアプリ設定（ここでは勉強開始時間の有効／無効及び時間設定）を管理する画面です。
/// ・SwitchListTile で勉強開始時間の有効／無効を切り替え、
///   有効な場合はリスト項目として時間の設定も行えます。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // studySettingsProvider から現在の設定状態を取得
    final studySettings = ref.watch(studySettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("設定"),
      ),
      body: ListView(
        children: [
          // スイッチで勉強開始時間設定の有効／無効を切り替える
          SwitchListTile(
            title: const Text("勉強開始時間を有効にする"),
            value: studySettings.enableStudyStartTime,
            onChanged: (value) {
              ref
                  .read(studySettingsProvider.notifier)
                  .setEnableStudyStartTime(value);
            },
          ),
          // 有効な場合のみ、時間設定項目を表示
          if (studySettings.enableStudyStartTime)
            ListTile(
              title: const Text("勉強開始時間"),
              subtitle: Text(studySettings.studyStartTime),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final parts = studySettings.studyStartTime.split(":");
                TimeOfDay initialTime = TimeOfDay(
                  hour: int.parse(parts[0]),
                  minute: int.parse(parts[1]),
                );
                final chosenTime = await showTimePicker(
                  context: context,
                  initialTime: initialTime,
                );
                if (chosenTime != null) {
                  final formatted =
                      "${chosenTime.hour.toString().padLeft(2, '0')}:${chosenTime.minute.toString().padLeft(2, '0')}";
                  ref
                      .read(studySettingsProvider.notifier)
                      .setStudyStartTime(formatted);
                }
              },
            ),
        ],
      ),
    );
  }
}

///////////////////////////////////////////////////////////////
// StudySettings Data Model
///////////////////////////////////////////////////////////////
/// [StudySettings] は、勉強設定に関するデータモデルです。
/// ・enableStudyStartTime: 勉強開始時間を有効にするかどうかのフラグ
/// ・studyStartTime: 実際の勉強開始時間（例 "08:00"）を文字列で保持
class StudySettings {
  final bool enableStudyStartTime;
  final String studyStartTime;

  StudySettings({
    required this.enableStudyStartTime,
    required this.studyStartTime,
  });
}

///////////////////////////////////////////////////////////////
// StudySettingsNotifier
///////////////////////////////////////////////////////////////
/// [StudySettingsNotifier] は、[StudySettings] の状態管理を行う StateNotifier です。
/// ・SharedPreferences から初期設定を読み込み、
/// ・setEnableStudyStartTime, setStudyStartTime で設定変更と永続化を行います。
class StudySettingsNotifier extends StateNotifier<StudySettings> {
  StudySettingsNotifier()
      : super(StudySettings(
            enableStudyStartTime: false, studyStartTime: "08:00")) {
    _loadSettings();
  }

  // SharedPreferences から保存済みの設定値を読み込み、state を更新
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    bool enabled = prefs.getBool('study_enableStartTime') ?? false;
    String startTime = prefs.getString('study_startTime') ?? "08:00";
    state =
        StudySettings(enableStudyStartTime: enabled, studyStartTime: startTime);
  }

  // 勉強開始時間の有効/無効の設定を更新し、SharedPreferences へ永続化する
  Future<void> setEnableStudyStartTime(bool value) async {
    state = StudySettings(
        enableStudyStartTime: value, studyStartTime: state.studyStartTime);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('study_enableStartTime', value);
  }

  // 勉強開始時間を更新し、SharedPreferences へ永続化する
  Future<void> setStudyStartTime(String time) async {
    state = StudySettings(
        enableStudyStartTime: state.enableStudyStartTime, studyStartTime: time);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('study_startTime', time);
  }
}

///////////////////////////////////////////////////////////////
// studySettingsProvider
///////////////////////////////////////////////////////////////
/// [studySettingsProvider] は、StudySettingsNotifier を通じて
/// アプリ全体で勉強設定の状態を共有するためのプロバイダーです。
final studySettingsProvider =
    StateNotifierProvider<StudySettingsNotifier, StudySettings>(
        (ref) => StudySettingsNotifier());
