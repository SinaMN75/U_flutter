import "package:u/utilities.dart";

import "../../demo/demo.dart";

/// Text fields, pickers, selectors, keyboards, forms, signature, card, files.
class InputsComponentsPage extends StatefulWidget {
  const InputsComponentsPage({super.key});

  @override
  State<InputsComponentsPage> createState() => _InputsComponentsPageState();
}

class _InputsComponentsPageState extends State<InputsComponentsPage> {
  final TextEditingController _pin = TextEditingController();
  final UCreditCardModel _card = UCreditCardModel();
  final UFilePickerController _files = UFilePickerController();
  final USignatureController _signature = USignatureController();
  final List<int> _tags = <int>[TagHotel.wifi.number];
  final List<String> _multi = <String>[];
  List<String> _faq = <String>["Opening hours?", "Parking?"];
  String _segment = "day";
  int _dropdown = 1;
  String? _city;
  double _rating = 3.5;
  String _plate = "";
  String _selectedChip = "Tea";

  static const List<String> _cities = <String>["Tehran", "Shiraz", "Isfahan", "Tabriz", "Mashhad", "Yazd"];

  Future<List<String>> _search(String q) async {
    await Future<void>.delayed(300.ms);
    return _cities.where((String c) => c.toLowerCase().contains(q.toLowerCase())).toList();
  }

