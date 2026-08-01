import "package:u/utilities.dart";

enum UMapTileProvider {
  openStreetMap,
  mapBox,
  openTopoMap,
  stamenTerrain,
}

class UMap extends StatefulWidget {
  const UMap({
    required this.controller,
    this.center = const LatLng(51.509364, -0.128928),
    this.zoom = 10.0,
    this.minZoom = 3.0,
    this.maxZoom = 18.0,
    this.tileProvider = UMapTileProvider.openStreetMap,
    this.markers = const <Marker>[],
    this.polylines = const <Polyline<Object>>[],
    this.polygons = const <Polygon<Object>>[],
    this.centerWidget,
    this.zoomButtons = true,
    this.myLocationButton = true,
    this.currentLocationLayer = true,
    this.initOnUserLocation = false,
    this.showAttribution = true,
    this.onTap,
    this.onLongPress,
    this.onPositionChanged,
    this.onPointerUp,
    this.mapBoxAccessToken,
    super.key,
  });

  /// The map controller for programmatic control.
  final MapController controller;

  /// The initial center of the map.
  final LatLng center;

  /// The initial zoom level.
  final double zoom;

  /// The minimum zoom level.
  final double minZoom;

  /// The maximum zoom level.
  final double maxZoom;

  /// The tile provider for the map (e.g., OpenStreetMap, MapBox).
  final UMapTileProvider tileProvider;

  /// List of markers to display on the map.
  final List<Marker> markers;

  /// List of polylines to display on the map.
  final List<Polyline<Object>> polylines;

  /// List of polygons to display on the map.
  final List<Polygon<Object>> polygons;

  /// Widget to display at the map's center.
  final Widget? centerWidget;

  /// Whether to show zoom buttons.
  final bool zoomButtons;

  /// Whether to show a button to center on the user's location.
  final bool myLocationButton;

  /// Whether to show the user's current location as a layer.
  final bool currentLocationLayer;

  /// Whether to initialize the map centered on the user's location.
  final bool initOnUserLocation;

  /// Whether to show attribution for the tile provider.
  final bool showAttribution;

  /// Callback for tap events on the map.
  final void Function(TapPosition, LatLng)? onTap;

  /// Callback for long press events on the map.
  final void Function(TapPosition, LatLng)? onLongPress;

  /// Callback for when the map's position changes.
  final void Function(MapCamera, bool)? onPositionChanged;

  /// Callback for pointer up events on the map.
  final void Function(PointerUpEvent, LatLng)? onPointerUp;

  /// MapBox access token (required for MapBox tile provider).
  final String? mapBoxAccessToken;

  @override
  State<UMap> createState() => _UMapState();
}

class _UMapState extends State<UMap> {
  @override
  void initState() {
    super.initState();
    if (widget.initOnUserLocation) {
      _centerOnUserLocation();
    }
  }

  Future<void> _centerOnUserLocation() async {
    try {
      final Position? position = await _getUserLocation();
      if (mounted && position != null) {
        widget.controller.move(
          LatLng(position.latitude, position.longitude),
          widget.controller.camera.zoom,
        );
      }
    } catch (e) {
      debugPrint("Error getting user location: $e");
    }
  }

