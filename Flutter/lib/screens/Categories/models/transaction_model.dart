class TransactionModel {
  final String id;
  final String userId;
  final String? categoryName;
  final String? categoryId; // Optional, can be null if not used
  final double amount;
  final String? description;
  final DateTime createdAt;
  final String transactionType; // 'expense' or 'income'

  TransactionModel({
    required this.id,
    required this.userId,
    this.categoryName,
    this.categoryId,
    required this.amount,
    required this.createdAt,
    required this.transactionType,
    this.description,
  });

  Map<String, dynamic> toMap() => {
        'transaction_id': id,
        'user_id': userId,
        'category_id': categoryId,
        // 'category_name': categoryName,
        'amount': amount,
        'description': description,
        'created_at': createdAt.toIso8601String(),
        'transaction_type': transactionType,
      };
//below
static TransactionModel fromMap(Map<String, dynamic> map) {
  return TransactionModel(
    id: map['transaction_id'] ?? '',
    userId: map['user_id'] ?? '',
    categoryId: map['category_id'] ?? '',  // Use category_id instead of category_name
    amount: (map['amount'] ?? 0).toDouble(),
    description: map['description'] ?? '',
    createdAt: map['created_at'] != null 
        ? DateTime.parse(map['created_at'])
        : DateTime.now(),
    transactionType: map['transaction_type'] ?? '',
  );
}
  @override
  String toString() {
    return 'TransactionModel{id: $id, userId: $userId, amount: $amount, description: $description, createdAt: $createdAt, transactionType: $transactionType}';
  } 
}

