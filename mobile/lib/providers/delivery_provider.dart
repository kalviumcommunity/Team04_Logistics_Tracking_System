import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import '../models/delivery_model.dart';
import '../models/user_model.dart';

class DeliveryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<DeliveryModel> _deliveries = [];
  List<UserModel> _executives = [];
  List<UserModel> _dispatchers = [];
  bool _isLoading = false;
  bool _isExecutivesLoading = false;
  bool _isDispatchersLoading = false;
  String? _error;
  String? _actionError;

  List<DeliveryModel> get deliveries => _deliveries;
  List<UserModel> get executives => _executives;
  List<UserModel> get dispatchers => _dispatchers;
  bool get isLoading => _isLoading;
  bool get isExecutivesLoading => _isExecutivesLoading;
  bool get isDispatchersLoading => _isDispatchersLoading;
  String? get error => _error;
  String? get actionError => _actionError;

  void clearError() {
    _error = null;
    _actionError = null;
    notifyListeners();
  }

  String _generateTrackingNumber() {
    final randomDigits = (100000 + Random().nextInt(900000)).toString();
    return 'DS-$randomDigits';
  }

  /// Fetch deliveries from Cloud Firestore
  Future<void> fetchDeliveries({String? status, String? executiveId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Query<Map<String, dynamic>> query = _firestore.collection('deliveries');

      if (status != null && status != 'ALL' && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status.toUpperCase());
      }

      final snapshot = await query.get();
      final docs = snapshot.docs;

      _deliveries = docs.map((doc) {
        return DeliveryModel.fromJson(doc.data(), doc.id);
      }).toList();

      // Sort client-side by createdAt if field exists
      _deliveries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('[DeliveryProvider] Error fetching deliveries: $e');
      _error = 'Failed to load deliveries from database.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch executives from Cloud Firestore
  Future<void> fetchExecutives() async {
    _isExecutivesLoading = true;
    _actionError = null;
    notifyListeners();

    try {
      final snapshot =
          await _firestore.collection('users').where('role', whereIn: [
        'DELIVERY_EXECUTIVE',
        'FIELD_EXECUTIVE',
        'EXECUTIVE',
      ]).get();

      _executives = snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data(), doc.id))
          .toList();

      debugPrint('[DeliveryProvider] Executives found: ${_executives.length}');
    } catch (e) {
      debugPrint('[DeliveryProvider] Error fetching executives: $e');
      _actionError = 'Unable to load Field Executives. Please try again.';
    } finally {
      _isExecutivesLoading = false;
      notifyListeners();
    }
  }

  /// Fetch dispatchers from Cloud Firestore
  Future<void> fetchDispatchers() async {
    _isDispatchersLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'DISPATCHER')
          .get();
      _dispatchers = snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('[DeliveryProvider] Error fetching dispatchers: $e');
    } finally {
      _isDispatchersLoading = false;
      notifyListeners();
    }
  }

  /// Get details of a single delivery
  Future<DeliveryModel?> getDeliveryDetails(String id) async {
    final queryStr = id.trim();
    if (queryStr.isEmpty) return null;
    try {
      // 1. Direct document ID lookup
      final doc = await _firestore.collection('deliveries').doc(queryStr).get();
      if (doc.exists && doc.data() != null) {
        return DeliveryModel.fromJson(doc.data()!, doc.id);
      }
      // 2. Exact or uppercase trackingNumber lookup
      final query = await _firestore
          .collection('deliveries')
          .where('trackingNumber', isEqualTo: queryStr.toUpperCase())
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return DeliveryModel.fromJson(
            query.docs.first.data(), query.docs.first.id);
      }
      // 3. Exact trackingNumber lookup as-is
      final queryAsIs = await _firestore
          .collection('deliveries')
          .where('trackingNumber', isEqualTo: queryStr)
          .limit(1)
          .get();
      if (queryAsIs.docs.isNotEmpty) {
        return DeliveryModel.fromJson(
            queryAsIs.docs.first.data(), queryAsIs.docs.first.id);
      }
      // 4. Check locally cached deliveries list
      final localMatch = _deliveries
          .where((d) =>
              d.id.toLowerCase() == queryStr.toLowerCase() ||
              d.trackingNumber.toLowerCase() == queryStr.toLowerCase())
          .firstOrNull;
      return localMatch;
    } catch (e) {
      debugPrint('[DeliveryProvider] Error getting delivery details: $e');
      _actionError = 'Error retrieving delivery details.';
      return null;
    }
  }

  /// Create a new delivery order in Firestore
  Future<bool> createDelivery(Map<String, dynamic> data) async {
    _actionError = null;
    try {
      final trackingNumber = _generateTrackingNumber();
      final nowStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      final status = (data['assignedExecutiveId'] != null &&
              data['assignedExecutiveId'].toString().isNotEmpty)
          ? 'ASSIGNED'
          : 'PENDING';

      // Find assigned executive object if present
      UserModel? assignedExec;
      if (data['assignedExecutiveId'] != null) {
        final execId = data['assignedExecutiveId'].toString();
        final execMatch = _executives.where((e) => e.id == execId);
        if (execMatch.isNotEmpty) {
          assignedExec = execMatch.first;
        } else {
          final execDoc =
              await _firestore.collection('users').doc(execId).get();
          if (execDoc.exists && execDoc.data() != null) {
            assignedExec = UserModel.fromJson(execDoc.data()!, execDoc.id);
          }
        }
      }

      final initialHistory = [
        {
          'id': 'hist_0',
          'status': status,
          'remarks': 'Delivery created by Dispatcher',
          'location': data['city'] ?? 'Dispatch Center',
          'createdAt': nowStr,
        }
      ];

      final recipientName =
          (data['customerName'] as String?)?.trim() ?? 'Customer';
      final customerMap = {
        'id': 'cust_${DateTime.now().millisecondsSinceEpoch}',
        'fullName': recipientName,
        'phone': data['customerPhone'] ?? '',
        'email': data['customerEmail'] ?? '',
        'address': data['deliveryAddress'] ?? '',
        'city': data['city'] ?? '',
      };

      final docData = <String, dynamic>{
        'trackingNumber': trackingNumber,
        'recipientName': recipientName,
        'pickupAddress': data['pickupAddress'] ?? '',
        'deliveryAddress': data['deliveryAddress'] ?? '',
        'city': data['city'] ?? '',
        'deliveryDate': data['deliveryDate'] ?? '',
        'deliveryTime': data['deliveryTime'] ?? '',
        'remarks': data['remarks'] ?? '',
        'status': status,
        'eta': data['eta'] ?? '45 mins',
        'customer': customerMap,
        'assignedTo': assignedExec?.id,
        'assignedExecutive': assignedExec?.toJson(),
        'assignedDispatcher': data['createdByDispatcherId'] ??
            (data['createdBy'] is Map ? data['createdBy']['id'] : null),
        'createdBy': data['createdBy'],
        'statusHistory': initialHistory,
        'createdAt': nowStr,
        'updatedAt': nowStr,
        'timestamp': FieldValue.serverTimestamp(),
      };
      if (data['latitude'] != null) docData['latitude'] = data['latitude'];
      if (data['longitude'] != null) docData['longitude'] = data['longitude'];

      final docRef = await _firestore.collection('deliveries').add(docData);

      // Also create notification if assigned
      if (assignedExec != null) {
        await _firestore.collection('notifications').add({
          'userId': assignedExec.id,
          'title': 'New Delivery Assigned 📦',
          'message':
              'Delivery $trackingNumber to $recipientName assigned to you.',
          'type': 'ASSIGNMENT',
          'isRead': false,
          'deliveryId': docRef.id,
          'createdAt': nowStr,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      await fetchDeliveries();
      return true;
    } catch (e) {
      debugPrint('[DeliveryProvider] Error creating delivery: $e');
      _actionError = 'Failed to create delivery.';
      notifyListeners();
      return false;
    }
  }

  /// Update existing delivery
  Future<bool> updateDelivery(String id, Map<String, dynamic> data) async {
    _actionError = null;
    try {
      final updateData = Map<String, dynamic>.from(data);
      updateData['updatedAt'] =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      await _firestore.collection('deliveries').doc(id).update(updateData);
      await fetchDeliveries();
      return true;
    } catch (e) {
      debugPrint('[DeliveryProvider] Error updating delivery: $e');
      _actionError = 'Failed to update delivery.';
      notifyListeners();
      return false;
    }
  }

  /// Assign an executive to a delivery
  Future<bool> assignExecutive(String deliveryId, String executiveId,
      {String? dispatcherId}) async {
    _actionError = null;
    debugPrint('[Assign] Delivery ID: $deliveryId');
    debugPrint(
        '[Assign] Dispatcher UID: ${dispatcherId ?? FirebaseAuth.instance.currentUser?.uid ?? 'unknown'}');
    debugPrint('[Assign] Executive UID: $executiveId');
    debugPrint('[Assign] Starting assignment...');

    try {
      UserModel? assignedExec;
      final match = _executives.where((e) => e.id == executiveId);
      if (match.isNotEmpty) {
        assignedExec = match.first;
      } else {
        final doc = await _firestore.collection('users').doc(executiveId).get();
        if (doc.exists && doc.data() != null) {
          assignedExec = UserModel.fromJson(doc.data()!, doc.id);
        }
      }

      final currentDispatcherUid =
          dispatcherId ?? FirebaseAuth.instance.currentUser?.uid;

      final nowStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      final historyEntry = {
        'id': 'hist_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'ASSIGNED',
        'remarks': 'Assigned to ${assignedExec?.fullName ?? 'Field Executive'}',
        'createdAt': nowStr,
      };

      final updateData = <String, dynamic>{
        'status': 'ASSIGNED',
        'assignedTo': executiveId,
        'assignedExecutive': assignedExec?.toJson(),
        'assignedDispatcher': currentDispatcherUid,
        'updatedAt': nowStr,
        'timestamp': FieldValue.serverTimestamp(),
        'statusHistory': FieldValue.arrayUnion([historyEntry]),
      };

      if (currentDispatcherUid != null && currentDispatcherUid.isNotEmpty) {
        updateData['assignedDispatcher'] = currentDispatcherUid;
      }

      await _firestore
          .collection('deliveries')
          .doc(deliveryId)
          .update(updateData);
      debugPrint(
          '[Assign] Firestore update successful for delivery $deliveryId');

      if (assignedExec != null) {
        await _firestore.collection('notifications').add({
          'userId': assignedExec.id,
          'title': 'Delivery Assigned 📦',
          'message': 'A delivery has been assigned to you.',
          'type': 'ASSIGNMENT',
          'isRead': false,
          'deliveryId': deliveryId,
          'createdAt': nowStr,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      await fetchDeliveries();
      return true;
    } catch (e) {
      debugPrint('[DeliveryProvider] Error assigning executive: $e');
      _actionError = 'Unable to assign delivery. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Reassign executive
  Future<bool> reassignExecutive(String deliveryId, String executiveId,
      {String? dispatcherId}) async {
    return assignExecutive(deliveryId, executiveId, dispatcherId: dispatcherId);
  }

  /// Cancel delivery
  Future<bool> cancelDelivery(String deliveryId) async {
    _actionError = null;
    try {
      final nowStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      final historyEntry = {
        'id': 'hist_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'CANCELLED',
        'remarks': 'Cancelled by Dispatcher',
        'createdAt': nowStr,
      };

      await _firestore.collection('deliveries').doc(deliveryId).update({
        'status': 'CANCELLED',
        'updatedAt': nowStr,
        'statusHistory': FieldValue.arrayUnion([historyEntry]),
      });

      await fetchDeliveries();
      return true;
    } catch (e) {
      debugPrint('[DeliveryProvider] Error cancelling delivery: $e');
      _actionError = 'Failed to cancel delivery.';
      notifyListeners();
      return false;
    }
  }

  /// Update delivery status (IN_TRANSIT, DELIVERED, etc.)
  Future<bool> updateStatus(String deliveryId, String status,
      {String? remarks, String? location, String? proofImageUrl}) async {
    _actionError = null;
    try {
      final nowStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      final historyEntry = {
        'id': 'hist_${DateTime.now().millisecondsSinceEpoch}',
        'status': status.toUpperCase(),
        'remarks': remarks ?? 'Status updated to $status',
        'location': location ?? 'GPS Location',
        'createdAt': nowStr,
      };

      final updateMap = <String, dynamic>{
        'status': status.toUpperCase(),
        'updatedAt': nowStr,
        'statusHistory': FieldValue.arrayUnion([historyEntry]),
      };

      if (proofImageUrl != null && proofImageUrl.isNotEmpty) {
        updateMap['proofImageUrl'] = proofImageUrl;
        updateMap['deliveryProofUrl'] = proofImageUrl;
      }
      if (location != null && location.isNotEmpty) {
        updateMap['currentLocation'] = location;
      }

      await _firestore
          .collection('deliveries')
          .doc(deliveryId)
          .update(updateMap);
      await fetchDeliveries();
      return true;
    } catch (e) {
      debugPrint('[DeliveryProvider] Error updating status: $e');
      _actionError = 'Error updating status.';
      notifyListeners();
      return false;
    }
  }

  /// Submit delivery failure
  Future<bool> submitFailure(String deliveryId, String reason, String remarks,
      {String? proofImageUrl}) async {
    _actionError = null;
    try {
      final nowStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      final historyEntry = {
        'id': 'hist_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'FAILED',
        'remarks': 'Delivery failed: $reason - $remarks',
        'createdAt': nowStr,
      };

      final updateMap = <String, dynamic>{
        'status': 'FAILED',
        'failureReason': reason,
        'failureRemarks': remarks,
        'updatedAt': nowStr,
        'statusHistory': FieldValue.arrayUnion([historyEntry]),
      };
      if (proofImageUrl != null && proofImageUrl.isNotEmpty) {
        updateMap['proofImageUrl'] = proofImageUrl;
        updateMap['deliveryProofUrl'] = proofImageUrl;
      }

      await _firestore
          .collection('deliveries')
          .doc(deliveryId)
          .update(updateMap);

      // Create Escalation entry
      await _firestore.collection('escalations').add({
        'deliveryId': deliveryId,
        'reason': reason,
        'remarks': remarks,
        'status': 'OPEN',
        'priority': 'HIGH',
        'proofImageUrl': proofImageUrl,
        'createdAt': nowStr,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await fetchDeliveries();
      return true;
    } catch (e) {
      debugPrint('[DeliveryProvider] Error submitting failure: $e');
      _actionError = 'Failed to submit failure report.';
      notifyListeners();
      return false;
    }
  }

  /// Upload image bytes to Firebase Storage and return public download URL
  Future<String?> uploadImageBytes({
    required String storagePath,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    try {
      final ref = _storage.ref().child(storagePath);
      final metadata = SettableMetadata(contentType: contentType);
      final uploadTask = await ref.putData(bytes, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('[DeliveryProvider] Firebase Storage upload error: $e');
      return null;
    }
  }
}
