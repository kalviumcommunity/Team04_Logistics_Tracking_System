import 'delivery_model.dart';
import 'user_model.dart';

class EscalationModel {
  final String id;
  final String status; // OPEN, IN_PROGRESS, RESOLVED
  final String priority;
  final String? resolutionNotes;
  final DeliveryModel? delivery;
  final String? reason;
  final String? remarks;
  final UserModel? reporter;
  final String createdAt;

  EscalationModel({
    required this.id,
    required this.status,
    required this.priority,
    this.resolutionNotes,
    this.delivery,
    this.reason,
    this.remarks,
    this.reporter,
    required this.createdAt,
  });

  factory EscalationModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    final failureReport = json['failureReport'];
    return EscalationModel(
      id: docId ?? json['id'] ?? '',
      status: json['status'] ?? 'OPEN',
      priority: json['priority'] ?? 'HIGH',
      resolutionNotes: json['resolutionNotes'],
      delivery: json['delivery'] != null
          ? DeliveryModel.fromJson(json['delivery'] as Map<String, dynamic>)
          : null,
      reason: json['reason'] ?? (failureReport != null ? failureReport['reason'] : null),
      remarks: json['remarks'] ?? (failureReport != null ? failureReport['remarks'] : null),
      reporter: json['reporter'] != null
          ? UserModel.fromJson(json['reporter'] as Map<String, dynamic>)
          : (failureReport != null && failureReport['executive'] != null
              ? UserModel.fromJson(failureReport['executive'] as Map<String, dynamic>)
              : null),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}
