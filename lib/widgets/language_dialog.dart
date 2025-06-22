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
      title: Text(l10n.language),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(l10n.english),
            leading: const Icon(Icons.language),
            onTap: () {
              onLocaleChange(const Locale('en'));
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text(l10n.hebrew),
            leading: const Icon(Icons.language),
            onTap: () {
              onLocaleChange(const Locale('he'));
              Navigator.pop(context);
            },
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
} 