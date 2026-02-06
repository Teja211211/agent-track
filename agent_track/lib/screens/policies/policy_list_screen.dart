import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/policy_model.dart';
import '../../core/services/database_service.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import 'add_edit_policy_screen.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PolicyListScreen extends StatefulWidget {
  final int initialTab;

  const PolicyListScreen({super.key, this.initialTab = 0});

  @override
  State<PolicyListScreen> createState() => _PolicyListScreenState();
}

class _PolicyListScreenState extends State<PolicyListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // In real app, get uid from Auth Provider
    final uid = context.read<AuthService>().currentUser?.uid ?? 'test_uid';
    final dbService = DatabaseService(uid: uid);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Policies'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'All Policies'),
            Tab(text: 'Expiring Soon'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddEditPolicyScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PolicyList(stream: dbService.policies),
          _PolicyList(stream: dbService.expiringPolicies, isExpiringTab: true),
        ],
      ),
    );
  }
}

class _PolicyList extends StatelessWidget {
  final Stream<List<PolicyModel>> stream;
  final bool isExpiringTab;

  const _PolicyList({required this.stream, this.isExpiringTab = false});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PolicyModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final policies = snapshot.data ?? [];
        
        if (policies.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isExpiringTab ? Icons.check_circle_outline : Icons.folder_open,
                  size: 64, 
                  color: AppColors.textSecondary
                ),
                const SizedBox(height: 16),
                Text(
                  isExpiringTab ? 'No policies expiring soon' : 'No policies found',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: policies.length,
          itemBuilder: (context, index) {
            final policy = policies[index];
            return _PolicyCard(policy: policy, isExpiring: isExpiringTab);
          },
        );
      },
    );
  }
}

class _PolicyCard extends StatelessWidget {
  final PolicyModel policy;
  final bool isExpiring;

  const _PolicyCard({required this.policy, required this.isExpiring});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    
    Color statusColor = AppColors.accentGreen;
    if (policy.status == PolicyStatus.lost) statusColor = AppColors.mutedGrey;
    if (isExpiring || policy.expiryDate.difference(DateTime.now()).inDays < 15) statusColor = AppColors.warningOrange;
    if (policy.expiryDate.isBefore(DateTime.now())) statusColor = AppColors.alertRed;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Colors.white,
      child: InkWell(
        onTap: () {
          // Navigate to details or edit
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AddEditPolicyScreen(policy: policy)),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      policy.clientName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      isExpiring ? 'Expiring' : policy.status.name.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Policy No: ${policy.policyNumber}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                   const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                   const SizedBox(width: 4),
                   Text(
                    'Expires: ${dateFormat.format(policy.expiryDate)}',
                    style: TextStyle(
                      color: isExpiring ? AppColors.alertRed : AppColors.textSecondary,
                      fontWeight: isExpiring ? FontWeight.bold : FontWeight.normal,
                    ),
                   ),
                ],
              ),
              const SizedBox(height: 8),
              if (isExpiring) ...[
                 const Divider(),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.end,
                   children: [
                     TextButton.icon(
                       onPressed: () async {
                         final Uri smsLaunchUri = Uri(
                           scheme: 'sms',
                           path: policy.mobileNumber,
                           queryParameters: <String, String>{
                             'body': 'Dear ${policy.clientName}, your policy ${policy.policyNumber} expires on ${dateFormat.format(policy.expiryDate)}. Please renew to avoid penalty.',
                           },
                         );
                         // url_launcher 6.1+ uses launchUrl
                         // import 'package:url_launcher/url_launcher.dart'; needed at top
                         // For now assuming we can add the import or use fully qualified if possible, 
                         // but easier to add import. 
                         // Since I can't add import easily with replace_content in middle, I'll use a mixin or helper?
                         // Actually I can just add the import at the top in a separate tool call or try to squeeze it in if context allows.
                         // But for now let's just write the code assuming import exists, and I will add import in next step.
                         
                         if (await canLaunchUrl(smsLaunchUri)) {
                           await launchUrl(smsLaunchUri);
                         }
                       }, 
                       icon: const Icon(Icons.message_outlined, size: 18), 
                       label: const Text('Message'),
                       style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                     ),
                     const SizedBox(width: 8),
                     ElevatedButton.icon(
                       onPressed: () async {
                          final Uri launchUri = Uri(
                            scheme: 'tel',
                            path: policy.mobileNumber,
                          );
                          if (await canLaunchUrl(launchUri)) {
                            await launchUrl(launchUri);
                          }
                       },
                       icon: const Icon(Icons.call, size: 18),
                       label: const Text('Call'),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: AppColors.accentGreen,
                         foregroundColor: Colors.white,
                         elevation: 0,
                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                       ),
                     ),
                   ],
                 )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
