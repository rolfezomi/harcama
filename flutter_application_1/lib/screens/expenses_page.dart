import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import 'add_expense_page.dart';

class ExpensesPage extends StatelessWidget {
  final List<Transaction> transactions;
  final Function(Transaction) onAddTransaction;
  final Function(String) onDeleteTransaction;
  final Function(String)? onPremiumFeatureRequested;

  const ExpensesPage({
    super.key,
    required this.transactions,
    required this.onAddTransaction,
    required this.onDeleteTransaction,
    this.onPremiumFeatureRequested,
  });

  Future<void> _openAddExpensePage(BuildContext context) async {
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => AddExpensePage(onAddTransaction: onAddTransaction),
        ),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bir hata oluştu: $error')),
        );
      }
    }
  }

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context, String id) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Silme Onayı'),
        content: const Text('Bu harcamayı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              onDeleteTransaction(id);
              Navigator.pop(context, true);
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 2,
    );

    final expenses = transactions
        .where((transaction) => transaction.type == TransactionType.expense)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      body: expenses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Henüz harcama eklenmedi',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _openAddExpensePage(context),
                    child: const Text('Harcama Ekle'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView.builder(
                itemCount: expenses.length,
                itemBuilder: (ctx, index) {
                  final expense = expenses[index];
                  return _buildExpenseItem(context, expense, formatter);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddExpensePage(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildExpenseItem(
      BuildContext context, Transaction expense, NumberFormat formatter) {
    return Dismissible(
      key: Key(expense.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        final result = await _showDeleteConfirmationDialog(context, expense.id);
        return result ?? false;
      },
      onDismissed: (direction) => onDeleteTransaction(expense.id),
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        child: ListTile(
          title: Text(expense.title),
          subtitle: Text(
            '${DateFormat('dd/MM/yyyy').format(expense.date)} - ${expense.category}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatter.format(expense.amount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              _buildPopupMenu(context, expense),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context, Transaction expense) {
    return PopupMenuButton<String>(
      onSelected: (String value) async {
        if (value == 'delete') {
          final confirmed =
              await _showDeleteConfirmationDialog(context, expense.id);
          if (confirmed ?? false) {
            onDeleteTransaction(expense.id);
          }
        } else if (value == 'edit') {
          onPremiumFeatureRequested?.call('Harcama Düzenleme');
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.blue),
              SizedBox(width: 8),
              Text('Düzenle'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text('Sil'),
            ],
          ),
        ),
      ],
      icon: const Icon(Icons.more_vert),
    );
  }
}
