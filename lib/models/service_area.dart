import 'package:google_maps_flutter/google_maps_flutter.dart';

class ServiceArea {
  String uuid;
  String name;
  LatLng location;
  double zoom;

  ServiceArea({
    this.uuid,
    this.name,
    this.location,
    this.zoom,
  });
}
