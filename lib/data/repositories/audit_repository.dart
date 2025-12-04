import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:tiffin_mate/data/models/audit_log.dart';

class AuditRepository {
  final FirebaseFirestore _firestore;
  final Box<AuditLog>? _auditBox;

  AuditRepository({FirebaseFirestore? firestore, Box<AuditLog>? auditBox})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auditBox = auditBox;

  Future<void> logAction(AuditLog log) async {
    // Write to Firestore
    try {
      await _firestore.collection('audit_logs').doc(log.id).set(log.toMap());
    } catch (e) {
      // If offline or error, we might want to queue it locally.
      // For now, we'll just try to save to Hive if available for local history
      // but the primary source of truth for audit logs is Firestore.
      print('Error writing audit log to Firestore: $e');
    }

    // Save locally for admin viewing if needed (optional, depending on requirements)
    if (_auditBox != null) {
      await _auditBox.put(log.id, log);
    }
  }

  Future<List<AuditLog>> getAuditLogs({
    String? adminId,
    String? targetUserId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    Query query = _firestore.collection('audit_logs');

    if (adminId != null) {
      query = query.where('adminId', isEqualTo: adminId);
    }
    if (targetUserId != null) {
      query = query.where('targetUserId', isEqualTo: targetUserId);
    }
    if (startDate != null) {
      query = query.where(
        'timestamp',
        isGreaterThanOrEqualTo: startDate.toIso8601String(),
      );
    }
    if (endDate != null) {
      query = query.where(
        'timestamp',
        isLessThanOrEqualTo: endDate.toIso8601String(),
      );
    }

    query = query.orderBy('timestamp', descending: true).limit(limit);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => AuditLog.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }
}
