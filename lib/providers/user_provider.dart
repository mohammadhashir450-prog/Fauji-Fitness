import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/storage_service.dart';

class UserProvider extends ChangeNotifier {
  final StorageService _storage;
  UserProfile? _user;
  bool _darkMode = true;

  UserProvider(this._storage);

  UserProfile? get user => _user;
  bool get darkMode => _darkMode;

  Future<void> load() async {
    _user = await _storage.loadUser();
    _darkMode = _user?.darkMode ?? true;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    if (_user != null) {
      _user!.darkMode = value;
      await _storage.saveUser(_user!);
    }
    notifyListeners();
  }

  Future<void> createOrUpdate({
    required String name,
    DateTime? dob,
    String sex = 'male',
    double? heightCm,
    Goal goal = Goal.maintain,
    MembershipType membershipType = MembershipType.basic,
    MemberCategory? memberCategory,
    bool darkMode = true,
    String? trainerName,
  }) async {
    if (_user == null) {
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      _user = UserProfile(
        id: id,
        name: name,
        dob: dob,
        sex: sex,
        heightCm: heightCm,
        goal: goal,
        membershipType: membershipType,
        memberCategory: memberCategory,
        darkMode: darkMode,
        trainerName: trainerName,
        registrationDate: DateTime.now(),
      );
    } else {
      _user!.name = name;
      _user!.dob = dob;
      _user!.sex = sex;
      _user!.heightCm = heightCm;
      _user!.goal = goal;
      _user!.membershipType = membershipType;
      _user!.memberCategory = memberCategory;
      _user!.darkMode = darkMode;
      _user!.trainerName = trainerName;
    }
    _darkMode = darkMode;
    await _storage.saveUser(_user!);
    notifyListeners();
  }
}
