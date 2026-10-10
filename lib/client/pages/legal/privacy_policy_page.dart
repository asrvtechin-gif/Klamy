import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'privacy_policy'.tr,
          style: const TextStyle(
            color: Color(0xFF0F2942),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F2942), size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F7F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFB3EBE5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_rounded, color: Color(0xFF007A78), size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Privacy is Our Priority',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F2942),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Last updated: October 2026',
                          style: TextStyle(fontSize: 12, color: Color(0xFF007A78)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '1. Introduction',
              content:
                  'Welcome to Klamy ("we", "our", or "us"). Klamy is dedicated to helping you organize, manage, and understand your health insurance claims and medical documents. We are committed to safeguarding the privacy and security of your personal health data and confidential records.',
            ),

            _buildSection(
              title: '2. Information We Collect',
              content:
                  'To provide our claims assistance and document vault services, we collect:\n\n'
                  '• Personal Information: Your name, email address, phone number, and account credentials.\n'
                  '• Claim & Policy Data: Policy numbers, insurance providers, claimed amounts, hospital names, admission/discharge dates, and diagnosis details.\n'
                  '• Uploaded Documents: Invoices, discharge summaries, prescriptions, lab reports, and insurer correspondence that you choose to store in your Documents Vault.',
            ),

            _buildSection(
              title: '3. Local AI Processing & On-Premise Privacy',
              content:
                  'Klamy utilizes locally deployed AI models (Qwen-VL) to analyze claims and suggest missing documentation.\n\n'
                  '• No Public AI Sharing: Your claim summaries and sensitive health records are processed through secure local instances and are never used to train public third-party commercial AI models.\n'
                  '• Role as Untrusted Evidence: Medical documents are read strictly as reference evidence for your personal review and are never stored as AI training prompts.',
            ),

            _buildSection(
              title: '4. How We Use and Protect Your Data',
              content:
                  'We use your data solely to:\n'
                  '• Provide automated claim tracking and document organization.\n'
                  '• Help identify missing documentation before insurer submission.\n'
                  '• Securely authenticate your account via Firebase Authentication.\n\n'
                  'We implement industry-standard encryption in transit (HTTPS/TLS) and restricted Firebase access rules ensuring that only you have access to your personal documents.',
            ),

            _buildSection(
              title: '5. Document Storage & Cloudinary',
              content:
                  'Your document images and PDFs are securely stored in verified cloud storage (Cloudinary) with strict access tokens. Document links are scoped directly to your unique authenticated user account.',
            ),

            _buildSection(
              title: '6. Your Rights & Data Control',
              content:
                  'You retain complete ownership of your data:\n'
                  '• Access & Edit: You can view and edit your profile details at any time.\n'
                  '• Delete Data: You can delete any claim or uploaded document from your Documents Vault whenever you wish.\n'
                  '• Account Removal: You may request complete account and data deletion by contacting our support team.',
            ),

            _buildSection(
              title: '7. Medical & Insurance Disclaimer',
              content:
                  'Klamy is an organizational assistance tool, not an insurance company, third-party administrator (TPA), or healthcare provider. Any claim summaries and document recommendations generated by the app are informative suggestions and do not constitute legal advice or guarantee insurance approval.',
            ),

            _buildSection(
              title: '8. Contact Us',
              content:
                  'If you have any questions, concerns, or requests regarding this Privacy Policy or your data, please contact us at:\n\n'
                  'Email: asrvtech.in@gmail.in\n'
                  'Website: https://klamy-8789e.web.app',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2942),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
