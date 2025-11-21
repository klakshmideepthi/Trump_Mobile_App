import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/user_registration_view_model.dart';
import '../../widgets/order_card.dart';
import '../../utils/theme.dart';
import '../../models/order_models.dart';
import '../../services/firebase_order_manager.dart';
import '../order_flow/order_detail_view.dart';

class PreviousOrdersView extends StatefulWidget {
  const PreviousOrdersView({super.key});

  @override
  State<PreviousOrdersView> createState() => _PreviousOrdersViewState();
}

class _PreviousOrdersViewState extends State<PreviousOrdersView> {
  final FirebaseOrderManager _orderManager = FirebaseOrderManager();
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Load all user orders (not just completed)
      final orders = await _orderManager.fetchUserOrders(user.uid);
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading orders: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Previous Orders'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.blueGradient,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(
                  child: Text(
                    'No previous orders',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: OrderCard(
                        order: order,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderDetailView(orderId: order.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

