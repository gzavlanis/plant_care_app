// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Plant Tracker';

  @override
  String get myPlants => 'My Plants';

  @override
  String get searchHint => 'Search by name or species...';

  @override
  String get filterAll => 'All';

  @override
  String get filterThirsty => 'Thirsty 💧';

  @override
  String get filterOk => 'Healthy 🌿';

  @override
  String get noPlantsFound => 'No plants found.';

  @override
  String get newPlant => 'New Plant';

  @override
  String get editPlant => 'Edit Plant';

  @override
  String get addPlant => 'Add Plant';

  @override
  String get savePlant => 'Save Plant';

  @override
  String get updatePlant => 'Update Plant';

  @override
  String get deletePlant => 'Delete Plant';

  @override
  String confirmDelete(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get water => 'Water';

  @override
  String get undo => 'UNDO';

  @override
  String plantWatered(String name) {
    return 'Plant \"$name\" was watered! 💧';
  }

  @override
  String get needsWater => 'Needs water!';

  @override
  String nextWateringIn(int days) {
    return 'Next watering in $days days';
  }

  @override
  String get navPlants => 'Plants';

  @override
  String get navStats => 'Statistics';

  @override
  String get sortNeedsWater => 'Most thirsty first';

  @override
  String get sortName => 'Alphabetical (A-Z)';

  @override
  String get sortRecent => 'Recently watered';

  @override
  String get statsTitle => 'Care Statistics';

  @override
  String get statsTotal => 'Total';

  @override
  String get statsThirsty => 'Thirsty';

  @override
  String get statsAvgInterval => 'Avg Interval';

  @override
  String get hydrationState => 'Hydration State';

  @override
  String get plantsByLocation => 'Plants by Location';

  @override
  String get locBalconySouth => 'South Balcony';

  @override
  String get locBalconyNorth => 'North Balcony';

  @override
  String get locLivingRoom => 'Living Room';

  @override
  String get locOffice => 'Office';

  @override
  String get locBedroom => 'Bedroom';

  @override
  String get locGarden => 'Garden';

  @override
  String get plantHelichrysum => 'Curry Plant';

  @override
  String get plantBlackPine => 'Black Pine';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get calendarTitle => 'Watering Calendar';

  @override
  String get calendarWatered => 'Watered';

  @override
  String get calendarDue => 'Needs water';

  @override
  String get calendarUpcoming => 'Scheduled';

  @override
  String get calendarNoEvents => 'No watering events for this day.';

  @override
  String get calendarToday => 'Today';
}
