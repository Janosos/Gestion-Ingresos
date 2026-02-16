import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/receivable_provider.dart';

class AddReceivableSheet extends StatefulWidget {
  final String? prefilledName;
  final double? initialAmount;

  const AddReceivableSheet({
    super.key,
    this.prefilledName,
    this.initialAmount,
  });

  @override
  State<AddReceivableSheet> createState() => _AddReceivableSheetState();
}

class _AddReceivableSheetState extends State<AddReceivableSheet> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.prefilledName);
    _amountController = TextEditingController(
      text: widget.initialAmount != null ? widget.initialAmount.toString() : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          // AutoComplete for Client Name
          Consumer<ReceivableProvider>(
            builder: (context, provider, child) {
              final options = provider.groupedReceivables.keys.toList();
              
              return Autocomplete<String>(
                initialValue: TextEditingValue(text: _nameController.text),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return options.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  _nameController.text = selection;
                },
                fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                  // Sync logic: update local controller if user types, but Autocomplete uses its own controller in this builder.
                  // We need to ensure specific behavior.
                  // Actually, better to just bind the textEditingController from builder to our logic?
                  // Or just use the one provided by Autocomplete as THE controller.
                  // But we need to access it in _submit.
                  // Solution: Update our _nameController on change, or just assign the one from builder to _nameController (if possible? no, late init).
                  // Better: internal listener.
                  
                  // Simple hack: Just use the controller provided by builder for everything?
                  // But we have logic in initState to set text.
                  // Autocomplete has initialValue.
                  
                  // Let's hook the controller.
                  if (textEditingController.text != _nameController.text) {
                     textEditingController.text = _nameController.text;
                  }
                  
                  // Listen to changes to update our internal controller if needed, or just refer to this one?
                  // We can't easily refer to it outside.
                  // So we'll update _nameController value when this changes.
                  
                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    enabled: widget.prefilledName == null,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nombre del Cliente',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) => _nameController.text = val,
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      color: const Color(0xFF1E293B),
                      elevation: 4.0,
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width - 48, // Match parent padding
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return ListTile(
                              title: Text(option, style: const TextStyle(color: Colors.white)),
                              onTap: () {
                                onSelected(option);
                                _nameController.text = option;
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(_amountController.text);
              if (amount == null || _nameController.text.isEmpty) return;
              
              Provider.of<ReceivableProvider>(context, listen: false).addReceivable(_nameController.text, amount);
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
    );
  }
}
