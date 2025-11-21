import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/order_models.dart';
import '../../providers/navigation_state.dart';
import '../../services/firebase_order_manager.dart';
import '../../utils/theme.dart';

class OrderDetailView extends StatefulWidget {
  final String orderId;

  const OrderDetailView({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<OrderDetailView> {
  OrderDetail? _orderDetail;
  Map<String, dynamic>? _orderData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'User not authenticated';
      });
      return;
    }

    try {
      final orderManager = FirebaseOrderManager();
      final orderData = await orderManager.fetchOrderDocument(user.uid, widget.orderId);
      
      if (orderData == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Order not found';
        });
        return;
      }

      setState(() {
        _orderData = orderData;
        _orderDetail = OrderDetail.fromMap(orderData);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load order details: ${e.toString()}';
      });
    }
  }

  void _onEditTapped() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not authenticated';
        });
        return;
      }

      final orderManager = FirebaseOrderManager();
      final orderData = await orderManager.fetchOrderDocument(user.uid, widget.orderId);
      
      if (orderData == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Order not found';
        });
        return;
      }

      final status = (orderData['status'] as String? ?? '').trim().toLowerCase();
      final step = orderData['currentStep'] as int? ?? 1;

      if (status == 'completed') {
        // Handle completed order - could open YouTube or show message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This order is already completed')),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Resume editing this order at its saved step
      final navigationState = Provider.of<NavigationState>(context, listen: false);
      navigationState.resumeOrder(widget.orderId, step.clamp(1, 6));
      navigationState.lastAppliedResumeForOrderId = widget.orderId;
      
      // Navigate back - ContentView will detect the navigation state change
      // and show the order flow at the correct step
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load order: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.blueGradient,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _onEditTapped,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            child: const Text('Done'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                )
              : _orderDetail != null && _orderData != null
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildOrderHeaderSection(),
                          const SizedBox(height: 16),
                          _buildPersonalInfoSection(_orderDetail!),
                          const SizedBox(height: 16),
                          _buildAddressInfoSection(_orderDetail!),
                          const SizedBox(height: 16),
                          _buildDeviceInfoSection(_orderDetail!),
                          const SizedBox(height: 16),
                          _buildServiceInfoSection(_orderDetail!),
                          const SizedBox(height: 16),
                          _buildBillingInfoSection(_orderDetail!),
                        ],
                      ),
                    )
                  : const Center(child: Text('No order data')),
    );
  }

  Widget _buildOrderHeaderSection() {
    final status = _orderData!['status'] as String? ?? 'pending';
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order ID',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                widget.orderId.length > 8 ? widget.orderId.substring(0, 8) : widget.orderId,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection(OrderDetail order) {
    return _buildSectionCard(
      title: 'Personal Information',
      children: [
        _buildDetailRow('Name', '${order.firstName ?? ''} ${order.lastName ?? ''}'.trim()),
        _buildDetailRow('Email', order.email ?? 'N/A'),
        if (order.phoneNumber != null && order.phoneNumber!.isNotEmpty)
          _buildDetailRow('Phone', order.phoneNumber!),
      ],
    );
  }

  Widget _buildAddressInfoSection(OrderDetail order) {
    return _buildSectionCard(
      title: 'Address Information',
      children: [
        _buildDetailRow('Street', order.street ?? 'N/A'),
        if (order.aptNumber != null && order.aptNumber!.isNotEmpty)
          _buildDetailRow('Apt/Unit', order.aptNumber!),
        _buildDetailRow('City', order.city ?? 'N/A'),
        _buildDetailRow('State', order.state ?? 'N/A'),
        _buildDetailRow('ZIP', order.zip ?? 'N/A'),
        _buildDetailRow('Country', order.country ?? 'N/A'),
      ],
    );
  }

  Widget _buildDeviceInfoSection(OrderDetail order) {
    return _buildSectionCard(
      title: 'Device Information',
      children: [
        _buildDetailRow('Brand', order.deviceBrand ?? 'N/A'),
        _buildDetailRow('Model', order.deviceModel ?? 'N/A'),
        _buildDetailRow(
          'Compatible',
          order.deviceIsCompatible == true ? 'Yes' : 'No',
        ),
        if (order.imei != null && order.imei!.isNotEmpty)
          _buildDetailRow('IMEI', order.imei!),
      ],
    );
  }

  Widget _buildServiceInfoSection(OrderDetail order) {
    return _buildSectionCard(
      title: 'Service Information',
      children: [
        _buildDetailRow('Number Type', order.numberType ?? 'N/A'),
        if (order.selectedPhoneNumber != null &&
            order.selectedPhoneNumber!.isNotEmpty)
          _buildDetailRow('Selected Number', order.selectedPhoneNumber!),
        _buildDetailRow('SIM Type', order.simType ?? 'N/A'),
        _buildDetailRow(
          'Port-in Skipped',
          order.portInSkipped == true ? 'Yes' : 'No',
        ),
      ],
    );
  }

  Widget _buildBillingInfoSection(OrderDetail order) {
    return _buildSectionCard(
      title: 'Billing Information',
      children: [
        if (order.billingDetails != null && order.billingDetails!.isNotEmpty)
          _buildDetailRow('Billing Details', order.billingDetails!),
        if (order.creditCardNumber != null &&
            order.creditCardNumber!.isNotEmpty)
          _buildDetailRow(
            'Credit Card',
            _maskCreditCard(order.creditCardNumber!),
          ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'draft':
        return Colors.grey;
      case 'processing':
        return AppTheme.mainBlue;
      default:
        return Colors.grey;
    }
  }

  String _maskCreditCard(String cardNumber) {
    if (cardNumber.length <= 4) {
      return cardNumber;
    }
    final lastFour = cardNumber.substring(cardNumber.length - 4);
    final masked = '*' * (cardNumber.length - 4);
    return '$masked$lastFour';
  }
}

