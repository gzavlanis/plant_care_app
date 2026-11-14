import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'controllers/plant_controller.dart';
import 'l10n/generated/app_localizations.dart';
import 'models/plant.dart';
import 'screens/calendar_screen.dart';
import 'screens/plant_detail_screen.dart';
import 'screens/stats_screen.dart';
import 'services/notification_service.dart';
import 'widgets/add_plant_sheet.dart';

// Provider για την επιλογή προβολής (false = Λίστα, true = Πλέγμα Καρτών)
class PlantGridViewNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final plantGridViewProvider = NotifierProvider<PlantGridViewNotifier, bool>(
  PlantGridViewNotifier.new,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(const ProviderScope(child: PlantTrackerApp()));
}

class PlantTrackerApp extends ConsumerWidget {
  const PlantTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Plant Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F8F5),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.dark,
          surface: const Color(0xFF1E2421),
        ),
        scaffoldBackgroundColor: const Color(0xFF121614),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// Navigation Shell με BottomNavigationBar
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    PlantListScreen(),
    CalendarScreen(),
    StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.yard_outlined),
            selectedIcon: const Icon(Icons.yard),
            label: l10n.navPlants,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: l10n.navCalendar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: l10n.navStats,
          ),
        ],
      ),
    );
  }
}

class PlantListScreen extends ConsumerWidget {
  const PlantListScreen({super.key});

