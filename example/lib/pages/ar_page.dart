import "package:u/utilities.dart";

import "../widgets/demo_section.dart";
import "../widgets/gallery_page.dart";

const String _astronautGlb = "https://modelviewer.dev/shared-assets/models/Astronaut.glb";
const String _astronautUsdz = "https://modelviewer.dev/shared-assets/models/Astronaut.usdz";
const String _chairGlb = "https://modelviewer.dev/shared-assets/models/glTF-Sample-Assets/Models/SheenChair/glTF-Binary/SheenChair.glb";
const String _posterImage = "https://picsum.photos/id/1025/800/600";

/// Every AR and 3D experience of the `u` plugin, each one call away.
class ArPage extends StatefulWidget {
  const ArPage({super.key});

  @override
  State<ArPage> createState() => _ArPageState();
}

class _ArPageState extends State<ArPage> {
  UArAvailability? _availability;

  @override
  void initState() {
    super.initState();
    unawaited(UAr.availability().then((UArAvailability value) => mounted ? setState(() => _availability = value) : null));
  }

  List<UArPlaceable> get _items => <UArPlaceable>[
    UArPlaceable(id: "astronaut", title: "Astronaut", source: UArSource.url(_astronautGlb), iosSource: UArSource.url(_astronautUsdz), surface: UArSurface.floor),
    UArPlaceable(id: "chair", title: "Chair", source: UArSource.url(_chairGlb), surface: UArSurface.floor, fitSize: 0.9),
    UArPlaceable(
      id: "frame",
      title: "Wall art",
      surface: UArSurface.wall,
      builder: (String id) => UArNode.image(
        id: id,
        source: UArSource.url(_posterImage, extension: "jpg"),
        width: 0.8,
        unlit: false,
      ),
    ),
    UArPlaceable(
      id: "cube",
      title: "Cube",
      surface: UArSurface.table,
      builder: (String id) => UArNode.box(
        id: id,
        width: 0.2,
        height: 0.2,
        depth: 0.2,
        material: const UArMaterial(color: Color(0xFF3F7CF4), metallic: 0.3, roughness: 0.35),
      ),
    ),
  ];

  Future<void> _places() async {
    final Position? found;
    try {
      found = await ULocation.getUserLocation();
    } catch (error) {
      UToast.error(message: "$error");
      return;
    }
    final Position? here = found;
    if (here == null) {
      UToast.error(message: "Turn on location and allow access to see places around you.");
      return;
    }
    final List<UArPlace> places = <UArPlace>[
      for (int i = 0; i < 6; i++)
        () {
          final List<double> p = UArGeo.offset(here.latitude, here.longitude, east: cos(i * pi / 3) * (40 + i * 25), north: sin(i * pi / 3) * (40 + i * 25));
          return UArPlace(id: "shop$i", latitude: p[0], longitude: p[1], title: "Shop ${i + 1}", subtitle: "20% off today", icon: Icons.storefront);
        }(),
    ];
    await UArExperiences.places(
      places: places,
      onPlaceTap: (UArPlace place) => UToast.info(message: place.title),
    );
  }

