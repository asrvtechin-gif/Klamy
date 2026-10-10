import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../components/claim_assistant_sheet.dart';
import '../../components/skeleton_box.dart';
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
          Obx(() {
            final isCreateTab = controller.selectedTab.value == 1;
            return Row(
              children: [
                if (isCreateTab) ...[
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
                  const SizedBox(width: 12),
                ],
                Text(
                  isCreateTab ? 'create_new_claim'.tr : 'claims_workspace'.tr,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2942),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            );
          }),

          const SizedBox(height: 6),

          Obx(
            () => Text(
              controller.selectedTab.value == 0
                  ? 'claims_subtitle'.tr
                  : 'Fill in the details below to initiate a new claim request.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.3,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Tab Body View
          Obx(() {
            if (controller.selectedTab.value == 0) {
              return _buildMyClaimsTab(context);
            } else {
              return _buildCreateClaimTab(context);
            }
          }),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
  Widget _buildMyClaimsTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'your_submitted_claims'.tr,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F2942),
              ),
            ),
            InkWell(
              onTap: () => controller.switchTab(1),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFB0E5E0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add, size: 16, color: Color(0xFF00A3A1)),
                    const SizedBox(width: 4),
                    Text(
                      'new_claim'.tr,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00A3A1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Obx(() {
          if (controller.isLoadingClaims.value) {
            return _buildClaimsLoadingState();
          }
          if (controller.claimsList.isEmpty) {
            return _buildEmptyClaimsState();
          }

          return Column(
            children: List.generate(controller.claimsList.length, (index) {
              final claim = controller.claimsList[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildClaimCard(context, claim),
              );
            }),
          );
        }),
      ],
    );
  }

  Widget _buildClaimsLoadingState() => Column(
    children: List.generate(
      2,
      (_) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonBox(width: 42, height: 42, radius: 12),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 132, height: 13),
                      SizedBox(height: 8),
                      SkeletonBox(width: 188, height: 10),
                    ],
                  ),
                ),
                SkeletonBox(width: 64, height: 22, radius: 12),
              ],
            ),
            SizedBox(height: 18),
            SkeletonBox(height: 40, radius: 12),
            SizedBox(height: 16),
            SkeletonBox(height: 8, radius: 5),
            SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: SkeletonBox(height: 30)),
                SizedBox(width: 12),
                Expanded(child: SkeletonBox(height: 30)),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildEmptyClaimsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFE0F2FE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.note_add_outlined,
              size: 32,
              color: Color(0xFF0284C7),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Claims Found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2942),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'You haven\'t created or uploaded any claims yet. Tap below to create your first claim.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => controller.switchTab(1),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text(
              'Create New Claim',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimCard(BuildContext context, Map<String, dynamic> claim) {
    final String status = claim['status'] ?? 'Under Review';
    Color statusBg = const Color(0xFFDCFCE7);
    Color statusFg = const Color(0xFF16A34A);

    if (status == 'Submitted') {
      statusBg = const Color(0xFFFEF3C7);
      statusFg = const Color(0xFFD97706);
    } else if (status == 'Approved') {
      statusBg = const Color(0xFFE0F2FE);
      statusFg = const Color(0xFF0284C7);
    }

    final double progress = (claim['progress'] as num?)?.toDouble() ?? 0.5;

    return InkWell(
      onTap: () => ClaimAssistantSheet.show(context, claim),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F7F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: Color(0xFF0F766E),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        claim['title'] ?? 'Health Claim',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F2942),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Claim No: ${claim['id']} • ${claim['insurer']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusFg,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Details grid
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSubDetail('Patient', claim['patientName'] ?? 'Self'),
                  _buildSubDetail('Hospital', claim['hospitalName'] ?? 'N/A'),
                  _buildSubDetail('Policy No.', claim['policyNumber'] ?? 'N/A'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Progress bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF0F766E),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2942),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 14),

            // Bottom Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCol(
                  'Amount',
                  '₹${(claim['amount'] as num?)?.toStringAsFixed(0) ?? claim['amount'] ?? '0'}',
                ),
                _buildStatCol('Documents', claim['docsCount'] ?? '0'),
                _buildStatCol('Active', claim['daysActive'] ?? '0'),
                _buildStatCol(
                  'Actions',
                  '${claim['openActions'] ?? 0} Pending',
                  valueColor: (claim['openActions'] ?? 0) > 0
                      ? const Color(0xFFE11D48)
                      : const Color(0xFF16A34A),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: 90,
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2942),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCol(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor ?? const Color(0xFF0F2942),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 1: CREATE NEW CLAIM VIEW (4-Step Wizard)
  // ==========================================
  Widget _buildCreateClaimTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stepper Progress Bar
        Obx(() => _buildStepper(controller.currentStep.value)),

        const SizedBox(height: 20),

        // Step Form View
        Obx(() {
          switch (controller.currentStep.value) {
            case 1:
              return _buildStep1PolicyDetails(context);
            case 2:
              return _buildStep2ClaimDetails(context);
            case 3:
              return _buildStep3DocumentUpload(context);
            case 4:
              return _buildStep4Review(context);
            default:
              return _buildStep1PolicyDetails(context);
          }
        }),

        const SizedBox(height: 24),

        // Next / Submit Button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: controller.nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: controller.isSubmittingClaim.value
                    ? const [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Saving claim...'),
                      ]
                    : [
                        Text(
                          controller.currentStep.value == 4
                              ? 'Submit Claim'
                              : 'Next Step',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          controller.currentStep.value == 4
                              ? Icons.check_circle_outline_rounded
                              : Icons.arrow_forward_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Stepper Header
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
                      color: isCurrent ? const Color(0xFF0F766E) : Colors.white,
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

  // STEP 1: POLICY DETAILS
  Widget _buildStep1PolicyDetails(BuildContext context) {
    return _buildFormCard(
      title: 'Policy Information',
      subtitle: 'Provide your health insurance policy information.',
      icon: Icons.shield_outlined,
      children: [
        const Text(
          'Insurance Provider',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F2942),
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Container(
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
                  style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
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
          ),
        ),

        const SizedBox(height: 16),

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
          hint: 'Enter policy number (e.g. POL-9823412)',
        ),

        const SizedBox(height: 16),

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
          hint: 'As mentioned on policy document',
        ),

        const SizedBox(height: 16),

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
                  Obx(
                    () => _buildDateField(
                      context,
                      text: controller.startDate.value.isEmpty
                          ? 'DD/MM/YYYY'
                          : controller.startDate.value,
                      onTap: () => controller.pickDate(context, 'startDate'),
                    ),
                  ),
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
                  Obx(
                    () => _buildDateField(
                      context,
                      text: controller.endDate.value.isEmpty
                          ? 'DD/MM/YYYY'
                          : controller.endDate.value,
                      onTap: () => controller.pickDate(context, 'endDate'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 2: CLAIM DETAILS
  Widget _buildStep2ClaimDetails(BuildContext context) {
    return _buildFormCard(
      title: 'Claim Information',
      subtitle: 'Specify hospitalization and patient details.',
      icon: Icons.local_hospital_outlined,
      children: [
        const Text(
          'Claim Title / Hospitalization Reason',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F2942),
          ),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: controller.claimTitleController,
          hint: 'e.g. Mother\'s Hospitalization or Dengue Treatment',
        ),

        const SizedBox(height: 16),

        const Text(
          'Patient Name',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F2942),
          ),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: controller.patientNameController,
          hint: 'Name of the hospitalized person',
        ),

        const SizedBox(height: 16),

        const Text(
          'Hospital Name',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F2942),
          ),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: controller.hospitalNameController,
          hint: 'e.g. Max Super Speciality Hospital',
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estimated Claim Amount',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F2942),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: controller.claimAmountController,
                    hint: 'e.g. 1,50,000',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Admission Date',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F2942),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => _buildDateField(
                      context,
                      text: controller.admissionDate.value.isEmpty
                          ? 'DD/MM/YYYY'
                          : controller.admissionDate.value,
                      onTap: () =>
                          controller.pickDate(context, 'admissionDate'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 3: DOCUMENT UPLOAD
  Widget _buildStep3DocumentUpload(BuildContext context) {
    final categories = <Map<String, dynamic>>[
      {
        'id': 'policy',
        'title': 'Policy Document',
        'subtitle': 'Health policy, policy schedule',
        'badge': 'Required',
        'icon': Icons.policy_outlined,
      },
      {
        'id': 'hospital_bills',
        'title': 'Hospital Bills',
        'subtitle': 'Bills, invoices, payment receipts',
        'badge': 'Recommended',
        'icon': Icons.receipt_long_outlined,
      },
      {
        'id': 'discharge_summary',
        'title': 'Discharge Summary',
        'subtitle': 'Hospital discharge summary',
        'badge': 'Recommended',
        'icon': Icons.medical_information_outlined,
      },
      {
        'id': 'prescription',
        'title': 'Prescription',
        'subtitle': 'Doctor prescriptions, medicines',
        'badge': 'Recommended',
        'icon': Icons.medication_outlined,
      },
      {
        'id': 'medical_reports',
        'title': 'Medical Reports',
        'subtitle': 'Lab tests, scans, reports',
        'badge': 'Recommended',
        'icon': Icons.biotech_outlined,
      },
      {
        'id': 'insurer_letters',
        'title': 'Insurer Letters',
        'subtitle': 'Approval, rejection, deduction letters',
        'badge': 'Optional',
        'icon': Icons.mail_outline_rounded,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 0),
        const Text(
          'Document Categories',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F2942),
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];
            final id = category['id'] as String;
            return Obx(
              () => _buildDocumentCategoryCard(
                id: id,
                title: category['title'] as String,
                subtitle: category['subtitle'] as String,
                badge: category['badge'] as String,
                icon: category['icon'] as IconData,
                selected: controller.selectedDocumentCategory.value == id,
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        const Text(
          'Upload Files',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F2942),
          ),
        ),
        const SizedBox(height: 10),
        Obx(
          () => InkWell(
            onTap: controller.isUploadingDocuments.value
                ? null
                : controller.pickAndUploadDocuments,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
              decoration: BoxDecoration(
                color: const Color(0xFFFCFEFF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFB8D8DF),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    controller.isUploadingDocuments.value
                        ? Icons.hourglass_top_rounded
                        : Icons.cloud_upload_outlined,
                    color: const Color(0xFF0F5075),
                    size: 34,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.isUploadingDocuments.value
                        ? 'Uploading files...'
                        : 'Tap to upload files',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F2942),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'PDF, JPG, PNG • Max 10 MB per file',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  if (controller.isUploadingDocuments.value) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(
                      color: Color(0xFF0F766E),
                      backgroundColor: Color(0xFFDDEFEA),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: Obx(
            () => ElevatedButton.icon(
              onPressed: controller.isUploadingDocuments.value
                  ? null
                  : controller.pickAndUploadDocuments,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F8B8D),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.note_add_outlined),
              label: const Text(
                'Select Files',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        Obx(() {
          if (controller.uploadedDocuments.isEmpty) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: controller.uploadedDocuments
                  .map(
                    (document) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFB0E5E0)),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF0F766E),
                        ),
                        title: Text(
                          document.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _documentCategoryLabel(document.category),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          );
        }),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFF0F766E), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Uploaded documents will be linked to this claim.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF42777C)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentCategoryCard({
    required String id,
    required String title,
    required String subtitle,
    required String badge,
    required IconData icon,
    required bool selected,
  }) {
    return InkWell(
      onTap: () => controller.selectedDocumentCategory.value = id,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF9F8) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? const Color(0xFF20A6A1) : const Color(0xFFE3EBEF),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFD1F2EF)
                    : const Color(0xFFEAF3FB),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 19,
                color: selected
                    ? const Color(0xFF0F766E)
                    : const Color(0xFF174A70),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                height: 1.15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F2942),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9,
                  height: 1.2,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFD8F2ED)
                    : const Color(0xFFEAF3F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 8,
                  color: selected
                      ? const Color(0xFF277D70)
                      : const Color(0xFF526B7A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _documentCategoryLabel(String category) {
    switch (category) {
      case 'policy':
        return 'Policy Document';
      case 'hospital_bills':
        return 'Hospital Bills';
      case 'discharge_summary':
        return 'Discharge Summary';
      case 'prescription':
        return 'Prescription';
      case 'medical_reports':
        return 'Medical Reports';
      case 'insurer_letters':
        return 'Insurer Letters';
      default:
        return 'Claim Document';
    }
  }

  // STEP 4: REVIEW
  Widget _buildStep4Review(BuildContext context) {
    return _buildFormCard(
      title: 'Verify & Submit',
      subtitle: 'Please verify all details before submitting your claim.',
      icon: Icons.fact_check_outlined,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _buildReviewRow(
                'Insurer',
                controller.selectedInsurer.value.isEmpty
                    ? 'Star Health Insurance'
                    : controller.selectedInsurer.value,
              ),
              const Divider(height: 16),
              _buildReviewRow(
                'Policy Number',
                controller.policyNumberController.text.trim().isEmpty
                    ? 'POL-1029384'
                    : controller.policyNumberController.text.trim(),
              ),
              const Divider(height: 16),
              _buildReviewRow(
                'Policy period',
                '${controller.startDate.value.isEmpty ? '—' : controller.startDate.value} - ${controller.endDate.value.isEmpty ? '—' : controller.endDate.value}',
              ),
              const Divider(height: 16),
              _buildReviewRow(
                'Claim Title',
                controller.claimTitleController.text.trim().isEmpty
                    ? 'Health Claim'
                    : controller.claimTitleController.text.trim(),
              ),
              const Divider(height: 16),
              _buildReviewRow(
                'Patient Name',
                controller.patientNameController.text.trim().isEmpty
                    ? 'Self'
                    : controller.patientNameController.text.trim(),
              ),
              const Divider(height: 16),
              _buildReviewRow(
                'Hospital Name',
                controller.hospitalNameController.text.trim().isEmpty
                    ? 'City Hospital'
                    : controller.hospitalNameController.text.trim(),
              ),
              const Divider(height: 16),
              _buildReviewRow(
                'Claim Amount',
                controller.claimAmountController.text.trim().isEmpty
                    ? '₹1,50,000'
                    : '₹${controller.claimAmountController.text.trim()}',
              ),
              const Divider(height: 16),
              _buildReviewRow(
                'Admission Date',
                controller.admissionDate.value.isEmpty
                    ? '—'
                    : controller.admissionDate.value,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F2942),
          ),
        ),
      ],
    );
  }

  // Reusable Form Card Wrapper
  Widget _buildFormCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2942),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
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
        keyboardType: keyboardType,
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
                  color: text.contains('DD')
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
