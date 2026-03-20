import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/plant_data.dart';
import 'screens/plant_list_screen.dart';
import 'services/plant_repository.dart';
import 'services/reminder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final ReminderService reminderService = ReminderService();

  runApp(
    Provider<PlantRepository>(
      create: (_) => PlantRepository(),
      child: Provider<ReminderService>.value(
        value: reminderService,
        child: ChangeNotifierProvider<PlantData>(
          create: (BuildContext context) => PlantData(
            repository: context.read<PlantRepository>(),
            reminderService: context.read<ReminderService>(),
          ),
          child: const PlantTrackerApp(),
        ),
      ),
    ),
  );
}

class PlantTrackerApp extends StatelessWidget {
  const PlantTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Plant Care Companion',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const PlantListScreen(),
    );
  }
}
