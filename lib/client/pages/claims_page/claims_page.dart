import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'claims_controller.dart';

class ClaimsPage extends StatelessWidget {
  ClaimsPage({super.key});

  final ClaimsController controller = Get.find<ClaimsController>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Header Area
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF0F2942),
                      size: 24,
                    ),
                    onPressed: controller.prevStep,
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Create Claim',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F2942),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 20,
                  color: Color(0xFF0F2942),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const Padding(
            padding: EdgeInsets.only(left: 40.0),
            child: Text(
              'Tell us about your claim so we can set up your workspace.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.3,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 2. Stepper Progress Bar
          Obx(() => _buildStepper(controller.currentStep.value)),

          const SizedBox(height: 24),

          // 3. Main Form Card
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step Title & Icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person_pin_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '1. Policy Details',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2942),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  "Let's start with your policy information.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 20),

                // Field 1: Insurance Provider
                const Text(
                  'Insurance Provider',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2942),
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: controller.selectedInsurer.value.isEmpty
                              ? null
                              : controller.selectedInsurer.value,
                          hint: const Text(
                            'Select your insurer',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF64748B),
                          ),
                          items: controller.insurers.map((String insurer) {
                            return DropdownMenuItem<String>(
                              value: insurer,
                              child: Text(
                                insurer,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF0F2942),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: controller.setInsurer,
                        ),
                      ),
                    )),

                const SizedBox(height: 16),

                // Field 2: Policy Number
                const Text(
                  'Policy Number',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2942),
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: controller.policyNumberController,
                  hint: 'Enter policy number',
                ),

                const SizedBox(height: 16),

                // Field 3: Policy Holder Name
                const Text(
                  'Policy Holder Name',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2942),
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: controller.policyHolderController,
                  hint: 'As per policy document',
                ),

                const SizedBox(height: 16),

                // Field 4: Policy Start & End Date
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Policy Start Date',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F2942),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Obx(() => _buildDateField(
                                context,
                                text: controller.startDate.value.isEmpty
                                    ? 'DD MMM YYYY'
                                    : controller.startDate.value,
                                onTap: () => controller.pickDate(context, true),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Policy End Date',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F2942),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Obx(() => _buildDateField(
                                context,
                                text: controller.endDate.value.isEmpty
                                    ? 'DD MMM YYYY'
                                    : controller.endDate.value,
                                onTap: () => controller.pickDate(context, false),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Help Box
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F7F5),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF0F766E),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Need help?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F2942),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'You can find your policy details in your policy document or on your insurer\'s website.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF5B7083),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          color: Color(0xFF0F766E),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 4. Next Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: controller.nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF15808D),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Stepper Header Component
  Widget _buildStepper(int activeStep) {
    final steps = [
      {'num': 1, 'title': 'Policy\nDetails'},
      {'num': 2, 'title': 'Claim\nDetails'},
      {'num': 3, 'title': 'Documents'},
      {'num': 4, 'title': 'Review'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (index) {
        final stepNum = steps[index]['num'] as int;
        final isActive = stepNum <= activeStep;
        final isCurrent = stepNum == activeStep;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isActive
                            ? const Color(0xFF0F766E)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFF0F766E)
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF0F766E)
                            : const Color(0xFFCBD5E1),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$stepNum',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isCurrent
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: stepNum < activeStep
                            ? const Color(0xFF0F766E)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                steps[index]['title'] as String,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isCurrent
                      ? const Color(0xFF0F2942)
                      : const Color(0xFF64748B),
                  height: 1.2,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 14, color: Color(0xFF0F2942)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context, {
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: text == 'DD MMM YYYY'
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF0F2942),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
