import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tiffin_mate/data/models/dispute_item.dart';
import 'package:tiffin_mate/data/models/tiffin_entry.dart';
import 'package:tiffin_mate/data/models/user_profile.dart';
import 'package:tiffin_mate/data/repositories/admin_repository.dart';
import 'package:tiffin_mate/data/repositories/audit_repository.dart';
import 'package:tiffin_mate/data/models/audit_log.dart';
import 'package:uuid/uuid.dart';

class AdminRepositoryImpl implements AdminRepository {
  final FirebaseFirestore _firestore;
  final AuditRepository _auditRepository;

  AdminRepositoryImpl({
    FirebaseFirestore? firestore,
    required AuditRepository auditRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auditRepository = auditRepository;

  @override
  Future<List<UserProfile>> getAllUsers() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    // Get Admin's Vendor ID
    final adminDoc = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final adminVendorId = adminDoc.data()?['vendorId'] as String?;

    Query query = _firestore.collection('users');

    // If admin has a vendorId, filter by it
    if (adminVendorId != null && adminVendorId.isNotEmpty) {
      query = query.where('vendorId', isEqualTo: adminVendorId);
    }

    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return UserProfile(
            id: doc.id,
            name: data['name'] ?? 'Unknown',
            defaultTiffinPrice:
                (data['defaultPrice'] as num?)?.toDouble() ?? 0.0,
            role: data['role'] ?? 'user',
            vendorId: data['vendorId'] as String?,
          );
        })
        .where((user) => user.id != currentUser.uid) // Filter out self
        .toList();
  }

  @override
  Future<void> addTiffinEntryForUser(String userId, TiffinEntry entry) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tiffins')
        .doc(entry.id)
        .set(entry.toMap());

    // Audit Log
    final auditLog = AuditLog(
      id: const Uuid().v4(),
      adminId: 'current_admin_id', // TODO: Get actual admin ID
      actionType: 'admin_add_entry',
      entryId: entry.id,
      targetUserId: userId,
      timestamp: DateTime.now(),
      meta: entry.toMap(),
    );
    await _auditRepository.logAction(auditLog);
  }

  @override
  Future<void> bulkAddTiffinEntries(
    List<String> userIds,
    TiffinEntry entryTemplate,
  ) async {
    final batch = _firestore.batch();
    final auditLogs = <AuditLog>[];

    for (final userId in userIds) {
      final entryId = const Uuid().v4();
      final entry = entryTemplate.copyWith(id: entryId);
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('tiffins')
          .doc(entryId);

      batch.set(docRef, entry.toMap());

      auditLogs.add(
        AuditLog(
          id: const Uuid().v4(),
          adminId: 'current_admin_id', // TODO: Get actual admin ID
          actionType: 'bulk_add_entry',
          entryId: entryId,
          targetUserId: userId,
          timestamp: DateTime.now(),
          meta: entry.toMap(),
        ),
      );
    }

    await batch.commit();

    for (final log in auditLogs) {
      await _auditRepository.logAction(log);
    }
  }

  @override
  Future<List<DisputeItem>> getDisputedEntries() async {
    // This is a bit complex because disputes are scattered across user subcollections.
    // A collection group query is best here.
    // Ensure 'tiffins' collection group index exists in Firestore.
    final snapshot = await _firestore
        .collectionGroup('tiffins')
        .where('status', isEqualTo: 'disputed')
        .get();

    return snapshot.docs.map((doc) {
      // doc.reference.parent is the collection 'tiffins'
      // doc.reference.parent.parent is the document 'users/{userId}'
      final userDocRef = doc.reference.parent.parent;
      final userId = userDocRef?.id ?? 'unknown';

      return DisputeItem(
        userId: userId,
        entry: TiffinEntry.fromMap(doc.data()),
      );
    }).toList();
  }

  @override
  Future<void> resolveDispute(String userId, TiffinEntry entry) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tiffins')
        .doc(entry.id)
        .set(entry.toMap());

    final auditLog = AuditLog(
      id: const Uuid().v4(),
      adminId: 'current_admin_id', // TODO: Get actual admin ID
      actionType: 'resolve_dispute',
      entryId: entry.id,
      targetUserId: userId,
      timestamp: DateTime.now(),
      meta: entry.toMap(),
    );
    await _auditRepository.logAction(auditLog);
  }
}
