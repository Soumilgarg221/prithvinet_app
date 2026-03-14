import 'package:cloud_firestore/cloud_firestore.dart';

// ── Stack Emission Row ────────────────────────────────────────────────────────
class StackEmissionRow {
  String stackSource;
  String unit;
  double? particulateMatter;
  String remark;

  StackEmissionRow({
    this.stackSource = '',
    this.unit = 'mg/Nm³',
    this.particulateMatter,
    this.remark = '',
  });

  Map<String, dynamic> toMap() => {
        'stackSource': stackSource,
        'unit': unit,
        'particulateMatter': particulateMatter,
        'remark': remark,
      };
}

// ── Air Reading ───────────────────────────────────────────────────────────────
class AirReading {
  final String roId;
  final String roName;
  final String monitoringType;
  final String? industryId;
  final String? industryName;
  final String locationId;
  final String locationName;
  final DateTime monitoringDateTime;
  final DateTime? analysisDateTime;
  final String submittedBy;
  final String submittedByName;
  final double? lat;
  final double? lng;

  // Stack emission rows
  final List<StackEmissionRow> stackRows;

  // Ambient air
  final double? pm10;
  final double? pm25;
  final double? so2;
  final double? no2;
  final double? o3;
  final double? co8hr;
  final double? nh3;
  final double? pb;

  // Computed
  final double? aqi;
  final String? aqiCategory;
  final bool hasViolation;
  final bool isSimulated;

