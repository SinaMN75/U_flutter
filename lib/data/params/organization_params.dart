part of "../data.dart";

class UOrganizationCreateParams {
  UOrganizationCreateParams({
    required this.title,
    required this.ownerId,
    this.tags = const <int>[101],
    this.ownerPassword,
    this.commissionPercent = 0,
  });

  final String title;
  final String ownerId;
  final List<int> tags;
  final String? ownerPassword;
  final double commissionPercent;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "ownerId": ownerId,
    "tags": tags,
    "ownerPassword": ownerPassword,
    "commissionPercent": commissionPercent,
  };
}

class UOrganizationUpdateParams {
  UOrganizationUpdateParams({
    required this.id,
    this.title,
    this.ownerId,
    this.ownerPassword,
    this.commissionPercent,
    this.tags,
    this.addTags,
    this.removeTags,
  });

  final String id;
  final String? title;
  final String? ownerId;
  final String? ownerPassword;
  final double? commissionPercent;
  final List<int>? tags;
  final List<int>? addTags;
  final List<int>? removeTags;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "ownerId": ownerId,
    "ownerPassword": ownerPassword,
    "commissionPercent": commissionPercent,
    "tags": tags,
    "addTags": addTags,
    "removeTags": removeTags,
  };
}

class UOrganizationReadParams {
  UOrganizationReadParams({this.pageSize, this.pageNumber, this.title, this.ids, this.tags});

  final int? pageSize;
  final int? pageNumber;
  final String? title;
  final List<String>? ids;
  final List<int>? tags;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "title": title,
    "ids": ids ?? <String>[],
    "tags": tags,
  };
}

class UOrganizationMemberParams {
  UOrganizationMemberParams({required this.organizationId, required this.userId, this.permissions = const <int>[], this.password});

  final String organizationId;
  final String userId;
  final List<int> permissions;
  final String? password;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "organizationId": organizationId,
    "userId": userId,
    "permissions": permissions,
    "password": password,
  };
}
