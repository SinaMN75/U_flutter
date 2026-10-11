import "package:u/utilities.dart";

/// Makes UUIDs (RFC 9562) with no package; v4 random and v7 time-sorted are the usual picks. `UUUID.uuidV4()`
abstract class UUUID {
  /// Namespace for [uuidV5] names that are domain names.
  static const String namespaceDns = "6ba7b810-9dad-11d1-80b4-00c04fd430c8";

  /// Namespace for [uuidV5] names that are URLs.
  static const String namespaceUrl = "6ba7b811-9dad-11d1-80b4-00c04fd430c8";

  static final Uint8List _node = UEncryption.randomBytes(6)..[0] |= 0x01;
  static final int _clockSeq = UEncryption.randomBytes(2).buffer.asByteData().getUint16(0) & 0x3fff;
  static BigInt _lastV1 = BigInt.zero;
  static int _lastV7 = 0;
  static int _v7Counter = 0;

  /// Time + random node id (v1); sortable only within one device. `UUUID.uuidV1()`
  static String uuidV1() => _format(_timeBased(reordered: false));

  /// Fully random (v4), the classic choice for ids. `UUUID.uuidV4()` → "3f0c…-4…"
  static String uuidV4() => _format(_version(UEncryption.randomBytes(16), 4));

  /// Same [name] + [namespace] always gives the same id (v5, SHA-1). `UUUID.uuidV5(UUUID.namespaceUrl, "https://x.com")`
  static String uuidV5(String namespace, String name) {
    final List<int> input = <int>[..._parse(namespace), ...utf8.encode(name)];
    return _format(_version(UEncryption.sha1Bytes(input).sublist(0, 16), 5));
  }

  /// Like v1 but the time comes first so ids sort by creation (v6). `UUUID.uuidV6()`
  static String uuidV6() => _format(_timeBased(reordered: true));

  /// Millisecond time + random, sorts by creation; best for database keys (v7). `UUUID.uuidV7()`
  static String uuidV7() {
    int ms = DateTime.now().millisecondsSinceEpoch;
    if (ms <= _lastV7) {
      ms = _lastV7;
      _v7Counter++;
    } else {
      _v7Counter = UEncryption.randomBytes(2).buffer.asByteData().getUint16(0) & 0x7ff;
    }
    _lastV7 = ms;
    final Uint8List b = UEncryption.randomBytes(16);
    for (int i = 0; i < 6; i++) {
      b[i] = (ms ~/ pow(2, 8 * (5 - i)).toInt()) & 0xff;
    }
    b[6] = (_v7Counter >> 8) & 0x0f;
    b[7] = _v7Counter & 0xff;
    return _format(_version(b, 7));
  }

  /// Custom layout (v8): your 16 [bytes] with only version/variant bits set; random when omitted. `UUUID.uuidV8()`
  static String uuidV8([List<int>? bytes]) => _format(_version(Uint8List.fromList(bytes ?? UEncryption.randomBytes(16)), 8));

