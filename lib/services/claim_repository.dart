import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';

class ClaimRepository extends GetxService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Please sign in to continue.');
    return user.uid;
  }

  DatabaseReference get _claimsRef => _database.ref('users/$_userId/claims');
  DatabaseReference get _actionsRef => _database.ref('users/$_userId/actions');
  DatabaseReference get _documentsRef =>
      _database.ref('users/$_userId/documents');
  DatabaseReference get _notificationsRef =>
      _database.ref('users/$_userId/notifications');
  DatabaseReference get _fcmTokensRef =>
      _database.ref('users/$_userId/fcmTokens');

  Stream<List<Map<String, dynamic>>> watchClaims() =>
      _claimsRef.onValue.map((event) {
        final value = event.snapshot.value;
        if (value is! Map) return <Map<String, dynamic>>[];
        return value.entries.map((entry) {
          final record = entry.value is Map
              ? Map<String, dynamic>.from(entry.value as Map)
              : <String, dynamic>{};
          record['id'] = entry.key.toString();
          return record;
        }).toList()..sort(
          (a, b) => ((b['createdAt'] as num?) ?? 0).compareTo(
            (a['createdAt'] as num?) ?? 0,
          ),
        );
      });

  Stream<List<Map<String, dynamic>>> watchActions() =>
      _actionsRef.onValue.map((event) {
        final value = event.snapshot.value;
        if (value is! Map) return <Map<String, dynamic>>[];
        return value.entries.map((entry) {
          final record = entry.value is Map
              ? Map<String, dynamic>.from(entry.value as Map)
              : <String, dynamic>{};
          record['id'] = entry.key.toString();
          return record;
        }).toList()..sort(
          (a, b) => ((b['createdAt'] as num?) ?? 0).compareTo(
            (a['createdAt'] as num?) ?? 0,
          ),
        );
      });

  Stream<List<Map<String, dynamic>>> watchClaimComplaints() =>
      _database.ref('users/$_userId/complaints').onValue.map((event) {
        final value = event.snapshot.value;
        if (value is! Map) return <Map<String, dynamic>>[];
        return value.entries.map((entry) {
          final record = entry.value is Map
              ? Map<String, dynamic>.from(entry.value as Map)
              : <String, dynamic>{};
          record['id'] = entry.key.toString();
          return record;
        }).toList()..sort(
          (a, b) => ((b['createdAt'] as num?) ?? 0).compareTo(
            (a['createdAt'] as num?) ?? 0,
          ),
        );
      });

  Future<String> saveClaimComplaint({
    required String claimId,
    required String claimTitle,
    required String insurer,
    required String irdaToken,
  }) async {
    final ref = _database.ref('users/$_userId/complaints').push();
    final complaintId = ref.key;
    if (complaintId == null) {
      throw StateError('Could not create a complaint tracking record.');
    }
    await ref.set({
      'id': complaintId,
      'claimId': claimId,
      'claimTitle': claimTitle,
      'insurer': insurer,
      'irdaToken': irdaToken,
      'status': 'New',
      'createdAt': ServerValue.timestamp,
      'updatedAt': ServerValue.timestamp,
    });
    return complaintId;
  }

  Future<void> updateClaimComplaintStatus({
    required String complaintId,
    required String status,
  }) async {
    await _database.ref('users/$_userId/complaints/$complaintId').update({
      'status': status,
      'updatedAt': ServerValue.timestamp,
    });
  }

  Stream<List<Map<String, dynamic>>> watchNotifications() =>
      _notificationsRef.onValue.map((event) {
        final value = event.snapshot.value;
        if (value is! Map) return <Map<String, dynamic>>[];
        return value.entries.map((entry) {
          final record = entry.value is Map
              ? Map<String, dynamic>.from(entry.value as Map)
              : <String, dynamic>{};
          record['id'] = entry.key.toString();
          return record;
        }).toList()..sort(
          (a, b) => ((b['createdAt'] as num?) ?? 0).compareTo(
            (a['createdAt'] as num?) ?? 0,
          ),
        );
      });

  Future<String> saveNotification(Map<String, dynamic> notification) async {
    final ref = _notificationsRef.push();
    final id = ref.key;
    if (id == null) throw StateError('Could not create a notification ID.');
    await ref.set({
      ...notification,
      'id': id,
      'isRead': false,
      'createdAt': ServerValue.timestamp,
    });
    return id;
  }

  Future<void> markNotificationRead(String notificationId) =>
      _notificationsRef.child(notificationId).update({'isRead': true});

  Future<void> markAllNotificationsRead() async {
    final snapshot = await _notificationsRef.get();
    final value = snapshot.value;
    if (value is! Map || value.isEmpty) return;
    final updates = <String, Object?>{};
    for (final key in value.keys) {
      updates['$key/isRead'] = true;
    }
    await _notificationsRef.update(updates);
  }

  Future<void> deleteNotification(String notificationId) =>
      _notificationsRef.child(notificationId).remove();

  Future<void> clearNotifications() => _notificationsRef.remove();

  Future<void> saveFcmToken(String token) async {
    final tokenKey = base64Url.encode(utf8.encode(token)).replaceAll('=', '');
    await _fcmTokensRef.child(tokenKey).set({
      'token': token,
      'updatedAt': ServerValue.timestamp,
    });
  }

  Future<void> removeFcmToken(String token) async {
    final tokenKey = base64Url.encode(utf8.encode(token)).replaceAll('=', '');
    await _fcmTokensRef.child(tokenKey).remove();
  }

  Stream<List<Map<String, dynamic>>> watchDocuments() =>
      _documentsRef.onValue.map((event) {
        final value = event.snapshot.value;
        if (value is! Map) return <Map<String, dynamic>>[];
        return value.entries.map((entry) {
          final record = entry.value is Map
              ? Map<String, dynamic>.from(entry.value as Map)
              : <String, dynamic>{};
          record['id'] = entry.key.toString();
          return record;
        }).toList()..sort(
          (a, b) => ((b['uploadedAt'] as num?) ?? 0).compareTo(
            (a['uploadedAt'] as num?) ?? 0,
          ),
        );
      });

  Future<String> saveUploadedDocument(Map<String, dynamic> document) async {
    final ref = _documentsRef.push();
    final id = ref.key;
    if (id == null) throw StateError('Could not create a document ID.');
    await ref.set({
      ...document,
      'status': 'Uploaded',
      'uploadedAt': ServerValue.timestamp,
    });
    return id;
  }

  Future<void> attachUploadedDocumentToClaim({
    required String claimId,
    required String documentId,
    required Map<String, dynamic> document,
  }) async {
    final claimRef = _claimsRef.child(claimId);
    final snapshot = await claimRef.get();
    if (!snapshot.exists || snapshot.value is! Map) {
      throw StateError('The claim was not found.');
    }
    final claim = Map<String, dynamic>.from(snapshot.value as Map);
    final storedDocuments = claim['documents'];
    final storedDocumentValues = storedDocuments is List
        ? storedDocuments
        : storedDocuments is Map
        ? storedDocuments.values.toList()
        : const <dynamic>[];
    final documents = storedDocumentValues
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    if (!documents.any((item) => item['recordId'] == documentId)) {
      documents.add({...document, 'recordId': documentId});
    }
    await claimRef.update({
      'documents': documents,
      'docsCount': '${documents.length} / 6',
      'progress': _documentProgress(documents.length),
      'lastDocumentUploadedAt': ServerValue.timestamp,
      'updatedAt': ServerValue.timestamp,
    });
    await _documentsRef.child(documentId).update({'claimId': claimId});
  }

  double _documentProgress(int uploadedCount) =>
      (uploadedCount / 6).clamp(0.0, 1.0).toDouble();

  Future<void> saveClaimAiReview({
    required String claimId,
    required Map<String, dynamic> review,
  }) async {
    await _claimsRef.child(claimId).update({
      'aiReview': review,
      'aiReviewedAt': ServerValue.timestamp,
      'updatedAt': ServerValue.timestamp,
    });
  }

  Future<List<Map<String, dynamic>>> loadClaimChatHistory({
    required String claimId,
  }) async {
    final snapshot = await _claimsRef.child(claimId).child('chatHistory').get();
    final value = snapshot.value;
    if (value is! Map) return <Map<String, dynamic>>[];
    final messages =
        value.entries.where((entry) => entry.value is Map).map((entry) {
          final message = Map<String, dynamic>.from(entry.value as Map);
          message['id'] = entry.key.toString();
          return message;
        }).toList()..sort(
          (a, b) => ((a['createdAt'] as num?) ?? 0).compareTo(
            (b['createdAt'] as num?) ?? 0,
          ),
        );
    return messages;
  }

  Future<void> appendClaimChatMessage({
    required String claimId,
    required String role,
    required String text,
  }) async {
    final messageRef = _claimsRef.child(claimId).child('chatHistory').push();
    await messageRef.set({
      'role': role,
      'text': text,
      'createdAt': ServerValue.timestamp,
    });
  }

  Future<String> createClaim(Map<String, dynamic> claim) async {
    final claimRef = _claimsRef.push();
    final claimId = claimRef.key;
    if (claimId == null) throw StateError('Could not create a claim ID.');

    final now = ServerValue.timestamp;
    final updates = <String, Object?>{
      'users/$_userId/claims/$claimId': {
        ...claim,
        'id': claimId,
        'status': 'Submitted',
        'progress': _documentProgress(
          claim['documents'] is List ? (claim['documents'] as List).length : 0,
        ),
        'openActions': 0,
        'createdAt': now,
        'updatedAt': now,
      },
    };
    final documents = claim['documents'];
    if (documents is List) {
      for (final document in documents) {
        if (document is Map) {
          final recordId = document['recordId']?.toString() ?? '';
          if (recordId.isNotEmpty) {
            updates['users/$_userId/documents/$recordId/claimId'] = claimId;
          }
        }
      }
    }
    await _database.ref().update(updates);
    return claimId;
  }

  Future<void> setActionDone({
    required String actionId,
    required String claimId,
    required bool done,
  }) async {
    final updates = <String, Object?>{
      'users/$_userId/actions/$actionId/done': done,
      'users/$_userId/actions/$actionId/category': done
          ? 'Completed'
          : 'Upcoming',
      'users/$_userId/actions/$actionId/completedAt': done
          ? ServerValue.timestamp
          : null,
    };
    final claimSnapshot = await _claimsRef.child(claimId).get();
    if (claimSnapshot.exists) {
      updates['users/$_userId/claims/$claimId/openActions'] = done ? 0 : 1;
      updates['users/$_userId/claims/$claimId/updatedAt'] =
          ServerValue.timestamp;
    }
    await _database.ref().update(updates);
  }
}
