class EvSpotModel {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String chargerType; // "AC" | "DC" | "Fast Charge"
  final bool isAvailable;
  final bool isActive;
  final String openHours;
  final String operatorName;
  final List<String> photos;

  const EvSpotModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.chargerType,
    required this.isAvailable,
    required this.isActive,
    required this.openHours,
    required this.operatorName,
    required this.photos,
  });

  factory EvSpotModel.fromJson(Map<String, dynamic> json) {
    return EvSpotModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      chargerType: json['chargerType']?.toString() ?? 'AC',
      isAvailable: json['isAvailable'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      openHours: json['openHours']?.toString() ?? '',
      operatorName: json['operatorName']?.toString() ?? '',
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'chargerType': chargerType,
        'isAvailable': isAvailable,
        'isActive': isActive,
        'openHours': openHours,
        'operatorName': operatorName,
        'photos': photos,
      };
}
