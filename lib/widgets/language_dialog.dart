import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LanguageDialog extends StatelessWidget {
  final Function(Locale) onLocaleChange;

  const LanguageDialog({
    super.key,
    required this.onLocaleChange,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.language, color: Colors.blue),
          const SizedBox(width: 8),
          Text(l10n.language),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageOption(
            context: context,
            flag: '🇺🇸',
            title: l10n.english,
            subtitle: 'English',
            locale: const Locale('en'),
          ),
          const SizedBox(height: 8),
          _buildLanguageOption(
            context: context,
            flag: '🇮🇱',
            title: l10n.hebrew,
            subtitle: 'עברית',
            locale: const Locale('he'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String flag,
    required String title,
    required String subtitle,
    required Locale locale,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Text(
          flag,
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          onLocaleChange(locale);
          Navigator.pop(context);
          
          // Show feedback to user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                locale.languageCode == 'en' 
                  ? 'Language changed successfully'
                  : 'השפה שונתה בהצלחה',
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }
} 