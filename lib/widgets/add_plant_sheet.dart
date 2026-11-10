import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/plant.dart';

class AddPlantSheet extends StatefulWidget {
  final Plant? initialPlant;
  final Function(Plant) onSave;

  const AddPlantSheet({super.key, this.initialPlant, required this.onSave});

  @override
  State<AddPlantSheet> createState() => _AddPlantSheetState();
}

class _AddPlantSheetState extends State<AddPlantSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _speciesController;
  late final TextEditingController _intervalController;

  late PlantLocation _selectedLocation;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  bool get _isEditing => widget.initialPlant != null;

  @override
  void initState() {
    super.initState();
    final p = widget.initialPlant;
    _nameController = TextEditingController(text: p?.name ?? '');
    _speciesController = TextEditingController(text: p?.species ?? '');
    _intervalController = TextEditingController(
      text: p != null ? p.wateringIntervalDays.toString() : '7',
    );
    _selectedLocation = p?.location ?? PlantLocation.balconySouth;

    if (p?.imageUrl != null && File(p!.imageUrl!).existsSync()) {
      _selectedImage = File(p.imageUrl!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Λήψη με Κάμερα'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Επιλογή από Συλλογή'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submitData() {
    if (!_formKey.currentState!.validate()) return;

    final plantToSave = Plant(
      id:
          widget.initialPlant?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      species: _speciesController.text.trim(),
      wateringIntervalDays: int.parse(_intervalController.text.trim()),
      lastWatered: widget.initialPlant?.lastWatered ?? DateTime.now(),
      imageUrl: _selectedImage?.path,
      wateringHistory: widget.initialPlant?.wateringHistory ?? const [],
      location: _selectedLocation,
    );

    widget.onSave(plantToSave);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: bottomInset + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'Επεξεργασία Φυτού' : 'Προσθήκη Φυτού',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : null,
                      child: _selectedImage == null
                          ? Icon(
                              Icons.spa_outlined,
                              size: 40,
                              color: Colors.grey.shade500,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _showImagePickerOptions,
                        borderRadius: BorderRadius.circular(20),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary,
                          child: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Κοινό Όνομα (π.χ. Μονστέρα)',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Παρακαλώ συμπληρώστε όνομα.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _speciesController,
                decoration: const InputDecoration(
                  labelText: 'Είδος / Βοτανικό όνομα',
                  prefixIcon: Icon(Icons.local_florist_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _intervalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Συχνότητα ποτίσματος (ημέρες)',
                  prefixIcon: Icon(Icons.water_drop_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Συμπληρώστε ημέρες.';
                  }
                  final number = int.tryParse(value);
                  if (number == null || number <= 0) {
                    return 'Δώστε έγκυρο αριθμό (> 0).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Επιλογή Χώρου / Τοποθεσίας
              const Text(
                'Τοποθεσία Φυτού',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: PlantLocation.values.map((loc) {
                  final isSelected = _selectedLocation == loc;
                  return ChoiceChip(
                    avatar: Icon(
                      loc.icon,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.primary,
                    ),
                    label: Text(loc.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedLocation = loc;
                        });
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _submitData,
                icon: const Icon(Icons.check),
                label: Text(
                  _isEditing ? 'Ενημέρωση Φυτού' : 'Αποθήκευση Φυτού',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
