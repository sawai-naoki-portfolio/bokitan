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
import 'JournalEntry.dart';

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
