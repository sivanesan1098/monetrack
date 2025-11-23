import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:monetrack/domain/entities/parsed_transaction.dart';

class MessageParser {
  List<Map<String, dynamic>> _rules = [];

  // For testing
  void setRules(List<Map<String, dynamic>> rules) {
    _rules = rules;
  }

  Future<void> loadRules() async {
    try {
      final jsonString = await rootBundle.loadString('assets/parsing_rules.json');
      final data = json.decode(jsonString);
      _rules = List<Map<String, dynamic>>.from(data['rules']);
    } catch (e) {
      print('Error loading parsing rules: $e');
    }
  }

  ParsedTransaction? parse(String message) {
    if (_rules.isEmpty) {
      // Fallback or wait for load? Ideally loadRules is called at app start.
      // For now, return null if no rules.
      return null;
    }

    for (final rule in _rules) {
      final amountRegex = RegExp(rule['amount_regex'], caseSensitive: false);
      final payeeRegex = rule['payee_regex'] != null ? RegExp(rule['payee_regex'], caseSensitive: false) : null;
      final dateRegex = rule['date_regex'] != null ? RegExp(rule['date_regex']) : null;
      
      final keywordsSpent = List<String>.from(rule['keywords_spent'] ?? []);
      final keywordsReceived = List<String>.from(rule['keywords_received'] ?? []);

      // Check type first
      String? type;
      for (final k in keywordsSpent) {
        if (message.toLowerCase().contains(k.toLowerCase())) {
          type = 'spent';
          break;
        }
      }
      if (type == null) {
        for (final k in keywordsReceived) {
          if (message.toLowerCase().contains(k.toLowerCase())) {
            type = 'received';
            break;
          }
        }
      }

      if (type == null) continue; // Must identify type

      // Extract Amount
      final amountMatch = amountRegex.firstMatch(message);
      if (amountMatch == null) continue;

      String amountStr = amountMatch.group(1)!.replaceAll(',', '');
      double? amount = double.tryParse(amountStr);
      if (amount == null) continue;

      // Extract Payee
      String payee = 'Unknown';
      if (payeeRegex != null) {
        final payeeMatch = payeeRegex.firstMatch(message);
        if (payeeMatch != null) {
          payee = payeeMatch.group(1)!.trim();
        }
      }

      // Extract Date
      DateTime? date;
      if (dateRegex != null) {
        final dateMatch = dateRegex.firstMatch(message);
        if (dateMatch != null) {
          // Simple parsing for dd/mm/yyyy or dd-mm-yyyy
          // In real app, use DateFormat
          try {
             // Placeholder for date parsing logic
             // For now, default to now if parse fails or implement simple splitter
             final parts = dateMatch.group(1)!.split(RegExp(r'[-/]'));
             if (parts.length == 3) {
               int day = int.parse(parts[0]);
               int month = int.parse(parts[1]);
               int year = int.parse(parts[2]);
               if (year < 100) year += 2000; // Handle 2-digit year
               date = DateTime(year, month, day);
             }
          } catch (e) {
            // ignore
          }
        }
      }
      date ??= DateTime.now();

      return ParsedTransaction(
        amount: amount,
        type: type,
        payee: payee,
        date: date,
        rawMessage: message,
        confidence: 0.8, // Simple static confidence for now
      );
    }
    return null;
  }
}
