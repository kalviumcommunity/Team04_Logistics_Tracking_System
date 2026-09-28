import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/escalation_model.dart';
import '../models/delivery_model.dart';

class EscalationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<EscalationModel> _escalations = [];
  bool _isLoading = false;
  String? _error;

  List<EscalationModel> get escalations => _escalations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch escalations from Cloud Firestore
  Future<void> fetchEscalations({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Query<Map<String, dynamic>> query = _firestore.collection('escalations');

      if (status != null && status != 'ALL' && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status.toUpperCase());
      }

      final snapshot = await query.get();
      final docs = snapshot.docs;

      final List<EscalationModel> list = [];
      for (final doc in docs) {
        final data = doc.data();
        DeliveryModel? deliveryObj;

        // Populate delivery details if deliveryId is present
        final deliveryId = data['deliveryId'] as String?;
        if (deliveryId != null && deliveryId.isNotEmpty) {
          try {
            final delDoc = await _firestore.collection('deliveries').doc(deliveryId).get();
            if (delDoc.exists && delDoc.data() != null) {
              deliveryObj = DeliveryModel.fromJson(delDoc.data()!, delDoc.id);
            }
          } catch (_) {}
        }

        final mergedData = Map<String, dynamic>.from(data);
        if (deliveryObj != null) {
          mergedData['delivery'] = deliveryObj.toJson();
        }

        list.add(EscalationModel.fromJson(mergedData, doc.id));
      }

      _escalations = list;
      _escalations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('[EscalationProvider] Error fetching escalations: $e');
      _error = 'Failed to load escalations.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update resolution / status for an escalation
  Future<bool> updateEscalation(String id, String status, String notes) async {
    try {
      await _firestore.collection('escalations').doc(id).update({
        'status': status.toUpperCase(),
        'resolutionNotes': notes,
        'resolvedAt': FieldValue.serverTimestamp(),
      });
      await fetchEscalations();
      return true;
    } catch (e) {
      debugPrint('[EscalationProvider] Error updating escalation: $e');
      return false;
    }
  }
}

