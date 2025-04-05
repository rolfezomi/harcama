import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'models/transaction.dart';
import 'screens/dashboard_page.dart';
import 'screens/add_expense_page.dart';
import 'screens/add_income_page.dart';
import 'screens/statistics_page.dart';
import 'screens/settings_page.dart';
import 'screens/expenses_page.dart';
import 'providers/theme_provider.dart';
import 'widgets/upgrade_prompt_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Harcama Takip',
          theme: themeProvider.themeData,
          home: const HomePage(),
          locale: const Locale('tr', 'TR'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('tr', 'TR'),
            Locale('en', 'US'),
          ],
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final List<Transaction> _transactions = [];

  void _showPremiumFeaturePrompt(String feature) {
    showDialog(
      context: context,
      builder: (context) => UpgradePromptDialog(feature: feature),
    );
  }

  void _addTransaction(Transaction transaction) {
    setState(() {
      _transactions.add(transaction);
    });
  }

  void _deleteTransaction(String id) {
    setState(() {
      _transactions.removeWhere((transaction) => transaction.id == id);
    });
  }

  // Tab geçişleri
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Harcama/Gelir ekleme seçenekleri
  void _showAddTransactionDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red[100],
                    child: const Icon(Icons.remove, color: Colors.red),
                  ),
                  title: const Text('Harcama Ekle'),
                  onTap: () {
                    Navigator.pop(context);
                    _openAddExpensePage();
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: const Icon(Icons.add, color: Colors.green),
                  ),
                  title: const Text('Gelir Ekle'),
                  onTap: () {
                    Navigator.pop(context);
                    _openAddIncomePage();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openAddExpensePage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => AddExpensePage(
          onAddTransaction: _addTransaction, // Düzeltilmiş
        ),
      ),
    );
  }

  void _openAddIncomePage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => AddIncomePage(
          onAddTransaction: _addTransaction, // Düzeltilmiş
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      DashboardPage(
        transactions: _transactions,
        onPremiumFeatureRequested: _showPremiumFeaturePrompt,
      ),
      ExpensesPage(
        transactions: _transactions,
        onAddTransaction: _addTransaction,
        onDeleteTransaction: _deleteTransaction,
        onPremiumFeatureRequested: _showPremiumFeaturePrompt,
      ),
      StatisticsPage(
        transactions: _transactions,
        onPremiumFeatureRequested: _showPremiumFeaturePrompt,
      ),
      SettingsPage(
        onPremiumFeatureRequested: _showPremiumFeaturePrompt,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Harcama Yönetimi'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium),
            onPressed: () => _showPremiumFeaturePrompt('Tüm Özellikler'),
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'İşlemler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'İstatistikler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
