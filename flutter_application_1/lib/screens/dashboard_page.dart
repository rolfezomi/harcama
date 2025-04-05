import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class DashboardPage extends StatelessWidget {
  final List<Transaction> transactions;
  final Function(String)? onPremiumFeatureRequested;

  const DashboardPage({
    super.key,
    required this.transactions,
    this.onPremiumFeatureRequested,
  });

  // Toplam harcama
  double get totalExpenses {
    return transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  // Toplam gelir
  double get totalIncomes {
    return transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, income) => sum + income.amount);
  }

  // Bakiye
  double get balance {
    return totalIncomes - totalExpenses;
  }

  // Bu ayki harcamalar
  double get monthlyExpenses {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    return transactions
        .where((t) => t.type == TransactionType.expense)
        .where((t) =>
            t.date.year == currentMonth.year &&
            t.date.month == currentMonth.month)
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  // Bu ayki gelirler
  double get monthlyIncomes {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    return transactions
        .where((t) => t.type == TransactionType.income)
        .where((t) =>
            t.date.year == currentMonth.year &&
            t.date.month == currentMonth.month)
        .fold(0, (sum, income) => sum + income.amount);
  }

  // Bu ayki bakiye
  double get monthlyBalance {
    return monthlyIncomes - monthlyExpenses;
  }

  // Harcama kategorileri
  Map<String, double> get expensesByCategory {
    final categoryMap = <String, double>{};

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        categoryMap.update(
          transaction.category,
          (value) => value + transaction.amount,
          ifAbsent: () => transaction.amount,
        );
      }
    }

    return categoryMap;
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 0,
    );

    // Son işlemleri tarihe göre sıralama
    final recentTransactions = List<Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Sadece son 5 işlemi al
    final latestTransactions = recentTransactions.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bakiye Kartı
          Card(
            elevation: 4,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Toplam Bakiye',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatter.format(balance),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: balance >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Toplam Gelir',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            formatter.format(totalIncomes),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Toplam Gider',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            formatter.format(totalExpenses),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Bu Ayki Özet Kartları
          Row(
            children: [
              // Bu Ay Gelir Kartı
              Expanded(
                child: Card(
                  elevation: 4,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bu Ay Gelir',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatter.format(monthlyIncomes),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Bu Ay Gider Kartı
              Expanded(
                child: Card(
                  elevation: 4,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bu Ay Gider',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatter.format(monthlyExpenses),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Detaylı Kategorik Harcama Raporu
          Card(
            elevation: 4,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Harcama Kategorileri',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () {
                          // Premium özellik için uyarı
                          onPremiumFeatureRequested
                              ?.call('Detaylı Kategori Raporu');
                        },
                        child: const Text('Detaylı Görünüm'),
                      ),
                    ],
                  ),
                  // Harcama kategorilerinin küçük bir özeti
                  ...expensesByCategory.entries.take(3).map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key),
                          Text(
                            formatter.format(entry.value),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Son İşlemler Kısmı
          Card(
            elevation: 4,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Son İşlemler',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (transactions.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            // İşlemler sayfasına git
                          },
                          child: const Text('Tümünü Gör'),
                        ),
                    ],
                  ),
                  if (latestTransactions.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('Henüz işlem bulunmuyor'),
                      ),
                    )
                  else
                    ...latestTransactions.map((transaction) {
                      final isExpense =
                          transaction.type == TransactionType.expense;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            // İşlem tipi ikonu
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: isExpense
                                  ? Colors.red[100]
                                  : Colors.green[100],
                              child: Icon(
                                isExpense ? Icons.remove : Icons.add,
                                color: isExpense ? Colors.red : Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // İşlem detayları
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    transaction.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${DateFormat('dd MMM', 'tr_TR').format(transaction.date)} - ${transaction.category}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // İşlem tutarı
                            Text(
                              isExpense
                                  ? '- ${formatter.format(transaction.amount)}'
                                  : '+ ${formatter.format(transaction.amount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isExpense ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
