import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../services/preferences_service.dart';

class HouseholdSetupScreen extends StatefulWidget {
  final VoidCallback onCompleted;

  const HouseholdSetupScreen({
    super.key,
    required this.onCompleted,
  });

  @override
  State<HouseholdSetupScreen> createState() => _HouseholdSetupScreenState();
}

class _HouseholdSetupScreenState extends State<HouseholdSetupScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final List<String> _children = [];
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _addChild() {
    if (_nameController.text.trim().isNotEmpty) {
      setState(() {
        _children.add(_nameController.text.trim());
        _nameController.clear();
      });
    }
  }

  void _removeChild(int index) {
    setState(() {
      _children.removeAt(index);
    });
  }

  Future<void> _continue() async {
    if (_children.isNotEmpty) {
      await PreferencesService.saveHouseholdMembers(_children);
    } else {
      // Default children if none added
      await PreferencesService.saveHouseholdMembers(['Alex', 'Sam']);
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode ? [
              Colors.grey.shade900,
              Colors.black,
              Colors.grey.shade800,
            ] : [
              Colors.orange.shade50,
              Colors.white,
              Colors.pink.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey.shade700 : Colors.orange.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.home,
                                size: 30,
                                color: isDarkMode ? Colors.white : Colors.orange.shade600,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.manageHousehold,
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    l10n.addYourFamilyMembers,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Add child section
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.addNewMember,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _nameController,
                                        focusNode: _nameFocus,
                                        decoration: InputDecoration(
                                          hintText: l10n.enterMemberName,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          prefixIcon: const Icon(Icons.person_add),
                                        ),
                                        onSubmitted: (_) => _addChild(),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton(
                                      onPressed: _addChild,
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.all(16),
                                      ),
                                      child: const Icon(Icons.add),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Children list
                        if (_children.isNotEmpty) ...[
                          Text(
                            '${l10n.familyMembers} (${_children.length})',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        Expanded(
                          child: _children.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.family_restroom,
                                        size: 80,
                                        color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        l10n.noFamilyMembersAddedYet,
                                        style: TextStyle(
                                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        l10n.addFamilyMembersAboveOrSkip,
                                        style: TextStyle(
                                          color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _children.length,
                                  itemBuilder: (context, index) {
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.primaries[index % Colors.primaries.length].shade100,
                                          child: Text(
                                            _children[index][0].toUpperCase(),
                                            style: TextStyle(
                                              color: Colors.primaries[index % Colors.primaries.length].shade600,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        title: Text(_children[index]),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                          onPressed: () => _removeChild(index),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Continue button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _continue,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _children.isEmpty ? l10n.skipAndUseDefaults : l10n.continueButton,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
} 