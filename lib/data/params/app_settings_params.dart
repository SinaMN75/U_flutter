part of "../data.dart";

class UAppSettingsReadParams {
  UAppSettingsReadParams();

  Map<String, dynamic> toMap() => <String, dynamic>{};
}

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