  /// True when [value] looks like a UUID ("8-4-4-4-12" hex). `UUUID.isValid(id)`
  static bool isValid(String value) => RegExp(r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$").hasMatch(value);

  /// Version number of a UUID (1-8), or null if it is not one. `UUUID.versionOf(UUUID.uuidV7())` → 7
  static int? versionOf(String value) => isValid(value) ? int.parse(value[14], radix: 16) : null;

  /// Creation time stored in a v7 UUID. `UUUID.timeOf(id)`
  static DateTime? timeOf(String value) {
    if (versionOf(value) != 7) return null;
    return DateTime.fromMillisecondsSinceEpoch(int.parse(value.replaceAll("-", "").substring(0, 12), radix: 16));
  }

  static Uint8List _timeBased({required bool reordered}) {
    // 100 ns ticks since 1582-10-15; BigInt because the value does not fit a web (JS) number.
    BigInt ticks = BigInt.from(DateTime.now().microsecondsSinceEpoch) * BigInt.from(10) + BigInt.parse("01B21DD213814000", radix: 16);
    if (ticks <= _lastV1) ticks = _lastV1 + BigInt.one;
    _lastV1 = ticks;
    int bits(int shift, int width) => ((ticks >> shift) & ((BigInt.one << width) - BigInt.one)).toInt();
    final Uint8List b = Uint8List(16);
    if (reordered) {
      final int high = bits(28, 32);
      final int mid = bits(12, 16);
      final int low = bits(0, 12);
      b.setAll(0, <int>[high >> 24 & 0xff, high >> 16 & 0xff, high >> 8 & 0xff, high & 0xff, mid >> 8, mid & 0xff, low >> 8, low & 0xff]);
    } else {
      final int low = bits(0, 32);
      final int mid = bits(32, 16);
      final int high = bits(48, 12);
      b.setAll(0, <int>[low >> 24 & 0xff, low >> 16 & 0xff, low >> 8 & 0xff, low & 0xff, mid >> 8, mid & 0xff, high >> 8, high & 0xff]);
    }
    b[8] = _clockSeq >> 8;
    b[9] = _clockSeq & 0xff;
    b.setAll(10, _node);
    return _version(b, reordered ? 6 : 1);
  }

  static Uint8List _version(Uint8List b, int version) => b
    ..[6] = (b[6] & 0x0f) | (version << 4)
    ..[8] = (b[8] & 0x3f) | 0x80;

  static List<int> _parse(String uuid) => UEncryption.hexToBytes(uuid.replaceAll("-", ""));

  static String _format(List<int> b) {
    final String h = UEncryption.hexEncode(b);
    return "${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}";
  }
}

/// Ready-made form validators; each returns a FormFieldValidator for `validator:`. `UTextField(validator: UValidators.email())`
abstract class UValidators {
  /// Runs [action] only when every field in the form is valid. `UValidators.validateForm(key: formKey, action: save)`
  static void validateForm({required GlobalKey<FormState> key, required VoidCallback action}) {
    if (key.currentState!.validate()) action();
  }

  /// Runs validators in order and shows the first error. `UValidators.combineValidators([UValidators.required(), UValidators.email()])`
  static FormFieldValidator<T> combineValidators<T>(List<FormFieldValidator<T>> validators) => (T? value) {
    for (final FormFieldValidator<T> validator in validators) {
      final String? result = validator(value);
      if (result != null) return result;
    }
    return null;
  };

  /// Fails on null, "", empty list or empty map. `UValidators.required()`
  static FormFieldValidator<T> required<T>({String? message}) => (T? value) {
    if (value == null) return message ?? U.s.required;
    if (value is String && value.trim().isEmpty) return message ?? U.s.required;
    if (value is List && value.isEmpty) return message ?? U.s.required;
    if (value is Map && value.isEmpty) return message ?? U.s.required;
    return null;
  };

  /// Fails when shorter than [minLength]. `UValidators.minLength(minLength: 8, message: "Too short")`
  static FormFieldValidator<String> minLength({required int minLength, required String message}) => (String? value) {
    if (value == null || value.length < minLength) return message;
    return null;
  };

  /// Fails when longer than [maxLength]. `UValidators.maxLength(maxLength: 20, message: "Too long")`
  static FormFieldValidator<String> maxLength({required int maxLength, required String message}) => (String? value) {
    if (value != null && value.length > maxLength) return message;
    return null;
  };

  /// Fails unless exactly [length] characters. `UValidators.exactLength(length: 10, message: "Must be 10 digits")`
  static FormFieldValidator<String> exactLength({required int length, required String message}) => (String? value) {
    if (value == null || value.length != length) return message;
    return null;
  };

  /// Checks an email address. `UValidators.email()`
  static FormFieldValidator<String> email({String? requiredMessage, String? invalidMessage, bool isRequired = true}) => (String? value) {
    if (isRequired && (value == null || value.isEmpty)) return requiredMessage ?? U.s.required;
    if (value != null && value.isNotEmpty && !value.isValidEmail) return invalidMessage ?? U.s.thisFieldIsInvalid;
    return null;
  };

