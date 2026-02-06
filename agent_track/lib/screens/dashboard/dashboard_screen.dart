import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import 'package:provider/provider.dart';
import '../auth/login_screen.dart';
import '../policies/policy_list_screen.dart'; // Will create next
import '../policies/add_edit_policy_screen.dart'; // Will create next

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Real Data Fetch
    final uid = context.watch<AuthService>().currentUser?.uid ?? 'test_uid';
    final dbService = DatabaseService(uid: uid);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthService>().signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
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
      body: FutureBuilder<Map<String, dynamic>>(
        future: dbService.getStats(),
        builder: (context, snapshot) {
          final stats = snapshot.data ?? {
            'totalPolicies': 0,
            'totalPremium': 0.0,
            'expiringSoon': 0,
          };
          
          // Refresh on pull or stream? FutureBuilder builds once. 
          // ideally we'd use a Stream for counts, but getStats is a Future.
          // For now, let's wrap body in a refreshable or just load once.
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome, Agent',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                
                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Total Policies',
                        value: stats['totalPolicies'].toString(),
                        icon: Icons.folder_copy_outlined,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Expiring Soon',
                        value: stats['expiringSoon'].toString(),
                        icon: Icons.timer_outlined,
                        color: AppColors.warningOrange,
                        onTap: () {
                           Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PolicyListScreen(initialTab: 1)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SummaryCard(
                  title: 'Total Business',
                  value: '\$${stats['totalPremium']}', // Format currency properly later
                  icon: Icons.attach_money,
                  color: AppColors.accentGreen,
                ),
            
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     const Text(
                      'Recent Activity',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PolicyListScreen(initialTab: 0)),
                          );
                      }, 
                      child: const Text('View All'),
                    )
                  ],
                 
                ),
                const SizedBox(height: 10),
                
                // Recent List (Placeholder)
                // In real app, query recent policies
                const Center(child: Text("Recent activity requires stream implementation", style: TextStyle(color: Colors.grey))),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                if (onTap != null) 
                  const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.mutedGrey),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
