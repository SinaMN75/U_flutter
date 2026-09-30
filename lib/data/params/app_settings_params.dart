part of "../data.dart";

class UAppSettingsUpdateParams {
  UAppSettingsUpdateParams({required this.settings});

  final UAppSettings settings;

  Map<String, dynamic> toMap() => <String, dynamic>{"settings": settings.toMap()};

  factory UAppSettingsUpdateParams.fromMap(Map<String, dynamic> json) => UAppSettingsUpdateParams(
    settings: UAppSettings.fromMap(json["settings"]),
  );

  String toJson() => json.encode(toMap());

  factory UAppSettingsUpdateParams.fromJson(String str) => UAppSettingsUpdateParams.fromMap(json.decode(str));
}

class UAppVersionUpdateParams {
  UAppVersionUpdateParams({
    required this.platform,
    required this.latestBuildNumber,
    required this.minBuildNumber,
    this.latestVersionName,
    this.description,
    this.links = const <UAppVersionLink>[],
  });

  final TagAppVersion platform;
  final int latestBuildNumber;
  final int minBuildNumber;
  final String? latestVersionName;
  final String? description;
  final List<UAppVersionLink> links;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "platform": platform.number,
    "latestBuildNumber": latestBuildNumber,
    "minBuildNumber": minBuildNumber,
    "latestVersionName": latestVersionName,
    "description": description,
    "links": List<dynamic>.from(links.map((UAppVersionLink x) => x.toMap())),
  };
}
