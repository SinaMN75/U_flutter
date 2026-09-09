import "package:u/utilities.dart";

class UMediaParseException implements Exception {
  const UMediaParseException(this.message, {this.offset});

  final String message;
  final int? offset;

  @override
  String toString() => offset == null ? "UMediaParseException: $message" : "UMediaParseException: $message (at $offset)";
}

class UMediaError implements Exception {
  const UMediaError({required this.code, required this.message, this.detail, this.platformCode, this.sourceId});

  final UMediaErrorCode code;
  final String message;
  final String? detail;
  final String? platformCode;
  final String? sourceId;

  bool get isRecoverable => code == UMediaErrorCode.network || code == UMediaErrorCode.timeout;

  factory UMediaError.fromMap(Map<Object?, Object?> map) => UMediaError(
    code: UMediaErrorCode.values.firstWhere(
      (UMediaErrorCode e) => e.name == map["code"],
      orElse: () => UMediaErrorCode.unknown,
    ),
    message: (map["message"] as String?) ?? "",
    detail: map["detail"] as String?,
    platformCode: map["platformCode"] as String?,
    sourceId: map["sourceId"] as String?,
  );

  @override
  String toString() => "UMediaError(${code.name}): $message${detail == null ? "" : " — $detail"}";
}
