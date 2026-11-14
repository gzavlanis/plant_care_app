// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get appTitle => 'Plant Tracker';

  @override
  String get myPlants => 'Τα Φυτά μου';

  @override
  String get searchHint => 'Αναζήτηση με όνομα ή είδος...';

  @override
  String get filterAll => 'Όλα';

  @override
  String get filterThirsty => 'Διψασμένα 💧';

  @override
  String get filterOk => 'Εντάξει 🌿';

  @override
  String get noPlantsFound => 'Δεν βρέθηκαν φυτά.';

  @override
  String get newPlant => 'Νέο Φυτό';

  @override
  String get editPlant => 'Επεξεργασία Φυτού';

  @override
  String get addPlant => 'Προσθήκη Φυτού';

  @override
  String get savePlant => 'Αποθήκευση Φυτού';

  @override
  String get updatePlant => 'Ενημέρωση Φυτού';

  @override
  String get deletePlant => 'Διαγραφή Φυτού';

  @override
  String confirmDelete(String name) {
    return 'Θέλεις σίγουρα να διαγράψεις το φυτό \"$name\";';
  }

  @override
  String get cancel => 'Άκυρο';

  @override
  String get delete => 'Διαγραφή';

  @override
  String get water => 'Πότισμα';

  @override
  String get undo => 'ΑΝΑΙΡΕΣΗ';

  @override
  String plantWatered(String name) {
    return 'Το φυτό \"$name\" ποτίστηκε! 💧';
  }

  @override
  String get needsWater => 'Χρειάζεται πότισμα!';

  @override
  String nextWateringIn(int days) {
    return 'Επόμενο σε $days μέρες';
  }

  @override
  String get navPlants => 'Φυτά';

  @override
  String get navStats => 'Στατιστικά';

  @override
  String get sortNeedsWater => 'Πιο διψασμένα πρώτα';

  @override
  String get sortName => 'Αλφαβητικά (Α-Ω)';

  @override
  String get sortRecent => 'Πρόσφατα ποτισμένα';

  @override
  String get statsTitle => 'Στατιστικά Φροντίδας';

  @override
  String get statsTotal => 'Σύνολο';

  @override
  String get statsThirsty => 'Διψασμένα';

  @override
  String get statsAvgInterval => 'Μ.Ο. Συχνότητας';

  @override
  String get hydrationState => 'Κατάσταση Ενυδάτωσης';

  @override
  String get plantsByLocation => 'Φυτά ανά Χώρο';

  @override
  String get locBalconySouth => 'Νότιο Μπαλκόνι';

  @override
  String get locBalconyNorth => 'Βόρειο Μπαλκόνι';

  @override
  String get locLivingRoom => 'Σαλόνι';

  @override
  String get locOffice => 'Γραφείο';

  @override
  String get locBedroom => 'Υπνοδωμάτιο';

  @override
  String get locGarden => 'Κήπος';

  @override
  String get plantHelichrysum => 'Ελίχρυσος';

  @override
  String get plantBlackPine => 'Μαύρη Πεύκη';

  @override
  String get navCalendar => 'Ημερολόγιο';

  @override
  String get calendarTitle => 'Ημερολόγιο Ποτίσματος';

  @override
  String get calendarWatered => 'Ποτίστηκε';

  @override
  String get calendarDue => 'Θέλει πότισμα';

  @override
  String get calendarUpcoming => 'Προγραμματισμένο';

  @override
  String get calendarNoEvents => 'Κανένα πότισμα για αυτή την ημέρα.';

  @override
  String get calendarToday => 'Σήμερα';
}
