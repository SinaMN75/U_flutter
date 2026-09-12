part of "../data.dart";

class UBrokerCreateParams {
  UBrokerCreateParams({
    required this.tags,
    required this.title,
    required this.code,
    this.id,
    this.detail1,
    this.detail2,
    this.legalName,
    this.registrationNumber,
    this.nationalId,
    this.address,
    this.postalCode,
    this.phoneNumber,
    this.supportPhoneNumber,
    this.callCenterPhoneNumber,
    this.representativeName,
    this.representativeRole,
    this.logoBase64,
    this.themeColor,
    this.contractNumberSuffix,
    this.provider,
    this.providerBaseUrl,
    this.providerAuthHeader,
    this.providerProject,
    this.providerDefinitionTemplate,
    this.agreementTemplateId,
    this.signatories = const <UBrokerSignatory>[],
  });

  final List<int> tags;
  final String title;
  final String code;
  final String? id;
  final String? detail1;
  final String? detail2;
  final String? legalName;
  final String? registrationNumber;
  final String? nationalId;
  final String? address;
  final String? postalCode;
  final String? phoneNumber;
  final String? supportPhoneNumber;
  final String? callCenterPhoneNumber;
  final String? representativeName;
  final String? representativeRole;
  final String? logoBase64;
  final String? themeColor;
  final String? contractNumberSuffix;
  final int? provider;
  final String? providerBaseUrl;
  final String? providerAuthHeader;
  final String? providerProject;
  final int? providerDefinitionTemplate;
  final String? agreementTemplateId;
  final List<UBrokerSignatory> signatories;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "title": title,
    "code": code,
    "id": id,
    "detail1": detail1,
    "detail2": detail2,
    "legalName": legalName,
    "registrationNumber": registrationNumber,
    "nationalId": nationalId,
    "address": address,
    "postalCode": postalCode,
    "phoneNumber": phoneNumber,
    "supportPhoneNumber": supportPhoneNumber,
    "callCenterPhoneNumber": callCenterPhoneNumber,
    "representativeName": representativeName,
    "representativeRole": representativeRole,
    "logoBase64": logoBase64,
    "themeColor": themeColor,
    "contractNumberSuffix": contractNumberSuffix,
    "provider": provider,
    "providerBaseUrl": providerBaseUrl,
    "providerAuthHeader": providerAuthHeader,
    "providerProject": providerProject,
    "providerDefinitionTemplate": providerDefinitionTemplate,
    "agreementTemplateId": agreementTemplateId,
    "signatories": List<dynamic>.from(signatories.map((UBrokerSignatory x) => x.toMap())),
  };
}

class UBrokerUpdateParams {
  UBrokerUpdateParams({
    required this.id,
    this.title,
    this.code,
    this.detail1,
    this.detail2,
    this.tags,
    this.addTags,
    this.removeTags,
    this.legalName,
    this.registrationNumber,
    this.nationalId,
    this.address,
    this.postalCode,
    this.phoneNumber,
    this.supportPhoneNumber,
    this.callCenterPhoneNumber,
    this.representativeName,
    this.representativeRole,
    this.logoBase64,
    this.themeColor,
    this.contractNumberSuffix,
    this.provider,
    this.providerBaseUrl,
    this.providerAuthHeader,
    this.providerProject,
    this.providerDefinitionTemplate,
    this.agreementTemplateId,
    this.signatories,
  });

