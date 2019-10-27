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
}
