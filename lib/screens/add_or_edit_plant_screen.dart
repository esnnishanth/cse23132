import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../models/plant.dart';
import '../providers/plant_data.dart';

class AddOrEditPlantScreen extends StatefulWidget {
  const AddOrEditPlantScreen({super.key, this.plant});

  final Plant? plant;

  @override
  State<AddOrEditPlantScreen> createState() => _AddOrEditPlantScreenState();
}

class _AddOrEditPlantScreenState extends State<AddOrEditPlantScreen> {
  static const List<String> _plantTypes = <String>[
    'Indoor',
    'Outdoor',
    'Succulent',
    'Flowering',
    'Herbal',
    'Vegetable',
    'Tree',
  ];

  static const List<String> _placeholderImages = <String>[
    'https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg',
    'https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg',
    'https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _locationTagController;

  late String? _selectedType;
  late double _wateringFrequency;
  late int _imageIndex;
  late String _imageUrl;

  double? _latitude;
  double? _longitude;
  bool _isSaving = false;

  bool get _isEditing => widget.plant != null;

  @override
  void initState() {
    super.initState();

    final Plant? plant = widget.plant;

    _nameController = TextEditingController(text: plant?.name ?? '');
    _locationTagController =
        TextEditingController(text: plant?.locationTag ?? '');

    _selectedType = plant?.type;
    _wateringFrequency = (plant?.wateringFrequencyDays ?? 7).toDouble();

    _imageUrl = plant?.imageUrl ?? _placeholderImages.first;
    _imageIndex = _placeholderImages.indexOf(_imageUrl);
    if (_imageIndex < 0) {
      _imageIndex = 0;
    }

    _latitude = plant?.latitude;
    _longitude = plant?.longitude;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationTagController.dispose();
    super.dispose();
  }

  Future<void> _captureCurrentLocation() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enable location services first.')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission was denied.')),
      );
      return;
    }

    try {
      final Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      if (_locationTagController.text.trim().isEmpty) {
        _locationTagController.text = 'Current location';
      }

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS location attached.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to read location: $error')),
      );
    }
  }

  void _pickNextImage() {
    setState(() {
      _imageIndex = (_imageIndex + 1) % _placeholderImages.length;
      _imageUrl = _placeholderImages[_imageIndex];
    });
  }

  Future<void> _savePlant() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a plant type.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final PlantData plantData = context.read<PlantData>();
    final DateTime now = DateTime.now();

    final Plant payload = Plant(
      id: widget.plant?.id ?? plantData.generatePlantId(),
      name: _nameController.text.trim(),
      imageUrl: _imageUrl,
      type: _selectedType!,
      wateringFrequencyDays: _wateringFrequency.round(),
      lastWateredDate: widget.plant?.lastWateredDate ?? now,
      createdAt: widget.plant?.createdAt ?? now,
      locationTag: _locationTagController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
    );

    try {
      if (_isEditing) {
        await plantData.updatePlant(payload);
      } else {
        await plantData.addPlant(payload);
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? '${payload.name} updated.' : '${payload.name} added.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Plant' : 'Add Plant'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Plant Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.eco),
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Plant name is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                hint: const Text('Select Plant Type'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _plantTypes
                    .map(
                      (String type) => DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (String? value) {
                  setState(() {
                    _selectedType = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationTagController,
                decoration: const InputDecoration(
                  labelText: 'Location Tag (e.g., Balcony, Garden)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _captureCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Attach Current GPS Location'),
              ),
              if (_latitude != null && _longitude != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'GPS: ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) {
                            return const Icon(Icons.broken_image, size: 48);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickNextImage,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Cycle Image'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Watering Frequency: ${_wateringFrequency.round()} days',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Slider(
                value: _wateringFrequency,
                min: 1,
                max: 30,
                divisions: 29,
                label: _wateringFrequency.round().toString(),
                onChanged: (double value) {
                  setState(() {
                    _wateringFrequency = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _savePlant,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isEditing ? 'Save Changes' : 'Save Plant'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
