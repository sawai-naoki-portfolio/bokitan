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