  Future<Position?> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  String _getTileUrlTemplate() {
    switch (widget.tileProvider) {
      case UMapTileProvider.openStreetMap:
        return "https://tile.openstreetmap.org/{z}/{x}/{y}.png";
      case UMapTileProvider.openTopoMap:
        return "https://a.tile.opentopomap.org/{z}/{x}/{y}.png";
      case UMapTileProvider.stamenTerrain:
        return "http://tile.stamen.com/terrain/{z}/{x}/{y}.jpg";
      case UMapTileProvider.mapBox:
        if (widget.mapBoxAccessToken == null) {
          throw Exception("MapBox access token is required for MapBox tile provider");
        }
        return "https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=${widget.mapBoxAccessToken}";
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: <Widget>[
      FlutterMap(
        mapController: widget.controller,
        options: MapOptions(
          initialCenter: widget.center,
          initialZoom: widget.zoom,
          minZoom: widget.minZoom,
          maxZoom: widget.maxZoom,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onPositionChanged: widget.onPositionChanged,
          onPointerUp: widget.onPointerUp,
        ),
        children: <Widget>[
          TileLayer(
            urlTemplate: _getTileUrlTemplate(),
            userAgentPackageName: "com.example.app",
            tileBuilder: widget.showAttribution
                ? (BuildContext context, Widget tileWidget, TileImage tile) => Stack(
                    children: <Widget>[
                      tileWidget,
                      if (widget.tileProvider == UMapTileProvider.openStreetMap)
                        const Positioned(
                          bottom: 5,
                          left: 5,
                          child: Text(
                            "© OpenStreetMap contributors",
                            style: TextStyle(fontSize: 10, color: Colors.black54),
                          ),
                        ),
                      if (widget.tileProvider == UMapTileProvider.openTopoMap)
                        const Positioned(
                          bottom: 5,
                          left: 5,
                          child: Text(
                            "© OpenTopoMap",
                            style: TextStyle(fontSize: 10, color: Colors.black54),
                          ),
                        ),
                      if (widget.tileProvider == UMapTileProvider.stamenTerrain)
                        const Positioned(
                          bottom: 5,
                          left: 5,
                          child: Text(
                            "© Stamen Design",
                            style: TextStyle(fontSize: 10, color: Colors.black54),
                          ),
                        ),
                      if (widget.tileProvider == UMapTileProvider.mapBox)
                        const Positioned(
                          bottom: 5,
                          left: 5,
                          child: Text(
                            "© Mapbox",
                            style: TextStyle(fontSize: 10, color: Colors.black54),
                          ),
                        ),
                    ],
                  )
                : null,
          ),
          if (widget.markers.isNotEmpty)
            MarkerLayer(
              markers: widget.markers,
            ),
          if (widget.polylines.isNotEmpty)
            PolylineLayer<Object>(
              polylines: widget.polylines,
            ),
          if (widget.polygons.isNotEmpty)
            PolygonLayer<Object>(
              polygons: widget.polygons,
            ),
        ],
      ),
      if (widget.myLocationButton)
        Positioned(
          bottom: 16,
          left: 16,
          child: FloatingActionButton(
            heroTag: "UMapFab1",
            mini: true,
            onPressed: _centerOnUserLocation,
            child: const Icon(Icons.my_location),
          ),
        ),
      if (widget.zoomButtons)
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            children: <Widget>[
              FloatingActionButton(
                heroTag: "UMapFab2",
                mini: true,
                onPressed: () => widget.controller.move(
                  widget.controller.camera.center,
                  widget.controller.camera.zoom + 1,
                ),
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: "UMapFab3",
                mini: true,
                onPressed: () => widget.controller.move(
                  widget.controller.camera.center,
                  widget.controller.camera.zoom - 1,
                ),
                child: const Icon(Icons.remove),
              ),
            ],
          ),
        ),
      if (widget.centerWidget != null)
        Align(
          child: widget.centerWidget,
        ),
    ],
  );
}

class DemoMap extends StatelessWidget {
  const DemoMap({super.key});

