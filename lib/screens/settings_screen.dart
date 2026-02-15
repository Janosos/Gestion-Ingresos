import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/receivable_provider.dart';
import '../services/data_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Logo Section
            Center(
              child: Column(
                children: [
                   Container(
                     width: 120,
                     height: 120,
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       boxShadow: [
                         BoxShadow(
                           color: Theme.of(context).primaryColor.withOpacity(0.2),
                           blurRadius: 20,
                           offset: const Offset(0, 10),
                         ),
                       ],
                       image: DecorationImage(
                         image: const AssetImage('assets/Tito_sinfondo.png'),
                         fit: BoxFit.cover,
                         colorFilter: Theme.of(context).brightness == Brightness.light 
                           ? const ColorFilter.mode(Colors.black, BlendMode.srcIn) 
                           : null,
                       ),
                     ),
                   ),
                   const SizedBox(height: 16),
                   const Text(
                     'Abarrotes Tito', 
                     style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                   ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Settings Options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildSectionHeader(context, 'Apariencia'),
                  _buildSwitchTile(
                    context, 
                    title: 'Modo Oscuro', 
                    subtitle: 'Cambiar entre tema claro y oscuro',
                    icon: Icons.dark_mode,
                    value: isDark,
                    onChanged: (val) => settings.toggleTheme(val),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader(context, 'Datos'),
                   _buildActionTile(
                    context, 
                    title: 'Borrar todos los registros', 
                    subtitle: 'Elimina ingresos y cuentas por cobrar permanentemente',
                    icon: Icons.delete_forever,
                    color: Colors.red,
                    onTap: () => _confirmDeleteAll(context),
                  ),

                  const SizedBox(height: 24),

                  _buildSectionHeader(context, 'Copia de Seguridad'),
                  _buildActionTile(
                    context,
                    title: 'Exportar Datos',
                    subtitle: 'Guardar una copia de seguridad (ZIP)',
                    icon: Icons.upload_file,
                    onTap: () => DataService.exportData(context),
                  ),
                  const SizedBox(height: 12),
                  _buildActionTile(
                    context,
                    title: 'Importar Datos',
                    subtitle: 'Restaurar desde una copia de seguridad',
                    icon: Icons.download_for_offline,
                    onTap: () => DataService.importData(context),
                  ),
                ],
              ),
            ),
            
            // Footer
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Desarrollado por ImperioDev V1.0.0',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(BuildContext context, {
    required String title, 
    required String subtitle, 
    required IconData icon, 
    required bool value, 
    required Function(bool) onChanged
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).iconTheme.color),
        ),
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, {
    required String title, 
    required String subtitle, 
    required IconData icon, 
    Color? color,
    required VoidCallback onTap
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? Theme.of(context).primaryColor).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color ?? Theme.of(context).primaryColor),
        ),
      ),
    );
  }

  void _confirmDeleteAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('¿Estás seguro?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Esta acción borrará TODOS los registros de ingresos y cuentas por cobrar. No se puede deshacer.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              // Delete everything
              final txProvider = Provider.of<TransactionProvider>(context, listen: false);
              final rxProvider = Provider.of<ReceivableProvider>(context, listen: false);
              
              await txProvider.deleteAllTransactions();
              await rxProvider.deleteAllReceivables();
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Todos los registros han sido eliminados')),
                );
              }
            },
            child: const Text('BORRAR TODO', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
