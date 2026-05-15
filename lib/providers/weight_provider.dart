import 'package:flutter/foundation.dart';

import '../models/weight_entry.dart';
import '../services/storage_service.dart';

class WeightProvider extends ChangeNotifier {
  final StorageService _storage;
  List<WeightEntry> _entries = [];

  WeightProvider(this._storage);

  List<WeightEntry> get entries => List.unmodifiable(_entries);

  Future<void> load() async {
    _entries = await _storage.loadWeights();
    _entries.sort((a, b) => a.date.compareTo(b.date));
    notifyListeners();
  }

  Future<void> addWeight(double weightKg, {DateTime? date, String? note}) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final entry = WeightEntry(id: id, date: date ?? DateTime.now(), weightKg: weightKg, note: note);
    await _storage.addWeight(entry);
    _entries.add(entry);
    _entries.sort((a, b) => a.date.compareTo(b.date));
    notifyListeners();
  }
}
