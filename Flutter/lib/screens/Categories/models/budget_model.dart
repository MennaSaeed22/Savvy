class Budget {
  final String userId;
  final String categoryId;
  final double allocatedAmount;
  final Map<String, dynamic> categoryMap;

  Budget({
    required this.userId,
    required this.categoryId,
    required this.allocatedAmount,
    required this.categoryMap,
  });
  
  // This getter makes it compatible with CategoryDetailScreen
  double get amount => allocatedAmount;
  
  String get categoryName => categoryMap['category_name'] ?? 'Unknown';

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      userId: map['user_id'] ?? '',
      categoryId: map['category_id'] ?? '',
      allocatedAmount: (map['allocated_amount'] ?? 0).toDouble(),
      categoryMap: map['categories'] ?? {}, // include the joined category map
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'category_id': categoryId,
      'allocated_amount': allocatedAmount,
    };
  }
  
  @override
  String toString() {
    return 'Budget{userId: $userId, categoryId: $categoryId, allocatedAmount: $allocatedAmount}';
  }
}