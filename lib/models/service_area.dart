import 'package:latlong/latlong.dart';

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

  double dist2From(LatLng target) {
    return (location.latitude - target.latitude) *
        (location.latitude - target.latitude) +
        (location.longitude - target.longitude) *
            (location.longitude - target.longitude);
  }
}
