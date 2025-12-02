import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../services/preferences_service.dart';
import '../../widgets/dialogs/add_member_dialog.dart';

class HouseholdSetupScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  final bool canGoBack;
  final VoidCallback? onBack;

  const HouseholdSetupScreen({
    super.key,
    required this.onCompleted,
    this.canGoBack = false,
    this.onBack,
  });

  @override
  State<HouseholdSetupScreen> createState() => _HouseholdSetupScreenState();
}

class _HouseholdSetupScreenState extends State<HouseholdSetupScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Store full member data including avatar and color
  final List<MemberData> _members = [];

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

    // Load any previously saved members
    _loadSavedMembers();
  }

  Future<void> _loadSavedMembers() async {
    final savedNames = await PreferencesService.getHouseholdMembers();
    if (savedNames != null && savedNames.isNotEmpty) {
      for (int i = 0; i < savedNames.length; i++) {
        final memberId = 'member_$i';
        final icon = await PreferencesService.getMemberIcon(memberId);
        final imageBytes = await PreferencesService.getMemberImageBytes(memberId);
        final color = await PreferencesService.getMemberColor(memberId);

        setState(() {
          _members.add(MemberData(
            name: savedNames[i],
            icon: icon ?? Icons.person,
            imageBytes: imageBytes,
            color: color ?? Colors.blue,
          ));
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _addMember() {
    showDialog(
      context: context,
      builder: (context) => AddMemberDialog(
        onAdd: (memberData) {
          setState(() {
            _members.add(memberData);
          });
          // Save immediately when adding
          _saveMembers();
        },
      ),
    );
  }

  void _removeMember(int index) {
    setState(() {
      _members.removeAt(index);
    });
    // Save immediately when removing
    _saveMembers();
  }

  Future<void> _saveMembers() async {
    if (_members.isNotEmpty) {
      // Save member names
      await PreferencesService.saveHouseholdMembers(
        _members.map((m) => m.name).toList(),
      );

      // Save member icons and images
      for (int i = 0; i < _members.length; i++) {
        final member = _members[i];
        final memberId = 'member_$i';

        // Save icon
        await PreferencesService.saveMemberIcon(memberId, member.icon);

        // Save image if exists
        if (member.imageBytes != null) {
          await PreferencesService.saveMemberImageBytes(memberId, member.imageBytes!);
        }

        // Save color
        await PreferencesService.saveMemberColor(memberId, member.color);
      }
    }
  }

  Future<void> _continue() async {
    await _saveMembers();

    if (_members.isEmpty) {
      // Default children if none added
      await PreferencesService.saveHouseholdMembers(['Alex', 'Sam']);
    }
    widget.onCompleted();
  }

  Widget _buildMemberAvatar(MemberData member) {
    if (member.imageBytes != null) {
      return CircleAvatar(
        backgroundColor: member.color.withOpacity(0.2),
        backgroundImage: MemoryImage(member.imageBytes!),
      );
    }
    return CircleAvatar(
      backgroundColor: member.color.withOpacity(0.2),
      child: Icon(
        member.icon,
        color: member.color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hasMembers = _members.isNotEmpty;

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
              // Header with progress dots (matching tutorial style)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    if (widget.canGoBack)
                      TextButton(
                        onPressed: widget.onBack,
                        child: Text(
                          l10n.previous,
                          style: TextStyle(color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600),
                        ),
                      )
                    else
                      const SizedBox(width: 80),
                    // Progress dots (step 2 of 3)
                    Row(
                      children: List.generate(3, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == 1
                                ? Theme.of(context).primaryColor
                                : (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                          ),
                        );
                      }),
                    ),
                    // Next button - only enabled when members added
                    TextButton(
                      onPressed: hasMembers ? _continue : null,
                      child: Text(
                        l10n.next,
                        style: TextStyle(
                          color: hasMembers
                              ? Theme.of(context).primaryColor
                              : (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            children: [
                              // Header icon (matching tutorial style)
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.green.withOpacity(0.2) : Colors.green.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text(
                                    '👨‍👩‍👧‍👦',
                                    style: TextStyle(fontSize: 60),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Title
                              Text(
                                l10n.manageHousehold,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.grey.shade800,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 8),

                              Text(
                                l10n.addYourFamilyMembers,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 24),

                              // Add member button
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  onTap: _addMember,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.person_add,
                                            color: Colors.blue,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            l10n.addNewMember,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.add_circle,
                                          color: Colors.blue,
                                          size: 24,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Members list
                              Expanded(
                                child: _members.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.family_restroom,
                                              size: 60,
                                              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              l10n.noFamilyMembersAddedYet,
                                              style: TextStyle(
                                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Add at least one family member to continue',
                                              style: TextStyle(
                                                color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                                                fontSize: 12,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: _members.length,
                                        itemBuilder: (context, index) {
                                          final member = _members[index];
                                          return Card(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: ListTile(
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 4,
                                              ),
                                              leading: _buildMemberAvatar(member),
                                              title: Text(
                                                member.name,
                                                style: const TextStyle(fontWeight: FontWeight.w600),
                                              ),
                                              subtitle: Row(
                                                children: [
                                                  Container(
                                                    width: 10,
                                                    height: 10,
                                                    decoration: BoxDecoration(
                                                      color: member.color,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Ready!',
                                                    style: TextStyle(
                                                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              trailing: IconButton(
                                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                                onPressed: () => _removeMember(index),
                                              ),
                                            ),
                                          );
                                        },
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
            ],
          ),
        ),
      ),
    );
  }
}
