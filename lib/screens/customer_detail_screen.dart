import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database/database_helper.dart';
import '../models/customer.dart';
import '../models/transaction.dart';
import '../utils/app_theme.dart';
import '../utils/language_manager.dart';
import 'add_transaction_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  List<UdhaarTransaction> _transactions = [];
  double _pendingAmount = 0;
  bool _isLoading = true;
  int _transactionCount = 0;
  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadInterstitialAd();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final transactions = await DatabaseHelper.instance
        .getTransactionsByCustomer(widget.customer.id!);
    final pending =
        await DatabaseHelper.instance.getPendingAmount(widget.customer.id!);

    // Get transaction count for ad trigger
    final prefs = await SharedPreferences.getInstance();
    _transactionCount = prefs.getInt('transaction_count') ?? 0;

    setState(() {
      _transactions = transactions;
      _pendingAmount = pending;
      _isLoading = false;
    });
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712', // Test ID
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (_) => _interstitialAd = null,
      ),
    );
  }

  Future<void> _showAdIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    _transactionCount++;
    await prefs.setInt('transaction_count', _transactionCount);

    // Show ad every 5th transaction
    if (_transactionCount % 5 == 0 && _interstitialAd != null) {
      await _interstitialAd!.show();
      _interstitialAd = null;
      _loadInterstitialAd();
    }
  }

  Future<void> _openWhatsApp() async {
    final prefs = await SharedPreferences.getInstance();
    final storeName = prefs.getString('store_name') ?? 'UdhaarBook';

    String message = LanguageManager.get('whatsapp_message')
        .replaceAll('{name}', widget.customer.name)
        .replaceAll('{store}', storeName)
        .replaceAll('{amount}', _pendingAmount.toStringAsFixed(0));

    final phone = widget.customer.phone ?? '';
    final url = phone.isNotEmpty
        ? 'https://wa.me/91$phone?text=${Uri.encodeComponent(message)}'
        : 'https://wa.me/?text=${Uri.encodeComponent(message)}';

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp not installed')),
      );
    }
  }

  Future<void> _deleteCustomer() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(LanguageManager.get('delete_customer')),
        content: Text(LanguageManager.get('delete_confirm')),
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

    if (confirm == true) {
      await DatabaseHelper.instance.deleteCustomer(widget.customer.id!);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCleared = _pendingAmount <= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer.name),
        actions: [
          // WhatsApp button
          IconButton(
            icon: const Icon(Icons.whatsapp_rounded),
            onPressed: _pendingAmount > 0 ? _openWhatsApp : null,
            tooltip: LanguageManager.get('whatsapp_reminder'),
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _deleteCustomer,
            color: Colors.white,
          ),
        ],
      ),
      body: Column(
        children: [
          // Pending amount card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCleared
                    ? [const Color(0xFF2E7D32), const Color(0xFF43A047)]
                    : [const Color(0xFFB71C1C), const Color(0xFFD32F2F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isCleared ? Colors.green : Colors.red)
                      .withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LanguageManager.get('current_pending'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '₹${_pendingAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.customer.phone != null &&
                    widget.customer.phone!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      widget.customer.phone!,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isCleared
                        ? LanguageManager.get('cleared')
                        : LanguageManager.get('pending'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Add Udhaar
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddTransactionScreen(
                            customer: widget.customer,
                            type: 'udhaar',
                          ),
                        ),
                      );
                      await _showAdIfNeeded();
                      _loadData();
                    },
                    icon: const Icon(Icons.arrow_upward_rounded),
                    label: Text(LanguageManager.get('add_udhaar')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorRed,
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Record Payment
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddTransactionScreen(
                            customer: widget.customer,
                            type: 'payment',
                            currentPending: _pendingAmount,
                          ),
                        ),
                      );
                      await _showAdIfNeeded();
                      _loadData();
                    },
                    icon: const Icon(Icons.arrow_downward_rounded),
                    label: Text(LanguageManager.get('record_payment')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.lightGreen,
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Transaction history header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  LanguageManager.get('transaction_history'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Transaction list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryGreen,
                    ),
                  )
                : _transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              LanguageManager.get('no_transactions'),
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final tx = _transactions[index];
                          final isUdhaar = tx.isUdhaar;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isUdhaar
                                    ? AppTheme.errorRed.withOpacity(0.1)
                                    : AppTheme.lightGreen.withOpacity(0.1),
                                child: Icon(
                                  isUdhaar
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                                  color: isUdhaar
                                      ? AppTheme.errorRed
                                      : AppTheme.lightGreen,
                                ),
                              ),
                              title: Text(
                                '₹${tx.amount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: isUdhaar
                                      ? AppTheme.errorRed
                                      : AppTheme.lightGreen,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatDate(tx.date),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (tx.note != null && tx.note!.isNotEmpty)
                                    Text(
                                      tx.note!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textGrey,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isUdhaar
                                      ? AppTheme.errorRed.withOpacity(0.1)
                                      : AppTheme.lightGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isUdhaar
                                      ? LanguageManager.get('add_udhaar')
                                      : LanguageManager.get('record_payment'),
                                  style: TextStyle(
                                    color: isUdhaar
                                        ? AppTheme.errorRed
                                        : AppTheme.lightGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}