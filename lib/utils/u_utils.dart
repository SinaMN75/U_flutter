import "package:u/utilities.dart";
import "package:uuid/uuid.dart";

abstract class UUUID {
  static const Uuid _uuid = Uuid();

  static String uuidV1() => _uuid.v1();

  static String uuidV4() => _uuid.v4();

  static String uuidV5(String namespace, String name) => _uuid.v5(namespace, name);

  static String uuidV6() => _uuid.v6();

  static String uuidV7() => _uuid.v7();

  static String uuidV8() => _uuid.v8();
}

abstract class UValidators {
  static void validateForm({required GlobalKey<FormState> key, required VoidCallback action}) {
    if (key.currentState!.validate()) action();
  }

  static FormFieldValidator<T> combineValidators<T>(List<FormFieldValidator<T>> validators) => (T? value) {
    for (final FormFieldValidator<T> validator in validators) {
      final String? result = validator(value);
      if (result != null) return result;
    }
    return null;
  };

  static FormFieldValidator<T> required<T>({String? message}) => (T? value) {
    if (value == null) return message;
    if (value is String && value.isEmpty) return message ?? U.s.required;
    if (value is List && value.isEmpty) return message ?? U.s.required;
    if (value is Map && value.isEmpty) return message ?? U.s.required;
    return null;
  };

  static FormFieldValidator<String> minLength({
    required int minLength,
    required String message,
  }) => (String? value) {
    if (value == null || value.length < minLength) {
      return message;
    }
    return null;
  };

  static FormFieldValidator<String> maxLength({
    required int maxLength,
    required String message,
  }) => (String? value) {
    if (value != null && value.length > maxLength) {
      return message;
    }
    return null;
  };

  static FormFieldValidator<String> exactLength({
    required int length,
    required String message,
  }) => (String? value) {
    if (value == null || value.length != length) {
      return message;
    }
    return null;
  };

  static FormFieldValidator<String> email({
    String? requiredMessage,
    String? invalidMessage,
    bool isRequired = true,
  }) => (String? value) {
    if (isRequired && (value == null || value.isEmpty)) {
      return requiredMessage ?? U.s.required;
    }
    if (value != null && value.isNotEmpty && !value.isValidEmail) {
      return invalidMessage ?? U.s.thisFieldIsInvalid;
    }
    return null;
  };

  static FormFieldValidator<String> phone({
    String? requiredMessage,
    String? invalidMessage,
    bool isRequired = true,
  }) => (String? value) {
    if (isRequired && (value == null || value.isEmpty)) {
      return requiredMessage ?? U.s.required;
    }
    if (value != null && value.isNotEmpty && !value.isValidPhone) {
      return invalidMessage ?? U.s.thisFieldIsInvalid;
    }
    return null;
  };

  static FormFieldValidator<String> number({
    String? requiredMessage,
    String? invalidMessage,
    int? minLength,
    int? maxLength,
    bool isRequired = true,
  }) => (String? value) {
    if (isRequired && (value == null || value.isEmpty)) return requiredMessage ?? U.s.required;
    if (value != null && value.isNotEmpty && !value.extractLatinNumber().isNumeric()) return invalidMessage ?? U.s.thisFieldIsInvalid;
    if (minLength != null && value != null && value.isNotEmpty && value.length < minLength) return invalidMessage ?? U.s.thisFieldIsInvalid;
    if (maxLength != null && value != null && value.isNotEmpty && value.length > maxLength) return invalidMessage ?? U.s.thisFieldIsInvalid;
    return null;
  };

  static FormFieldValidator<String> iranianNationalCode({
    String? requiredMessage,
    String? invalidMessage,
    bool isRequired = true,
  }) => (String? value) {
    if (isRequired && (value == null || value.isEmpty)) return requiredMessage ?? U.s.required;
    if (value != null && value.isNotEmpty && !PersianTools.validateNationalCode(value.toLatinNumber())) return invalidMessage ?? U.s.thisFieldIsInvalid;
    return null;
  };

  static FormFieldValidator<String> numberRange({
    required double min,
    required double max,
    required String rangeMessage,
    required String invalidNumberMessage,
    bool isRequired = true,
  }) => (String? value) {
    if (isRequired && (value == null || value.isEmpty)) {
      return invalidNumberMessage;
    }
    if (value != null && value.isNotEmpty) {
      final double? numValue = double.tryParse(value.extractLatinNumber());
      if (numValue == null) return invalidNumberMessage;
      if (numValue < min || numValue > max) return rangeMessage;
    }
    return null;
  };

  static FormFieldValidator<String> url({
    String? requiredMessage,
    String? invalidMessage,
    bool isRequired = true,
  }) => (String? value) {
    if (isRequired && (value == null || value.isEmpty)) {
      return requiredMessage ?? U.s.required;
    }
    if (value != null && value.isNotEmpty && !value.isValidUrl) {
      return invalidMessage ?? U.s.thisFieldIsInvalid;
    }
    return null;
  };

  static FormFieldValidator<String> password({
    required String weakMessage,
    String? requiredMessage,
    bool isRequired = true,
  }) => (String? value) {
    if (isRequired && (value == null || value.isEmpty)) {
      return requiredMessage ?? U.s.required;
    }
    if (value != null && value.isNotEmpty && !value.isStrongPassword) {
      return weakMessage;
    }
    return null;
  };

  static FormFieldValidator<String> alphanumeric({
    String? requiredMessage,
    String? invalidMessage,
    bool isRequired = true,
  }) => (String? value) {
    if (isRequired && (value == null || value.isEmpty)) {
      return requiredMessage ?? U.s.required;
    }
    if (value != null && value.isNotEmpty && !value.isAlphanumeric) {
      return invalidMessage ?? U.s.thisFieldIsInvalid;
    }
    return null;
  };

  static FormFieldValidator<String> pattern({
    required RegExp pattern,
    required String message,
    bool isRequired = true,
  }) => (String? value) {
    if (isRequired && (value == null || value.isEmpty)) {
      return message;
    }
    if (value != null && value.isNotEmpty && !pattern.hasMatch(value)) {
      return message;
    }
    return null;
  };

  static FormFieldValidator<String> match({
    required String otherValue,
    required String mismatchMessage,
  }) => (String? value) {
    if (value != otherValue) {
      return mismatchMessage;
    }
    return null;
  };

  static FormFieldValidator<String> complexPassword() => combineValidators(<FormFieldValidator<String>>[
    required(message: "Password is required"),
    minLength(minLength: 8, message: "Password must be at least 8 characters"),
    password(
      requiredMessage: "Password is required",
      weakMessage: "Password must contain uppercase, lowercase, number, and special character",
    ),
  ]);
}

Future<void> delay(int milliseconds, VoidCallback action) async => Future<dynamic>.delayed(
  Duration(milliseconds: milliseconds),
  () async => action(),
);

class UDebouncer {
  final Duration delay;
  Timer? _timer;

  UDebouncer({required this.delay});

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => cancel();
}
