import 'package:google_maps_flutter/google_maps_flutter.dart';

class ServiceArea {
  ServiceArea({
    this.uuid,
    this.name,
    this.location,
    this.zoom,
  });

  String uuid;
  String name;
  LatLng location;
  double zoom;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceArea &&
          runtimeType == other.runtimeType &&
          uuid == other.uuid &&
          name == other.name &&
          location == other.location &&
          zoom == other.zoom;

  @override
  int get hashCode =>
      uuid.hashCode ^ name.hashCode ^ location.hashCode ^ zoom.hashCode;

  @override
  String toString() {
    return 'ServiceArea{uuid: $uuid, name: $name, location: $location, zoom: $zoom}';
  }
}
