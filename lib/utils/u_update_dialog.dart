import "package:u/utilities.dart";

enum UpdateType { none, optional, force }

class UUpdateResponse {
  final Os? android;
  final Os? ios;
  final Os? windows;
  final Os? macos;

  UUpdateResponse({
    this.android,
    this.ios,
    this.windows,
    this.macos,
  });

  factory UUpdateResponse.fromJson(String str) => UUpdateResponse.fromMap(json.decode(str));

  factory UUpdateResponse.fromMap(Map<String, dynamic> json) => UUpdateResponse(
    android: json["android"] == null ? null : Os.fromMap(json["android"]),
    ios: json["ios"] == null ? null : Os.fromMap(json["ios"]),
    windows: json["windows"] == null ? null : Os.fromMap(json["windows"]),
    macos: json["macos"] == null ? null : Os.fromMap(json["macos"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "android": android?.toMap(),
    "ios": ios?.toMap(),
    "windows": windows?.toMap(),
    "macos": macos?.toMap(),
  };

  String toJson() => json.encode(toMap());
}

class Os {
  final int? min;
  final int? current;
  final String? link1;
  final String? link2;
  final String? link1Title;
  final String? link2Title;

  Os({
    this.min,
    this.current,
    this.link1,
    this.link2,
    this.link1Title,
    this.link2Title,
  });

  factory Os.fromMap(Map<String, dynamic> json) => Os(
    min: json["min"],
    current: json["current"],
    link1: json["link1"],
    link2: json["link2"],
    link1Title: json["link1Title"],
    link2Title: json["link2Title"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "min": min,
    "current": current,
    "link1": link1,
    "link2": link2,
    "link1Title": link1Title,
    "link2Title": link2Title,
  };
}

class UUpdateDialog {
  static const String _skipKey = "skip_update_version";

  static Future<void> checkAndShow(
    UUpdateResponse serverData,
    VoidCallback onSkipOrNotAvailable,
  ) async {
    final Os? info = _platformUpdate(serverData);
    if (info == null) {
      onSkipOrNotAvailable();
      return;
    }

    final UpdateType type = await _checkUpdate(info);

    if (type == UpdateType.none) {
      onSkipOrNotAvailable();
      return;
    }

    // ✅ Skip check is ONLY for optional update
    if (type == UpdateType.optional) {
      final int? skipped = ULocalStorage.getInt(_skipKey);
      if (skipped == info.current) {
        onSkipOrNotAvailable();
        return;
      }
    }

    await showDialog(
      barrierDismissible: type == UpdateType.optional,
      context: navigatorKey.currentContext!,
      builder: (_) => WillPopScope(
        onWillPop: () async => type == UpdateType.optional,
        child: AlertDialog(
          title: Text(type == UpdateType.force ? "Update Required" : "Update Available"),
          content: UColumn(
            width: 200,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                type == UpdateType.force ? "You must update to continue using the app." : "A newer version of the app is available.",
              ),
              if (info.link1 != null && info.link1Title != null)
                UButton(
                  width: MediaQuery.sizeOf(navigatorKey.currentContext!).width,
                  onTap: () => ULaunch.launchURL(info.link1!),
                  title: info.link1Title ?? "---",
                ).pOnly(top: 8),
              if (info.link2 != null && info.link2Title != null)
                UButton(
                  width: MediaQuery.sizeOf(navigatorKey.currentContext!).width,
                  onTap: () => ULaunch.launchURL(info.link2!),
                  title: info.link2Title ?? "",
                ).pOnly(top: 8),
              if (type == UpdateType.optional)
                UButton(
                  width: MediaQuery.sizeOf(navigatorKey.currentContext!).width,
                  type: UButtonType.text,
                  textStyle: Theme.of(navigatorKey.currentContext!).textTheme.bodyMedium!.copyWith(color: Colors.red),
                  onTap: () => exit(0),
                  title: "Exit",
                ).pOnly(top: 8)
              else
                UButton(
                  width: MediaQuery.sizeOf(navigatorKey.currentContext!).width,
                  type: UButtonType.text,
                  title: "Later",
                  onTap: () {
                    if (info.current != null) {
                      ULocalStorage.set(_skipKey, info.current);
                    }
                    UNavigator.back();
                    onSkipOrNotAvailable();
                  },
                ).pOnly(top: 8),
            ],
          ),
        ),
      ),
    );
  }

  static Os? _platformUpdate(UUpdateResponse x) {
    if (UApp.isAndroid) return x.android;
    if (UApp.isIos) return x.ios;
    if (UApp.isWindows) return x.windows;
    if (UApp.isMacOs) return x.macos;
    return null;
  }

  static Future<UpdateType> _checkUpdate(Os info) async {
    if (info.min == null || info.current == null) return UpdateType.none;
    if (UApp.buildNumber.toInt() < info.min!) return UpdateType.force;
    if (UApp.buildNumber.toInt() < info.current!) return UpdateType.optional;
    return UpdateType.none;
  }
}
