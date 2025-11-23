class ParsedTransaction {
  final double amount;
  final String currency;
  final String type; // 'spent' or 'received'
  final DateTime? date;
  final String payee;
  final String rawMessage;
  final double confidence;

  ParsedTransaction({
    required this.amount,
    this.currency = 'INR',
    required this.type,
    this.date,
    required this.payee,
    required this.rawMessage,
    required this.confidence,
  });

  @override
  String toString() {
    return 'ParsedTransaction(amount: $amount, type: $type, payee: $payee, date: $date)';
  }
}
