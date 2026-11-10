import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plant.dart';

class PlantStorageService {
  static const String _storageKey = 'saved_plants_list';

  Future<List<Plant>> loadPlants() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decodedList = json.decode(jsonString);
      return decodedList
          .map((item) => Plant.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> savePlants(List<Plant> plants) async {
    final prefs = await SharedPreferences.getInstance();
    final listMaps = plants.map((p) => p.toMap()).toList();
    final jsonString = json.encode(listMaps);
    await prefs.setString(_storageKey, jsonString);
  }
}