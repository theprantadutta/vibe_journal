import 'package:flutter/material.dart';
import 'package:vibe_journal/core/widgets/legal_document_view.dart';

class TermsAndConditionsContent extends StatelessWidget {
  final bool showAcceptanceControls;
  final bool isCheckboxChecked;
  final ValueChanged<bool?>? onCheckboxChanged;
  final VoidCallback? onAcceptButtonPressed;
  final bool isAcceptButtonEnabled;

  const TermsAndConditionsContent({
    super.key,
    this.showAcceptanceControls = false,
    this.isCheckboxChecked = false,
    this.onCheckboxChanged,
    this.onAcceptButtonPressed,
    this.isAcceptButtonEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return LegalDocumentView(
      title: 'Terms & Conditions',
      showAcceptanceControls: showAcceptanceControls,
      isCheckboxChecked: isCheckboxChecked,
      onCheckboxChanged: onCheckboxChanged,
      onAcceptButtonPressed: onAcceptButtonPressed,
      isAcceptButtonEnabled: isAcceptButtonEnabled,
      content: '''
Last Updated: June 8, 2025

By using the VibeJournal application ("Service"), you agree to be bound by these Terms & Conditions.

1.  Use of Service
    a. You agree to use the Service for personal, non-commercial purposes only. You are responsible for all activities that occur under your account.
    b. You must not use the Service to record or store any content that is illegal, defamatory, or infringes on the rights of others.

2.  User Content
    a. You retain full ownership of the audio recordings and content you create ("User Content").
    b. By using our AI analysis features, you grant us a license to process your User Content through third-party services for the purpose of providing transcription and sentiment analysis back to you.

3.  Premium Services
    a. VibeJournal offers optional premium subscription plans. All payments will be processed through the Google Play Store and are subject to their terms of service.
    b. Subscriptions will automatically renew unless canceled by you through your Google Play account settings.

4.  Disclaimer of Warranties
    a. The Service is provided "as is." We do not warrant that the service will be uninterrupted or error-free. The mood and sentiment analysis features are provided for informational and journaling purposes only and are not a substitute for professional medical or psychological advice.

5.  Limitation of Liability
    a. In no event shall VibeJournal or its developers be liable for any indirect, incidental, or consequential damages arising out of the use of the Service.

6.  Termination
    a. We may terminate or suspend your account at any time, without prior notice, for conduct that violates these Terms or is otherwise harmful to other users or the Service.

7.  Governing Law
    a. These terms shall be governed by the laws of the jurisdiction in which the app developer is based, without regard to its conflict of law provisions.
''',
    );
  }
}
