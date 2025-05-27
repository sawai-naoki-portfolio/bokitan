import 'package:bookkeeping_vocabulary_notebook/utility/ResponsiveSizes.dart';
import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ヘルプ"),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          "ヘルプ画面（実装予定）",
          style: TextStyle(fontSize: context.fontSizeMedium),
        ),
      ),
    );
  }
}
