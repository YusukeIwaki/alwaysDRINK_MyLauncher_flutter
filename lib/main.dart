import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

void main() => runApp(AlwaysDrinkApp());

const MaterialColor alwaysDrinkColor = MaterialColor(
  0xFF62A9DE,
  <int, Color>{
    50: Color(0xFFECF5FB),
    100: Color(0xFFD0E5F5),
    200: Color(0xFFB1D4EF),
    300: Color(0xFF91C3E8),
    400: Color(0xFF7AB6E3),
    500: Color(0xFF62A9DE),
    600: Color(0xFF5AA2DA),
    700: Color(0xFF5098D5),
    800: Color(0xFF468FD1),
    900: Color(0xFF347EC8),
  },
);

const MaterialAccentColor alwaysDrinkAccentColor = MaterialAccentColor(
  0xFF2A83DB,
  <int, Color>{
    100: Color(0xFF6AA8E6),
    200: Color(0xFF2A83DB),
    400: Color(0xFF1F70D2),
    700: Color(0xFF0F53C4)
  },
);

class ServiceArea {
  String uuid;
  String name;
  LatLng location;
  double zoom;

  ServiceArea({this.uuid, this.name, this.location, this.zoom});
}

class Shop {
  String uuid;
  String name;
  String roughLocationDescription;
  String businessHoursDescription;
  LatLng location;
  Picture thumbnail;
  List<Picture> pictures;

  Shop(
      {this.uuid,
      this.name,
      this.roughLocationDescription,
      this.businessHoursDescription,
      this.location,
      this.thumbnail,
      this.pictures});

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

class Picture {
  String smallUrl;
  String largeUrl;

  Picture({this.smallUrl, this.largeUrl});
}

class AlwaysDrinkApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
          primarySwatch: alwaysDrinkColor, accentColor: alwaysDrinkAccentColor),
      home: ShopListPage(),
    );
  }
}

class ShopListPageState extends State {
  static CameraPosition _initCameraPosition =
      CameraPosition(target: LatLng(34.6870728, 135.0490244), zoom: 5.0);
  Completer<GoogleMapController> _googleMapController = Completer();

  PageController pageController = PageController(
    initialPage: 0,
    keepPage: false,
    viewportFraction: 0.95,
  );

  Iterable<ServiceArea> serviceAreas = List();
  List<Shop> shops = List();
  Shop selectedShop = null;

  @override
  void initState() {
    super.initState();

    _fetchShopList();
  }

  _fetchShopList() async {
    final response = await http.get(
        "https://api.always.fan/mono/v2/pb/subscription-plan/751acbbe/provider");
    if (response.statusCode == 200) {
      final responseJson = json.decode(response.body);
      List<ServiceArea> newServiceAreas =
          (responseJson["places"] as Iterable).map((place) {
        return ServiceArea(
          uuid: place["uuid"],
          name: place["name"],
          location: LatLng(place["lat"], place["lng"]),
          zoom: (place["zoom"] as int).toDouble(),
        );
      }).toList();

      List<Shop> newShops = (responseJson["menus"] as Iterable).map((menu) {
        return Shop(
          uuid: menu["pbProvider"]["uuid"],
          name: menu["pbProvider"]["name"],
          roughLocationDescription: menu["pbProvider"]["area"],
          businessHoursDescription: menu["pbProvider"]["businessHours"],
          location: LatLng(menu["pbProvider"]["location"]["lat"],
              menu["pbProvider"]["location"]["lon"]),
          thumbnail: (menu["pictures"] as Iterable).map((picture) {
            return Picture(
                smallUrl: picture["pictureUrl"]["smallUrl"],
                largeUrl: picture["pictureUrl"]["largeUrl"]);
          }).first,
          pictures: (menu["pbProvider"]["pictures"] as Iterable).map((picture) {
            return Picture(
                smallUrl: picture["pictureUrl"]["smallUrl"],
                largeUrl: picture["pictureUrl"]["largeUrl"]);
          }).toList(),
        );
      }).toList();
      setState(() {
        serviceAreas =
            newServiceAreas.where((serviceArea) => serviceArea.zoom >= 10);
        shops = newShops;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _googleMapController.future.then((googleMap) {
      if (selectedShop != null) {
        double zoom = selectedShop.nearestServiceAreaIn(serviceAreas).zoom;
        googleMap.animateCamera(
            CameraUpdate.newLatLngZoom(selectedShop.location, zoom));
      }
    });
    if (selectedShop != null) {
      int initialPage =
          shops.indexWhere((shop) => shop.uuid == selectedShop.uuid);
      if (initialPage >= 0) {
        pageController.animateToPage(initialPage,
            duration: Duration(milliseconds: 600), curve: Curves.easeOutQuart);
      }
    }
    ;
    return Column(
      children: <Widget>[
        Expanded(
          child: GoogleMap(
            initialCameraPosition: _initCameraPosition,
            markers: shops.map((shop) {
              return Marker(
                  markerId: MarkerId(shop.uuid),
                  position: shop.location,
                  icon: shop.uuid == selectedShop?.uuid
                      ? BitmapDescriptor.defaultMarker
                      : BitmapDescriptor.defaultMarkerWithHue(180),
                  infoWindow: InfoWindow(title: shop.markerTitle()),
                  onTap: () {
                    setState(() {
                      selectedShop = shop;
                    });
                  });
            }).toSet(),
            onMapCreated: (googleMap) {
              _googleMapController.complete(googleMap);
            },
          ),
        ),
        Container(
          height: 240,
          child: PageView(
            controller: pageController,
            children: shops.map<Widget>((shop) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16.0)),
                  ),
                  child: Stack(
                    children: <Widget>[
                      MediaQuery.removePadding(
                        context: context,
                        removeTop: true,
                        child: ListView(
                          children:
                              List<Widget>.generate(20, (internalListIndex) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Container(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                      "internal content ${internalListIndex}"),
                                  decoration:
                                      BoxDecoration(color: Colors.yellow),
                                )
                              ],
                            );
                          }),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          height: 32,
                          child: Text(
                            shop.name,
                            style: Theme.of(context)
                                .textTheme
                                .subhead
                                .merge(TextStyle(color: Colors.white)),
                          ),
                          decoration: BoxDecoration(
                              color: Color.fromARGB(0x99, 0, 0, 0)),
                          padding: EdgeInsets.all(8),
                        ),
                      )
                    ],
                  ),
                ),
              );
            }).toList(),
            onPageChanged: (page) {
              setState(() {
                if (page >= 0 && page < shops.length) {
                  selectedShop = shops.elementAt(page);
                } else {
                  selectedShop = null;
                }
              });
            },
          ),
        ),
      ],
    );
    ;
  }
}

class ShopListPage extends StatefulWidget {
  @override
  State createState() => ShopListPageState();
}
