import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/plant_controller.dart';
import '../widgets/add_plant_sheet.dart';

class PlantDetailScreen extends ConsumerWidget {
  final String plantId;

  const PlantDetailScreen({super.key, required this.plantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plants = ref.watch(plantListProvider);
    final plantIndex = plants.indexWhere((p) => p.id == plantId);

    if (plantIndex == -1) {
      return const SizedBox.shrink();
    }

    final plant = plants[plantIndex];
    final needsWater = plant.needsWater;
    final hasImage =
        plant.imageUrl != null && File(plant.imageUrl!).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: Text(plant.name),
        actions: [
          // Κουμπί Επεξεργασίας
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Επεξεργασία φυτού',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (ctx) => AddPlantSheet(
                  initialPlant: plant,
                  onSave: (updated) {
                    ref.read(plantListProvider.notifier).updatePlant(updated);
                  },
                ),
              );
            },
          ),
          // Κουμπί Διαγραφής
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Διαγραφή φυτού',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Διαγραφή Φυτού'),
                  content: Text(
                    'Θέλεις σίγουρα να διαγράψεις το φυτό "${plant.name}";',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Άκυρο'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () {
                        final idToDelete = plant.id;

                        // 1. Κλείνει το διάλογο επιβεβαίωσης
                        Navigator.of(ctx).pop();

                        // 2. Επιστρέφει στην προηγούμενη οθόνη (Dashboard)
                        Navigator.of(context).pop();

                        // 3. Εκτελεί τη διαγραφή μετά την αποχώρηση για αποφυγή flicker
                        ref
                            .read(plantListProvider.notifier)
                            .deletePlant(idToDelete);
                      },
                      child: const Text('Διαγραφή'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(
              tag: 'plant_image_${plant.id}',
              child: Container(
                height: 280,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  image: hasImage
                      ? DecorationImage(
                          image: FileImage(File(plant.imageUrl!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: !hasImage
                    ? Icon(
                        Icons.local_florist,
                        size: 90,
                        color: Colors.green.shade400,
                      )
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name,
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (plant.species.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      plant.species,
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: needsWater
                          ? Colors.orange.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: needsWater
                            ? Colors.orange.shade200
                            : Colors.green.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          needsWater
                              ? Icons.warning_rounded
                              : Icons.check_circle_rounded,
                          size: 32,
                          color: needsWater
                              ? Colors.orange.shade800
                              : Colors.green.shade700,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                needsWater
                                    ? 'Χρειάζεται άμεσα πότισμα'
                                    : 'Εντάξει με το νερό',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: needsWater
                                      ? Colors.orange.shade900
                                      : Colors.green.shade900,
                                ),
                              ),
                              Text(
                                needsWater
                                    ? 'Έχει περάσει η προθεσμία ποτίσματος.'
                                    : 'Επόμενο πότισμα σε ${plant.daysUntilWatering} ημέρες.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: needsWater
                                      ? Colors.orange.shade800
                                      : Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Πληροφορίες Φροντίδας',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(child: Icon(Icons.repeat)),
                    title: const Text('Συχνότητα'),
                    subtitle: Text('Κάθε ${plant.wateringIntervalDays} ημέρες'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      child: Icon(Icons.calendar_today_outlined),
                    ),
                    title: const Text('Τελευταίο Πότισμα'),
                    subtitle: Text(
                      '${plant.lastWatered.day.toString().padLeft(2, '0')}/${plant.lastWatered.month.toString().padLeft(2, '0')}/${plant.lastWatered.year}',
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Icon(plant.location.icon)),
                    title: const Text('Τοποθεσία'),
                    subtitle: Text(plant.location.label),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Ιστορικό Ποτισμάτων',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  if (plant.wateringHistory.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Δεν υπάρχουν παλαιότερες καταγραφές.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: plant.wateringHistory.length > 5
                          ? 5
                          : plant.wateringHistory.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final date = plant.wateringHistory[index];
                        final formattedDate =
                            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.water_drop,
                            color: Colors.blueAccent,
                            size: 20,
                          ),
                          title: Text(formattedDate),
                          subtitle: Text(
                            'Καταγραφή #${plant.wateringHistory.length - index}',
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 24),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: () {
                      ref.read(plantListProvider.notifier).waterPlant(plant.id);
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Το φυτό "${plant.name}" ποτίστηκε! 💧',
                          ),
                          duration: const Duration(seconds: 4),
                          action: SnackBarAction(
                            label: 'ΑΝΑΙΡΕΣΗ',
                            textColor: Colors.yellowAccent,
                            onPressed: () {
                              ref
                                  .read(plantListProvider.notifier)
                                  .undoWatering(plant.id);
                            },
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.water_drop),
                    label: const Text('Σημείωση ως Ποτισμένο Σήμερα'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
