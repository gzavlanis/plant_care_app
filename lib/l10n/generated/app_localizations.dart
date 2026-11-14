import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_el.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('el'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In el, this message translates to:
  /// **'Plant Tracker'**
  String get appTitle;

  /// No description provided for @myPlants.
  ///
  /// In el, this message translates to:
  /// **'Τα Φυτά μου'**
  String get myPlants;

  /// No description provided for @searchHint.
  ///
  /// In el, this message translates to:
  /// **'Αναζήτηση με όνομα ή είδος...'**
  String get searchHint;

  /// No description provided for @filterAll.
  ///
  /// In el, this message translates to:
  /// **'Όλα'**
  String get filterAll;

  /// No description provided for @filterThirsty.
  ///
  /// In el, this message translates to:
  /// **'Διψασμένα 💧'**
  String get filterThirsty;

  /// No description provided for @filterOk.
  ///
  /// In el, this message translates to:
  /// **'Εντάξει 🌿'**
  String get filterOk;

  /// No description provided for @noPlantsFound.
  ///
  /// In el, this message translates to:
  /// **'Δεν βρέθηκαν φυτά.'**
  String get noPlantsFound;

  /// No description provided for @newPlant.
  ///
  /// In el, this message translates to:
  /// **'Νέο Φυτό'**
  String get newPlant;

  /// No description provided for @editPlant.
  ///
  /// In el, this message translates to:
  /// **'Επεξεργασία Φυτού'**
  String get editPlant;

  /// No description provided for @addPlant.
  ///
  /// In el, this message translates to:
  /// **'Προσθήκη Φυτού'**
  String get addPlant;

  /// No description provided for @savePlant.
  ///
  /// In el, this message translates to:
  /// **'Αποθήκευση Φυτού'**
  String get savePlant;

  /// No description provided for @updatePlant.
  ///
  /// In el, this message translates to:
  /// **'Ενημέρωση Φυτού'**
  String get updatePlant;

  /// No description provided for @deletePlant.
  ///
  /// In el, this message translates to:
  /// **'Διαγραφή Φυτού'**
  String get deletePlant;

  /// No description provided for @confirmDelete.
  ///
  /// In el, this message translates to:
  /// **'Θέλεις σίγουρα να διαγράψεις το φυτό \"{name}\";'**
  String confirmDelete(String name);

  /// No description provided for @cancel.
  ///
  /// In el, this message translates to:
  /// **'Άκυρο'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In el, this message translates to:
  /// **'Διαγραφή'**
  String get delete;

  /// No description provided for @water.
  ///
  /// In el, this message translates to:
  /// **'Πότισμα'**
  String get water;

  /// No description provided for @undo.
  ///
  /// In el, this message translates to:
  /// **'ΑΝΑΙΡΕΣΗ'**
  String get undo;

  /// No description provided for @plantWatered.
  ///
  /// In el, this message translates to:
  /// **'Το φυτό \"{name}\" ποτίστηκε! 💧'**
  String plantWatered(String name);

  /// No description provided for @needsWater.
  ///
  /// In el, this message translates to:
  /// **'Χρειάζεται πότισμα!'**
  String get needsWater;

  /// No description provided for @nextWateringIn.
  ///
  /// In el, this message translates to:
  /// **'Επόμενο σε {days} μέρες'**
  String nextWateringIn(int days);

  /// No description provided for @navPlants.
  ///
  /// In el, this message translates to:
  /// **'Φυτά'**
  String get navPlants;

  /// No description provided for @navStats.
  ///
  /// In el, this message translates to:
  /// **'Στατιστικά'**
  String get navStats;

  /// No description provided for @sortNeedsWater.
  ///
  /// In el, this message translates to:
  /// **'Πιο διψασμένα πρώτα'**
  String get sortNeedsWater;

  /// No description provided for @sortName.
  ///
  /// In el, this message translates to:
  /// **'Αλφαβητικά (Α-Ω)'**
  String get sortName;

  /// No description provided for @sortRecent.
  ///
  /// In el, this message translates to:
  /// **'Πρόσφατα ποτισμένα'**
  String get sortRecent;

  /// No description provided for @statsTitle.
  ///
  /// In el, this message translates to:
  /// **'Στατιστικά Φροντίδας'**
  String get statsTitle;

  /// No description provided for @statsTotal.
  ///
  /// In el, this message translates to:
  /// **'Σύνολο'**
  String get statsTotal;

  /// No description provided for @statsThirsty.
  ///
  /// In el, this message translates to:
  /// **'Διψασμένα'**
  String get statsThirsty;

  /// No description provided for @statsAvgInterval.
  ///
  /// In el, this message translates to:
  /// **'Μ.Ο. Συχνότητας'**
  String get statsAvgInterval;

  /// No description provided for @hydrationState.
  ///
  /// In el, this message translates to:
  /// **'Κατάσταση Ενυδάτωσης'**
  String get hydrationState;

  /// No description provided for @plantsByLocation.
  ///
  /// In el, this message translates to:
  /// **'Φυτά ανά Χώρο'**
  String get plantsByLocation;

  /// No description provided for @locBalconySouth.
  ///
  /// In el, this message translates to:
  /// **'Νότιο Μπαλκόνι'**
  String get locBalconySouth;

  /// No description provided for @locBalconyNorth.
  ///
  /// In el, this message translates to:
  /// **'Βόρειο Μπαλκόνι'**
  String get locBalconyNorth;

  /// No description provided for @locLivingRoom.
  ///
  /// In el, this message translates to:
  /// **'Σαλόνι'**
  String get locLivingRoom;

  /// No description provided for @locOffice.
  ///
  /// In el, this message translates to:
  /// **'Γραφείο'**
  String get locOffice;

  /// No description provided for @locBedroom.
  ///
  /// In el, this message translates to:
  /// **'Υπνοδωμάτιο'**
  String get locBedroom;

  /// No description provided for @locGarden.
  ///
  /// In el, this message translates to:
  /// **'Κήπος'**
  String get locGarden;

  /// No description provided for @plantHelichrysum.
  ///
  /// In el, this message translates to:
  /// **'Ελίχρυσος'**
  String get plantHelichrysum;

  /// No description provided for @plantBlackPine.
  ///
  /// In el, this message translates to:
  /// **'Μαύρη Πεύκη'**
  String get plantBlackPine;

  /// No description provided for @navCalendar.
  ///
  /// In el, this message translates to:
  /// **'Ημερολόγιο'**
  String get navCalendar;

  /// No description provided for @calendarTitle.
  ///
  /// In el, this message translates to:
  /// **'Ημερολόγιο Ποτίσματος'**
  String get calendarTitle;

  /// No description provided for @calendarWatered.
  ///
  /// In el, this message translates to:
  /// **'Ποτίστηκε'**
  String get calendarWatered;

  /// No description provided for @calendarDue.
  ///
  /// In el, this message translates to:
  /// **'Θέλει πότισμα'**
  String get calendarDue;

  /// No description provided for @calendarUpcoming.
  ///
  /// In el, this message translates to:
  /// **'Προγραμματισμένο'**
  String get calendarUpcoming;

  /// No description provided for @calendarNoEvents.
  ///
  /// In el, this message translates to:
  /// **'Κανένα πότισμα για αυτή την ημέρα.'**
  String get calendarNoEvents;

  /// No description provided for @calendarToday.
  ///
  /// In el, this message translates to:
  /// **'Σήμερα'**
  String get calendarToday;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['el', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
