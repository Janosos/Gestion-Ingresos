import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/receivable_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/add_transaction_sheet.dart';
import '../models/transaction_model.dart';
import 'package:intl/date_symbol_data_local.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  
  @override
  void initState() {
    super.initState();
    // Ensure we sync settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      Provider.of<TransactionProvider>(context, listen: false).updateWeekStart(settings.startWeekOnSunday);
    });
  }

  @override
  Widget build(BuildContext context) {
     final txProvider = Provider.of<TransactionProvider>(context);
     final recvProvider = Provider.of<ReceivableProvider>(context);
     final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
           SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 20.0), // Reduced from all(20)
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const SizedBox(height: 10), // Reduced from 40
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildDateFilters(txProvider),
                  const SizedBox(height: 24),
                  _buildTotalBalance(txProvider, currencyFormat),
                  const SizedBox(height: 32),
                  const Text('Resumen Financiero', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildSummaryCardsGrid(txProvider, recvProvider, currencyFormat),
                  const SizedBox(height: 24),
                  _buildQuickActions(context),
                  const SizedBox(height: 24),
                  _buildRecentTransactions(txProvider, currencyFormat),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
      children: [
        // Message (Left)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bienvenido,', style: TextStyle(fontSize: 14, color: Theme.of(context).hintColor, fontWeight: FontWeight.w500)),
            Text('Abarrotes Tito', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.2, color: Theme.of(context).textTheme.bodyLarge?.color)),
          ],
        ),
        // Logo (Right)
        Container(
          height: 60,
          width: 60,
          margin: const EdgeInsets.only(left: 8), 
          // Better approach: Use Image.asset inside child
          child: Image.asset(
            'assets/Tito_sinfondo.png',
            fit: BoxFit.contain,
            color: Theme.of(context).brightness == Brightness.light ? Colors.black : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDateFilters(TransactionProvider provider) {
     return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFilterChip('Hoy', DateFilterType.day, provider),
          const SizedBox(width: 8),
          _buildFilterChip('Esta Semana', DateFilterType.week, provider),
          const SizedBox(width: 8),
          _buildFilterChip('Este Mes', DateFilterType.month, provider),
          const SizedBox(width: 8),
           GestureDetector(
            onTap: () => _showCalendar(context, provider),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: provider.filterType == DateFilterType.custom 
                    ? const Color(0xFF137FEC) 
                    : Theme.of(context).dividerColor
                ),
                color: provider.filterType == DateFilterType.custom 
                    ? const Color(0xFF137FEC).withOpacity(0.2) 
                    : Colors.transparent,
              ),
              child: Icon(
                Icons.calendar_month, 
                size: 20, 
                color: provider.filterType == DateFilterType.custom 
                    ? const Color(0xFF137FEC) 
                    : Theme.of(context).iconTheme.color
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, DateFilterType type, TransactionProvider provider) {
    final isSelected = provider.filterType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => provider.setFilterType(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF137FEC) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: isSelected ? null : Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Future<void> _showCalendar(BuildContext context, TransactionProvider provider) async {
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
    if (picked != null) {
      provider.setDate(picked); // Set the specific date
      provider.setFilterType(DateFilterType.day); // Switch to day view for that date
    }
  }

  Widget _buildTotalBalance(TransactionProvider provider, NumberFormat currencyFormat) {
    final balance = provider.filteredBalance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getBalanceLabel(provider.filterType), 
          style: TextStyle(fontSize: 14, color: Theme.of(context).hintColor, fontWeight: FontWeight.w500)
        ),
        const SizedBox(height: 4),
        Text(
          currencyFormat.format(balance), 
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1, color: Theme.of(context).textTheme.bodyLarge?.color)
        ),
      ],
    );
  }
  
  String _getBalanceLabel(DateFilterType type) {
    switch (type) {
      case DateFilterType.day: return 'Balance del Día';
      case DateFilterType.week: return 'Balance de la Semana';
      case DateFilterType.month: return 'Balance del Mes';
      case DateFilterType.custom: return 'Balance Seleccionado';
    }
  }

  // ...

  Widget _buildSummaryCardsGrid(TransactionProvider txProvider, ReceivableProvider recvProvider, NumberFormat currencyFormat) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1, 
      children: [
        _buildSummaryCard(
          title: 'Efectivo en Caja',
          amount: currencyFormat.format(txProvider.totalCashIncome),
          icon: Icons.payments,
          color: const Color(0xFF10B981),
        ),
         _buildSummaryCard(
          title: 'Tarjetas/Transf.',
          amount: currencyFormat.format(txProvider.totalCardIncome + txProvider.totalTransferIncome),
          icon: Icons.credit_card,
          color: const Color(0xFF137FEC),
        ),
         _buildSummaryCard(
          title: 'Por Cobrar',
          amount: currencyFormat.format(recvProvider.totalOutstanding),
          icon: Icons.pending_actions,
          color: const Color(0xFFF59E0B),
        ),
         _buildSummaryCard(
          title: 'A Proveedores',
          amount: '-${currencyFormat.format(txProvider.totalSupplierExpenses)}',
          icon: Icons.local_shipping,
          color: const Color(0xFFEF4444),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Icon(icon, color: color.withOpacity(0.1), size: 48), 
            ],
          ),
          const Spacer(),
          Text(title, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(amount, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context, 
            Icons.add_circle, 
            'Ingreso', 
            const Color(0xFF10B981), 
            () => _showAddTransactionDialog(context, TransactionType.income)
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            context, 
            Icons.remove_circle, 
            'Gasto', 
            const Color(0xFFEF4444), 
            () => _showAddTransactionDialog(context, TransactionType.expense)
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: const Color(0xFF137FEC).withOpacity(0.05), // Slight tint
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
          ],
        ),
      ),
    );
  }


  Widget _buildRecentTransactions(TransactionProvider provider, NumberFormat currencyFormat) {
    final recents = provider.recentTransactions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Movimientos recientes (día en curso)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recents.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final tx = recents[index];
            final isIncome = tx.type == TransactionType.income;
            
            String subtitle = '';
            if (isIncome) {
              switch (tx.category) {
                case TransactionCategory.salesCash: subtitle = 'Ingreso - Efectivo'; break;
                case TransactionCategory.salesCard: subtitle = 'Ingreso - Tarjeta'; break;
                case TransactionCategory.salesTransfer: subtitle = 'Ingreso - Transferencia'; break;
                default: subtitle = 'Ingreso';
              }
            } else {
              subtitle = 'Gasto - ${_getCategoryLabel(tx.category)}';
            }

            return Container(
              padding: const EdgeInsets.all(12),
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
                      color: isIncome ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      isIncome ? Icons.arrow_downward : Icons.arrow_upward, 
                      color: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      size: 20
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tx.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
                        Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                      ],
                    ),
                  ),
                  Text(
                    '${isIncome ? '+' : '-'}${currencyFormat.format(tx.amount)}',
                    style: TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.bold, 
                      color: isIncome ? const Color(0xFF10B981) : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                    )
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _getCategoryLabel(TransactionCategory category) {
    if (category == TransactionCategory.supplier) return 'Proveedores';
    return category.name;
  }


  void _showAddTransactionDialog(BuildContext context, TransactionType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101922),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AddTransactionSheet(type: type),
    );
  }
}
