import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/claim_local_ai_assistant_service.dart';

class GrievanceDraftSheet extends StatefulWidget {
  final Map<String, dynamic> claim;

  const GrievanceDraftSheet({super.key, required this.claim});

  static Future<void> show(BuildContext context, Map<String, dynamic> claim) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => GrievanceDraftSheet(claim: claim),
      );

  @override
  State<GrievanceDraftSheet> createState() => _GrievanceDraftSheetState();
}

class _GrievanceDraftSheetState extends State<GrievanceDraftSheet> {
  static const _accent = Color(0xFF0F766E);
  final _notesController = TextEditingController();
  late final ClaimLocalAiAssistantService _assistant;

  String _selectedType = 'Unfair Claim Rejection';
  final List<String> _types = [
    'Unfair Claim Rejection',
    'Arbitrary Deduction / Short Settlement',
    'Undue Delay in Processing',
    'Hospitalization Cashless Denial',
  ];

  bool _loading = false;
  String? _draftError;          // show errors inline — never use Get.snackbar inside modal
  Map<String, dynamic>? _draftData;
  late TextEditingController _subjectController;
  late TextEditingController _bodyController;

  @override
  void initState() {
    super.initState();
    _assistant = Get.isRegistered<ClaimLocalAiAssistantService>()
        ? Get.find<ClaimLocalAiAssistantService>()
        : Get.put(ClaimLocalAiAssistantService(), permanent: true);
    _subjectController = TextEditingController();
    _bodyController = TextEditingController();
    _generateDraft();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _generateDraft() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _draftError = null;
    });
    try {
      final claimId = (widget.claim['id'] ?? '').toString();
      final res = await _assistant.draftGrievance(
        claimId: claimId,
        grievanceType: _selectedType,
        userNotes: _notesController.text.trim(),
        claim: widget.claim,
      );
      if (!mounted) return;
      setState(() {
        _draftData = res;
        _subjectController.text = res['subject'] ?? '';
        _bodyController.text = res['body'] ?? '';
        _loading = false;
        _draftError = null;
      });
    } catch (e) {
      if (!mounted) return;
      // Show error inline — never call Get.snackbar inside a modal bottom sheet
      // (causes _dependents.isEmpty assertion crash)
      setState(() {
        _loading = false;
        _draftError = e.toString()
            .replaceFirst(RegExp(r'^(Bad state:\s*|Exception:\s*|StateError:\s*)'), '');
      });
    }
  }

  Future<void> _launchEmail() async {
    if (_draftData == null) return;
    final to = (_draftData!['toEmail'] ?? '').toString().trim();
    final cc = (_draftData!['ccEmail'] ?? 'complaints@irdai.gov.in').toString().trim();
    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();

    // Always copy full letter to clipboard first
    await Clipboard.setData(ClipboardData(text: '$subject\n\n$body'));

    // Open mailto with only TO + CC + Subject (no body — long bodies break most email apps)
    // We use Uri.encodeComponent so spaces are encoded as %20 instead of +
    String encodeQueryParameters(Map<String, String> params) {
      return params.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
    }

    final query = encodeQueryParameters({
      if (cc.isNotEmpty) 'cc': cc,
      if (subject.isNotEmpty) 'subject': subject,
    });
    final mailtoUri = Uri.parse('mailto:$to${query.isNotEmpty ? '?$query' : ''}');

    bool launched = false;
    try {
      launched = await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
    } catch (_) {}

    if (!mounted) return;

    // Use ScaffoldMessenger — NOT Get.snackbar — inside modal bottom sheets
    final msg = launched
        ? '📋 Letter copied! Paste it in the email body (long-press → Paste).\nTO: $to   CC: $cc'
        : '📋 No email app found. Letter copied to clipboard!\nSend manually to: $to (CC: $cc)';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 12)),
        backgroundColor: launched ? const Color(0xFF0F766E) : Colors.black87,
        duration: const Duration(seconds: 7),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.gavel_rounded, color: Colors.red, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'File IRDAI Grievance',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F2942),
                        ),
                      ),
                      Text(
                        'Direct email to Insurer GRO + CC IRDAI',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: _loading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: _accent),
                        SizedBox(height: 16),
                        Text(
                          'Klamy AI is drafting legal grievance letter…',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      // Claim summary tag
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shield_outlined, color: _accent, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${widget.claim['insurer'] ?? 'Insurer'} • Claim No: ${widget.claim['id']} • ₹${widget.claim['amount'] ?? '0'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F2942),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      if (_draftError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Draft error: $_draftError',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
                                ),
                              ),
                              TextButton(
                                onPressed: _generateDraft,
                                child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Grievance category dropdown
                      const Text(
                        'Grievance Category',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedType,
                            isExpanded: true,
                            items: _types
                                .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedType = val);
                                _generateDraft();
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Email recipient badges
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('TO (Insurer GRO)', style: TextStyle(fontSize: 10, color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold)),
                                  Text(
                                    _draftData?['toEmail'] ?? 'gro@insurance.com',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('CC (IRDAI Complaints)', style: TextStyle(fontSize: 10, color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                                  Text(
                                    'complaints@irdai.gov.in',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Subject line
                      const Text(
                        'Subject Line',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _subjectController,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Draft body
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Legal Letter Body (Editable)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _bodyController.text));
                              Get.snackbar('Copied', 'Letter text copied to clipboard!');
                            },
                            icon: const Icon(Icons.copy_rounded, size: 14),
                            label: const Text('Copy', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _bodyController,
                        maxLines: 12,
                        style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF334155)),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Dispatch button
                      ElevatedButton.icon(
                        onPressed: _draftData == null ? null : _launchEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text(
                          'Copy Letter & Open Email App',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Regenerate button
                      OutlinedButton.icon(
                        onPressed: _generateDraft,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _accent,
                          side: const BorderSide(color: _accent),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Re-draft with Klamy AI', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
