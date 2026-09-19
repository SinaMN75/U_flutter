import "package:flutter/cupertino.dart" show CupertinoPicker;
import "package:u/utilities.dart";

enum UJalaliDatePickerType { classic, material, spinner }

abstract class UJalaliDatePicker {
  static Future<Jalali?> show({
    UJalaliDatePickerType type = UJalaliDatePickerType.spinner,
    Jalali? initialDate,
    Jalali? firstDate,
    Jalali? lastDate,
    String? helpText,
    bool asDialog = false,
    DatePickerEntryMode initialEntryMode = DatePickerEntryMode.calendar,
  }) {
    final Jalali initial = initialDate ?? Jalali.now();
    final Jalali first = firstDate ?? Jalali(initial.year - 100);
    final Jalali last = lastDate ?? Jalali(initial.year + 50, 12, Jalali(initial.year + 50, 12).monthLength);
    final Jalali safe = clamp(initial, first, last);

    switch (type) {
      case UJalaliDatePickerType.classic:
        return UNavigator.dialog<Jalali>(
          JalaliDatePickerDialog(
            initialDate: safe,
            startYear: first.year,
            endYear: last.year,
            onDateSelected: (DateTime _, Jalali _) {},
          ),
        );
      case UJalaliDatePickerType.material:
        return UNavigator.dialog<Jalali>(
          UJalaliDatePickerMaterial(
            initialDate: safe,
            firstDate: first,
            lastDate: last,
            helpText: helpText,
            initialEntryMode: initialEntryMode,
          ),
        );
      case UJalaliDatePickerType.spinner:
        final Widget spinner = UJalaliDatePickerSpinner(
          initialDate: safe,
          firstDate: first,
          lastDate: last,
          helpText: helpText,
        );
        return asDialog
            ? UNavigator.dialog<Jalali>(
                Dialog(
                  clipBehavior: Clip.antiAlias,
                  child: UContainer(width: 340, child: spinner),
                ),
              )
            : UNavigator.bottomSheet<Jalali>(spinner);
    }
  }

  static Jalali clamp(Jalali date, Jalali first, Jalali last) {
    if (date.julianDayNumber < first.julianDayNumber) return first;
    if (date.julianDayNumber > last.julianDayNumber) return last;
    return date;
  }

  static String number(int value, {required bool persian}) => persian ? value.toString().toPersianNumber() : value.toString();

  static String monthName(int month, {required bool persian}) => persian ? JalaliFormatter.monthNames[month - 1] : JalaliFormatter.monthNamesLatin[month - 1];

  static String weekDayName(int weekDay, {required bool persian}) => persian ? JalaliFormatter.weekDayNames[weekDay - 1] : JalaliFormatter.weekDayNamesLatin[weekDay - 1];

  static String format(Jalali date, {required bool persian}) {
    final String year = date.year.toString().padLeft(4, "0");
    final String month = date.month.toString().padLeft(2, "0");
    final String day = date.day.toString().padLeft(2, "0");
    final String value = "$year/$month/$day";
    return persian ? value.toPersianNumber() : value;
  }

  static String headline(Jalali date, {required bool persian}) => persian
      ? "${JalaliFormatter.weekDayNames[date.weekDay - 1]}، ${number(date.day, persian: true)} ${JalaliFormatter.monthNames[date.month - 1]}"
      : "${JalaliFormatter.weekDayNamesLatin[date.weekDay - 1]}, ${date.day} ${JalaliFormatter.monthNamesLatin[date.month - 1]}";

  static Jalali? parse(String value) {
    final List<String> parts = value.toLatinNumber().split("/");
    if (parts.length != 3) return null;
    final int? year = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    if (year < 1 || year > 3177 || month < 1 || month > 12 || day < 1) return null;
    if (day > Jalali(year, month).monthLength) return null;
    return Jalali(year, month, day);
  }
}

class UJalaliDatePickerMaterial extends StatefulWidget {
  const UJalaliDatePickerMaterial({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    super.key,
    this.onDateSelected,
    this.helpText,
    this.initialEntryMode = DatePickerEntryMode.calendar,
    this.initialPickerMode = DatePickerMode.day,
  });

