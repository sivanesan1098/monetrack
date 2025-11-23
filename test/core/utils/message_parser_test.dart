import 'package:flutter_test/flutter_test.dart';
import 'package:monetrack/core/utils/message_parser.dart';

void main() {
  late MessageParser parser;

  setUp(() {
    parser = MessageParser();
    parser.setRules([
      {
        "id": "test_rule",
        "priority": 1,
        "amount_regex": r"(?:(?:₹|INR|Rs\.?|\$)\s?)?([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)",
        "date_regex": r"(\d{1,2}\/\d{1,2}\/\d{2,4}|\d{1,2}-\d{1,2}-\d{2,4})",
        "payee_regex": r"(?:to|at|from)\s+([A-Za-z0-9\s]+?)(?:\s+(?:on|using|via|ref|bal)|$)",
        "keywords_spent": ["debited", "paid", "sent"],
        "keywords_received": ["credited", "received"]
      }
    ]);
  });

  test('Parser should identify spent transaction', () {
    const message = "Paid ₹ 500.00 to Amazon on 12/12/2023";
    final result = parser.parse(message);
    
    expect(result, isNotNull);
    expect(result!.amount, 500.0);
    expect(result.type, 'spent');
    expect(result.payee, 'Amazon');
  });

  test('Parser should identify received transaction', () {
    const message = "Credited INR 1,200.50 from Salary on 01-01-2024";
    final result = parser.parse(message);
    
    expect(result, isNotNull);
    expect(result!.amount, 1200.50);
    expect(result.type, 'received');
    expect(result.payee, 'Salary');
  });
  
  test('Parser should return null for unrelated message', () {
    const message = "Hello, how are you?";
    final result = parser.parse(message);
    
    expect(result, isNull);
  });
}
