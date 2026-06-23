class AgentModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String city;

  AgentModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.city,
  });

  factory AgentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AgentModel(
      id: documentId,
      name: map['name'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      city: map['city'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
    };
  }
}