import "package:u/utilities.dart";

enum _PickerMode { calendar, selectYear, selectMonth }

class JalaliDatePickerDialog extends StatefulWidget {
  const JalaliDatePickerDialog({
    required this.initialDate,
    required this.onDateSelected,
    this.endYear = 1350,
    this.startYear = 1410,
    super.key,
  });

  final Jalali initialDate;
  final int startYear;
  final int endYear;
  final Function(DateTime, Jalali) onDateSelected;

  @override
  _JalaliDatePickerDialogState createState() => _JalaliDatePickerDialogState();
}

class _JalaliDatePickerDialogState extends State<JalaliDatePickerDialog> {
  late Jalali selectedDate;
  late int currentYear;
  late int currentMonth;
  _PickerMode mode = _PickerMode.selectYear;

  final List<String> monthNames = <String>["فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور", "مهر", "آبان", "آذر", "دی", "بهمن", "اسفند"];

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
    currentYear = selectedDate.year;
    currentMonth = selectedDate.month;
  }

  Widget _buildHeader() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          "$currentYear",
          style: TextStyle(color: scheme.onPrimary, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          monthNames[currentMonth - 1],
          style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.75), fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ],
    ).container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      backgroundColor: scheme.primary,
    );
  }

  Widget _buildCalendarNavigation() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
      IconButton(
        onPressed: () {
          setState(() {
            if (currentMonth == 1) {
              currentMonth = 12;
              currentYear--;
            } else {
              currentMonth--;
            }
          });
        },
        icon: const Icon(Icons.arrow_back),
      ),
      Text(
        "${monthNames[currentMonth - 1]} $currentYear",
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      IconButton(
        onPressed: () {
          setState(() {
            if (currentMonth == 12) {
              currentMonth = 1;
              currentYear++;
            } else {
              currentMonth++;
            }
          });
        },
        icon: const Icon(Icons.arrow_forward),
      ),
    ],
  );

  Widget _buildCalendarGrid() {
    final List<Widget> dayWidgets = <Widget>[];

    const List<String> weekDays = <String>["شنبه", "یکشنبه", "دوشنبه", "سه‌شنبه", "چهارشنبه", "پنجشنبه", "جمعه"];
    dayWidgets.addAll(
      weekDays
          .map(
            (String day) => UTextLabelSmall(day, fontWeight: FontWeight.bold).container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
            ),
          )
          .toList(),
    );

    final int weekdayOffset = Jalali(currentYear, currentMonth).weekDay - 1;

    for (int i = 0; i < weekdayOffset; i++) dayWidgets.add(const SizedBox());

    final int daysInMonth = Jalali(currentYear, currentMonth).monthLength;
    for (int day = 1; day <= daysInMonth; day++) {
      final bool isSelected = selectedDate.year == currentYear && selectedDate.month == currentMonth && selectedDate.day == day;
      final ColorScheme scheme = Theme.of(context).colorScheme;
      dayWidgets.add(
        InkWell(
          onTap: () => setState(() => selectedDate = Jalali(currentYear, currentMonth, day)),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected ? scheme.primary : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              "$day",
              style: TextStyle(
                color: isSelected ? scheme.onPrimary : scheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      padding: const EdgeInsets.all(8),
      crossAxisCount: 7,
      shrinkWrap: true,
      children: dayWidgets,
    );
  }

  Widget _buildYearSelection() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final int lo = min(widget.startYear, widget.endYear);
    final int hi = max(widget.startYear, widget.endYear);
    final List<int> years = <int>[for (int y = hi; y >= lo; y--) y];
    return Scrollbar(
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: years.length,
        itemBuilder: (BuildContext context, int index) {
          final int year = years[index];
          final bool selected = year == currentYear;
          return InkWell(
            onTap: () => setState(() {
              currentYear = year;
              selectedDate = Jalali(currentYear, currentMonth, selectedDate.day);
              mode = _PickerMode.selectMonth;
            }),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 3),
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? scheme.primary : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "$year",
                style: TextStyle(color: selected ? scheme.onPrimary : scheme.onSurface, fontWeight: selected ? FontWeight.bold : FontWeight.normal),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Month grid arranged in 4 seasonal rows of 3 months each.
  Widget _buildMonthSelection() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<Widget> monthWidgets = <Widget>[];
    for (int i = 0; i < 12; i++) {
      final bool selected = currentMonth == i + 1;
      monthWidgets.add(
        InkWell(
          onTap: () => setState(() {
            currentMonth = i + 1;
            selectedDate = Jalali(currentYear, currentMonth, selectedDate.day);
            mode = _PickerMode.calendar;
          }),
          child:
              Text(
                monthNames[i],
                textAlign: TextAlign.center,
                style: TextStyle(color: selected ? scheme.onPrimary : scheme.onSurface),
              ).container(
                backgroundColor: selected ? scheme.primary : scheme.surfaceContainerHighest,
                radius: 8,
                margin: const EdgeInsets.all(4),
                alignment: Alignment.center,
              ),
        ),
      );
    }
    return GridView.count(
      padding: const EdgeInsets.all(8),
      crossAxisCount: 3,
      childAspectRatio: 2.4,
      shrinkWrap: true,
      children: monthWidgets,
    );
  }

  Widget _buildContent() {
    switch (mode) {
      case _PickerMode.selectYear:
        return _buildYearSelection();
      case _PickerMode.selectMonth:
        return _buildMonthSelection();
      case _PickerMode.calendar:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildCalendarNavigation(),
            _buildCalendarGrid(),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    contentPadding: EdgeInsets.zero,
    content: Column(
      children: <Widget>[
        Stack(
          children: <Widget>[
            _buildHeader().alignAtCenter(),
            IconButton(
              onPressed: () => setState(() => mode = _PickerMode.selectYear),
              icon: const Icon(Icons.calendar_month),
            ).alignAtCenterLeft().pOnly(top: 12, left: 12),
          ],
        ),
        Expanded(child: _buildContent()),
      ],
    ).container(width: 350, height: 500),
    actions: <Widget>[
      TextButton(onPressed: UNavigator.back, child: Text(U.s.cancel)),
      TextButton(
        onPressed: () {
          widget.onDateSelected.call(selectedDate.toDateTime(), selectedDate);
          UNavigator.back(selectedDate);
        },
        child: Text(U.s.submit),
      ),
    ],
  );
}
