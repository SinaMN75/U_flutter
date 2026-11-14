part of "../data.dart";

class UGeoPhone {
  UGeoPhone({required this.kind, required this.number});

  factory UGeoPhone.fromMap(Map<String, dynamic> json) => UGeoPhone(
    kind: TagEmergencyNumber.values.firstWhereOrNull((TagEmergencyNumber x) => x.number == json["kind"]) ?? TagEmergencyNumber.general,
    number: json["number"] ?? "",
  );

  final TagEmergencyNumber kind;
  final String number;

  Map<String, dynamic> toMap() => <String, dynamic>{"kind": kind.number, "number": number};
}

/// The embassy of [country] inside the country it is listed on.
class UCountryEmbassy {
  UCountryEmbassy({required this.country, this.city, this.address, this.phoneNumber, this.website});

  factory UCountryEmbassy.fromMap(Map<String, dynamic> json) => UCountryEmbassy(
    country: json["country"] ?? "",
    city: json["city"],
    address: json["address"],
    phoneNumber: json["phoneNumber"],
    website: json["website"],
  );

  final String country;
  final String? city;
  final String? address;
  final String? phoneNumber;
  final String? website;

  Map<String, dynamic> toMap() => <String, dynamic>{"country": country, "city": city, "address": address, "phoneNumber": phoneNumber, "website": website};
}

/// A local tip; empty [passports] = for every traveller.
class UCountryTip {
  UCountryTip({required this.title, this.passports = const <String>[], this.text});

  factory UCountryTip.fromMap(Map<String, dynamic> json) => UCountryTip(
    title: json["title"] ?? "",
    passports: json["passports"] == null ? const <String>[] : List<String>.from(json["passports"].map((dynamic x) => x)),
    text: json["text"],
  );

  final String title;
  final List<String> passports;
  final String? text;

  Map<String, dynamic> toMap() => <String, dynamic>{"title": title, "passports": passports, "text": text};
}

class UCountryJson {
  UCountryJson({
    this.description,
    this.currency,
    this.languages = const <String>[],
    this.timeZone,
    this.callingCode,
    this.emergencyNumbers = const <UGeoPhone>[],
    this.embassies = const <UCountryEmbassy>[],
    this.tips = const <UCountryTip>[],
  });

  factory UCountryJson.fromMap(Map<String, dynamic> json) => UCountryJson(
    description: json["description"],
    currency: json["currency"],
    languages: json["languages"] == null ? const <String>[] : List<String>.from(json["languages"].map((dynamic x) => x)),
    timeZone: json["timeZone"],
    callingCode: json["callingCode"],
    emergencyNumbers: json["emergencyNumbers"] == null ? const <UGeoPhone>[] : List<UGeoPhone>.from(json["emergencyNumbers"].map((dynamic x) => UGeoPhone.fromMap(x))),
    embassies: json["embassies"] == null ? const <UCountryEmbassy>[] : List<UCountryEmbassy>.from(json["embassies"].map((dynamic x) => UCountryEmbassy.fromMap(x))),
    tips: json["tips"] == null ? const <UCountryTip>[] : List<UCountryTip>.from(json["tips"].map((dynamic x) => UCountryTip.fromMap(x))),
  );

  final String? description;
  final String? currency;
  final List<String> languages;
  final String? timeZone;
  final String? callingCode;
  final List<UGeoPhone> emergencyNumbers;

  /// For a traveller: only the embassies of their passports' countries.
  final List<UCountryEmbassy> embassies;

  /// For a traveller: only the general tips and the ones for their passports.
  final List<UCountryTip> tips;
}

class UCountryResponse {
  UCountryResponse({
    required this.id,
    required this.createdAt,
    required this.tags,
    required this.jsonData,
    required this.code,
    required this.title,
    this.order = 0,
    this.cityCount = 0,
    this.placeCount = 0,
    this.utcOffsetMinutes,
    this.progress,
    this.visa,
    this.cities,
    this.visaRules,
    this.media,
  });

