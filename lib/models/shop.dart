import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'picture.dart';
import 'service_area.dart';

class Shop {
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

  String uuid;
  String name;
  String description;
  String roughLocationDescription;
  String businessHoursDescription;
  LatLng location;
  Picture thumbnail;
  List<Picture> pictures;

  String markerTitle() {
    if (roughLocationDescription.isNotEmpty) {
      return '$roughLocationDescription - $name';
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
    return serviceAreas.reduce((ServiceArea currentArea, ServiceArea nextArea) {
      if (_dist2From(nextArea.location) < _dist2From(currentArea.location)) {
        return nextArea;
      } else {
        return currentArea;
      }
    });
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Shop &&
          runtimeType == other.runtimeType &&
          uuid == other.uuid &&
          name == other.name &&
          description == other.description &&
          roughLocationDescription == other.roughLocationDescription &&
          businessHoursDescription == other.businessHoursDescription &&
          location == other.location &&
          thumbnail == other.thumbnail &&
          pictures == other.pictures;

  @override
  int get hashCode =>
      uuid.hashCode ^
      name.hashCode ^
      description.hashCode ^
      roughLocationDescription.hashCode ^
      businessHoursDescription.hashCode ^
      location.hashCode ^
      thumbnail.hashCode ^
      pictures.hashCode;

  @override
  String toString() {
    return 'Shop{uuid: $uuid, name: $name, description: $description, roughLocationDescription: $roughLocationDescription, businessHoursDescription: $businessHoursDescription, location: $location, thumbnail: $thumbnail, pictures: $pictures}';
  }
}
