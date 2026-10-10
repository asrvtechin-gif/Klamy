import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'terms_conditions'.tr,
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
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.gavel_rounded, color: Color(0xFF0F2942), size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Terms of Service',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F2942),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Effective Date: October 2026',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '1. Agreement to Terms',
              content:
                  'By creating an account, accessing, or using the Klamy mobile application and related services ("Service"), you agree to be bound by these Terms and Conditions. If you do not agree, please do not use the application.',
            ),

            _buildSection(
              title: '2. Description of the Service',
              content:
                  'Klamy provides an intelligent mobile platform designed to help users:\n'
                  '• Track and organize health insurance claims and policies.\n'
                  '• Store and categorize medical invoices, discharge papers, and prescriptions.\n'
                  '• Receive AI-assisted document checklists and summaries to identify potentially missing paperwork before claim submission.',
            ),

            _buildSection(
              title: '3. Important Disclaimers',
              content:
                  '• Not an Insurance Provider: Klamy is NOT an insurer, insurance broker, agent, or Third Party Administrator (TPA). Klamy does not approve, adjudicate, or pay insurance claims.\n\n'
                  '• Not Medical or Legal Advice: The information and summaries provided by the Klamy AI assistant are for organizational guidance only. They do not substitute professional medical diagnosis, clinical advice, or legal counsel regarding insurance policies.\n\n'
                  '• No Guarantee of Approval: Suggested documents and claim reviews do not ensure that your insurance company will approve your reimbursement or cashless claim.',
            ),

            _buildSection(
              title: '4. User Responsibilities & Conduct',
              content:
                  'By using Klamy, you agree that:\n'
                  '• You are at least 18 years of age or using the app with parental/guardian authorization.\n'
                  '• All documents and invoices you upload are genuine and belong to you or a dependent under your care.\n'
                  '• You will maintain the security and confidentiality of your login credentials.\n'
                  '• You will not upload fraudulent invoices, altered bills, malicious files, or materials that violate any applicable laws.',
            ),

            _buildSection(
              title: '5. Intellectual Property Rights',
              content:
                  'All rights, title, and interest in Klamy (including app design, branding, features, algorithms, and interface) remain the exclusive property of Klamy and its licensors. You retain all ownership rights to the personal documents and files you upload.',
            ),

            _buildSection(
              title: '6. Limitation of Liability',
              content:
                  'To the maximum extent permitted by applicable law, Klamy and its operators shall not be liable for any direct, indirect, incidental, or consequential damages resulting from:\n'
                  '• Any denial, deduction, or delay of claims by your insurance company.\n'
                  '• Temporary unavailability of the local AI server, cloud storage, or network connectivity.\n'
                  '• Inaccuracies in user-uploaded documents or optical character recognition (OCR) parsing.',
            ),

            _buildSection(
              title: '7. Account Termination',
              content:
                  'We reserve the right to suspend or terminate your account if you violate these terms, engage in fraudulent activities, or abuse our services. You may discontinue use and delete your account and records at any time.',
            ),

            _buildSection(
              title: '8. Modifications to Terms',
              content:
                  'We may update these Terms & Conditions from time to time. Continued use of Klamy following updates constitutes your acceptance of the revised terms.',
            ),

            _buildSection(
              title: '9. Governing Law & Contact',
              content:
                  'These Terms are governed by and construed in accordance with the laws of India. For any disputes or queries, contact us at:\n\n'
                  'Email: asrvtech.in@gmail.in',
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
