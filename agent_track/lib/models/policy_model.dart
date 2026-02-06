import 'package:cloud_firestore/cloud_firestore.dart';

enum PolicyStatus { active, renewed, lost }

class PolicyModel {
  final String id;
  final String uid; // Agent ID
  final String clientName;
  final String policyNumber;
  final String mobileNumber;
  final String email;
  final double premiumAmount;
  final Map<String, dynamic> vehicleDetails; // { 'make': 'Toyota', 'model': 'Camry', 'regNo': '...' }
  final DateTime expiryDate;
  final String description;
  final PolicyStatus status;
  final DateTime? renewalDate;

  PolicyModel({
    required this.id,
    required this.uid,
    required this.clientName,
    required this.policyNumber,
    required this.mobileNumber,
    required this.email,
    required this.premiumAmount,
    required this.vehicleDetails,
    required this.expiryDate,
    required this.description,
    required this.status,
    this.renewalDate,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'clientName': clientName,
      'policyNumber': policyNumber,
      'mobileNumber': mobileNumber,
      'email': email,
      'premiumAmount': premiumAmount,
      'vehicleDetails': vehicleDetails,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'description': description,
      'status': status.name, // Store as string
      'renewalDate': renewalDate != null ? Timestamp.fromDate(renewalDate!) : null,
    };
  }

  // Create from Firestore DocumentSnapshot
  factory PolicyModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PolicyModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      clientName: data['clientName'] ?? '',
      policyNumber: data['policyNumber'] ?? '',
      mobileNumber: data['mobileNumber'] ?? '',
      email: data['email'] ?? '',
      premiumAmount: (data['premiumAmount'] ?? 0).toDouble(),
      vehicleDetails: Map<String, dynamic>.from(data['vehicleDetails'] ?? {}),
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
      description: data['description'] ?? '',
      status: PolicyStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => PolicyStatus.active,
      ),
      renewalDate: data['renewalDate'] != null ? (data['renewalDate'] as Timestamp).toDate() : null,
    );
  }
  
  // Create from Map (useful for copies)
   factory PolicyModel.fromMap(Map<String, dynamic> map, String id) {
    return PolicyModel(
      id: id,
      uid: map['uid'] ?? '',
      clientName: map['clientName'] ?? '',
      policyNumber: map['policyNumber'] ?? '',
      mobileNumber: map['mobileNumber'] ?? '',
      email: map['email'] ?? '',
      premiumAmount: (map['premiumAmount'] ?? 0).toDouble(),
      vehicleDetails: Map<String, dynamic>.from(map['vehicleDetails'] ?? {}),
      expiryDate: (map['expiryDate'] as Timestamp).toDate(),
      description: map['description'] ?? '',
      status: PolicyStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PolicyStatus.active,
      ),
      renewalDate: map['renewalDate'] != null ? (map['renewalDate'] as Timestamp).toDate() : null,
    );
  }

  PolicyModel copyWith({
    String? id,
    String? uid,
    String? clientName,
    String? policyNumber,
    String? mobileNumber,
    String? email,
    double? premiumAmount,
    Map<String, dynamic>? vehicleDetails,
    DateTime? expiryDate,
    String? description,
    PolicyStatus? status,
    DateTime? renewalDate,
  }) {
    return PolicyModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      clientName: clientName ?? this.clientName,
      policyNumber: policyNumber ?? this.policyNumber,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      premiumAmount: premiumAmount ?? this.premiumAmount,
      vehicleDetails: vehicleDetails ?? this.vehicleDetails,
      expiryDate: expiryDate ?? this.expiryDate,
      description: description ?? this.description,
      status: status ?? this.status,
      renewalDate: renewalDate ?? this.renewalDate,
    );
  }
}
