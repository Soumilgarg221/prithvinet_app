import 'package:cloud_firestore/cloud_firestore.dart';

import 'reading_models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Regional Offices ──────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getRegionalOffices() async {
    final snap = await _db.collection('regionalOffices').get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  // ── Industries ────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getIndustries({String? roId}) async {
    Query q = _db.collection('industries');
    if (roId != null) q = q.where('roId', isEqualTo: roId);
    final snap = await q.get();
    return snap.docs
        .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
        .toList();
  }

  // ── Monitoring Locations ─────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getLocations({String? roId}) async {
    Query q = _db.collection('monitoringLocations');
    if (roId != null) q = q.where('roId', isEqualTo: roId);
    final snap = await q.get();
    return snap.docs
        .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
        .toList();
  }

  // ── Monitoring Team Members ──────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getTeamMembers({String? roId}) async {
    Query q = _db.collection('monitoringTeams');
    if (roId != null) q = q.where('roId', isEqualTo: roId);
    final snap = await q.get();
    return snap.docs
        .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
        .toList();
  }

  // ── Prescribed Limits ────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getPrescribedLimits({String? type}) async {
    Query q = _db.collection('prescribedLimits');
    if (type != null) q = q.where('monitoringType', isEqualTo: type);
    final snap = await q.get();
    return snap.docs
        .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
        .toList();
  }

  // ── Air Readings ─────────────────────────────────────────────────────────
  Future<String> submitAirReading(AirReading reading) async {
    final ref = await _db.collection('airReadings').add(reading.toFirestore());
    return ref.id;
  }

  Stream<List<Map<String, dynamic>>> getAirReadings({required String uid}) {
    return _db
        .collection('airReadings')
        .where('submittedBy', isEqualTo: uid)
        .orderBy('monitoringDateTime', descending: true)
        .limit(30)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  // ── Water Readings ───────────────────────────────────────────────────────
  Future<String> submitWaterReading(WaterReading reading) async {
    final ref =
        await _db.collection('waterReadings').add(reading.toFirestore());
    return ref.id;
  }

  Stream<List<Map<String, dynamic>>> getWaterReadings({required String uid}) {
    return _db
        .collection('waterReadings')
        .where('submittedBy', isEqualTo: uid)
        .orderBy('monitoringDateTime', descending: true)
        .limit(30)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  // ── Noise Readings ───────────────────────────────────────────────────────
  Future<String> submitNoiseReading(NoiseReading reading) async {
    final ref =
        await _db.collection('noiseReadings').add(reading.toFirestore());
    return ref.id;
  }

  Stream<List<Map<String, dynamic>>> getNoiseReadings({required String uid}) {
    return _db
        .collection('noiseReadings')
        .where('submittedBy', isEqualTo: uid)
        .orderBy('monitoringDateTime', descending: true)
        .limit(30)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  // ── Compliance (monthly submission check) ────────────────────────────────
  Future<Map<String, int>> getMonthlySubmissionCount(String uid) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startTs = Timestamp.fromDate(startOfMonth);

    final airSnap = await _db
        .collection('airReadings')
        .where('submittedBy', isEqualTo: uid)
        .where('monitoringDateTime', isGreaterThanOrEqualTo: startTs)
        .count()
        .get();

    final waterSnap = await _db
        .collection('waterReadings')
        .where('submittedBy', isEqualTo: uid)
        .where('monitoringDateTime', isGreaterThanOrEqualTo: startTs)
        .count()
        .get();

    final noiseSnap = await _db
        .collection('noiseReadings')
        .where('submittedBy', isEqualTo: uid)
        .where('monitoringDateTime', isGreaterThanOrEqualTo: startTs)
        .count()
        .get();

    return {
      'air': airSnap.count ?? 0,
      'water': waterSnap.count ?? 0,
      'noise': noiseSnap.count ?? 0,
    };
  }
}
