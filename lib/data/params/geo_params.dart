part of "../data.dart";

class UCountryCreateParams {
  UCountryCreateParams({
    required this.code,
    required this.title,
    this.tags,
    this.order,
    this.description,
    this.currency,
    this.languages,
    this.timeZone,
    this.callingCode,
    this.emergencyNumbers,
    this.embassies,
    this.tips,
  });

  /// ISO 3166-1 alpha-2, e.g. "AM".
  final String code;
  final String title;

  /// One status ([TagCountry.active], [TagCountry.comingSoon] or [TagCountry.inactive]) and any regions.
  final List<int>? tags;
  final int? order;
  final String? description;
  final String? currency;
  final List<String>? languages;
  final String? timeZone;
  final String? callingCode;
  final List<UGeoPhone>? emergencyNumbers;
  final List<UCountryEmbassy>? embassies;
  final List<UCountryTip>? tips;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "code": code,
    "title": title,
    "tags": tags ?? <int>[TagCountry.active.number],
    "order": order,
    "description": description,
    "currency": currency,
    "languages": languages,
    "timeZone": timeZone,
    "callingCode": callingCode,
    "emergencyNumbers": emergencyNumbers?.map((UGeoPhone x) => x.toMap()).toList(),
    "embassies": embassies?.map((UCountryEmbassy x) => x.toMap()).toList(),
    "tips": tips?.map((UCountryTip x) => x.toMap()).toList(),
  };
}

class UCountryUpdateParams {
  UCountryUpdateParams({
    required this.id,
    this.code,
    this.title,
    this.tags,
    this.order,
    this.description,
    this.currency,
    this.languages,
    this.timeZone,
    this.callingCode,
    this.emergencyNumbers,
    this.embassies,
    this.tips,
  });

  final String id;
  final String? code;
  final String? title;
  final List<int>? tags;
  final int? order;

  /// An empty string clears the text fields.
  final String? description;
  final String? currency;
  final List<String>? languages;
  final String? timeZone;
  final String? callingCode;
  final List<UGeoPhone>? emergencyNumbers;
  final List<UCountryEmbassy>? embassies;
  final List<UCountryTip>? tips;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "code": code,
    "title": title,
    "tags": tags,
    "order": order,
    "description": description,
    "currency": currency,
    "languages": languages,
    "timeZone": timeZone,
    "callingCode": callingCode,
    "emergencyNumbers": emergencyNumbers?.map((UGeoPhone x) => x.toMap()).toList(),
    "embassies": embassies?.map((UCountryEmbassy x) => x.toMap()).toList(),
    "tips": tips?.map((UCountryTip x) => x.toMap()).toList(),
  };
}

class UCountryReadParams {
  UCountryReadParams({this.title, this.passports, this.tags, this.selectorArgs, this.pageSize, this.pageNumber});

  /// Part of the title, or the exact code.
  final String? title;

  /// The traveller's passports; empty = the signed-in user's profile.
  final List<String>? passports;
  final List<int>? tags;
  final UCountrySelectorArgs? selectorArgs;
  final int? pageSize;
  final int? pageNumber;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "passports": passports,
    "tags": tags,
    "selectorArgs": selectorArgs?.toMap(),
    "pageSize": pageSize,
    "pageNumber": pageNumber,
  }..removeWhere((String _, dynamic v) => v == null);
}

class UCountryReadByIdParams {
  UCountryReadByIdParams({this.id, this.code, this.passports, this.selectorArgs});

  final String? id;

  /// Instead of [id]: the ISO alpha-2 code.
  final String? code;
  final List<String>? passports;
  final UCountrySelectorArgs? selectorArgs;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "code": code,
    "passports": passports,
    "selectorArgs": selectorArgs?.toMap(),
  }..removeWhere((String _, dynamic v) => v == null);
}

class UCityCreateParams {
  UCityCreateParams({required this.countryId, required this.title, this.tags, this.latitude, this.longitude, this.order, this.description, this.timeZone});

  final String countryId;
  final String title;
  final List<int>? tags;
  final double? latitude;
  final double? longitude;
  final int? order;
  final String? description;
  final String? timeZone;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "countryId": countryId,
    "title": title,
    "tags": tags ?? <int>[TagCity.active.number],
    "latitude": latitude,
    "longitude": longitude,
    "order": order,
    "description": description,
    "timeZone": timeZone,
  };
}

class UCityUpdateParams {
  UCityUpdateParams({required this.id, this.title, this.tags, this.latitude, this.longitude, this.order, this.description, this.timeZone});

  final String id;
  final String? title;
  final List<int>? tags;
  final double? latitude;
  final double? longitude;
  final int? order;
  final String? description;
  final String? timeZone;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "tags": tags,
    "latitude": latitude,
    "longitude": longitude,
    "order": order,
    "description": description,
    "timeZone": timeZone,
  };
}

class UCityReadParams {
  UCityReadParams({this.countryId, this.title, this.tags, this.selectorArgs, this.pageSize, this.pageNumber});

  final String? countryId;
  final String? title;
  final List<int>? tags;
  final UCitySelectorArgs? selectorArgs;
  final int? pageSize;
  final int? pageNumber;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "countryId": countryId,
    "title": title,
    "tags": tags,
    "selectorArgs": selectorArgs?.toMap(),
    "pageSize": pageSize,
    "pageNumber": pageNumber,
  }..removeWhere((String _, dynamic v) => v == null);
}

class UPlaceCreateParams {
  UPlaceCreateParams({
    required this.cityId,
    required this.title,
    required this.latitude,
    required this.longitude,
    this.categoryId,
    this.tags,
    this.description,
    this.address,
    this.phoneNumber,
    this.website,
    this.workingHours,
  });