  /// Checks a phone number (8-15 digits, optional +). `UValidators.phone()`
  static FormFieldValidator<String> phone({String? requiredMessage, String? invalidMessage, bool isRequired = true}) => (String? value) {
    if (isRequired && (value == null || value.isEmpty)) return requiredMessage ?? U.s.required;
    if (value != null && value.isNotEmpty && !value.toLatinNumber().isValidPhone) return invalidMessage ?? U.s.thisFieldIsInvalid;
    return null;
  };

  /// Checks a phone number (8-15 digits, optional +). `UValidators.phone()`
  static FormFieldValidator<String> iranianPhone({String? requiredMessage, String? invalidMessage, bool isRequired = true}) => (String? value) {
    if (isRequired && (value == null || value.isEmpty)) return requiredMessage ?? U.s.required;
    if (value != null && value.isNotEmpty && !RegExp(r"^09\d{9}$").hasMatch(value.toLatinNumber().replaceAll(" ", ""))) return invalidMessage ?? U.s.thisFieldIsInvalid;
    return null;
  };

  /// Only digits (Persian/Arabic digits accepted), optional length limits. `UValidators.number(minLength: 4)`
  static FormFieldValidator<String> number({String? requiredMessage, String? invalidMessage, int? minLength, int? maxLength, bool isRequired = true}) => (String? value) {
    if (isRequired && (value == null || value.isEmpty)) return requiredMessage ?? U.s.required;
    if (value != null && value.isNotEmpty && !value.extractLatinNumber().isNumeric()) return invalidMessage ?? U.s.thisFieldIsInvalid;
    if (minLength != null && value != null && value.isNotEmpty && value.length < minLength) return invalidMessage ?? U.s.thisFieldIsInvalid;
    if (maxLength != null && value != null && value.isNotEmpty && value.length > maxLength) return invalidMessage ?? U.s.thisFieldIsInvalid;
    return null;
  };

  /// Checks an Iranian national code (کد ملی) checksum. `UValidators.iranianNationalCode()`
  static FormFieldValidator<String> iranianNationalCode({String? requiredMessage, String? invalidMessage, bool isRequired = true}) => (String? value) {
    if (isRequired && (value == null || value.isEmpty)) return requiredMessage ?? U.s.required;
    if (value != null && value.isNotEmpty && !UPersianTools.validateNationalCode(value.toLatinNumber())) return invalidMessage ?? U.s.thisFieldIsInvalid;
    return null;
  };

  /// Checks an Iranian tax memory id (شناسه یکتای حافظه مالیاتی). `UValidators.iranianTaxPayerCode()`
  static FormFieldValidator<String> iranianTaxPayerCode({String? requiredMessage, String? invalidMessage, bool isRequired = true}) => (String? value) {
    if (isRequired && (value == null || value.isEmpty)) return requiredMessage ?? U.s.required;
    if (value != null && value.isNotEmpty && !UPersianTools.validateTaxMemoryId(value.toLatinNumber())) return invalidMessage ?? U.s.thisFieldIsInvalid;
    return null;
  };

  /// Checks an Iranian card number (Luhn). `UValidators.cardNumber()`
  static FormFieldValidator<String> cardNumber({String? requiredMessage, String? invalidMessage, bool isRequired = true}) => (String? value) {
    if (isRequired && (value == null || value.isEmpty)) return requiredMessage ?? U.s.required;
    if (value != null && value.isNotEmpty && !UPersianTools.validateCardNumber(value.extractLatinNumber())) return invalidMessage ?? U.s.thisFieldIsInvalid;
    return null;
  };

