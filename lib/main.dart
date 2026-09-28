import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'services/language_service.dart';
import 'services/notification_service.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/customer/customer_main_layout.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Load user's saved language preference before the first frame
  await LanguageService().loadSavedLanguage();

  // Initialize Push Notifications
  await NotificationService().initialize();

  runApp(const HarvestHubApp());
}

class HarvestHubApp extends StatefulWidget {
  const HarvestHubApp({super.key});

  @override
  State<HarvestHubApp> createState() => _HarvestHubAppState();
}

class _HarvestHubAppState extends State<HarvestHubApp> {
  final LanguageService _languageService = LanguageService();

  @override
  void initState() {
    super.initState();
    // Rebuild the whole app whenever the locale changes
    _languageService.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _languageService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HarvestHub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // ── Localization setup ──────────────────────────────────────────────
      locale: _languageService.currentLocale,
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ur', 'PK'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Resolve locale: prefer saved preference, fall back to device locale
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        // Always honour the user's explicit choice from LanguageService
        return _languageService.currentLocale;
      },
      builder: (context, child) {
        // Keep standard UI layout direction (left-to-right) so headers, navigation,
        // tabs, icons, and components maintain consistent, beautiful mobile layout
        return Directionality(
          textDirection: TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },

      // ── Routes ──────────────────────────────────────────────────────────
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/roles': (_) => const RoleSelectionScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/verify-email': (_) => EmailVerificationScreen(
              email: '',
              onVerified: () {},
            ),
        '/home': (_) => const CustomerMainLayout(),
      },
    );
  }
}
