import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String? roId;
  final String? roName;
  final Map<String, bool> permissions;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.roId,
    this.roName,
    this.permissions = const {},
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'monitoringTeam',
      roId: data['roId'],
      roName: data['roName'],
      permissions: Map<String, bool>.from(data['permissions'] ?? {}),
    );
  }

  bool get canReportAir => permissions['reportAir'] ?? false;
  bool get canReportWaterNatural => permissions['reportWaterNatural'] ?? false;
  bool get canReportWaterWaste => permissions['reportWaterWaste'] ?? false;
  bool get canReportNoise => permissions['reportNoise'] ?? false;
  bool get canReportIndustrial => permissions['reportIndustrial'] ?? false;
  bool get isSuperAdmin => role == 'superAdmin';
  bool get isMonitoringTeam => role == 'monitoringTeam';
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc.data()!, user.uid);
  }

  Future<UserModel?> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final doc = await _firestore.collection('users').doc(cred.user!.uid).get();
    if (!doc.exists) throw Exception('User profile not found');
    return UserModel.fromFirestore(doc.data()!, cred.user!.uid);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
