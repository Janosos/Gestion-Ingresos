import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/receivable_model.dart';

class ReceivableProvider with ChangeNotifier {
  List<Receivable> _receivables = [];

  List<Receivable> get receivables => _receivables;

  ReceivableProvider() {
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('receivables');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      _receivables = decoded.map((item) => Receivable.fromJson(item)).toList();
    } else {
      _receivables = [];
    }
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_receivables.map((r) => r.toJson()).toList());
    await prefs.setString('receivables', encoded);
  }

  // Total Outstanding (only pending)
  double get totalOutstanding {
    return _receivables
        .where((r) => !r.isPaid)
        .fold(0, (sum, r) => sum + r.amount);
  }

  void addReceivable(String clientName, double amount) {
    final newReceivable = Receivable(
      id: DateTime.now().toString(),
      clientName: clientName,
      amount: amount,
      date: DateTime.now(),
      isPaid: false,
    );
    _receivables.add(newReceivable);
    _saveData();
    notifyListeners();
  }

  void toggleStatus(String id, {String? paymentTransactionId}) {
    final index = _receivables.indexWhere((r) => r.id == id);
    if (index != -1) {
      final current = _receivables[index];
      // Update status and potentially the transaction ID
      final updated = Receivable(
        id: current.id,
        clientName: current.clientName,
        amount: current.amount,
        date: current.date,
        isPaid: !current.isPaid,
        paymentTransactionId: paymentTransactionId ?? (current.isPaid ? null : current.paymentTransactionId), 
         // Logic: If we are paying (result isPaid=true), we expect an ID. 
         // If we are unpaying (result isPaid=false), we expect to clear it (null), unless passed otherwise.
      );
      
      _receivables[index] = updated;
      _saveData();
      notifyListeners();
      notifyListeners();
    }
  }

  // Settle all debts for a client
  void settleClientDebt(String clientName, String paymentTransactionId) {
    bool changed = false;
    for (var i = 0; i < _receivables.length; i++) {
        if (_receivables[i].clientName == clientName && !_receivables[i].isPaid) {
            _receivables[i] = Receivable(
                id: _receivables[i].id,
                clientName: _receivables[i].clientName,
                amount: _receivables[i].amount,
                date: _receivables[i].date,
                isPaid: true,
                paymentTransactionId: paymentTransactionId,
            );
            changed = true;
        }
    }
    if (changed) {
        _saveData();
        notifyListeners();
    }
  }

  // Delete a single receivable
  void deleteReceivable(String id) {
    _receivables.removeWhere((r) => r.id == id);
    _saveData();
    notifyListeners();
  }

  // Delete all receivables for a specific client
  void deleteReceivablesByClient(String clientName) {
    _receivables.removeWhere((r) => r.clientName == clientName);
    _saveData();
    notifyListeners();
  }

  // Delete all receivables
  Future<void> deleteAllReceivables() async {
    _receivables.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('receivables');
    notifyListeners();
  }

  // Get grouped receivables: Map<ClientName, List<Receivable>>
  Map<String, List<Receivable>> get groupedReceivables {
    final Map<String, List<Receivable>> grouped = {};
    for (var receivable in _receivables) {
      if (!grouped.containsKey(receivable.clientName)) {
        grouped[receivable.clientName] = [];
      }
      grouped[receivable.clientName]!.add(receivable);
    }
    return grouped;
  }
}

