import 'package:tiffin_mate/data/models/dispute_item.dart';
import 'package:tiffin_mate/data/models/tiffin_entry.dart';
import 'package:tiffin_mate/data/models/user_profile.dart';

abstract class AdminRepository {
  Future<List<UserProfile>> getAllUsers();
  Future<void> addTiffinEntryForUser(String userId, TiffinEntry entry);
  Future<void> bulkAddTiffinEntries(
    List<String> userIds,
    TiffinEntry entryTemplate,
  );
  Future<List<DisputeItem>> getDisputedEntries();
  Future<void> resolveDispute(String userId, TiffinEntry entry);
}
