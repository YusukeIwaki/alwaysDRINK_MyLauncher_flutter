// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of google_maps_flutter;

/// Represents a point coordinate in the [GoogleMap]'s view.
///
/// The screen location is specified in screen pixels (not display pixels) relative
/// to the top left of the map, not top left of the whole screen. (x, y) = (0, 0)
/// corresponds to top-left of the [GoogleMap] not the whole screen.
@immutable
class ScreenCoordinate {
  const ScreenCoordinate({
    @required this.x,
    @required this.y,
  });

  final int x;
  final int y;

  dynamic _toJson() {
    return <String, int>{
      "x": x,
      "y": y,
    };
  }

  @override
  String toString() => '$runtimeType($x, $y)';

  @override
  bool operator ==(Object o) {
    return o is ScreenCoordinate && o.x == x && o.y == y;
  }

  @override
  int get hashCode => hashValues(x, y);
}
