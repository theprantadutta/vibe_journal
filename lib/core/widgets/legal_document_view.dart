import 'package:flutter/material.dart';
import 'package:vibe_journal/config/theme/app_colors.dart';

class LegalDocumentView extends StatelessWidget {
  final String title;
  final String content;
  final bool showAcceptanceControls;
  final bool isCheckboxChecked;
  final ValueChanged<bool?>? onCheckboxChanged;
  final VoidCallback? onAcceptButtonPressed;
  final bool isAcceptButtonEnabled;

  const LegalDocumentView({
    super.key,
    required this.title,
    required this.content,
    this.showAcceptanceControls = false,
    this.isCheckboxChecked = false,
    this.onCheckboxChanged,
    this.onAcceptButtonPressed,
    this.isAcceptButtonEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            title,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        if (showAcceptanceControls) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                Checkbox(
                  value: isCheckboxChecked,
                  onChanged: onCheckboxChanged,
                  activeColor: AppColors.primary,
                ),
                Expanded(
                  child: Text(
                    "I have read and agree to the $title.",
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: ElevatedButton(
              onPressed: isAcceptButtonEnabled ? onAcceptButtonPressed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.surface,
              ),
              child: const Text('Accept and Continue'),
            ),
          ),
        ],
      ],
    );
  }
}
