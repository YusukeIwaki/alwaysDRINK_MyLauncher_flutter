import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'picture.dart';
import 'service_area.dart';

class Shop {
  String uuid;
  String name;
  String description;
  String roughLocationDescription;
  String businessHoursDescription;
  LatLng location;
  Picture thumbnail;
  List<Picture> pictures;

  Shop({
    this.uuid,
    this.name,
    this.description,
    this.roughLocationDescription,
    this.businessHoursDescription,
    this.location,
    this.thumbnail,
    this.pictures,
  });

  String markerTitle() {
    if (roughLocationDescription.isNotEmpty) {
      return "${roughLocationDescription} - ${name}";
    } else {
      return name;
    }
  }

  double _dist2From(LatLng target) {
    return (location.latitude - target.latitude) *
            (location.latitude - target.latitude) +
        (location.longitude - target.longitude) *
            (location.longitude - target.longitude);
  }

  ServiceArea nearestServiceAreaIn(Iterable<ServiceArea> serviceAreas) {
    return serviceAreas.reduce((currentArea, nextArea) =>
        _dist2From(nextArea.location) < _dist2From(currentArea.location)
            ? nextArea
            : currentArea);
  }
}
