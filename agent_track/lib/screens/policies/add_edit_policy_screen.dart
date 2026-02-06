import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/policy_model.dart';
import '../../core/services/database_service.dart';
import '../../core/services/auth_service.dart';
// import 'package:url_launcher/url_launcher.dart'; // Will implement actions later

class AddEditPolicyScreen extends StatefulWidget {
  final PolicyModel? policy;

  const AddEditPolicyScreen({super.key, this.policy});

  @override
  State<AddEditPolicyScreen> createState() => _AddEditPolicyScreenState();
}

class _AddEditPolicyScreenState extends State<AddEditPolicyScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _clientNameController = TextEditingController();
  final _policyNumberController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _premiumController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _regNoController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));
  PolicyStatus _status = PolicyStatus.active;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.policy != null) {
      _loadPolicyData(widget.policy!);
    }
  }

  void _loadPolicyData(PolicyModel policy) {
    _clientNameController.text = policy.clientName;
    _policyNumberController.text = policy.policyNumber;
    _mobileController.text = policy.mobileNumber;
    _emailController.text = policy.email;
    _premiumController.text = policy.premiumAmount.toString();
    
    final vehicle = policy.vehicleDetails;
    _makeController.text = vehicle['make'] ?? '';
    _modelController.text = vehicle['model'] ?? '';
    _regNoController.text = vehicle['regNo'] ?? '';
    
    _descriptionController.text = policy.description;
    _expiryDate = policy.expiryDate;
    _status = policy.status;
  }

  Future<void> _savePolicy() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final uid = context.read<AuthService>().currentUser?.uid ?? 'test_uid';
      final db = DatabaseService(uid: uid);

      final policyData = PolicyModel(
        id: widget.policy?.id ?? '', // ID handled by Firestone for new docs usually, check logic
        uid: uid,
        clientName: _clientNameController.text.trim(),
        policyNumber: _policyNumberController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        premiumAmount: double.tryParse(_premiumController.text) ?? 0.0,
        vehicleDetails: {
          'make': _makeController.text.trim(),
          'model': _modelController.text.trim(),
          'regNo': _regNoController.text.trim(),
        },
        expiryDate: _expiryDate,
        description: _descriptionController.text.trim(),
        status: _status,
      );

      if (widget.policy == null) {
        await db.addPolicy(policyData);
      } else {
        await db.updatePolicy(policyData);
      }
      
      if (mounted) Navigator.pop(context);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePolicy() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Policy?'),
        content: const Text('Are you sure you want to delete this policy? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: AppColors.alertRed),
            child: const Text('Delete'),
          ),
        ],
      )
    );

    if (confirmed == true && widget.policy != null) {
      setState(() => _isLoading = true);
      try {
        final uid = context.read<AuthService>().currentUser?.uid ?? 'test_uid';
        await DatabaseService(uid: uid).deletePolicy(widget.policy!.id);
        if (mounted) Navigator.pop(context);
      } catch (e) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
      } finally {
         if (mounted) setState(() => _isLoading = false);
      }
    }
  }
  
  // Quick Mark Renewed
  Future<void> _markRenewed() async {
    // Basic logic: Clone and Update.
    // For MVP: open dialog to confirm details.
    // Ideally this would open a new instance of this screen with pre-filled data.
    
    // Set old policy to Renewed
    setState(() => _status = PolicyStatus.renewed);
    await _savePolicy(); // This saves the OLD policy as renewed.
    
    // Navigate to new policy screen with cloned data
    if (mounted) {
       final newPolicyBase = widget.policy!.copyWith(
         id: '', // New ID
         expiryDate: DateTime.now().add(const Duration(days: 365)), // Default +1 year
         status: PolicyStatus.active,
         // Keep other details
       );
       Navigator.of(context).pushReplacement(
         MaterialPageRoute(builder: (_) => AddEditPolicyScreen(policy: newPolicyBase)),
       );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.policy == null ? 'New Policy' : 'Edit Policy'),
        actions: [
          if (widget.policy != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.alertRed),
              onPressed: _isLoading ? null : _deletePolicy,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Client Details
              _SectionHeader(title: 'Client Details'),
              _CustomTextField(label: 'Client Name', controller: _clientNameController, icon: Icons.person),
              _CustomTextField(label: 'Mobile Number', controller: _mobileController, icon: Icons.phone, keyboardType: TextInputType.phone),
              _CustomTextField(label: 'Email', controller: _emailController, icon: Icons.email, keyboardType: TextInputType.emailAddress),
              
              const SizedBox(height: 16),
              // Policy Details
              _SectionHeader(title: 'Policy Details'),
              _CustomTextField(label: 'Policy Number', controller: _policyNumberController, icon: Icons.description),
              _CustomTextField(label: 'Premium Amount', controller: _premiumController, icon: Icons.attach_money, keyboardType: TextInputType.number),
              
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Expiry Date'),
                subtitle: Text(DateFormat('dd MMM yyyy').format(_expiryDate)),
                trailing: const Icon(Icons.calendar_month, color: AppColors.primary),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context, 
                    initialDate: _expiryDate, 
                    firstDate: DateTime(2000), 
                    lastDate: DateTime(2050)
                  );
                  if (picked != null) setState(() => _expiryDate = picked);
                },
              ),
               
              DropdownButtonFormField<PolicyStatus>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: PolicyStatus.values.map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s.name.toUpperCase()),
                )).toList(),
                onChanged: (val) => setState(() => _status = val!),
              ),

              const SizedBox(height: 16),
              // Vehicle Details
              _SectionHeader(title: 'Vehicle Details'),
              Row(
                children: [
                   Expanded(child: _CustomTextField(label: 'Make', controller: _makeController)),
                   const SizedBox(width: 12),
                   Expanded(child: _CustomTextField(label: 'Model', controller: _modelController)),
                ],
              ),
              _CustomTextField(label: 'Registration No', controller: _regNoController),
              
              const SizedBox(height: 24),
              // Action Buttons
               SizedBox(
                 width: double.infinity,
                 child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePolicy,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(widget.policy == null ? 'Create Policy' : 'Update Policy'),
                 ),
               ),
               
               if (widget.policy != null && widget.policy!.status != PolicyStatus.renewed) ...[
                 const SizedBox(height: 12),
                 OutlinedButton(
                   onPressed: _isLoading ? null : _markRenewed,
                   style: OutlinedButton.styleFrom(
                     foregroundColor: AppColors.accentGreen,
                     side: const BorderSide(color: AppColors.accentGreen),
                     padding: const EdgeInsets.symmetric(vertical: 16),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   ),
                   child: const Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(Icons.autorenew),
                       SizedBox(width: 8),
                       Text('Mark as Renewed & Create New'),
                     ],
                   ),
                 ),
               ]
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final TextInputType keyboardType;
  
  const _CustomTextField({required this.label, required this.controller, this.icon, this.keyboardType = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, size: 20) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
      ),
    );
  }
}
