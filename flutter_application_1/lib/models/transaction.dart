import 'package:uuid/uuid.dart';

enum TransactionType {
  expense,
  income,
}

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final TransactionType type;

  Transaction({
    String? id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
  }) : id = id ?? const Uuid().v4();
}
