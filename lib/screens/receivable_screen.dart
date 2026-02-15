import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/receivable_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/receivable_model.dart';
import '../models/transaction_model.dart';

class ReceivableScreen extends StatelessWidget {
  const ReceivableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReceivableProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    final groupedReceivables = provider.groupedReceivables;
    final clientNames = groupedReceivables.keys.toList()..sort();

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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pendientes de Cobro', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                    // "+" Button removed as requested
                  ],
                ),
                const SizedBox(height: 24),
                // Total Outstanding Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF137FEC), Color(0xFF2563EB)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF137FEC).withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -10, top: -10,
                        child: Container(height: 128, width: 128, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1))),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total por Cobrar', style: TextStyle(color: Color(0xFFDBEAFE), fontSize: 14, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(currencyFormat.format(provider.totalOutstanding), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: -1)),
                                const SizedBox(width: 8),
                                const Text('MXN', style: TextStyle(color: Color(0xFFDBEAFE), fontSize: 14, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Clients List
          Expanded(
            child: clientNames.isEmpty 
              ? Center(child: Text('No hay cobros pendientes', style: TextStyle(color: Colors.grey.shade500)))
              : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              itemCount: clientNames.length,
              itemBuilder: (context, index) {
                final clientName = clientNames[index];
                final clientDebts = groupedReceivables[clientName] ?? [];
                // Calculate total for this client
                final clientTotal = clientDebts.where((r) => !r.isPaid).fold(0.0, (sum, r) => sum + r.amount);
                final hasPending = clientDebts.any((r) => !r.isPaid);
                
                return _buildClientItem(context, clientName, clientTotal, clientDebts.length, hasPending, currencyFormat, provider);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddReceivableDialog(context),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
    );
  }

  Widget _buildClientItem(BuildContext context, String name, double total, int count, bool hasPending, NumberFormat currencyFormat, ReceivableProvider provider) {
    final color = hasPending ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    
    return GestureDetector(
      onTap: () => _showClientDetails(context, name, provider),
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
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Text(name[0].toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('$count registros', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(currencyFormat.format(total), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                Text(hasPending ? 'Pendiente' : 'Pagado', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showClientDetails(BuildContext context, String clientName, ReceivableProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101922),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Consumer<ReceivableProvider>(
              builder: (context, provider, child) {
                 final debts = provider.groupedReceivables[clientName] ?? [];
                 final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

                 if (debts.isEmpty) {
                   // If all debts deleted, close grouped view probably? Or show empty
                   WidgetsBinding.instance.addPostFrameCallback((_) {
                     if (context.mounted) Navigator.pop(context); 
                   });
                   return const SizedBox();
                 }

                 return Column(
                   children: [
                     // Handle bar
                     Center(
                       child: Container(
                         margin: const EdgeInsets.only(top: 12, bottom: 12),
                         width: 40,
                         height: 4,
                         decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2)),
                       ),
                     ),
                     Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                       child: Column(
                         children: [
                           Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                               Expanded(child: Text(clientName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))),
                               Row(
                                 children: [
                                   IconButton(
                                     icon: const Icon(Icons.delete_sweep, color: Colors.red, size: 28),
                                     onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            backgroundColor: const Color(0xFF1E293B),
                                            title: const Text('Eliminar Cliente', style: TextStyle(color: Colors.white)),
                                            content: Text('¿Eliminar todos los registros de $clientName?', style: const TextStyle(color: Colors.grey)),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                                              TextButton(
                                                onPressed: () {
                                                  provider.deleteReceivablesByClient(clientName);
                                                  Navigator.pop(context); // Close dialog
                                                  Navigator.pop(context); // Close sheet
                                                }, 
                                                child: const Text('Eliminar', style: TextStyle(color: Colors.red))
                                              ),
                                            ],
                                          ),
                                        );
                                     },
                                   ),
                                   const SizedBox(width: 8),
                                   IconButton(
                                     icon: const Icon(Icons.add_circle, color: Color(0xFF2563EB), size: 32),
                                     onPressed: () => _showAddReceivableDialog(context, prefilledName: clientName),
                                   ),
                                 ],
                               )
                             ],
                           ),
                           if (debts.any((r) => !r.isPaid)) ...[
                             const SizedBox(height: 16),
                             SizedBox(
                               width: double.infinity,
                               child: ElevatedButton.icon(
                                 onPressed: () => _confirmSettleDebt(context, clientName, debts, provider),
                                 icon: const Icon(Icons.check_circle, color: Colors.white),
                                 label: const Text('Liquidar Deuda Total', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                 style: ElevatedButton.styleFrom(
                                   backgroundColor: const Color(0xFF10B981),
                                   padding: const EdgeInsets.symmetric(vertical: 12),
                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                 ),
                               ),
                             ),
                           ],
                         ],
                       ),
                     ),
                     const Divider(color: Colors.white10),
                     Expanded(
                       child: ListView.builder(
                         controller: scrollController,
                         padding: const EdgeInsets.all(20),
                         itemCount: debts.length,
                         itemBuilder: (context, index) {
                           final item = debts[index];
                           final color = item.isPaid ? const Color(0xFF10B981) : const Color(0xFFEF4444);
                           return Dismissible(
                             key: Key(item.id),
                             direction: DismissDirection.endToStart,
                             background: Container(
                               alignment: Alignment.centerRight,
                               padding: const EdgeInsets.only(right: 20),
                               color: Colors.red,
                               child: const Icon(Icons.delete, color: Colors.white),
                             ),
                             confirmDismiss: (direction) async {
                               return await showDialog(
                                 context: context,
                                 builder: (context) => AlertDialog(
                                   backgroundColor: const Color(0xFF1E293B),
                                   title: const Text('Eliminar', style: TextStyle(color: Colors.white)),
                                   content: const Text('¿Estás seguro de eliminar este registro?', style: TextStyle(color: Colors.grey)),
                                   actions: [
                                     TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                     TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
                                   ],
                                 ),
                               );
                             },
                             onDismissed: (direction) {
                               provider.deleteReceivable(item.id);
                             },
                             child: Container(
                               margin: const EdgeInsets.only(bottom: 12),
                               padding: const EdgeInsets.all(12),
                               decoration: BoxDecoration(
                                 color: Colors.white.withOpacity(0.05),
                                 borderRadius: BorderRadius.circular(12),
                               ),
                               child: Row(
                                 children: [
                                   Expanded(
                                     child: Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                         Text(currencyFormat.format(item.amount), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                                         Text(DateFormat('d MMM yyyy').format(item.date), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                       ],
                                     ),
                                   ),
                                   
                                   // Actions
                                   Row(
                                     children: [
                                      IconButton(
                                         icon: Icon(item.isPaid ? Icons.check_circle : Icons.radio_button_unchecked, color: color),
                                         onPressed: () => _showStatusDialog(context, item, provider),
                                       ),
                                     ],
                                   )
                                 ],
                               ),
                             ),
                           );
                         },
                       ),
                     ),
                   ],
                 );
              },
            );
          },
        );
      },
    );
  }

  void _showAddReceivableDialog(BuildContext context, {String? prefilledName}) {
    final nameController = TextEditingController(text: prefilledName);
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101922),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nuevo Pendiente', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              decoration: InputDecoration(
                prefixText: '\$ ',
                prefixStyle: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey),
                hintText: '0.00',
                hintStyle: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey.withOpacity(0.3)),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              enabled: prefilledName == null, // Lock if adding to existing
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nombre del Cliente',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                if (amount == null || nameController.text.isEmpty) return;
                
                Provider.of<ReceivableProvider>(context, listen: false).addReceivable(nameController.text, amount);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Guardar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusDialog(BuildContext context, Receivable item, ReceivableProvider provider) {
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    TransactionCategory selectedMethod = TransactionCategory.salesCash;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF101922),
            title: Text(item.clientName, style: const TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Marcar como ${item.isPaid ? 'PENDIENTE' : 'PAGADO'}?',
                  style: const TextStyle(color: Colors.grey),
                ),
                if (!item.isPaid) ...[
                  const SizedBox(height: 20),
                  const Text('Método de Pago:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  _buildPaymentOption(
                    'Efectivo', 
                    TransactionCategory.salesCash, 
                    selectedMethod, 
                    (val) => setState(() => selectedMethod = val),
                  ),
                  _buildPaymentOption(
                    'Tarjeta', 
                    TransactionCategory.salesCard, 
                    selectedMethod, 
                    (val) => setState(() => selectedMethod = val),
                   ),
                  _buildPaymentOption(
                    'Transferencia', 
                    TransactionCategory.salesTransfer, 
                    selectedMethod, 
                    (val) => setState(() => selectedMethod = val),
                  ),
                ]
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  if (!item.isPaid) {
                     final newTxId = DateTime.now().toString();
                     final tx = Transaction(
                       id: newTxId,
                       title: 'Cobro: ${item.clientName}',
                       amount: item.amount,
                       date: DateTime.now(),
                       type: TransactionType.income,
                       category: selectedMethod, 
                     );
                     txProvider.addTransaction(tx);
                     provider.toggleStatus(item.id, paymentTransactionId: newTxId);
                  } else {
                     if (item.paymentTransactionId != null) {
                        txProvider.deleteTransaction(item.paymentTransactionId!);
                     }
                     provider.toggleStatus(item.id, paymentTransactionId: null);
                  }
                  Navigator.pop(context);
                },
                child: Text(
                  item.isPaid ? 'Marcar Pendiente' : 'Marcar Pagado',
                  style: TextStyle(color: item.isPaid ? Colors.red : Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        }
      ),
    );
  }
  void _confirmSettleDebt(BuildContext context, String clientName, List<Receivable> debts, ReceivableProvider provider) {
    final pendingTotal = debts.where((r) => !r.isPaid).fold(0.0, (sum, r) => sum + r.amount);
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    
    TransactionCategory selectedMethod = TransactionCategory.salesCash;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text('Liquidar Deuda Total', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Estás seguro de marcar todos los pendientes de $clientName como PAGADOS?',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Text(
                  'Total: ${currencyFormat.format(pendingTotal)}',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text('Método de Pago:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                _buildPaymentOption(
                  'Efectivo', 
                  TransactionCategory.salesCash, 
                  selectedMethod, 
                  (val) => setState(() => selectedMethod = val),
                ),
                _buildPaymentOption(
                  'Tarjeta', 
                  TransactionCategory.salesCard, 
                  selectedMethod, 
                  (val) => setState(() => selectedMethod = val),
                 ),
                _buildPaymentOption(
                  'Transferencia', 
                  TransactionCategory.salesTransfer, 
                  selectedMethod, 
                  (val) => setState(() => selectedMethod = val),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              TextButton(
                onPressed: () {
                   final txProvider = Provider.of<TransactionProvider>(context, listen: false);
                   final newTxId = DateTime.now().toString();
                   
                   // Create single income transaction
                   final tx = Transaction(
                     id: newTxId,
                     title: 'Liquidación deuda: $clientName',
                     amount: pendingTotal,
                     date: DateTime.now(),
                     type: TransactionType.income,
                     category: selectedMethod, 
                   );
                   txProvider.addTransaction(tx);
                   
                   // Mark all as paid
                   provider.settleClientDebt(clientName, newTxId);
                   
                   Navigator.pop(context); // Close dialog
                }, 
                child: const Text('LIQUIDAR', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildPaymentOption(String label, TransactionCategory value, TransactionCategory groupValue, Function(TransactionCategory) onChanged) {
    return RadioListTile<TransactionCategory>(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      value: value,
      groupValue: groupValue,
      onChanged: (val) {
        if (val != null) onChanged(val);
      },
      activeColor: const Color(0xFF10B981),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}