  @override
  void dispose() {
    _pin.dispose();
    _signature.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DemoPage(
    title: "Inputs & forms",
    children: <Widget>[
      DemoGroup("Text fields", <Widget>[
        const Demo('UTextField(labelText: …, hasClearButton: true)', child: UTextField(labelText: "Name", hasClearButton: true)),
        const Demo("UTextField(obscureText: true) — eye button", child: UTextField(labelText: "Password", obscureText: true)),
        Demo(
          "UTextField(formatters: [UCurrencyInputFormatter()])",
          child: UTextField(labelText: "Amount", keyboardType: TextInputType.number, formatters: <TextInputFormatter>[UCurrencyInputFormatter()]),
        ),
        Demo(
          "UTextField(formatters: [UNumberInputFormatter(maxDigits: 10)])",
          child: UTextField(labelText: "National code", keyboardType: TextInputType.number, formatters: <TextInputFormatter>[UNumberInputFormatter(maxDigits: 10)]),
        ),
        Demo(
          'UTextField(formatters: [UPhoneInputFormatter(countryCode: "IR")])',
          child: UTextField(
            labelText: "Mobile",
            keyboardType: TextInputType.phone,
            formatters: <TextInputFormatter>[UPhoneInputFormatter(countryCode: "IR")],
          ),
        ),
        Demo(
          "UTextFieldPhoneNumber(onChanged: …)",
          child: UTextFieldPhoneNumber(onChanged: (UPhoneNumberData p) => UToast.toast(message: p.phoneNumber)),
        ),
        Demo("UCountryFlag(country: UCountries.iran())", child: UCountryFlag(country: UCountries.iran())),
        Demo(
          "UTextFieldDatePicker(jalali: true, onChange: …)",
          child: UTextFieldDatePicker(
            labelText: "Birth date",
            jalali: true,
            onChange: (DateTime d, UJalali j) => UToast.toast(message: j.formatCompactDate()),
          ),
        ),
        Demo(
          "UTextFieldDatePicker(time: true, onChange: …)",
          child: UTextFieldDatePicker(labelText: "Meeting", time: true, onChange: (DateTime d, UJalali j) {}),
        ),
        Demo(
          "UDropDownField<int>(items: …, onChanged: …)",
          child: UDropDownField<int>(
            labelText: "Size",
            initialValue: _dropdown,
            items: const <DropdownMenuItem<int>>[
              DropdownMenuItem<int>(value: 1, child: Text("Small")),
              DropdownMenuItem<int>(value: 2, child: Text("Large")),
            ],
            onChanged: (int? v) => setState(() => _dropdown = v ?? 1),
          ),
        ),
        Demo(
          "UTextFieldAutoComplete<String>(items: …)",
          child: UTextFieldAutoComplete<String>(
            items: _cities,
            labelBuilder: (String c) => c,
            selectedItem: _city ?? _cities.first,
            onChanged: (String c) => setState(() => _city = c),
            hintText: "City",
          ),
        ),
        Demo(
          "UTextFieldAutoCompleteAsync<String>(fetchData: …)",
          child: UTextFieldAutoCompleteAsync<String>(fetchData: _search, labelBuilder: (String c) => c, selectedItem: null, onChanged: (String? c) {}, hintText: "Search cities"),
        ),
        Demo(
          "UTextFieldAutoCompleteAsyncMulti<String>(selected: …)",
          child: UTextFieldAutoCompleteAsyncMulti<String>(selected: _multi, fetchData: _search, labelBuilder: (String c) => c, hintText: "Add cities", onChanged: (List<String> s) {}),
        ),
        Demo(
          "UOtpField(length: 6, onCompleted: …)",
          child: UOtpField(length: 6, onCompleted: (String code) => UToast.success(message: "code $code")),
        ),
        Demo(
          "UPlateField(onPlateChange: …)",
          child: UColumn(
            spacing: 4,
            children: <Widget>[
              UPlateField(onPlateChange: (String p) => setState(() => _plate = p)),
              Text(_plate),
            ],
          ),
        ),
      ]),
      DemoGroup("Keyboards & selectors", <Widget>[
        Demo(
          "UNumericKeyboard(onKeyTap: controller.appendCharacter, …)",
          child: UColumn(
            spacing: 8,
            children: <Widget>[
              UTextField(controller: _pin, readOnly: true, textAlign: TextAlign.center),
              UNumericKeyboard(onKeyTap: (String v) => _pin.appendCharacter(v, maxLength: 6), onBackspace: _pin.dropLastCharacter, onBackspaceLongPress: _pin.clear),
            ],
          ),
        ),
        Demo(
          'USegmentedControl<String>(items: …)',
          child: USegmentedControl<String>(
            items: const <String, String>{"day": "Day", "week": "Week", "month": "Month"},
            selectedValue: _segment,
            onValueChanged: (String? v) => setState(() => _segment = v ?? "day"),
          ),
        ),
        Demo(
          "UChipChoice<String>(options: …, selected: …)",
          child: UChipChoice<String>(options: const <String>["Tea", "Coffee", "Juice"], selected: _selectedChip, onChanged: (int i, bool on, String item) => setState(() => _selectedChip = item)),
        ),
        Demo(
          "UTagChips<TagHotel>(options: TagHotel.values.group(500), tags: …)",
          child: UTagChips<TagHotel>(title: "Amenities", options: TagHotel.values.group(500).take(6).toList(), tags: _tags),
        ),
        Demo(
          "URatingBar.builder(onRatingUpdate: …) / URatingBarIndicator(rating: …)",
          child: UColumn(
            spacing: 8,
            children: <Widget>[
              URatingBar.builder(
                initialRating: _rating,
                allowHalfRating: true,
                itemBuilder: (BuildContext c, int i) => const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (double r) => setState(() => _rating = r),
              ),
              URatingBarIndicator(
                rating: _rating,
                itemSize: 20,
                itemBuilder: (BuildContext c, int i) => const Icon(Icons.star, color: Colors.amber),
              ),
            ],
          ),
        ),
        Demo(
          "UCountryProvincePicker(onCityChanged: …)",
          child: UCountryProvincePicker(onCityChanged: (UCity? c) => UToast.toast(message: c?.nameEn ?? "-")),
        ),
        Demo(
          "UCategorySelector(…) (reads U.categories)",
          child: UCategorySelector(onCategorySelected: (UCategoryResponse? c) {}, onSubCategorySelected: (UCategoryResponse? c) {}),
        ),
      ]),
      DemoGroup("Jalali date pickers", <Widget>[
        Fn("await UJalaliDatePicker.show(type: material)", () async => (await UJalaliDatePicker.show(type: UJalaliDatePickerType.material))?.formatCompactDate()),
        Fn("await UJalaliDatePicker.show() (spinner)", () async => (await UJalaliDatePicker.show())?.formatCompactDate()),
        Fn(
          "UJalaliDatePicker.format / headline / monthName / weekDayName / number",
          () => <String>[
            UJalaliDatePicker.format(UJalali.now(), persian: true),
            UJalaliDatePicker.headline(UJalali.now(), persian: true),
            UJalaliDatePicker.monthName(1, persian: true),
            UJalaliDatePicker.weekDayName(1, persian: false),
            UJalaliDatePicker.number(1403, persian: true),
          ],
          auto: true,
        ),
        Fn('UJalaliDatePicker.parse("1403/01/15") / clamp', () => <Object?>[UJalaliDatePicker.parse("1403/01/15"), UJalaliDatePicker.clamp(UJalali(1500), UJalali(1400), UJalali(1410))], auto: true),
        Demo(
          "UJalaliDatePickerSpinner(…)",
          child: UJalaliDatePickerSpinner(initialDate: UJalali.now(), firstDate: UJalali(1350), lastDate: UJalali(1450)),
        ),
        Demo(
          "UJalaliDatePickerMaterial(…)",
          child: SizedBox(
            height: 420,
            child: UJalaliDatePickerMaterial(initialDate: UJalali.now(), firstDate: UJalali(1350), lastDate: UJalali(1450)),
          ),
        ),
        Demo(
          "UJalaliDatePickerDialog(initialDate: …, onDateSelected: …)",
          child: UButton(
            title: "Open",
            onTap: () => UNavigator.dialog<void>(
              UJalaliDatePickerDialog(
                initialDate: UJalali.now(),
                onDateSelected: (DateTime d, UJalali j) => UToast.toast(message: j.formatCompactDate()),
              ),
            ),
          ),
        ),
      ]),
      DemoGroup("Forms & lists", <Widget>[
        Fn(
          "UFormDialog.show(title: …, children: …)",
          () => UFormDialog.show(
            title: "Edit profile",
            children: (BuildContext c, StateSetter set) => <Widget>[UTextField(labelText: "Name", validator: UValidators.required()), const UTextField(labelText: "Bio", lines: 3)],
            onSubmit: () async => true,
          ),
        ),
        Fn(
          "UFilterDialog.show(title: …, onApply: …, onClear: …)",
          () => UFilterDialog.show(
            title: "Filters",
            onApply: () => UToast.info(message: "applied"),
            onClear: () => UToast.info(message: "cleared"),
            children: (StateSetter set) => <Widget>[const UTextField(labelText: "From price"), const UTextField(labelText: "To price")],
          ),
        ),
        const Demo(
          "UFieldPair(first, second)",
          child: UFieldPair(UTextField(labelText: "First name"), UTextField(labelText: "Last name")),
        ),
        Demo(
          "UFormDialog(…) inline",
          child: SizedBox(
            height: 220,
            child: UFormDialog(
              title: "Inline form",
              children: (BuildContext c, StateSetter s) => <Widget>[const UTextField(labelText: "Email")],
            ),
          ),
        ),
        Demo(
          "UFilterDialog(…) inline",
          child: SizedBox(
            height: 220,
            child: UFilterDialog(
              title: "Inline filter",
              onApply: () {},
              onClear: () {},
              children: (StateSetter s) => <Widget>[const UTextField(labelText: "Keyword")],
            ),
          ),
        ),
        Demo(
          "UListEditor.strings(items: …, onChanged: …)",
          child: UListEditor.strings(items: _faq, title: "FAQ", addLabel: "Add question", onChanged: (List<String> v) => setState(() => _faq = v)),
        ),
        Demo(
          "UListEditor<T>(fields: [UListEditorField(…)], toItem: …)",
          child: UListEditor<MapEntry<String, String>>(
            items: const <MapEntry<String, String>>[MapEntry<String, String>("Wi-Fi", "Free")],
            fields: <UListEditorField<MapEntry<String, String>>>[
              UListEditorField<MapEntry<String, String>>("Name", (MapEntry<String, String> e) => e.key),
              UListEditorField<MapEntry<String, String>>("Value", (MapEntry<String, String> e) => e.value),
            ],
            toItem: (List<String> t) => t.first.isEmpty ? null : MapEntry<String, String>(t.first, t.last),
            onChanged: (List<MapEntry<String, String>> v) {},
            addLabel: "Add row",
          ),
        ),
        Demo(
          "UListEditor.nearby(…) / UListEditor.faqs(…)",
          child: UColumn(
            spacing: 8,
            children: <Widget>[
              UListEditor.nearby(items: const <UPlaceNearby>[], onChanged: (List<UPlaceNearby> v) {}),
              UListEditor.faqs(items: const <UPlaceFaq>[], onChanged: (List<UPlaceFaq> v) {}),
            ],
          ),
        ),
      ]),
      DemoGroup("Signature, card, files", <Widget>[
        Demo(
          "USignaturePad(onSave: …)",
          child: SizedBox(
            height: 280,
            child: USignaturePad(onSave: (UFileData f) => UToast.success(message: "Signature ${f.sizeInBytes?.toBKMG()}")),
          ),
        ),
        Demo(
          "USignaturePadRaw(controller: …) + USignatureController",
          child: UColumn(
            spacing: 8,
            children: <Widget>[
              SizedBox(height: 140, child: USignaturePadRaw(controller: _signature)),
              UWrap(
                spacing: 8,
                children: <Widget>[
                  UButton(title: "undo", onTap: _signature.undo),
                  UButton(title: "redo", onTap: _signature.redo),
                  UButton(title: "clear", onTap: _signature.clear),
                  UButton(title: "red pen", onTap: () => _signature.penColor = Colors.red),
                  UButton(
                    title: "toPngBytes",
                    onTap: () async =>
                        UToast.info(message: "${(await _signature.toPngBytes())?.length} bytes · ${_signature.strokes.length} strokes · undo ${_signature.canUndo} · redo ${_signature.canRedo}"),
                  ),
                  UButton(
                    title: "draw a line from code",
                    onTap: () {
                      _signature.beginStroke(const Offset(10, 10));
                      _signature.extendStroke(const Offset(120, 60), 1);
                      _signature.commitStroke();
                      UToast.toast(message: "active stroke: ${_signature.activeStroke}, pen ${_signature.penColor}");
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Demo(
          "UCreditCardWidget(…) + UCreditCardForm(model: …)",
          child: UColumn(
            spacing: 8,
            children: <Widget>[
              UCreditCardWidget(cardNumber: _card.cardNumber, expiryDate: _card.expiryDate, cardHolderName: _card.cardHolderName, cvvCode: _card.cvvCode, showBackView: _card.isCvvFocused),
              UCreditCardForm(model: _card, onChanged: (UCreditCardModel m) => setState(() {})),
            ],
          ),
        ),
        Fn('UCardBrandDetector.detect("6037…") / label / gradientColors / isAmex', () {
          final UCardBrand b = UCardBrandDetector.detect("6037991234567890");
          return <Object>[b, UCardBrandDetector.label(b), UCardBrandDetector.gradientColors(b).length, UCardBrandDetector.isAmex(b)];
        }, auto: true),
        Demo("UFilePicker(controller: …, selectCover: true)", child: UFilePicker(controller: _files, selectCover: true)),
        Demo("UFilePicker.gallery(controller)", child: UFilePicker.gallery(_files)),
        Fn(
          "controller: files / all / existingFiles / removedFiles / cover / hasChanges / coverChanged",
          () => <Object?>[_files.files.length, _files.all.length, _files.existingFiles.length, _files.removedFiles.length, _files.cover?.name, _files.hasChanges, _files.coverChanged],
        ),
        Fn("controller.add / isNew / isCover / setCover / replace / remove", () {
          final UFileData f = UFileData(bytes: Uint8List.fromList(<int>[1]), extension: "txt");
          _files.add(<UFileData>[f]);
          _files.setCover(f);
          final List<bool> flags = <bool>[_files.isNew(f), _files.isCover(f)];
          _files.remove(f);
          _files.replace(<UFileData>[]);
          return flags;
        }),
        Demo(
          "UBase64ImagePicker(label: …, initial: …, onChanged: …)",
          child: UBase64ImagePicker(
            label: "Logo",
            initial: null,
            onChanged: (String? b64) => UToast.toast(message: "${b64?.length ?? 0} chars"),
          ),
        ),
      ]),
    ],
  );
}
