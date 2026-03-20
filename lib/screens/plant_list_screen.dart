import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/plant.dart';
import '../providers/plant_data.dart';
import 'add_or_edit_plant_screen.dart';
import 'plant_details_screen.dart';

class PlantListScreen extends StatefulWidget {
  const PlantListScreen({super.key});

  @override
  State<PlantListScreen> createState() => _PlantListScreenState();
}

class _PlantListScreenState extends State<PlantListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _searchController.clear();
        context.read<PlantData>().setSearchQuery('');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search by name, type, or location',
                  border: InputBorder.none,
                ),
                onChanged: context.read<PlantData>().setSearchQuery,
              )
            : const Text('Plant Care Companion'),
        actions: <Widget>[
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: Consumer<PlantData>(
        builder: (BuildContext context, PlantData plantData, Widget? child) {
          final List<String> reminders = plantData.consumePendingReminders();
          if (reminders.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) {
                return;
              }
              for (final String reminder in reminders) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(reminder)),
                );
              }
            });
          }

          if (plantData.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (plantData.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  plantData.errorMessage!,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final List<Plant> plants = plantData.plants;
          if (plants.isEmpty) {
            return const Center(
              child: Text('No plants yet. Tap + to add one.'),
            );
          }

          return ListView.builder(
            itemCount: plants.length,
            itemBuilder: (BuildContext context, int index) {
              final Plant plant = plants[index];
              final bool needsWatering = plant.needsWatering();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: Hero(
                    tag: 'plant-image-${plant.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        plant.imageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (
                          BuildContext context,
                          Object error,
                          StackTrace? stackTrace,
                        ) {
                          return const SizedBox(
                            width: 56,
                            height: 56,
                            child: Icon(Icons.broken_image),
                          );
                        },
                      ),
                    ),
                  ),
                  title: Text(plant.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('${plant.type} • every ${plant.wateringFrequencyDays} days'),
                      Text(
                        plant.locationTag.isEmpty
                            ? 'Location: not tagged'
                            : 'Location: ${plant.locationTag}',
                      ),
                      if (needsWatering)
                        Text(
                          'Needs watering',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.water_drop,
                      color: needsWatering ? Colors.blue : Colors.grey,
                    ),
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
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            PlantDetailsScreen(plantId: plant.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (BuildContext context) =>
                  const AddOrEditPlantScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
