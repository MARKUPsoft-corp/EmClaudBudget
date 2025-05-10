import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budget_express/core/constants/app_constants.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Préférences
  bool _useDarkMode = false;
  bool _useSystemTheme = true;
  String _currencyFormat = '€';
  String _dateFormat = AppConstants.dateFormat;
  
  // État de chargement
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }
  
  // Charger les préférences
  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _useDarkMode = prefs.getBool('useDarkMode') ?? false;
        _useSystemTheme = prefs.getBool('useSystemTheme') ?? true;
        _currencyFormat = prefs.getString('currencyFormat') ?? '€';
        _dateFormat = prefs.getString('dateFormat') ?? AppConstants.dateFormat;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Sauvegarder les préférences
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('useDarkMode', _useDarkMode);
      await prefs.setBool('useSystemTheme', _useSystemTheme);
      await prefs.setString('currencyFormat', _currencyFormat);
      await prefs.setString('dateFormat', _dateFormat);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Préférences sauvegardées'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde des préférences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Apparence
                  _buildSectionHeader(context, 'Apparence'),
                  const SizedBox(height: 16),
                  
                  _buildThemeSettings(),
                  const SizedBox(height: 24),
                  
                  // Section Formats
                  _buildSectionHeader(context, 'Formats'),
                  const SizedBox(height: 16),
                  
                  _buildFormatSettings(),
                  const SizedBox(height: 24),
                  
                  // Section À propos
                  _buildSectionHeader(context, 'À propos'),
                  const SizedBox(height: 16),
                  
                  _buildAboutSection(),
                  const SizedBox(height: 24),
                  
                  // Section Raccourcis clavier (uniquement pour Linux)
                  if (defaultTargetPlatform == TargetPlatform.linux) ...[
                    _buildSectionHeader(context, 'Raccourcis clavier'),
                    const SizedBox(height: 16),
                    
                    _buildKeyboardShortcutsSection(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Bouton de sauvegarde
                  Center(
                    child: ElevatedButton(
                      onPressed: _savePreferences,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text('Sauvegarder les préférences'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  // En-tête de section
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Divider(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          thickness: 1,
        ),
      ],
    );
  }
  
  // Paramètres du thème
  Widget _buildThemeSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Utiliser le thème du système
            SwitchListTile(
              title: const Text('Utiliser le thème du système'),
              subtitle: const Text('L\'application s\'adaptera automatiquement au thème de votre appareil'),
              value: _useSystemTheme,
              onChanged: (value) {
                setState(() {
                  _useSystemTheme = value;
                });
                
                if (value) {
                  AdaptiveTheme.of(context).setSystem();
                } else {
                  if (_useDarkMode) {
                    AdaptiveTheme.of(context).setDark();
                  } else {
                    AdaptiveTheme.of(context).setLight();
                  }
                }
              },
            ),
            
            // Option mode sombre (uniquement si thème système désactivé)
            if (!_useSystemTheme)
              SwitchListTile(
                title: const Text('Mode sombre'),
                subtitle: const Text('Utiliser un thème sombre pour l\'application'),
                value: _useDarkMode,
                onChanged: (value) {
                  setState(() {
                    _useDarkMode = value;
                  });
                  
                  if (value) {
                    AdaptiveTheme.of(context).setDark();
                  } else {
                    AdaptiveTheme.of(context).setLight();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
  
  // Paramètres de format
  Widget _buildFormatSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Format de devise
            ListTile(
              title: const Text('Format de devise'),
              subtitle: Text('Actuellement: $_currencyFormat'),
              trailing: DropdownButton<String>(
                value: _currencyFormat,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _currencyFormat = value;
                    });
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: '€',
                    child: Text('Euro (€)'),
                  ),
                  DropdownMenuItem(
                    value: '\$',
                    child: Text('Dollar (\$)'),
                  ),
                  DropdownMenuItem(
                    value: '£',
                    child: Text('Livre (£)'),
                  ),
                ],
              ),
            ),
            
            const Divider(),
            
            // Format de date
            ListTile(
              title: const Text('Format de date'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Actuellement: $_dateFormat'),
                  Text(
                    'Exemple: ${DateFormat(_dateFormat).format(DateTime.now())}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              trailing: DropdownButton<String>(
                value: _dateFormat,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _dateFormat = value;
                    });
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: 'dd/MM/yyyy',
                    child: Text('JJ/MM/AAAA'),
                  ),
                  DropdownMenuItem(
                    value: 'MM/dd/yyyy',
                    child: Text('MM/JJ/AAAA'),
                  ),
                  DropdownMenuItem(
                    value: 'yyyy-MM-dd',
                    child: Text('AAAA-MM-JJ'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Section À propos
  Widget _buildAboutSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const ListTile(
              leading: Icon(Icons.info),
              title: Text('Budget Express'),
              subtitle: Text('Version 1.0.0'),
            ),
            
            const Divider(),
            
            const ListTile(
              title: Text('Développé avec Flutter'),
              subtitle: Text('Une application de gestion financière personnelle'),
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Confidentialité'),
              subtitle: const Text('Toutes vos données sont stockées localement et ne sont jamais partagées'),
              onTap: () {
                // Afficher les détails de confidentialité
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Politique de confidentialité'),
                    content: const SingleChildScrollView(
                      child: Text(
                        'Budget Express respecte votre vie privée. Toutes vos données financières sont stockées uniquement sur votre appareil et ne sont jamais envoyées à des serveurs externes. Nous ne collectons aucune information personnelle ou d\'utilisation. Cette application fonctionne entièrement hors ligne pour garantir la sécurité et la confidentialité de vos informations financières.',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fermer'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // Section Raccourcis clavier (uniquement pour Linux)
  Widget _buildKeyboardShortcutsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...AppConstants.keyboardShortcuts.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        entry.key,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(entry.value),
                  ],
                ),
              );
            }).toList(),
            
            const SizedBox(height: 16),
            const Text(
              'Note: Ces raccourcis clavier sont disponibles uniquement sur la version Linux.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