  @override
  Widget build(BuildContext context) {
    final MapController controller = MapController();

    final List<Marker> markers = <Marker>[
      const Marker(
        point: LatLng(51.509364, -0.128928),
        width: 40,
        height: 40,
        child: Icon(
          Icons.location_pin,
          color: Colors.red,
          size: 40,
        ),
      ),
      const Marker(
        point: LatLng(51.514364, -0.133928),
        width: 40,
        height: 40,
        child: Icon(
          Icons.location_pin,
          color: Colors.blue,
          size: 40,
        ),
      ),
    ];

    final List<Polyline<Object>> polylines = <Polyline<Object>>[
      Polyline<Object>(
        points: <LatLng>[
          const LatLng(51.509364, -0.128928),
          const LatLng(51.514364, -0.133928),
          const LatLng(51.510364, -0.138928),
        ],
        color: Colors.blue,
        strokeWidth: 4,
      ),
    ];

    final List<Polygon<Object>> polygons = <Polygon<Object>>[
      Polygon<Object>(
        points: <LatLng>[
          const LatLng(51.505364, -0.125928),
          const LatLng(51.507364, -0.130928),
          const LatLng(51.503364, -0.130928),
        ],
        color: Colors.green.withValues(alpha: 0.3),
        borderColor: Colors.green,
        borderStrokeWidth: 2,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Map Demo")),
      body: UMap(
        controller: controller,
        zoom: 12,
        markers: markers,
        polylines: polylines,
        polygons: polygons,
        centerWidget: const Icon(
          Icons.center_focus_strong,
          color: Colors.red,
          size: 24,
        ),
        onTap: (TapPosition position, LatLng point) {
          debugPrint("Tapped at: $point");
        },
        onLongPress: (TapPosition position, LatLng point) {
          debugPrint("Long pressed at: $point");
        },
        onPositionChanged: (MapCamera camera, bool hasGesture) {
          debugPrint("Map moved to: ${camera.center}, zoom: ${camera.zoom}");
        },
      ),
    );
  }
}

// class UMap extends StatefulWidget {
//   const UMap({
//     required this.controller,
//     super.key,
//     this.center = const LatLng(35, 55),
//     this.zoom = 10,
//     this.minZoom = 5,
//     this.maxZoom = 18,
//     this.markers,
//     this.centerWidget,
//     this.zoomButtons = true,
//     this.currentLocationLayer = true,
//     this.myLocationButton = true,
//     this.initOnUserLocation = true,
//     this.onTap,
//     this.onLongPress,
//     this.onPositionChanged,
//     this.onPointerUp,
//   });
//
//   final MapController controller;
//   final LatLng center;
//   final double zoom;
//   final double minZoom;
//   final double maxZoom;
//   final List<Marker>? markers;
//   final Widget? centerWidget;
//   final bool zoomButtons;
//   final bool currentLocationLayer;
//   final bool myLocationButton;
//   final bool initOnUserLocation;
//   final Function(TapPosition tapPosition, LatLng point)? onTap;
//   final Function(TapPosition tapPosition, LatLng point)? onLongPress;
//   final Function(MapCamera position, bool hasGesture)? onPositionChanged;
//   final Function(PointerUpEvent event, LatLng point)? onPointerUp;
//
//   @override
//   State<UMap> createState() => _UMapState();
// }
//
// class _UMapState extends State<UMap> {
//   @override
//   void initState() {
//     if (widget.initOnUserLocation) {
//       ULocation.getUserLocation(
//         onUserLocationFound: (final dynamic location) {
//           widget.controller.move(LatLng(location.latitude, location.longitude), widget.controller.camera.zoom);
//         },
//       );
//     }
//     super.initState();
//   }
//
//   @override
//   Widget build(final BuildContext context) => Stack(
//         children: <Widget>[
//           FlutterMap(
//             mapController: widget.controller,
//             options: MapOptions(
//               initialCenter: widget.center,
//               initialZoom: widget.zoom,
//               onTap: widget.onTap,
//               maxZoom: widget.maxZoom,
//               minZoom: widget.minZoom,
//               onLongPress: widget.onLongPress,
//               onPositionChanged: widget.onPositionChanged,
//               onPointerUp: widget.onPointerUp,
//             ),
//             children: <Widget>[
//               TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
//               MarkerLayer(markers: widget.markers ?? <Marker>[]),
//               if (widget.currentLocationLayer)
//                 const CurrentLocationLayer(
//                   alignDirectionOnUpdate: AlignOnUpdate.always,
//                   style: LocationMarkerStyle(
//                     markerSize: Size(16, 16),
//                     markerDirection: MarkerDirection.heading,
//                   ),
//                 ),
//             ],
//           ),
//           if (widget.myLocationButton)
//             FloatingActionButton(
//               heroTag: "UMapFab1",
//               mini: true,
//               onPressed: () async => ULocation.getUserLocation(
//                 onUserLocationFound: (final dynamic location) {
//                   widget.controller.move(LatLng(location.latitude, location.longitude), widget.controller.camera.zoom);
//                 },
//               ),
//               child: const Icon(Icons.my_location),
//             ).pAll(16).alignAtBottomLeft(),
//           if (widget.zoomButtons)
//             UIconTextVertical(
//               leading: FloatingActionButton(
//                 heroTag: "UMapFab2",
//                 mini: true,
//                 child: const Icon(Icons.add),
//                 onPressed: () => widget.controller.move(
//                   widget.controller.camera.center,
//                   widget.controller.camera.zoom + 1,
//                 ),
//               ),
//               trailing: FloatingActionButton(
//                 heroTag: "UMapFab3",
//                 mini: true,
//                 child: const Icon(Icons.remove),
//                 onPressed: () => widget.controller.move(
//                   widget.controller.camera.center,
//                   widget.controller.camera.zoom - 1,
//                 ),
//               ),
//             ).pAll(16).alignAtBottomRight(),
//           if (widget.centerWidget != null) Align(child: widget.centerWidget),
//         ],
//       );
// }
