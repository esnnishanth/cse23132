import 'dart:async';

import 'package:flutter/material.dart';

import '../models/plant.dart';
import '../services/plant_repository.dart';
import '../services/reminder_service.dart';

class PlantData extends ChangeNotifier {
  PlantData({required PlantRepository repository, required ReminderService reminderService})
      : _repository = repository,
        _reminderService = reminderService {
    _subscription = _repository.watchPlants().listen(
      _onPlantsUpdated,
      onError: _onSyncError,
    );
  }

  final PlantRepository _repository;
  final ReminderService _reminderService;

  final List<Plant> _plants = <Plant>[];
  final List<String> _pendingReminders = <String>[];
  StreamSubscription<List<Plant>>? _subscription;

  String _searchQuery = '';
  String? _errorMessage;
  bool _isLoading = true;
  bool _isWriting = false;

  List<Plant> get plants {
    if (_searchQuery.isEmpty) {
      return List<Plant>.unmodifiable(_plants);
    }

    final String normalizedQuery = _searchQuery.toLowerCase();
    final List<Plant> filtered = _plants.where((Plant plant) {
      return plant.name.toLowerCase().contains(normalizedQuery) ||
          plant.type.toLowerCase().contains(normalizedQuery) ||
          plant.locationTag.toLowerCase().contains(normalizedQuery);
    }).toList(growable: false);

    return List<Plant>.unmodifiable(filtered);
  }

  bool get isLoading => _isLoading;
  bool get isWriting => _isWriting;
  String? get errorMessage => _errorMessage;

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  Plant? findById(String plantId) {
    for (final Plant plant in _plants) {
      if (plant.id == plantId) {
        return plant;
      }
    }
    return null;
  }

  String generatePlantId() {
    return _repository.newPlantId();
  }

  List<String> consumePendingReminders() {
    final List<String> messages = List<String>.from(_pendingReminders);
    _pendingReminders.clear();
    return messages;
  }

  Future<void> addPlant(Plant plant) async {
    await _runWrite(() => _repository.addPlant(plant));
  }

  Future<void> updatePlant(Plant plant) async {
    await _runWrite(() => _repository.updatePlant(plant));
  }

  Future<void> deletePlant(String plantId) async {
    await _runWrite(() => _repository.deletePlant(plantId));
  }

  Future<void> markPlantAsWatered(Plant plant) async {
    await _runWrite(
      () => _repository.updatePlant(
        plant.copyWith(lastWateredDate: DateTime.now()),
      ),
    );
  }

  Future<void> _runWrite(Future<void> Function() operation) async {
    _isWriting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await operation();
    } catch (error) {
      _errorMessage = 'Operation failed: $error';
      rethrow;
    } finally {
      _isWriting = false;
      notifyListeners();
    }
  }

  void _onPlantsUpdated(List<Plant> syncedPlants) {
    _plants
      ..clear()
      ..addAll(syncedPlants);

    _isLoading = false;
    _errorMessage = null;

    final List<String> newReminders =
      _reminderService.collectDueReminderMessages(_plants);
    _pendingReminders.addAll(newReminders);

    notifyListeners();
  }

  void _onSyncError(Object error, StackTrace stackTrace) {
    _isLoading = false;
    _errorMessage = 'Failed to sync plants: $error';
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
