import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_models.dart' as models;
import 'firebase_manager.dart';

class FirebaseOrderManager {
  static final FirebaseOrderManager _instance = FirebaseOrderManager._internal();
  factory FirebaseOrderManager() => _instance;
  FirebaseOrderManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseManager _firebaseManager = FirebaseManager();

  Future<void> saveStepProgress({
    required String userId,
    required String orderId,
    required int step,
    Map<String, dynamic> data = const {},
  }) async {
    await _firebaseManager.updateOrder(userId, orderId, {
      'currentStep': step,
      'status': 'pending',
      ...data,
    });
  }

  Future<void> markOrderCompleted(String userId, String orderId) async {
    await _firebaseManager.updateOrder(userId, orderId, {
      'status': 'completed',
      'orderCompleted': true,
      'currentStep': 6,
    });
  }

  Future<void> markOrderPendingPortIn(String userId, String orderId) async {
    await _firebaseManager.updateOrder(userId, orderId, {
      'status': 'pending_port_in',
      'currentStep': 5,
    });
  }

  Future<Map<String, String>?> fetchLatestIncompleteOrder(String userId) async {
    try {
      // Fetch all pending and pending_port_in orders and sort in memory to avoid requiring a composite index
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('orders')
          .where('status', whereIn: ['pending', 'pending_port_in'])
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      // Sort by updatedAt in memory (descending) and get the latest one
      final sortedDocs = querySnapshot.docs.toList()
        ..sort((a, b) {
          final aUpdated = a.data()['updatedAt'] as Timestamp?;
          final bUpdated = b.data()['updatedAt'] as Timestamp?;
          if (aUpdated == null && bUpdated == null) return 0;
          if (aUpdated == null) return 1;
          if (bUpdated == null) return -1;
          return bUpdated.compareTo(aUpdated);
        });

      final doc = sortedDocs.first;
      final data = doc.data();
      return {
        'orderId': doc.id,
        'currentStep': (data['currentStep'] ?? 1).toString(),
      };
    } catch (e) {
      return null;
    }
  }

  Future<List<models.Order>> fetchUserOrders(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('orders')
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return models.Order(
          id: doc.id,
          userId: userId,
          planName: data['planName'] ?? '',
          amount: (data['amount'] ?? 0).toDouble(),
          orderDate: (data['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          status: models.OrderStatus.values.firstWhere(
            (e) => e.name == (data['status'] ?? 'pending'),
            orElse: () => models.OrderStatus.pending,
          ),
          billingCompleted: data['billingCompleted'] ?? false,
          phoneNumber: data['phoneNumber'],
          simType: data['simType'] ?? '',
          currentStep: data['currentStep'],
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchOrderDocument(String userId, String orderId) async {
    return await _firebaseManager.getOrder(userId, orderId);
  }

  Future<List<models.Order>> fetchCompletedOrders(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('orders')
          .where('status', isEqualTo: 'completed')
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();

        // Get plan name and amount from order data
        final planName = data['planName'] ?? '';
        double amount;
        if (data['planPrice'] != null) {
          if (data['planPrice'] is int) {
            amount = (data['planPrice'] as int).toDouble();
          } else if (data['planPrice'] is double) {
            amount = data['planPrice'] as double;
          } else {
            amount = (data['amount'] ?? 0).toDouble();
          }
        } else {
          amount = (data['amount'] ?? 0).toDouble();
        }

        return models.Order(
          id: doc.id,
          userId: userId,
          planName: planName,
          amount: amount,
          orderDate: (data['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          status: models.OrderStatus.values.firstWhere(
            (e) => e.name == (data['status'] ?? 'pending'),
            orElse: () => models.OrderStatus.pending,
          ),
          billingCompleted: data['billingCompleted'] ?? false,
          phoneNumber: data['phoneNumber']?.toString(),
          simType: data['simType']?.toString() ?? '',
          currentStep: data['currentStep'] as int?,
        );
      }).toList();
    } catch (e) {
      print('DEBUG: Error fetching completed orders: $e');
      return [];
    }
  }

  // Alternative method to fetch orders by multiple statuses
  Future<List<models.Order>> fetchOrdersByStatus(
    String userId,
    List<models.OrderStatus> statuses,
  ) async {
    try {
      final statusStrings = statuses.map((e) => e.name).toList();

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('orders')
          .where('status', whereIn: statusStrings)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();

        // Get plan name and amount from order data
        final planName = data['planName'] ?? '';
        double amount;
        if (data['planPrice'] != null) {
          if (data['planPrice'] is int) {
            amount = (data['planPrice'] as int).toDouble();
          } else if (data['planPrice'] is double) {
            amount = data['planPrice'] as double;
          } else {
            amount = (data['amount'] ?? 0).toDouble();
          }
        } else {
          amount = (data['amount'] ?? 0).toDouble();
        }

        return models.Order(
          id: doc.id,
          userId: userId,
          planName: planName,
          amount: amount,
          orderDate: (data['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          status: models.OrderStatus.values.firstWhere(
            (e) => e.name == (data['status'] ?? 'pending'),
            orElse: () => models.OrderStatus.pending,
          ),
          billingCompleted: data['billingCompleted'] ?? false,
          phoneNumber: data['phoneNumber']?.toString(),
          simType: data['simType']?.toString() ?? '',
          currentStep: data['currentStep'] as int?,
        );
      }).toList();
    } catch (e) {
      print('DEBUG: Error fetching orders by status: $e');
      return [];
    }
  }

  /// Cancel an order by setting its status to "draft"
  Future<bool> cancelOrder(String userId, String orderId) async {
    print('DEBUG: FirebaseOrderManager.cancelOrder called with orderId: $orderId');

    try {
      await _firebaseManager.updateOrder(userId, orderId, {
        'status': 'draft',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('DEBUG: FirebaseOrderManager - Successfully cancelled order $orderId');
      return true;
    } catch (e) {
      print('DEBUG: FirebaseOrderManager - Failed to cancel order: $e');
      return false;
    }
  }

  /// Delete an order
  Future<bool> deleteOrder(String userId, String orderId) async {
    print('DEBUG: FirebaseOrderManager.deleteOrder called with orderId: $orderId');

    try {
      await _firebaseManager.deleteOrder(userId, orderId);
      print('DEBUG: FirebaseOrderManager - Successfully deleted order $orderId');
      return true;
    } catch (e) {
      print('DEBUG: FirebaseOrderManager - Failed to delete order: $e');
      return false;
    }
  }
}

