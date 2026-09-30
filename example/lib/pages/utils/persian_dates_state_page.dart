import "package:u/utilities.dart";

import "../../demo/demo.dart";

/// UPersianTools, UPhoneNumberUtils, UJalali / UGregorian and URx state.
class PersianDatesStatePage extends StatefulWidget {
  const PersianDatesStatePage({super.key});

  @override
  State<PersianDatesStatePage> createState() => _PersianDatesStatePageState();
}

class _PersianDatesStatePageState extends State<PersianDatesStatePage> {
  final URxInt _count = 0.obs;
  final URxBool _on = false.obs;
  final URxnBool _maybe = URxnBool();
  final URxState _state = URxState();
  final URxList<String> _items = <String>[].obs;
  final URxMap<String, int> _cart = <String, int>{}.obs;
  final URxSet<int> _selected = <int>{}.obs;

  UJalali get _j => UJalali(1403, 6, 31, 14, 5);

  @override
  Widget build(BuildContext context) => DemoPage(
    title: "Persian, dates, state",
    children: <Widget>[
      DemoGroup("Iranian helpers", <Widget>[
        Fn('UPersianTools.isPersian("سلام") / hasPersian("hi سلام")', () => <bool>[UPersianTools.isPersian("سلام"), UPersianTools.hasPersian("hi سلام")], auto: true),
        Fn(
          'UPersianTools.trim(" x ") / replaceMapValue',
          () => <String>[
            UPersianTools.trim(" x "),
            UPersianTools.replaceMapValue("a-b", <String, String>{"-": "+"}),
          ],
        ),
        Fn('UPersianTools.validateNationalCode("0499370899")', () => UPersianTools.validateNationalCode("0499370899"), auto: true),
        Fn('UPersianTools.validateTaxMemoryId("A1B2C3")', () => UPersianTools.validateTaxMemoryId("A1B2C3")),
        Fn(
          'UPersianTools.validateCardNumber / getBankNameFromCard / formatCardNumber',
          () => <Object?>[UPersianTools.validateCardNumber("6037991234567890"), UPersianTools.getBankNameFromCard("6037991234567890"), UPersianTools.formatCardNumber("6037991234567890")],
        ),
        Fn(
          'UPersianTools.isShebaValid / getBankFromSheba',
          () => <Object?>[UPersianTools.isShebaValid("IR062960000000100324200001"), UPersianTools.getBankFromSheba("IR062960000000100324200001")?.persianName],
        ),
        Fn("UPersianTools.numberToWords(1250)", () => UPersianTools.numberToWords(1250), auto: true),
        Fn('UPersianTools.wordsToNumberString("سیصد و پنج")', () => UPersianTools.wordsToNumberString("سیصد و پنج")),
        Fn('UPersianTools.convertDigits("123", en, fa)', () => UPersianTools.convertDigits("123", UDigitLocale.en, UDigitLocale.fa)),
        Fn('UPersianTools.getPhoneDetails("09121234567") / formatPhoneNumber', () => <Object?>[UPersianTools.getPhoneDetails("09121234567")?.name, UPersianTools.formatPhoneNumber("09121234567")]),
      ]),
      DemoGroup("Phone numbers", <Widget>[
        Fn('UPhoneNumberUtils.toE164("0912 123 4567", countryCode: "IR")', () => UPhoneNumberUtils.toE164("0912 123 4567", countryCode: "IR"), auto: true),
        Fn('normalizePhone / sanitize', () => <String>[UPhoneNumberUtils.normalizePhone("۰۹۱۲ ۱۲۳ ۴۵۶۷", countryCode: "IR"), UPhoneNumberUtils.sanitize("+98 (912) 123")]),
        Fn(
          'dialCodeOf("IR") / countryOfDialCode("+44") / countryOf("+49…")',
          () => <Object?>[UPhoneNumberUtils.dialCodeOf("IR"), UPhoneNumberUtils.countryOfDialCode("+44")?.nameEn, UPhoneNumberUtils.countryOf("+4915112345678")?.nameEn],
        ),
        Fn('resolveCountry("DE")', () => UPhoneNumberUtils.resolveCountry("DE").nameEn),
        Fn(
          'nationalNumber / stripTrunkPrefix',
          () => <String>[UPhoneNumberUtils.nationalNumber("+989121234567", countryCode: "IR"), UPhoneNumberUtils.stripTrunkPrefix("09121234567", countryCode: "IR")],
        ),
        Fn('isValid("09121234567", countryCode: "IR")', () => UPhoneNumberUtils.isValid("09121234567", countryCode: "IR")),
        Fn("maxNationalDigits / maxInputDigits / placeholder", () => <Object>[UPhoneNumberUtils.maxNationalDigits("IR"), UPhoneNumberUtils.maxInputDigits("IR"), UPhoneNumberUtils.placeholder("IR")]),
        Fn(
          "formatMask / formatNational / formatE164",
          () => <String>[UPhoneNumberUtils.formatMask(10, "IR"), UPhoneNumberUtils.formatNational("9121234567", countryCode: "IR"), UPhoneNumberUtils.formatE164("+989121234567")],
        ),
        Fn('inputDigits("09121234567999", countryCode: "IR")', () => UPhoneNumberUtils.inputDigits("09121234567999", countryCode: "IR")),
      ]),
      DemoGroup("Jalali dates", <Widget>[
        Fn("UJalali.now().formatFullDate(persianDigits: true)", () => UJalali.now().formatFullDate(persianDigits: true), auto: true),
        Fn("formatCompactDate / formatDateTime / formatTime", () => <String>[_j.formatCompactDate(), _j.formatDateTime(), _j.formatTime()]),
        Fn("formatShortDate / formatMonthYear / formatAfghanDate", () => <String>[_j.formatShortDate(), _j.formatMonthYear(), _j.formatAfghanDate()]),
        Fn('formatCustom("wN dd mN yyyy - HH:MM")', () => _j.formatCustom("wN dd mN yyyy - HH:MM")),
        Fn(
          "add(months: 1) / addDays / addHours / addMinutes / addSeconds",
          () => <String>[_j.add(months: 1).formatCompactDate(), _j.addDays(-7).formatCompactDate(), _j.addHours(12).formatDateTime(), _j.addMinutes(-90).formatTime(), _j.addSeconds(75).formatTime()],
        ),
        Fn("toGregorian() / UGregorian(2024, 3, 20).toJalali()", () => <String>["${_j.toGregorian()}", "${UGregorian(2024, 3, 20).toJalali()}"]),
        Fn(
          "firstDayOfMonth / lastDayOfMonth / nextDay / previousDay",
          () => <String>[_j.firstDayOfMonth().formatCompactDate(), _j.lastDayOfMonth().formatCompactDate(), _j.nextDay().formatCompactDate(), _j.previousDay().formatCompactDate()],
        ),
        Fn("startOfWeek / endOfWeek / daysUntil(now)", () => <Object>[_j.startOfWeek().formatCompactDate(), _j.endOfWeek().formatCompactDate(), _j.daysUntil(UJalali.now())]),
        Fn("quarter / isWeekend / weeksInYear / isToday / isThisMonth", () => <Object>[_j.quarter, _j.isWeekend(), _j.weeksInYear(), _j.isToday(), _j.isThisMonth()]),
        Fn("isBefore / isAfter / isAtSameMomentAs / isSameDayAs", () => <bool>[_j.isBefore(UJalali.now()), _j.isAfter(UJalali.now()), _j.isAtSameMomentAs(_j), _j.isSameDayAs(_j.addHours(1))]),
        Fn("millisecondsSinceEpoch", () => _j.millisecondsSinceEpoch),
      ]),
      DemoGroup("Reactive state (URx + UObx)", <Widget>[
        Demo(
          "final URxInt count = 0.obs;  UObx(() => Text(count.value))",
          child: UObx(() => UButton(title: "Tapped ${_count.value} times", onTap: () => _count.value++)),
        ),
        Fn("count(10) / count.refresh()", () {
          _count(10);
          _count.refresh();
          return _count.value;
        }),
        Demo(
          "URxBool.toggle() / isTrue / isFalse",
          child: UObx(() => SwitchListTile(value: _on.isTrue, title: Text("isFalse = ${_on.isFalse}"), onChanged: (_) => _on.toggle())),
        ),
        Fn("URxnBool.toggle() / isTrue / isFalse", () {
          _maybe.toggle();
          return <bool?>[_maybe.value, _maybe.isTrue, _maybe.isFalse];
        }),
        Demo(
          "URxState: loading() → loaded() / error() / emptying() / paging() / initial()",
          child: UObx(
            () => URow(
              spacing: 8,
              children: <Widget>[
                Text(_state.value.name),
                if (_state.isLoading()) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                Text("${_state.isInitial()} ${_state.isLoaded()} ${_state.isError()} ${_state.isEmpty()} ${_state.isPaging()}"),
              ],
            ),
          ),
        ),
        Fn("run state machine", () async {
          _state.loading();
          await Future<void>.delayed(1.seconds);
          _state.paging();
          await Future<void>.delayed(500.ms);
          _state.emptying();
          await Future<void>.delayed(500.ms);
          _state.error();
          await Future<void>.delayed(500.ms);
          _state.initial();
          return _state.loaded();
        }),
        Demo("URxList.add / assign / assignAll", child: UObx(() => Text(_items.join(", ")))),
        Fn("items.add · assignAll · assign", () {
          _items.add("x");
          _items.assignAll(<String>[..._items, "y"]);
          if (_items.length > 4) _items.assign("reset");
          return _items.toList();
        }),
        Fn("URxMap.assignAll / URxSet.assignAll", () {
          _cart.assignAll(<String, int>{"apple": 2});
          _selected.assignAll(<int>{1, 2});
          return <Object>[_cart.value, _selected.value];
        }),
        Fn(
          ".obs on every type",
          () => <Object>[
            "x".obs.runtimeType,
            1.5.obs.runtimeType,
            (3 as num).obs.runtimeType,
            DateTime.now().obs.runtimeType,
            (null as int?).obs.runtimeType,
            (null as double?).obs.runtimeType,
            (null as num?).obs.runtimeType,
            (null as String?).obs.runtimeType,
            (null as bool?).obs.runtimeType,
            (null as List<int>?).obs.runtimeType,
            (null as Map<String, int>?).obs.runtimeType,
            (null as Set<int>?).obs.runtimeType,
          ],
        ),
      ]),
    ],
  );
}
