import 'package:flutter/material.dart';
import '../theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Donasi Menjadi Mudah',
      'description':
          'Donasiku adalah platform untuk memberikan donasi barang layak pakai ke berbagai kalangan.',
      'image': 'assets/images/image 1.png',
      'icon': Icons.volunteer_activism_rounded,
      'color': AppTheme.primaryBlue,
    },
    {
      'title': 'Punya Barang Bekas\nLayak Pakai?',
      'description':
          'Jangan biarkan barang tak terpakai menumpuk. Donasikan dengan mudah lewat Donasiku.',
      'image': 'assets/images/image 1 (1).png',
      'icon': Icons.recycling_rounded,
      'color': AppTheme.emeraldGreen,
    },
    {
      'title': 'Maknai Setiap Hidup\nSebagai Donatur',
      'description':
          'Setiap donasi membawa harapan baru. Jadilah bagian dari perubahan.',
      'image': 'assets/images/image 1 (2).png',
      'icon': Icons.favorite_rounded,
      'color': AppTheme.coral,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/images/logo.png', height: 32),
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/policy'),
                      child: Text(
                        'Lewati',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Page Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (int page) {
                  setState(() => _currentPage = page);
                },
                itemBuilder: (context, index) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Padding(
                      key: ValueKey(index),
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Image Container
                          Container(
                            height: 280,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: (_pages[index]['color'] as Color).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: Image.asset(
                                _pages[index]['image']!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 48),
                          // Title
                          Text(
                            _pages[index]['title']!,
                            style: AppTheme.headingLarge.copyWith(fontSize: 26),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          // Description
                          Text(
                            _pages[index]['description']!,
                            style: AppTheme.bodyLarge.copyWith(
                              color: AppTheme.textGrey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Section
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Column(
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        width: _currentPage == index ? 32 : 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? (_pages[_currentPage]['color'] as Color)
                              : AppTheme.borderGrey,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          Navigator.pushNamed(context, '/policy');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage]['color'] as Color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == _pages.length - 1
                                ? 'Mulai Donasi'
                                : 'Lanjut',
                            style: AppTheme.buttonText,
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
