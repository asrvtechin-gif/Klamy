import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

/// Calls the Gemini API directly from the app — no local server or USB required.
/// Works on any internet connection (WiFi, 4G, etc.).
class ClaimLocalAiAssistantService extends GetxService {
  static const _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static const _geminiModel = 'gemini-flash-latest';
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel';
  static const _requestTimeout = Duration(seconds: 90);

  final http.Client _client = http.Client();

  // ─── Insurer GRO Emails ───────────────────────────────────────────────────
  static const _insurerGro = <String, String>{
    'star health': 'grievance@starhealth.in',
    'hdfc ergo': 'care@hdfcergo.com',
    'icici lombard': 'customersupport@icicilombard.com',
    'bajaj allianz': 'bagichelp@bajajallianz.co.in',
    'new india': 'cmd@newindia.co.in',
    'united india': 'headoffice@uiic.co.in',
    'national insurance': 'customerservice@nationalinsurance.nic.co.in',
    'oriental insurance': 'customerservice@orientalinsurance.org.in',
    'max bupa': 'grievance@maxbupa.com',
    'reliance health': 'rgicl.customerservice@relianceada.com',
    'aditya birla': 'health.services@adityabirlacapital.com',
    'care health': 'grievance@carehealth.in',
    'niva bupa': 'grievance@nivabupa.com',
    'cholamandalam': 'customerservice@cholainsurance.com',
    'tata aig': 'customersupport@tataaig.com',
    'sbi general': 'customerfirst@sbigeneral.in',
  };

  String _groEmail(String insurer) {
    final key = insurer.toLowerCase().trim();
    for (final entry in _insurerGro.entries) {
      if (key.contains(entry.key)) return entry.value;
    }
    return 'grievanceofficer@insurance.com';
  }

  // ─── Fetch logged-in user details ────────────────────────────────────────
  Future<Map<String, String>> _fetchUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    String name = (user?.displayName ?? '').trim();
    final email = (user?.email ?? '').trim();
    String phone = '';
    if (user != null) {
      try {
        final snap =
            await FirebaseDatabase.instance.ref('users/${user.uid}/profile').get();
        if (snap.exists && snap.value is Map) {
          final data = Map<String, dynamic>.from(snap.value as Map);
          if (name.isEmpty && data['displayName'] != null && data['displayName'].toString().trim().isNotEmpty) {
            name = data['displayName'].toString().trim();
          }
          phone = data['phone']?.toString().trim() ?? '';
        }
      } catch (_) {}
    }
    if (name.isEmpty) {
      name = 'Shubham Singh';
    }

    // Format today's date as "10 October 2026"
    final now = DateTime.now();
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final date = '${now.day} ${months[now.month]} ${now.year}';

