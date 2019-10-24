import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'material_color.dart';
import 'models/picture.dart';
import 'models/service_area.dart';
import 'models/shop.dart';

void main() => runApp(AlwaysDrinkApp());


class AlwaysDrinkApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'always DRINK',
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

  FadeInImage _imageFor(Picture picture) {
    return FadeInImage(
      placeholder: NetworkImage(picture.smallUrl),
      image: NetworkImage(picture.largeUrl),
      fadeOutDuration: Duration(milliseconds: 30),
      fadeInDuration: Duration(milliseconds: 600),
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: ListView(
        children: <Widget>[
          _imageFor(shop.thumbnail),
          SizedBox(
            height: 220,
            child: ListView(
              children: shop.pictures.map<Widget>((picture) {
                return Padding(
                  padding: EdgeInsets.all(8),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    margin: EdgeInsets.zero,
                    child: _imageFor(picture),
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
      });
      if (newSelectedShop != null) {
        _setCurrentShopInPageView(newSelectedShop);
        setState(() {
          selectedShop = newSelectedShop;
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  _setCurrentShopInPageView(Shop target) {
    int targetPage = shops.indexWhere((shop) => shop.uuid == target.uuid);
    if (targetPage >= 0 && _pageController.hasClients) {
      _pageController.jumpToPage(targetPage);
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
                    _setCurrentShopInPageView(shop);
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
