import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/plant.dart';
import '../providers/plant_data.dart';
import '../widgets/plant_detail_row.dart';
import 'add_or_edit_plant_screen.dart';

class PlantDetailsScreen extends StatelessWidget {
  const PlantDetailsScreen({super.key, required this.plantId});

  final String plantId;

  Future<void> _confirmDelete(
    BuildContext context,
    PlantData plantData,
    Plant plant,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Plant'),
          content: Text('Delete ${plant.name}? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await plantData.deletePlant(plant.id);
      if (!context.mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${plant.name} deleted.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlantData>(
      builder: (BuildContext context, PlantData plantData, Widget? child) {
        final Plant? plant = plantData.findById(plantId);
        if (plant == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Plant Details')),
            body: const Center(child: Text('Plant not found.')),
          );
        }

        final bool needsWatering = plant.needsWatering();

        return Scaffold(
          appBar: AppBar(
            title: Text(plant.name),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) =>
                          AddOrEditPlantScreen(plant: plant),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: plantData.isWriting
                    ? null
                    : () => _confirmDelete(context, plantData, plant),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Hero(
                  tag: 'plant-image-${plant.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      plant.imageUrl,
                      height: 240,
                      fit: BoxFit.cover,
                      errorBuilder: (
                        BuildContext context,
                        Object error,
                        StackTrace? stackTrace,
                      ) {
                        return const SizedBox(
                          height: 240,
                          child: Center(child: Icon(Icons.broken_image)),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: <Widget>[
                        PlantDetailRow(
                          icon: Icons.category,
                          label: 'Type',
                          value: plant.type,
                        ),
                        const Divider(),
                        PlantDetailRow(
                          icon: Icons.calendar_today,
                          label: 'Watering Frequency',
                          value: '${plant.wateringFrequencyDays} days',
                        ),
                        const Divider(),
                        PlantDetailRow(
                          icon: Icons.opacity,
                          label: 'Last Watered',
                          value: plant.lastWateredDate
                              .toLocal()
                              .toString()
                              .split(' ')[0],
                        ),
                        const Divider(),
                        PlantDetailRow(
                          icon: Icons.place,
                          label: 'Location Tag',
                          value: plant.locationTag.isEmpty
                              ? 'Not set'
                              : plant.locationTag,
                        ),
                        if (plant.latitude != null && plant.longitude != null)
                          Column(
                            children: <Widget>[
                              const Divider(),
                              PlantDetailRow(
                                icon: Icons.gps_fixed,
                                label: 'GPS Coordinates',
                                value:
                                    '${plant.latitude!.toStringAsFixed(5)}, ${plant.longitude!.toStringAsFixed(5)}',
                              ),
                            ],
                          ),
                        if (needsWatering)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.warning, color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Needs watering now.',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: plantData.isWriting
                      ? null
                      : () async {
                          try {
                            await plantData.markPlantAsWatered(plant);
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${plant.name} marked as watered.'),
                              ),
                            );
                          } catch (error) {
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Update failed: $error')),
                            );
                          }
                        },
                  icon: const Icon(Icons.water_drop),
                  label: const Text('Mark as Watered'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: needsWatering
                        ? Theme.of(context).colorScheme.secondary
                        : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
