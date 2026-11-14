import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/plant.dart';
import '../services/botanical_lookup_service.dart';

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

  // State για το υβριδικό autocomplete επιστημονικής ονομασίας
  List<String> _speciesSuggestions = [];
  bool _isSearchingSpecies = false;
  bool _ignoreSpeciesListener = false;
  Timer? _debounceTimer;

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

    _nameController.addListener(_onNameChanged);
    _speciesController.addListener(_onSpeciesChanged);
  }

  void _onNameChanged() {
    _debounceTimer?.cancel();
    final query = _nameController.text.trim();

    if (query.length < 3) {
      if (_speciesSuggestions.isNotEmpty || _isSearchingSpecies) {
        setState(() {
          _speciesSuggestions = [];
          _isSearchingSpecies = false;
        });
      }
      return;
    }

    // Βήμα 1: Άμεσος τοπικός έλεγχος (Offline)
    final localMatches = BotanicalLookupService.searchLocal(query);
    if (localMatches.isNotEmpty) {
      setState(() {
        _speciesSuggestions = localMatches;
        _isSearchingSpecies = false;
      });
      return;
    }

    // Βήμα 2: Online αναζήτηση μέσω GBIF / Wikipedia API με debounce 450ms
    setState(() {
      _isSearchingSpecies = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 450), () async {
      final onlineMatches = await BotanicalLookupService.searchOnline(query);
      if (!mounted) return;
      if (_nameController.text.trim() == query) {
        setState(() {
          _speciesSuggestions = onlineMatches;
          _isSearchingSpecies = false;
        });
      }
    });
  }

  void _onSpeciesChanged() {
    if (_ignoreSpeciesListener) return;
    if (mounted) setState(() {});

    _debounceTimer?.cancel();
    final query = _speciesController.text.trim();

    if (query.length < 3) {
      if (_speciesSuggestions.isNotEmpty || _isSearchingSpecies) {
        setState(() {
          _speciesSuggestions = [];
          _isSearchingSpecies = false;
        });
      }
      return;
    }

    setState(() {
      _isSearchingSpecies = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      final matches = await BotanicalLookupService.suggestScientificPrefix(
        query,
      );
      if (!mounted) return;
      if (_speciesController.text.trim() == query) {
        setState(() {
          _speciesSuggestions = matches;
          _isSearchingSpecies = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
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

    // Φιλτράρουμε ώστε να μην δείχνουμε πρόταση που έχει ήδη επιλεγεί
    final visibleSuggestions = _speciesSuggestions
        .where((s) => s != _speciesController.text.trim())
        .toList();

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
                  labelText: 'Κοινό Όνομα (π.χ. Πόθος)',
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
                decoration: InputDecoration(
                  labelText: 'Είδος / Βοτανικό όνομα',
                  prefixIcon: const Icon(Icons.local_florist_outlined),
                  suffixIcon: _isSearchingSpecies
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
              ),

              // Προτεινόμενες επιστημονικές ονομασίες (Chips)
              if (visibleSuggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: visibleSuggestions.map((suggestion) {
                    return ActionChip(
                      avatar: Icon(
                        Icons.auto_awesome,
                        size: 15,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      label: Text(
                        suggestion,
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onPressed: () {
                        _ignoreSpeciesListener = true;
                        setState(() {
                          _speciesController.text = suggestion;
                          _speciesSuggestions = [];
                        });
                        _ignoreSpeciesListener = false;
                      },
                    );
                  }).toList(),
                ),
              ],

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

              // Επιλογή Χώρου / Τοποθεσίας (χωρίς checkmark)
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
                    showCheckmark: false,
                    avatar: Icon(
                      loc.icon,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.primary,
                    ),
                    label: Text(loc.localizedLabel(context)),
                    selected: isSelected,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.w600 : null,
                    ),
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
