import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';

class AddTransactionSheet extends StatefulWidget {
  final TransactionType type;
  final double? initialAmount;
  const AddTransactionSheet({super.key, required this.type, this.initialAmount});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController(); // New controller
  TransactionCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    // Pre-fill amount if provided
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount.toString();
    }

    // Set default category based on type
    if (widget.type == TransactionType.income) {
      _selectedCategory = TransactionCategory.salesCash;
      _titleController.text = 'Venta';
    } else {
      _selectedCategory = TransactionCategory.supplier;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.type == TransactionType.income;
    final color = isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isIncome ? 'Nuevo Ingreso' : 'Nuevo Gasto',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
               IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Amount Input
          TextField(
            controller: _amountController,
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
          // Title Input
          TextField(
            controller: _titleController,
            readOnly: isIncome, // Fixed to Venta for Income
            style: TextStyle(color: isIncome ? Colors.grey : Colors.white),
            decoration: InputDecoration(
              labelText: 'Concepto',
              labelStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          // Description Input (Optional)
          if (isIncome) ...[
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Comentarios (Opcional)',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.comment, color: Colors.grey, size: 20),
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          if (!isIncome) const SizedBox(height: 24),

          // Category Selection
          const Text('Tipo', style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: isIncome 
              ? [
                  _buildCategoryChip(TransactionCategory.salesCash, 'Efectivo', Icons.payments),
                  _buildCategoryChip(TransactionCategory.salesCard, 'Tarjeta', Icons.credit_card),
                  _buildCategoryChip(TransactionCategory.salesTransfer, 'Transferencia', Icons.account_balance),
                ]
              : [
                  _buildCategoryChip(TransactionCategory.supplier, 'Proveedor', Icons.local_shipping),
                  _buildCategoryChip(TransactionCategory.various, 'Varios', Icons.receipt_long),
                ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Guardar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(TransactionCategory category, String label, IconData icon) {
    final isSelected = _selectedCategory == category;
    final color = Theme.of(context).primaryColor;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedCategory = category);
      },
      backgroundColor: Colors.white.withOpacity(0.05),
      selectedColor: color,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.5)),
      ),
    );
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || _titleController.text.isEmpty || _selectedCategory == null) return;
    
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final date = provider.selectedDate;
    
    final now = DateTime.now();
    final transactionDate = DateTime(
      date.year,
      date.month,
      date.day,
      now.hour,
      now.minute,
      now.second
    );

    final tx = Transaction(
      id: DateTime.now().toString(),
      title: _titleController.text,
      amount: amount,
      date: transactionDate,
      type: widget.type,
      category: _selectedCategory!,
      description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
    );

    provider.addTransaction(tx);
    Navigator.pop(context);
  }
}
