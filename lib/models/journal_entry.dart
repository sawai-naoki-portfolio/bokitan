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