  /// Checks an Iranian card expiry "YY/MM" (Jalali): month 01–12 and not already passed. `UValidators.iranianCardExpiry()`
  static FormFieldValidator<String> iranianCardExpiry({String? requiredMessage, String? invalidMessage, String? expiredMessage, bool isRequired = true}) => (String? value) {
    final String digits = (value ?? "").extractLatinNumber();
    if (digits.isEmpty) return isRequired ? requiredMessage ?? U.s.required : null;
    if (digits.length != 4) return invalidMessage ?? U.s.thisFieldIsInvalid;
    final int year = 1400 + int.parse(digits.substring(0, 2));
    final int month = int.parse(digits.substring(2));
    if (month < 1 || month > 12) return invalidMessage ?? U.s.thisFieldIsInvalid;
    final UJalali now = UJalali.now();
    if (year < now.year || (year == now.year && month < now.month)) return expiredMessage ?? U.s.expired;
    return null;
  };

  /// Checks an IBAN / Sheba number ("IR" + 24 digits). `UValidators.iban()`
  static FormFieldValidator<String> iban({String? requiredMessage, String? invalidMessage, bool isRequired = true}) => (String? value) {
    if (isRequired && (value == null || value.isEmpty)) return requiredMessage ?? U.s.required;
    final String sheba = (value ?? "").toLatinNumber().replaceAll(" ", "").toUpperCase();
    if (sheba.isNotEmpty && !UPersianTools.isShebaValid(sheba.startsWith("IR") ? sheba : "IR$sheba")) return invalidMessage ?? U.s.thisFieldIsInvalid;
    return null;
  };

  /// Number between [min] and [max] (inclusive). `UValidators.numberRange(min: 1, max: 100, rangeMessage: "1-100", invalidNumberMessage: "Not a number")`
  static FormFieldValidator<String> numberRange({required double min, required double max, required String rangeMessage, required String invalidNumberMessage, bool isRequired = true}) =>
      (String? value) {
        if (isRequired && (value == null || value.isEmpty)) return invalidNumberMessage;
        if (value != null && value.isNotEmpty) {
          final double? numValue = double.tryParse(value.toLatinNumber().replaceAll(RegExp(r"[^0-9.\-]"), ""));
          if (numValue == null) return invalidNumberMessage;
          if (numValue < min || numValue > max) return rangeMessage;
        }
        return null;
      };

  /// Checks a web address (http/https optional). `UValidators.url()`
  static FormFieldValidator<String> url({String? requiredMessage, String? invalidMessage, bool isRequired = true}) => (String? value) {
    if (isRequired && (value == null || value.isEmpty)) return requiredMessage ?? U.s.required;
    if (value != null && value.isNotEmpty && !value.isValidUrl) return invalidMessage ?? U.s.thisFieldIsInvalid;
    return null;
  };

  /// Needs 8+ chars with upper, lower, digit and symbol. `UValidators.password(weakMessage: "Too weak")`
  static FormFieldValidator<String> password({required String weakMessage, String? requiredMessage, bool isRequired = true}) => (String? value) {
    if (isRequired && (value == null || value.isEmpty)) return requiredMessage ?? U.s.required;
    if (value != null && value.isNotEmpty && !value.isStrongPassword) return weakMessage;
    return null;
  };

  /// Only English letters and digits. `UValidators.alphanumeric()`
  static FormFieldValidator<String> alphanumeric({String? requiredMessage, String? invalidMessage, bool isRequired = true}) => (String? value) {
    if (isRequired && (value == null || value.isEmpty)) return requiredMessage ?? U.s.required;
    if (value != null && value.isNotEmpty && !value.isAlphanumeric) return invalidMessage ?? U.s.thisFieldIsInvalid;
    return null;
  };

  /// Must match your own regular expression. `UValidators.pattern(pattern: RegExp(r"^09\d{9}$"), message: "Invalid")`
  static FormFieldValidator<String> pattern({required RegExp pattern, required String message, bool isRequired = true}) => (String? value) {
    if (isRequired && (value == null || value.isEmpty)) return message;
    if (value != null && value.isNotEmpty && !pattern.hasMatch(value)) return message;
    return null;
  };

  /// Must equal [otherValue], e.g. "repeat password". `UValidators.match(otherValue: passwordController.text, mismatchMessage: "Not the same")`
  static FormFieldValidator<String> match({required String otherValue, required String mismatchMessage}) => (String? value) {
    if (value != otherValue) return mismatchMessage;
    return null;
  };