  final Jalali initialDate;
  final Jalali firstDate;
  final Jalali lastDate;
  final Function(DateTime, Jalali)? onDateSelected;
  final String? helpText;
  final DatePickerEntryMode initialEntryMode;
  final DatePickerMode initialPickerMode;

  @override
  State<UJalaliDatePickerMaterial> createState() => _UJalaliDatePickerMaterialState();
}

class _UJalaliDatePickerMaterialState extends UState<UJalaliDatePickerMaterial> {
  late Jalali _selected = widget.initialDate;
  late int _displayYear = widget.initialDate.year;
  late int _displayMonth = widget.initialDate.month;
  late DatePickerEntryMode _entryMode = widget.initialEntryMode;
  late DatePickerMode _pickerMode = widget.initialPickerMode;
  late final PageController _pageController = PageController(initialPage: _pageOf(_displayYear, _displayMonth));
  late final TextEditingController _inputController = TextEditingController(text: UJalaliDatePicker.format(widget.initialDate, persian: false));
  late final ScrollController _yearScrollController = ScrollController(initialScrollOffset: (max(0, (_displayYear - widget.firstDate.year) ~/ 3 - 2) * 56).toDouble());
  String? _inputError;

  int get _monthCount => (widget.lastDate.year - widget.firstDate.year) * 12 + (widget.lastDate.month - widget.firstDate.month) + 1;

  int get _yearCount => widget.lastDate.year - widget.firstDate.year + 1;

  int _pageOf(int year, int month) => (year - widget.firstDate.year) * 12 + (month - widget.firstDate.month);

  int _yearOfPage(int page) => widget.firstDate.year + (widget.firstDate.month - 1 + page) ~/ 12;

  int _monthOfPage(int page) => (widget.firstDate.month - 1 + page) % 12 + 1;

  bool _isOutOfRange(Jalali date) => date.julianDayNumber < widget.firstDate.julianDayNumber || date.julianDayNumber > widget.lastDate.julianDayNumber;

  @override
  void dispose() {
    _pageController.dispose();
    _inputController.dispose();
    _yearScrollController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    final int target = page.clamp(0, _monthCount - 1);
    setState(() {
      _displayYear = _yearOfPage(target);
      _displayMonth = _monthOfPage(target);
    });
    unawaited(_pageController.animateToPage(target, duration: const Duration(milliseconds: 250), curve: Curves.easeOut));
  }

  void _selectYear(int year) {
    final int month = year == widget.firstDate.year
        ? max(_displayMonth, widget.firstDate.month)
        : year == widget.lastDate.year
        ? min(_displayMonth, widget.lastDate.month)
        : _displayMonth;
    setState(() {
      _displayYear = year;
      _displayMonth = month;
      _pickerMode = DatePickerMode.day;
    });
    _jumpToPage(_pageOf(year, month));
  }

  void _jumpToPage(int page) => WidgetsBinding.instance.addPostFrameCallback((Duration _) {
    if (mounted && _pageController.hasClients) _pageController.jumpToPage(page);
  });

  void _toggleEntryMode() {
    if (_entryMode == DatePickerEntryMode.input) {
      final Jalali? parsed = UJalaliDatePicker.parse(_inputController.text);
      setState(() {
        _entryMode = DatePickerEntryMode.calendar;
        _pickerMode = DatePickerMode.day;
        if (parsed != null && !_isOutOfRange(parsed)) {
          _selected = parsed;
          _displayYear = parsed.year;
          _displayMonth = parsed.month;
        }
      });
      _jumpToPage(_pageOf(_displayYear, _displayMonth));
    } else {
      _inputController.text = UJalaliDatePicker.format(_selected, persian: false);
      setState(() {
        _entryMode = DatePickerEntryMode.input;
        _inputError = null;
      });
    }
  }

  void _onInputChanged(String value) {
    final Jalali? parsed = UJalaliDatePicker.parse(value);
    setState(() {
      if (parsed == null) {
        _inputError = value.isEmpty ? null : U.s.invalidDate;
      } else if (_isOutOfRange(parsed)) {
        _inputError = U.s.dateOutOfRange;
      } else {
        _inputError = null;
        _selected = parsed;
      }
    });
  }

