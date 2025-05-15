import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // JSON読み込み用、rootBundle利用
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:math_expressions/math_expressions.dart';

/// BuildContext の拡張として、画面サイズに基づいた各種サイズを返すヘルパー
extension ResponsiveSizes on BuildContext {
  /// 現在の画面サイズ（幅×高さ）
  Size get screenSize => MediaQuery.of(this).size;

  // ── パディング系 ──

  double get paddingExtraSmall => screenSize.width * 0.01;

  double get paddingSmall => screenSize.width * 0.02;

  double get paddingMedium => screenSize.width * 0.04;

  double get paddingLarge => screenSize.width * 0.06;

  double get paddingExtraLarge => screenSize.width * 0.08;

  // ── ボタン系 ──

  double get buttonHeight => screenSize.height * 0.07;

  double get buttonWidth => screenSize.width * 0.8;

  // ── アイコン系 ──

  double get iconSizeSmall => screenSize.width * 0.05;

  double get iconSizeMedium => screenSize.width * 0.07;

  double get iconSizeLarge => screenSize.width * 0.09;

  // ── テキストフィールド系 ──

  double get textFieldHeight => screenSize.height * 0.06;

  // ── フォントサイズ系 ──

  double get fontSizeExtraSmall => screenSize.width * 0.03;

  double get fontSizeSmall => screenSize.width * 0.035;

  double get fontSizeMedium => screenSize.width * 0.04;

  double get fontSizeLarge => screenSize.width * 0.045;

  double get fontSizeExtraLarge => screenSize.width * 0.05;

  // ── SizedBox 用のスペース ──

  SizedBox get verticalSpaceExtraSmall =>
      SizedBox(height: screenSize.height * 0.01);

  SizedBox get verticalSpaceSmall => SizedBox(height: screenSize.height * 0.02);

  SizedBox get verticalSpaceMedium =>
      SizedBox(height: screenSize.height * 0.03);

  SizedBox get verticalSpaceLarge => SizedBox(height: screenSize.height * 0.05);

  SizedBox get horizontalSpaceExtraSmall =>
      SizedBox(width: screenSize.width * 0.01);

  SizedBox get horizontalSpaceSmall => SizedBox(width: screenSize.width * 0.02);

  SizedBox get horizontalSpaceMedium =>
      SizedBox(width: screenSize.width * 0.03);

  SizedBox get horizontalSpaceLarge => SizedBox(width: screenSize.width * 0.05);

  // ── Divider 用のサイズ ──

  /// Divider の高さ。ここでの「高さ」は Divider ウィジェット全体が占める垂直方向のスペース
  double get dividerHeightExtraSmall => screenSize.height * 0.01;

  double get dividerHeightSmall => screenSize.height * 0.015;

  double get dividerHeightMedium => screenSize.height * 0.02;

  double get dividerHeightLarge => screenSize.height * 0.025;

  /// Divider の線の太さ（thickness）
  double get dividerThickness => screenSize.width * 0.003;
}

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
      confirmDismiss: (direction) async {
        return await onConfirm();
      },
      onDismissed: (direction) {
        onDismissed();
      },
      child: child,
    );
  }
}

// カンマ区切りで金額をフォーマットするTextInputFormatter
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // 空の場合はそのまま返す
    if (newValue.text.isEmpty) return newValue;
    // 数字以外の文字（カンマなど）を除去
    String numericString = newValue.text.replaceAll(RegExp('[^0-9]'), '');
    if (numericString.isEmpty) return newValue;
    // 数字があればintに変換し、フォーマットする
    final int value = int.parse(numericString);
    final String newText = _formatter.format(value);

    // カーソル位置は末尾に固定（必要に応じて調整可）
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

/// --- 共通ヘルパーメソッド ---
/// 単語詳細ダイアログを表示する
// メモを SharedPreferences から読み込む（毎回最新の値を反映）
Future<String> loadMemo(Product product) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('memo_${product.name}') ?? "";
}
// 単語詳細ダイアログ