  void _openAddPlantModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return AddPlantSheet(
          onSave: (plant) {
            ref.read(plantListProvider.notifier).addPlant(plant);
          },
        );
      },
    );
  }

  void _waterWithSnackbar(
    BuildContext context,
    WidgetRef ref,
    Plant plant,
    AppLocalizations l10n,
  ) {
    HapticFeedback.mediumImpact();
    ref.read(plantListProvider.notifier).waterPlant(plant.id);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.plantWatered(plant.name)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: l10n.undo,
          textColor: Colors.yellowAccent,
          onPressed: () {
            ref.read(plantListProvider.notifier).undoWatering(plant.id);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plants = ref.watch(filteredPlantsProvider);
    final activeFilter = ref.watch(plantFilterProvider);
    final activeSort = ref.watch(plantSortProvider);
    final currentLocale = ref.watch(localeProvider);
    final isGridView = ref.watch(plantGridViewProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.myPlants,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          // 1. Εναλλαγή Προβολής (Λίστα / Κάρτες Πλέγματος)
          IconButton(
            icon: Icon(
              isGridView ? Icons.view_list_outlined : Icons.grid_view_outlined,
            ),
            tooltip: isGridView ? 'Προβολή Λίστας' : 'Προβολή Καρτών',
            onPressed: () {
              ref.read(plantGridViewProvider.notifier).toggle();
            },
          ),

          // 2. Κουμπί Εναλλαγής Γλώσσας (EL / EN)
          TextButton(
            onPressed: () {
              ref.read(localeProvider.notifier).toggleLocale();
            },
            style: TextButton.styleFrom(
              minimumSize: const Size(36, 36),
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
            child: Text(
              currentLocale.languageCode.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          // 3. Κουμπί Εναλλαγής Θέματος (Light / Dark)
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            tooltip: isDark ? 'Light Mode' : 'Dark Mode',
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),

          // 4. Μενού Ταξινόμησης (Sort)
          PopupMenuButton<PlantSort>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onSelected: (sort) {
              ref.read(plantSortProvider.notifier).setSort(sort);
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: PlantSort.needsWaterFirst,
                child: Row(
                  children: [
                    Icon(
                      Icons.water_drop,
                      size: 18,
                      color: activeSort == PlantSort.needsWaterFirst
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(l10n.sortNeedsWater),
                  ],
                ),
              ),
              PopupMenuItem(
                value: PlantSort.nameAsc,
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha,
                      size: 18,
                      color: activeSort == PlantSort.nameAsc
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(l10n.sortName),
                  ],
                ),
              ),
              PopupMenuItem(
                value: PlantSort.recentlyWatered,
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: 18,
                      color: activeSort == PlantSort.recentlyWatered
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(l10n.sortRecent),
                  ],
                ),
              ),
            ],
          ),

          // 5. Test Notification
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Test Notification',
            onPressed: () {
              NotificationService().showWateringNotification(
                id: 999,
                plantName: 'Ελίχρυσος',
                message: '300ml',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SearchBar(
              hintText: l10n.searchHint,
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.surface,
              ),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  ),
                ),
              ),
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).setQuery(value);
              },
            ),
          ),

          // 2. Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 6.0,
            ),
            child: Row(
              children: [
                FilterChip(
                  label: Text(l10n.filterAll),
                  selected: activeFilter == PlantFilter.all,
                  onSelected: (_) {
                    ref
                        .read(plantFilterProvider.notifier)
                        .setFilter(PlantFilter.all);
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(l10n.filterThirsty),
                  selected: activeFilter == PlantFilter.needsWater,
                  selectedColor: isDark
                      ? Colors.orange.shade900.withValues(alpha: 0.4)
                      : Colors.orange.shade100,
                  onSelected: (_) {
                    ref
                        .read(plantFilterProvider.notifier)
                        .setFilter(PlantFilter.needsWater);
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(l10n.filterOk),
                  selected: activeFilter == PlantFilter.ok,
                  selectedColor: isDark
                      ? Colors.green.shade900.withValues(alpha: 0.4)
                      : Colors.green.shade100,
                  onSelected: (_) {
                    ref
                        .read(plantFilterProvider.notifier)
                        .setFilter(PlantFilter.ok);
                  },
                ),
              ],
            ),
          ),

          // 3. Λίστα ή Πλέγμα Φυτών
          Expanded(
            child: plants.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.yard_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.noPlantsFound,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : isGridView
                ? GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.74,
                        ),
                    itemCount: plants.length,
                    itemBuilder: (context, index) {
                      final plant = plants[index];
                      return _buildPlantGridCard(context, ref, plant, l10n);
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                    itemCount: plants.length,
                    itemBuilder: (context, index) {
                      final plant = plants[index];
                      return _buildPlantCard(context, ref, plant);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddPlantModal(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.newPlant),
      ),
    );
  }

  /// Κάθετη Κάρτα για το Πλέγμα 2 στηλών (Grid View)
  Widget _buildPlantGridCard(
    BuildContext context,
    WidgetRef ref,
    Plant plant,
    AppLocalizations l10n,
  ) {
    final needsWater = plant.needsWater;
    final hasImage =
        plant.imageUrl != null && File(plant.imageUrl!).existsSync();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final statusColor = needsWater
        ? (isDark ? Colors.orange.shade300 : Colors.orange.shade800)
        : (isDark ? Colors.green.shade300 : Colors.green.shade700);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: needsWater
              ? (isDark ? Colors.orange.shade700 : Colors.orange.shade300)
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          width: needsWater ? 1.5 : 1.0,
        ),
      ),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => PlantDetailScreen(plantId: plant.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Επάνω τμήμα: Φωτογραφία ή Εικονίδιο + Badge Τοποθεσίας
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'plant_image_${plant.id}',
                    child: hasImage
                        ? Image.file(File(plant.imageUrl!), fit: BoxFit.cover)
                        : Container(
                            color: needsWater
                                ? (isDark
                                      ? Colors.orange.shade900.withValues(
                                          alpha: 0.25,
                                        )
                                      : Colors.orange.shade50)
                                : (isDark
                                      ? Colors.green.shade900.withValues(
                                          alpha: 0.25,
                                        )
                                      : Colors.green.shade50),
                            child: Center(
                              child: Icon(
                                Icons.local_florist,
                                size: 42,
                                color: statusColor,
                              ),
                            ),
                          ),
                  ),
                  // Badge χώρου πάνω αριστερά
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.black : Colors.white)
                            .withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            plant.location.icon,
                            size: 12,
                            color: isDark
                                ? Colors.grey.shade200
                                : Colors.grey.shade800,
                          ),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 85),
                            child: Text(
                              plant.location.localizedLabel(context),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey.shade200
                                    : Colors.grey.shade800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Κάτω τμήμα: Πληροφορίες & Πότισμα
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.localizedName(context),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plant.species.isNotEmpty ? plant.species : '—',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: plant.hydrationLevel,
                        minHeight: 5,
                        backgroundColor: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          plant.hydrationLevel < 0.25
                              ? Colors.red.shade400
                              : plant.hydrationLevel < 0.55
                              ? Colors.orange.shade400
                              : Colors.green.shade500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            needsWater
                                ? l10n.needsWater
                                : l10n.nextWateringIn(plant.daysUntilWatering),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: IconButton.filledTonal(
                            padding: EdgeInsets.zero,
                            iconSize: 18,
                            onPressed: () =>
                                _waterWithSnackbar(context, ref, plant, l10n),
                            icon: const Icon(Icons.water_drop_outlined),
                            tooltip: l10n.water,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Οριζόντια Κάρτα για την Προβολή Λίστας (List View)
  Widget _buildPlantCard(BuildContext context, WidgetRef ref, Plant plant) {
    final needsWater = plant.needsWater;
    final hasImage =
        plant.imageUrl != null && File(plant.imageUrl!).existsSync();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Dismissible(
      key: Key('dismissible_${plant.id}'),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            const Icon(Icons.water_drop, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            Text(
              l10n.water,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              l10n.delete,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.delete_outline, color: Colors.white, size: 28),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _waterWithSnackbar(context, ref, plant, l10n);
          return false;
        }

        if (direction == DismissDirection.endToStart) {
          HapticFeedback.heavyImpact();

          final bool? shouldDelete = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.deletePlant),
              content: Text(l10n.confirmDelete(plant.name)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(l10n.delete),
                ),
              ],
            ),
          );

          if (shouldDelete == true) {
            ref.read(plantListProvider.notifier).deletePlant(plant.id);
            return true;
          }
          return false;
        }

        return false;
      },
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: needsWater
                ? (isDark ? Colors.orange.shade700 : Colors.orange.shade300)
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
            width: needsWater ? 1.5 : 1.0,
          ),
        ),
        color: Theme.of(context).colorScheme.surface,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => PlantDetailScreen(plantId: plant.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Hero(
                  tag: 'plant_image_${plant.id}',
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: needsWater
                        ? (isDark
                              ? Colors.orange.shade900.withValues(alpha: 0.3)
                              : Colors.orange.shade50)
                        : (isDark
                              ? Colors.green.shade900.withValues(alpha: 0.3)
                              : Colors.green.shade50),
                    backgroundImage: hasImage
                        ? FileImage(File(plant.imageUrl!))
                        : null,
                    child: !hasImage
                        ? Icon(
                            Icons.local_florist,
                            size: 30,
                            color: needsWater
                                ? (isDark
                                      ? Colors.orange.shade300
                                      : Colors.orange.shade800)
                                : (isDark
                                      ? Colors.green.shade300
                                      : Colors.green.shade700),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plant.localizedName(context),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              plant.species.isNotEmpty ? plant.species : '—',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    plant.location.icon,
                                    size: 13,
                                    color: isDark
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      plant.location.localizedLabel(context),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.grey.shade300
                                            : Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: plant.hydrationLevel,
                          minHeight: 6,
                          backgroundColor: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            plant.hydrationLevel < 0.25
                                ? Colors.red.shade400
                                : plant.hydrationLevel < 0.55
                                ? Colors.orange.shade400
                                : Colors.green.shade500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            needsWater
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_outline,
                            size: 16,
                            color: needsWater
                                ? (isDark
                                      ? Colors.orange.shade300
                                      : Colors.orange.shade800)
                                : (isDark
                                      ? Colors.green.shade300
                                      : Colors.green.shade700),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              needsWater
                                  ? l10n.needsWater
                                  : l10n.nextWateringIn(
                                      plant.daysUntilWatering,
                                    ),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: needsWater
                                    ? (isDark
                                          ? Colors.orange.shade300
                                          : Colors.orange.shade800)
                                    : (isDark
                                          ? Colors.green.shade300
                                          : Colors.green.shade700),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () =>
                      _waterWithSnackbar(context, ref, plant, l10n),
                  icon: const Icon(Icons.water_drop_outlined),
                  tooltip: l10n.water,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
