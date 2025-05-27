
import 'dart:io';
import 'dart:ui';

import 'package:bookkeeping_vocabulary_notebook/utility/ResponsiveSizes.dart';
import 'package:bookkeeping_vocabulary_notebook/view/widget/showMemoDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../utility/MemoDisplay.dart';
import '../../utility/Product.dart';

/// ---------------------------------------------------------------------------
/// showProductDialog
/// ─ 単語の詳細ダイアログを表示するウィジェット。
///   内部でStatefulBuilderを用いて、最新のメモ情報などの再描画を最小限の範囲で実施。
/// ---------------------------------------------------------------------------
void showProductDialog(BuildContext context, Product product) {
  final GlobalKey dialogKey = GlobalKey();

  showDialog(
    context: context,
    builder: (context) {
      return RepaintBoundary(
        key: dialogKey,
        child: StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
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
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () async {
                      // product 情報も渡すように変更
                      await _captureAndShareDialog(dialogKey, context, product);
                    },
                  ),
                ],
              ),
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
        ),
      );
    },
  );
}

/// キャプチャして画像ファイルに保存後、SNS共有
/// // まず、_captureAndShareDialog のシグネチャを変更して product を受け取るようにします。
Future<void> _captureAndShareDialog(
    GlobalKey key, BuildContext context, Product product) async {
  try {
    // GlobalKeyからRepaintBoundaryを取得
    RenderRepaintBoundary? boundary =
    key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    // 画面のピクセル比に合わせて画像をキャプチャ
    double pixelRatio = MediaQuery.of(context).devicePixelRatio;
    var image = await boundary.toImage(pixelRatio: pixelRatio);
    ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
    if (byteData == null) return;
    Uint8List pngBytes = byteData.buffer.asUint8List();

    // 一時ディレクトリに画像を書き出す
    final tempDir = await getTemporaryDirectory();
    final file = await File(
        '${tempDir.path}/dialog_${DateTime.now().millisecondsSinceEpoch}.png')
        .create();
    await file.writeAsBytes(pngBytes);

    // 共有テキストは商品名と説明を組み合わせる
    String shareText = '【${product.name}】\n${product.description}\n#簿記単';

    // クリップボードに共有テキストを保存
    await Clipboard.setData(ClipboardData(text: shareText));

    // Share.shareXFiles により画像とテキストを共有する
    await Share.shareXFiles([XFile(file.path)], text: shareText);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("画像のキャプチャ/共有に失敗しました: $e")),
    );
  }
}
