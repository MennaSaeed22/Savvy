// packages
import 'package:flutter/material.dart';
import 'package:savvy/screens/globals.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// screens
import 'screens/Athentication/login_screen.dart';
import 'screens/Athentication/signup_screen.dart';
import 'screens/Onboarding/launch_screen.dart';
import 'screens/Onboarding/onboarding_screen.dart';
import 'screens/Categories/expenses/add_expense_screen.dart';
import 'screens/Categories/expenses/categories_screen.dart';
import 'screens/Home/home_screen.dart';
import 'screens/Home/income_screen.dart';
import 'screens/Analytics/presentation/analyticsScreen.dart';
import 'screens/Profile/DeleteAccount_screen.dart';
import 'screens/Profile/NotificationSettings_screen.dart';
import 'screens/Profile/PasswordSettings_screen.dart';
import 'screens/Profile/profile_screen.dart';
import 'screens/Profile/edit_profile_screen.dart';
import 'screens/Profile/help_screen.dart';
import 'screens/Profile/settings_screen.dart';
import 'screens/Profile/email_screen.dart';
import 'screens/Notifications/notificaitons_screen.dart';
import 'screens/Transactions/edit_transaction_screen.dart';
import 'screens/Transactions/history_screen.dart';
import 'screens/Transactions/transactions_screen.dart';

// services
import 'services/notification_service.dart';
import 'providers/app_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  tz.initializeTimeZones();
  await NotificationService.init();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: primaryColor,
          selectionColor: primaryColor.withOpacity(0.3),
          selectionHandleColor: primaryColor,
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => OnboardingScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/Launch': (context) => LaunchScreen(),
        '/home': (context) => HomeScreen(),
        '/categories': (context) => CategoriesScreen(),
        '/analytics': (context) => const AnalyticsScreen(),
        '/profile': (context) => ProfileScreen(),
        '/edit-profile': (context) => EditProfileScreen(),
        '/help': (context) => HelpScreen(),
        '/settings': (context) => SettingsScreen(),
        '/notifications': (context) => NotificationsScreen(),
        '/NotificationSettings': (context) => NotificationSettingsScreen(),
        '/PasswordSettings': (context) => PasswordSettingsScreen(),
        '/DeleteAccount': (context) => DeleteAccountScreen(),
        '/Email': (context) => EmailScreen(),
        '/history': (context) => HistoryScreen(),
        '/transactions': (context) => TransactionsScreen(),
        '/income': (context) => IncomeScreen(),
        '/expenses': (context) => AddExpenseScreen(),
        '/transaction-details': (context) => TransactionDetailsScreen(transaction: {},),
      },
    );
  }
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (!mounted) return;
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await ref.read(userProvider.notifier).refresh();
        await ref.read(transactionProvider.notifier).refresh();
        await ref.read(financialSummaryProvider.notifier).refresh();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } catch (e) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/onboarding');
        }
      }
    } else {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              'Savvy',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
