import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/claim_document_upload_service.dart';
import '../../services/claim_local_ai_assistant_service.dart';
import '../../services/claim_repository.dart';
import 'grievance_draft_sheet.dart';

class ClaimAssistantSheet extends StatefulWidget {
  final Map<String, dynamic> claim;

  const ClaimAssistantSheet({super.key, required this.claim});

  static Future<void> show(BuildContext context, Map<String, dynamic> claim) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ClaimAssistantSheet(claim: claim),
      );

  @override
  State<ClaimAssistantSheet> createState() => _ClaimAssistantSheetState();
}

class _ClaimAssistantSheetState extends State<ClaimAssistantSheet>
    with SingleTickerProviderStateMixin {
  static const _accent = Color(0xFF0F766E);
  late final ClaimLocalAiAssistantService _assistant;
  late final ClaimRepository _repository;
  late final Map<String, dynamic> _claim;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  final List<Map<String, dynamic>> _vaultDocuments = [];
  late final AnimationController _skeletonController;
  late final Animation<double> _skeletonPulse;
  StreamSubscription<List<Map<String, dynamic>>>? _vaultSubscription;

  bool _reviewLoadStarted = false;
  bool _loadingReview = true;
  bool _loadingChat = true;
  bool _sendingMessage = false;
  bool _waitingForFirstChunk = false;
  String? _reviewError;
  String? _uploadingCategory;
  String _summary = '';
  List<Map<String, dynamic>> _suggestions = [];
  List<String> _analyzedDocumentNames = [];
  List<String> _unavailableDocumentNames = [];

  @override
  void initState() {
    super.initState();
    _skeletonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _skeletonPulse = Tween<double>(begin: 0.42, end: 1).animate(
      CurvedAnimation(parent: _skeletonController, curve: Curves.easeInOut),
    );
    _claim = Map<String, dynamic>.from(widget.claim);
    _assistant = Get.isRegistered<ClaimLocalAiAssistantService>()
        ? Get.find<ClaimLocalAiAssistantService>()
        : Get.put(ClaimLocalAiAssistantService(), permanent: true);
    _repository = Get.isRegistered<ClaimRepository>()
        ? Get.find<ClaimRepository>()
        : Get.put(ClaimRepository(), permanent: true);
    _vaultSubscription = _repository.watchDocuments().listen(
      (documents) {
        if (!mounted) return;
        setState(() {
          _vaultDocuments
            ..clear()
            ..addAll(documents);
        });
        if (!_reviewLoadStarted) {
          _reviewLoadStarted = true;
          _loadReview();
        }
      },
      onError: (_) {
        if (mounted && !_reviewLoadStarted) {
          _reviewLoadStarted = true;
          _loadReview();
        }
      },
    );
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    try {
      final messages = await _repository.loadClaimChatHistory(
        claimId: (_claim['id'] ?? '').toString(),
      );
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(
            messages.map(
              (message) => _ChatMessage(
                text: (message['text'] ?? '').toString(),
                fromUser: message['role'] == 'User',
              ),
            ),
          );
        _loadingChat = false;
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingChat = false);
      _showMessage(
        'Could not load this claim chat history: $error',
        isError: true,
      );
    }
  }

  Future<void> _loadReview({bool refresh = false}) async {
    setState(() {
      _loadingReview = true;
      _reviewError = null;
    });
    try {
      final cached = _claim['aiReview'];
      final currentDocumentUrls = [..._uploadedDocuments, ..._vaultDocuments]
          .map(
            (document) =>
                (document['documentUrl'] ?? document['secureUrl'] ?? '')
                    .toString(),
          )
          .where((url) => url.isNotEmpty)
          .toSet();
      final cachedDocumentUrls =
          cached is Map && cached['reviewedDocumentUrls'] is List
          ? (cached['reviewedDocumentUrls'] as List)
                .map((url) => url.toString())
                .toSet()
          : <String>{};
      final canUseCachedReview =
          !refresh &&
          cached is Map &&
          (cached['provider'] == 'local_qwen' || cached['provider'] == 'gemini') &&
          currentDocumentUrls.difference(cachedDocumentUrls).isEmpty;
      final review = canUseCachedReview
          ? Map<String, dynamic>.from(cached)
          : await _assistant.summarizeClaim(_claim);
      final suggestedValue = review['suggestedDocuments'];
      final suggestedList = suggestedValue is List
          ? suggestedValue
          : suggestedValue is Map
          ? suggestedValue.values.toList()
          : null;
      if (review['summary'] == null || suggestedList == null) {
        throw const FormatException('Klamy returned an incomplete response.');
      }
      if (!mounted) return;
      setState(() {
        _summary = review['summary'].toString();
        _suggestions = suggestedList
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _analyzedDocumentNames =
            (review['analyzedDocumentNames'] is List
                    ? review['analyzedDocumentNames'] as List
                    : const <dynamic>[])
                .map((name) => name.toString())
                .toList();
        _unavailableDocumentNames =
            (review['unavailableDocumentNames'] is List
                    ? review['unavailableDocumentNames'] as List
                    : const <dynamic>[])
                .map((name) => name.toString())
                .toList();
        _loadingReview = false;
      });
      if (!canUseCachedReview) {
        try {
          await _repository.saveClaimAiReview(
            claimId: (_claim['id'] ?? '').toString(),
            review: review,
          );
        } catch (error) {
          // Keep the assistant usable, but make the failed Vault sync visible.
          _showMessage(
            'Klamy suggestions could not sync to Documents Vault: $error',
            isError: true,
          );
        }
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingReview = false;
        _reviewError = error.toString().replaceFirst(RegExp(r'^(Bad state:\s*|Exception:\s*|StateError:\s*|FormatException:\s*)'), '');
      });
    }
  }

  List<Map<String, dynamic>> get _uploadedDocuments {
    final value = _claim['documents'];
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (value is Map) {
      return value.values
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return [];
  }

  Set<String> get _uploadedCategories => _vaultDocuments
      .map((document) => (document['category'] ?? '').toString())
      .toSet();

  Future<void> _uploadForCategory(String category) async {
    if (_uploadingCategory != null) return;
    if (!ClaimDocumentUploadService.isConfigured) {
      _showMessage(
        'Cloudinary is not configured. Check the cloud name and unsigned upload preset.',
        isError: true,
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      if (file.size > 10 * 1024 * 1024) {
        _showMessage('Each file must be 10 MB or smaller.', isError: true);
        return;
      }
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        _showMessage('Could not read the selected file.', isError: true);
        return;
      }
      setState(() => _uploadingCategory = category);
      final uploadService = Get.isRegistered<ClaimDocumentUploadService>()
          ? Get.find<ClaimDocumentUploadService>()
          : Get.put(ClaimDocumentUploadService(), permanent: true);
      final uploaded = await uploadService.upload(
        fileName: file.name,
        bytes: bytes,
        category: category,
      );
      final recordId = await _repository.saveUploadedDocument(
        uploaded.toJson(),
      );
      final document = {...uploaded.toJson(), 'recordId': recordId};
      final claimId = (_claim['id'] ?? '').toString();
      await _repository.attachUploadedDocumentToClaim(
        claimId: claimId,
        documentId: recordId,
        document: document,
      );
      if (!mounted) return;
      setState(() {
        final documents = _uploadedDocuments..add(document);
        _claim['documents'] = documents;
        _claim['docsCount'] = '${documents.length} / 6';
        _claim['progress'] = (documents.length / 6).clamp(0.0, 1.0);
      });
      _showMessage('Document uploaded and linked to this claim.');
      unawaited(_loadReview(refresh: true));
    } catch (error) {
      _showMessage('Upload failed: $error', isError: true);
    } finally {
      if (mounted) setState(() => _uploadingCategory = null);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sendingMessage || _loadingChat) return;
    _messageController.clear();
    final recentMessages = _messages
        .where((message) => message.text.trim().isNotEmpty)
        .toList();
    final conversation = recentMessages.reversed
        .take(8)
        .toList()
        .reversed
        .map(
          (message) => {
            'role': message.fromUser ? 'User' : 'Klamy',
            'text': message.text,
          },
        )
        .toList();
    final assistantMessage = _ChatMessage(text: '');
    setState(() {
      _messages.add(_ChatMessage(text: text, fromUser: true));
      _messages.add(assistantMessage);
      _sendingMessage = true;
      _waitingForFirstChunk = true;
    });
    _scrollToBottom();
    try {
      await _repository.appendClaimChatMessage(
        claimId: (_claim['id'] ?? '').toString(),
        role: 'User',
        text: text,
      );
      await for (final chunk in _assistant.sendClaimMessage(
        claim: _claim,
        conversation: conversation,
        message: text,
      )) {
        if (!mounted) return;
        setState(() {
          assistantMessage.text += chunk;
          if (assistantMessage.text.contains('<think>') || assistantMessage.text.contains('</think>')) {
            assistantMessage.text = assistantMessage.text
                .replaceAll(RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false), '')
                .replaceAll(RegExp(r'<think>[\s\S]*', caseSensitive: false), '');
          }
          _waitingForFirstChunk = false;
        });
        _scrollToBottom(animate: false);
      }
      final cleanAnswer = assistantMessage.text
          .replaceAll(RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false), '')
          .replaceAll(RegExp(r'</?think>', caseSensitive: false), '')
          .trim();
      assistantMessage.text = cleanAnswer;
      if (cleanAnswer.isEmpty) throw StateError('Klamy did not return an answer.');
      try {
        await _repository.appendClaimChatMessage(
          claimId: (_claim['id'] ?? '').toString(),
          role: 'Klamy',
          text: cleanAnswer,
        );
      } catch (error) {
        _showMessage(
          'Klamy replied, but the reply could not be saved: $error',
          isError: true,
        );
      }
    } catch (error) {
      if (!mounted) return;
      final partialReply = assistantMessage.text.trim();
      setState(() {
        _waitingForFirstChunk = false;
        if (partialReply.isEmpty) {
          _messages.remove(assistantMessage);
          _messages.add(_ChatMessage(text: _chatErrorMessage(error)));
        } else {
          assistantMessage.text =
              '$partialReply\n\nReply interrupted. Ask again if you need the rest.';
        }
      });
      if (partialReply.isNotEmpty) {
        try {
          await _repository.appendClaimChatMessage(
            claimId: (_claim['id'] ?? '').toString(),
            role: 'Klamy',
            text: assistantMessage.text,
          );
        } catch (_) {
          // Keep the partial response visible even if saving it fails.
        }
      }
    } finally {
      if (mounted) {
        setState(() => _sendingMessage = false);
        _scrollToBottom();
      }
    }
  }

  String _chatErrorMessage(Object error) {
    final message = error.toString().replaceFirst(RegExp(r'^(Bad state:\s*|Exception:\s*|StateError:\s*)'), '');
    if (message.contains('App Check could not provide a token')) {
      return 'Klamy could not verify this app. Check the Firebase App Check setup and try again.';
    }
    if (message.contains('AI rate or quota limit')) {
      return 'AI usage limit reached, or the service is busy. Wait a little and retry.';
    }
    if (message.contains('Ollama is not running')) {
      return 'The laptop model server is stopped. Start Ollama and the Klamy local AI server, then try again.';
    }
    if (message.contains('Ollama returned HTTP')) {
      return '$message Make sure qwen3-vl:latest is installed by running "ollama list" on the laptop.';
    }
    if (message.contains('Local Qwen') ||
        message.contains('Connection refused') ||
        message.contains('laptop AI server') ||
        message.contains('Cloudflare Tunnel')) {
      return message;
    }
    if (message.isNotEmpty && message != 'Klamy did not return an answer.') {
      return message;
    }
    return 'Klamy could not reply this time. Please try again in a moment.';
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final bottom = _scrollController.position.maxScrollExtent;
        if (animate) {
          _scrollController.animateTo(
            bottom,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(bottom);
        }
      }
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    Get.snackbar(
      isError ? 'Could not complete action' : 'Claim Assistant',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError ? Colors.red.shade700 : _accent,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _vaultSubscription?.cancel();
    _skeletonController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.92,
        child: Container(
          padding: EdgeInsets.only(bottom: bottomInset),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F7F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: _accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Claim Assistant',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F2942),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    _buildClaimHeader(),
                    const SizedBox(height: 12),
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    _buildSuggestedDocuments(),
                    const SizedBox(height: 16),
                    _buildChat(),
                    const SizedBox(height: 10),
                    const Text(
                      'AI suggestions are for guidance. Confirm document requirements with your insurer.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClaimHeader() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Row(
      children: [
        const Icon(Icons.description_outlined, color: _accent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (_claim['title'] ?? 'Health Claim').toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2942),
                ),
              ),
              Text(
                'Claim ${(_claim['id'] ?? '').toString()} • ${(_claim['insurer'] ?? '').toString()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => GrievanceDraftSheet.show(context, _claim),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          icon: const Icon(Icons.gavel_rounded, size: 14),
          label: const Text(
            'IRDAI Grievance',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );

  Widget _buildSummaryCard() => _sectionCard(
    title: 'Klamy claim summary',
    icon: Icons.summarize_outlined,
    trailing: IconButton(
      tooltip: 'Refresh summary',
      onPressed: _loadingReview ? null : () => _loadReview(refresh: true),
      icon: const Icon(Icons.refresh_rounded, size: 20),
    ),
    child: _loadingReview
        ? _buildSummarySkeleton()
        : _reviewError != null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Klamy could not prepare the summary. $_reviewError',
                style: const TextStyle(fontSize: 13, color: Color(0xFFB91C1C)),
              ),
              TextButton.icon(
                onPressed: () => _loadReview(refresh: true),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _summary,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: Color(0xFF334155),
                ),
              ),
              if (_analyzedDocumentNames.isNotEmpty) ...[
                const SizedBox(height: 9),
                Text(
                  'Reviewed: ${_analyzedDocumentNames.join(', ')}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF16845B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (_unavailableDocumentNames.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Could not read: ${_unavailableDocumentNames.join(', ')}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB45309),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
  );

  Widget _buildSummarySkeleton() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: FadeTransition(
      opacity: _skeletonPulse,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summarySkeletonLine(0.96),
          const SizedBox(height: 9),
          _summarySkeletonLine(1),
          const SizedBox(height: 9),
          _summarySkeletonLine(0.88),
          const SizedBox(height: 9),
          _summarySkeletonLine(0.61),
        ],
      ),
    ),
  );

  Widget _summarySkeletonLine(double widthFactor) => FractionallySizedBox(
    widthFactor: widthFactor,
    alignment: Alignment.centerLeft,
    child: Container(
      height: 9,
      decoration: BoxDecoration(
        color: const Color(0xFFD8E1E9),
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );

  Widget _buildSuggestedDocuments() => _sectionCard(
    title: 'Suggested documents',
    icon: Icons.upload_file_outlined,
    child: _loadingReview
        ? const LinearProgressIndicator(color: _accent)
        : _reviewError != null
        ? const Text(
            'Suggestions will appear when Klamy is available.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          )
        : _suggestions.isEmpty
        ? const Text(
            'No additional documents suggested.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          )
        : Column(children: _suggestions.map(_buildSuggestionCard).toList()),
  );

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion) {
    final category = (suggestion['category'] ?? '').toString();
    final title = (suggestion['title'] ?? _categoryName(category)).toString();
    final uploaded = _uploadedCategories.contains(category);
    final isUploading = _uploadingCategory == category;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: _accent, size: 21),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F2942),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  (suggestion['reason'] ?? '').toString(),
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.3,
                    color: Color(0xFF64748B),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    uploaded
                        ? 'Uploaded in Documents Vault'
                        : 'Missing from Documents Vault',
                    style: TextStyle(
                      fontSize: 10,
                      color: uploaded
                          ? const Color(0xFF16845B)
                          : const Color(0xFFDC2626),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton.filledTonal(
            tooltip: uploaded ? 'Upload another file' : 'Upload document',
            onPressed: isUploading ? null : () => _uploadForCategory(category),
            icon: isUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(uploaded ? Icons.add_rounded : Icons.upload_rounded),
            style: IconButton.styleFrom(
              foregroundColor: _accent,
              backgroundColor: const Color(0xFFE6F7F5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChat() => _sectionCard(
    title: 'Ask Klamy',
    icon: Icons.chat_bubble_outline_rounded,
    child: _loadingChat
        ? Column(
            children: [
              _buildChatSkeleton(fromUser: true, lineWidths: const [150, 92]),
              const SizedBox(height: 8),
              _buildChatSkeleton(
                fromUser: false,
                lineWidths: const [196, 164, 112],
              ),
            ],
          )
        : _messages.isEmpty
        ? const Text(
            'Ask about this claim or the suggested documents.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          )
        : Column(
            children: [
              ..._messages
                  .where((message) => message.text.trim().isNotEmpty)
                  .map(_buildChatBubble),
              if (_sendingMessage && _waitingForFirstChunk) ...[
                const SizedBox(height: 4),
                _buildTypingSkeleton(),
              ],
            ],
          ),
  );

  Widget _buildChatSkeleton({
    required bool fromUser,
    required List<double> lineWidths,
  }) => Align(
    alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
    child: FadeTransition(
      opacity: _skeletonPulse,
      child: Container(
        width: 238,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: fromUser ? const Color(0xFFE6F7F5) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < lineWidths.length; index++) ...[
              if (index > 0) const SizedBox(height: 7),
              Container(
                width: lineWidths[index],
                height: 9,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8E1E9),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _buildTypingSkeleton() => Align(
    alignment: Alignment.centerLeft,
    child: FadeTransition(
      opacity: _skeletonPulse,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < 3; index++) ...[
              if (index > 0) const SizedBox(width: 5),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF94A3B8),
                  shape: BoxShape.circle,
                ),
              ),
            ],
            const SizedBox(width: 8),
            Text(
              'klamy_analyzing'.tr,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildChatBubble(_ChatMessage message) => Align(
    alignment: message.fromUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 290),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: message.fromUser
            ? const Color(0xFFE6F7F5)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        message.text,
        style: const TextStyle(
          fontSize: 12,
          height: 1.35,
          color: Color(0xFF334155),
        ),
      ),
    ),
  );

  Widget _buildMessageInput() => Container(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
    ),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _messageController,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendMessage(),
            decoration: InputDecoration(
              hintText: 'Ask about this claim...',
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: _sendingMessage || _loadingChat ? null : _sendMessage,
          icon: const Icon(Icons.send_rounded, size: 19),
          style: IconButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _accent, size: 19),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2942),
                ),
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );

  String _categoryName(String category) => switch (category) {
    'policy' => 'Policy Document',
    'hospital_bills' => 'Hospital Bills',
    'discharge_summary' => 'Discharge Summary',
    'prescription' => 'Prescription',
    'medical_reports' => 'Medical Reports',
    'insurer_letters' => 'Insurer Letters',
    _ => 'Claim Document',
  };
}

class _ChatMessage {
  String text;
  final bool fromUser;

  _ChatMessage({required this.text, this.fromUser = false});
}
