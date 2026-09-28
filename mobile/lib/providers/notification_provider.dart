import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  /// Fetch notifications for current user from Cloud Firestore
  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentUid = _auth.currentUser?.uid;
      Query<Map<String, dynamic>> query = _firestore.collection('notifications');

      if (currentUid != null) {
        query = query.where('userId', isEqualTo: currentUid);
      }

      final snapshot = await query.get();
      _notifications = snapshot.docs.map((doc) {
        return NotificationModel.fromJson(doc.data(), doc.id);
      }).toList();

      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _unreadCount = _notifications.where((n) => !n.isRead).length;
    } catch (e) {
      debugPrint('[NotificationProvider] Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark single notification as read
  Future<void> markAsRead(String id) async {
    try {
      await _firestore.collection('notifications').doc(id).update({'isRead': true});
      await fetchNotifications();
    } catch (e) {
      debugPrint('[NotificationProvider] Failed to mark notification read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final batch = _firestore.batch();
      for (final n in _notifications.where((element) => !element.isRead)) {
        final docRef = _firestore.collection('notifications').doc(n.id);
        batch.update(docRef, {'isRead': true});
      }
      await batch.commit();
      await fetchNotifications();
    } catch (e) {
      debugPrint('[NotificationProvider] Failed to mark all read: $e');
    }
  }
}

