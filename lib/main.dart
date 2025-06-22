import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding/language_selection_screen.dart';
import 'screens/onboarding/household_setup_screen.dart';
import 'screens/onboarding/tutorial_screen.dart';
import 'services/preferences_service.dart';

void main() {
  runApp(const RoutineFlowApp());
}

class RoutineFlowApp extends StatefulWidget {
  const RoutineFlowApp({super.key});

  @override
  State<RoutineFlowApp> createState() => _RoutineFlowAppState();
}

class _RoutineFlowAppState extends State<RoutineFlowApp> {
  Locale _locale = const Locale('en');
  bool _isLoading = true;
  bool _onboardingCompleted = false;
  List<String>? _savedMembers;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    try {
      // Load saved language
      final savedLanguage = await PreferencesService.getLanguage();
      if (savedLanguage != null) {
        _locale = Locale(savedLanguage);
      }

      // Load onboarding status
      final onboardingCompleted = await PreferencesService.isOnboardingCompleted();
      _onboardingCompleted = onboardingCompleted;

      // Load household members
      _savedMembers = await PreferencesService.getHouseholdMembers();

    } catch (e) {
      // Handle error gracefully
      print('Error loading preferences: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
    PreferencesService.saveLanguage(locale.languageCode);
  }

  void _completeOnboarding() {
    setState(() {
      _onboardingCompleted = true;
    });
    // Reload household members after onboarding
    _loadHouseholdMembers();
  }

  Future<void> _loadHouseholdMembers() async {
    _savedMembers = await PreferencesService.getHouseholdMembers();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Routine Flow',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: _isLoading
          ? const _LoadingScreen()
          : _onboardingCompleted
              ? HomeScreen(
                  onLocaleChange: _setLocale,
                  initialMembers: _savedMembers,
                )
              : _OnboardingFlow(
                  onCompleted: _completeOnboarding,
                  onLocaleChange: _setLocale,
                ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.schedule,
                size: 80,
                color: Colors.blue,
              ),
              SizedBox(height: 24),
              Text(
                'Routine Flow',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 16),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingFlow extends StatefulWidget {
  final VoidCallback onCompleted;
  final Function(Locale) onLocaleChange;

  const _OnboardingFlow({
    required this.onCompleted,
    required this.onLocaleChange,
  });

  @override
  State<_OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<_OnboardingFlow> {
  int _currentStep = 0;

  void _nextStep() {
    setState(() {
      _currentStep++;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return LanguageSelectionScreen(
          onLanguageSelected: (locale) {
            widget.onLocaleChange(locale);
            _nextStep();
          },
        );
      case 1:
        return HouseholdSetupScreen(
          onCompleted: _nextStep,
        );
      case 2:
        return TutorialScreen(
          onCompleted: widget.onCompleted,
        );
      default:
        return LanguageSelectionScreen(
          onLanguageSelected: (locale) {
            widget.onLocaleChange(locale);
            _nextStep();
          },
        );
    }
  }
}
