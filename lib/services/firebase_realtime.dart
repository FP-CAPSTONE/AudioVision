class CurrentLocationData {
  String name = 'john';
  List<Coordinate> coordinates;

  CurrentLocationData({
    required this.name,
    required this.coordinates,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'coordinates':
          coordinates.map((coordinate) => coordinate.toJson()).toList(),
    };
  }

  factory CurrentLocationData.fromJson(Map<String, dynamic> json) {
    return CurrentLocationData(
      name: json['name'],
      coordinates: (json['coordinates'] as List<dynamic>?)
              ?.map((coordinate) => Coordinate.fromJson(coordinate))
              .toList() ??
          [],
    );
  }
}

class Coordinate {
  double longitude;
  double latitude;
  DateTime timestamp = DateTime.now();

  Coordinate({
    required this.longitude,
    required this.latitude,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'longitude': longitude,
      'latitude': latitude,
      'timestamp': timestamp.toIso8601String(), // Convert DateTime to string
    };
  }

  factory Coordinate.fromJson(Map<String, dynamic> json) {
    return Coordinate(
      longitude: json['longitude'],
      latitude: json['latitude'],
      timestamp: DateTime.parse(json['timestamp'] ?? ''),
    );
  }
}