  void _submit() {
    widget.onDateSelected?.call(_selected.toDateTime(), _selected);
    UNavigator.back(_selected);
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    clipBehavior: Clip.antiAlias,
    backgroundColor: scheme.surfaceContainerHigh,
    child: UContainer(
      width: 328,
      height: _entryMode == DatePickerEntryMode.input ? 260 : 512,
      child: Column(
        children: <Widget>[
          _header(),
          Divider(height: 1, color: scheme.outlineVariant),
          Expanded(child: _entryMode == DatePickerEntryMode.input ? _input() : _calendar()),
          _actions(),
        ],
      ),
    ),
  );

  Widget _header() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      UTextLabelMedium(
        widget.helpText ?? (_entryMode == DatePickerEntryMode.input ? U.s.enterDate : U.s.selectDate),
        color: scheme.onSurfaceVariant,
      ),
      const SizedBox(height: 28),
      Row(
        children: <Widget>[
          UTextHeadlineSmall(
            UJalaliDatePicker.headline(_selected, persian: isFa),
            color: scheme.onSurface,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            expanded: 1,
          ),
          IconButton(
            onPressed: _toggleEntryMode,
            tooltip: _entryMode == DatePickerEntryMode.input ? U.s.switchToCalendar : U.s.switchToTextInput,
            icon: Icon(
              _entryMode == DatePickerEntryMode.input ? Icons.calendar_today_outlined : Icons.edit_outlined,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ],
  ).pLTRB(24, 16, 8, 12);

  Widget _calendar() => Column(
    children: <Widget>[
      _subHeader(),
      if (_pickerMode == DatePickerMode.day) _weekDays(),
      Expanded(child: _pickerMode == DatePickerMode.day ? _monthPages() : _yearGrid()),
    ],
  );

  Widget _subHeader() => Row(
    children: <Widget>[
      TextButton(
        onPressed: () => setState(() => _pickerMode = _pickerMode == DatePickerMode.day ? DatePickerMode.year : DatePickerMode.day),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            UTextLabelLarge(
              "${UJalaliDatePicker.monthName(_displayMonth, persian: isFa)} ${UJalaliDatePicker.number(_displayYear, persian: isFa)}",
              color: scheme.onSurfaceVariant,
            ),
            Icon(
              _pickerMode == DatePickerMode.day ? Icons.arrow_drop_down : Icons.arrow_drop_up,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
      const Spacer(),
      if (_pickerMode == DatePickerMode.day) ...<Widget>[
        IconButton(
          onPressed: _pageOf(_displayYear, _displayMonth) > 0 ? () => _goToPage(_pageOf(_displayYear, _displayMonth) - 1) : null,
          tooltip: U.s.previousMonth,
          icon: Icon(Icons.chevron_left, color: scheme.onSurfaceVariant),
        ),
        IconButton(
          onPressed: _pageOf(_displayYear, _displayMonth) < _monthCount - 1 ? () => _goToPage(_pageOf(_displayYear, _displayMonth) + 1) : null,
          tooltip: U.s.nextMonth,
          icon: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ),
      ],
    ],
  ).pSymmetric(horizontal: 8);

  Widget _weekDays() => Row(
    children: List<Widget>.generate(
      7,
      (int index) => UTextBodySmall(
        isFa ? JalaliFormatter.weekDayNamesShort[index] : JalaliFormatter.weekDayNamesShortLatin[index],
        color: scheme.onSurface,
        textAlign: TextAlign.center,
        expanded: 1,
      ),
    ),
  ).pSymmetric(horizontal: 12, vertical: 4);

  Widget _monthPages() => PageView.builder(
    controller: _pageController,
    itemCount: _monthCount,
    onPageChanged: (int page) => setState(() {
      _displayYear = _yearOfPage(page);
      _displayMonth = _monthOfPage(page);
    }),
    itemBuilder: (BuildContext context, int page) => _daysGrid(_yearOfPage(page), _monthOfPage(page)),
  );

  Widget _daysGrid(int year, int month) {
    final int offset = Jalali(year, month).weekDay - 1;
    final int length = Jalali(year, month).monthLength;
    final Jalali today = Jalali.now();
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
      itemCount: offset + length,
      itemBuilder: (BuildContext context, int index) {
        if (index < offset) return const SizedBox.shrink();
        final int day = index - offset + 1;
        final Jalali date = Jalali(year, month, day);
        final bool disabled = _isOutOfRange(date);
        final bool selected = _selected.year == year && _selected.month == month && _selected.day == day;
        final bool isToday = today.year == year && today.month == month && today.day == day;
        return UContainer(
          onTap: disabled ? null : () => setState(() => _selected = date),
          margin: const EdgeInsets.all(3),
          shape: BoxShape.circle,
          color: selected ? scheme.primary : null,
          border: !selected && isToday ? Border.all(color: scheme.primary) : null,
          alignment: Alignment.center,
          child: UTextBodyLarge(
            UJalaliDatePicker.number(day, persian: isFa),
            color: disabled
                ? scheme.onSurface.withValues(alpha: 0.38)
                : selected
                ? scheme.onPrimary
                : isToday
                ? scheme.primary
                : scheme.onSurface,
          ),
        );
      },
    );
  }

  Widget _yearGrid() => GridView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 2.2, mainAxisSpacing: 8, crossAxisSpacing: 8),
    itemCount: _yearCount,
    controller: _yearScrollController,
    itemBuilder: (BuildContext context, int index) {
      final int year = widget.firstDate.year + index;
      final bool selected = year == _displayYear;
      return UContainer(
        onTap: () => _selectYear(year),
        radius: 20,
        color: selected ? scheme.primary : null,
        border: selected ? null : Border.all(color: scheme.outline),
        alignment: Alignment.center,
        child: UTextBodyLarge(
          UJalaliDatePicker.number(year, persian: isFa),
          color: selected ? scheme.onPrimary : scheme.onSurface,
        ),
      );
    },
  );

  Widget _input() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      UTextField(
        controller: _inputController,
        labelText: U.s.date,
        hintText: "1404/05/25",
        keyboardType: TextInputType.datetime,
        textAlign: TextAlign.center,
        formatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp("[0-9/]")),
          LengthLimitingTextInputFormatter(10),
        ],
        onChanged: _onInputChanged,
      ),
      if (_inputError != null) UTextBodySmall(_inputError!, color: scheme.error).pOnly(top: 8),
    ],
  ).pSymmetric(horizontal: 24);

  Widget _actions() => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: <Widget>[
      TextButton(onPressed: UNavigator.back, child: Text(U.s.cancel)),
      TextButton(onPressed: _inputError == null ? _submit : null, child: Text(U.s.ok)),
    ],
  ).pLTRB(8, 4, 8, 8);
}

