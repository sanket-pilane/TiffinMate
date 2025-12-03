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

    _userBox = await Hive.openBox<UserProfile>(_userBoxName);
    _tiffinBox = await Hive.openBox<TiffinEntry>(_tiffinBoxName);

    if (_userBox.isEmpty) {
      await _userBox.put('profile', UserProfile(defaultTiffinPrice: 0.0));
    }

    // Attempt sync on startup if user is logged in
    if (_userId != null) {
      syncLocalToCloud();
    }
  }

  // --- Auth Methods ---

  @override
  Future<UserCredential> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    // After login, try to sync
    syncLocalToCloud();
    return credential;
  }

  @override
  Future<UserCredential> signUp(
    String email,
    String password,
    String name,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Save initial profile to local Hive
    final profile = UserProfile(name: name, defaultTiffinPrice: 0.0);
    await saveUserProfile(profile);

    return credential;
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    // Optional: Clear local data on logout if you want privacy
    // await _tiffinBox.clear();
    // await _userBox.clear();
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
}
