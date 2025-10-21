import 'package:animationandcharts/firebase_options.dart';
import 'package:animationandcharts/routes/router.dart';
import 'package:animationandcharts/screens/account_screen.dart';
import 'package:animationandcharts/screens/add_edit_account_screen.dart';
import 'package:animationandcharts/screens/add_transaction_screen.dart';
import 'package:animationandcharts/screens/categories_screen.dart';
import 'package:animationandcharts/screens/dashboard_screen.dart';
import 'package:animationandcharts/screens/auth/email_verification_screen.dart';
import 'package:animationandcharts/screens/auth/forgot_password_screen.dart';
import 'package:animationandcharts/screens/home_screen.dart';
import 'package:animationandcharts/screens/auth/login_screen.dart';
import 'package:animationandcharts/screens/profile_screen.dart';
import 'package:animationandcharts/screens/settings_screen.dart';
import 'package:animationandcharts/screens/setup_wizard/success_screen.dart';
import 'package:animationandcharts/screens/auth/signup_screen.dart';
import 'package:animationandcharts/screens/auth/splash_screen.dart';
import 'package:animationandcharts/screens/transactions_list_screen.dart';
import 'package:animationandcharts/screens/welcome_screen.dart';
// import 'package:animationandcharts/services/notification_service.dart';
import 'package:animationandcharts/theme/app_theme.dart';
import 'package:animationandcharts/theme/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;

/// 🌐 Global navigator key — allows navigation from anywhere (e.g., notifications)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _startupSetting() async {
  //firebase setup
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );
  FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true, // enables offline cache
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);


  //supabase setup
  // await Supabase.initialize(
  //   url: 'https://jidcizfhqkwihjalmdet.supabase.co',
  //   anonKey:
  //       'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImppZGNpemZocWt3aWhqYWxtZGV0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg5NDMwNjUsImV4cCI6MjA3NDUxOTA2NX0.m9Da1ZxneI1543Xw6Fmyel6x_K3_x8oeT-raWJ9O1FE',
  // );


  //notifiaction setup
  // tz.initializeTimeZones(); // ✅ Required for scheduling
  // tz.setLocalLocation(tz.getLocation('Asia/Karachi')); // set your local timezone

  // await NotificationService.init(); // Initialize
  // await NotificationService.requestPermissions(); // Request permission
}


//only once

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.remove();
  await _startupSetting();
  runApp(ProviderScope(child: const Expensio()));
}


class Expensio extends ConsumerStatefulWidget {
  const Expensio({super.key});

  @override
  ConsumerState<Expensio> createState() => _ExpensioState();
}

class _ExpensioState extends ConsumerState<Expensio> {
  RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();
  var userId = "";
  var userEmail = "";

  @override
  void initState() {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      userId = user.uid;  
      userEmail=user.email!;   
    } 
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Expensio',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      navigatorObservers: [routeObserver],
      navigatorKey: navigatorKey,
      initialRoute: '/',

      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.home: (context) => HomeScreen(userId: userId,),
        AppRoutes.setupSuccess: (context) => const SetupSuccessScreen(),
        AppRoutes.accounts: (context) => AccountsScreen(userId: userId,),
        AppRoutes.categories: (context) => CategoriesScreen(userId: userId),
        AppRoutes.profile: (context) => const ProfileScreen(),
        AppRoutes.addAccount: (context) => AddEditAccountScreen(userId: userId,),
        AppRoutes.addTransaction: (context) => AddEditTransactionScreen(userId: userId,),
        AppRoutes.settings: (context) => SettingsScreen(userId: userId,),
        AppRoutes.transactions: (context) => TransactionsListScreen(userId: userId,),
        AppRoutes.dashboard: (context) => DashboardScreen(userId: userId,),
        AppRoutes.welcome: (context) => const WelcomeScreen(),

        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.signup: (context) => const SignUpScreen(),
        AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
        AppRoutes.emailVerification: (context) =>
            EmailVerificationScreen(email: userEmail,),
      },
    );
  }
}
