import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/language_manager.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _storeNameController = TextEditingController();
  int _currentPage = 0;
  String _errorText = '';

  final List<Map<String, dynamic>> _slides = [
    {
      'icon': Icons.person_add_rounded,
      'color': Color(0xFF1B5E20),
    },
    {
      'icon': Icons.account_balance_wallet_rounded,
      'color': Color(0xFF1B5E20),
    },
    {
      'icon': Icons.whatsapp_rounded,
      'color': Color(0xFF1B5E20),
    },
  ];

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finish() async {
    final storeName = _storeNameController.text.trim();
    if (storeName.isEmpty) {
      setState(() {
        _errorText = LanguageManager.get('error_store_name');
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('store_name', storeName);
    await prefs.setBool('is_first_launch', false);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _storeNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Page View
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                    _errorText = '';
                  });
                },
                children: [
                  // Slide 1
                  _buildSlide(
                    icon: _slides[0]['icon'],
                    color: _slides[0]['color'],
                    title: LanguageManager.get('onboard_title_1'),
                    desc: LanguageManager.get('onboard_desc_1'),
                  ),

                  // Slide 2
                  _buildSlide(
                    icon: _slides[1]['icon'],
                    color: _slides[1]['color'],
                    title: LanguageManager.get('onboard_title_2'),
                    desc: LanguageManager.get('onboard_desc_2'),
                  ),

                  // Slide 3 — Store name input
                  _buildLastSlide(),
                ],
              ),
            ),

            // Dots indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppTheme.primaryGreen
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: _currentPage < 2 ? _nextPage : _finish,
                child: Text(
                  _currentPage < 2
                      ? LanguageManager.get('continue_btn')
                      : LanguageManager.get('get_started'),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon circle
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 72, color: color),
          ),

          const SizedBox(height: 48),

          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            desc,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textGrey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLastSlide() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.store_rounded,
              size: 72,
              color: AppTheme.primaryGreen,
            ),
          ),

          const SizedBox(height: 40),

          Text(
            LanguageManager.get('onboard_title_3'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            LanguageManager.get('enter_store_name'),
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textGrey,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Store name input
          TextField(
            controller: _storeNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: LanguageManager.get('store_name'),
              hintText: LanguageManager.get('store_name_hint'),
              prefixIcon: const Icon(
                Icons.store_rounded,
                color: AppTheme.primaryGreen,
              ),
              errorText: _errorText.isEmpty ? null : _errorText,
            ),
            onChanged: (_) {
              if (_errorText.isNotEmpty) {
                setState(() => _errorText = '');
              }
            },
          ),
        ],
      ),
    );
  }
}