  @override
  Widget build(BuildContext context) {
    final UArCapabilities? caps = _availability?.capabilities;
    return GalleryPage(
      title: "AR & 3D",
      intro: "ARCore + OpenGL on Android, ARKit + RealityKit on iOS, WebXR + WebGL on the web. No pub packages; the 3D viewer works everywhere with no permission.",
      sections: <Widget>[
        DemoSection(
          title: "Device capabilities",
          description: "UAr.availability() reports what this device supports so UI can hide the rest.",
          code: "final UArAvailability a = await UAr.availability();\nif (a.capabilities.depth) { /* occlusion */ }",
          child: caps == null
              ? const LinearProgressIndicator()
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    Chip(label: UTextLabelSmall("status: ${_availability!.status.name}")),
                    for (final (String, bool) entry in <(String, bool)>[
                      ("world", caps.worldTracking),
                      ("walls", caps.planeVertical),
                      ("classification", caps.planeClassification),
                      ("depth", caps.depth),
                      ("people", caps.peopleOcclusion),
                      ("lidar", caps.lidar),
                      ("images", caps.imageTracking),
                      ("faces", caps.faceTracking),
                      ("body", caps.bodyTracking),
                      ("vps", caps.geospatial),
                      ("gps", caps.gpsGeo),
                      ("cloud", caps.cloudAnchors),
                      ("room", caps.roomPlan),
                      ("capture", caps.objectCapture),
                      ("ocr", caps.textRecognition),
                      ("webxr", caps.webXr),
                      ("quick look / scene viewer", caps.nativeViewer),
                    ])
                      Chip(avatar: Icon(entry.$2 ? Icons.check_circle : Icons.cancel, size: 16), label: UTextLabelSmall(entry.$1)),
                  ],
                ),
        ),
        DemoSection(
          title: "3D product viewer",
          description: "Drag to orbit, pinch to zoom, double-tap to reset. Hotspots are Flutter widgets pinned to the model.",
          code: "U3DViewer(\n  source: UArSource.url(\"…/Astronaut.glb\"),\n  iosSource: UArSource.url(\"…/Astronaut.usdz\"),\n  hotspots: <UArHotspot>[…],\n)",
          child: SizedBox(
            height: 340,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: U3DViewer(
                source: UArSource.url(_astronautGlb),
                iosSource: UArSource.url(_astronautUsdz),
                title: "Astronaut",
                hotspots: <UArHotspot>[
                  UArHotspot(
                    id: "helmet",
                    position: const UArVector3(0, 0.42, 0.1),
                    builder: (BuildContext context, UArProjection projection) => const Chip(label: UTextLabelSmall("Helmet")),
                  ),
                ],
              ),
            ),
          ),
        ),
        DemoSection(
          title: "Place in your space",
          description: "Floor, table and wall placement with move / rotate / scale, photo and video capture.",
          code: "UArExperiences.place(items: <UArPlaceable>[…]);",
          child: UButton(
            title: "Open",
            onTap: () => unawaited(UArExperiences.place(items: _items)),
          ),
        ),
        DemoSection(
          title: "Measuring tape",
          description: "Tap to drop points; closing the shape also gives the floor area.",
          code: "UArExperiences.measure(closeShape: true);",
          child: UButton(title: "Open", onTap: () => unawaited(UArExperiences.measure(closeShape: true))),
        ),
        DemoSection(
          title: "Shop cards around you",
          description: "Location-based cards: visual positioning where Google / Apple have mapped the street, GPS + compass everywhere else.",
          code: "UArExperiences.places(places: <UArPlace>[…]);",
          child: UButton(title: "Open", onTap: () => unawaited(_places())),
        ),
        DemoSection(
          title: "Image triggers",
          description: "Point at a known picture (poster, menu, packaging) to bring it to life.",
          code: "UArExperiences.images(targets: <UArImageTarget>[…]);",
          child: UButton(
            title: "Open",
            onTap: () => unawaited(
              UArExperiences.images(
                targets: <UArImageTarget>[
                  UArImageTarget(
                    name: "poster",
                    source: UArSource.url(_posterImage, extension: "jpg"),
                    physicalWidth: 0.3,
                    model: UArSource.url(_astronautGlb),
                    modelSize: 0.2,
                    overlayBuilder: (BuildContext context, UArTrackedImage image, UArProjection projection) => const Chip(label: UTextLabelMedium("Hello from the poster")),
                  ),
                ],
              ),
            ),
          ),
        ),
        DemoSection(
          title: "QR anchored cards",
          description: "Scans codes in the camera and pins a card where each one is.",
          code: "UArExperiences.codes(cardBuilder: (context, code, projection) => …);",
          child: UButton(
            title: "Open",
            onTap: () => unawaited(UArExperiences.codes(cardBuilder: (BuildContext context, String code, UArProjection projection) => Chip(label: UTextLabelMedium(code)))),
          ),
        ),
        DemoSection(
          title: "Face try-on",
          description: "Front camera; the item follows the head.",
          code: "UArExperiences.tryOn(items: <UArTryOnItem>[…]);",
          child: UButton(
            title: "Open",
            onTap: () => unawaited(
              UArExperiences.tryOn(
                items: <UArTryOnItem>[
                  UArTryOnItem(id: "astronaut", title: "Mini", source: UArSource.url(_astronautGlb), iosSource: UArSource.url(_astronautUsdz), fitSize: 0.12, position: const UArVector3(0, 0.14, 0)),
                ],
              ),
            ),
          ),
        ),
        DemoSection(
          title: "Native viewers",
          description: "Scene Viewer on Android, AR Quick Look on iOS and iOS Safari — no session of our own.",
          code: "UAr.openNativeViewer(UArNativeViewerOptions(source: …, iosSource: …));",
          child: UButton(
            title: "View in your space",
            onTap: () => unawaited(UAr.openNativeViewer(UArNativeViewerOptions(source: UArSource.url(_astronautGlb), iosSource: UArSource.url(_astronautUsdz), title: "Astronaut"))),
          ),
        ),
        DemoSection(
          title: "Room scan & object capture (iOS LiDAR)",
          description: "RoomPlan floor plans and on-device photogrammetry into USDZ.",
          code: "final UArRoomScanResult? room = await UArExperiences.scanRoom();",
          child: Wrap(
            spacing: 8,
            children: <Widget>[
              UButton(
                title: "Scan room",
                onTap: () async {
                  final UArRoomScanResult? room = await UArExperiences.scanRoom();
                  if (room != null) UToast.success(message: "${room.walls.length} walls, ${room.objects.length} objects");
                },
              ),
              UButton(
                title: "Capture object",
                onTap: () async {
                  final UArObjectCaptureResult? result = await UArExperiences.captureObject();
                  final String? path = result?.modelPath;
                  if (path != null) await UArExperiences.viewProduct(source: UArSource.file(path), iosSource: UArSource.file(path));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