  final String id;
  final String? title;
  final String? code;
  final String? detail1;
  final String? detail2;
  final List<int>? tags;
  final List<int>? addTags;
  final List<int>? removeTags;
  final String? legalName;
  final String? registrationNumber;
  final String? nationalId;
  final String? address;
  final String? postalCode;
  final String? phoneNumber;
  final String? supportPhoneNumber;
  final String? callCenterPhoneNumber;
  final String? representativeName;
  final String? representativeRole;
  final String? logoBase64;
  final String? themeColor;
  final String? contractNumberSuffix;
  final int? provider;
  final String? providerBaseUrl;
  final String? providerAuthHeader;
  final String? providerProject;
  final int? providerDefinitionTemplate;
  final String? agreementTemplateId;
  final List<UBrokerSignatory>? signatories;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "code": code,
    "detail1": detail1,
    "detail2": detail2,
    "tags": tags == null ? null : List<dynamic>.from(tags!.map((int x) => x)),
    "addTags": addTags == null ? null : List<dynamic>.from(addTags!.map((int x) => x)),
    "removeTags": removeTags == null ? null : List<dynamic>.from(removeTags!.map((int x) => x)),
    "legalName": legalName,
    "registrationNumber": registrationNumber,
    "nationalId": nationalId,
    "address": address,
    "postalCode": postalCode,
    "phoneNumber": phoneNumber,
    "supportPhoneNumber": supportPhoneNumber,
    "callCenterPhoneNumber": callCenterPhoneNumber,
    "representativeName": representativeName,
    "representativeRole": representativeRole,
    "logoBase64": logoBase64,
    "themeColor": themeColor,
    "contractNumberSuffix": contractNumberSuffix,
    "provider": provider,
    "providerBaseUrl": providerBaseUrl,
    "providerAuthHeader": providerAuthHeader,
    "providerProject": providerProject,
    "providerDefinitionTemplate": providerDefinitionTemplate,
    "agreementTemplateId": agreementTemplateId,
    "signatories": signatories == null ? null : List<dynamic>.from(signatories!.map((UBrokerSignatory x) => x.toMap())),
  };
}

class UBrokerReadParams {
  UBrokerReadParams({
    this.pageSize,
    this.pageNumber,
    this.tags,
    this.ids,
    this.title,
    this.code,
    this.orderBy,
    this.selectorArgs,
  });

  final int? pageSize;
  final int? pageNumber;
  final List<int>? tags;
  final List<String>? ids;
  final String? title;
  final String? code;
  final int? orderBy;
  final BrokerSelectorArgs? selectorArgs;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "ids": ids == null ? <dynamic>[] : List<dynamic>.from(ids!.map((String x) => x)),
    "title": title,
    "code": code,
    "orderBy": orderBy,
    "selectorArgs": selectorArgs?.toMap(),
  };
}

class UTerminalBrandCreateParams {
  UTerminalBrandCreateParams({
    required this.tags,
    required this.title,
    required this.code,
    required this.brokerId,
    this.id,
    this.detail1,
    this.detail2,
    this.requiresSimCardSerial,
    this.requiresImei,
    this.imageBase64,
    this.order,
    this.agreementTemplateId,
    this.legacyTag,
  });

  final List<int> tags;
  final String title;
  final String code;
  final String brokerId;
  final String? id;
  final String? detail1;
  final String? detail2;
  final bool? requiresSimCardSerial;
  final bool? requiresImei;
  final String? imageBase64;
  final int? order;
  final String? agreementTemplateId;
  final int? legacyTag;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "title": title,
    "code": code,
    "brokerId": brokerId,
    "id": id,
    "detail1": detail1,
    "detail2": detail2,
    "requiresSimCardSerial": requiresSimCardSerial,
    "requiresImei": requiresImei,
    "imageBase64": imageBase64,
    "order": order,
    "agreementTemplateId": agreementTemplateId,
    "legacyTag": legacyTag,
  };
}

class UTerminalBrandUpdateParams {
  UTerminalBrandUpdateParams({
    required this.id,
    this.title,
    this.code,
    this.brokerId,
    this.detail1,
    this.detail2,
    this.tags,
    this.addTags,
    this.removeTags,
    this.requiresSimCardSerial,
    this.requiresImei,
    this.imageBase64,
    this.order,
    this.agreementTemplateId,
    this.legacyTag,
  });

