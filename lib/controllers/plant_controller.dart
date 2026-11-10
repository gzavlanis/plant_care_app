// lib/controllers/plant_controller.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/plant.dart';
import '../services/notification_service.dart';
import '../services/plant_storage_service.dart';

final storageServiceProvider = Provider<PlantStorageService>((ref) {
  return PlantStorageService();
});

// 1. Φίλτρα Κατάστασης
enum PlantFilter { all, needsWater, ok }

class PlantFilterNotifier extends Notifier<PlantFilter> {
  @override
  PlantFilter build() => PlantFilter.all;

  void setFilter(PlantFilter filter) => state = filter;
}

final plantFilterProvider = NotifierProvider<PlantFilterNotifier, PlantFilter>(
  PlantFilterNotifier.new,
);

// 2. Κριτήρια Ταξινόμησης (Sort)
enum PlantSort { needsWaterFirst, nameAsc, recentlyWatered }

class PlantSortNotifier extends Notifier<PlantSort> {
  @override
  PlantSort build() => PlantSort.needsWaterFirst;

  void setSort(PlantSort sort) => state = sort;
}

final plantSortProvider = NotifierProvider<PlantSortNotifier, PlantSort>(
  PlantSortNotifier.new,
);

// 3. Search Query Notifier
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

// 4. Plant List Notifier (CRUD & Persistence & Notifications)
class PlantNotifier extends Notifier<List<Plant>> {
  @override
  List<Plant> build() {
    _loadInitial();
    return [];
  }

  PlantStorageService get _storageService => ref.read(storageServiceProvider);

  Future<void> _loadInitial() async {
    final loaded = await _storageService.loadPlants();
    if (loaded.isNotEmpty) {
      state = loaded;
    } else {
      state = [
        Plant(
          id: '1',
          name: 'Ελίχρυσος',
          species: 'Helichrysum italicum',
          wateringIntervalDays: 4,
          lastWatered: DateTime.now().subtract(const Duration(days: 5)),
        ),
        Plant(
          id: '2',
          name: 'Μαύρη Πεύκη',
          species: 'Pinus nigra',
          wateringIntervalDays: 7,
          lastWatered: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];
      _storageService.savePlants(state);
      // Προγραμματισμός αρχικών ειδοποιήσεων
      for (final plant in state) {
        _scheduleNotificationForPlant(plant);
      }
    }
  }

  // Helper για μοναδικό int ID ειδοποίησης
  int _getNotificationId(String plantId) => plantId.hashCode.abs();

  // Helper για προγραμματισμό ειδοποίησης στις 09:00 π.μ. την ημέρα λήξης
  void _scheduleNotificationForPlant(Plant plant) {
    final nextWateringDate =
    plant.lastWatered.add(Duration(days: plant.wateringIntervalDays));

    final reminderDateTime = DateTime(
      nextWateringDate.year,
      nextWateringDate.month,
      nextWateringDate.day,
      9, // 09:00 π.μ.
      0,
    );

    NotificationService().schedulePlantWatering(
      notificationId: _getNotificationId(plant.id),
      plantName: plant.name,
      scheduledDate: reminderDateTime,
    );
  }

  void addPlant(Plant plant) {
    state = [...state, plant];
    _storageService.savePlants(state);
    _scheduleNotificationForPlant(plant);
  }

  void updatePlant(Plant updatedPlant) {
    state = [
      for (final plant in state)
        if (plant.id == updatedPlant.id) updatedPlant else plant,
    ];
    _storageService.savePlants(state);
    _scheduleNotificationForPlant(updatedPlant);
  }

  void deletePlant(String id) {
    NotificationService().cancelNotification(_getNotificationId(id));
    state = state.where((p) => p.id != id).toList();
    _storageService.savePlants(state);
  }

  void waterPlant(String id) {
    Plant? updated;
    state = [
      for (final plant in state)
        if (plant.id == id)
          updated = Plant(
            id: plant.id,
            name: plant.name,
            species: plant.species,
            wateringIntervalDays: plant.wateringIntervalDays,
            lastWatered: DateTime.now(),
            imageUrl: plant.imageUrl,
            wateringHistory: [plant.lastWatered, ...plant.wateringHistory],
            location: plant.location,
          )
        else
          plant,
    ];
    _storageService.savePlants(state);
    if (updated != null) {
      _scheduleNotificationForPlant(updated);
    }
  }

  void undoWatering(String id) {
    Plant? restored;
    state = [
      for (final plant in state)
        if (plant.id == id && plant.wateringHistory.isNotEmpty)
          restored = Plant(
            id: plant.id,
            name: plant.name,
            species: plant.species,
            wateringIntervalDays: plant.wateringIntervalDays,
            lastWatered: plant.wateringHistory.first,
            imageUrl: plant.imageUrl,
            wateringHistory: plant.wateringHistory.sublist(1),
            location: plant.location,
          )
        else
          plant,
    ];
    _storageService.savePlants(state);
    if (restored != null) {
      _scheduleNotificationForPlant(restored);
    }
  }
}

final plantListProvider = NotifierProvider<PlantNotifier, List<Plant>>(
  PlantNotifier.new,
);

// 5. Σύνθετος Computed Provider: Filter + Search + Sort
final filteredPlantsProvider = Provider<List<Plant>>((ref) {
  final plants = ref.watch(plantListProvider);
  final filter = ref.watch(plantFilterProvider);
  final sort = ref.watch(plantSortProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  // 1. Φιλτράρισμα βάσει κατάστασης
  var result = plants.where((p) {
    switch (filter) {
      case PlantFilter.needsWater:
        return p.needsWater;
      case PlantFilter.ok:
        return !p.needsWater;
      case PlantFilter.all:
        return true;
    }
  }).toList();

  // 2. Φιλτράρισμα βάσει Search Query
  if (query.isNotEmpty) {
    result = result.where((p) {
      final nameMatches = p.name.toLowerCase().contains(query);
      final speciesMatches = p.species.toLowerCase().contains(query);
      return nameMatches || speciesMatches;
    }).toList();
  }

  // 3. Ταξινόμηση (Sorting)
  switch (sort) {
    case PlantSort.needsWaterFirst:
      result.sort((a, b) => a.hydrationLevel.compareTo(b.hydrationLevel));
      break;
    case PlantSort.nameAsc:
      result.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      break;
    case PlantSort.recentlyWatered:
      result.sort((a, b) => b.lastWatered.compareTo(a.lastWatered));
      break;
  }

  return result;
});

// Theme Mode State Management
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _themePrefKey = 'user_theme_mode';

  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.system;
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_themePrefKey);
    if (savedMode != null) {
      state = ThemeMode.values.firstWhere(
            (m) => m.name == savedMode,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePrefKey, mode.name);
  }

  Future<void> toggleTheme() async {
    if (state == ThemeMode.dark) {
      await setTheme(ThemeMode.light);
    } else {
      await setTheme(ThemeMode.dark);
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

// Locale State Management (Εναλλαγή EL <-> EN)
class LocaleNotifier extends Notifier<Locale> {
  static const _localePrefKey = 'user_locale_code';

  @override
  Locale build() {
    _loadLocale();
    return const Locale('el'); // Προεπιλογή: Ελληνικά
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localePrefKey);
    if (code != null) {
      state = Locale(code);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localePrefKey, locale.languageCode);
  }

  Future<void> toggleLocale() async {
    if (state.languageCode == 'el') {
      await setLocale(const Locale('en'));
    } else {
      await setLocale(const Locale('el'));
    }
  }
}

final localeProvider =
NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);