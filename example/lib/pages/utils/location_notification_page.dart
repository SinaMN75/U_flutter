import "package:u/utilities.dart";

import "../../demo/demo.dart";

/// ULocation and UNotification.
class LocationNotificationPage extends StatefulWidget {
  const LocationNotificationPage({super.key});

  @override
  State<LocationNotificationPage> createState() => _LocationNotificationPageState();
}

class _LocationNotificationPageState extends State<LocationNotificationPage> {
  StreamSubscription<UNotificationEvent>? _events;
  String _lastEvent = "none yet";

  UNotificationRequest _request(int id, String title) => UNotificationRequest(id: id, title: title, body: "From the u example", payload: <String, Object?>{"page": "orders"});

  @override
  void initState() {
    super.initState();
    _events = UNotification.listen((UNotificationEvent e) => setState(() => _lastEvent = "${e.type.name} #${e.id} ${e.payload}"));
  }

  @override
  void dispose() {
    _events?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DemoPage(
    title: "Location & notifications",
    intro: "Location needs `dart run u:app permission add location`; notifications need `permission add notifications` (and `alarm` for exact times on Android).",
    children: <Widget>[
      DemoGroup("Permission & state", <Widget>[
        Fn("await ULocation.permission()", ULocation.permission),
        Fn("await ULocation.requestPermission()", ULocation.requestPermission),
        Fn("await ULocation.ensureReady()", ULocation.ensureReady, note: "null = ready, else the reason"),
        Fn("await ULocation.isReady()", ULocation.isReady),
        Fn("await ULocation.isServiceEnabled()", ULocation.isServiceEnabled),
        Fn('ULocation.requestPrecise("Delivery")', () => ULocation.requestPrecise("Delivery"), note: "iOS 14+ only"),
        Fn("ULocation.openLocationSettings()", ULocation.openLocationSettings),
        Fn("ULocation.openAppSettings()", ULocation.openAppSettings),
      ]),
      DemoGroup("Position", <Widget>[
        Fn("await ULocation.current()", ULocation.current),
        Fn("await ULocation.position()", ULocation.position),
        Fn("await ULocation.lastKnown()", ULocation.lastKnown),
        Fn("ULocation.stream(ULocationSettings(distanceFilter: 5))", () => ULocation.stream(const ULocationSettings(distanceFilter: 5))),
        Fn("ULocation.heading()", ULocation.heading, note: "Android, iOS, Windows, mobile web"),
        Fn("ULocation.visits()", ULocation.visits, note: "iOS only"),
      ]),
      DemoGroup("Geofences", <Widget>[
        Fn("ULocation.addGeofence(UGeofence(id: 'home', …))", () => ULocation.addGeofence(const UGeofence(id: "home", latitude: 35.6997, longitude: 51.3380, radius: 300))),
        Fn("await ULocation.geofences()", ULocation.geofences),
        Fn("ULocation.geofenceEvents()", ULocation.geofenceEvents),
        Fn('ULocation.removeGeofence("home")', () => ULocation.removeGeofence("home")),
        Fn("ULocation.clearGeofences()", ULocation.clearGeofences),
      ]),
      DemoGroup("Addresses & math", <Widget>[
        Fn("await ULocation.isGeocodingAvailable()", ULocation.isGeocodingAvailable),
        Fn("await ULocation.addressOf(35.6997, 51.3380)", () => ULocation.addressOf(35.6997, 51.3380), note: "Android, iOS, macOS"),
        Fn('await ULocation.find("Azadi Tower, Tehran")', () => ULocation.find("Azadi Tower, Tehran")),
        Fn("ULocation.distance(Tehran → Isfahan) km", () => (ULocation.distance(35.6892, 51.3890, 32.6546, 51.6680) / 1000).toStringAsFixed(1), auto: true),
        Fn("ULocation.bearing(Tehran → Isfahan)", () => ULocation.bearing(35.6892, 51.3890, 32.6546, 51.6680).toStringAsFixed(1), auto: true),
      ]),
      DemoGroup("Notifications: permission", <Widget>[
        Fn("UNotification.init()", UNotification.init),
        Fn("await UNotification.permission()", UNotification.permission),
        Fn("await UNotification.requestPermission()", UNotification.requestPermission),
        Fn("await UNotification.isAllowed()", UNotification.isAllowed),
        Fn("UNotification.openSettings()", UNotification.openSettings),
        Fn("UNotification.requestExactAlarms()", UNotification.requestExactAlarms, note: "Android 12+"),
      ]),
      DemoGroup("Notifications: show", <Widget>[
        Fn('UNotification.show(1, title: "Hi", body: …)', () => UNotification.show(1, title: "Hello", body: "A simple notification")),
        Fn(
          "UNotification.showRequest(… actions, reply …)",
          () => UNotification.showRequest(
            UNotificationRequest(
              id: 2,
              title: "New message",
              body: "Sina: are you coming?",
              actions: const <UNotificationAction>[
                UNotificationAction(id: "yes", title: "Yes"),
                UNotificationAction(id: "reply", title: "Reply", input: true, inputPlaceholder: "Type…"),
              ],
            ),
          ),
        ),
        Fn('UNotification.progress(3, title: "Downloading", value: 40)', () => UNotification.progress(3, title: "Downloading", value: 40)),
        Demo("last event (UNotification.listen)", child: Text(_lastEvent)),
        Fn("UNotification.events (first event)", () => UNotification.events.first.timeout(const Duration(seconds: 5))),
        Fn("await UNotification.launchEvent()", UNotification.launchEvent),
        Fn("await UNotification.active()", UNotification.active),
      ]),
      DemoGroup("Notifications: schedule", <Widget>[
        Fn("UNotification.schedule(req, now + 10s)", () => UNotification.schedule(_request(10, "Scheduled"), DateTime.now().add(10.seconds))),
        Fn("UNotification.after(15.seconds, req)", () => UNotification.after(15.seconds, _request(11, "After 15 s"))),
        Fn("UNotification.daily(req, hour: 9)", () => UNotification.daily(_request(12, "Daily 09:00"), hour: 9)),
        Fn("UNotification.weekly(req, weekday: saturday, hour: 10)", () => UNotification.weekly(_request(13, "Weekly"), weekday: DateTime.saturday, hour: 10)),
        Fn("UNotification.monthlyJalali(req, day: 31, hour: 9)", () => UNotification.monthlyJalali(_request(14, "Rent"), day: 31, hour: 9), note: "Short months use their last day"),
        Fn("await UNotification.pending()", UNotification.pending),
        Fn("UNotification.cancel(10)", () => UNotification.cancel(10)),
        Fn('UNotification.cancelGroup("chat")', () => UNotification.cancelGroup("chat")),
        Fn("UNotification.cancelAll()", UNotification.cancelAll),
      ]),
      DemoGroup("Channels & badge", <Widget>[
        Fn("UNotification.createChannelGroup('shop', 'Shop')", () => UNotification.createChannelGroup("shop", "Shop"), note: "Android only"),
        Fn(
          "UNotification.createChannel(UNotificationChannel(id: 'orders', …))",
          () => UNotification.createChannel(const UNotificationChannel(id: "orders", name: "Orders", importance: UNotificationImportance.high)),
        ),
        Fn("await UNotification.channels()", UNotification.channels),
        Fn("UNotification.deleteChannel('orders')", () => UNotification.deleteChannel("orders")),
        Fn("UNotification.setBadge(3)", () => UNotification.setBadge(3)),
        Fn("UNotification.clearBadge()", UNotification.clearBadge),
      ]),
    ],
  );
}
