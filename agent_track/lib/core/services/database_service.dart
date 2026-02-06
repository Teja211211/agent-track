import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/policy_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid; // Current Agent's ID

  DatabaseService({required this.uid});

  // Collection Reference
  CollectionReference get _policiesCollection => _db.collection('policies');

  // Add Policy
  Future<void> addPolicy(PolicyModel policy) async {
    await _policiesCollection.add(policy.toMap());
  }

  // Update Policy
  Future<void> updatePolicy(PolicyModel policy) async {
    await _policiesCollection.doc(policy.id).update(policy.toMap());
  }

  // Delete Policy
  Future<void> deletePolicy(String policyId) async {
    await _policiesCollection.doc(policyId).delete();
  }

  // Get Policies Stream (Real-time updates)
  Stream<List<PolicyModel>> get policies {
    return _policiesCollection
        .where('uid', isEqualTo: uid)
        .orderBy('expiryDate', descending: false)
        .snapshots()
        .map(_policyListFromSnapshot);
  }

  // Helper: List from Snapshot
  List<PolicyModel> _policyListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return PolicyModel.fromSnapshot(doc);
    }).toList();
  }
  
  // Get Expiring Policies Stream (Next 15 days)
  Stream<List<PolicyModel>> get expiringPolicies {
    final now = DateTime.now();
    final fifteenDaysLater = now.add(const Duration(days: 15));
    
    return _policiesCollection
        .where('uid', isEqualTo: uid)
        .where('status', isNotEqualTo: PolicyStatus.renewed.name) // Don't show already renewed
        // .where('status', isNotEqualTo: PolicyStatus.lost.name) // Composite index needed for multiple NotEqual
        // Firestore limitation: only one field can have NotEqual or Range filter inequality
        // Logic will need client-side filtering or careful index setup.
        // For now, simpler query:
        .orderBy('expiryDate')
        .startAt([Timestamp.fromDate(now)])
        .endAt([Timestamp.fromDate(fifteenDaysLater)])
        .snapshots()
        .map((snapshot) {
             // Client side filter to be safe
             return _policyListFromSnapshot(snapshot).where((p) => 
               p.status != PolicyStatus.renewed && p.status != PolicyStatus.lost
             ).toList();
        });
  }

  // Get Stats
  Future<Map<String, dynamic>> getStats() async {
    final query = await _policiesCollection.where('uid', isEqualTo: uid).get();
    final policies = _policyListFromSnapshot(query);
    
    final activePolicies = policies.where((p) => p.status == PolicyStatus.active);
    final totalPolicies = activePolicies.length;
    final totalPremium = activePolicies.fold(0.0, (sum, p) => sum + p.premiumAmount);
    
    final now = DateTime.now();
    final expiringCount = policies.where((p) => 
      p.status == PolicyStatus.active &&
      p.expiryDate.isAfter(now) && 
      p.expiryDate.isBefore(now.add(const Duration(days: 15)))
    ).length;

    return {
      'totalPolicies': totalPolicies,
      'totalPremium': totalPremium,
      'expiringSoon': expiringCount,
    };
  }
}
