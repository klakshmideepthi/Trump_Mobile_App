import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/user_registration_view_model.dart';
import '../../services/notification_service.dart';
import '../../utils/theme.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _isLoading = true;
  bool _notificationsEnabled = false;
  bool _isUpdatingNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    final notificationService = NotificationService();
    final enabled = await notificationService.areNotificationsEnabled();
    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    if (_isUpdatingNotifications) return;

    setState(() {
      _isUpdatingNotifications = true;
    });

    try {
      final notificationService = NotificationService();
      
      if (value) {
        // Enable notifications
        final success = await notificationService.enableNotifications();
        if (mounted) {
          setState(() {
            _notificationsEnabled = success;
          });
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notifications enabled'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to enable notifications'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Disable notifications
        await notificationService.disableNotifications();
        if (mounted) {
          setState(() {
            _notificationsEnabled = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notifications disabled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingNotifications = false;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    
    // Load user data if not already loaded
    if (viewModel.userId == null || 
        (viewModel.firstName.isEmpty && viewModel.lastName.isEmpty && viewModel.phoneNumber.isEmpty)) {
      await viewModel.loadUserData();
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.blueGradient,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Consumer<UserRegistrationViewModel>(
              builder: (context, viewModel, _) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Account Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildInfoRow('First Name', viewModel.firstName.isNotEmpty ? viewModel.firstName : 'N/A'),
                              _buildInfoRow('Last Name', viewModel.lastName.isNotEmpty ? viewModel.lastName : 'N/A'),
                              _buildInfoRow('Mobile Number', viewModel.phoneNumber.isNotEmpty ? viewModel.phoneNumber : 'N/A'),
                              _buildInfoRow('Email', user?.email ?? 'N/A'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Notification Settings',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Enable Notifications',
                                      style: TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  _isUpdatingNotifications
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Switch(
                                          value: _notificationsEnabled,
                                          onChanged: _toggleNotifications,
                                        ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Show shipping address if available
                      if (viewModel.street.isNotEmpty || 
                          viewModel.city.isNotEmpty || 
                          viewModel.zip.isNotEmpty ||
                          viewModel.state.isNotEmpty)
                        ...[
                          const SizedBox(height: 24),
                          Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Shipping Address',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (viewModel.street.isNotEmpty)
                                    _buildInfoRow('Street', viewModel.street),
                                  if (viewModel.aptNumber.isNotEmpty)
                                    _buildInfoRow('Apt/Unit', viewModel.aptNumber),
                                  if (viewModel.city.isNotEmpty)
                                    _buildInfoRow('City', viewModel.city),
                                  if (viewModel.state.isNotEmpty)
                                    _buildInfoRow('State', viewModel.state),
                                  if (viewModel.zip.isNotEmpty)
                                    _buildInfoRow('Zip Code', viewModel.zip),
                                  if (viewModel.country.isNotEmpty)
                                    _buildInfoRow('Country', viewModel.country),
                                ],
                              ),
                            ),
                          ),
                        ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