class UJalaliDatePickerSpinner extends StatefulWidget {
  const UJalaliDatePickerSpinner({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    super.key,
    this.onDateSelected,
    this.helpText,
    this.showTodayButton = true,
  });

  final Jalali initialDate;
  final Jalali firstDate;
  final Jalali lastDate;
  final Function(DateTime, Jalali)? onDateSelected;
  final String? helpText;
  final bool showTodayButton;

  @override
  State<UJalaliDatePickerSpinner> createState() => _UJalaliDatePickerSpinnerState();
}

class _UJalaliDatePickerSpinnerState extends UState<UJalaliDatePickerSpinner> {
  late int _year = widget.initialDate.year;
  late int _month = widget.initialDate.month;
  late int _day = widget.initialDate.day;
  late final FixedExtentScrollController _yearController = FixedExtentScrollController(initialItem: _year - _minYear);
  late final FixedExtentScrollController _monthController = FixedExtentScrollController(initialItem: _month - _minMonth);
  late final FixedExtentScrollController _dayController = FixedExtentScrollController(initialItem: _day - _minDay);

  int get _minYear => widget.firstDate.year;

  int get _maxYear => widget.lastDate.year;

  int get _minMonth => _year == _minYear ? widget.firstDate.month : 1;

  int get _maxMonth => _year == _maxYear ? widget.lastDate.month : 12;

  int get _minDay => _year == _minYear && _month == widget.firstDate.month ? widget.firstDate.day : 1;

