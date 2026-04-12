import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dashboards/donor_dashboard.dart';
import 'dashboards/receiver_dashboard.dart';
import 'dashboards/admin_dashboard.dart';
import 'pending_verification_screen.dart';
import 'tracking_screen.dart';
import 'chat_list_screen.dart';
import 'profile_screen.dart';
import '../theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  String? _role;
  bool _isVerified = false;
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserRoleAndVerification();
  }

  Future<void> _fetchUserRoleAndVerification() async {
    final user = _authService.currentUser;
    if (user != null) {
      final role = await _authService.getUserRole(user.uid);
      final isVerified = await _authService.getUserVerificationStatus(user.uid);
      if (mounted) {
        setState(() {
          _role = role;
          _isVerified = isVerified;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    if (_role == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 64, color: AppTheme.errorRed),
              const SizedBox(height: 16),
              Text('Terjadi kesalahan', style: AppTheme.headingSmall),
              const SizedBox(height: 8),
              Text('Tidak dapat memuat peran pengguna', style: AppTheme.bodyMedium),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await _authService.signOut();
                  if (mounted) Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Keluar'),
              ),
            ],
          ),
        ),
      );
    }

    // Role Handling
    if (_role == 'Admin') {
      return const AdminDashboard();
    }

    if (_role == 'Penerima' && !_isVerified) {
      return const PendingVerificationScreen();
    }

    // 4-tab pages for verified roles
    final List<Widget> pages = _role == 'Donatur'
        ? [
            const DonorDashboard(),
            const TrackingScreen(),
            const ChatListScreen(),
            const ProfileScreen(),
          ]
        : [
            const ReceiverDashboard(),
            const TrackingScreen(),
            const ChatListScreen(),
            const ProfileScreen(),
          ];

    final List<BottomNavigationBarItem> navItems = _role == 'Donatur'
        ? const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined),
              activeIcon: Icon(Icons.local_shipping_rounded),
              label: 'Tracking',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_outlined),
              activeIcon: Icon(Icons.chat_rounded),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ]
        : const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore_rounded),
              label: 'Jelajahi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined),
              activeIcon: Icon(Icons.local_shipping_rounded),
              label: 'Tracking',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_outlined),
              activeIcon: Icon(Icons.chat_rounded),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 1, color: AppTheme.borderGrey),
          Container(
            color: AppTheme.white,
            child: SafeArea(
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                items: navItems,
                elevation: 0,
                backgroundColor: Colors.transparent,
                type: BottomNavigationBarType.fixed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
