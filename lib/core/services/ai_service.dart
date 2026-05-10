import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:monetrack/domain/entities/transaction.dart';
import 'package:monetrack/domain/repositories/transaction_repository.dart';

class AiService {
  final TransactionRepository _transactionRepository;
  GenerativeModel? _model;
  String? _cachedApiKey;

  AiService(this._transactionRepository);

  void initialize(String apiKey) {
    if (_cachedApiKey == apiKey && _model != null) return;
    
    _cachedApiKey = apiKey;
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
  }

  bool get isInitialized => _model != null;

  Future<String> askQuestion(String question) async {
    if (_model == null) {
      return "Error: AI Service not initialized. Please set your API key in Settings.";
    }

    try {
      // 1. Fetch transactions for context
      // Note: In a real large app, you'd filter by date or use a RAG approach.
      // For MVP, we pass the last 100 transactions as context.
      final transactions = await _transactionRepository.getTransactions();
      final recentTransactions = transactions.take(100).toList();

      final transactionContext = _buildTransactionContext(recentTransactions);

      final prompt = '''
You are a helpful personal finance assistant named Monetrack AI.
You have access to the user's recent transactions. Answer the user's question clearly and concisely based ONLY on this data. If the user asks something unrelated to their expenses or finance, politely decline.

<Transactions_Context>
$transactionContext
</Transactions_Context>

<User_Question>
$question
</User_Question>

Answer:
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      
      return response.text ?? "I'm sorry, I couldn't generate a response.";
    } catch (e) {
      return "Sorry, there was an error communicating with the AI. Error: $e";
    }
  }

  String _buildTransactionContext(List<TransactionEntity> transactions) {
    if (transactions.isEmpty) return "No recent transactions found.";
    
    final buffer = StringBuffer();
    buffer.writeln("Date | Type | Amount | Payee | Category");
    buffer.writeln("---------------------------------------");
    
    for (var t in transactions) {
      final dateStr = "\${t.date.year}-\${t.date.month.toString().padLeft(2, '0')}-\${t.date.day.toString().padLeft(2, '0')}";
      buffer.writeln("\$dateStr | \${t.type} | \${t.amount} \${t.currency} | \${t.payee} | \${t.categoryId ?? 'Uncategorized'}");
    }
    return buffer.toString();
  }
}
