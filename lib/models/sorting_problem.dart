import 'journal_entry.dart';

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
