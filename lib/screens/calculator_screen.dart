import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import '../models/transaction_model.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/add_receivable_sheet.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _expression = '';
  String _result = '0';

  void _onPressed(String text) {
    setState(() {
      if (text == 'C') {
        _expression = '';
        _result = '0';
      } else if (text == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else if (text == '%') {
        _expression += '%';
      } else if (text == '=') {
        try {
          Parser p = Parser();
          // Replace visual operators with math ones
          String sanitized = _expression.replaceAll('x', '*').replaceAll('÷', '/');
          
          // Handle percentages:
          // 1. "N % M"  -> "(N * M / 100)"
          // 2. "N %"    -> "(N / 100)"
          
          // Regex for "Number % Number": (\d+(?:\.\d+)?)[\s]*%[\s]*(\d+(?:\.\d+)?)
          // Note: MathExpressions might interpret % as Modulo if we don't replace it carefully.
          // We want to replace it before parsing.
          
          // First, handle "Number % Number" which we want to be "Number * Number / 100"
          // AND handle the case where it might be `50 + 10 % 5` or something.
          
          // Wait, the user specifically said: "al escribir 9800%56". 
          // If I just typed `9800%56`, `math_expressions` sees `9800 % 56` (Modulo).
          // I want to replace that pattern.
          
          // Regex to match: Any number, followed by %, followed by Any number.
          sanitized = sanitized.replaceAllMapped(
            RegExp(r'(\d+(?:\.\d+)?)%(\d+(?:\.\d+)?)'), 
            (Match m) => '(${m[1]} * ${m[2]} / 100)'
          );
          
          // After handling binary %, handle unary % (e.g., "50%").
          // Be careful not to replace the % we just inserted inside the new string logic if we did it wrong.
          // But our replacement above removed the `%`.
          // So any remaining `%` should be unary.
          
          sanitized = sanitized.replaceAllMapped(
            RegExp(r'(\d+(?:\.\d+)?)%'), 
            (Match m) => '(${m[1]} / 100)'
          );

          Expression exp = p.parse(sanitized);
          ContextModel cm = ContextModel();
          double eval = exp.evaluate(EvaluationType.REAL, cm);
          
          // Format result to remove .0 if integer
          if (eval % 1 == 0) {
            _result = eval.toInt().toString();
          } else {
            _result = eval.toStringAsFixed(2);
          }
        } catch (e) {
          _result = 'Error';
        }
      } else {
        _expression += text;
      }
    });
  }

  void _onAction(BuildContext context, String actionType) {
    // Ensure we have a valid number to pass
    double? amount;
    // If expression is empty but result is 0, passed 0.
    // If expression is like "5+5", we should probably evaluate first or just use current result if it was already calculated.
    // User might type "50" and hit Green button.
    
    // Strategy: Try to parse expression. If "Error" or empty, parse result.
    // simpler: If expression has operators, try evaluate. Else parse expression.
    
    String textToParse = _result;
    
    // If user just typed "100" without "=", expression is "100", result is "0" (default). 
    // We should take expression if result is default 0 and expression is numeric.
    if (_result == '0' && _expression.isNotEmpty) {
      // Check if expression is just a number
      if (double.tryParse(_expression) != null) {
        textToParse = _expression;
      } else {
        // Evaluate it
        try {
           Parser p = Parser();
           String sanitized = _expression.replaceAll('x', '*').replaceAll('÷', '/');
           sanitized = sanitized.replaceAllMapped(
             RegExp(r'(\d+(?:\.\d+)?)%(\d+(?:\.\d+)?)'), 
             (Match m) => '(${m[1]} * ${m[2]} / 100)'
           );
           sanitized = sanitized.replaceAllMapped(
             RegExp(r'(\d+(?:\.\d+)?)%'), 
             (Match m) => '(${m[1]} / 100)'
           );
           Expression exp = p.parse(sanitized);
           ContextModel cm = ContextModel();
           double eval = exp.evaluate(EvaluationType.REAL, cm);
           textToParse = eval.toString();
        } catch(e) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Operación inválida')));
           return;
        }
      }
    } else if (_result == 'Error') {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error en cálculo')));
       return;
    }
    
    amount = double.tryParse(textToParse);

    if (amount == null) return;

    if (actionType == 'income') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF101922), // Matching existing theme
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) => AddTransactionSheet(type: TransactionType.income, initialAmount: amount),
      );
    } else if (actionType == 'expense') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF101922),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) => AddTransactionSheet(type: TransactionType.expense, initialAmount: amount),
      );
    } else if (actionType == 'receivable') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF101922),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) => AddReceivableSheet(initialAmount: amount),
      );
    }
    
    // Optional: Clear after action?
    // setState(() { _expression = ''; _result = '0'; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.grey : Colors.grey.shade600;
    
    // Custom button builder
    Widget buildButton(String text, {Color? color, Color? textColor, int flex = 1}) {
      final defaultBtnColor = isDark ? Theme.of(context).cardColor : Colors.white;
      // If no specific text color provided, use black for light mode, white for dark
      final defaultTxtColor = textColor ?? (isDark ? Colors.white : Colors.black87);
      
      return Expanded(
        flex: flex,
        child: Container(
          margin: const EdgeInsets.all(4),
          child: ElevatedButton(
            onPressed: () => _onPressed(text),
            style: ElevatedButton.styleFrom(
              backgroundColor: color ?? defaultBtnColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: EdgeInsets.zero, // Remove fixed padding
              minimumSize: const Size(double.infinity, double.infinity), // Fill the container
              elevation: 2, 
              shadowColor: Colors.black12,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: defaultTxtColor,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Action buttons remain colored so text is always white on them
    Widget buildActionButton(Color color, IconData icon, String label, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8), // Reduce/Remove vertical padding, use centering
            height: double.infinity, // Fill height of row
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(height: 4),
                Text(label, 
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
           SizedBox(height: MediaQuery.of(context).padding.top),
           // Display Area
           Expanded(
             flex: 3,
             child: Container(
               width: double.infinity,
               padding: const EdgeInsets.all(16),
               alignment: Alignment.bottomRight,
               child: FittedBox(
                 fit: BoxFit.scaleDown,
                 alignment: Alignment.centerRight,
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.end,
                   crossAxisAlignment: CrossAxisAlignment.end,
                   children: [
                     Text(
                       _expression,
                       style: TextStyle(fontSize: 32, color: secondaryTextColor),
                     ),
                     const SizedBox(height: 4),
                     Text(
                       _result == '0' && _expression.isNotEmpty && double.tryParse(_expression) != null 
                           ? _expression 
                           : _result,
                       style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: textColor),
                     ),
                   ],
                 ),
               ),
             ),
           ),
           
           Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
           
            // Action Buttons - Fixed height to prevent squashing
            SizedBox(
              height: 64, 
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                child: Row(
                  children: [
                    buildActionButton(const Color(0xFF10B981), Icons.add, 'Ingreso', () => _onAction(context, 'income')),
                    buildActionButton(const Color(0xFFEF4444), Icons.remove, 'Egreso', () => _onAction(context, 'expense')),
                    buildActionButton(const Color(0xFFF59E0B), Icons.person_add, 'Fiar', () => _onAction(context, 'receivable')),
                  ],
                ),
              ),
            ),

           Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),

           // Keypad
           Expanded(
             flex: 5,
             // No flex value needed, just take remaining space
             child: Padding(
               padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          buildButton('C', textColor: const Color(0xFFEF4444)),
                          buildButton('÷', textColor: const Color(0xFF2563EB)),
                          buildButton('x', textColor: const Color(0xFF2563EB)),
                          buildButton('⌫', textColor: const Color(0xFFEF4444)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          buildButton('7'),
                          buildButton('8'),
                          buildButton('9'),
                          buildButton('-', textColor: const Color(0xFF2563EB)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          buildButton('4'),
                          buildButton('5'),
                          buildButton('6'),
                          buildButton('+', textColor: const Color(0xFF2563EB)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          buildButton('1'),
                          buildButton('2'),
                          buildButton('3'),
                          buildButton('=', color: const Color(0xFF2563EB), textColor: Colors.white),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          buildButton('%'),
                          buildButton('0', flex: 2), // Span 2 columns to align grid
                          buildButton('.'),
                        ],
                      ),
                    ),
                  ],
                ),
             ),
           ),
           SizedBox(height: MediaQuery.of(context).padding.bottom + 16), // Bottom safe area
        ],
      ),
    );
  }
}
