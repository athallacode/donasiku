import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/policy_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_donation_screen.dart';
import 'screens/history_screen.dart';
import 'modules/pencarian_area/providers/discovery_provider.dart';
import 'utils/app_error_handler.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    AppErrorHandler.logError('Main.initialize', e);
  }
  runApp(const DonasikuApp());
}

class DonasikuApp extends StatelessWidget {
  const DonasikuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DiscoveryProvider(),
      child: MaterialApp(
        title: 'Donasiku',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/splash',
        builder: (context, widget) {
          ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
            AppErrorHandler.logError('System.RenderError', errorDetails.exception, errorDetails.stack);
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 64, color: AppTheme.errorRed),
                      const SizedBox(height: 16),
                      Text('Terjadi Kesalahan Tampilan', style: AppTheme.headingSmall),
                      const SizedBox(height: 8),
                      Text(
                        'Aplikasi mengalami kendala saat memuat antarmuka. Kami telah mencatat kejadian ini.',
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pushReplacementNamed('/splash'),
                        child: const Text('Muat Ulang Aplikasi'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          };
          return widget!;
        },
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/policy': (context) => const PolicyScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/add-donation': (context) => const AddDonationScreen(),
          '/history': (context) => const HistoryScreen(),
        },
      ),
    );
  }
}
