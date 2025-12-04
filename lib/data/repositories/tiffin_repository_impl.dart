import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tiffin_mate/data/models/tiffin_entry.dart';
import 'package:tiffin_mate/data/models/user_profile.dart';
import 'package:tiffin_mate/data/repositories/tiffin_repository.dart';

class TiffinRepositoryImpl implements TiffinRepository {
  static const String _userBoxName = 'userProfileBox';
  static const String _tiffinBoxName = 'tiffinEntriesBox';

  late Box<UserProfile> _userBox;
  late Box<TiffinEntry> _tiffinBox;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(dir.path);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserProfileAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TiffinEntryAdapter());
    }

    // If user is already logged in, open their boxes
    if (_userId != null) {
      await initUserData();
    }
  }

  @override
  Future<void> initUserData() async {
    if (_userId == null) return;

    // If boxes are already open and for the correct user (we assume _userId doesn't change without signOut), return.
    // But to be safe, we can check box names or just reopen (Hive handles this).
    // However, Hive.openBox is idempotent.

    _userBox = await Hive.openBox<UserProfile>('${_userBoxName}_$_userId');
    _tiffinBox = await Hive.openBox<TiffinEntry>('${_tiffinBoxName}_$_userId');

    if (_userBox.isEmpty) {
      await _userBox.put('profile', UserProfile(defaultTiffinPrice: 0.0));
    }

    // Sync profile immediately on startup/init
    await syncUserProfileFromCloud();
    syncLocalToCloud();
  }

  // --- Auth Methods ---

  @override
  Future<UserCredential> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Initialize user-specific boxes
    if (credential.user != null) {
      await initUserData();
    }

    return credential;
  }

  @override
  Future<UserCredential> signUp(
    String email,
    String password,
    String name, {
    String? vendorId,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user != null) {
      await initUserData();

      // Save initial profile to local Hive
      final profile = UserProfile(
        name: name,
        defaultTiffinPrice: 0.0,
        vendorId: vendorId,
      );
      await saveUserProfile(profile);
    }

    return credential;
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    // Close boxes to ensure data isolation
    if (Hive.isBoxOpen(_userBox.name)) await _userBox.close();
    if (Hive.isBoxOpen(_tiffinBox.name)) await _tiffinBox.close();
  }

  // --- Data Methods ---

  @override
  Future<UserProfile> getUserProfile() async {
    return _userBox.get('profile')!;
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    await _userBox.put('profile', profile);
    // Sync profile to cloud (Optional)
    if (_userId != null) {
      await _firestore.collection('users').doc(_userId).set({
        'name': profile.name,
        'defaultPrice': profile.defaultTiffinPrice,
        'vendorId': profile.vendorId,
      }, SetOptions(merge: true));
    }
  }

  @override
  Future<void> addTiffinEntry(TiffinEntry entry) async {
    await _tiffinBox.put(entry.id, entry);
    _trySyncSingleEntry(entry);
  }

  @override
  Future<List<TiffinEntry>> getAllLocalTiffins() async {
    final tiffins = _tiffinBox.values.toList();
    tiffins.sort((a, b) => b.date.compareTo(a.date));
    return tiffins;
  }

  @override
  Future<void> deleteTiffinEntry(String id) async {
    await _tiffinBox.delete(id);
    if (_userId != null) {
      try {
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('tiffins')
            .doc(id)
            .delete();
      } catch (e) {
        print("Cloud delete failed: $e");
      }
    }
  }

  // --- Synchronization Logic ---

  Future<void> _trySyncSingleEntry(TiffinEntry entry) async {
    if (_userId == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('tiffins')
          .doc(entry.id)
          .set(entry.toMap());
      entry.isSynced = true;
      await entry.save();
    } catch (e) {
      print("Offline: Data saved locally only.");
    }
  }

  @override
  Future<void> syncLocalToCloud() async {
    if (_userId == null) return;

    final unsyncedEntries = _tiffinBox.values
        .where((e) => !e.isSynced)
        .toList();
    if (unsyncedEntries.isEmpty) return;

    print("Syncing ${unsyncedEntries.length} items to cloud...");

    for (var entry in unsyncedEntries) {
      try {
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('tiffins')
            .doc(entry.id)
            .set(entry.toMap());

        entry.isSynced = true;
        await entry.save();
      } catch (e) {
        print("Sync failed for ${entry.id}: $e");
        break;
      }
    }
  }

  @override
  Future<void> syncUserProfileFromCloud() async {
    if (_userId == null) return;

    try {
      final doc = await _firestore.collection('users').doc(_userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final currentProfile = _userBox.get('profile')!;

        final updatedProfile = currentProfile.copyWith(
          name: data['name'] as String?,
          defaultTiffinPrice: (data['defaultPrice'] as num?)?.toDouble(),
          role: data['role'] as String?,
          vendorId: data['vendorId'] as String?,
        );

        await _userBox.put('profile', updatedProfile);
      }
    } catch (e) {
      print("Profile sync failed: $e");
    }
  }
}