  factory UCountryResponse.fromMap(Map<String, dynamic> json) => UCountryResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    jsonData: UCountryJson.fromMap(json["jsonData"] ?? <String, dynamic>{}),
    code: json["code"],
    title: json["title"],
    order: json["order"] ?? 0,
    cityCount: json["cityCount"] ?? 0,
    placeCount: json["placeCount"] ?? 0,
    utcOffsetMinutes: json["utcOffsetMinutes"],
    progress: json["progress"] == null ? null : UGeoProgress.fromMap(json["progress"]),
    visa: json["visa"] == null ? null : UVisaRuleResponse.fromMap(json["visa"]),
    cities: json["cities"] == null ? null : List<UCityResponse>.from(json["cities"].map((dynamic x) => UCityResponse.fromMap(x))),
    visaRules: json["visaRules"] == null ? null : List<UVisaRuleResponse>.from(json["visaRules"].map((dynamic x) => UVisaRuleResponse.fromMap(x))),
    media: json["media"] == null ? null : List<UMediaResponse>.from(json["media"].map((dynamic x) => UMediaResponse.fromMap(x))),
  );

  final String id;
  final DateTime createdAt;
  final List<int> tags;
  final UCountryJson jsonData;
  final String code;
  final String title;
  final int order;
  final int cityCount;

  /// Active places.
  final int placeCount;

  /// The current offset of [UCountryJson.timeZone]; null when the time zone is not set.
  final int? utcOffsetMinutes;

  /// How much of the country the signed-in traveller has visited; null for guests.
  final UGeoProgress? progress;

  /// The easiest rule among the traveller's passports; null when no passport is known or there is no rule.
  final UVisaRuleResponse? visa;
  final List<UCityResponse>? cities;
  final List<UVisaRuleResponse>? visaRules;
  final List<UMediaResponse>? media;

  bool get isComingSoon => tags.contains(TagCountry.comingSoon.number);

  bool get isInactive => tags.contains(TagCountry.inactive.number);

  /// The entry kit items (3xx) this country offers, in tag order.
  List<TagCountry> get entryKit => TagCountry.values.where((TagCountry t) => t.number ~/ 100 == 3 && tags.contains(t.number)).toList();
}

/// Active places of a country or city and how many of them the traveller has visited.
class UGeoProgress {
  UGeoProgress({this.places = 0, this.visited = 0, this.percent = 0, this.visitedCities = 0});

  factory UGeoProgress.fromMap(Map<String, dynamic> json) => UGeoProgress(
    places: json["places"] ?? 0,
    visited: json["visited"] ?? 0,
    percent: json["percent"] ?? 0,
    visitedCities: json["visitedCities"] ?? 0,
  );

  final int places;
  final int visited;
  final int percent;

  /// Countries only.
  final int visitedCities;
}

class UCityJson {
  UCityJson({this.description, this.timeZone});

  factory UCityJson.fromMap(Map<String, dynamic> json) => UCityJson(description: json["description"], timeZone: json["timeZone"]);

  final String? description;

  /// Null = the country's.
  final String? timeZone;
}

class UCityResponse {
  UCityResponse({
    required this.id,
    required this.createdAt,
    required this.tags,
    required this.jsonData,
    required this.title,
    required this.countryId,
    this.latitude,
    this.longitude,
    this.order = 0,
    this.placeCount = 0,
    this.utcOffsetMinutes,
    this.progress,
    this.country,
    this.media,
  });

  factory UCityResponse.fromMap(Map<String, dynamic> json) => UCityResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    jsonData: UCityJson.fromMap(json["jsonData"] ?? <String, dynamic>{}),
    title: json["title"],
    countryId: json["countryId"],
    latitude: json["latitude"]?.toDouble(),
    longitude: json["longitude"]?.toDouble(),
    order: json["order"] ?? 0,
    placeCount: json["placeCount"] ?? 0,
    utcOffsetMinutes: json["utcOffsetMinutes"],
    progress: json["progress"] == null ? null : UGeoProgress.fromMap(json["progress"]),
    country: json["country"] == null ? null : UCountryResponse.fromMap(json["country"]),
    media: json["media"] == null ? null : List<UMediaResponse>.from(json["media"].map((dynamic x) => UMediaResponse.fromMap(x))),
  );

  final String id;
  final DateTime createdAt;
  final List<int> tags;
  final UCityJson jsonData;
  final String title;
  final String countryId;
  final double? latitude;
  final double? longitude;
  final int order;
  final int placeCount;

  /// The current offset of the city's own time zone; null = the country's.
  final int? utcOffsetMinutes;

  /// Null for guests.
  final UGeoProgress? progress;
  final UCountryResponse? country;
  final List<UMediaResponse>? media;

  bool get isActive => tags.contains(TagCity.active.number);
}

class UPlaceJson {
  UPlaceJson({this.description, this.address, this.phoneNumber, this.website, this.workingHours = const <UStoreWorkingDay>[]});

  factory UPlaceJson.fromMap(Map<String, dynamic> json) => UPlaceJson(
    description: json["description"],
    address: json["address"],
    phoneNumber: json["phoneNumber"],
    website: json["website"],
    workingHours: json["workingHours"] == null ? const <UStoreWorkingDay>[] : List<UStoreWorkingDay>.from(json["workingHours"].map((dynamic x) => UStoreWorkingDay.fromMap(x))),
  );

