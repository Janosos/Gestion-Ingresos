import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/transaction_model.dart';

class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  
  DateTime _selectedDate = DateTime.now();

  List<Transaction> get transactions => _transactions;
  
  DateTime get selectedDate => _selectedDate;

  TransactionProvider() {
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('transactions');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      _transactions = decoded.map((item) => Transaction.fromJson(item)).toList();
    } else {
       // Initialize with empty list or keep mock data only for dev if needed. 
       // For now, let's start empty to respect "User data".
       // Or if we want to keep the mock data for the demo:
       // _transactions = [...mockData];
       // _saveData();
       // Let's start clean for persistence logic.
       _transactions = [];
    }
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_transactions.map((tx) => tx.toJson()).toList());
    await prefs.setString('transactions', encoded);
  }

  // Date Filter Logic
  DateFilterType _filterType = DateFilterType.day;
  DateTimeRange? _customDateRange;

  DateFilterType get filterType => _filterType;
  DateTimeRange? get customDateRange => _customDateRange;

  void setFilterType(DateFilterType type) {
    _filterType = type;
    notifyListeners();
  }

  void setCustomDateRange(DateTimeRange range) {
    _filterType = DateFilterType.custom;
    _customDateRange = range;
    notifyListeners();
  }

  // Helper to check if a date matches the current filter
  bool _matchesFilter(DateTime date, bool startWeekOnSunday) {
    final now = DateTime.now();
    switch (_filterType) {
      case DateFilterType.day:
        return date.year == _selectedDate.year &&
               date.month == _selectedDate.month &&
               date.day == _selectedDate.day;
      case DateFilterType.week:
        // Calculate start of week
        // weekday: Mon=1 ... Sun=7
        // If startWeekOnSunday: Sun=1
        
        int currentWeekday = now.weekday; // 1-7 (Mon-Sun)
        
        DateTime startOfWeek;
        if (startWeekOnSunday) {
           // If today is Sunday (7), offset is 0. If Monday (1), offset is 1.
           // custom logic: if start is Sunday.
           // If today is Sunday (7), search for previous Sunday? No, current week starts on this Sunday?
           // Usually "current week" means the week containing 'now'.
           
           // If standard is Mon(1)..Sun(7). 
           // If we want Sun..Sat.
           // If today is Wed(3). Start (last Sunday) was 3 days ago via standard? No.
           // Let's us DateTime utilities or simple math.
           
           final int daysSinceSunday = date.weekday == 7 ? 0 : date.weekday; 
           // If today is Sun(7), daysSince = 0.
           // If today is Mon(1), daysSince = 1.
           // DateTime subtract handles it.
           
           // Wait, I need to check against 'now' (or selectedDate if we want to browse weeks? User said "Esta Semana" implying current real time week).
           // "Esta Semana" usually means "Current Week".
           
           final int daysFromStart = now.weekday == 7 ? 0 : now.weekday;
           startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysFromStart));
        } else {
           // Start is Monday
           final int daysFromStart = now.weekday - 1;
           startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysFromStart));
        }
        
        final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        return date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && date.isBefore(endOfWeek);
        
      case DateFilterType.month:
        return date.year == now.year && date.month == now.month;
      case DateFilterType.custom:
         if (_customDateRange == null) return false;
         return date.isAfter(_customDateRange!.start.subtract(const Duration(seconds: 1))) && 
                date.isBefore(_customDateRange!.end.add(const Duration(days: 1))); // Inclusive end day
    }
  }

  List<Transaction> getFilteredTransactions(bool startWeekOnSunday) {
    return _transactions.where((tx) => _matchesFilter(tx.date, startWeekOnSunday)).toList();
  }
  
  // Replaces old transactionsByDate to use the filter info BUT we might need the provider context for the setting.
  // Ideally filtering happens in the UI or we pass the setting in.
  // For simplicity, let's keep `transactionsByDate` as "Filtered Transactions" and assume the UI passes the setting or we don't depend on it inside the getter (which is hard).
  // Alternative: Inject SettingsProvider? No, circular dependency risk.
  // Best approach: Add an argument to getters? No, getters don't take args.
  // We can update the provider to store `startWeekOnSunday` locally when it updates?
  // OR just calculate "Current Week" logic loosely or standard (Mon-Sun).
  // User explicitly asked for the setting.
  
  // Let's add a method `getTransactions(bool startWeekOnSunday)` or similar.
  // Or better, Update `DashboardScreen` to handle the filtering? 
  // No, Provider should handle logic.
  
  // Let's allow setting the config in the provider.
  bool _startWeekOnSunday = false;
  void updateWeekStart(bool isSunday) {
    _startWeekOnSunday = isSunday;
    notifyListeners();
  }

  List<Transaction> get filteredTransactions {
    return _transactions.where((tx) => _matchesFilter(tx.date, _startWeekOnSunday)).toList();
  }

  // Update existing getters to use filteredTransactions
  List<Transaction> get incomeTransactions {
    return filteredTransactions.where((tx) => tx.type == TransactionType.income).toList();
  }
  
  List<Transaction> get supplierTransactions {
    return filteredTransactions.where((tx) => 
      tx.type == TransactionType.expense && 
      tx.category == TransactionCategory.supplier
    ).toList();
  }

  // Daily Breakdown - NOW BASED ON FILTER
  double get totalIncome {
    return incomeTransactions.fold(0, (sum, tx) => sum + tx.amount);
  }
  
  double get totalCashIncome {
    return incomeTransactions
        .where((tx) => tx.category == TransactionCategory.salesCash)
        .fold(0, (sum, tx) => sum + tx.amount);
  }
  
  double get totalCardIncome {
    return incomeTransactions
        .where((tx) => tx.category == TransactionCategory.salesCard)
        .fold(0, (sum, tx) => sum + tx.amount);
  }
  
  double get totalTransferIncome {
    return incomeTransactions
        .where((tx) => tx.category == TransactionCategory.salesTransfer)
        .fold(0, (sum, tx) => sum + tx.amount);
  }

  double get totalSupplierExpenses {
    return supplierTransactions.fold(0, (sum, tx) => sum + tx.amount);
  }
  
  // Balance based on FILTER
  double get filteredBalance {
    double total = 0;
    for (var tx in filteredTransactions) {
      if (tx.type == TransactionType.income) {
        total += tx.amount;
      } else {
        total -= tx.amount;
      }
    }
    return total;
  }


  // Backward Compatibility / Aliases for Screen usage
  void setDate(DateTime date) {
    _selectedDate = date;
    setFilterType(DateFilterType.day);
  }

  List<Transaction> get transactionsByDate => filteredTransactions;
  List<Transaction> get incomeTransactionsByDate => incomeTransactions;
  List<Transaction> get supplierTransactionsByDate => supplierTransactions;
  
  double get dailyTotalIncome => totalIncome;
  double get dailyCashIncome => totalCashIncome;
  double get dailyCardIncome => totalCardIncome;
  double get dailyTransferIncome => totalTransferIncome;
  List<Transaction> get recentTransactions {
    final sorted = List<Transaction>.from(filteredTransactions)..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(5).toList();
  }

  double get dailyTotalSupplierExpenses => totalSupplierExpenses;


  void addTransaction(Transaction transaction) {
    _transactions.add(transaction);
    _saveData();
    notifyListeners();
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((tx) => tx.id == id);
    _saveData();
    notifyListeners();
  }

  Future<void> deleteAllTransactions() async {
    _transactions.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('transactions');
    notifyListeners();
  }
}

enum DateFilterType {
  day,
  week,
  month,
  custom,
}