// 単語詳細ダイアログ
void showProductDialog(BuildContext context, Product product) {
  showDialog(
    context: context,
    builder: (context) {
      // StatefulBuilder で AlertDialog 全体の再描画を必要最小限に抑える
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            // タイトル部分：左側に商品名、右側にチェックボックス（チェックボックス部分は Consumer で独立）
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
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
            // content 部分：最大高さを設定して SingleChildScrollView でスクロール可能に
            content: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 商品説明
                    Text(product.description),
                    context.verticalSpaceMedium,
                    // 毎回最新の memo を反映する MemoDisplay を利用
                    MemoDisplay(product: product),
                  ],
                ),
              ),
            ),
            actions: [
              // 「メモを書く」ボタン：メモ入力後に setState で AlertDialog を再描画
              TextButton(
                onPressed: () async {
                  await showMemoDialog(context, product);
                  setState(() {}); // 保存後に再描画して最新のメモを反映
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
// メモ表示用ウィジェット（キャッシュせずに常に最新の memo を読み込む）

// メモ表示ウィジェット（キャッシュせずに毎回 loadMemo を呼び出す）
class MemoDisplay extends StatelessWidget {
  final Product product;

  const MemoDisplay({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // ConstrainedBox で最低50pxの高さを確保
    return ConstrainedBox(
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
                  fontSize: context.fontSizeExtraSmall, color: Colors.grey),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

// ユーザーが自由にメモ入力できるダイアログ
// ユーザーが自由にメモ入力できるダイアログ
Future<void> showMemoDialog(BuildContext context, Product product) async {
  final prefs = await SharedPreferences.getInstance();
  final String initialMemo = prefs.getString('memo_${product.name}') ?? "";
  final TextEditingController controller =
      TextEditingController(text: initialMemo);

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("メモを書く"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "ここにメモを入力してください",
          ),
          maxLines: null, // 複数行入力可能
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

/// 新規カテゴリー作成ダイアログを表示する
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

/// カテゴリー削除の確認ダイアログを表示する
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

List<WordTestQuestion> generateQuizQuestions(
    List<Product> quizPool, List<Product> distractorPool,
    {int quizCount = 10}) {
  final random = Random();
  final quizProducts = (List<Product>.from(quizPool)..shuffle(random))
      .take(min(quizCount, quizPool.length))
      .toList();
  return quizProducts.map((product) {
    // distractorPool から正解以外の候補を抽出
    List<String> distractors = distractorPool
        .where((p) => p.name != product.name)
        .map((p) => p.name)
        .toList();
    distractors.shuffle(random);

    // 正しい回答とダミー候補から必ず3個取得（足りなければダミーの"選択肢なし"で埋める）
    List<String> options = [product.name];
    if (distractors.length >= 3) {
      options.addAll(distractors.take(3));
    } else {
      options.addAll(distractors);
      // 足りない場合はダミー文言で埋める（必要に応じて適宜変更してください）
      while (options.length < 4) {
        options.add("選択肢なし");
      }
    }
    options.shuffle(random);
    return WordTestQuestion(product: product, options: options);
  }).toList();
}

/// --- 共通ウィジェット ---
/// 単語カード（ListTileを内包したカード）
class ProductCard extends StatelessWidget {
  final Product product;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress; // 追加
  final EdgeInsets margin;

  const ProductCard({
    super.key,
    required this.product,
    this.trailing,
    this.onTap,
    this.onLongPress, // 追加
    this.margin = const EdgeInsets.all(10.0),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
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
        onLongPress: onLongPress, // 追加
      ),
    );
  }
}

/// --- モデル・プロバイダー系 ---
class Product {
  final String name;
  final String yomigana;
  final String description;
  final String category; // 追加

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
      category: json['category'] ?? '未分類', // デフォルト値などを設定可能
    );
  }
}

/// JSONファイルから単語データを読み込むProvider
final productsProvider = FutureProvider<List<Product>>((ref) async {
  final data = await rootBundle.loadString('assets/products.json');
  final jsonResult = jsonDecode(data) as List;
  return jsonResult.map((json) => Product.fromJson(json)).toList();
});

/// 検索クエリの状態管理
final searchQueryProvider = StateProvider<String>((ref) => '');

// SavedItemsNotifier (saved_itemsの管理)
// 並び替え用のメソッドを追加
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

  // 新たに並び順を更新するメソッド
  Future<void> reorderItems(List<String> newOrder) async {
    state = newOrder;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_items', state);
  }
}

final savedItemsProvider =
    StateNotifierProvider<SavedItemsNotifier, List<String>>(
        (ref) => SavedItemsNotifier());

// 非表示にした単語名を保持するプロバイダー
final hiddenSavedProvider = StateProvider<Set<String>>((ref) => {});

/// カテゴリモデル：ユーザーが登録する各カテゴリ
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

/// カテゴリ管理の状態（作成・編集・削除、単語の所属更新、並び替え）
class CategoriesNotifier extends StateNotifier<List<Category>> {
  CategoriesNotifier() : super([]) {
    _loadCategories();
  }

  Future<void> reorderProducts(
      String categoryName, int oldIndex, int newIndex) async {
    state = state.map((c) {
      if (c.name == categoryName) {
        List<String> newProducts = List.from(c.products);
        // ここでの newIndex の補正処理は削除する（UI 側で処理済み）
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

  /// 並び替え処理
  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    List<Category> updated = List.from(state);
    // ここでは newIndex の補正処理は不要です
    final Category item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    state = updated;
    await _saveCategories();
  }

  /// 指定のカテゴリに対して、単語所属の更新
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

/// 単語テスト用のクイズ問題クラス
class WordTestQuestion {
  final Product product;
  final List<String> options;
  String? userAnswer; //ユーザーが選んだ回答

  WordTestQuestion({required this.product, required this.options});

  bool get isCorrect => userAnswer == product.name;
}

class CategoryItemWidget extends ConsumerWidget {
  final Product product;
  final int index;
  final Category currentCategory;

  const CategoryItemWidget({
    super.key,
    required this.product,
    required this.index,
    required this.currentCategory,
  });

  Future<void> _deleteItem(BuildContext context, WidgetRef ref) async {
    bool? confirm = await showDialog<bool>(
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
    if (confirm == true) {
      await ref
          .read(categoriesProvider.notifier)
          .updateProductAssignment(currentCategory.name, product.name, false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(product.name),
      direction: DismissDirection.endToStart,
      // confirmDismiss で左スワイプによる削除の前に確認ダイアログを表示
      confirmDismiss: (direction) async {
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
      onDismissed: (direction) async {
        await ref
            .read(categoriesProvider.notifier)
            .updateProductAssignment(currentCategory.name, product.name, false);
      },
      child: GestureDetector(
        // 長押し時にも同様の削除確認ダイアログを表示
        onLongPress: () async {
          await _deleteItem(context, ref);
        },
        child: Card(
          elevation: 4,
          margin: EdgeInsets.symmetric(
              vertical: context.paddingMedium,
              horizontal: context.paddingMedium),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            // 左側にドラッグハンドル（二点ボタン）を配置
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

// ☆ 新規ウィジェット: CategoryItemCard
// 　ProductCardと同様のUIを利用し、全体をReorderableDelayedDragStartListenerでラップすることで
// 　長押しでドラッグ（並び替え）できるようにします。
class CategoryItemCard extends ConsumerWidget {
  final Product product;
  final int index;
  final Category currentCategory;

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
        // onTapは商品詳細ダイアログを表示する既存の処理を流用
        onTap: () => showProductDialog(context, product),
        // ProductCardの見た目は SearchPage と同じUI（CircleAvatar, タイトル, サブタイトル）
        margin: EdgeInsets.symmetric(
            vertical: context.paddingMedium, horizontal: context.paddingMedium),
      ),
    );
  }
}

// SavedItemCard：保存した単語一覧用のカードウィジェット
// ProductCardと同じ見た目を利用し、ReorderableDelayedDragStartListenerで
// カード全体を長押しでドラッグ可能にしています。
class SavedItemCard extends ConsumerWidget {
  final Product product;
  final int index;

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
            vertical: context.paddingMedium, horizontal: context.paddingMedium),
      ),
    );
  }
}

// ☆ 修正後の CategoryItemsPageState
// ・従来のCategoryItemWidget（Dismissible や長押し削除処理付き）を廃止して
// 　新規ウィジェット CategoryItemCard を利用します。
// ・リスト項目は ProductCard の見た目をそのまま利用
class CategoryItemsPageState extends ConsumerState<CategoryItemsPage> {
  bool _isSorting = false; // 並び替えモードを管理するフラグ

  @override
  Widget build(BuildContext context) {
    // 現在のカテゴリ情報を取得（最新のもので上書き）
    final allCategories = ref.watch(categoriesProvider);
    final currentCategory = allCategories.firstWhere(
      (cat) => cat.name == widget.category.name,
      orElse: () => widget.category,
    );
    // assets側のプロダクトやユーザー追加分などを統合した全商品一覧
    final allProducts = ref.watch(allProductsProvider);
    // カテゴリーに登録済みの商品一覧（順番は currentCategory.products の順）
    final filtered = currentCategory.products.map((productName) {
      return allProducts.firstWhere((p) => p.name == productName);
    }).toList();

    // カテゴリー名は後々各処理に利用するため変数に格納
    final categoryName = currentCategory.name;

    return Scaffold(
      appBar: AppBar(
        title: Text("カテゴリー: $categoryName"),
        centerTitle: true,
        actions: [
          // 並び替えモード中はチェックアイコンを表示し、そのタップで通常モードに戻す
          if (_isSorting)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                setState(() {
                  _isSorting = false;
                });
              },
            )
        ],
      ),
      body: filtered.isEmpty
          ? const Center(child: Text("このカテゴリーに商品はありません"))
          : _isSorting
              ? _buildSortingList(filtered, categoryName)
              : _buildNormalList(filtered, categoryName),
    );
  }

  /// 通常モード：WordListPage と同じ単語リスト表示
  /// 通常モード：各カテゴリーに登録済みの商品のリスト表示
  Widget _buildNormalList(List<Product> products, String categoryName) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return SwipeToDeleteCard(
          keyValue: ValueKey(product.name),
          // 削除前に確認ダイアログを表示
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
          // 削除が確定した際、商品割当状態を更新（削除）
          onDismissed: () async {
            await ref
                .read(categoriesProvider.notifier)
                .updateProductAssignment(categoryName, product.name, false);
          },
          // 子ウィジェットには元々のProductCard（長押し時の下部シート表示付き）を配置
          child: GestureDetector(
            onLongPress: () {
              // 長押し時に表示するアクションシート
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
                  horizontal: context.paddingExtraSmall),
              onTap: () => showProductDialog(context, product),
            ),
          ),
        );
      },
    );
  }

  /// 並び替えモード：ドラッグで並び替え可能なリスト表示
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
          // 並び替え状態ではsubtitleを表示せず、nameのみ表示
          title: Text(
            product.name,
            style: TextStyle(
              fontSize: context.fontSizeMedium,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Google Play Console のようなシンプルなデザインにするため、余分な情報は削除
          onTap: () => showProductDialog(context, product),
        );
      },
    );
  }
}

/// チェックした問題（再テスト対象）の状態を永続化するプロバイダー
class CheckedQuestionsNotifier extends StateNotifier<Set<String>> {
  CheckedQuestionsNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('checked_questions') ?? [];
    // ロードした結果と既存の state をマージする
    state = state.union(list.toSet());
  }

  Future<void> add(String productName) async {
    if (!state.contains(productName)) {
      state = {...state, productName};
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('checked_questions', state.toList());
    }
  }

  Future<void> remove(String productName) async {
    if (state.contains(productName)) {
      state = state.where((name) => name != productName).toSet();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('checked_questions', state.toList());
    }
  }

  Future<void> toggle(String productName) async {
    if (state.contains(productName)) {
      await remove(productName);
    } else {
      await add(productName);
    }
  }
}

final checkedQuestionsProvider =
    StateNotifierProvider<CheckedQuestionsNotifier, Set<String>>(
        (ref) => CheckedQuestionsNotifier());

// まず、必ず WidgetsBinding を初期化
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

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
      home: const SearchPage(),
    );
  }
}

// ユーザーが追加した商品を管理する Notifier
class CustomProductsNotifier extends StateNotifier<List<Product>> {
  CustomProductsNotifier() : super([]) {
    _loadCustomProducts();
  }

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

  Future<void> addProduct(Product product) async {
    state = [...state, product];
    final prefs = await SharedPreferences.getInstance();
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

final customProductsProvider =
    StateNotifierProvider<CustomProductsNotifier, List<Product>>(
        (ref) => CustomProductsNotifier());

final allProductsProvider = Provider<List<Product>>((ref) {
  final assetProductsAsync = ref.watch(productsProvider);
  final customProducts = ref.watch(customProductsProvider);
  List<Product> assetProducts = [];

  // assets側のデータが読み込まれている場合のみ統合
  assetProductsAsync.when(
    data: (products) => assetProducts = products,
    loading: () {},
    error: (_, __) {},
  );
  return [...assetProducts, ...customProducts];
});

/// 単語検索ページ
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _controller = TextEditingController();

  // 検索クエリが空の場合に利用するランダムな商品リストのキャッシュ
  List<Product>? _cachedRandomProducts;

  // 並び替えモード用の状態変数
  final bool _isSorting = false;
  List<Product>? _sortedProducts;

  Future<void> _onRefresh() async {
    _cachedRandomProducts = null; // キャッシュクリア
    await Future.delayed(const Duration(milliseconds: 1000));
    ref.invalidate(productsProvider);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 長押し時に表示するアクションシート（既存処理）
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
                leading: const Icon(Icons.check_box),
                title: const Text("単語チェック問題に登録する"),
                onTap: () {
                  Navigator.pop(context);
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
                FocusScope.of(context).unfocus();
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
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              // 検索入力フィールド
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
              // 単語リスト部分（既存処理）
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
                    filteredProducts = products.where((p) {
                      final query = searchQuery.toLowerCase();
                      return p.name.toLowerCase().contains(query) ||
                          p.yomigana.toLowerCase().contains(query);
                    }).toList();
                  } else {
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

/// 単語テストページ（10問出題）
class WordTestPage extends ConsumerStatefulWidget {
  const WordTestPage({super.key});

  @override
  ConsumerState<WordTestPage> createState() => _WordTestPageState();
}

class _WordTestPageState extends ConsumerState<WordTestPage> {
  List<WordTestQuestion> quiz = [];
  int currentQuestionIndex = 0;

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
                Text(
                  "問題 ${currentQuestionIndex + 1} / ${quiz.length}",
                  style: TextStyle(
                      fontSize: context.fontSizeExtraLarge,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  "問題：${currentQuestion.product.description}",
                  style: TextStyle(fontSize: context.fontSizeMedium),
                ),
                const SizedBox(height: 24),
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
                              if (!currentQuestion.isCorrect) {
                                // 回答が不正解の場合、ミス回数を更新
                                ref
                                    .read(mistakeCountsProvider.notifier)
                                    .increment(currentQuestion.product.name);
                              }
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
                      child: Text(option,
                          style: TextStyle(fontSize: context.fontSizeMedium)),
                    ),
                  );
                }),
                const SizedBox(height: 16),
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

// 修正例：テスト結果画面に遷移元を識別するフラグを追加
class WordTestResultPage extends ConsumerWidget {
  final List<WordTestQuestion> quiz;
  final bool isCheckboxTest; // チェックボックス問題からのテストかどうかのフラグ

  const WordTestResultPage({
    super.key,
    required this.quiz,
    this.isCheckboxTest = false, // デフォルトは単語テストとして扱う
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int correctCount = quiz.where((q) => q.isCorrect).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text("テスト結果"),
      ),
      body: Padding(
        padding: EdgeInsets.all(context.paddingSmall),
        child: Column(
          children: [
            Text(
              "結果：$correctCount / ${quiz.length} 問正解",
              style: TextStyle(
                fontSize: context.fontSizeExtraLarge,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 20),

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
                              Text(
                                "問題 ${index + 1}",
                                style: TextStyle(
                                  fontSize: context.fontSizeExtraLarge,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                question.product.description,
                                style:
                                    TextStyle(fontSize: context.fontSizeSmall),
                              ),
                              const SizedBox(height: 12),
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
            // ホームへ戻るボタンなど
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
                    // 遷移元に応じて画面を分岐
                    if (isCheckboxTest) {
                      // チェックボックス問題から遷移してきたときは、
                      // 出題数も同じ設定（例：generateQuizQuestionsで指定している件数）にして再度チェックボックス問題へ
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CheckboxTestPage()),
                      );
                    } else {
                      // 単語テストの場合
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

class CheckedQuestionsPage extends ConsumerStatefulWidget {
  const CheckedQuestionsPage({super.key});

  @override
  CheckedQuestionsPageState createState() => CheckedQuestionsPageState();
}

class CheckedQuestionsPageState extends ConsumerState<CheckedQuestionsPage> {
  final bool _isSorting = false;
  List<Product>? _sortedProducts; // 並び替え用の一時リスト

  @override
  Widget build(BuildContext context) {
    // チェック済みの単語（問題として登録された単語）のセットを取得
    final checked = ref.watch(checkedQuestionsProvider);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("単語チェック問題"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 上部固定：チェック済みの単語が1件でもある場合のみ「問題出題」ボタンが活性状態となる
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
              // checked.isEmptyならonPressedがnullとなり、非活性状態になる
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
          // 下部：チェック済みの単語リストを表示
          Padding(
            padding: EdgeInsets.only(top: context.paddingExtraLarge * 2.5),
            child: Padding(
              padding: EdgeInsets.all(context.paddingExtraSmall),
              child: productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text("データ読み込みエラー: $error")),
                data: (products) {
                  // ここではProductリストから、チェック済み（checkedに含まれる）商品を抽出
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

  /// 長押し時に表示するボトムシート
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

class CheckboxTestPage extends ConsumerStatefulWidget {
  const CheckboxTestPage({super.key});

  @override
  ConsumerState<CheckboxTestPage> createState() => _CheckboxTestPageState();
}

class _CheckboxTestPageState extends ConsumerState<CheckboxTestPage> {
  List<WordTestQuestion> quiz = [];
  int currentQuestionIndex = 0;

  // 追加：各問題の解答処理を一度だけ実行するためのフラグ
  bool _isAnswered = false;

  void _generateQuiz(List<Product> products, Set<String> checked) {
    final filteredProducts =
        products.where((p) => checked.contains(p.name)).toList();
    if (filteredProducts.isEmpty) return;
    quiz = generateQuizQuestions(filteredProducts, products, quizCount: 10);
    currentQuestionIndex = 0;
    _isAnswered = false; // 新しい問題開始時にフラグをリセット
  }

  @override
  Widget build(BuildContext context) {
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
                Text(
                  "問題 ${currentQuestionIndex + 1} / ${quiz.length}",
                  style: TextStyle(
                      fontSize: context.fontSizeExtraLarge,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  "問題：${currentQuestion.product.description}",
                  style: TextStyle(fontSize: context.fontSizeMedium),
                ),
                const SizedBox(height: 24),
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
                              setState(() {
                                currentQuestion.userAnswer = option;
                              });
                              // 不正解の場合は、ここで1回だけミス数を更新
                              if (!currentQuestion.isCorrect) {
                                await ref
                                    .read(mistakeCountsProvider.notifier)
                                    .increment(currentQuestion.product.name);
                              }
                              await Future.delayed(const Duration(seconds: 1));
                              if (currentQuestionIndex < quiz.length - 1) {
                                setState(() {
                                  currentQuestionIndex++;
                                  _isAnswered = false; // 次の問題開始時にリセット
                                });
                              } else {
                                // CheckboxTestPage内での遷移例
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WordTestResultPage(
                                        quiz: quiz, isCheckboxTest: true),
                                  ),
                                );
                              }
                            }
                          : null,
                      child: Text(option,
                          style: TextStyle(fontSize: context.fontSizeMedium)),
                    ),
                  );
                }),
                const SizedBox(height: 16),
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

class SavedItemsPage extends ConsumerWidget {
  const SavedItemsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          // 保存リストに沿って対象の Product を抽出
          final savedProducts = savedItems
              .where((name) => allProducts.any((p) => p.name == name))
              .map((name) => allProducts.firstWhere((p) => p.name == name))
              .toList();

          return CommonProductListView(
            products: savedProducts,
            itemBuilder: (context, product) {
              return SwipeToDeleteCard(
                keyValue: ValueKey(product.name),
                // 削除前に確認ダイアログを表示
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
                // 削除が確定した際の処理
                onDismissed: () async {
                  await ref
                      .read(savedItemsProvider.notifier)
                      .removeItem(product.name);
                },
                // 子ウィジェットは、タップ時は詳細ダイアログを表示、長押し時に下部シートで追加アクションを表示
                child: GestureDetector(
                  onLongPress: () {
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
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text("既に単語チェック問題に登録されています。"),
                                  ));
                                } else {
                                  ref
                                      .read(checkedQuestionsProvider.notifier)
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
                      ),
                    );
                  },
                  child: ProductCard(
                    product: product,
                    onTap: () => showProductDialog(context, product),
                    margin: EdgeInsets.symmetric(
                        vertical: context.paddingExtraSmall,
                        horizontal: context.paddingExtraSmall),
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

class SavedItemsPageState extends ConsumerState<SavedItemsPage> {
  // 並び替えモードのフラグ（初期状態は通常モード）
  bool _isSorting = false;

  @override
  Widget build(BuildContext context) {
    final savedItems = ref.watch(savedItemsProvider);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('保存単語'),
        centerTitle: true,
        actions: [
          // 並び替えモード中は「完了（チェックアイコン）」、通常モードでは「並び替え（ソートアイコン）」を表示
          IconButton(
            icon: _isSorting ? const Icon(Icons.check) : const Icon(null),
            onPressed: () {
              // アイコン押下で並び替えモードのオン／オフを切り替え
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
            // 保存済みリストに沿って対象 Product を抽出
            final savedProducts = savedItems
                .where((itemName) => products.any((p) => p.name == itemName))
                .map((itemName) =>
                    products.firstWhere((p) => p.name == itemName))
                .toList();

            if (savedProducts.isEmpty) {
              return const Center(child: Text('保存された単語はありません'));
            }

            if (_isSorting) {
              // ※ 並び替えモード：ReorderableListView を利用
              return ReorderableListView.builder(
                itemCount: savedProducts.length,
                onReorder: (oldIndex, newIndex) async {
                  if (newIndex > oldIndex) newIndex--;
                  // 並び替え後のリスト順を savedItemsProvider に反映
                  List<String> newOrder = List.from(savedItems);
                  final item = newOrder.removeAt(oldIndex);
                  newOrder.insert(newIndex, item);
                  await ref
                      .read(savedItemsProvider.notifier)
                      .reorderItems(newOrder);
                },
                itemBuilder: (context, index) {
                  final product = savedProducts[index];
                  // 並び替えモードでは、カード全体は ListTile（もしくは ProductCard の見た目に近いもの）にして、
                  // 右側のアイコンをドラッグハンドル（二点アイコン）に変更
                  return ListTile(
                    key: ValueKey(product.name),
                    // ドラッグ可能なアイコン
                    leading: const Icon(Icons.drag_handle),
                    title: Text(product.name),
                    subtitle: Text(product.description),
                    // タップ時は商品詳細ダイアログを表示。※UIの他の部分はそのまま
                    onTap: () => showProductDialog(context, product),
                  );
                },
              );
            } else {
              // ※ 通常モード：元の ListView.builder を利用し、長押しで下部シート表示
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
                        // 長押し時に下部シートで各アクションを表示
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
                                      // 保存するでカテゴリー割当シートを表示
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
                                      // チェック問題に既に登録済みか確認
                                      final currentChecked =
                                          ref.read(checkedQuestionsProvider);
                                      if (currentChecked
                                          .contains(product.name)) {
                                        // 既に存在している場合は状態を変更せずに通知する
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text("既に単語チェック問題に登録されています。"),
                                          ),
                                        );
                                      } else {
                                        // 未登録の場合のみ追加
                                        ref
                                            .read(checkedQuestionsProvider
                                                .notifier)
                                            .add(product.name);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
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
                                      // 並び替えモードに切り替え
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

class CategorySelectionPage extends ConsumerStatefulWidget {
  const CategorySelectionPage({super.key});

  @override
  CategorySelectionPageState createState() => CategorySelectionPageState();
}

class CategorySelectionPageState extends ConsumerState<CategorySelectionPage> {
  // 並び替えモードかどうかを管理するフラグ
  bool _isReordering = false;

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);

    Widget listWidget;
    if (_isReordering) {
      // 並び替えモード：ReorderableListView.builder でドラッグ操作可能
      listWidget = ReorderableListView.builder(
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
                  builder: (_) => CategoryItemsPage(category: cat),
                ),
              );
            },
          );
        },
      );
    } else {
      // 通常モード：SwipeToDeleteCard 内の ListTile に長押しでオプションを表示
      listWidget = ListView.builder(
        padding: EdgeInsets.symmetric(vertical: context.paddingMedium),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return SwipeToDeleteCard(
            keyValue: ValueKey(cat.name),
            // スワイプした際の削除確認ダイアログ
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
                    builder: (_) => CategoryItemsPage(category: cat),
                  ),
                );
              },
              // 長押しで下部シートを表示（名称変更、削除、並び替え）
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
          // 並び替えモード中はチェックアイコンを表示して通常モードに戻す
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

  /// 長押し時に表示するボトムシート（名称変更・削除・並び替えの各オプション）
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

  /// カテゴリー名称変更用ダイアログ
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

class CategoryAssignmentSheet extends ConsumerStatefulWidget {
  final Product product;

  const CategoryAssignmentSheet({super.key, required this.product});

  @override
  CategoryAssignmentSheetState createState() => CategoryAssignmentSheetState();
}

class CategoryAssignmentSheetState
    extends ConsumerState<CategoryAssignmentSheet> {
  // ローカルで各カテゴリーのチェック状態を保持（キーはカテゴリー名）
  late Map<String, bool> _localAssignments;

  // 「保存した単語一覧」のローカル状態
  late bool _localSaved;

  @override
  void initState() {
    super.initState();
    // 初期状態として、プロバイダーから現在の状態を取得
    // ref.read() は initState 内でも使えます
    final currentCategories = ref.read(categoriesProvider);
    _localAssignments = {
      for (var cat in currentCategories)
        cat.name: cat.products.contains(widget.product.name)
    };
    final currentSaved = ref.read(savedItemsProvider);
    _localSaved = currentSaved.contains(widget.product.name);
  }

  @override
  Widget build(BuildContext context) {
    // 再度カテゴリー一覧を取得（変更があった場合に備える）
    final categories = ref.watch(categoriesProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(context.paddingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // タイトル行：左にタイトル、右に「＋新規カテゴリーを追加」ボタン
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
                    final newCat = await showCategoryCreationDialog(context);
                    if (newCat != null && newCat.isNotEmpty) {
                      // 新規カテゴリーを追加
                      await ref
                          .read(categoriesProvider.notifier)
                          .addCategory(newCat);
                      // 新規カテゴリー追加後、ローカル状態にも追加（初期は割当無し）
                      setState(() {
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
            // 保存した単語一覧チェックボックス（ローカル状態で保持）
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
            // カテゴリーリスト（各カテゴリーのチェック状態もローカル管理）
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  // ローカル状態に存在しない場合は、初期値としてfalseを設定
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
            // 下部「完了」ボタン：完了ボタンが押されたときにプロバイダーへ更新を反映
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () async {
                // 各カテゴリーについてローカル状態をもとに更新
                for (var entry in _localAssignments.entries) {
                  await ref
                      .read(categoriesProvider.notifier)
                      .updateProductAssignment(
                        entry.key,
                        widget.product.name,
                        entry.value,
                      );
                }
                // 保存状態も更新
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

/// ---------------------
/// CategoryItemsPage
/// ---------------------
///
// CategoryItemsPageをStatefulWidgetに変更
class CategoryItemsPage extends ConsumerStatefulWidget {
  final Category category;

  const CategoryItemsPage({super.key, required this.category});

  @override
  CategoryItemsPageState createState() => CategoryItemsPageState();
}

class AddItemToCategoryDialog extends ConsumerWidget {
  final Category category;

  const AddItemToCategoryDialog({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 全商品一覧から、既にカテゴリーに入っていない商品の名前を抽出
    final allProducts = ref.watch(allProductsProvider);
    final availableOptions = allProducts
        .where((p) => !category.products.contains(p.name))
        .map((p) => p.name)
        .toList();

    return AlertDialog(
      title: const Text("商品を追加"),
      content: Autocomplete<String>(
        // 候補の絞り込み（入力に応じて）
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.trim().isEmpty) {
            return availableOptions;
          }
          return availableOptions.where((option) => option
              .toLowerCase()
              .contains(textEditingValue.text.toLowerCase()));
        },
        // ユーザーが候補を選択したタイミング
        onSelected: (String selected) async {
          await ref
              .read(categoriesProvider.notifier)
              .updateProductAssignment(category.name, selected, true);
          Navigator.of(context).pop();
        },
        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: const InputDecoration(
              labelText: "商品を検索",
              border: OutlineInputBorder(),
            ),
            onEditingComplete: onEditingComplete,
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("キャンセル"),
        ),
      ],
    );
  }
}

class AddProductDialog extends StatefulWidget {
  const AddProductDialog({super.key});

  @override
  AddProductDialogState createState() => AddProductDialogState();
}

class AddProductDialogState extends State<AddProductDialog> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("新規商品追加"),
      content: TextField(
        controller: _nameController,
        decoration: const InputDecoration(labelText: "商品名"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("キャンセル"),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isNotEmpty) {
              // 商品名のみでProductインスタンスを生成（読み仮名、説明は空文字）
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

class MistakeCountNotifier extends StateNotifier<Map<String, int>> {
  MistakeCountNotifier() : super({}) {
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('mistake_counts');
    if (data != null) {
      state = Map<String, int>.from(jsonDecode(data));
    }
  }

  Future<void> increment(String productName) async {
    final current = state[productName] ?? 0;
    state = {...state, productName: current + 1};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mistake_counts', jsonEncode(state));
  }
}

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

/// 代表的な勘定科目の選択肢（必要に応じて追加）
const List<String> accountOptions = [
  // ＜資産＞
  "仕入",
  "現金",
  "当座預金",
  "普通預金",
  "未収入金",
  "売掛金",
  "受取手形",
  "仕掛品",
  "製品",
  "材料",
  "備品",
  "建物",
  "建物減価償却累計額",
  "ソフトウェア",
  "ソフトウェア償却費",
  "売買目的有価証券",
  "有価証券評価損",
  "有価証券売却益",
  "満期保有目的債券",
  "有価証券利息",
  "繰延税金資産",

  // ＜負債＞
  "買掛金",
  "支払手形",
  "長期借入金",
  "未払金",
  "仮払法人税等",
  "未払消費税",
  "未払法人税等",
  "退職給付引当金",
  "リース債務",
  "資産除去債務",
  "前受金",
  "未払利息",
  "貸倒引当金",
  "貸倒引当金繰入",

  // ＜純資産／資本＞
  "資本金",
  "資本準備金",
  "その他資本剰余金",
  "非支配株主持分",
  "新株予約権",

  // ＜収益＞
  "売上",
  "仮受消費税",
  "受取利息",
  "為替差益",
  "投資有価証券売却益",
  "役務収益",
  "クレジット売掛金",

  // ＜費用＞
  "給料",
  "所得税預り金",
  "社会保険料預り金",
  "支払家賃",
  "広告宣伝費",
  "仮払金",
  "旅費交通費",
  "支払保険料",
  "退職給付費用",
  "貸倒損失",
  "減価償却費",
  "減損損失",
  "修繕費",
  "株式報酬費用",
  "社債発行費",
  "固定資産売却損",
  "国庫補助金受贈益",
  "保険差益",
  "手形売却損",
  "仕入割引",
  "売上割引",
  "仕損品",
  "異常仕損損失",
  "雑収入",
  "材料受入価格差異",
  "材料費数量差異",
  "労務費賃率差異",
  "労務費時間差異",
  "製造間接費",
  "製造間接費予算差異",
  "製造間接費能率差異",
  "製造間接費操業度差異",
  "製造間接費配賦差異",
  "売上原価",
  "賃金",
  "未払賃金",
  "預り金",
  "固定製造間接費",
  "固定販売費及び一般管理費",

  // ＜その他＞
  "建設仮勘定",
  "為替予約",
  "デリバティブ評価益",
  "電子記録債権",
  "電子記録債権売却損",
  "電子記録債務",
];

/// 各仕訳の正解エントリーを表す
class JournalEntry {
  final String side; // 「借方」または「貸方」
  final String account; // 勘定科目
  final int amount; // 金額

  JournalEntry({
    required this.side,
    required this.account,
    required this.amount,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      side: json['side'] as String,
      account: json['account'] as String,
      amount: json['amount'] as int,
    );
  }
}

/// 仕訳問題（取引）のデータモデル
class SortingProblem {
  final String id;
  final String transactionDate;
  final String description;
  final List<JournalEntry> entries;
  final String feedback;
  final String bookkeepingType; // 新たに追加

  SortingProblem({
    required this.id,
    required this.transactionDate,
    required this.description,
    required this.entries,
    required this.feedback,
    required this.bookkeepingType,
  });

  factory SortingProblem.fromJson(Map<String, dynamic> json) {
    final entriesJson = json['entries'] as List;
    return SortingProblem(
      id: json['id'] as String,
      transactionDate: json['transaction_date'] as String,
      description: json['description'] as String,
      entries: entriesJson.map((e) => JournalEntry.fromJson(e)).toList(),
      feedback: json['feedback'] as String,
      bookkeepingType: json['bookkeepingType'] as String, // ここで読み込む
    );
  }
}

/// JSONファイル（assets/siwake.json）から仕訳問題リストを読み込むProvider
final sortingProblemsProvider =
    FutureProvider<List<SortingProblem>>((ref) async {
  final data = await rootBundle.loadString('assets/siwake.json');
  final List<dynamic> jsonResult = jsonDecode(data);
  return jsonResult.map((json) => SortingProblem.fromJson(json)).toList();
});

/// ─────────────────────────────────────────────
/// ユーザーが問題に解答するウィジェット【左右レイアウト：左→借方、右→貸方】
/// ─────────────────────────────────────────────
class JournalEntryQuizWidget extends StatefulWidget {
  final SortingProblem problem;
  final Function(bool) onSubmitted; // 正誤結果のコールバック

  const JournalEntryQuizWidget({
    super.key,
    required this.problem,
    required this.onSubmitted,
  });

  @override
  State<JournalEntryQuizWidget> createState() => _JournalEntryQuizWidgetState();
}

class _JournalEntryQuizWidgetState extends State<JournalEntryQuizWidget> {
  // 正解の仕訳を「借方」と「貸方」に分割
  late final List<JournalEntry> debitAnswers;
  late final List<JournalEntry> creditAnswers;

  // すべてのエントリーから共通の勘定科目リストを作成
  late final List<String> commonAccountOptions;

  // ユーザー入力（借方）
  late List<String?> userDebitAccounts;
  late List<TextEditingController> debitAmountControllers;

  // ユーザー入力（貸方）
  late List<String?> userCreditAccounts;
  late List<TextEditingController> creditAmountControllers;

  bool? isAnswerCorrect;

  @override
  void initState() {
    super.initState();
    debitAnswers =
        widget.problem.entries.where((entry) => entry.side == "借方").toList();
    creditAnswers =
        widget.problem.entries.where((entry) => entry.side == "貸方").toList();
    // 借方・貸方共通の勘定科目リスト（重複除外）
    commonAccountOptions =
        widget.problem.entries.map((e) => e.account).toSet().toList();

    userDebitAccounts = List.filled(debitAnswers.length, null);
    debitAmountControllers =
        List.generate(debitAnswers.length, (_) => TextEditingController());

    userCreditAccounts = List.filled(creditAnswers.length, null);
    creditAmountControllers =
        List.generate(creditAnswers.length, (_) => TextEditingController());
  }

  @override
  void dispose() {
    for (var ctrl in debitAmountControllers) {
      ctrl.dispose();
    }
    for (var ctrl in creditAmountControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void submitAnswer() {
    // 入力漏れチェック（借方）
    for (int i = 0; i < userDebitAccounts.length; i++) {
      if (userDebitAccounts[i] == null ||
          debitAmountControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("借方のすべての項目を選択してください")),
        );
        return;
      }
    }
    // 入力漏れチェック（貸方）
    for (int i = 0; i < userCreditAccounts.length; i++) {
      if (userCreditAccounts[i] == null ||
          creditAmountControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("貸方のすべての項目を選択してください")),
        );
        return;
      }
    }

    List<Map<String, dynamic>> userDebitList = [];
    for (int i = 0; i < userDebitAccounts.length; i++) {
      // 金額入力フィールドのテキストからカンマを取り除く
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

    bool debitCorrect = _isListEqual(userDebitList, correctDebitList);
    bool creditCorrect = _isListEqual(userCreditList, correctCreditList);

    setState(() {
      isAnswerCorrect = debitCorrect && creditCorrect;
    });
    widget.onSubmitted(isAnswerCorrect!);
  }

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
  } // 左側（借方エントリー）のウィジェット

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
          // ここで勘定科目の DropdownButtonFormField のコードは変わらず
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
          // 金額入力フィールドに電卓アイコンを追加
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
              suffixIcon: IconButton(
                icon: const Icon(Icons.calculate),
                onPressed: () async {
                  // 現在入力されている内容（カンマを除去して数値に変換）
                  double initialValue = double.tryParse(
                          debitAmountControllers[index]
                              .text
                              .replaceAll(',', '')
                              .trim()) ??
                      0;
                  // 電卓ウィジェットをモーダルボトムシートで表示
                  final result = await showModalBottomSheet<double>(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) =>
                        CalculatorWidget(initialValue: initialValue),
                  );
                  if (result != null) {
                    // 結果をカンマ区切りでフォーマットしてフィールドに反映
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

// 右側（貸方エントリー）のウィジェット
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
          // 貸方金額入力フィールドに Calculator を実装
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
                  // 入力中のテキストからカンマを除去して数値に変換
                  double initialValue = double.tryParse(
                          creditAmountControllers[index]
                              .text
                              .replaceAll(',', '')
                              .trim()) ??
                      0;
                  // CalculatorWidget をモーダルボトムシートとして表示
                  final result = await showModalBottomSheet<double>(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) =>
                        CalculatorWidget(initialValue: initialValue),
                  );
                  if (result != null) {
                    // 結果をカンマ付きでフォーマットしてテキストフィールドに反映
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
                  // キーボードを閉じる
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

class CalculatorWidget extends StatefulWidget {
  /// CalculatorWidget の初期値は常に 0 からスタート
  final double initialValue;

  const CalculatorWidget({super.key, this.initialValue = 0});

  @override
  CalculatorWidgetState createState() => CalculatorWidgetState();
}

class CalculatorWidgetState extends State<CalculatorWidget> {
  String display = '0';

  @override
  void initState() {
    super.initState();
    display = '0';
  }

  /// 数式の評価結果をフォーマットするヘルパー
  String formatResult(double result) {
    if (result == result.toInt()) {
      return result.toInt().toString();
    } else {
      return result.toString();
    }
  }

  /// キー押下の処理
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
          // 整数なら小数点以下を省略
          display = formatResult(result);
        } catch (e) {
          display = "Error";
        }
      } else {
        // もし display が "0" または "Error" の場合、数字または小数点入力なら上書き
        if ((display == "0" || display == "Error") &&
            "0123456789.".contains(key)) {
          display = key;
        } else {
          display += key;
        }
      }
    });
  }

  /// キー用のボタンウィジェット
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
    // 5行×4列のキーリスト（最後のキーは空文字にして余白として利用）
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
      height: 500, // ModalBottomSheetに合わせた高さ（調整可能）
      child: Column(
        children: [
          // 入力結果表示部
          Container(
            padding: EdgeInsets.all(context.paddingMedium),
            alignment: Alignment.centerRight,
            child: Text(
              display,
              style: TextStyle(fontSize: context.fontSizeMedium),
            ),
          ),
          const Divider(),
          // キーパッド部分：4列グリッド
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
          // 「確定」ボタン：このボタンを押すと現在の計算結果が呼び出し元に返される
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
              // 結果のフォーマット
              String formatted = formatResult(result);
              // 呼び出し元に返す
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
}

class CommonProductListView extends StatelessWidget {
  /// 表示する商品のリスト
  final List<Product> products;

  /// 各アイテムのウィジェットを生成するためのビルダー
  final Widget Function(BuildContext context, Product product) itemBuilder;

  /// プル・トゥ・リフレッシュ処理（オプション）
  final Future<void> Function()? onRefresh;

  /// 並び替え可能な表示にする際のフラグ
  final bool isReorderable;

  /// 並び替え時のコールバック（trueの場合は必須）
  final void Function(int oldIndex, int newIndex)? onReorder;

  const CommonProductListView({
    super.key,
    required this.products,
    required this.itemBuilder,
    this.onRefresh,
    this.isReorderable = false,
    this.onReorder,
  }) : assert(!isReorderable || onReorder != null,
            'Reorderableの場合、onReorderは必須です');

  @override
  Widget build(BuildContext context) {
    // 並び替えが有効であればReorderableListViewを利用
    Widget list;
    if (isReorderable) {
      list = ReorderableListView.builder(
        itemCount: products.length,
        onReorder: onReorder!,
        itemBuilder: (context, index) {
          final product = products[index];
          // ReorderableListViewでは各アイテムにKeyが必要
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

    // RefreshIndicatorが設定されていればラップして返す
    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        child: list,
      );
    }
    return list;
  }
}

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
          // 検索クエリが空ならランダム表示、入力があればフィルター表示
          final filteredProducts = (searchQuery.isNotEmpty)
              ? products
                  .where((p) =>
                      p.name
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()) ||
                      p.yomigana
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()))
                  .toList()
              : products; // 例として全件表示

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

/// 設定画面：FutureBuilderで初回設定値を読み込んでからフォームウィジェットに渡す
class SettingsPage extends ConsumerWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studySettings = ref.watch(studySettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("設定"),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("勉強開始時間を有効にする"),
            value: studySettings.enableStudyStartTime,
            onChanged: (value) {
              ref
                  .read(studySettingsProvider.notifier)
                  .setEnableStudyStartTime(value);
            },
          ),
          if (studySettings.enableStudyStartTime)
            ListTile(
              title: const Text("勉強開始時間"),
              subtitle: Text(studySettings.studyStartTime),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                // 現在設定されている時刻を TimeOfDay に変換
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
                  // 時刻を "HH:mm" 形式にフォーマット
                  final formatted =
                      "${chosenTime.hour.toString().padLeft(2, '0')}:${chosenTime.minute.toString().padLeft(2, '0')}";
                  ref
                      .read(studySettingsProvider.notifier)
                      .setStudyStartTime(formatted);
                }
              },
            ),
          // 他の設定項目があればここに追加・・・
        ],
      ),
    );
  }
}

// 勉強開始時間設定用のモデル
class StudySettings {
  final bool enableStudyStartTime;
  final String studyStartTime; // "HH:mm" 形式

  StudySettings({
    required this.enableStudyStartTime,
    required this.studyStartTime,
  });
}

// StateNotifier を使って状態管理（SharedPreferences への保存も実施）
class StudySettingsNotifier extends StateNotifier<StudySettings> {
  StudySettingsNotifier()
      : super(StudySettings(
            enableStudyStartTime: false, studyStartTime: "08:00")) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    bool enabled = prefs.getBool('study_enableStartTime') ?? false;
    String startTime = prefs.getString('study_startTime') ?? "08:00";
    state =
        StudySettings(enableStudyStartTime: enabled, studyStartTime: startTime);
  }

  Future<void> setEnableStudyStartTime(bool value) async {
    state = StudySettings(
        enableStudyStartTime: value, studyStartTime: state.studyStartTime);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('study_enableStartTime', value);
  }

  Future<void> setStudyStartTime(String time) async {
    state = StudySettings(
        enableStudyStartTime: state.enableStudyStartTime, studyStartTime: time);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('study_startTime', time);
  }
}

// Riverpod 用のプロバイダー
final studySettingsProvider =
    StateNotifierProvider<StudySettingsNotifier, StudySettings>(
        (ref) => StudySettingsNotifier());
