import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../providers/terms_provider.dart';

class TermsScreen extends ConsumerWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: C.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: C.approvedBg,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset('assets/images/croc.png'),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Terms of Service',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: C.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Please review and accept to continue.',
                style: TextStyle(fontSize: 14, color: C.textSecondary),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: C.grey50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: C.border),
                  ),
                  child: const SingleChildScrollView(
                    child: Text(
                      _termsText,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.7,
                        color: C.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () =>
                    ref.read(termsAcceptedProvider.notifier).accept(),
                child: const Text('I Agree'),
              ),
              const SizedBox(height: 10),
              const Text(
                'By tapping "I Agree", you acknowledge that you have read\nand agree to our Terms of Service and Privacy Policy.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: C.textTertiary, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _termsText = '''
PARADISE AGAIN — TERMS OF SERVICE

Last updated: March 2026

1. ACCEPTANCE OF TERMS
By downloading, installing, or using the CROC mobile application ("App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree, do not use the App.

2. DESCRIPTION OF SERVICE
CROC is a deal management platform for MCA (Merchant Cash Advance) brokers. The App provides tools to view submitted deals, track lender deliveries, and monitor lender responses.

3. ELIGIBILITY
You must be at least 18 years old and authorized to conduct business as an MCA broker or representative to use this App.

4. ACCOUNT SECURITY
You are responsible for maintaining the confidentiality of your login credentials. You agree to notify us immediately of any unauthorized use of your account.

5. ACCEPTABLE USE
You agree not to:
  a. Use the App for any unlawful purpose
  b. Share confidential deal or borrower information with unauthorized parties
  c. Attempt to access data belonging to other users
  d. Reverse-engineer, decompile, or modify the App

6. DATA & PRIVACY
  a. We collect and store information necessary to provide the service, including your email, deal submissions, and lender communications.
  b. Borrower data is handled in accordance with applicable privacy laws.
  c. We do not sell your personal data to third parties.

7. CONFIDENTIALITY
All deal information, borrower details, lender responses, and offer terms accessed through the App are confidential. You agree not to disclose this information except as required for legitimate business purposes.

8. DISCLAIMER OF WARRANTIES
The App is provided "as is" without warranties of any kind. We do not guarantee uninterrupted or error-free service.

9. LIMITATION OF LIABILITY
To the maximum extent permitted by law, CROC shall not be liable for any indirect, incidental, or consequential damages arising from your use of the App.

10. MODIFICATIONS
We reserve the right to modify these Terms at any time. Continued use of the App after changes constitutes acceptance of the updated Terms.

11. TERMINATION
We may suspend or terminate your access at any time for violation of these Terms or for any other reason at our discretion.

12. CONTACT
For questions about these Terms, contact maheedhar@croccrm.com.
''';
