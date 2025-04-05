import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../models/transaction.dart';

class StatisticsPage extends StatefulWidget {
  final List<Transaction> transactions;
  final Function(String)? onPremiumFeatureRequested;

  const StatisticsPage({
    super.key,
    required this.transactions,
    this.onPremiumFeatureRequested,
  });

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'Bu Ay';
  final List<String> _timePeriods = ['Bu Ay', 'Bu Yıl', 'Tüm Zamanlar'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Seçilen dönem için filtrelenmiş işlemler
  List<Transaction> get filteredTransactions {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Bu Ay':
        return widget.transactions.where((t) => 
          t.date.month == now.month && t.date.year == now.year).toList();
      case 'Bu Yıl':
        return widget.transactions.where((t) => t.date.year == now.year).toList();
      case 'Tüm Zamanlar':
      default:
        return widget.transactions;
    }
  }

  // Toplam harcama
  double get totalExpenses {
    return filteredTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  // Toplam gelir
  double get totalIncome {
    return filteredTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, income) => sum + income.amount);
  }

  // Harcama kategorileri
  Map<String, double> get expensesByCategory {
    final categoryMap = <String, double>{};
    for (final transaction in filteredTransactions) {
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

  // Gelir kategorileri
  Map<String, double> get incomeByCategory {
    final categoryMap = <String, double>{};
    for (final transaction in filteredTransactions) {
      if (transaction.type == TransactionType.income) {
        categoryMap.update(
          transaction.category,
          (value) => value + transaction.amount,
          ifAbsent: () => transaction.amount,
        );
      }
    }
    return categoryMap;
  }

  // Haftalık harcamalar
  Map<String, double> getWeeklyData() {
    final Map<String, double> weeklyData = {};
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final dayName = DateFormat('E', 'tr_TR').format(date);
      weeklyData[dayName] = 0;
    }

    for (final transaction in filteredTransactions) {
      if (transaction.type == TransactionType.expense) {
        final daysDiff = transaction.date.difference(startOfWeek).inDays;
        if (daysDiff >= 0 && daysDiff < 7) {
          final dayName = DateFormat('E', 'tr_TR').format(transaction.date);
          weeklyData.update(dayName, (value) => value + transaction.amount);
        }
      }
    }
    
    return weeklyData;
  }

  // Aylık harcamalar
  Map<String, double> get monthlyExpenses {
    final monthlyMap = <String, double>{};
    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);

    // Son 6 ay için boş değerlerle başlat
    for (int i = 0; i < 6; i++) {
      final month = DateTime(sixMonthsAgo.year, sixMonthsAgo.month + i);
      final monthName = DateFormat('MMM', 'tr_TR').format(month);
      monthlyMap[monthName] = 0;
    }

    for (final transaction in widget.transactions) {
      if (transaction.type == TransactionType.expense &&
          transaction.date.isAfter(sixMonthsAgo)) {
        final monthName = DateFormat('MMM', 'tr_TR').format(transaction.date);
        monthlyMap.update(
          monthName,
          (value) => value + transaction.amount,
        );
      }
    }

    return monthlyMap;
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 0,
    );

    // Kategorileri büyükten küçüğe sırala
    final sortedExpenseCategories = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    final sortedIncomeCategories = incomeByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Kategori renkleri
    final expenseCategoryColors = {
      'Yiyecek': Colors.red,
      'Ulaşım': Colors.blue,
      'Eğlence': Colors.purple,
      'Faturalar': Colors.orange,
      'Alışveriş': Colors.green,
      'Sağlık': Colors.teal,
      'Diğer': Colors.brown,
    };
    
    final incomeCategoryColors = {
      'Maaş': Colors.green,
      'Serbest Meslek': Colors.teal,
      'Yan Gelir': Colors.blue,
      'Yatırım': Colors.purple,
      'Hediye': Colors.amber,
      'Diğer': Colors.grey,
    };

    final defaultColors = [
      Colors.red, Colors.blue, Colors.green, Colors.purple,
      Colors.orange, Colors.teal, Colors.pink, Colors.amber, Colors.indigo,
    ];

    // Pasta grafik hazırlama - Giderler
    final expensePieChartSections = <PieChartSectionData>[];
    if (totalExpenses > 0) {
      for (var i = 0; i < sortedExpenseCategories.length; i++) {
        final category = sortedExpenseCategories[i];
        final percentage = category.value / totalExpenses;
        final color = expenseCategoryColors[category.key] ?? defaultColors[i % defaultColors.length];

        expensePieChartSections.add(
          PieChartSectionData(
            color: color,
            value: category.value,
            title: percentage > 0.05 ? '${(percentage * 100).toStringAsFixed(0)}%' : '',
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white,
            ),
          ),
        );
      }
    } else {
      expensePieChartSections.add(
        PieChartSectionData(
          color: Colors.grey.shade300,
          value: 1,
          title: '',
          radius: 100,
        ),
      );
    }
    
    // Pasta grafik - Gelirler
    final incomePieChartSections = <PieChartSectionData>[];
    if (totalIncome > 0) {
      for (var i = 0; i < sortedIncomeCategories.length; i++) {
        final category = sortedIncomeCategories[i];
        final percentage = category.value / totalIncome;
        final color = incomeCategoryColors[category.key] ?? defaultColors[i % defaultColors.length];

        incomePieChartSections.add(
          PieChartSectionData(
            color: color,
            value: category.value,
            title: percentage > 0.05 ? '${(percentage * 100).toStringAsFixed(0)}%' : '',
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white,
            ),
          ),
        );
      }
    } else {
      incomePieChartSections.add(
        PieChartSectionData(
          color: Colors.grey.shade300,
          value: 1,
          title: '',
          radius: 100,
        ),
      );
    }

    // Haftalık harcama verileri
    final weeklyData = getWeeklyData();
    final weeklySpots = weeklyData.entries
        .map((e) => FlSpot(weeklyData.keys.toList().indexOf(e.key).toDouble(), e.value))
        .toList();

    final maxWeeklyValue = weeklyData.values.isEmpty 
        ? 1000.0 
        : weeklyData.values.reduce((a, b) => a > b ? a : b) * 1.2;

    // Aylık harcama verileri
    final monthlyData = monthlyExpenses;
    final monthlySpots = monthlyData.entries
        .map((e) => FlSpot(monthlyData.keys.toList().indexOf(e.key).toDouble(), e.value))
        .toList();

    final maxMonthlyValue = monthlyData.values.isEmpty 
        ? 1000.0 
        : monthlyData.values.reduce((a, b) => a > b ? a : b) * 1.2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('İstatistikler'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Harcamalar'),
            Tab(text: 'Gelirler'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButton<String>(
              value: _selectedPeriod,
              icon: const Icon(Icons.arrow_drop_down),
              elevation: 16,
              underline: Container(height: 0),
              onChanged: (String? value) {
                if (value != null) {
                  setState(() => _selectedPeriod = value);
                }
              },
              items: _timePeriods.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // HARCAMALAR SAYFASI
          _buildExpensesTab(
            context, 
            formatter, 
            sortedExpenseCategories, 
            expensePieChartSections, 
            expenseCategoryColors, 
            defaultColors, 
            weeklyData, 
            weeklySpots, 
            maxWeeklyValue,
            monthlyData,
            maxMonthlyValue
          ),
          
          // GELİRLER SAYFASI
          _buildIncomesTab(
            context, 
            formatter, 
            sortedIncomeCategories, 
            incomePieChartSections, 
            incomeCategoryColors, 
            defaultColors
          ),
        ],
      ),
    );
  }

  // Harcamalar tab sayfası
  Widget _buildExpensesTab(
    BuildContext context, 
    NumberFormat formatter, 
    List<MapEntry<String, double>> sortedExpenseCategories,
    List<PieChartSectionData> expensePieChartSections,
    Map<String, Color> expenseCategoryColors,
    List<Color> defaultColors,
    Map<String, double> weeklyData,
    List<FlSpot> weeklySpots,
    double maxWeeklyValue,
    Map<String, double> monthlyData,
    double maxMonthlyValue
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toplam Harcama Kartı
          _buildSummaryCard(
            context,
            title: '$_selectedPeriod Toplam Harcama',
            amount: totalExpenses,
            formatter: formatter,
            color: Colors.red,
          ),

          const SizedBox(height: 24),

          // Kategori Dağılımı Kartı
          _buildCategoryCard(
            context,
            title: 'Kategori Dağılımı',
            emptyText: 'Bu dönemde harcama kaydı bulunmuyor',
            sortedCategories: sortedExpenseCategories,
            pieChartSections: expensePieChartSections,
            categoryColors: expenseCategoryColors,
            defaultColors: defaultColors,
            total: totalExpenses,
            formatter: formatter,
            premiumFeature: 'Detaylı Kategori Analizi',
          ),

          const SizedBox(height: 24),

          // Haftalık Trend Kartı
          _buildWeeklyTrendCard(
            context,
            weeklyData,
            weeklySpots,
            maxWeeklyValue,
            formatter
          ),

          const SizedBox(height: 24),

          // Aylık Trend Kartı
          _buildMonthlyTrendCard(
            context,
            monthlyData,
            maxMonthlyValue,
            formatter
          ),
        ],
      ),
    );
  }

  // Gelirler tab sayfası
  Widget _buildIncomesTab(
    BuildContext context, 
    NumberFormat formatter, 
    List<MapEntry<String, double>> sortedIncomeCategories,
    List<PieChartSectionData> incomePieChartSections,
    Map<String, Color> incomeCategoryColors,
    List<Color> defaultColors
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toplam Gelir Kartı
          _buildSummaryCard(
            context,
            title: '$_selectedPeriod Toplam Gelir',
            amount: totalIncome,
            formatter: formatter,
            color: Colors.green,
          ),

          const SizedBox(height: 24),

          // Gelir Kategorileri
          _buildCategoryCard(
            context,
            title: 'Kategori Dağılımı',
            emptyText: 'Bu dönemde gelir kaydı bulunmuyor',
            sortedCategories: sortedIncomeCategories,
            pieChartSections: incomePieChartSections,
            categoryColors: incomeCategoryColors,
            defaultColors: defaultColors,
            total: totalIncome,
            formatter: formatter,
            premiumFeature: 'Detaylı Gelir Analizi',
          ),

          const SizedBox(height: 24),

          // Gelir/Gider Karşılaştırması
          _buildComparisonCard(context, formatter),

          const SizedBox(height: 24),

          // Premium Bölümü
          _buildPremiumCard(context),
        ],
      ),
    );
  }
  
  // Toplam Özet Kartı
  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required double amount,
    required NumberFormat formatter,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            CircularPercentIndicator(
              radius: 80.0,
              lineWidth: 13.0,
              animation: true,
              percent: amount > 0 ? 1.0 : 0.0,
              center: Text(
                formatter.format(amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                ),
              ),
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: color,
              backgroundColor: color.withOpacity(0.2),
            ),
          ],
        ),
      ),
    );
  }

  // Kategori Dağılım Kartı
  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String emptyText,
    required List<MapEntry<String, double>> sortedCategories,
    required List<PieChartSectionData> pieChartSections,
    required Map<String, Color> categoryColors,
    required List<Color> defaultColors,
    required double total,
    required NumberFormat formatter,
    required String premiumFeature,
  }) {
    return Card(
      elevation: 4,
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
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (sortedCategories.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      widget.onPremiumFeatureRequested?.call(premiumFeature);
                    },
                    child: const Text('Detaylı Analiz'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            sortedCategories.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        emptyText,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      SizedBox(
                        height: 240,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: pieChartSections,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      ...sortedCategories.map((category) {
                        final percentage = category.value / total;
                        final color = categoryColors[category.key] ??
                            defaultColors[
                                sortedCategories.indexOf(category) %
                                    defaultColors.length];

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  category.key,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              Text(
                                formatter.format(category.value),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${(percentage * 100).toStringAsFixed(1)}%)',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  // Haftalık Trend Kartı
  Widget _buildWeeklyTrendCard(
    BuildContext context,
    Map<String, double> weeklyData,
    List<FlSpot> weeklySpots,
    double maxWeeklyValue,
    NumberFormat formatter
  ) {
    return Card(
      elevation: 4,
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
                  'Haftalık Harcama Trendi',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (weeklyData.values.any((value) => value > 0))
                  TextButton(
                    onPressed: () {
                      widget.onPremiumFeatureRequested?.call('Detaylı Haftalık Rapor');
                    },
                    child: const Text('Detaylı Rapor'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            weeklyData.values.every((value) => value == 0)
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'Bu hafta harcama kaydı bulunmuyor',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 && value.toInt() < weeklyData.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      weeklyData.keys.toList()[value.toInt()],
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                              reservedSize: 30,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: weeklySpots,
                            isCurved: true,
                            color: Colors.red,
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.red.withOpacity(0.2),
                            ),
                          ),
                        ],
                        minY: 0,
                        maxY: maxWeeklyValue,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // Aylık Trend Kartı
  Widget _buildMonthlyTrendCard(
    BuildContext context,
    Map<String, double> monthlyData,
    double maxMonthlyValue,
    NumberFormat formatter
  ) {
    return Card(
      elevation: 4,
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
                  'Aylık Harcama Trendi',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (monthlyData.values.any((value) => value > 0))
                  TextButton(
                    onPressed: () {
                      widget.onPremiumFeatureRequested?.call('Detaylı Aylık Rapor');
                    },
                    child: const Text('Detaylı Rapor'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            monthlyData.values.every((value) => value == 0)
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'Son 6 ayda harcama kaydı bulunmuyor',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxMonthlyValue,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipBgColor: Colors.blueGrey,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                formatter.format(rod.toY),
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 && value.toInt() < monthlyData.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      monthlyData.keys.toList()[value.toInt()],
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                              reservedSize: 30,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: monthlyData.entries
                            .map((entry) => BarChartGroupData(
                                  x: monthlyData.keys.toList().indexOf(entry.key),
                                  barRods: [
                                    BarChartRodData(
                                      toY: entry.value,
                                      color: Colors.red,
                                      width: 20,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(6),
                                        topRight: Radius.circular(6),
                                      ),
                                    ),
                                  ],
                                ))
                            .toList(),
                        gridData: const FlGridData(show: false),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // Gelir/Gider Karşılaştırma Kartı
  Widget _buildComparisonCard(BuildContext context, NumberFormat formatter) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gelir/Gider Karşılaştırması',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (totalIncome == 0 && totalExpenses == 0)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'Bu dönemde kayıt bulunmuyor',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Net Bakiye:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        formatter.format(totalIncome - totalExpenses),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: totalIncome - totalExpenses >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: totalIncome == 0
                        ? 0
                        : (totalExpenses / totalIncome).clamp(0.0, 1.0),
                    backgroundColor: Colors.green.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.red.withOpacity(0.8)),
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${totalIncome == 0 ? 0 : ((totalExpenses / totalIncome) * 100).toStringAsFixed(1)}% Harcandı',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        '${totalIncome == 0 ? 0 : (100 - (totalExpenses / totalIncome) * 100).toStringAsFixed(1)}% Kaldı',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),ween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Toplam Gelir'),
                            const SizedBox(height: 4),
                            Text(
                              formatter.format(totalIncome),
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Toplam Gider'),
                            const SizedBox(height: 4),
                            Text(
                              formatter.format(totalExpenses),
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBet