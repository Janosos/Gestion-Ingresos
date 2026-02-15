import 'package:flutter/material.dart';
import 'income_screen.dart';
import 'dashboard_screen.dart';
import 'receivable_screen.dart';
import 'supplier_screen.dart'; 
import 'settings_screen.dart'; // Import this

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(), // Inicio
    const IncomeScreen(),    // Ingresos
    const SupplierScreen(),  // Proveedores
    const ReceivableScreen(), // Cobrar
    const SettingsScreen(),   // Ajustes
  ];



  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        height: 84, // Explicit height from HTML
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
        ),
        padding: const EdgeInsets.only(bottom: 16), // Adjust for bottom safe area visual
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.dashboard, 'Inicio', 0),
            _buildNavItem(Icons.account_balance_wallet, 'Ingresos', 1),
            _buildNavItem(Icons.local_shipping, 'Prov.', 2),
             _buildNavItem(Icons.pending_actions, 'Cobrar', 3), // Using pending_actions for Cobrar
            _buildNavItem(Icons.settings, 'Ajustes', 4),
          ],
        ),
      ),
    );
  }


  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? Theme.of(context).primaryColor : Colors.grey.shade400; // Muted color from HTML
    
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: SizedBox(
        width: 64, // Touch target
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