  final String? description;
  final String? address;
  final String? phoneNumber;
  final String? website;

  /// Empty = not known.
  final List<UStoreWorkingDay> workingHours;
}

class UPlaceResponse {
  UPlaceResponse({
    required this.id,
    required this.createdAt,
    required this.tags,
    required this.jsonData,
    required this.title,
    required this.cityId,
    required this.countryId,
    this.latitude = 0,
    this.longitude = 0,
    this.categoryId,
    this.distanceKm,
    this.visited,
    this.city,
    this.category,
    this.media,
  });

  factory UPlaceResponse.fromMap(Map<String, dynamic> json) => UPlaceResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    jsonData: UPlaceJson.fromMap(json["jsonData"] ?? <String, dynamic>{}),
    title: json["title"],
    cityId: json["cityId"],
    countryId: json["countryId"],
    latitude: json["latitude"]?.toDouble() ?? 0,
    longitude: json["longitude"]?.toDouble() ?? 0,
    categoryId: json["categoryId"],
    distanceKm: json["distanceKm"]?.toDouble(),
    visited: json["visited"],
    city: json["city"] == null ? null : UCityResponse.fromMap(json["city"]),
    category: json["category"] == null ? null : UCategoryResponse.fromMap(json["category"]),
    media: json["media"] == null ? null : List<UMediaResponse>.from(json["media"].map((dynamic x) => UMediaResponse.fromMap(x))),
  );

  final String id;
  final DateTime createdAt;
  final List<int> tags;
  final UPlaceJson jsonData;
  final String title;
  final String cityId;
  final String countryId;
  final double latitude;
  final double longitude;
  final String? categoryId;

  /// When read near a point.
  final double? distanceKm;

  /// By the signed-in traveller; null for guests.
  final bool? visited;
  final UCityResponse? city;
  final UCategoryResponse? category;
  final List<UMediaResponse>? media;

  bool get isActive => tags.contains(TagPlace.active.number);
}

class UPlaceVisitJson {
  UPlaceVisitJson({this.latitude, this.longitude});

  factory UPlaceVisitJson.fromMap(Map<String, dynamic> json) => UPlaceVisitJson(latitude: json["latitude"]?.toDouble(), longitude: json["longitude"]?.toDouble());

  /// Where the traveller was when marking the place.
  final double? latitude;
  final double? longitude;
}

class UPlaceVisitResponse {
  UPlaceVisitResponse({
    required this.id,
    required this.createdAt,
    required this.tags,
    required this.jsonData,
    required this.placeId,
    required this.cityId,
    required this.countryId,
    this.place,
  });

  factory UPlaceVisitResponse.fromMap(Map<String, dynamic> json) => UPlaceVisitResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    jsonData: UPlaceVisitJson.fromMap(json["jsonData"] ?? <String, dynamic>{}),
    placeId: json["placeId"],
    cityId: json["cityId"],
    countryId: json["countryId"],
    place: json["place"] == null ? null : UPlaceResponse.fromMap(json["place"]),
  );

  final String id;
  final DateTime createdAt;
  final List<int> tags;
  final UPlaceVisitJson jsonData;
  final String placeId;
  final String cityId;
  final String countryId;
  final UPlaceResponse? place;
}

class UVisaRuleJson {
  UVisaRuleJson({this.maxStayDays, this.fee, this.notes, this.link, this.documents = const <String>[]});

  factory UVisaRuleJson.fromMap(Map<String, dynamic> json) => UVisaRuleJson(
    maxStayDays: json["maxStayDays"],
    fee: json["fee"],
    notes: json["notes"],
    link: json["link"],
    documents: json["documents"] == null ? const <String>[] : List<String>.from(json["documents"].map((dynamic x) => x)),
  );

  final int? maxStayDays;
  final String? fee;
  final String? notes;
  final String? link;
  final List<String> documents;
}

class UVisaRuleResponse {
  UVisaRuleResponse({required this.id, required this.createdAt, required this.tags, required this.jsonData, required this.passport, required this.countryId, this.country});

  factory UVisaRuleResponse.fromMap(Map<String, dynamic> json) => UVisaRuleResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    jsonData: UVisaRuleJson.fromMap(json["jsonData"] ?? <String, dynamic>{}),
    passport: json["passport"],
    countryId: json["countryId"],
    country: json["country"] == null ? null : UCountryResponse.fromMap(json["country"]),
  );

  final String id;
  final DateTime createdAt;
  final List<int> tags;
  final UVisaRuleJson jsonData;
  final String passport;
  final String countryId;
  final UCountryResponse? country;

  TagVisaRule? get kind => TagVisaRule.values.firstWhereOrNull((TagVisaRule x) => tags.contains(x.number));
}
