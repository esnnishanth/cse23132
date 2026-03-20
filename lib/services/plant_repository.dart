import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/plant.dart';

class PlantRepository {
  PlantRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _plantsCollection =>
      _firestore.collection('plants');

  String newPlantId() {
    return _plantsCollection.doc().id;
  }

  Stream<List<Plant>> watchPlants() {
    return _plantsCollection.snapshots().map(
      (QuerySnapshot<Map<String, dynamic>> snapshot) {
        final List<Plant> plants = snapshot.docs
            .map((QueryDocumentSnapshot<Map<String, dynamic>> document) {
          return Plant.fromDocument(document);
        }).toList();

        plants.sort(
          (Plant a, Plant b) =>
              a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        return plants;
      },
    );
  }

  Future<void> addPlant(Plant plant) async {
    await _plantsCollection.doc(plant.id).set(plant.toMap());
  }

  Future<void> updatePlant(Plant plant) async {
    await _plantsCollection.doc(plant.id).set(plant.toMap());
  }

  Future<void> deletePlant(String plantId) async {
    await _plantsCollection.doc(plantId).delete();
  }
}
