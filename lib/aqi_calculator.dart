class AqiCalculator {
  // CPCB Sub-Index breakpoints
  // Format: [CL, CH, ILow, IHigh]
  static const _pm25Breakpoints = [
    [0.0, 30.0, 0.0, 50.0],
    [30.0, 60.0, 51.0, 100.0],
    [60.0, 90.0, 101.0, 200.0],
    [90.0, 120.0, 201.0, 300.0],
    [120.0, 250.0, 301.0, 400.0],
    [250.0, 500.0, 401.0, 500.0],
  ];

  static const _pm10Breakpoints = [
    [0.0, 50.0, 0.0, 50.0],
    [50.0, 100.0, 51.0, 100.0],
    [100.0, 250.0, 101.0, 200.0],
    [250.0, 350.0, 201.0, 300.0],
    [350.0, 430.0, 301.0, 400.0],
    [430.0, 600.0, 401.0, 500.0],
  ];

  static const _so2Breakpoints = [
    [0.0, 40.0, 0.0, 50.0],
    [40.0, 80.0, 51.0, 100.0],
    [80.0, 380.0, 101.0, 200.0],
    [380.0, 800.0, 201.0, 300.0],
    [800.0, 1600.0, 301.0, 400.0],
    [1600.0, 2100.0, 401.0, 500.0],
  ];

  static const _no2Breakpoints = [
    [0.0, 40.0, 0.0, 50.0],
    [40.0, 80.0, 51.0, 100.0],
    [80.0, 180.0, 101.0, 200.0],
    [180.0, 280.0, 201.0, 300.0],
    [280.0, 400.0, 301.0, 400.0],
    [400.0, 800.0, 401.0, 500.0],
  ];

  static double? _subIndex(double value, List<List<double>> breakpoints) {
    for (final bp in breakpoints) {
      if (value >= bp[0] && value <= bp[1]) {
        return (bp[3] - bp[2]) / (bp[1] - bp[0]) * (value - bp[0]) + bp[2];
      }
    }
    return null;
  }

  static Map<String, dynamic> calculate({
    double? pm25,
    double? pm10,
    double? so2,
    double? no2,
  }) {
    final subIndices = <double>[];

    if (pm25 != null) {
      final si = _subIndex(pm25, _pm25Breakpoints);
      if (si != null) subIndices.add(si);
    }
    if (pm10 != null) {
      final si = _subIndex(pm10, _pm10Breakpoints);
      if (si != null) subIndices.add(si);
    }
    if (so2 != null) {
      final si = _subIndex(so2, _so2Breakpoints);
      if (si != null) subIndices.add(si);
    }
    if (no2 != null) {
      final si = _subIndex(no2, _no2Breakpoints);
      if (si != null) subIndices.add(si);
    }

    if (subIndices.isEmpty) return {'aqi': null, 'category': null};

    final aqi = subIndices.reduce((a, b) => a > b ? a : b).roundToDouble();
    return {'aqi': aqi, 'category': _category(aqi)};
  }

  static String _category(double aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Satisfactory';
    if (aqi <= 200) return 'Moderate';
    if (aqi <= 300) return 'Poor';
    if (aqi <= 400) return 'Very Poor';
    return 'Severe';
  }
}
