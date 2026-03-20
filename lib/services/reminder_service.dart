import '../models/plant.dart';

class ReminderService {
  final Map<String, DateTime> _lastReminderDate = <String, DateTime>{};

  List<String> collectDueReminderMessages(List<Plant> plants) {
    final DateTime now = DateTime.now();
    final List<String> messages = <String>[];

    for (final Plant plant in plants) {
      if (!plant.needsWatering(now: now)) {
        continue;
      }

      final DateTime? lastReminder = _lastReminderDate[plant.id];
      if (lastReminder != null && _isSameDay(lastReminder, now)) {
        continue;
      }

      messages.add('${plant.name} needs watering today.');
      _lastReminderDate[plant.id] = now;
    }

    return messages;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