  final String cityId;
  final String title;
  final double latitude;
  final double longitude;

  /// A shared category tagged [TagCategory.place].
  final String? categoryId;
  final List<int>? tags;
  final String? description;
  final String? address;
  final String? phoneNumber;
  final String? website;
  final List<UStoreWorkingDay>? workingHours;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "cityId": cityId,
    "title": title,
    "latitude": latitude,
    "longitude": longitude,
    "categoryId": categoryId,
    "tags": tags ?? <int>[TagPlace.active.number],
    "description": description,
    "address": address,
    "phoneNumber": phoneNumber,
    "website": website,
    "workingHours": workingHours?.map((UStoreWorkingDay x) => x.toMap()).toList(),
  };
}

class UPlaceUpdateParams {
  UPlaceUpdateParams({
    required this.id,
    this.cityId,
    this.categoryId,
    this.title,
    this.tags,
    this.latitude,
    this.longitude,
    this.description,
    this.address,
    this.phoneNumber,
    this.website,
    this.workingHours,
  });

  final String id;
  final String? cityId;

  /// The empty Guid (all zeros) takes the category away.
  final String? categoryId;
  final String? title;
  final List<int>? tags;
  final double? latitude;
  final double? longitude;
  final String? description;
  final String? address;
  final String? phoneNumber;
  final String? website;
  final List<UStoreWorkingDay>? workingHours;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "cityId": cityId,
    "categoryId": categoryId,
    "title": title,
    "tags": tags,
    "latitude": latitude,
    "longitude": longitude,
    "description": description,
    "address": address,
    "phoneNumber": phoneNumber,
    "website": website,
    "workingHours": workingHours?.map((UStoreWorkingDay x) => x.toMap()).toList(),
  };
}

class UPlaceReadParams {
  UPlaceReadParams({
    this.countryId,
    this.cityId,
    this.categoryId,
    this.title,
    this.tags,
    this.latitude,
    this.longitude,
    this.radiusKm,
    this.selectorArgs,
    this.pageSize,
    this.pageNumber,
  });

  final String? countryId;
  final String? cityId;
  final String? categoryId;
  final String? title;
  final List<int>? tags;

  /// Nearest first; with [radiusKm], only places inside it.
  final double? latitude;
  final double? longitude;
  final double? radiusKm;
  final UPlaceSelectorArgs? selectorArgs;
  final int? pageSize;
  final int? pageNumber;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "countryId": countryId,
    "cityId": cityId,
    "categoryId": categoryId,
    "title": title,
    "tags": tags,
    "latitude": latitude,
    "longitude": longitude,
    "radiusKm": radiusKm,
    "selectorArgs": selectorArgs?.toMap(),
    "pageSize": pageSize,
    "pageNumber": pageNumber,
  }..removeWhere((String _, dynamic v) => v == null);
}

class UVisaRuleCreateParams {
  UVisaRuleCreateParams({required this.passport, required this.countryId, required this.kind, this.maxStayDays, this.fee, this.notes, this.link, this.documents});

  /// ISO alpha-2 of the passport's country.
  final String passport;
  final String countryId;
  final TagVisaRule kind;
  final int? maxStayDays;
  final String? fee;
  final String? notes;
  final String? link;
  final List<String>? documents;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "passport": passport,
    "countryId": countryId,
    "tags": <int>[kind.number],
    "maxStayDays": maxStayDays,
    "fee": fee,
    "notes": notes,
    "link": link,
    "documents": documents,
  };
}

class UVisaRuleUpdateParams {
  UVisaRuleUpdateParams({required this.id, this.kind, this.maxStayDays, this.fee, this.notes, this.link, this.documents});

  final String id;
  final TagVisaRule? kind;

  /// 0 clears it.
  final int? maxStayDays;
  final String? fee;
  final String? notes;
  final String? link;
  final List<String>? documents;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "tags": kind == null ? null : <int>[kind!.number],
    "maxStayDays": maxStayDays,
    "fee": fee,
    "notes": notes,
    "link": link,
    "documents": documents,
  };
}

class UVisaRuleReadParams {
  UVisaRuleReadParams({this.passport, this.countryId, this.tags, this.selectorArgs, this.pageSize, this.pageNumber});

  final String? passport;
  final String? countryId;
  final List<int>? tags;
  final UVisaRuleSelectorArgs? selectorArgs;
  final int? pageSize;
  final int? pageNumber;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "passport": passport,
    "countryId": countryId,
    "tags": tags,
    "selectorArgs": selectorArgs?.toMap(),
    "pageSize": pageSize,
    "pageNumber": pageNumber,
  }..removeWhere((String _, dynamic v) => v == null);
}

class UPlaceVisitCreateParams {
  UPlaceVisitCreateParams({required this.placeId, this.latitude, this.longitude});

  final String placeId;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "placeId": placeId,
    "latitude": latitude,
    "longitude": longitude,
  }..removeWhere((String _, dynamic v) => v == null);
}

class UPlaceVisitReadParams {
  UPlaceVisitReadParams({this.countryId, this.cityId, this.placeId, this.selectorArgs, this.pageSize, this.pageNumber});

  final String? countryId;
  final String? cityId;
  final String? placeId;
  final UPlaceVisitSelectorArgs? selectorArgs;
  final int? pageSize;
  final int? pageNumber;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "countryId": countryId,
    "cityId": cityId,
    "placeId": placeId,
    "selectorArgs": selectorArgs?.toMap(),
    "pageSize": pageSize,
    "pageNumber": pageNumber,
  }..removeWhere((String _, dynamic v) => v == null);
}
