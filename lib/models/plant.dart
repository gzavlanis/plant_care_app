import 'dart:convert';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

// Enum για τους διαθέσιμους χώρους με όνομα και εικονίδιο
enum PlantLocation {
  balconySouth('Νότιο Μπαλκόνι', Icons.wb_sunny_outlined),
  balconyNorth('Βόρειο Μπαλκόνι', Icons.cloud_outlined),
  livingRoom('Σαλόνι', Icons.weekend_outlined),
  office('Γραφείο', Icons.desk_outlined),
  bedroom('Υπνοδωμάτιο', Icons.bed_outlined),
  garden('Κήπος', Icons.yard_outlined);

  final String label;
  final IconData icon;

  const PlantLocation(this.label, this.icon);

  // Δυναμική μετάφραση βάσει του ενεργού Locale
  String localizedLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return label;

    switch (this) {
      case PlantLocation.balconySouth:
        return l10n.locBalconySouth;
      case PlantLocation.balconyNorth:
        return l10n.locBalconyNorth;
      case PlantLocation.livingRoom:
        return l10n.locLivingRoom;
      case PlantLocation.office:
        return l10n.locOffice;
      case PlantLocation.bedroom:
        return l10n.locBedroom;
      case PlantLocation.garden:
        return l10n.locGarden;
    }
  }
}

class Plant {
  final String id;
  final String name;
  final String species;
  final int wateringIntervalDays;
  final DateTime lastWatered;
  final String? imageUrl;
  final List<DateTime> wateringHistory;
  final PlantLocation location; // Νέο πεδίο: Τοποθεσία/Χώρος

  const Plant({
    required this.id,
    required this.name,
    required this.species,
    required this.wateringIntervalDays,
    required this.lastWatered,
    this.imageUrl,
    this.wateringHistory = const [],
    this.location = PlantLocation.balconySouth,
  });

  bool get needsWater {
    final nextWateringDate = lastWatered.add(
      Duration(days: wateringIntervalDays),
    );
    return DateTime.now().isAfter(nextWateringDate);
  }

  int get daysUntilWatering {
    final nextWateringDate = lastWatered.add(
      Duration(days: wateringIntervalDays),
    );
    final difference = nextWateringDate.difference(DateTime.now()).inDays;
    return difference < 0 ? 0 : difference;
  }

  double get hydrationLevel {
    final totalDuration = Duration(days: wateringIntervalDays).inSeconds;
    if (totalDuration == 0) return 0.0;

    final elapsed = DateTime.now().difference(lastWatered).inSeconds;
    final remaining = totalDuration - elapsed;

    if (remaining <= 0) return 0.0;
    final ratio = remaining / totalDuration;
    return ratio.clamp(0.0, 1.0);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'wateringIntervalDays': wateringIntervalDays,
      'lastWatered': lastWatered.toIso8601String(),
      'imageUrl': imageUrl,
      'wateringHistory': wateringHistory
          .map((d) => d.toIso8601String())
          .toList(),
      'location': location.name,
    };
  }

  String localizedName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return name;

    switch (id) {
      case '1':
        return l10n.plantHelichrysum;
      case '2':
        return l10n.plantBlackPine;
      default:
        return name;
    }
  }

  factory Plant.fromMap(Map<String, dynamic> map) {
    // Ασφαλής ανάκτηση location με fallback σε περίπτωση παλαιότερων δεδομένων
    PlantLocation parsedLocation = PlantLocation.balconySouth;
    if (map['location'] != null) {
      parsedLocation = PlantLocation.values.firstWhere(
        (loc) => loc.name == map['location'],
        orElse: () => PlantLocation.balconySouth,
      );
    }

    return Plant(
      id: map['id'] as String,
      name: map['name'] as String,
      species: map['species'] as String,
      wateringIntervalDays: map['wateringIntervalDays'] as int,
      lastWatered: DateTime.parse(map['lastWatered'] as String),
      imageUrl: map['imageUrl'] as String?,
      wateringHistory: map['wateringHistory'] != null
          ? (map['wateringHistory'] as List<dynamic>)
                .map((d) => DateTime.parse(d as String))
                .toList()
          : [],
      location: parsedLocation,
    );
  }

  String toJson() => json.encode(toMap());

  factory Plant.fromJson(String source) =>
      Plant.fromMap(json.decode(source) as Map<String, dynamic>);
}
