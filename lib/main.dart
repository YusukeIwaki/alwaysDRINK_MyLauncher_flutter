import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';


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
  String description;
  String roughLocationDescription;
  String businessHoursDescription;
  LatLng location;
  Picture thumbnail;
  List<Picture> pictures;

  Shop(
      {this.uuid,
      this.name,
      this.description,
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

class ShopDetail extends StatelessWidget {
  final Shop shop;
  ShopDetail({this.shop});

  _saveAlwaysShopUuid(String uuid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("shop_uuid", uuid);
  }

  _openBrowser(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {

    }
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: ListView(
        children: <Widget>[
          Image.network(shop.thumbnail.largeUrl),
          SizedBox(
            height: 220,
            child: ListView(
              children: shop.pictures.map<Widget>((picture) {
                return Padding(
                  padding: EdgeInsets.all(8),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    margin: EdgeInsets.zero,
                    child: Image.network(picture.largeUrl),
                  ),
                );
              }).toList(),
              scrollDirection: Axis.horizontal,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 16),
            child: Text(
                shop.description,
                style: Theme.of(context)
                    .textTheme
                    .body1
                    .merge(TextStyle(height: 1.5))),
          ),
          Divider(),
          Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8),
            child: Text(
                "営業時間",
                style: Theme.of(context)
                    .textTheme
                    .subhead),
          ),
          Padding(
              padding: EdgeInsets.only(left: 32, right: 16, top: 8, bottom: 16),
              child: Text(
                  shop.businessHoursDescription,
                  style: Theme.of(context)
                      .textTheme
                      .body1
                      .merge(TextStyle(height: 1.5))),
          ),
          Padding(
            padding: EdgeInsets.all(24),
            child: Row(
              children: <Widget>[
                OutlineButton(
                  child: Text("Set As Always"),
                  color: alwaysDrinkAccentColor,
                  textColor: alwaysDrinkAccentColor,
                  onPressed: () {
                    _saveAlwaysShopUuid(shop.uuid);
                  },
                ),
                Spacer(),
                RaisedButton(
                  child: Text("パスを表示"),
                  color: alwaysDrinkAccentColor,
                  textColor: Colors.white,
                  onPressed: () {
                    _openBrowser("https://always.fan/original/drink/user-subscription/751acbbe?p=${shop.uuid}");
                  },
                ),
              ],
            ),
          ),
          Container(
            height: 24,
          )
        ],
      ),
    );
  }
}

class ShopListPageState extends State {
  static CameraPosition _initCameraPosition =
      CameraPosition(target: LatLng(34.6870728, 135.0490244), zoom: 5.0);
  Completer<GoogleMapController> _googleMapController = Completer();

  PageController _pageController;

  Iterable<ServiceArea> serviceAreas = List();
  List<Shop> shops = List();
  Shop selectedShop = null;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(
      initialPage: 0,
      keepPage: false,
      viewportFraction: 0.95,
    );
    _fetchShopList();
  }

  Future<String> _alwaysShopUuid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("shop_uuid");
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
          description: menu["pbProvider"]["description"],
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
      String alwaysShopUuid = await _alwaysShopUuid();
      Shop newSelectedShop = null;
      if (alwaysShopUuid != null) {
        try {
          newSelectedShop = newShops.firstWhere((shop) => shop.uuid == alwaysShopUuid);
        } catch (err) { }
      }
      setState(() {
        serviceAreas =
            newServiceAreas.where((serviceArea) => serviceArea.zoom >= 10);
        shops = newShops;
        selectedShop = newSelectedShop;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  _setCurrentShopInPageView(Shop target, bool animate) {
    int targetPage = shops.indexWhere((shop) => shop.uuid == target.uuid);
    if (targetPage >= 0 && _pageController.hasClients) {
      if (animate) {
        _pageController.animateToPage(targetPage,
            duration: Duration(milliseconds: 600), curve: Curves.easeOutQuart);
      } else {
        _pageController.jumpToPage(targetPage);
      }
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
      _setCurrentShopInPageView(selectedShop, true);
    }
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
                    _setCurrentShopInPageView(shop, false);
                  });
            }).toSet(),
            myLocationButtonEnabled: false,
            onMapCreated: (googleMap) {
              _googleMapController.complete(googleMap);
            },
          ),
        ),
        Container(
          height: 280,
          child: PageView(
            controller: _pageController,
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
                      ShopDetail(shop: shop),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
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
          decoration: BoxDecoration(color: Colors.white),
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
