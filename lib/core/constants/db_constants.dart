class DbConstants {
  static const String databaseName = 'monetrack.db';
  static const int databaseVersion = 1;

  // Tables
  static const String tableTransactions = 'transactions';
  static const String tableCategories = 'categories';

  // Common Columns
  static const String colId = 'id';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';

  // Transaction Columns
  static const String colAmount = 'amount';
  static const String colCurrency = 'currency';
  static const String colType = 'type'; // 'spent' or 'received'
  static const String colDate = 'date'; // millisecondsSinceEpoch
  static const String colPayee = 'payee';
  static const String colCategoryId = 'category_id';
  static const String colNotes = 'notes';
  static const String colSource = 'source'; // 'auto' or 'manual'
  static const String colRawText = 'raw_text';

  // Category Columns
  static const String colName = 'name';
  static const String colIcon = 'icon'; // string identifier for icon
  static const String colColor = 'color'; // int value
  static const String colDefaultType = 'default_type'; // 'expense' or 'income'
}
