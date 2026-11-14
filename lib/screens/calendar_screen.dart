// lib/screens/calendar_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../controllers/plant_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/plant.dart';
import 'plant_detail_screen.dart';

enum _EventType { watered, due, upcoming }

class _CalendarEvent {
  final Plant plant;
  final _EventType type;

  const _CalendarEvent({required this.plant, required this.type});
}

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;
  PlantLocation? _locationFilter; // null = Όλα

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Υπολογίζει όλα τα γεγονότα (παλιά, εκκρεμή, μελλοντικά) για τον τρέχοντα μήνα
  Map<DateTime, List<_CalendarEvent>> _buildMonthEvents(List<Plant> plants) {
    final map = <DateTime, List<_CalendarEvent>>{};
    final now = DateTime.now();
    final today = _dateOnly(now);
    final monthStart = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final monthEnd = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);

    void addEvent(DateTime day, _CalendarEvent event) {
      if (day.isBefore(monthStart) || day.isAfter(monthEnd)) return;
      final list = map.putIfAbsent(day, () => []);
      // Αποφυγή διπλότυπων για το ίδιο φυτό την ίδια ημέρα
      if (!list.any(
        (e) => e.plant.id == event.plant.id && e.type == event.type,
      )) {
        list.add(event);
      }
    }

    for (final plant in plants) {
      if (_locationFilter != null && plant.location != _locationFilter) {
        continue;
      }

      // 1. Ολοκληρωμένα ποτίσματα (από το ιστορικό + το lastWatered)
      final completedDates = <DateTime>{
        _dateOnly(plant.lastWatered),
        ...plant.wateringHistory.map(_dateOnly),
      };

      for (final d in completedDates) {
        addEvent(d, _CalendarEvent(plant: plant, type: _EventType.watered));
      }

      // 2. Επόμενο / Εκκρεμές πότισμα
      final rawNext = _dateOnly(
        plant.lastWatered.add(Duration(days: plant.wateringIntervalDays)),
      );

      // Αν έχει καθυστερήσει (πριν από σήμερα), το καρφιτσώνουμε στο "Σήμερα" ως Due
      DateTime cursor;
      if (rawNext.isBefore(today) || rawNext.isAtSameMomentAs(today)) {
        addEvent(today, _CalendarEvent(plant: plant, type: _EventType.due));
        cursor = today.add(Duration(days: plant.wateringIntervalDays));
      } else {
        cursor = rawNext;
      }

      // 3. Προβολή μελλοντικών ποτισμάτων μέχρι το τέλος του επιλεγμένου μήνα
      while (!cursor.isAfter(monthEnd)) {
        if (!cursor.isBefore(monthStart) && !completedDates.contains(cursor)) {
          addEvent(
            cursor,
            _CalendarEvent(plant: plant, type: _EventType.upcoming),
          );
        }
        cursor = cursor.add(Duration(days: plant.wateringIntervalDays));
      }
    }

    return map;
  }

  Color _dotColor(_EventType type) {
    switch (type) {
      case _EventType.watered:
        return Colors.green.shade500;
      case _EventType.due:
        return Colors.orange.shade600;
      case _EventType.upcoming:
        return Colors.lightBlue.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final plants = ref.watch(plantListProvider);
    final locale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final eventsMap = _buildMonthEvents(plants);
    final selectedEvents = eventsMap[_selectedDate] ?? [];

    final now = DateTime.now();
    final today = _dateOnly(now);

    // Υπολογισμός κελιών μήνα (Εβδομάδα ξεκινάει Δευτέρα = 1 ... Κυριακή = 7)
    final firstDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    );
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final leadingEmptyCells = firstDayOfMonth.weekday - 1;
    final totalCells = leadingEmptyCells + daysInMonth;

    final monthTitle = DateFormat.yMMMM(locale.languageCode)
        .format(_focusedMonth);
    final capitalizedMonthTitle =
        monthTitle[0].toUpperCase() + monthTitle.substring(1);

    // Συντομογραφίες ημερών εβδομάδας (Δε - Κυ / Mo - Su)
    final weekdayLabels = List.generate(7, (i) {
      // 2024-01-01 ήταν Δευτέρα
      final d = DateTime(2024, 1, 1 + i);
      return DateFormat.E(locale.languageCode).format(d);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.calendarTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(today.year, today.month, 1);
                _selectedDate = today;
              });
            },
            child: Text(l10n.calendarToday),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Φίλτρο Χώρου (Chips)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: Text(l10n.filterAll),
                  selected: _locationFilter == null,
                  onSelected: (_) => setState(() => _locationFilter = null),
                ),
                const SizedBox(width: 6),
                ...PlantLocation.values.map((loc) {
                  final selected = _locationFilter == loc;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      showCheckmark: false,
                      avatar: Icon(loc.icon, size: 15),
                      label: Text(loc.localizedLabel(context)),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _locationFilter = selected ? null : loc;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          // 2. Πλοήγηση Μήνα (< Νοέμβριος 2026 >)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month - 1,
                        1,
                      );
                    });
                  },
                ),
                Text(
                  capitalizedMonthTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month + 1,
                        1,
                      );
                    });
                  },
                ),
              ],
            ),
          ),

          // 3. Επικεφαλίδες Ημερών Εβδομάδας
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: weekdayLabels
                  .map(
                    (label) => Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 6),

          // 4. Μηνιαίος Πίνακας Ημερών με Πινέζες
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalCells,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (context, index) {
                if (index < leadingEmptyCells) {
                  return const SizedBox.shrink();
                }

                final dayNumber = index - leadingEmptyCells + 1;
                final cellDate = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month,
                  dayNumber,
                );
                final isToday = cellDate.isAtSameMomentAs(today);
                final isSelected = cellDate.isAtSameMomentAs(_selectedDate);
                final dayEvents = eventsMap[cellDate] ?? [];

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      _selectedDate = cellDate;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.16)
                          : isToday
                          ? (isDark
                                ? Colors.grey.shade800.withValues(alpha: 0.5)
                                : Colors.grey.shade200)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : isToday
                            ? colorScheme.primary.withValues(alpha: 0.5)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isToday || isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? colorScheme.primary : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (dayEvents.isNotEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ...dayEvents
                                  .take(3)
                                  .map(
                                    (e) => Container(
                                      width: 6,
                                      height: 6,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _dotColor(e.type),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              if (dayEvents.length > 3)
                                Text(
                                  '+',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          )
                        else
                          const SizedBox(height: 6),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 5. Υπόμνημα (Legend)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem(Colors.green.shade500, l10n.calendarWatered),
                _buildLegendItem(Colors.orange.shade600, l10n.calendarDue),
                _buildLegendItem(
                  Colors.lightBlue.shade500,
                  l10n.calendarUpcoming,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 6. Λίστα Φυτών Επιλεγμένης Ημέρας
          Expanded(
            child: selectedEvents.isEmpty
                ? Center(
                    child: Text(
                      l10n.calendarNoEvents,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: selectedEvents.length,
                    itemBuilder: (context, index) {
                      final event = selectedEvents[index];
                      final plant = event.plant;
                      final hasImage =
                          plant.imageUrl != null &&
                          File(plant.imageUrl!).existsSync();
                      final dotColor = _dotColor(event.type);

                      String statusLabel;
                      switch (event.type) {
                        case _EventType.watered:
                          statusLabel = l10n.calendarWatered;
                          break;
                        case _EventType.due:
                          statusLabel = l10n.calendarDue;
                          break;
                        case _EventType.upcoming:
                          statusLabel = l10n.calendarUpcoming;
                          break;
                      }

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    PlantDetailScreen(plantId: plant.id),
                              ),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: dotColor.withValues(alpha: 0.15),
                            backgroundImage: hasImage
                                ? FileImage(File(plant.imageUrl!))
                                : null,
                            child: !hasImage
                                ? Icon(Icons.local_florist, color: dotColor)
                                : null,
                          ),
                          title: Text(
                            plant.localizedName(context),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$statusLabel • ${plant.location.localizedLabel(context)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          trailing: event.type == _EventType.due
                              ? IconButton.filledTonal(
                                  icon: const Icon(Icons.water_drop),
                                  tooltip: l10n.water,
                                  onPressed: () {
                                    HapticFeedback.mediumImpact();
                                    ref
                                        .read(plantListProvider.notifier)
                                        .waterPlant(plant.id);
                                  },
                                )
                              : const Icon(Icons.chevron_right, size: 20),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
