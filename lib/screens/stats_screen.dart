import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/plant_controller.dart';
import '../models/plant.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plants = ref.watch(plantListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (plants.isEmpty) {
      return const Center(
        child: Text(
          'Δεν υπάρχουν δεδομένα για στατιστικά.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final totalPlants = plants.length;
    final thirstyCount = plants.where((p) => p.needsWater).length;
    final hydratedCount = totalPlants - thirstyCount;

    // Μέσος όρος ημερών συχνότητας
    final avgInterval =
        (plants.fold<int>(0, (sum, p) => sum + p.wateringIntervalDays) /
                totalPlants)
            .toStringAsFixed(1);

    // Κατανομή ανά τοποθεσία
    final locationCounts = <PlantLocation, int>{};
    for (final loc in PlantLocation.values) {
      locationCounts[loc] = plants.where((p) => p.location == loc).length;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Στατιστικά Φροντίδας',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Metrics Cards Row
            Row(
              children: [
                _buildMetricCard(
                  context,
                  title: 'Σύνολο',
                  value: '$totalPlants',
                  icon: Icons.local_florist,
                  color: Colors.green,
                ),
                const SizedBox(width: 12),
                _buildMetricCard(
                  context,
                  title: 'Διψασμένα',
                  value: '$thirstyCount',
                  icon: Icons.warning_amber_rounded,
                  color: Colors.orange,
                ),
                const SizedBox(width: 12),
                _buildMetricCard(
                  context,
                  title: 'Μ.Ο. Συχνότητας',
                  value: '$avgInterval ημ.',
                  icon: Icons.repeat,
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 2. Pie Chart: Κατάσταση Ενυδάτωσης
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
              ),
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Κατάσταση Ενυδάτωσης',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 45,
                          sections: [
                            PieChartSectionData(
                              value: hydratedCount.toDouble(),
                              title: hydratedCount > 0
                                  ? '$hydratedCount 🌿'
                                  : '',
                              color: const Color(0xFF2E7D32),
                              radius: 40,
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            PieChartSectionData(
                              value: thirstyCount.toDouble(),
                              title: thirstyCount > 0 ? '$thirstyCount 💧' : '',
                              color: Colors.orange.shade700,
                              radius: 40,
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem(
                          const Color(0xFF2E7D32),
                          'Ενυδατωμένα',
                        ),
                        const SizedBox(width: 20),
                        _buildLegendItem(
                          Colors.orange.shade700,
                          'Χρειάζονται πότισμα',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Bar Chart: Κατανομή ανά Τοποθεσία
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
              ),
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Φυτά ανά Χώρο',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (plants.length + 1).toDouble(),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index >= 0 &&
                                      index < PlantLocation.values.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Icon(
                                        PlantLocation.values[index].icon,
                                        size: 18,
                                        color: isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade700,
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                          barGroups: PlantLocation.values.asMap().entries.map((
                            entry,
                          ) {
                            final idx = entry.key;
                            final loc = entry.value;
                            final count = locationCounts[loc] ?? 0;
                            return BarChartGroupData(
                              x: idx,
                              barRods: [
                                BarChartRodData(
                                  toY: count.toDouble(),
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 18,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Εικονίδια: Νότιο Μπαλκόνι | Βόρειο | Σαλόνι | Γραφείο | Υπνοδωμάτιο | Κήπος',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
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

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