  AirReading({
    required this.roId,
    required this.roName,
    required this.monitoringType,
    this.industryId,
    this.industryName,
    required this.locationId,
    required this.locationName,
    required this.monitoringDateTime,
    this.analysisDateTime,
    required this.submittedBy,
    required this.submittedByName,
    this.lat,
    this.lng,
    this.stackRows = const [],
    this.pm10,
    this.pm25,
    this.so2,
    this.no2,
    this.o3,
    this.co8hr,
    this.nh3,
    this.pb,
    this.aqi,
    this.aqiCategory,
    this.hasViolation = false,
    this.isSimulated = false,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'roId': roId,
      'roName': roName,
      'monitoringType': monitoringType,
      if (industryId != null) 'industryId': industryId,
      if (industryName != null) 'industryName': industryName,
      'locationId': locationId,
      'locationName': locationName,
      'monitoringDateTime': Timestamp.fromDate(monitoringDateTime),
      if (analysisDateTime != null)
        'analysisDateTime': Timestamp.fromDate(analysisDateTime!),
      'submittedBy': submittedBy,
      'submittedByName': submittedByName,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      'stackEmissions': stackRows.map((r) => r.toMap()).toList(),
      'ambient': {
        if (pm10 != null) 'pm10': pm10,
        if (pm25 != null) 'pm25': pm25,
        if (so2 != null) 'so2': so2,
        if (no2 != null) 'no2': no2,
        if (o3 != null) 'o3': o3,
        if (co8hr != null) 'co8hr': co8hr,
        if (nh3 != null) 'nh3': nh3,
        if (pb != null) 'pb': pb,
      },
      if (aqi != null) 'aqi': aqi,
      if (aqiCategory != null) 'aqiCategory': aqiCategory,
      'hasViolation': hasViolation,
      'isSimulated': isSimulated,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

// ── Water Sample Row ──────────────────────────────────────────────────────────
class WaterSample {
  String sampleId;
  String sampleLocation;
  double? temperature;
  String appearance;
  String odour;
  double? ph;
  double? turbidity;
  double? conductivity;
  double? totalSolids;
  // Waste water only
  double? bod;
  double? cod;
  double? dissolvedSolids;
  double? suspendedSolids;
  double? oilGrease;

  WaterSample({
    this.sampleId = '',
    this.sampleLocation = '',
    this.temperature,
    this.appearance = '',
    this.odour = '',
    this.ph,
    this.turbidity,
    this.conductivity,
    this.totalSolids,
    this.bod,
    this.cod,
    this.dissolvedSolids,
    this.suspendedSolids,
    this.oilGrease,
  });

  Map<String, dynamic> toMap() => {
        'sampleId': sampleId,
        'sampleLocation': sampleLocation,
        if (temperature != null) 'temperature': temperature,
        'appearance': appearance,
        'odour': odour,
        if (ph != null) 'ph': ph,
        if (turbidity != null) 'turbidity': turbidity,
        if (conductivity != null) 'conductivity': conductivity,
        if (totalSolids != null) 'totalSolids': totalSolids,
        if (bod != null) 'bod': bod,
        if (cod != null) 'cod': cod,
        if (dissolvedSolids != null) 'dissolvedSolids': dissolvedSolids,
        if (suspendedSolids != null) 'suspendedSolids': suspendedSolids,
        if (oilGrease != null) 'oilGrease': oilGrease,
      };
}

// ── Water Reading ─────────────────────────────────────────────────────────────
class WaterReading {
  final String roId;
  final String roName;
  final String waterType; // 'natural' | 'waste'
  final String? industryId;
  final String? industryName;
  final String locationId;
  final String locationName;
  final DateTime monitoringDateTime;
  final String submittedBy;
  final String submittedByName;
  final double? lat;
  final double? lng;
  final List<WaterSample> samples;
  final String? chemistName;
  final String? scientistName;
  final bool hasViolation;

  WaterReading({
    required this.roId,
    required this.roName,
    required this.waterType,
    this.industryId,
    this.industryName,
    required this.locationId,
    required this.locationName,
    required this.monitoringDateTime,
    required this.submittedBy,
    required this.submittedByName,
    this.lat,
    this.lng,
    this.samples = const [],
    this.chemistName,
    this.scientistName,
    this.hasViolation = false,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'roId': roId,
      'roName': roName,
      'waterType': waterType,
      if (industryId != null) 'industryId': industryId,
      if (industryName != null) 'industryName': industryName,
      'locationId': locationId,
      'locationName': locationName,
      'monitoringDateTime': Timestamp.fromDate(monitoringDateTime),
      'submittedBy': submittedBy,
      'submittedByName': submittedByName,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      'samples': samples.map((s) => s.toMap()).toList(),
      if (chemistName != null) 'chemistName': chemistName,
      if (scientistName != null) 'scientistName': scientistName,
      'hasViolation': hasViolation,
      'isSimulated': false,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

// ── Noise Row ─────────────────────────────────────────────────────────────────
class NoiseRow {
  String location;
  String zone; // Silence / Residential / Commercial / Industrial
  String unit;
  String monitoringTime; // Day / Night
  double? noiseLevel;
  bool isHigh;

  NoiseRow({
    this.location = '',
    this.zone = 'Residential',
    this.unit = 'dB(A)',
    this.monitoringTime = 'Day',
    this.noiseLevel,
    this.isHigh = false,
  });

  double get prescribedLimit {
    switch (zone) {
      case 'Silence':
        return monitoringTime == 'Day' ? 50 : 40;
      case 'Residential':
        return monitoringTime == 'Day' ? 55 : 45;
      case 'Commercial':
        return monitoringTime == 'Day' ? 65 : 55;
      case 'Industrial':
        return monitoringTime == 'Day' ? 75 : 70;
      default:
        return 55;
    }
  }

  bool get exceedsLimit => noiseLevel != null && noiseLevel! > prescribedLimit;

  Map<String, dynamic> toMap() => {
        'location': location,
        'zone': zone,
        'unit': unit,
        'monitoringTime': monitoringTime,
        if (noiseLevel != null) 'noiseLevel': noiseLevel,
        'prescribedLimit': prescribedLimit,
        'isHigh': exceedsLimit,
      };
}

// ── Noise Reading ─────────────────────────────────────────────────────────────
class NoiseReading {
  final String roId;
  final String roName;
  final String locationId;
  final String locationName;
  final DateTime monitoringDateTime;
  final String submittedBy;
  final String submittedByName;
  final double? lat;
  final double? lng;
  final List<NoiseRow> rows;
  final bool hasViolation;

  NoiseReading({
    required this.roId,
    required this.roName,
    required this.locationId,
    required this.locationName,
    required this.monitoringDateTime,
    required this.submittedBy,
    required this.submittedByName,
    this.lat,
    this.lng,
    this.rows = const [],
    this.hasViolation = false,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'roId': roId,
      'roName': roName,
      'locationId': locationId,
      'locationName': locationName,
      'monitoringDateTime': Timestamp.fromDate(monitoringDateTime),
      'submittedBy': submittedBy,
      'submittedByName': submittedByName,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      'readings': rows.map((r) => r.toMap()).toList(),
      'hasViolation': rows.any((r) => r.exceedsLimit),
      'isSimulated': false,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
