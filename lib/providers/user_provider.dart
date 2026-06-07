import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../services/storage_service.dart';

class UserProvider extends ChangeNotifier {
  final StorageService _storage;
  UserProfile? _user;
  bool _darkMode = true;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  UserProvider(this._storage);

  UserProfile? get user => _user;
  bool get darkMode => _darkMode;

  Future<void> load() async {
    // Try local first for speed
    _user = await _storage.loadUser();

    // Then sync from Firestore if logged in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await syncFromFirestore(currentUser.uid);
    }

    _darkMode = _user?.darkMode ?? true;
    notifyListeners();
  }

  Future<void> syncFromFirestore(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        // Merge Firestore data into UserProfile
        _user = UserProfile.fromJson(data);
        await _storage.saveUser(_user!);
        _darkMode = _user!.darkMode;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Firestore Sync Error: $e");
    }
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    if (_user != null) {
      _user!.darkMode = value;
      await _storage.saveUser(_user!);

      // Update Firestore
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await _db.collection('users').doc(currentUser.uid).update({'darkMode': value});
      }
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
    final currentUser = FirebaseAuth.instance.currentUser;
    final id = currentUser?.uid ?? DateTime.now().microsecondsSinceEpoch.toString();

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
      registrationDate: _user?.registrationDate ?? DateTime.now(),
    );

    _darkMode = darkMode;
    await _storage.saveUser(_user!);

    // Sync to Firestore
    if (currentUser != null) {
      await _db.collection('users').doc(currentUser.uid).set(_user!.toJson(), SetOptions(merge: true));
    }

    notifyListeners();
  }
}