  int get _maxDay {
    final int length = Jalali(_year, _month).monthLength;
    return _year == _maxYear && _month == widget.lastDate.month ? min(length, widget.lastDate.day) : length;
  }

  Jalali get _value => Jalali(_year, _month, _day);

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  void _sync() {
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) return;
      final int monthItem = _month - _minMonth;
      final int dayItem = _day - _minDay;
      if (_monthController.hasClients && _monthController.selectedItem != monthItem) _monthController.jumpToItem(monthItem);
      if (_dayController.hasClients && _dayController.selectedItem != dayItem) _dayController.jumpToItem(dayItem);
    });
  }

  void _onYearChanged(int index) {
    setState(() {
      _year = _minYear + index;
      _month = _month.clamp(_minMonth, _maxMonth);
      _day = _day.clamp(_minDay, _maxDay);
    });
    _sync();
  }

  void _onMonthChanged(int index) {
    setState(() {
      _month = _minMonth + index;
      _day = _day.clamp(_minDay, _maxDay);
    });
    _sync();
  }

  void _onDayChanged(int index) => setState(() => _day = _minDay + index);

  void _goToToday() {
    final Jalali today = UJalaliDatePicker.clamp(Jalali.now(), widget.firstDate, widget.lastDate);
    setState(() {
      _year = today.year;
      _month = today.month;
      _day = today.day;
    });
    if (_yearController.hasClients) _yearController.jumpToItem(_year - _minYear);
    _sync();
  }

  void _submit() {
    widget.onDateSelected?.call(_value.toDateTime(), _value);
    UNavigator.back(_value);
  }

  @override
  Widget build(BuildContext context) => UColumn(
    padding: const EdgeInsets.all(12),
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      _header(),
      _wheels(),
      _actions(),
    ],
  );

  Widget _header() => Row(
    children: <Widget>[
      UTextTitleMedium(UJalaliDatePicker.headline(_value, persian: isFa), color: scheme.onSurface).pOnly(top: 4).expanded(),
      if (widget.showTodayButton) TextButton(onPressed: _goToToday, child: Text(U.s.today)),
    ],
  ).pLTRB(20, 16, 12, 8);

  Widget _wheels() => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      SizedBox(
        height: 200,
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 80,
              left: 12,
              right: 12,
              child: UContainer(height: 40, radius: 12, color: scheme.primary.withValues(alpha: 0.12)),
            ),
            Row(
              children: <Widget>[
                _wheel(
                  controller: _dayController,
                  itemCount: _maxDay - _minDay + 1,
                  onChanged: _onDayChanged,
                  labelBuilder: (int index) => UJalaliDatePicker.number(_minDay + index, persian: isFa),
                  flex: 2,
                ),
                _wheel(
                  controller: _monthController,
                  itemCount: _maxMonth - _minMonth + 1,
                  onChanged: _onMonthChanged,
                  labelBuilder: (int index) => UJalaliDatePicker.monthName(_minMonth + index, persian: isFa),
                  flex: 3,
                ),
                _wheel(
                  controller: _yearController,
                  itemCount: _maxYear - _minYear + 1,
                  onChanged: _onYearChanged,
                  labelBuilder: (int index) => UJalaliDatePicker.number(_minYear + index, persian: isFa),
                  flex: 3,
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required ValueChanged<int> onChanged,
    required String Function(int index) labelBuilder,
    int flex = 1,
  }) => CupertinoPicker.builder(
    scrollController: controller,
    itemExtent: 40,
    childCount: itemCount,
    squeeze: 1.1,
    diameterRatio: 1.6,
    selectionOverlay: const SizedBox.shrink(),
    onSelectedItemChanged: onChanged,
    itemBuilder: (BuildContext context, int index) => UTextBodyLarge(
      labelBuilder(index),
      color: scheme.onSurface,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      center: true,
    ),
  ).expanded(flex: flex);

  Widget _actions() => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: <Widget>[
      TextButton(onPressed: UNavigator.back, child: Text(U.s.cancel)),
      TextButton(onPressed: _submit, child: Text(U.s.confirm)),
    ],
  ).pLTRB(8, 4, 8, 12);
}
