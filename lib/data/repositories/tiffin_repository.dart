import 'package:tiffin_mate/data/models/tiffin_entry.dart';
import 'package:tiffin_mate/data/models/user_profile.dart';

abstract class TiffinRepository {
  Future<void> initialize();
  Future<UserProfile> getUserProfile();
  Future<void> saveUserProfile(UserProfile profile);
  Future<void> addTiffinEntry(TiffinEntry entry);
  Future<List<TiffinEntry>> getAllLocalTiffins();
  Future<void> deleteTiffinEntry(String id);
}
