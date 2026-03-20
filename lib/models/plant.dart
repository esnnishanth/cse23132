import 'package:cloud_firestore/cloud_firestore.dart';

class Plant {
  const Plant({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.type,
    required this.wateringFrequencyDays,
    required this.lastWateredDate,
    required this.createdAt,
    required this.locationTag,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String imageUrl;
  final String type;
  final int wateringFrequencyDays;
  final DateTime lastWateredDate;
  final DateTime createdAt;
  final String locationTag;
  final double? latitude;
  final double? longitude;

  DateTime get nextWateringDate =>
      lastWateredDate.add(Duration(days: wateringFrequencyDays));

  bool needsWatering({DateTime? now}) {
    final DateTime current = now ?? DateTime.now();
    return current.isAfter(nextWateringDate);
  }

  Plant copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? type,
    int? wateringFrequencyDays,
    DateTime? lastWateredDate,
    DateTime? createdAt,
    String? locationTag,
    double? latitude,
    double? longitude,
  }) {
    return Plant(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      wateringFrequencyDays: wateringFrequencyDays ?? this.wateringFrequencyDays,
      lastWateredDate: lastWateredDate ?? this.lastWateredDate,
      createdAt: createdAt ?? this.createdAt,
      locationTag: locationTag ?? this.locationTag,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'imageUrl': imageUrl,
      'type': type,
      'wateringFrequencyDays': wateringFrequencyDays,
      'lastWateredDate': Timestamp.fromDate(lastWateredDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'locationTag': locationTag,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Plant.fromDocument(DocumentSnapshot<Map<String, dynamic>> document) {
    final Map<String, dynamic> data =
        document.data() ?? <String, dynamic>{};

    return Plant(
      id: document.id,
      name: data['name'] as String? ?? 'Unnamed Plant',
      imageUrl: data['imageUrl'] as String? ??
          'https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg',
      type: data['type'] as String? ?? 'Indoor',
      wateringFrequencyDays: _toInt(data['wateringFrequencyDays'], fallback: 7),
      lastWateredDate: _toDateTime(data['lastWateredDate']),
      createdAt: _toDateTime(data['createdAt']),
      locationTag: data['locationTag'] as String? ?? '',
      latitude: _toDouble(data['latitude']),
      longitude: _toDouble(data['longitude']),
    );
  }

  static int _toInt(Object? value, {required int fallback}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  static double? _toDouble(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static DateTime _toDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
