import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:monetrack/core/utils/message_parser.dart';

void main() {
  late MessageParser parser;

  setUp(() {
    parser = MessageParser();
    final file = File('../../assets/parsing_rules.json');
    if (file.existsSync()) {
      final String jsonString = file.readAsStringSync();
      final data = json.decode(jsonString);
      parser.setRules(List<Map<String, dynamic>>.from(data['rules']));
      // Note: parser._spamKeywords isn't easily settable from outside without changing parser, 
      // but we mainly want to test rules.
    } else {
      // Fallback if filepath is different during test execution
      final file2 = File('assets/parsing_rules.json');
      if (file2.existsSync()) {
        final String jsonString = file2.readAsStringSync();
        final data = json.decode(jsonString);
        parser.setRules(List<Map<String, dynamic>>.from(data['rules']));
      }
    }
  });

  group('MessageParser Tests for Indian Banks', () {
    test('HDFC Debit SMS', () {
      final message = 'UPDATE: INR 125.00 debited from HDFC Bank A/c xx1234 on 02-03-26. Info: Swiggy. Avl Bal: INR 1,200.50.';
      final parsed = parser.parse(message);
      
      expect(parsed, isNotNull);
      expect(parsed?.amount, 125.0);
      expect(parsed?.type, 'spent');
      expect(parsed?.payee, 'Swiggy');
    });

    test('HDFC UPI Debit SMS', () {
      final message = 'Rs. 500.00 debited from a/c **1234 on 03-03-26 to VPA abc@upi. Ref No 123456789.';
      final parsed = parser.parse(message);
      
      expect(parsed, isNotNull);
      expect(parsed?.amount, 500.0);
      expect(parsed?.type, 'spent');
      expect(parsed?.payee.toLowerCase(), 'abc@upi');
    });

    test('SBI Debit SMS', () {
      final message = 'Dear SBI User, your A/c XXXXX1234-debited by Rs.100.00 on 03/03/26 trf to Mr ABC. Ref No 123.';
      final parsed = parser.parse(message);
      
      expect(parsed, isNotNull);
      expect(parsed?.amount, 100.0);
      expect(parsed?.type, 'spent');
      expect(parsed?.payee, 'Mr ABC');
    });

    test('ICICI Credit SMS', () {
      final message = 'Acct XX1234 is credited with Rs 5,000.00 on 01-Mar-26 from EMPLOYER. Inv. Bal: Rs 15,000.00';
      final parsed = parser.parse(message);
      
      expect(parsed, isNotNull);
      expect(parsed?.amount, 5000.0);
      expect(parsed?.type, 'received');
      expect(parsed?.payee, 'EMPLOYER');
    });

    test('UPI Sent SMS', () {
      final message = 'Paid ₹250.00 to Swiggy Instamart on 04-03-2026.';
      final parsed = parser.parse(message);
      
      expect(parsed, isNotNull);
      expect(parsed?.amount, 250.0);
      expect(parsed?.type, 'spent');
      expect(parsed?.payee, 'Swiggy Instamart');
    });
  });
}
