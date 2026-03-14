import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Returns monitoring locations sorted by proximity to current position
  List<Map<String, dynamic>> sortByProximity(
    List<Map<String, dynamic>> locations,
    Position currentPos,
  ) {
    final sorted = List<Map<String, dynamic>>.from(locations);
    sorted.sort((a, b) {
      final distA = Geolocator.distanceBetween(
        currentPos.latitude,
        currentPos.longitude,
        (a['lat'] as num).toDouble(),
        (a['lng'] as num).toDouble(),
      );
      final distB = Geolocator.distanceBetween(
        currentPos.latitude,
        currentPos.longitude,
        (b['lat'] as num).toDouble(),
        (b['lng'] as num).toDouble(),
      );
      return distA.compareTo(distB);
    });
    return sorted;
  }

  String formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m away';
    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }

  double distanceTo(Map<String, dynamic> location, Position pos) {
    return Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      (location['lat'] as num).toDouble(),
      (location['lng'] as num).toDouble(),
    );
  }
}
