import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';
import '../widgets/add_transaction_sheet.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  int _selectedFilterIndex = 0; // 0: All, 1: Cash, 2: Digital (Card + Transfer)
  TransactionType _selectedType = TransactionType.income;

  /* Unused methods removed */

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    final dateFormat = DateFormat('EEE, d MMM', 'es_MX');
    
    // Select Source List
    List<Transaction> displayTransactions;
    if (_selectedType == TransactionType.income) {
      displayTransactions = provider.incomeTransactions;
    } else {
      displayTransactions = provider.expenseTransactions;
    }

    // Filter logic (Only for Income currently)
    if (_selectedType == TransactionType.income) {
      if (_selectedFilterIndex == 1) {
         displayTransactions = displayTransactions.where((tx) => tx.category == TransactionCategory.salesCash).toList();
      } else if (_selectedFilterIndex == 2) {
         displayTransactions = displayTransactions.where((tx) => 
           tx.category == TransactionCategory.salesCard || 
           tx.category == TransactionCategory.salesTransfer
         ).toList();
      }
    }
    
    // Sort by latest
    displayTransactions.sort((a, b) => b.date.compareTo(a.date));

    // Calculate totals for Summary Card
    double totalAmount = 0;
    if (_selectedType == TransactionType.income) {
      totalAmount = provider.dailyTotalIncome;
    } else {
      totalAmount = displayTransactions.fold(0, (sum, tx) => sum + tx.amount);
    }

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
                    Text(_selectedType == TransactionType.income ? 'Ingresos' : 'Egresos', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                    // Type Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                           _buildTypeToggle(TransactionType.income, Icons.arrow_downward),
                           _buildTypeToggle(TransactionType.expense, Icons.arrow_upward),
                        ],
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
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _selectedType == TransactionType.income 
                          ? [const Color(0xFF137FEC), const Color(0xFF2563EB)]
                          : [const Color(0xFFEF4444), const Color(0xFFB91C1C)], // Red for expenses
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_selectedType == TransactionType.income ? const Color(0xFF137FEC) : const Color(0xFFEF4444)).withOpacity(0.2),
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
                      Positioned(
                        bottom: -16, left: -16,
                        child: Container(height: 128, width: 128, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.1))),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Text(_selectedType == TransactionType.income ? 'Total recaudado' : 'Total gastado', style: const TextStyle(color: Color(0xFFDBEAFE), fontSize: 14, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text(currencyFormat.format(totalAmount), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: -1)),
                            const SizedBox(height: 16),
                              if (_selectedType == TransactionType.income)
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 8.0,
                                  children: [
                                    _buildSummaryBadge(Icons.payments, 'Efec: ${currencyFormat.format(provider.dailyCashIncome)}'),
                                    _buildSummaryBadge(Icons.credit_card, 'Tarj: ${currencyFormat.format(provider.dailyCardIncome)}'),
                                    _buildSummaryBadge(Icons.account_balance, 'Transf: ${currencyFormat.format(provider.dailyTransferIncome)}'),
                                  ],
                                ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Segmented Control Tabs (Only for Income)
                if (_selectedType == TransactionType.income)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildSegmentTab('Todos', 0),
                        _buildSegmentTab('Efectivo', 1),
                        _buildSegmentTab('Tarj/Transf', 2),
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
              itemCount: displayTransactions.isEmpty ? 1 : displayTransactions.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                   return Padding(
                     padding: const EdgeInsets.only(bottom: 16.0),
                     child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Transacciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('${displayTransactions.length} registros', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                        ),
                      ],
                                     ),
                   );
                }
                
                if (displayTransactions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40.0),
                      child: Text(_selectedType == TransactionType.income ? 'No hay ingresos registrados' : 'No hay egresos registrados', style: const TextStyle(color: Colors.grey)),
                    ),
                  );
                }

                final tx = displayTransactions[index - 1];
                return _buildTransactionItem(context, tx, currencyFormat);
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

            builder: (context) => AddTransactionSheet(type: _selectedType), // Use selected type
          );
        },
        backgroundColor: _selectedType == TransactionType.income ? Theme.of(context).primaryColor : const Color(0xFFEF4444),
        child: Icon(_selectedType == TransactionType.income ? Icons.add : Icons.remove, size: 32, color: Colors.white),
      ),
    );
  }
  
  Widget _buildTypeToggle(TransactionType type, IconData icon) {
    final isSelected = _selectedType == type;
    final color = isSelected 
        ? (type == TransactionType.income ? Theme.of(context).primaryColor : const Color(0xFFEF4444)) 
        : Colors.grey;
    final bgColor = isSelected ? color.withOpacity(0.1) : Colors.transparent;

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildSegmentTab(String label, int index) {
    final isSelected = _selectedFilterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilterIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ] : null,
          ),
          child: Center(
            child: Text(
              label, 
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey, 
                fontSize: 12, // Smaller font to fit 3 items
                fontWeight: FontWeight.w600
              )
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBadge(IconData icon, String text) {
    // Compact badge for 3 columns
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFFDBEAFE)),
          const SizedBox(width: 2),
          Text(text, style: const TextStyle(color: Color(0xFFDBEAFE), fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Transaction tx, NumberFormat currencyFormat) {
    IconData icon;
    Color color = const Color(0xFF10B981); // Emerald
    
    if (tx.type == TransactionType.expense) {
      color = const Color(0xFFEF4444); // Red
    }

    switch (tx.category) {
      case TransactionCategory.salesCash:
        icon = Icons.payments;
        break;
      case TransactionCategory.salesCard:
        icon = Icons.credit_card;
        color = Theme.of(context).primaryColor;
        break;
      case TransactionCategory.salesTransfer:
        icon = Icons.account_balance;
        color = Colors.purpleAccent;
        break;
      case TransactionCategory.supplier:
        icon = Icons.local_shipping;
        break;
      case TransactionCategory.various: // Add explicit case for various if needed, or let it fall to default
        icon = Icons.category;
        break;
      default:
         if (tx.type == TransactionType.expense) {
           icon = Icons.money_off; 
         } else {
           icon = Icons.attach_money;
         }
    }
    
    final isIncome = tx.type == TransactionType.income;

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
            title: Text(isIncome ? '¿Eliminar ingreso?' : '¿Eliminar egreso?', style: const TextStyle(color: Colors.white)),
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
          SnackBar(content: Text(isIncome ? 'Ingreso eliminado' : 'Egreso eliminado')),
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
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  if (tx.description != null && tx.description!.isNotEmpty)
                     Padding(
                       padding: const EdgeInsets.only(top: 2.0),
                       child: Text(tx.description!, style: TextStyle(fontSize: 13, color: Theme.of(context).primaryColor, fontStyle: FontStyle.italic)),
                     ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(DateFormat('HH:mm').format(tx.date), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
                      const SizedBox(width: 8),
                      const Icon(Icons.circle, size: 4, color: Colors.grey),
                      const SizedBox(width: 8),
                      // Text('#${tx.id.substring(tx.id.length - 4)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  )
                ],
              ),
            ),
            Text(currencyFormat.format(tx.amount), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
  
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
