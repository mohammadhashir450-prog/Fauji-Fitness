import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../models/weight_entry.dart';

class StorageService {
  const StorageService();

  static const _userKey = 'user_profile';
  static const _weightsKey = 'weight_entries';
  static const _geminiKey = 'gemini_api_key';

  Future<void> saveGeminiKey(String key) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_geminiKey, key);
  }

  Future<String?> loadGeminiKey() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_geminiKey);
  }

  Future<void> saveUser(UserProfile user) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<UserProfile?> loadUser() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_userKey);
    if (s == null) return null;
    return UserProfile.fromJson(jsonDecode(s) as Map<String, dynamic>);
  }

  Future<List<WeightEntry>> loadWeights() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_weightsKey);
    if (s == null) return [];
    final List<dynamic> arr = jsonDecode(s) as List<dynamic>;
    return arr
        .map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addWeight(WeightEntry entry) async {
    final sp = await SharedPreferences.getInstance();
    final list = await loadWeights();
    list.add(entry);
    await sp.setString(_weightsKey, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Future<void> clearAll() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_userKey);
    await sp.remove(_weightsKey);
  }
}
