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
        primarySwatch: alwaysDrinkColor,
        accentColor: alwaysDrinkAccentColor,
      ),
      home: Scaffold(
        body: ShopListPage(),
      ),
    );
  }
}

class ShopDetail extends StatelessWidget {
  const ShopDetail({this.shop});

  final Shop shop;

  Future<void> _saveAlwaysShopUuid(String uuid) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('shop_uuid', uuid);
  }

  Future<void> _openBrowser(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  FadeInImage _imageFor(Picture picture) {
    return FadeInImage(
      placeholder: NetworkImage(picture.smallUrl),
      image: NetworkImage(picture.largeUrl),
      fadeOutDuration: const Duration(milliseconds: 30),
      fadeInDuration: const Duration(milliseconds: 600),
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
              children: shop.pictures.map<Widget>((Picture picture) {
                return Padding(
                  padding: const EdgeInsets.all(8),
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
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 24,
              bottom: 16,
            ),
            child: Text(shop.description,
                style: Theme.of(context)
                    .textTheme
                    .body1
                    .merge(const TextStyle(height: 1.5))),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 24,
              bottom: 8,
            ),
            child: Text('営業時間', style: Theme.of(context).textTheme.subhead),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 32,
              right: 16,
              top: 8,
              bottom: 16,
            ),
            child: Text(shop.businessHoursDescription,
                style: Theme.of(context)
                    .textTheme
                    .body1
                    .merge(const TextStyle(height: 1.5))),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: <Widget>[
                OutlineButton(
                  child: const Text('SET AS ALWAYS'),
                  color: alwaysDrinkAccentColor,
                  textColor: alwaysDrinkAccentColor,
                  onPressed: () {
                    _saveAlwaysShopUuid(shop.uuid);
                    final SnackBar snackBar = SnackBar(
                      content: Text('${shop.name} が\n次回起動時からすぐ表示されます'),
                    );

                    // Find the Scaffold in the widget tree and use
                    // it to show a SnackBar.
                    Scaffold.of(context).showSnackBar(snackBar);
                  },
                ),
                const Spacer(),
                RaisedButton(
                  child: const Text('パスを表示'),
                  color: alwaysDrinkAccentColor,
                  textColor: Colors.white,
                  onPressed: () {
                    _openBrowser(
                        'https://always.fan/original/drink/user-subscription/751acbbe?p=${shop.uuid}');
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
  static const CameraPosition _initCameraPosition =
      CameraPosition(target: LatLng(34.6870728, 135.0490244), zoom: 5.0);
  final Completer<GoogleMapController> _googleMapController =
      Completer<GoogleMapController>();

  PageController _pageController;
  bool _isPageViewAnimating;

  Iterable<ServiceArea> serviceAreas = <ServiceArea>[];
  List<Shop> shops = <Shop>[];
  Shop selectedShop;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(
      viewportFraction: 0.95,
    );
    _isPageViewAnimating = false;
    _fetchShopList();
  }

  Future<String> _alwaysShopUuid() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('shop_uuid');
  }

  Future<void> _fetchShopList() async {
    final http.Response response = await http.get(
        'https://api.always.fan/mono/v2/pb/subscription-plan/751acbbe/provider');
    if (response.statusCode == 200) {
      // ignore: always_specify_types
      final responseJson = json.decode(response.body);
      // ignore: always_specify_types
      final Iterable places = responseJson['places'];
      // ignore: always_specify_types
      final List<ServiceArea> newServiceAreas = places.map((place) {
        final int zoom = place['zoom'];
        return ServiceArea(
          uuid: place['uuid'],
          name: place['name'],
          location: LatLng(place['lat'], place['lng']),
          zoom: zoom.toDouble(),
        );
      }).toList();

      // ignore: always_specify_types
      final Iterable menus = responseJson['menus'];
      // ignore: always_specify_types
      final List<Shop> newShops = menus.map((menu) {
        // ignore: always_specify_types
        final Iterable pictures = menu['pictures'];
        // ignore: always_specify_types
        final Iterable pbProviderPictures = menu['pbProvider']['pictures'];
        return Shop(
          uuid: menu['pbProvider']['uuid'],
          name: menu['pbProvider']['name'],
          description: menu['pbProvider']['description'],
          roughLocationDescription: menu['pbProvider']['area'],
          businessHoursDescription: menu['pbProvider']['businessHours'],
          location: LatLng(
            menu['pbProvider']['location']['lat'],
            menu['pbProvider']['location']['lon'],
          ),
          // ignore: always_specify_types
          thumbnail: pictures.map((picture) {
            return Picture(
              smallUrl: picture['pictureUrl']['smallUrl'],
              largeUrl: picture['pictureUrl']['largeUrl'],
            );
          }).first,
          // ignore: always_specify_types
          pictures: pbProviderPictures.map((picture) {
            return Picture(
              smallUrl: picture['pictureUrl']['smallUrl'],
              largeUrl: picture['pictureUrl']['largeUrl'],
            );
          }).toList(),
        );
      }).toList();

      final String alwaysShopUuid = await _alwaysShopUuid();
      Shop newSelectedShop;
      if (alwaysShopUuid != null) {
        try {
          newSelectedShop =
              newShops.firstWhere((Shop shop) => shop.uuid == alwaysShopUuid);
        } catch (err) {
          // エラー起きたときには初期フォーカスされないだけなので、特になにもしない。
        }
      }
      setState(() {
        serviceAreas = newServiceAreas
            .where((ServiceArea serviceArea) => serviceArea.zoom >= 10);
        shops = newShops;
      });
      if (newSelectedShop != null) {
        _updateSelectedShop(newSelectedShop);
      }
    }
  }

  void _updateSelectedShopForPage(int page) {
    if (page >= 0 && page < shops.length) {
      _updateSelectedShop(shops.elementAt(page));
    } else {
      _updateSelectedShop(null);
    }
  }

  void _updateSelectedShop(Shop newShop) {
    if (selectedShop?.uuid == newShop?.uuid) {
      return;
    }
    _hideInfoWindowForSelectedShop();
    setState(() {
      selectedShop = newShop;
    });
    _showInfoWindowForSelectedShop();
  }

  Future<void> _showInfoWindowForSelectedShop() async {
    if (selectedShop != null && _googleMapController.isCompleted) {
      final GoogleMapController googleMap = await _googleMapController.future;

      final MarkerId selectedShopMarker = MarkerId(selectedShop.uuid);
      final bool isSelectedShopMarkerShown =
          await googleMap.isMarkerInfoWindowShown(selectedShopMarker);
      if (!isSelectedShopMarkerShown) {
        await googleMap.showMarkerInfoWindow(selectedShopMarker);
      }
    }
  }

  Future<void> _hideInfoWindowForSelectedShop() async {
    if (selectedShop != null && _googleMapController.isCompleted) {
      final GoogleMapController googleMap = await _googleMapController.future;

      final MarkerId selectedShopMarker = MarkerId(selectedShop.uuid);
      final bool isSelectedShopMarkerShown =
          await googleMap.isMarkerInfoWindowShown(selectedShopMarker);
      if (isSelectedShopMarkerShown) {
        await googleMap.hideMarkerInfoWindow(selectedShopMarker);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  void _setCurrentShopInPageView(Shop target) {
    final int targetPage =
        shops.indexWhere((Shop shop) => shop.uuid == target.uuid);
    if (targetPage <= 0 || !_pageController.hasClients) {
      return;
    }
    final int currentPage = _pageController.page.toInt();
    if (targetPage == currentPage) {
      return;
    }

    _isPageViewAnimating = true;
    _pageController.animateToPage(
      targetPage,
      duration: Duration(milliseconds: 600),
      curve: Curves.easeOutQuart,
    ).then((_) {
      // animateToPageでアニメーション途中にも通知されてしまうバグのworkaround.
      // https://github.com/flutter/flutter/issues/43813
      _isPageViewAnimating = false;
      _updateSelectedShopForPage(targetPage);
    });
  }

  @override
  Widget build(BuildContext context) {
    _googleMapController.future.then((GoogleMapController googleMap) async {
      if (selectedShop != null) {
        final double zoom =
            selectedShop.nearestServiceAreaIn(serviceAreas).zoom;
        googleMap.animateCamera(
            CameraUpdate.newLatLngZoom(selectedShop.location, zoom));
        _showInfoWindowForSelectedShop();
      }
    });
    if (selectedShop != null) {
      _setCurrentShopInPageView(selectedShop);
    }
    return Column(
      children: <Widget>[
        Expanded(
          child: GoogleMap(
            initialCameraPosition: _initCameraPosition,
            markers: shops.map((Shop shop) {
              return Marker(
                  markerId: MarkerId(shop.uuid),
                  position: shop.location,
                  icon: shop.uuid == selectedShop?.uuid
                      ? BitmapDescriptor.defaultMarker
                      : BitmapDescriptor.defaultMarkerWithHue(180),
                  infoWindow: InfoWindow(title: shop.markerTitle()),
                  onTap: () {
                    _updateSelectedShop(shop);
                  });
            }).toSet(),
            myLocationButtonEnabled: false,
            onMapCreated: (GoogleMapController googleMap) {
              _googleMapController.complete(googleMap);
            },
          ),
        ),
        Container(
          height: 280,
          child: PageView(
            controller: _pageController,
            children: shops.map<Widget>((Shop shop) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  margin: EdgeInsets.zero,
                  shape: const RoundedRectangleBorder(
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
                          decoration: const BoxDecoration(
                              color: Color.fromARGB(0x99, 0, 0, 0)),
                          padding: const EdgeInsets.all(8),
                        ),
                      )
                    ],
                  ),
                ),
              );
            }).toList(),
            onPageChanged: (int page) {
              if (_isPageViewAnimating) {
                // animateToPageでアニメーション途中にも通知されてしまうバグのworkaround.
                // https://github.com/flutter/flutter/issues/43813
                return;
              }
              _updateSelectedShopForPage(page);
            },
          ),
          decoration: BoxDecoration(color: Colors.white),
        ),
      ],
    );
  }
}

class ShopListPage extends StatefulWidget {
  @override
  State createState() => ShopListPageState();
}
