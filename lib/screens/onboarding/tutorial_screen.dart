import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../services/preferences_service.dart';

class TutorialScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  final bool canGoBack;
  final VoidCallback? onBack;
  final bool isFromMenu; // When opened from menu, don't save onboarding status

  const TutorialScreen({
    super.key,
    required this.onCompleted,
    this.canGoBack = false,
    this.onBack,
    this.isFromMenu = false,
  });

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 7;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeTutorial();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (widget.canGoBack && widget.onBack != null) {
      // Go back to previous onboarding step (household setup)
      widget.onBack!();
    }
  }

  Future<void> _completeTutorial() async {
    // Only mark onboarding as completed if this is the actual onboarding flow
    if (!widget.isFromMenu) {
      await PreferencesService.setOnboardingCompleted(true);
    }
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode ? [
              Colors.grey.shade900,
              Colors.black,
              Colors.grey.shade800,
            ] : [
              Colors.purple.shade50,
              Colors.blue.shade50,
              Colors.green.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with progress
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back/Skip button
                    if (_currentPage > 0 || widget.canGoBack)
                      TextButton(
                        onPressed: _previousPage,
                        child: Text(
                          l10n.previous,
                          style: TextStyle(color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600),
                        ),
                      )
                    else
                      TextButton(
                        onPressed: _completeTutorial,
                        child: Text(
                          l10n.skip,
                          style: TextStyle(color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600),
                        ),
                      ),
                    // Progress dots
                    Row(
                      children: List.generate(_totalPages, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == _currentPage
                                ? Theme.of(context).primaryColor
                                : (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                          ),
                        );
                      }),
                    ),
                    // Next/Done button
                    TextButton(
                      onPressed: _currentPage == _totalPages - 1 ? _completeTutorial : _nextPage,
                      child: Text(
                        _currentPage == _totalPages - 1 ? l10n.done : l10n.next,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tutorial pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    // Page 1: Welcome
                    _buildTutorialPage(
                      icon: Icons.home,
                      iconColor: Colors.blue,
                      title: l10n.welcomeToRoutineFlow,
                      description: l10n.welcomeDescription,
                      image: '🏠',
                    ),
                    // Page 2: Morning & Evening Routines
                    _buildTutorialPage(
                      icon: Icons.schedule,
                      iconColor: Colors.orange,
                      title: l10n.morningEveningRoutines,
                      description: l10n.morningEveningDescription,
                      image: '🌅🌙',
                    ),
                    // Page 3: Family Members & Avatars
                    _buildTutorialPage(
                      icon: Icons.face,
                      iconColor: Colors.green,
                      title: l10n.tutorialAvatarsTitle,
                      description: l10n.tutorialAvatarsDescription,
                      image: '👤📸',
                    ),
                    // Page 4: Track Progress
                    _buildTutorialPage(
                      icon: Icons.check_circle,
                      iconColor: Colors.purple,
                      title: l10n.trackProgress,
                      description: l10n.trackProgressDescription,
                      image: '✅',
                    ),
                    // Page 5: Custom Routines
                    _buildTutorialPage(
                      icon: Icons.add_circle,
                      iconColor: Colors.teal,
                      title: l10n.tutorialCustomRoutinesTitle,
                      description: l10n.tutorialCustomRoutinesDescription,
                      image: '➕✨',
                    ),
                    // Page 6: View Modes & Dark Mode
                    _buildTutorialPage(
                      icon: Icons.view_module,
                      iconColor: Colors.indigo,
                      title: l10n.tutorialViewModesTitle,
                      description: l10n.tutorialViewModesDescription,
                      image: '📱💻',
                    ),
                    // Page 7: Child Mode
                    _buildTutorialPage(
                      icon: Icons.child_care,
                      iconColor: Colors.pink,
                      title: l10n.childMode,
                      description: l10n.childModeDescription,
                      image: '🧒🔒',
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialPage({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String image,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large emoji/image
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: isDarkMode ? iconColor.withOpacity(0.2) : iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Text(
                image,
                style: const TextStyle(fontSize: 50),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Icon badge
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isDarkMode ? iconColor.withOpacity(0.2) : iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 30,
              color: iconColor,
            ),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
