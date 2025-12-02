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
  }

  @override
  Future<UserProfile> getUserProfile() async {
    return _userBox.get('profile')!;
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    await _userBox.put('profile', profile);
  }

  @override
  Future<void> addTiffinEntry(TiffinEntry entry) async {
    await _tiffinBox.put(entry.id, entry);
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
  }
}
