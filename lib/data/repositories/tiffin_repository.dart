import 'package:firebase_auth/firebase_auth.dart';
import 'package:tiffin_mate/data/models/tiffin_entry.dart';
import 'package:tiffin_mate/data/models/user_profile.dart';

abstract class TiffinRepository {
  Future<void> initialize();
  Future<void> initUserData();

  // Auth Methods
  Stream<User?> get authStateChanges;
  Future<UserCredential> signIn(String email, String password);
  Future<UserCredential> signUp(
    String email,
    String password,
    String name, {
    String? vendorId,
  });
  Future<void> signOut();

  // Data Methods
  Future<UserProfile> getUserProfile();
  Future<void> saveUserProfile(UserProfile profile);
  Future<void> addTiffinEntry(TiffinEntry entry);
  Future<List<TiffinEntry>> getAllLocalTiffins();
  Future<void> deleteTiffinEntry(String id);
  Future<void> syncLocalToCloud();
  Future<void> syncUserProfileFromCloud();
}
