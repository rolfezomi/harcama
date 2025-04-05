import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  final Function(String)? onPremiumFeatureRequested;

  const SettingsPage({
    super.key,
    this.onPremiumFeatureRequested,
  });

  void _showThemeDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tema Seçenekleri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<bool>(
              title: const Text('Açık Tema'),
              value: false,
              groupValue: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.setTheme(false);
                Navigator.pop(context);
              },
            ),
            RadioListTile<bool>(
              title: const Text('Koyu Tema'),
              value: true,
              groupValue: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.setTheme(true);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Diğer metodlar aynı kalacak...

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // Tema Ayarları
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Tema'),
            subtitle: Text(themeProvider.isDarkMode ? 'Koyu Mod' : 'Açık Mod'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context),
          ),

          // Diğer liste öğeleri aynı kalacak...
        ],
      ),
    );
  }
}
