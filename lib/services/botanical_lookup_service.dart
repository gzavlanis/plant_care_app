import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class BotanicalLookupService {
  static final Dio _gbifDio = Dio(
    BaseOptions(
      baseUrl: 'https://api.gbif.org/v1',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  static final Dio _wikiDio = Dio(
    BaseOptions(
      baseUrl: 'https://el.wikipedia.org/w',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {'User-Agent': 'PlantTrackerApp/1.0'},
    ),
  );

  // In-memory cache για να μην ξαναγίνονται κλήσεις για το ίδιο query
  static final Map<String, List<String>> _apiCache = {};

  // Τοπικό λεξικό (Ελληνικά & Αγγλικά κοινά ονόματα - 0ms)
  static final Map<String, List<String>> _localDictionary = {
    'ποθος': ['Epipremnum aureum', 'Scindapsus pictus'],
    'pothos': ['Epipremnum aureum', 'Scindapsus pictus'],
    'μονστερα': ['Monstera deliciosa', 'Monstera adansonii'],
    'monstera': ['Monstera deliciosa', 'Monstera adansonii'],
    'ελιχρυσος': ['Helichrysum italicum', 'Helichrysum stoechas'],
    'μαυρη πευκη': ['Pinus thunbergii'],
    'πευκο': ['Pinus pinaster', 'Pinus halepensis', 'Pinus thunbergii'],
    'κρινακι της θαλασσας': ['Pancratium maritimum'],
    'κρινος της θαλασσας': ['Pancratium maritimum'],
    'ασκελετουρα': ['Drimia maritima'],
    'πλουμερια': ['Plumeria rubra'],
    'φραντζιπανι': ['Plumeria rubra'],
    'αβοκαντο': ['Persea americana'],
    'καφεοδεντρο': ['Coffea arabica'],
    'καφες': ['Coffea arabica'],
    'παιωνια': ['Paeonia suffruticosa'],
    'στεφανωτη': ['Stephanotis floribunda'],
    'κυκλαμινο': ['Cyclamen persicum'],
    'νεραγκουλα': ['Ranunculus asiaticus'],
    'ανεμωνη': ['Anemone coronaria'],
    'ναρκισσος': ['Narcissus tazetta'],
    'σαλεπι': ['Himantoglossum robertianum'],
    'ανθρωπακι': ['Orchis italica'],
    'αζαλεα': ['Rhododendron simsii'],
    'λεβαντα': ['Lavandula angustifolia', 'Lavandula stoechas'],
    'δεντρολιβανο': ['Salvia rosmarinus'],
    'βασιλικος': ['Ocimum basilicum'],
    'αλοη': ['Aloe vera'],
    'σανσεβιερια': ['Dracaena trifasciata'],
    'ζαμιοκουλκας': ['Zamioculcas zamiifolia'],
    'ζαμια': ['Zamioculcas zamiifolia'],
    'σπαθιφυλλο': ['Spathiphyllum wallisii'],
    'φικος': ['Ficus benjamina', 'Ficus lyrata', 'Ficus elastica'],
    'καλαθεα': ['Goeppertia'],
    'ορχιδεα': ['Phalaenopsis'],
    'λεμονια': ['Citrus limon'],
    'φιστικια': ['Pistacia vera'],
    'πλατανος': ['Platanus orientalis'],
    'γαρδενια': ['Gardenia jasminoides'],
    'ιβισκος': ['Hibiscus rosa-sinensis'],
    'βουκαμβιλια': ['Bougainvillea spectabilis'],
    'γιασεμι': ['Jasminum officinale', 'Trachelospermum jasminoides'],
  };

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .trim()
        .replaceAll('ά', 'α')
        .replaceAll('έ', 'ε')
        .replaceAll('ή', 'η')
        .replaceAll('ί', 'ι')
        .replaceAll('ό', 'ο')
        .replaceAll('ύ', 'υ')
        .replaceAll('ώ', 'ω')
        .replaceAll('ϊ', 'ι')
        .replaceAll('ϋ', 'υ')
        .replaceAll('ΐ', 'ι')
        .replaceAll('ΰ', 'υ');
  }

  static bool _containsGreek(String text) {
    return RegExp(r'[\u0370-\u03FF]').hasMatch(text);
  }

  /// 1. Άμεση αναζήτηση στο τοπικό λεξικό (Offline)
  static List<String> searchLocal(String query) {
    final clean = _normalize(query);
    if (clean.length < 3) return [];

    if (_localDictionary.containsKey(clean)) {
      return _localDictionary[clean]!;
    }

    final matches = <String>{};
    for (final entry in _localDictionary.entries) {
      if (clean.contains(entry.key) || entry.key.startsWith(clean)) {
        matches.addAll(entry.value);
      }
    }
    return matches.toList();
  }

  /// 2. Online αναζήτηση από το πεδίο "Κοινό Όνομα" (Ελληνικά & Αγγλικά)
  static Future<List<String>> searchOnline(String query) async {
    final clean = query.trim();
    if (clean.length < 3) return [];

    final cacheKey = 'common_${clean.toLowerCase()}';
    if (_apiCache.containsKey(cacheKey) && _apiCache[cacheKey]!.isNotEmpty) {
      return _apiCache[cacheKey]!;
    }

    final results = <String>{};

    // Α. Αναζήτηση στο GBIF (Vernacular names + Scientific names)
    try {
      final gbifResponse = await _gbifDio.get(
        '/species/search',
        queryParameters: {
          'q': clean,
          'highertaxon_key': 6, // 6 = Βασίλειο Plantae (Φυτά)
          'status': 'ACCEPTED',
          'limit': 6,
        },
      );

      final data = gbifResponse.data as Map<String, dynamic>;
      final list = data['results'] as List<dynamic>? ?? [];

      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final canonical = map['canonicalName'] as String?;
        if (canonical != null && canonical.isNotEmpty) {
          results.add(canonical);
        }
      }
    } catch (_) {}

    // Β. Αν είναι στα Ελληνικά και το GBIF δεν έδωσε αποτελέσματα,
    // ψάχνουμε στην Ελληνική Wikipedia -> Αγγλικός τίτλος -> Επαλήθευση στο GBIF
    if (results.isEmpty && _containsGreek(clean)) {
      try {
        final wikiResponse = await _wikiDio.get(
          '/api.php',
          queryParameters: {
            'action': 'query',
            'generator': 'search',
            'gsrsearch': clean,
            'gsrlimit': 3,
            'prop': 'langlinks',
            'lllang': 'en',
            'format': 'json',
          },
        );

        final wikiData = wikiResponse.data as Map<String, dynamic>;
        final pages = (wikiData['query'] as Map<String, dynamic>?)?['pages']
        as Map<String, dynamic>?;

        if (pages != null) {
          for (final page in pages.values) {
            final pageMap = page as Map<String, dynamic>;
            final langlinks = pageMap['langlinks'] as List<dynamic>?;
            if (langlinks != null && langlinks.isNotEmpty) {
              final enTitle =
              (langlinks.first as Map<String, dynamic>)['*'] as String?;
              if (enTitle != null && enTitle.isNotEmpty) {
                final verified = await _verifyPlantInGbif(enTitle);
                if (verified != null) {
                  results.add(verified);
                }
              }
            }
          }
        }
      } catch (_) {}
    }

    final finalList = results.take(4).toList();
    if (finalList.isNotEmpty) {
      _apiCache[cacheKey] = finalList;
    }
    return finalList;
  }

  /// 3. Prefix Autocomplete καθώς πληκτρολογείς λατινικά στο πεδίο του Είδους (π.χ. "Pinus ")
  static Future<List<String>> suggestScientificPrefix(String rawInput) async {
    final clean = rawInput.trim();
    if (clean.length < 3) return [];

    final lowerClean = clean.toLowerCase();

    // Πρώτα ελέγχουμε τοπικά όσα αρχίζουν από αυτό το γένος (π.χ. "pinus")
    final localGenusMatches = <String>{};
    for (final list in _localDictionary.values) {
      for (final scientific in list) {
        if (scientific.toLowerCase().startsWith(lowerClean)) {
          localGenusMatches.add(scientific);
        }
      }
    }

    final cacheKey = 'prefix_$lowerClean';
    if (_apiCache.containsKey(cacheKey) && _apiCache[cacheKey]!.isNotEmpty) {
      return {...localGenusMatches, ..._apiCache[cacheKey]!}.take(5).toList();
    }

    // Online αναζήτηση στο GBIF με rank=SPECIES για καθαρά είδη φυτών
    try {
      final response = await _gbifDio.get(
        '/species/suggest',
        queryParameters: {
          'q': clean,
          'limit': 20, // Χωρίς περιορισμό rank ώστε να φέρνει τα πιο δημοφιλή πρώτα
        },
      );

      final data = response.data as List<dynamic>;
      final results = <String>{...localGenusMatches};

      for (final item in data) {
        final map = item as Map<String, dynamic>;
        final kingdom = map['kingdom']?.toString().toLowerCase();
        final rank = map['rank']?.toString().toUpperCase();
        final rawName =
        (map['canonicalName'] ?? map['scientificName'])?.toString();

        // Κρατάμε μόνο φυτά (Plantae) και είδη (SPECIES) που ξεκινούν από το prefix
        if (kingdom == 'plantae' &&
            rank == 'SPECIES' &&
            rawName != null &&
            rawName.toLowerCase().startsWith(lowerClean)) {
          final parts = rawName.trim().split(RegExp(r'\s+'));
          if (parts.length >= 2) {
            results.add('${parts[0]} ${parts[1]}');
          }
        }
      }

      final finalList = results.take(6).toList();
      if (finalList.isNotEmpty) {
        _apiCache[cacheKey] = finalList;
      }
      return finalList;
    } catch (e) {
      debugPrint('GBIF lookup error: $e');
      return localGenusMatches.take(5).toList();
    }
  }

  /// Βοηθητική μέθοδος επαλήθευσης φυτού στο GBIF
  static Future<String?> _verifyPlantInGbif(String name) async {
    try {
      final res = await _gbifDio.get(
        '/species/match',
        queryParameters: {
          'name': name,
          'kingdom': 'Plantae',
        },
      );
      final data = res.data as Map<String, dynamic>;
      if (data['matchType'] != 'NONE' && data['canonicalName'] != null) {
        return data['canonicalName'] as String;
      }
    } catch (_) {}
    return null;
  }
}