  final String id;
  final String? title;
  final String? code;
  final String? brokerId;
  final String? detail1;
  final String? detail2;
  final List<int>? tags;
  final List<int>? addTags;
  final List<int>? removeTags;
  final bool? requiresSimCardSerial;
  final bool? requiresImei;
  final String? imageBase64;
  final int? order;
  final String? agreementTemplateId;
  final int? legacyTag;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "code": code,
    "brokerId": brokerId,
    "detail1": detail1,
    "detail2": detail2,
    "tags": tags == null ? null : List<dynamic>.from(tags!.map((int x) => x)),
    "addTags": addTags == null ? null : List<dynamic>.from(addTags!.map((int x) => x)),
    "removeTags": removeTags == null ? null : List<dynamic>.from(removeTags!.map((int x) => x)),
    "requiresSimCardSerial": requiresSimCardSerial,
    "requiresImei": requiresImei,
    "imageBase64": imageBase64,
    "order": order,
    "agreementTemplateId": agreementTemplateId,
    "legacyTag": legacyTag,
  };
}

class UTerminalBrandReadParams {
  UTerminalBrandReadParams({
    this.pageSize,
    this.pageNumber,
    this.tags,
    this.ids,
    this.title,
    this.code,
    this.brokerId,
    this.orderBy,
    this.selectorArgs,
  });

  final int? pageSize;
  final int? pageNumber;
  final List<int>? tags;
  final List<String>? ids;
  final String? title;
  final String? code;
  final String? brokerId;
  final int? orderBy;
  final TerminalBrandSelectorArgs? selectorArgs;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "ids": ids == null ? <dynamic>[] : List<dynamic>.from(ids!.map((String x) => x)),
    "title": title,
    "code": code,
    "brokerId": brokerId,
    "orderBy": orderBy,
    "selectorArgs": selectorArgs?.toMap(),
  };
}

class UAgreementTemplateCreateParams {
  UAgreementTemplateCreateParams({
    required this.tags,
    required this.title,
    required this.code,
    this.id,
    this.detail1,
    this.detail2,
    this.headerTitle,
    this.blocks = const <UAgreementTemplateBlock>[],
  });

  final List<int> tags;
  final String title;
  final String code;
  final String? id;
  final String? detail1;
  final String? detail2;
  final String? headerTitle;
  final List<UAgreementTemplateBlock> blocks;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "title": title,
    "code": code,
    "id": id,
    "detail1": detail1,
    "detail2": detail2,
    "headerTitle": headerTitle,
    "blocks": List<dynamic>.from(blocks.map((UAgreementTemplateBlock x) => x.toMap())),
  };
}

class UAgreementTemplateUpdateParams {
  UAgreementTemplateUpdateParams({
    required this.id,
    this.title,
    this.code,
    this.detail1,
    this.detail2,
    this.tags,
    this.addTags,
    this.removeTags,
    this.headerTitle,
    this.blocks,
  });

  final String id;
  final String? title;
  final String? code;
  final String? detail1;
  final String? detail2;
  final List<int>? tags;
  final List<int>? addTags;
  final List<int>? removeTags;
  final String? headerTitle;
  final List<UAgreementTemplateBlock>? blocks;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "code": code,
    "detail1": detail1,
    "detail2": detail2,
    "tags": tags == null ? null : List<dynamic>.from(tags!.map((int x) => x)),
    "addTags": addTags == null ? null : List<dynamic>.from(addTags!.map((int x) => x)),
    "removeTags": removeTags == null ? null : List<dynamic>.from(removeTags!.map((int x) => x)),
    "headerTitle": headerTitle,
    "blocks": blocks == null ? null : List<dynamic>.from(blocks!.map((UAgreementTemplateBlock x) => x.toMap())),
  };
}

class UAgreementTemplateReadParams {
  UAgreementTemplateReadParams({
    this.pageSize,
    this.pageNumber,
    this.tags,
    this.ids,
    this.title,
    this.code,
    this.orderBy,
    this.selectorArgs,
  });

  final int? pageSize;
  final int? pageNumber;
  final List<int>? tags;
  final List<String>? ids;
  final String? title;
  final String? code;
  final int? orderBy;
  final AgreementTemplateSelectorArgs? selectorArgs;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "ids": ids == null ? <dynamic>[] : List<dynamic>.from(ids!.map((String x) => x)),
    "title": title,
    "code": code,
    "orderBy": orderBy,
    "selectorArgs": selectorArgs?.toMap(),
  };
}
