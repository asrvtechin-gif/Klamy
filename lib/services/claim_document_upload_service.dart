import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ClaimDocumentUpload {
  final String fileName;
  final String category;
  final String storageKey;
  final String documentUrl;
  final String recordId;

  const ClaimDocumentUpload({
    required this.fileName,
    required this.category,
    required this.storageKey,
    this.documentUrl = '',
    this.recordId = '',
  });

  ClaimDocumentUpload withRecordId(String id) => ClaimDocumentUpload(
    fileName: fileName,
    category: category,
    storageKey: storageKey,
    documentUrl: documentUrl,
    recordId: id,
  );

  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'category': category,
    'storageKey': storageKey,
    'documentUrl': documentUrl,
    if (recordId.isNotEmpty) 'recordId': recordId,
  };
}

class ClaimDocumentUploadService extends GetxService {
  static const String cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'n8u6logx',
  );
  static const String uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'klamy5',
  );
  static bool get isConfigured =>
      cloudName.isNotEmpty && uploadPreset.isNotEmpty;

  Future<ClaimDocumentUpload> upload({
    required String fileName,
    required List<int> bytes,
    required String category,
  }) async {
    if (!isConfigured) {
      throw StateError(
        'Cloudinary is not configured. Set CLOUDINARY_CLOUD_NAME and '
        'CLOUDINARY_UPLOAD_PRESET when starting the app.',
      );
    }
    if (bytes.isEmpty) throw StateError('The selected document is empty.');

    final uri = Uri.https('api.cloudinary.com', '/v1_1/$cloudName/auto/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = 'klamy/claims'
      ..fields['context'] = 'document_type=$category'
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

    late final http.Response response;
    try {
      final streamed = await request.send().timeout(const Duration(minutes: 3));
      response = await http.Response.fromStream(streamed);
    } on http.ClientException catch (error) {
      throw StateError('Could not reach Cloudinary: ${error.message}');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw FormatException(
        'Cloudinary returned a non-JSON response (${response.statusCode}).',
      );
    }
    if (decoded is! Map) {
      throw const FormatException('Cloudinary returned an invalid response.');
    }
    final body = Map<String, dynamic>.from(decoded);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = body['error'] is Map
          ? (body['error'] as Map)['message']
          : body['error'];
      if (error != null &&
          error.toString().toLowerCase().contains('upload preset not found')) {
        throw StateError(
          'Cloudinary preset "$uploadPreset" was not found for this cloud. '
          'Create an unsigned upload preset with this exact name in the same Cloudinary account.',
        );
      }
      throw StateError(
        'Cloudinary upload failed (${response.statusCode})'
        '${error == null ? '.' : ': $error'}',
      );
    }

    final publicId = (body['public_id'] ?? '').toString();
    if (publicId.isEmpty) {
      throw const FormatException(
        'Cloudinary response did not include public_id.',
      );
    }

    return ClaimDocumentUpload(
      fileName: fileName,
      category: category,
      storageKey: publicId,
      documentUrl: (body['secure_url'] ?? '').toString(),
    );
  }
}