  /// Must equal the current text of [controller] (reads it on every check). `UValidators.matchController(controller: passwordController, mismatchMessage: "Not the same")`
  static FormFieldValidator<String> matchController({required TextEditingController controller, required String mismatchMessage}) => (String? value) {
    if (value != controller.text) return mismatchMessage;
    return null;
  };

  /// Required + 8 chars + strong password, with English messages. `UValidators.complexPassword()`
  static FormFieldValidator<String> complexPassword() => combineValidators(<FormFieldValidator<String>>[
    required(message: "Password is required"),
    minLength(minLength: 8, message: "Password must be at least 8 characters"),
    password(requiredMessage: "Password is required", weakMessage: "Password must contain uppercase, lowercase, number, and special character"),
  ]);
}

/// Runs [action] after [milliseconds]. `delay(500, () => print("later"))`
Future<void> delay(int milliseconds, VoidCallback action) => Future<void>.delayed(Duration(milliseconds: milliseconds), action);

/// Runs only the last call after a quiet [delay], e.g. search-as-you-type. `final UDebouncer d = UDebouncer(delay: 400.ms); d.run(search);`
class UDebouncer {
  /// Makes a debouncer that waits [delay] after the last call.
  UDebouncer({required this.delay});

  /// How long to wait after the last call.
  final Duration delay;
  Timer? _timer;

  /// True while a call is waiting to run.
  bool get isPending => _timer?.isActive ?? false;

  /// Schedules [action], cancelling the one waiting before it. `debouncer.run(() => search(text))`
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Drops the waiting call.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Same as cancel(); call it in your State.dispose().
  void dispose() => cancel();
}

/// Runs at most once per [interval], e.g. a button that must not fire twice. `final UThrottler t = UThrottler(interval: 1.seconds); t.run(pay);`
class UThrottler {
  /// Makes a throttler that allows one call per [interval]; [trailing] also runs the last skipped call at the end.
  UThrottler({required this.interval, this.trailing = false});

  /// Minimum time between two runs.
  final Duration interval;

  /// When true, the last call made during the wait also runs once the wait ends.
  final bool trailing;
  DateTime? _last;
  Timer? _timer;
  void Function()? _queued;

  /// Runs [action] now if allowed, otherwise skips it (or queues it when [trailing]). `throttler.run(save)`
  void run(void Function() action) {
    final DateTime now = DateTime.now();
    if (_last == null || now.difference(_last!) >= interval) {
      _last = now;
      action();
      return;
    }
    if (!trailing) return;
    _queued = action;
    _timer ??= Timer(interval - now.difference(_last!), () {
      _timer = null;
      final void Function()? next = _queued;
      _queued = null;
      if (next != null) run(next);
    });
  }

  /// Forgets the last run and drops any queued call.
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _queued = null;
    _last = null;
  }

  /// Same as cancel(); call it in your State.dispose().
  void dispose() => cancel();
}

/// Retries a failing async job with growing waits (1s, 2s, 4s…). `await URetry.run(() => api.load(), attempts: 3)`
abstract class URetry {
  /// Calls [action] until it succeeds or [attempts] run out, then rethrows the last error; [retryIf] can stop early.
  static Future<T> run<T>(
    Future<T> Function() action, {
    int attempts = 3,
    Duration delay = const Duration(seconds: 1),
    double factor = 2,
    Duration maxDelay = const Duration(seconds: 30),
    bool Function(Object error)? retryIf,
    void Function(Object error, int attempt)? onRetry,
  }) async {
    Duration wait = delay;
    for (int attempt = 1; ; attempt++) {
      try {
        return await action();
      } catch (error) {
        if (attempt >= attempts || (retryIf != null && !retryIf(error))) rethrow;
        onRetry?.call(error, attempt);
        await Future<void>.delayed(wait);
        final int next = (wait.inMilliseconds * factor).round();
        wait = Duration(milliseconds: min(next, maxDelay.inMilliseconds));
      }
    }
  }
}
