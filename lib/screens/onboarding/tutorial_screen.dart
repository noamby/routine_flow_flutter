import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../services/preferences_service.dart';

class TutorialScreen extends StatefulWidget {
  final VoidCallback onCompleted;

  const TutorialScreen({
    super.key,
    required this.onCompleted,
  });

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 5;

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
    }
  }

  Future<void> _completeTutorial() async {
    await PreferencesService.setOnboardingCompleted(true);
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
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
                    TextButton(
                      onPressed: _completeTutorial,
                      child: Text(
                        l10n.skip,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    Row(
                      children: List.generate(_totalPages, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == _currentPage
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade300,
                          ),
                        );
                      }),
                    ),
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
                    _buildTutorialPage(
                      icon: Icons.home,
                      iconColor: Colors.blue,
                      title: l10n.welcomeToRoutineFlow,
                      description: l10n.welcomeDescription,
                      image: '🏠',
                    ),
                    _buildTutorialPage(
                      icon: Icons.schedule,
                      iconColor: Colors.orange,
                      title: l10n.morningEveningRoutines,
                      description: l10n.morningEveningDescription,
                      image: '⏰',
                    ),
                    _buildTutorialPage(
                      icon: Icons.family_restroom,
                      iconColor: Colors.green,
                      title: l10n.familyMembersTitle,
                      description: l10n.familyMembersDescription,
                      image: '👨‍👩‍👧‍👦',
                    ),
                    _buildTutorialPage(
                      icon: Icons.check_circle,
                      iconColor: Colors.purple,
                      title: l10n.trackProgress,
                      description: l10n.trackProgressDescription,
                      image: '✅',
                    ),
                    _buildTutorialPage(
                      icon: Icons.child_care,
                      iconColor: Colors.pink,
                      title: l10n.childMode,
                      description: l10n.childModeDescription,
                      image: '🧒',
                    ),
                  ],
                ),
              ),
              
              // Navigation buttons
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage > 0)
                      ElevatedButton(
                        onPressed: _previousPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.grey.shade700,
                        ),
                        child: Text(l10n.previous),
                      )
                    else
                      const SizedBox(width: 80),
                    
                    ElevatedButton(
                      onPressed: _currentPage == _totalPages - 1 ? _completeTutorial : _nextPage,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: Text(
                        _currentPage == _totalPages - 1 ? l10n.getStarted : l10n.next,
                        style: const TextStyle(fontSize: 16),
                      ),
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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large emoji/image
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                image,
                style: const TextStyle(fontSize: 60),
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
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
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 