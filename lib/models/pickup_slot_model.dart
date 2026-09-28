class PickupSlotModel {
  final String id;
  final String farmerId;
  final String farmerName;
  final String farmName;
  final DateTime date;
  final String startTime; // e.g., "09:00 AM"
  final String endTime;   // e.g., "11:00 AM"
  final int totalSlots;
  final int bookedSlots;
  final bool isActive;
  final String? location;

  PickupSlotModel({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.farmName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.totalSlots,
    this.bookedSlots = 0,
    this.isActive = true,
    this.location,
  });

  int get availableSlots => totalSlots - bookedSlots;
  bool get isFull => availableSlots <= 0;

  String get dateString {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  String get timeRange => '$startTime - $endTime';

  factory PickupSlotModel.fromMap(String id, Map<String, dynamic> map) {
    return PickupSlotModel(
      id: id,
      farmerId: map['farmerId'] ?? '',
      farmerName: map['farmerName'] ?? '',
      farmName: map['farmName'] ?? '',
      date: (map['date'] as dynamic).toDate(),
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      totalSlots: map['totalSlots'] ?? 0,
      bookedSlots: map['bookedSlots'] ?? 0,
      isActive: map['isActive'] ?? true,
      location: map['location'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'farmerId': farmerId,
      'farmerName': farmerName,
      'farmName': farmName,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'totalSlots': totalSlots,
      'bookedSlots': bookedSlots,
      'isActive': isActive,
      'location': location,
    };
  }

  PickupSlotModel copyWith({
    String? id,
    String? farmerId,
    String? farmerName,
    String? farmName,
    DateTime? date,
    String? startTime,
    String? endTime,
    int? totalSlots,
    int? bookedSlots,
    bool? isActive,
    String? location,
  }) {
    return PickupSlotModel(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      farmName: farmName ?? this.farmName,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalSlots: totalSlots ?? this.totalSlots,
      bookedSlots: bookedSlots ?? this.bookedSlots,
      isActive: isActive ?? this.isActive,
      location: location ?? this.location,
    );
  }
}
