import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentLocation() async {
    // Check whether device location services are enabled.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    // Check location permission.
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception(
        'Location permission denied. Please allow location access.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission permanently denied. Enable it in app settings.',
      );
    }

    // Capture current position.
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (e) {
      throw Exception('Unable to get current location: $e');
    }
  }

  bool isWithinOfficeRadius({
    required double currentLatitude,
    required double currentLongitude,
    required double officeLatitude,
    required double officeLongitude,
    required double allowedRadius,
  }) {
    final distance = Geolocator.distanceBetween(
      currentLatitude,
      currentLongitude,
      officeLatitude,
      officeLongitude,
    );

    return distance <= allowedRadius;
  }

  double calculateDistance({
    required double currentLatitude,
    required double currentLongitude,
    required double officeLatitude,
    required double officeLongitude,
  }) {
    return Geolocator.distanceBetween(
      currentLatitude,
      currentLongitude,
      officeLatitude,
      officeLongitude,
    );
  }

  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }

  Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }
}
