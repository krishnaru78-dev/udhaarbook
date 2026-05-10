import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../utils/app_theme.dart';
import '../utils/language_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _storePhoneController = TextEditingController();
  String _selectedLanguage = 'en';

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'hi', 'name': 'हिंदी'},
    {'code': 'mr', 'name': 'मराठी'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _storeNameController.text = prefs.getString('store_name') ?? '';
      _storePhoneController.text = prefs.getString('store_phone') ?? '';
      _selectedLanguage = prefs.getString('language') ?? 'en';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('store_name', _storeNameController.text.trim());
    await prefs.setString('store_phone', _storePhoneController.text.trim());
    await prefs.setString('language', _selectedLanguage);
    await LanguageManager.setLanguage(_selectedLanguage);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Settings saved!'),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _clearAllData() async {
    // First confirmation
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(LanguageManager.get('clear_data')),
        content: Text(LanguageManager.get('clear_data_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LanguageManager.get('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorRed,
            ),
            child: Text(LanguageManager.get('yes_delete')),
          ),
        ],
      ),
    );

    if (confirm1 != true) return;

    // Second confirmation
    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Are you absolutely sure?'),
        content: const Text(
          'This cannot be undone. ALL customers and transactions will be deleted forever.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LanguageManager.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            child: const Text('Yes, Delete Everything'),
          ),
        ],
      ),
    );

    if (confirm2 != true) return;

    await DatabaseHelper.instance.clearAllData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All data cleared!'),
        backgroundColor: AppTheme.errorRed,
      ),
    );
  }

  Future<void> _exportCSV() async {
    final data = await DatabaseHelper.instance.getAllDataForExport();

    if (data.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export!')),
      );
      return;
    }

    // Build CSV string
    final buffer = StringBuffer();
    buffer.writeln('Customer Name,Phone,Type,Amount,Note,Date');
    for (final row in data) {
      buffer.writeln(
        '${row['customer_name']},${row['phone'] ?? ''},'
        '${row['type']},${row['amount']},${row['note'] ?? ''},'
        '${row['date']}',
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('CSV export coming in next update!'),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storePhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LanguageManager.get('settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── GENERAL ──────────────────────────────────────
          _sectionHeader(LanguageManager.get('general')),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Store name
                  TextField(
                    controller: _storeNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: LanguageManager.get('store_name'),
                      prefixIcon: const Icon(
                        Icons.store_rounded,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Store phone
                  TextField(
                    controller: _storePhoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: InputDecoration(
                      labelText: LanguageManager.get('store_phone'),
                      prefixIcon: const Icon(
                        Icons.phone_rounded,
                        color: AppTheme.primaryGreen,
                      ),
                      counterText: '',
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Language selector
                  DropdownButtonFormField<String>(
                    value: _selectedLanguage,
                    decoration: InputDecoration(
                      labelText: LanguageManager.get('language'),
                      prefixIcon: const Icon(
                        Icons.language_rounded,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    items: _languages.map((lang) {
                      return DropdownMenuItem(
                        value: lang['code'],
                        child: Text(lang['name']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedLanguage = value);
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // Save button
                  ElevatedButton.icon(
                    onPressed: _saveSettings,
                    icon: const Icon(Icons.save_rounded),
                    label: Text(LanguageManager.get('save')),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── DATA ─────────────────────────────────────────
          _sectionHeader(LanguageManager.get('data')),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.file_download_rounded,
                    color: AppTheme.primaryGreen,
                  ),
                  title: Text(LanguageManager.get('export_csv')),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 16),
                  onTap: _exportCSV,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.delete_forever_rounded,
                    color: AppTheme.errorRed,
                  ),
                  title: Text(
                    LanguageManager.get('clear_data'),
                    style: const TextStyle(color: AppTheme.errorRed),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppTheme.errorRed,
                  ),
                  onTap: _clearAllData,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── MONETIZATION ─────────────────────────────────
          _sectionHeader('Monetization'),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.block_rounded,
                    color: AppTheme.accentGold,
                  ),
                  title: Text(LanguageManager.get('remove_ads')),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '₹99',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('In-app purchase coming soon!'),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppTheme.accentGold,
                  ),
                  title: Text(LanguageManager.get('upgrade_pro')),
                  subtitle: const Text('Unlimited customers, PDF, no ads'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'PRO',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pro upgrade coming soon!'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── ABOUT ────────────────────────────────────────
          _sectionHeader(LanguageManager.get('about')),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.star_rounded,
                    color: AppTheme.accentGold,
                  ),
                  title: Text(LanguageManager.get('rate_us')),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                  ),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.share_rounded,
                    color: AppTheme.primaryGreen,
                  ),
                  title: Text(LanguageManager.get('share_app')),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                  ),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.info_outline_rounded,
                    color: AppTheme.textGrey,
                  ),
                  title: Text(LanguageManager.get('version')),
                  trailing: const Text(
                    'v1.0.0',
                    style: TextStyle(
                      color: AppTheme.textGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Footer
          Center(
            child: Text(
              'Made with ❤️ for Indian Kirana Stores',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.textGrey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}