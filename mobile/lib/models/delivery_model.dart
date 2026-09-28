import 'customer_model.dart';
import 'user_model.dart';

class DeliveryStatusHistoryModel {
  final String id;
  final String status;
  final String? remarks;
  final String? location;
  final String createdAt;
  final UserModel? updatedBy;

  DeliveryStatusHistoryModel({
    required this.id,
    required this.status,
    this.remarks,
    this.location,
    required this.createdAt,
    this.updatedBy,
  });

  factory DeliveryStatusHistoryModel.fromJson(Map<String, dynamic> json) {
    return DeliveryStatusHistoryModel(
      id: json['id'] ?? '',
      status: json['status'] ?? '',
      remarks: json['remarks'],
      location: json['location'],
      createdAt: json['createdAt'] ?? '',
      updatedBy: json['updatedBy'] != null
          ? UserModel.fromJson(json['updatedBy'])
          : null,
    );
  }
}

class DeliveryModel {
  final String id;
  final String trackingNumber;
  final String pickupAddress;
  final String deliveryAddress;
  final String city;
  final String deliveryDate;
  final String deliveryTime;
  final String? remarks;
  final String
      status; // PENDING, ASSIGNED, IN_TRANSIT, DELIVERED, FAILED, CANCELLED
  final String? eta;
  final String? proofImageUrl;
  final String? deliveryProofUrl;
  final String? recipientName;
  final String? assignedTo;
  final String? assignedDispatcher;
  final String? failureReason;
  final double? latitude;
  final double? longitude;
  final String? currentLocation;
  final String? updatedAt;
  final CustomerModel? customer;
  final UserModel? assignedExecutive;
  final UserModel? createdBy;
  final List<DeliveryStatusHistoryModel>? statusHistory;
  final String createdAt;

  DeliveryModel({
    required this.id,
    required this.trackingNumber,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.city,
    required this.deliveryDate,
    required this.deliveryTime,
    this.remarks,
    required this.status,
    this.eta,
    this.proofImageUrl,
    this.deliveryProofUrl,
    this.recipientName,
    this.assignedTo,
    this.assignedDispatcher,
    this.failureReason,
    this.latitude,
    this.longitude,
    this.currentLocation,
    this.updatedAt,
    this.customer,
    this.assignedExecutive,
    this.createdBy,
    this.statusHistory,
    required this.createdAt,
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    List<DeliveryStatusHistoryModel>? history;
    if (json['statusHistory'] is List) {
      history = (json['statusHistory'] as List)
          .map((item) => DeliveryStatusHistoryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    String createdAtStr = '';
    if (json['createdAt'] != null) {
      if (json['createdAt'] is String) {
        createdAtStr = json['createdAt'];
      } else if (json['createdAt'].toString().isNotEmpty) {
        createdAtStr = json['createdAt'].toString();
      }
    }

    final proof = (json['deliveryProofUrl'] as String?) ?? (json['proofImageUrl'] as String?);
    final recipient = (json['recipientName'] as String?) ??
        (json['customer'] is Map ? (json['customer']['fullName'] as String?) : null);
    final assignedToId = (json['assignedTo'] as String?) ??
        (json['assignedExecutiveId'] as String?) ??
        (json['assignedExecutive'] is Map ? (json['assignedExecutive']['id'] as String?) : null);
    final assignedDispId = (json['assignedDispatcher'] as String?) ??
        (json['dispatcherId'] as String?) ??
        (json['createdBy'] is Map ? (json['createdBy']['id'] as String?) : null);

    double? lat;
    if (json['latitude'] != null) {
      lat = (json['latitude'] as num).toDouble();
    }
    double? lng;
    if (json['longitude'] != null) {
      lng = (json['longitude'] as num).toDouble();
    }

    return DeliveryModel(
      id: docId ?? json['id'] ?? '',
      trackingNumber: json['trackingNumber'] ?? '',
      pickupAddress: json['pickupAddress'] ?? '',
      deliveryAddress: json['deliveryAddress'] ?? '',
      city: json['city'] ?? '',
      deliveryDate: json['deliveryDate'] ?? '',
      deliveryTime: json['deliveryTime'] ?? '',
      remarks: json['remarks'],
      status: json['status'] ?? 'PENDING',
      eta: json['eta'],
      proofImageUrl: proof,
      deliveryProofUrl: proof,
      recipientName: recipient,
      assignedTo: assignedToId,
      assignedDispatcher: assignedDispId,
      failureReason: json['failureReason'] as String?,
      latitude: lat,
      longitude: lng,
      currentLocation: (json['currentLocation'] as String?) ?? (json['location'] as String?),
      updatedAt: json['updatedAt']?.toString(),
      customer: json['customer'] != null && json['customer'] is Map
          ? CustomerModel.fromJson(Map<String, dynamic>.from(json['customer'] as Map))
          : ((json['customerPhone'] != null || json['recipientPhone'] != null || json['customerName'] != null || recipient != null)
              ? CustomerModel(
                  id: '',
                  fullName: recipient ?? (json['customerName'] as String?) ?? '',
                  email: (json['customerEmail'] ?? json['recipientEmail']) as String?,
                  phone: (json['customerPhone'] ?? json['recipientPhone'] ?? json['phone'] ?? '') as String,
                  address: (json['deliveryAddress'] ?? '') as String,
                  city: (json['city'] ?? '') as String,
                )
              : null),
      assignedExecutive: json['assignedExecutive'] != null
          ? UserModel.fromJson(json['assignedExecutive'] as Map<String, dynamic>)
          : null,
      createdBy: json['createdBy'] != null
          ? UserModel.fromJson(json['createdBy'] as Map<String, dynamic>)
          : null,
      statusHistory: history,
      createdAt: createdAtStr,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trackingNumber': trackingNumber,
      'pickupAddress': pickupAddress,
      'deliveryAddress': deliveryAddress,
      'city': city,
      'deliveryDate': deliveryDate,
      'deliveryTime': deliveryTime,
      'remarks': remarks,
      'status': status,
      'eta': eta,
      'proofImageUrl': proofImageUrl ?? deliveryProofUrl,
      'deliveryProofUrl': deliveryProofUrl ?? proofImageUrl,
      'recipientName': recipientName ?? customer?.fullName,
      'assignedTo': assignedTo ?? assignedExecutive?.id,
      'assignedDispatcher': assignedDispatcher ?? createdBy?.id,
      'failureReason': failureReason,
      'latitude': latitude,
      'longitude': longitude,
      'currentLocation': currentLocation,
      'updatedAt': updatedAt,
      'customer': customer?.toJson(),
      'assignedExecutive': assignedExecutive?.toJson(),
      'createdBy': createdBy?.toJson(),
      'createdAt': createdAt,
    };
  }
}
