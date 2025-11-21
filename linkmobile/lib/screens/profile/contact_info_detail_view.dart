import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_registration_view_model.dart';
import '../../services/firebase_manager.dart';
import '../../utils/validators.dart';
import '../../utils/theme.dart';

class ContactInfoDetailView extends StatefulWidget {
  const ContactInfoDetailView({super.key});

  @override
  State<ContactInfoDetailView> createState() => _ContactInfoDetailViewState();
}

class _ContactInfoDetailViewState extends State<ContactInfoDetailView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    _firstNameController.text = viewModel.firstName;
    _lastNameController.text = viewModel.lastName;
    _phoneController.text = viewModel.phoneNumber;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final viewModel = Provider.of<UserRegistrationViewModel>(context, listen: false);
    final userId = viewModel.userId;
    
    if (userId == null) {
      setState(() {
        _isSaving = false;
      });
      return;
    }

    try {
      viewModel.firstName = _firstNameController.text;
      viewModel.lastName = _lastNameController.text;
      viewModel.phoneNumber = _phoneController.text;

      final contactData = {
        'firstName': viewModel.firstName,
        'lastName': viewModel.lastName,
        'phoneNumber': viewModel.phoneNumber,
        'email': viewModel.email,
      };

      await FirebaseManager().saveContactInfo(userId, contactData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact information saved'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Information'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => Validators.required(value, fieldName: 'First name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => Validators.required(value, fieldName: 'Last name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: Validators.phoneNumber,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.mainBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

