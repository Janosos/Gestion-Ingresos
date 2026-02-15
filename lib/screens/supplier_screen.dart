import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';
import '../widgets/add_transaction_sheet.dart';

class SupplierScreen extends StatelessWidget {
  const SupplierScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    final dateFormat = DateFormat('EEE, d MMM', 'es_MX');

    // Filtered by date (handled by provider.supplierTransactionsByDate)
    final transactions = provider.supplierTransactionsByDate;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          
          // Header Section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Proveedores', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                    // Note: Date is controlled globally (or by Income screen?), 
                    // user said "este modulo si se ve afectado por la fecha seleccionada". 
                    // Does this screen need its own date picker or reuse the one from Dashboard/Income?
                    // Typically if it's affected, it should show what date is selected.
                    // Let's add the date display/picker here too for consistency if they navigate directly.
                     GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              isSameDay(provider.selectedDate, DateTime.now()) 
                                ? 'Hoy, ${dateFormat.format(provider.selectedDate)}' 
                                : dateFormat.format(provider.selectedDate),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Total Summary Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)], // Red gradient for expenses
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                       Positioned(
                        right: -16, top: -16,
                        child: Container(height: 96, width: 96, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1))),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pago a Proveedores', style: TextStyle(color: Color(0xFFFEE2E2), fontSize: 14, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text(currencyFormat.format(provider.dailyTotalSupplierExpenses), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: -1)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Transactions List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              itemCount: transactions.isEmpty ? 1 : transactions.length,
              itemBuilder: (context, index) {
                if (transactions.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40.0),
                      child: Text('No hay pagos registrados', style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }

                final tx = transactions[index];
                return Dismissible(
                  key: Key(tx.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF1E293B),
                        title: const Text('¿Eliminar gasto?', style: TextStyle(color: Colors.white)),
                        content: Text(
                          'Estás a punto de eliminar "${tx.title}". Esta acción no se puede deshacer.',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    Provider.of<TransactionProvider>(context, listen: false).deleteTransaction(tx.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gasto "${tx.title}" eliminado')),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Icon(Icons.local_shipping, color: Color(0xFFEF4444), size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tx.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
                              const SizedBox(height: 4),
                              Text(DateFormat('HH:mm').format(tx.date), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Text(currencyFormat.format(tx.amount), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: const Color(0xFF101922),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),

            builder: (context) => const AddTransactionSheet(type: TransactionType.expense),
          );
        },
        backgroundColor: const Color(0xFFEF4444),
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
    );
  }

  void _selectDate(BuildContext context) async {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
         return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: const Color(0xFF101922),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF101922),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != provider.selectedDate) {
      provider.setDate(picked);
    }
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
