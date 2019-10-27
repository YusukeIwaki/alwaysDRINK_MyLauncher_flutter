import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'marker_cluster_layer.dart';
import 'marker_cluster_layer_options.dart';

class MarkerClusterPlugin extends MapPlugin {
  @override
  Widget createLayer(
      LayerOptions options, MapState mapState, Stream<void> stream) {
    return MarkerClusterLayer(options, mapState, stream);
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is MarkerClusterLayerOptions;
  }
}
