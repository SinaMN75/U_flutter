// The nullable locals below exist to show the null-safe extensions (isNullOrBlank, orIfBlank, orEmpty) on a null receiver.
// ignore_for_file: unnecessary_nullable_for_final_variable_declarations

import "package:u/utilities.dart";

import "../../demo/demo.dart";

/// Every extension method: String, TextEditingController, numbers, Duration, DateTime, lists, maps, BuildContext, Widget.
class ExtensionsPage extends StatefulWidget {
  const ExtensionsPage({super.key});

  @override
  State<ExtensionsPage> createState() => _ExtensionsPageState();
}

class _ExtensionsPageState extends State<ExtensionsPage> {
  final TextEditingController _c = TextEditingController(text: "۱۲,۵۰۰ تومان");
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  bool _disabled = true;
  bool _loading = true;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static const String? _null = null;
  static final List<Map<String, Object>> _people = <Map<String, Object>>[
    <String, Object>{"name": "Sina", "city": "Tehran", "age": 30},
    <String, Object>{"name": "Sara", "city": "Shiraz", "age": 25},
    <String, Object>{"name": "Ali", "city": "Tehran", "age": 41},
  ];

  @override
  Widget build(BuildContext context) => DemoPage(
    title: "Extensions",
    intro: "All results below run on open. `import \"package:u/utilities.dart\"` brings every extension.",
    children: <Widget>[
      DemoGroup("String: numbers & money", <Widget>[
        Fn('"۱۲۳".toLatinNumber() / "123".toPersianNumber()', () => <String>["۱۲۳".toLatinNumber(), "123".toPersianNumber()], auto: true),
        Fn('"a1-b2".numberString() / number() / extractLatinNumber()', () => <Object>["a1-b2".numberString(), "Order #42".number(), "۱۲-۳".extractLatinNumber()], auto: true),
        Fn('"1500000".separateNumbers3By3() / separateCharacters(4, " ")', () => <String>["1500000".separateNumbers3By3(), "6037991234567890".separateCharacters(4, " ")], auto: true),
        Fn('"1500000".rial() / toman()', () => <String>["1500000".rial(), "1500000".toman()], auto: true),
        Fn('"42".toInt() / "3.5".toDouble() / toIntOrNull / toDoubleOrNull', () => <Object?>["42".toInt(), "3.5".toDouble(), "x".toIntOrNull(), "۲.۵".toDoubleOrNull()], auto: true),
        Fn('"3.5".isNumeric() / "TRUE".isTrue() / "false".isFalse()', () => <bool>["3.5".isNumeric(), "TRUE".isTrue(), "false".isFalse()], auto: true),
        Fn('"5".append0() / "hello".subStringIfExist(0, 3)', () => <String>["5".append0(), "hello".subStringIfExist(0, 3)], auto: true),
      ]),
      DemoGroup("String: text", <Widget>[
        Fn('"hello big world".capitalize() / toTitleCase() / toSlug()', () => <String>["hello big world".capitalize(), "hello big world".toTitleCase(), "Hello World!".toSlug()], auto: true),
        Fn('"Hello world".maxLength(max: 8) / reversed / countOf("l")', () => <Object>["Hello world".maxLength(max: 8), "abc".reversed, "Hello world".countOf("l")], auto: true),
        Fn('"09121234567".mask(start: 4, end: 3) / removeCharAt(1)', () => <String>["09121234567".mask(start: 4, end: 3), "abc".removeCharAt(1)], auto: true),
        Fn('"علي".normalizePersian() / isPersian / hasPersian / isBlank', () => <Object>["علي".normalizePersian(), "سلام".isPersian, "hi سلام".hasPersian, "  ".isBlank], auto: true),
        Fn('"#FF5722".toColor()', () => "#FF5722".toColor(), auto: true),
        Fn(
          "isValidEmail / isValidUrl / isValidPhone / isAlphanumeric / isStrongPassword",
          () => <bool>["a@b.com".isValidEmail, "x.com".isValidUrl, "+989121234567".isValidPhone, "abc123".isAlphanumeric, "Abcdef1!".isStrongPassword],
          auto: true,
        ),
        Fn('"Monday".persianDayDay() / "دوشنبه".englishDay()', () => <String>["Monday".persianDayDay(), "دوشنبه".englishDay()], auto: true),
        Fn('"07".persianMonth() / "07".englishMonth()', () => <String>["07".persianMonth(), "07".englishMonth()], auto: true),
      ]),
      DemoGroup("String: files, dates, encodings", <Widget>[
        Fn('url.fileName / fileNameWithoutExtension / fileExtension', () => <String>["https://x.com/a/b.pdf?x=1".fileName, "a/b.tar.gz".fileNameWithoutExtension, "a/b.pdf".fileExtension], auto: true),
        Fn(
          '"2024-03-20T14:05:09".getYear() getMonth() getDay()',
          () => <int>["2024-03-20".getYear(), "2024-03-20".getMonth(), "2024-03-20".getDay(), "14:05".getHour(), "14:05".getMinute()],
          auto: true,
        ),
        Fn(
          '"2024-03-20".toDateTime() / toJalaliCompactDateString / toJalaliDateString',
          () => <Object?>["2024-03-20".toDateTime(), "2024-03-20".toJalaliCompactDateString(), "2024-03-20".toJalaliDateString()],
          auto: true,
        ),
        Fn(
          '"2024-03-20T14:05:09".formatJalaliDateTime() / toTimeAgo(persian: true)',
          () => <String>["2024-03-20T14:05:09".formatJalaliDateTime(), DateTime.now().subtract(3.hours).toIso8601String().toTimeAgo(persian: true)],
          auto: true,
        ),
        Fn('"hi".toBase64() / fromBase64 / toBase58 / fromBase58', () => <String>["hi".toBase64(), "aGk=".fromBase64(), "hi".toBase58(), "hi".toBase58().fromBase58()], auto: true),
        Fn('"aGk=".toBytesFromBase64() / toBytesFromBase64Url()', () => <Object>["aGk=".toBytesFromBase64(), "aGk=".toBytesFromBase64Url()], auto: true),
        Fn("bytes.toBase64() / toBase64Url() / toBase64WithoutPadding() / toHex()", () {
          final Uint8List b = Uint8List.fromList(<int>[104, 105, 255]);
          return <String>[b.toBase64(), b.toBase64Url(), b.toBase64WithoutPadding(), b.toHex()];
        }, auto: true),
      ]),
      DemoGroup("String? (null-safe)", <Widget>[
        Fn(
          "null.isNullOrEmpty() / isNotNullOrEmpty() / isNullOrBlank() / orIfBlank('Guest')",
          () => <Object>[_null.isNullOrEmpty(), _null.isNotNullOrEmpty(), _null.isNullOrBlank(), _null.orIfBlank("Guest")],
          auto: true,
        ),
        Fn(
          "null.toStringOrEmptyIfNull() / nullIfEmpty() / numberString() / number()",
          () => <Object?>[_null.toStringOrEmptyIfNull(), _null.nullIfEmpty(), _null.numberString(), _null.number()],
          auto: true,
        ),
        Fn("null.isNumeric() / getPrice()", () => <Object>[_null.isNumeric(), ("1500000" as String?).getPrice()], auto: true),
        Fn("String?.separateNumbers3By3() / rial() / toman() / rialToTomanMoneyPersian()", () {
          const String? v = "150000";
          return <String>[v.separateNumbers3By3(), v.rial(), v.toman(), v.rialToTomanMoneyPersian()];
        }, auto: true),
        Fn("String?.toJalaliDate() / toJalaliDateTime() / toJalaliDateString() / formatJalaliDateTime()", () {
          const String? v = "2024-03-20T14:05:00";
          return <String>[v.toJalaliDate(), v.toJalaliDateTime(), v.toJalaliDateString(), v.formatJalaliDateTime()];
        }, auto: true),
      ]),
      DemoGroup("TextEditingController", <Widget>[
        Demo("controller", child: UTextField(controller: _c)),
        Fn("numString() / numInt() / numDouble() / trimmedLatin()", () => <Object>[_c.numString(), _c.numInt(), _c.numDouble(), _c.trimmedLatin()]),
        Fn("valueOrNull() / isNullOrEmpty() / isNotNullOrEmpty()", () => <Object?>[_c.valueOrNull(), _c.isNullOrEmpty(), _c.isNotNullOrEmpty()]),
        Fn('appendCharacter("5") / dropLastCharacter() / setText("12500")', () {
          _c.appendCharacter("5");
          _c.dropLastCharacter();
          _c.setText("12500");
          return _c.text;
        }),
      ]),
      DemoGroup("Numbers & durations", <Widget>[
        Fn("1536.toBKMG() / 1234567.8.withCommas", () => <String>[1536.toBKMG(), 1234567.8.withCommas], auto: true),
        Fn("300.ms / 2.seconds / 5.minutes / 2.hours / 7.days", () => <Duration>[300.ms, 2.seconds, 5.minutes, 2.hours, 7.days], auto: true),
        Fn("30.between(18, 60) / 25.percentOf(200) / 0.256.toPercent()", () => <Object>[30.between(18, 60), 25.percentOf(200), 0.256.toPercent()], auto: true),
        Fn("1250.toPersianWords()", () => 1250.toPersianWords(), auto: true),
        Fn(
          "1234.567.separate3By3(maxPrecision: 2) / toStringAsSmartRound() / toSafeInt(maxValue: 100)",
          () => <Object>[1234.567.separate3By3(maxPrecision: 2), 2.50.toStringAsSmartRound(), 150.7.toSafeInt(maxValue: 100)],
          auto: true,
        ),
        Fn(
          "1500000.toman() / rial() / separate3By3() / rialToToman() / toKMB()",
          () => <String>[1500000.toman(), 1500000.rial(), 1500000.separate3By3(), 1500000.rialToToman(), 2300000.toKMB()],
          auto: true,
        ),
        Fn("10.subtractClamping(15) / 3725.secondsToTimeLeft() / 5.twoDigits", () => <Object>[10.subtractClamping(15), 3725.secondsToTimeLeft(), 5.twoDigits], auto: true),
        Fn("1.getMonthName(true) / 1.jalaliMonthName / 1.gregorianMonthName", () => <String>[1.getMonthName(true), 1.jalaliMonthName, 1.gregorianMonthName], auto: true),
        Fn("1700000000000.toDateTime()", () => 1700000000000.toDateTime(), auto: true),
        Fn("int?: rial() / toman() / rialToToman() / toStringOrEmptyIfNull()", () {
          const int? v = 150000;
          return <String>[v.rial(), v.toman(), v.rialToToman(), v.toStringOrEmptyIfNull()];
        }, auto: true),
        Fn("double?: rial() / toman() / rialToTomanMoneyPersian() / toStringOrEmptyIfNull()", () {
          const double? v = 150000.7;
          return <String>[v.rial(), v.toman(), v.rialToTomanMoneyPersian(), v.toStringOrEmptyIfNull()];
        }, auto: true),
        Fn("95.seconds.toClock() / 3725.seconds.toHuman(persian: true)", () => <String>[95.seconds.toClock(), 3725.seconds.toHuman(persian: true), 3725.seconds.toHuman()], auto: true),
        Fn("await 1.seconds.delay()", () async {
          await 1.seconds.delay();
          return "waited";
        }),
      ]),
      DemoGroup("DateTime", <Widget>[
        Fn('now.formatDate("yyyy-MM-dd HH:mm")', () => DateTime.now().formatDate("yyyy-MM-dd HH:mm"), auto: true),
        Fn(
          "now.toJalaliDate() / toJalaliDateTime() / toJalaliDateTimeSeconds()",
          () => <String>[DateTime.now().toJalaliDate(), DateTime.now().toJalaliDateTime(), DateTime.now().toJalaliDateTimeSeconds()],
          auto: true,
        ),
        Fn('now.toJalali() / toJalaliFormat("wN dd mN yyyy")', () => <Object>[DateTime.now().toJalali(), DateTime.now().toJalaliFormat("wN dd mN yyyy")], auto: true),
        Fn("(now - 3h).toTimeAgo() / toTimeAgo(persian: true)", () => <String>[DateTime.now().subtract(3.hours).toTimeAgo(), DateTime.now().subtract(3.hours).toTimeAgo(persian: true)], auto: true),
        Fn(
          "isToday / isYesterday / isTomorrow / isPast / isFuture",
          () => <bool>[DateTime.now().isToday, DateTime.now().subtract(1.days).isYesterday, DateTime.now().add(1.days).isTomorrow, DateTime(2000).isPast, DateTime(2100).isFuture],
          auto: true,
        ),
        Fn(
          "isSameDay / startOfDay / endOfDay / startOfMonth",
          () => <Object>[DateTime.now().isSameDay(DateTime.now().startOfDay), DateTime.now().startOfDay, DateTime.now().endOfDay, DateTime.now().startOfMonth],
          auto: true,
        ),
        Fn(
          "DateTime(2024, 1, 31).addMonths(1) / daysUntil / age",
          () => <Object>[DateTime(2024, 1, 31).addMonths(1), DateTime.now().daysUntil(DateTime(DateTime.now().year + 1)), DateTime(1995, 6, 1).age],
          auto: true,
        ),
        Fn("utcNow() / utcNowIso()", () => <Object>[DateTime.now().utcNow(), DateTime.now().utcNowIso()], auto: true),
      ]),
      DemoGroup("Lists", <Widget>[
        Fn("groupBy((p) => p['city'])", () => _people.groupBy((Map<String, Object> p) => p["city"]).map((Object? k, List<Map<String, Object>> v) => MapEntry<Object?, int>(k, v.length)), auto: true),
        Fn(
          "sortedBy(age, descending) / distinctBy(city)",
          () => <Object>[
            _people.sortedBy<num>((Map<String, Object> p) => p["age"]! as num, descending: true).map((Map<String, Object> p) => p["name"]),
            _people.distinctBy((Map<String, Object> p) => p["city"]).length,
          ],
          auto: true,
        ),
        Fn(
          "sumBy / averageBy / maxBy / minBy",
          () => <Object?>[
            _people.sumBy((Map<String, Object> p) => p["age"]! as num),
            _people.averageBy((Map<String, Object> p) => p["age"]! as num),
            _people.maxBy((Map<String, Object> p) => p["age"]! as num)?["name"],
            _people.minBy((Map<String, Object> p) => p["age"]! as num)?["name"],
          ],
          auto: true,
        ),
        Fn(
          "[1..5].chunked(2) / separatedBy(0)",
          () => <Object>[
            <int>[1, 2, 3, 4, 5].chunked(2),
            <int>[1, 2, 3].separatedBy(0),
          ],
          auto: true,
        ),
        Fn("mapIndexed / forEachIndexed", () {
          final List<String> out = <String>[];
          <String>["a", "b"].forEachIndexed((int i, String e) => out.add("$i$e"));
          return <Object>[
            <String>["a", "b"].mapIndexed((int i, String e) => "$i:$e").toList(),
            out,
          ];
        }, auto: true),
        Fn(
          "firstWhereOrNull / getFirstIfExist / firstOrDefault / takeIfPossible",
          () => <Object?>[
            <int>[1, 2].firstWhereOrNull((int e) => e > 5),
            <int>[].getFirstIfExist(),
            <int>[].firstOrDefault(defaultValue: 9),
            <int>[1, 2].takeIfPossible(5).toList(),
          ],
          auto: true,
        ),
        Fn(
          "containsAll / containsAny",
          () => <bool>[
            <int>[1, 2, 3].containsAll(<int>[1, 3]),
            <int>[1, 2].containsAny(<int>[9, 2]),
          ],
          auto: true,
        ),
        Fn(
          "insertFirstReturn / addAndReturn / addAllAndReturn / insertAndReturn / alternative",
          () => <Object>[
            <int>[2].insertFirstReturn(1),
            <int>[1].addAndReturn(2),
            <int>[1].addAllAndReturn(<int>[2, 3]),
            <int>[1, 3].insertAndReturn(1, 2),
            <String>["old", "x"].alternative("old", "new"),
          ],
          auto: true,
        ),
        Fn("List? isNullOrEmpty() / isNotNullOrEmpty() / orEmpty() / containsAll", () {
          const List<int>? v = null;
          return <Object>[v.isNullOrEmpty(), v.isNotNullOrEmpty(), v.orEmpty(), v.containsAll(<int>[])];
        }, auto: true),
        Demo("[a, b, c].withSpacing(8)", child: Row(children: <Widget>[const Icon(Icons.star), const Icon(Icons.star), const Icon(Icons.star)].withSpacing(8))),
        Demo(
          "tiles.withDividers()",
          child: Column(
            children: <Widget>[const ListTile(title: Text("One")), const ListTile(title: Text("Two"))].withDividers(),
          ),
        ),
      ]),
      DemoGroup("Maps", <Widget>[
        Fn(
          '{"a": 1}.add("b", 2) / getOr<int>("x", 0)',
          () => <Object>[
            <String, int>{"a": 1}.add("b", 2),
            <String, dynamic>{"a": 1}.getOr<int>("x", 0),
          ],
          auto: true,
        ),
        Fn("removeNulls() / pick([..]) / omit([..])", () {
          final Map<String, Object?> m = <String, Object?>{"id": 1, "name": "Sina", "password": "x", "bio": null};
          return <Object>[
            m.removeNulls(),
            m.pick(<String>["id", "name"]),
            m.omit(<String>["password"]),
          ];
        }, auto: true),
        Fn(
          "deepMerge",
          () =>
              <String, dynamic>{
                "a": 1,
                "b": <String, dynamic>{"x": 1, "y": 2},
              }.deepMerge(<String, dynamic>{
                "b": <String, dynamic>{"y": 3},
              }),
          auto: true,
        ),
      ]),
      DemoGroup("BuildContext", <Widget>[
        Builder(
          builder: (BuildContext c) =>
              Fn("context.width / height / screenSize / devicePixelRatio / textScale", () => <Object>[c.width.round(), c.height.round(), c.screenSize, c.devicePixelRatio, c.textScale], auto: true),
        ),
        Builder(
          builder: (BuildContext c) => Fn(
            "isMobileSize / isTabletSize / isDesktopSize / responsive(1, tablet: 2, desktop: 4)",
            () => <Object>[c.isMobileSize, c.isTabletSize, c.isDesktopSize, c.responsive(1, tablet: 2, desktop: 4)],
            auto: true,
          ),
        ),
        Builder(builder: (BuildContext c) => Fn("orientation / isLandscape / isPortrait", () => <Object>[c.orientation, c.isLandscape, c.isPortrait], auto: true)),
        Builder(
          builder: (BuildContext c) =>
              Fn("padding / viewPadding / viewInsets / keyboardHeight / isKeyboardOpen", () => <Object>[c.padding, c.viewPadding, c.viewInsets, c.keyboardHeight, c.isKeyboardOpen], auto: true),
        ),
        Builder(
          builder: (BuildContext c) =>
              Fn("theme / colorScheme.primary / textTheme / isDarkMode", () => <Object?>[c.theme.brightness, c.colorScheme.primary, c.textTheme.bodyMedium?.fontSize, c.isDarkMode], auto: true),
        ),
        Builder(
          builder: (BuildContext c) => Fn("locale / isRtl / hideKeyboard()", () {
            c.hideKeyboard();
            return <Object>[c.locale, c.isRtl];
          }, auto: true),
        ),
      ]),
      DemoGroup("Widget helpers", <Widget>[
        Demo(".pAll / pSymmetric / pOnly / pLTRB", child: const Text("padded").pAll(4).pSymmetric(horizontal: 4).pOnly(left: 4).pLTRB(2, 2, 2, 2).container(borderColor: Colors.grey, radius: 8)),
        Demo(
          ".container(…) / .chip(…) / .card()",
          child: Row(
            spacing: 8,
            children: <Widget>[
              const Text("box").container(backgroundColor: Colors.amber.shade100, radius: 8, padding: const EdgeInsets.all(8)),
              const Text("New").chip(backgroundColor: Colors.green.shade100),
              const Text("card").pAll(8).card(),
            ],
          ),
        ),
        Demo(
          ".onTap / .onPress / .onTapInk / .onLongPress / .onDoubleTap",
          child: Row(
            spacing: 12,
            children: <Widget>[
              const Text("tap").onTap(() => UToast.toast(message: "onTap")),
              const Text("press").onPress(() => UToast.toast(message: "onPress")),
              const Text("ink").pAll(6).onTapInk(() => UToast.toast(message: "onTapInk")),
              const Text("long").onLongPress(() => UToast.toast(message: "onLongPress")),
              const Text("double").onDoubleTap(() => UToast.toast(message: "onDoubleTap")),
            ],
          ),
        ),
        Demo(
          ".showMenus([…])",
          child: const Text("tap for a menu").showMenus(<PopupMenuEntry<int>>[const PopupMenuItem<int>(value: 1, child: Text("Edit")), const PopupMenuItem<int>(value: 2, child: Text("Delete"))]),
        ),
        Demo(
          ".expanded() / .flexible() / .fit()",
          child: Row(
            children: <Widget>[
              const Text("expanded").container(backgroundColor: Colors.blue.shade100).expanded(),
              const Text("flexible text that can shrink").flexible(),
              const Text("fits").fit().sized(width: 30),
            ],
          ),
        ),
        Demo(".ltr() / .rtl()", child: Column(children: <Widget>[const Text("0912 123 4567 ←ltr").ltr(), const Text("متن راست به چپ").rtl()])),
        Demo(
          ".scale / .rotate / .translate / .opacity",
          child: Row(
            spacing: 24,
            children: <Widget>[
              const Icon(Icons.star).scale(1.5),
              const Icon(Icons.arrow_upward).rotate(pi / 2),
              const Icon(Icons.star).translate(const Offset(0, -4)),
              const Icon(Icons.star).opacity(0.3),
            ],
          ),
        ),
        Demo(
          ".position(top:, right:) inside a Stack",
          child: SizedBox(
            height: 40,
            child: Stack(
              children: <Widget>[
                const Icon(Icons.mail, size: 32),
                const Icon(Icons.circle, size: 10, color: Colors.red).position(top: 0, left: 26),
              ],
            ),
          ),
        ),
        Demo(
          ".alignAt* / .alignXY / .alignAtLERP / .center()",
          child: SizedBox(
            height: 80,
            child: Stack(
              children: <Widget>[
                const Text("TL").alignAtTopLeft(),
                const Text("TC").alignAtTopCenter(),
                const Text("TR").alignAtTopRight(),
                const Text("CL").alignAtCenterLeft(),
                const Text("C").alignAtCenter(),
                const Text("CR").alignAtCenterRight(),
                const Text("BL").alignAtBottomLeft(),
                const Text("BC").alignAtBottomCenter(),
                const Text("BR").alignAtBottomRight(),
                const Text("xy").alignXY(-0.5, 0.5),
                const Text("lerp").alignAtLERP(Alignment.topLeft, Alignment.bottomRight, 0.25),
                const Text("·").center(),
              ],
            ),
          ),
        ),
        Demo(
          ".clipRadius(12) / .clipCircle() / .tooltip() / .hero()",
          child: Row(
            spacing: 12,
            children: <Widget>[
              Container(width: 40, height: 40, color: Colors.teal).clipRadius(12),
              Container(width: 40, height: 40, color: Colors.orange).clipCircle(),
              const Icon(Icons.info).tooltip("Tooltip!"),
              const Icon(Icons.flight).hero("demo-hero"),
            ],
          ),
        ),
        Demo(
          ".visible(bool) / .disabled(bool)",
          child: Row(
            spacing: 12,
            children: <Widget>[
              UButton(title: "toggle", onTap: () => setState(() => _disabled = !_disabled)),
              const Text("hidden when disabled").visible(!_disabled),
              UButton(title: "can't tap", onTap: () {}).disabled(_disabled),
            ],
          ),
        ),
        Demo(
          ".skeleton(loading)",
          child: Row(
            spacing: 12,
            children: <Widget>[
              UButton(title: "toggle", onTap: () => setState(() => _loading = !_loading)),
              const Text("Sina Mohammadzadeh").skeleton(_loading),
            ],
          ),
        ),
        Demo(".fadeSlideIn()", child: const Text("I slide in once").fadeSlideIn()),
        Demo(
          ".scrollable() / .safeArea() / .sliver() / .form(key)",
          child: SizedBox(
            height: 60,
            child: CustomScrollView(
              slivers: <Widget>[
                Row(children: List<Widget>.generate(20, (int i) => Text(" $i "))).scrollable(scrollDirection: Axis.horizontal).safeArea().sliver(),
                UTextField(hintText: "in a form").form(_form).sliver(),
              ],
            ),
          ),
        ),
        Demo("UState (base State with scheme/width/isFa)", child: const _UStateDemo()),
      ]),
    ],
  );
}

class _UStateDemo extends StatefulWidget {
  const _UStateDemo();

  @override
  State<_UStateDemo> createState() => _UStateDemoState();
}

class _UStateDemoState extends UState<_UStateDemo> {
  @override
  Widget build(BuildContext context) =>
      Text("width ${width.round()} · height ${height.round()} · isFa $isFa · ${screenSize.aspectRatio.toStringAsFixed(2)} · ${theme.brightness.name}", style: TextStyle(color: scheme.primary));
}
