import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:monetrack/domain/entities/parsed_transaction.dart';

class MessageParser {
  List<Map<String, dynamic>> _rules = [];

  // For testing
  void setRules(List<Map<String, dynamic>> rules) {
    _rules = rules;
  }

  List<String> _spamKeywords = [];

  Future<void> loadRules() async {
    try {
      final jsonString = await rootBundle.loadString('assets/parsing_rules.json');
      final data = json.decode(jsonString);
      _rules = List<Map<String, dynamic>>.from(data['rules']);
      _spamKeywords = List<String>.from(data['spam_keywords'] ?? []);
    } catch (e) {
      print('Error loading parsing rules: $e');
    }
  }

  ParsedTransaction? parse(String message) {
    if (_rules.isEmpty) return null;

    final lowerMsg = message.toLowerCase();
    
    // 1. Filter Spam/Promotions
    for (final spam in _spamKeywords) {
      if (lowerMsg.contains(spam.toLowerCase())) {
        return null; // Ignore spam
      }
    }

    // 2. Require at least one "anchor" word to ensure it's a transaction
    // (e.g., "a/c", "acct", "card", "bank", "txn", "ref", "debited", "credited")
    // This helps avoid random messages with numbers being parsed.
    // However, "debited"/"credited" are already checked in rules.
    // Let's rely on the rules but ensure the regexes are strict.

    for (final rule in _rules) {
      final amountRegex = RegExp(rule['amount_regex'], caseSensitive: false);
      final payeeRegex = rule['payee_regex'] != null ? RegExp(rule['payee_regex'], caseSensitive: false) : null;
      final dateRegex = rule['date_regex'] != null ? RegExp(rule['date_regex']) : null;
      
      final keywordsSpent = List<String>.from(rule['keywords_spent'] ?? []);
      final keywordsReceived = List<String>.from(rule['keywords_received'] ?? []);

      // Check type first
      String? type;
      for (final k in keywordsSpent) {
        if (lowerMsg.contains(k.toLowerCase())) {
          type = 'spent';
          break;
        }
      }
      if (type == null) {
        for (final k in keywordsReceived) {
          if (lowerMsg.contains(k.toLowerCase())) {
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
        } else {
          continue; // Rule must match payee pattern if provided
        }
      }

      // Extract Date
      DateTime? date;
      if (dateRegex != null) {
        final dateMatch = dateRegex.firstMatch(message);
        if (dateMatch != null) {
          try {
             final parts = dateMatch.group(1)!.split(RegExp(r'[-/]'));
             if (parts.length == 3) {
               int day = int.parse(parts[0]);
               int month = int.parse(parts[1]);
               int year = int.parse(parts[2]);
               if (year < 100) year += 2000; // Handle 2-digit year
               date = DateTime(year, month, day);
               
               // Try to extract time if present in message near the date
               // Simple heuristic: look for HH:MM after date
               final timeRegex = RegExp(r'(\d{1,2}):(\d{2})');
               final timeMatch = timeRegex.firstMatch(message.substring(dateMatch.end));
               if (timeMatch != null) {
                 int hour = int.parse(timeMatch.group(1)!);
                 int minute = int.parse(timeMatch.group(2)!);
                 date = DateTime(year, month, day, hour, minute);
               }
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
        confidence: 0.9,
      );
    }
    return null;
  }
}
