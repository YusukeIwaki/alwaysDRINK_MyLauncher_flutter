import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

class AlwaysDrinkApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
          primarySwatch: alwaysDrinkColor,
          accentColor: alwaysDrinkAccentColor
      ),
      home: ShopListPage(),
    );
  }
}

class ShopListPage extends StatelessWidget {
  static CameraPosition _initCameraPosition = CameraPosition(
    target: LatLng(34.6870728, 135.0490244),
    zoom: 5.0
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: GoogleMap(
            initialCameraPosition: _initCameraPosition,
            onMapCreated: (googleMap) {
            },
          ),
        ),
        Container(
          height: 240,
          child: PageView(
            controller: PageController(
              viewportFraction: 0.95,
            ),
            children: List<Widget>.generate(20, (i){
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
                            children: List<Widget>.generate(20, (internalListIndex){
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  Container(
                                    padding: EdgeInsets.all(16),
                                    child: Text("internal content ${internalListIndex}"),
                                    decoration: BoxDecoration(color: Colors.yellow),
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
                          child: Text("Page: ${i}",
                            style: Theme.of(context).textTheme.subhead.merge(TextStyle(color: Colors.white)),
                          ),
                          decoration: BoxDecoration(color: Color.fromARGB(0x99, 0, 0, 0)),
                          padding: EdgeInsets.all(8),
                        ),
                      )
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