    return {
      'name': name,
      'email': email,
      'phone': phone.isNotEmpty ? phone : '+91 9876543210',
      'date': date,
    };
  }

  // ─── Summarize Claim ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> summarizeClaim(
    Map<String, dynamic> claim,
  ) async {
    final claimJson = jsonEncode(claim);
    final prompt = '''
You are Klamy AI, an Indian insurance claim assistant. Analyze this claim and return a JSON object.

Claim data:
$claimJson

Return ONLY valid JSON (no markdown, no code fences) with exactly these fields:
{
  "provider": "gemini",
  "summary": "2-4 sentence summary of the claim status, key details, and what the user should focus on next",
  "suggestedDocuments": [
    {
      "category": "one of: policy, hospital_bills, discharge_summary, prescription, medical_reports, insurer_letters",
      "title": "Document display name",
      "reason": "Why this document is important for this claim"
    }
  ],
  "analyzedDocumentNames": [],
  "unavailableDocumentNames": []
}
''';

    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ],
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.3,
        'maxOutputTokens': 1024,
      },
    });

    final uri =
        Uri.parse('$_baseUrl:generateContent?key=$_geminiApiKey');
    late final http.Response response;
    try {
      response = await _client
          .post(uri,
              headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw StateError(
          'Klamy AI took too long to respond. Please try again.');
    } on http.ClientException catch (e) {
      throw StateError('Could not reach Klamy AI: ${e.message}');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
          'Klamy AI returned an error (HTTP ${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body);
    final text = decoded['candidates']?[0]?['content']?['parts']?[0]?['text'];
    if (text == null) {
      throw const FormatException('Klamy returned an empty response.');
    }

    final result = jsonDecode(text);
    if (result is! Map) {
      throw const FormatException('Klamy returned an invalid format.');
    }
    return Map<String, dynamic>.from(result);
  }

  // ─── Draft Grievance ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> draftGrievance({
    required String claimId,
    String grievanceType = 'rejection',
    String userNotes = '',
    Map<String, dynamic>? claim,
  }) async {
    final insurer = (claim?['insurer'] ?? 'Unknown Insurer').toString();
    final amount = (claim?['amount'] ?? '0').toString();
    final policyNo = (claim?['policyNumber'] ?? claimId).toString();
    final toEmail = _groEmail(insurer);

    // Fetch logged-in user's real details to auto-fill the letter
    final userDetails = await _fetchUserDetails();
    final userName = userDetails['name']!;
    final userEmail = userDetails['email']!;
    final userPhone = userDetails['phone']!;
    final todayDate = userDetails['date']!;

    final prompt = '''
You are a legal expert assistant specializing in Indian insurance law and IRDAI regulations.

Draft a formal legal grievance letter for an insurance claim dispute.

Complainant Details:
- Full Name: $userName
- Email: $userEmail
- Phone: $userPhone
- Date: $todayDate

Claim Details:
- Claim ID: $claimId
- Policy Number: $policyNo
- Insurer: $insurer
- Claim Amount: Rs.$amount
- Grievance Type: $grievanceType
- Additional Notes: ${userNotes.isNotEmpty ? userNotes : 'None'}

CRITICAL INSTRUCTIONS:
1. Use the EXACT Complainant and Claim details given above directly in the text.
2. Absolutely DO NOT include ANY bracketed placeholders like [DATE], [NAME], [INSERT ...], [YOUR NAME], [POLICY NUMBER], etc.
3. Absolutely DO NOT include any notes, instructions, or disclaimers like "(Please fill in...)", "Note: You must modify...", or "[Signature]".
4. The letter must be completely finalized and ready to dispatch, ending with a formal sign-off:
Yours faithfully,
$userName
Phone: $userPhone
Email: $userEmail
Policy No: $policyNo
Claim No: $claimId

Return ONLY a JSON object with exactly two keys: "subject" and "body".
"subject" = formal email subject line without any plus signs or placeholders.
"body" = the complete ready-to-send grievance letter text.
Do NOT include markdown code fences or any text outside the JSON.
''';

    final requestBody = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ],
        }
      ],
      'generationConfig': {
        'temperature': 0.4,
        'maxOutputTokens': 2048,
      },
    });

    final uri = Uri.parse('$_baseUrl:generateContent?key=$_geminiApiKey');
    late final http.Response response;
    try {
      response = await _client
          .post(uri,
              headers: {'Content-Type': 'application/json'}, body: requestBody)
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw StateError('Klamy AI took too long to draft the letter.');
    } on http.ClientException catch (e) {
      throw StateError('Could not reach Klamy AI: ${e.message}');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String detail = 'HTTP ${response.statusCode}';
      try {
        final err = jsonDecode(response.body);
        detail = err['error']?['message']?.toString() ?? detail;
      } catch (_) {}
      throw StateError('Klamy AI error: $detail');
    }

    final decoded = jsonDecode(response.body);
    final rawText =
        decoded['candidates']?[0]?['content']?['parts']?[0]?['text']
            ?.toString() ??
            '';

    if (rawText.isEmpty) {
      return _grievanceFallback(
          claimId, policyNo, insurer, amount, grievanceType, toEmail);
    }

    // Parse JSON from text — strip markdown fences if present
    Map<String, dynamic>? result;
    try {
      var clean = rawText.trim();
      if (clean.startsWith('```')) {
        clean = clean
            .replaceFirst(RegExp(r'^```[a-z]*\n?'), '')
            .replaceFirst(RegExp(r'```\s*$'), '')
            .trim();
      }
      final parsed = jsonDecode(clean);
      if (parsed is Map) result = Map<String, dynamic>.from(parsed);
    } catch (_) {
      // Try extracting JSON object using regex
      final jsonMatch =
          RegExp(r'\{[\s\S]*\}', multiLine: true).firstMatch(rawText);
      if (jsonMatch != null) {
        try {
          final parsed = jsonDecode(jsonMatch.group(0)!);
          if (parsed is Map) result = Map<String, dynamic>.from(parsed);
        } catch (_) {}
      }
    }

    // Clean subject (ensure no accidental pluses or bracket tokens)
    var subject = result?['subject']?.toString() ??
        'Formal Grievance: Claim $claimId – $grievanceType – $insurer';
    subject = subject.replaceAll('+', ' ').trim();

    var letterBody = result?['body']?.toString() ?? rawText;

    // Safety net: replace any leftover placeholders with real data and remove manual edit notes
    letterBody = _replacePlaceholders(
      letterBody,
      userName,
      userEmail,
      userPhone,
      todayDate,
      claimId,
      policyNo,
      insurer,
    );

    return {
      'status': 'ok',
      'toEmail': toEmail,
      'ccEmail': 'complaints@irdai.gov.in',
      'subject': subject,
      'body': letterBody,
      'claimNumber': claimId,
      'policyNumber': policyNo,
      'insurer': insurer,
    };
  }

  // ─── Chat (Streaming) ────────────────────────────────────────────────────
  Stream<String> sendClaimMessage({
    required Map<String, dynamic> claim,
    required List<Map<String, dynamic>> conversation,
    required String message,
  }) async* {
    final claimJson = jsonEncode(claim);
    final systemText =
        'You are Klamy AI, an expert Indian insurance claim assistant. '
        'You help users understand their insurance claims, suggest required documents, '
        'explain claim procedures, and guide them on IRDAI regulations. '
        'Be concise, empathetic, and practical. '
        'Claim context: $claimJson';

    // Build Gemini multi-turn contents
    final contents = <Map<String, dynamic>>[];

    // Add prior conversation turns
    for (final msg in conversation) {
      final role = (msg['role'] ?? '').toString().toLowerCase();
      contents.add({
        'role': role == 'user' ? 'user' : 'model',
        'parts': [
          {'text': (msg['text'] ?? '').toString()}
        ],
      });
    }

    // Add current user message
    contents.add({
      'role': 'user',
      'parts': [
        {'text': message}
      ],
    });

    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': systemText}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1024,
      },
    });

    final uri = Uri.parse(
        '$_baseUrl:streamGenerateContent?key=$_geminiApiKey&alt=sse');
    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = body;

    late final http.StreamedResponse response;
    try {
      response = await _client.send(request).timeout(_requestTimeout);
    } on TimeoutException {
      throw StateError('Klamy AI took too long. Please try again.');
    } on http.ClientException catch (e) {
      throw StateError('Could not reach Klamy AI: ${e.message}');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errBody = await response.stream.bytesToString();
      throw StateError(
          'Klamy AI returned an error (HTTP ${response.statusCode}): $errBody');
    }

    final buffer = StringBuffer();
    await for (final line in response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (line.startsWith('data: ')) {
        final jsonStr = line.substring(6).trim();
        if (jsonStr == '[DONE]' || jsonStr.isEmpty) continue;
        try {
          final decoded = jsonDecode(jsonStr);
          final chunk = decoded['candidates']?[0]?['content']?['parts']?[0]
              ?['text'];
          if (chunk != null && chunk.toString().isNotEmpty) {
            buffer.write(chunk);
            yield chunk.toString();
          }
        } on FormatException {
          // Skip malformed SSE lines
        }
      }
    }

    if (buffer.isEmpty) {
      throw StateError('Klamy AI did not return any response.');
    }
  }

  // ─── Fallback Template ───────────────────────────────────────────────────
  Map<String, dynamic> _grievanceFallback(
    String claimId,
    String policyNo,
    String insurer,
    String amount,
    String grievanceType,
    String toEmail, {
    String userName = 'Policyholder',
    String userEmail = '',
    String userPhone = 'N/A',
    String todayDate = '',
  }) {
    final subject =
        'Formal Grievance: Claim No. $claimId – $grievanceType – $insurer';
    final body = '''$todayDate

To,
The Grievance Redressal Officer,
$insurer

Subject: $subject

Dear Sir/Madam,

I, $userName, am writing to formally register my grievance against $insurer regarding the unjust handling of my insurance claim bearing Claim No. $claimId under Policy No. $policyNo.

The nature of my grievance is: $grievanceType

I am aggrieved to inform you that my claim for Rs.$amount has not been processed in accordance with the IRDAI (Protection of Policyholders' Interests) Regulations, 2017, and the IRDAI Master Circular on Health Insurance (2024). The insurer's action constitutes a violation of:

1. Regulation 9 of IRDAI (Protection of Policyholders' Interests) Regulations, 2017 — requiring fair and prompt claim settlement.
2. IRDAI Master Circular on Health Insurance — Clause on Claim Settlement timelines.
3. Insurance Act, 1938 — Section 64VB and related provisions on fair dealing.

I hereby request the following:
1. Immediate review and resolution of the grievance.
2. Written communication of the decision with proper justification.
3. If the claim is rejected, detailed reasoning citing specific policy clause(s).

Failing resolution within the stipulated 15-day period, I reserve the right to escalate this matter to:
- The IRDAI Grievance Cell at complaints@irdai.gov.in
- The Insurance Ombudsman of the relevant jurisdiction.

Yours faithfully,
$userName
Phone: $userPhone
Email: $userEmail
Policy No: $policyNo
Claim No: $claimId''';

    return {
      'status': 'ok',
      'toEmail': toEmail,
      'ccEmail': 'complaints@irdai.gov.in',
      'subject': subject,
      'body': body,
      'claimNumber': claimId,
      'policyNumber': policyNo,
      'insurer': insurer,
    };
  }

  // ─── Replace Placeholders ────────────────────────────────────────────────
  /// Replaces any leftover bracket-style placeholders in the Gemini-generated
  /// letter with the real user data as a safety net.
  String _replacePlaceholders(
    String text,
    String name,
    String email,
    String phone,
    String date,
    String claimId,
    String policyNo,
    String insurer,
  ) {
    var result = text
        .replaceAll(RegExp(r'\[(?:insert\s+)?date(?:\s+of\s+incident)?\]', caseSensitive: false), date)
        .replaceAll(RegExp(r'\[(?:your\s+|complainant\s+|full\s+|policyholder\s+)?name\]', caseSensitive: false), name)
        .replaceAll(RegExp(r'\[(?:your\s+|contact\s+|mobile\s+)?phone(?:\s+number)?\]', caseSensitive: false), phone)
        .replaceAll(RegExp(r'\[(?:contact\s+|mobile\s+)number\]', caseSensitive: false), phone)
        .replaceAll(RegExp(r'\[(?:your\s+)?email(?:\s+address)?\]', caseSensitive: false), email)
        .replaceAll(RegExp(r'\[(?:your\s+|insert\s+)?policy(?:\s+number)?\]', caseSensitive: false), policyNo)
        .replaceAll(RegExp(r'\[(?:your\s+|insert\s+)?claim(?:\s+number|\s+id)?\]', caseSensitive: false), claimId)
        .replaceAll(RegExp(r'\[(?:insert\s+)?insurer(?:\s+name)?\]', caseSensitive: false), insurer)
        .replaceAll(RegExp(r'\[signature\]', caseSensitive: false), name);

    // Remove any trailing or bracketed instructions telling the user to edit manually
    result = result
        .replaceAll(RegExp(r'\n?\s*[\(\[]\s*Note:?[^\)\]]*[\)\]]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\n?\s*\*Note:?[^\n]*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\n?\s*Note:?[^\n]*fill[^\n]*', caseSensitive: false), '');

    return result.trim();
  }

  @override
  void onClose() {
    _client.close();
    super.onClose();
  }
}
