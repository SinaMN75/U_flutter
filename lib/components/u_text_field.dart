import "package:u/utilities.dart";

class UTextField extends StatefulWidget {
  const UTextField({
    super.key,
    this.text,
    this.labelText,
    this.hintText,
    this.contentPadding,
    this.fontSize,
    this.controller,
    this.onTap,
    this.validator,
    this.prefix,
    this.suffix,
    this.onSave,
    this.initialValue,
    this.textHeight,
    this.onChanged,
    this.onFieldSubmitted,
    this.maxLength,
    this.formatters,
    this.autoFillHints,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.lines = 1,
    this.hasClearButton = false,
    this.required = false,
    this.isDense = false,
    this.textAlign = TextAlign.start,
    this.textColor,
    this.focusNode,
    this.margin,
    this.visible = true,
    this.opacity,
    this.fit,
    this.fitAlignment = Alignment.center,
    this.scale,
    this.rotate,
    this.translate,
    this.center = false,
    this.safeArea = false,
    this.expanded,
    this.flexible,
    this.positioned = false,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.positionedWidth,
    this.positionedHeight,
    this.borderRadius,
    this.floatingLabelBehavior,
  });

  final bool obscureText;
  final bool hasClearButton;
  final bool required;
  final bool isDense;
  final bool readOnly;
  final String? text;
  final String? labelText;
  final String? hintText;
  final String? initialValue;
  final String? Function(String?)? validator;
  final double? fontSize;
  final double? textHeight;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final int lines;
  final int? maxLength;
  final EdgeInsetsGeometry? contentPadding;
  final VoidCallback? onTap;
  final Widget? prefix;
  final Widget? suffix;
  final Function(String? value)? onSave;
  final TextAlign textAlign;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final List<TextInputFormatter>? formatters;
  final List<String>? autoFillHints;
  final Color? textColor;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? margin;
  final bool visible;
  final double? opacity;
  final BoxFit? fit;
  final AlignmentGeometry fitAlignment;
  final double? scale;
  final double? rotate;
  final Offset? translate;
  final bool center;
  final bool safeArea;
  final int? expanded;
  final int? flexible;
  final bool positioned;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? positionedWidth;
  final double? positionedHeight;
  final double? borderRadius;
  final FloatingLabelBehavior? floatingLabelBehavior;

  @override
  State<UTextField> createState() => _UTextFieldState();
}

class _UTextFieldState extends State<UTextField> {
  bool obscure = false;

  @override
  void initState() {
    obscure = widget.obscureText;
    super.initState();
  }

  InputBorder? _rounded(InputBorder? border) {
    if (widget.borderRadius == null || border == null) return null;
    final BorderRadius radius = BorderRadius.circular(widget.borderRadius!);
    if (border is OutlineInputBorder) return border.copyWith(borderRadius: radius);
    return OutlineInputBorder(borderRadius: radius, borderSide: border.borderSide);
  }

  @override
  Widget build(BuildContext context) {
    final InputDecorationThemeData inputTheme = Theme.of(context).inputDecorationTheme;
    return uWrap(
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.text != null)
            UIconTextHorizontal(
              leading: Text(widget.text!, style: Theme.of(context).textTheme.titleSmall),
              trailing: widget.required ? UTextBodyMedium("*", color: Theme.of(context).colorScheme.error) : const SizedBox(),
            ).pSymmetric(vertical: 8),
          TextFormField(
            focusNode: widget.focusNode,
            autofillHints: widget.autoFillHints,
            textDirection: widget.keyboardType == TextInputType.number || widget.keyboardType == TextInputType.phone ? TextDirection.ltr : null,
            inputFormatters: widget.formatters ?? (widget.keyboardType == TextInputType.number || widget.keyboardType == TextInputType.phone ? <TextInputFormatter>[UNumberInputFormatter()] : null),
            style: TextStyle(fontSize: widget.fontSize, color: widget.textColor),
            maxLength: widget.maxLength,
            onChanged: widget.onChanged,
            readOnly: widget.readOnly,
            initialValue: widget.initialValue,
            textAlign: widget.textAlign,
            onSaved: widget.onSave,
            onTap: widget.onTap,
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            obscureText: obscure,
            validator: widget.validator,
            minLines: widget.lines,
            onFieldSubmitted: widget.onFieldSubmitted,
            maxLines: widget.lines == 1 ? 1 : 20,
            decoration: InputDecoration(
              labelText: widget.labelText,
              floatingLabelBehavior: widget.floatingLabelBehavior,
              border: _rounded(inputTheme.border),
              enabledBorder: _rounded(inputTheme.enabledBorder),
              focusedBorder: _rounded(inputTheme.focusedBorder),
              errorBorder: _rounded(inputTheme.errorBorder),
              focusedErrorBorder: _rounded(inputTheme.focusedErrorBorder),
              disabledBorder: _rounded(inputTheme.disabledBorder),
              isDense: widget.isDense,
              helperStyle: const TextStyle(fontSize: 0),
              hintText: widget.hintText,
              contentPadding: widget.contentPadding ?? (widget.lines > 1 ? const EdgeInsets.symmetric(vertical: 20, horizontal: 12) : const EdgeInsets.symmetric(vertical: 2, horizontal: 12)),
              suffixIcon: widget.obscureText
                  ? IconButton(
                      splashRadius: 1,
                      onPressed: () => setState(() => obscure = !obscure),
                      icon: obscure ? const Icon(Icons.visibility) : const Icon(Icons.visibility_off),
                    )
                  : widget.suffix,
              prefixIcon: widget.prefix,
            ),
          ),
        ],
      ),
      margin: widget.margin,
      visible: widget.visible,
      opacity: widget.opacity,
      fit: widget.fit,
      fitAlignment: widget.fitAlignment,
      scale: widget.scale,
      rotate: widget.rotate,
      translate: widget.translate,
      center: widget.center,
      safeArea: widget.safeArea,
      expanded: widget.expanded,
      flexible: widget.flexible,
      positioned: widget.positioned,
      left: widget.left,
      top: widget.top,
      right: widget.right,
      bottom: widget.bottom,
      positionedWidth: widget.positionedWidth,
      positionedHeight: widget.positionedHeight,
    );
  }
}

class UDropDownField<T> extends StatefulWidget {
  const UDropDownField({
    required this.initialValue,
    required this.items,
    required this.onChanged,
    super.key,
    this.text,
    this.labelText,
    this.hintText,
    this.contentPadding,
    this.fontSize,
    this.onTap,
    this.validator,
    this.prefix,
    this.suffix,
    this.onSave,
    this.textHeight,
    this.required = false,
    this.isDense = true,
    this.margin,
    this.visible = true,
    this.opacity,
    this.fit,
    this.fitAlignment = Alignment.center,
    this.scale,
    this.rotate,
    this.translate,
    this.center = false,
    this.safeArea = false,
    this.expanded,
    this.flexible,
    this.positioned = false,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.positionedWidth,
    this.positionedHeight,
  });

  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;
  final T initialValue;

  final bool required;
  final bool isDense;
  final String? text;
  final String? labelText;
  final String? hintText;
  final String? Function(T?)? validator;
  final double? fontSize;
  final double? textHeight;
  final EdgeInsetsGeometry? contentPadding;
  final VoidCallback? onTap;
  final Widget? prefix;
  final Widget? suffix;
  final Function(T? value)? onSave;
  final EdgeInsetsGeometry? margin;
  final bool visible;
  final double? opacity;
  final BoxFit? fit;
  final AlignmentGeometry fitAlignment;
  final double? scale;
  final double? rotate;
  final Offset? translate;
  final bool center;
  final bool safeArea;
  final int? expanded;
  final int? flexible;
  final bool positioned;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? positionedWidth;
  final double? positionedHeight;

  @override
  State<UDropDownField<T>> createState() => _UDropDownFieldState<T>();
}

class _UDropDownFieldState<T> extends State<UDropDownField<T>> {
  @override
  Widget build(BuildContext context) => uWrap(
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (widget.text != null)
          UIconTextHorizontal(
            leading: Text(widget.text!, style: Theme.of(context).textTheme.titleSmall),
            trailing: widget.required ? UTextBodyMedium("*", color: Theme.of(context).colorScheme.error) : const SizedBox(),
          ).pSymmetric(vertical: 8),
        DropdownButtonFormField<T>(
          initialValue: widget.initialValue,
          items: widget.items,
          onChanged: (T? i) => widget.onChanged(i as T),
          onSaved: widget.onSave,
          onTap: widget.onTap,
          validator: widget.validator,
          decoration: InputDecoration(
            filled: true,
            labelText: widget.labelText,
            isDense: widget.isDense,
            hintText: widget.hintText,
            contentPadding: widget.contentPadding ?? const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            suffixIcon: widget.suffix,
            prefixIcon: widget.prefix,
          ),
        ),
      ],
    ),
    margin: widget.margin,
    visible: widget.visible,
    opacity: widget.opacity,
    fit: widget.fit,
    fitAlignment: widget.fitAlignment,
    scale: widget.scale,
    rotate: widget.rotate,
    translate: widget.translate,
    center: widget.center,
    safeArea: widget.safeArea,
    expanded: widget.expanded,
    flexible: widget.flexible,
    positioned: widget.positioned,
    left: widget.left,
    top: widget.top,
    right: widget.right,
    bottom: widget.bottom,
    positionedWidth: widget.positionedWidth,
    positionedHeight: widget.positionedHeight,
  );
}

class UTextFieldDatePicker extends StatefulWidget {
  const UTextFieldDatePicker({
    required this.onChange,
    super.key,
    this.text,
    this.fontSize,
    this.hintText,
    this.labelText,
    this.prefix,
    this.suffix,
    this.textHeight,
    this.controller,
    this.initialDate,
    this.startYear,
    this.endYear,
    this.validator,
    this.readOnly = false,
    this.date = true,
    this.time = false,
    this.textAlign = TextAlign.start,
    this.jalali = false,
    this.jalaliType = UJalaliDatePickerType.material,
    this.spinnerAsDialog = false,
    this.helpText,
    this.margin,
    this.visible = true,
    this.opacity,
    this.fit,
    this.fitAlignment = Alignment.center,
    this.scale,
    this.rotate,
    this.translate,
    this.center = false,
    this.safeArea = false,
    this.expanded,
    this.flexible,
    this.positioned = false,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.positionedWidth,
    this.positionedHeight,
  });

  final Function(DateTime, UJalali) onChange;
  final String? text;
  final double? fontSize;
  final String? hintText;
  final String? labelText;
  final Widget? prefix;
  final bool readOnly;
  final Widget? suffix;
  final TextAlign textAlign;
  final double? textHeight;
  final TextEditingController? controller;
  final DateTime? initialDate;
  final int? startYear;
  final int? endYear;
  final String? Function(String?)? validator;
  final bool date;
  final bool time;
  final bool jalali;
  final UJalaliDatePickerType jalaliType;
  final bool spinnerAsDialog;
  final String? helpText;
  final EdgeInsetsGeometry? margin;
  final bool visible;
  final double? opacity;
  final BoxFit? fit;
  final AlignmentGeometry fitAlignment;
  final double? scale;
  final double? rotate;
  final Offset? translate;
  final bool center;
  final bool safeArea;
  final int? expanded;
  final int? flexible;
  final bool positioned;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? positionedWidth;
  final double? positionedHeight;

  @override
  State<UTextFieldDatePicker> createState() => _UTextFieldDatePickerState();
}

class _UTextFieldDatePickerState extends State<UTextFieldDatePicker> {
  late DateTime selectedDateTime;

  @override
  void initState() {
    selectedDateTime = widget.initialDate ?? DateTime.now();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UTextField(
    controller: widget.controller,
    text: widget.text,
    prefix: widget.prefix,
    suffix: widget.suffix,
    labelText: widget.labelText,
    fontSize: widget.fontSize,
    hintText: widget.hintText,
    textAlign: widget.textAlign,
    readOnly: true,
    textHeight: widget.textHeight,
    validator: widget.validator,
    margin: widget.margin,
    visible: widget.visible,
    opacity: widget.opacity,
    fit: widget.fit,
    fitAlignment: widget.fitAlignment,
    scale: widget.scale,
    rotate: widget.rotate,
    translate: widget.translate,
    center: widget.center,
    safeArea: widget.safeArea,
    expanded: widget.expanded,
    flexible: widget.flexible,
    positioned: widget.positioned,
    left: widget.left,
    top: widget.top,
    right: widget.right,
    bottom: widget.bottom,
    positionedWidth: widget.positionedWidth,
    positionedHeight: widget.positionedHeight,
    onTap: () async {
      if (!widget.readOnly) {
        if (widget.date) {
          if (widget.jalali) {
            final int startYear = widget.startYear ?? 1350;
            final int endYear = widget.endYear ?? 1420;
            final UJalali? picked = await UJalaliDatePicker.show(
              type: widget.jalaliType,
              initialDate: UJalali.fromDateTime(selectedDateTime),
              firstDate: UJalali(startYear),
              lastDate: UJalali(endYear, 12, UJalali(endYear, 12).monthLength),
              helpText: widget.helpText,
              asDialog: widget.spinnerAsDialog,
            );

            if (!mounted) return;
            if (picked != null) {
              final DateTime gregorian = picked.toDateTime();
              selectedDateTime = DateTime(gregorian.year, gregorian.month, gregorian.day, selectedDateTime.hour, selectedDateTime.minute);
              setState(() {});
              widget.onChange(selectedDateTime, picked);
            }
          } else {
            final DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: selectedDateTime,
              firstDate: DateTime(widget.startYear ?? 1950),
              lastDate: DateTime(widget.endYear ?? 2040),
            );

            if (!mounted) return;
            if (pickedDate != null) {
              selectedDateTime = DateTime(
                pickedDate.year,
                pickedDate.month,
                pickedDate.day,
                selectedDateTime.hour,
                selectedDateTime.minute,
              );
              setState(() {});
              final UJalali jalali = UJalali.fromDateTime(selectedDateTime);
              widget.onChange(selectedDateTime, jalali);
            }
          }

          if (widget.time) {
            final TimeOfDay? timeOfDay = await showTimePicker(
              context: navigatorKey.currentContext!,
              initialTime: TimeOfDay.fromDateTime(selectedDateTime),
            );

            if (!mounted) return;
            if (timeOfDay != null) {
              selectedDateTime = DateTime(
                selectedDateTime.year,
                selectedDateTime.month,
                selectedDateTime.day,
                timeOfDay.hour,
                timeOfDay.minute,
              );
              setState(() {});
              final UJalali jalali = UJalali.fromDateTime(selectedDateTime);
              widget.onChange(selectedDateTime, jalali);
            }
          }
        }
      }
    },
  );
}

class UTextFieldAutoComplete<T> extends StatefulWidget {
  const UTextFieldAutoComplete({
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    required this.selectedItem,
    super.key,
    this.hintText,
    this.title,
    this.margin,
    this.visible = true,
    this.opacity,
    this.fit,
    this.fitAlignment = Alignment.center,
    this.scale,
    this.rotate,
    this.translate,
    this.center = false,
    this.safeArea = false,
    this.expanded,
    this.flexible,
    this.positioned = false,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.positionedWidth,
    this.positionedHeight,
  });

  final List<T> items;
  final String Function(T) labelBuilder;
  final void Function(T) onChanged;
  final T selectedItem;
  final String? hintText;
  final String? title;
  final EdgeInsetsGeometry? margin;
  final bool visible;
  final double? opacity;
  final BoxFit? fit;
  final AlignmentGeometry fitAlignment;
  final double? scale;
  final double? rotate;
  final Offset? translate;
  final bool center;
  final bool safeArea;
  final int? expanded;
  final int? flexible;
  final bool positioned;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? positionedWidth;
  final double? positionedHeight;

  @override
  State<UTextFieldAutoComplete<T>> createState() => _UTextFieldAutoCompleteState<T>();
}

class _UTextFieldAutoCompleteState<T> extends State<UTextFieldAutoComplete<T>> {
  late URxList<T> filteredItems = widget.items.obs;

  Future<void> _openSearchDialog() async {
    await showDialog<T>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: UTextBodySmall(U.s.searchAndSelect),
        content: SizedBox(
          width: 200,
          height: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UTextField(
                hintText: U.s.search,
                onChanged: (String? i) => filteredItems(
                  widget.items.where((T item) => widget.labelBuilder(item).toLowerCase().contains(i!.toLowerCase())).toList(),
                ),
              ),
              const SizedBox(height: 12),
              UObx(
                () => ListView.separated(
                  shrinkWrap: true,
                  itemCount: filteredItems.length,
                  separatorBuilder: (BuildContext context, int index) => const Divider(height: 0),
                  itemBuilder: (BuildContext context, int index) {
                    final T item = filteredItems[index];
                    return ListTile(
                      title: Text(widget.labelBuilder(item)),
                      onTap: () {
                        widget.onChanged(item);
                        Navigator.of(context).pop(item);
                      },
                    );
                  },
                ),
              ).expanded(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => uWrap(
    widget.title == null
        ? _input()
        : UIconTextVertical(
            crossAxisAlignment: CrossAxisAlignment.start,
            leading: UTextBodySmall(widget.title ?? ""),
            trailing: _input(),
          ),
    margin: widget.margin,
    visible: widget.visible,
    opacity: widget.opacity,
    fit: widget.fit,
    fitAlignment: widget.fitAlignment,
    scale: widget.scale,
    rotate: widget.rotate,
    translate: widget.translate,
    center: widget.center,
    safeArea: widget.safeArea,
    expanded: widget.expanded,
    flexible: widget.flexible,
    positioned: widget.positioned,
    left: widget.left,
    top: widget.top,
    right: widget.right,
    bottom: widget.bottom,
    positionedWidth: widget.positionedWidth,
    positionedHeight: widget.positionedHeight,
  );

  Widget _input() => InkWell(
    onTap: _openSearchDialog,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: widget.hintText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      child: Text(widget.labelBuilder(widget.selectedItem)),
    ),
  );
}

class UTextFieldAutoCompleteAsync<T> extends StatefulWidget {
  const UTextFieldAutoCompleteAsync({
    required this.labelBuilder,
    required this.onChanged,
    required this.selectedItem,
    required this.fetchData,
    super.key,
    this.hintText,
    this.debounceDuration = const Duration(milliseconds: 500),
    this.margin,
    this.visible = true,
    this.opacity,
    this.fit,
    this.fitAlignment = Alignment.center,
    this.scale,
    this.rotate,
    this.translate,
    this.center = false,
    this.safeArea = false,
    this.expanded,
    this.flexible,
    this.positioned = false,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.positionedWidth,
    this.positionedHeight,
  });

  final String Function(T) labelBuilder;
  final void Function(T?) onChanged;
  final T? selectedItem;
  final String? hintText;
  final Duration debounceDuration;
  final Future<List<T>> Function(String query) fetchData;
  final EdgeInsetsGeometry? margin;
  final bool visible;
  final double? opacity;
  final BoxFit? fit;
  final AlignmentGeometry fitAlignment;
  final double? scale;
  final double? rotate;
  final Offset? translate;
  final bool center;
  final bool safeArea;
  final int? expanded;
  final int? flexible;
  final bool positioned;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? positionedWidth;
  final double? positionedHeight;

  @override
  State<UTextFieldAutoCompleteAsync<T>> createState() => _UTextFieldAutoCompleteAsyncState<T>();
}

class _UTextFieldAutoCompleteAsyncState<T> extends State<UTextFieldAutoCompleteAsync<T>> {
  final List<T> _list = <T>[];
  T? _selectedItem;
  Timer? _debounceTimer;
  bool _isLoading = false;

  @override
  void initState() {
    _selectedItem = widget.selectedItem;
    _search("");
    super.initState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() {
      _list.clear();
      _isLoading = false;
    });

    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () async {
      setState(() => _isLoading = true);

      try {
        final List<T> results = await widget.fetchData(query);
        if (!mounted) return;
        setState(() {
          _list.clear();
          _list.addAll(results);
          _isLoading = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _list.clear();
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _openSearchDialog() async {
    final T? result = await showDialog<T?>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          Future<void> doSearch(String query) async {
            _debounceTimer?.cancel();
            setDialogState(() => _isLoading = true);
            _debounceTimer = Timer(widget.debounceDuration, () async {
              try {
                final List<T> results = await widget.fetchData(query);
                if (!mounted) return;
                setDialogState(() {
                  _list
                    ..clear()
                    ..addAll(results);
                  _isLoading = false;
                });
              } catch (e) {
                if (!mounted) return;
                setDialogState(() {
                  _list.clear();
                  _isLoading = false;
                });
              }
            });
          }

          return AlertDialog(
            title: Text(U.s.search),
            content: SizedBox(
              width: 200,
              height: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    decoration: InputDecoration(
                      hintText: U.s.search,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: doSearch,
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: _buildResultsList()),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (result != null && mounted) {
      setState(() => _selectedItem = result);
      widget.onChanged(result);
    }
  }

  Widget _buildResultsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_list.isEmpty) {
      return const Center(child: Text("---"));
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _list.length,
      itemBuilder: (BuildContext context, int index) {
        final T item = _list[index];
        return ListTile(
          title: Text(widget.labelBuilder(item)),
          onTap: () => Navigator.of(context).pop(item),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => uWrap(
    InkWell(
      onTap: _openSearchDialog,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.hintText,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        child: _selectedItem == null ? const Text("___") : Text(widget.labelBuilder(_selectedItem as T)),
      ),
    ),
    margin: widget.margin,
    visible: widget.visible,
    opacity: widget.opacity,
    fit: widget.fit,
    fitAlignment: widget.fitAlignment,
    scale: widget.scale,
    rotate: widget.rotate,
    translate: widget.translate,
    center: widget.center,
    safeArea: widget.safeArea,
    expanded: widget.expanded,
    flexible: widget.flexible,
    positioned: widget.positioned,
    left: widget.left,
    top: widget.top,
    right: widget.right,
    bottom: widget.bottom,
    positionedWidth: widget.positionedWidth,
    positionedHeight: widget.positionedHeight,
  );
}

class UTextFieldPhoneNumber extends StatefulWidget {
  const UTextFieldPhoneNumber({
    super.key,
    this.pickerMode = UCountryPickerMode.bottomSheet,
    this.onChanged,
    this.controller,
    this.initialValue,
    this.initialCountryCode,
    this.text,
    this.labelText,
    this.hintText,
    this.validator,
    this.required = false,
    this.readOnly = false,
    this.contentPadding,
    this.focusNode,
    this.margin,
    this.visible = true,
    this.opacity,
    this.fit,
    this.fitAlignment = Alignment.center,
    this.scale,
    this.rotate,
    this.translate,
    this.center = false,
    this.safeArea = false,
    this.expanded,
    this.flexible,
    this.positioned = false,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.positionedWidth,
    this.positionedHeight,
  });

  final UCountryPickerMode pickerMode;
  final Function(UPhoneNumberData)? onChanged;
  final TextEditingController? controller;
  final String? initialValue;
  final String? initialCountryCode;
  final String? text;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final bool required;
  final bool readOnly;
  final EdgeInsetsGeometry? contentPadding;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? margin;
  final bool visible;
  final double? opacity;
  final BoxFit? fit;
  final AlignmentGeometry fitAlignment;
  final double? scale;
  final double? rotate;
  final Offset? translate;
  final bool center;
  final bool safeArea;
  final int? expanded;
  final int? flexible;
  final bool positioned;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? positionedWidth;
  final double? positionedHeight;

  @override
  State<UTextFieldPhoneNumber> createState() => _UTextFieldPhoneNumberState();
}

class _UTextFieldPhoneNumberState extends State<UTextFieldPhoneNumber> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  late UCountry _selectedCountry;
  String _lastText = "";

  @override
  void initState() {
    super.initState();
    final String initial = widget.initialValue ?? widget.controller?.text ?? "";
    _selectedCountry = UPhoneNumberUtils.countryOf(initial) ?? UPhoneNumberUtils.resolveCountry(widget.initialCountryCode);
    _setNational(UPhoneNumberUtils.nationalNumber(initial, countryCode: _selectedCountry.dialCode), _selectedCountry, notify: false);
    _phoneController.addListener(_onPhoneChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncController();
    });
    widget.controller?.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    _phoneController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String get _national => UPhoneNumberUtils.sanitize(_phoneController.text).replaceAll("+", "");

  String get _e164 => _national.isEmpty ? "" : "${_selectedCountry.dialCode}$_national";

  bool get _isComplete => _national.isNotEmpty && UPhoneNumberUtils.isValid(_e164, countryCode: _selectedCountry.dialCode);

  void _syncController() {
    final TextEditingController? controller = widget.controller;
    if (controller != null && controller.text != _e164) controller.text = _e164;
  }

  void _emit() {
    _syncController();
    widget.onChanged?.call(
      UPhoneNumberData(
        countryCode: _selectedCountry.dialCode,
        phoneNumber: _e164,
        phoneWithoutCode: _national,
        countryName: _selectedCountry.nameEn,
        capital: _selectedCountry.capitalEn,
        continent: _selectedCountry.continentEn,
        primaryReligion: _selectedCountry.primaryReligionEn,
        currency: _selectedCountry.currency,
        primaryLanguage: _selectedCountry.primaryLanguageEn,
      ),
    );
  }

  void _setNational(String digits, UCountry country, {bool notify = true}) {
    final String limited = UPhoneNumberUtils.inputDigits(digits, countryCode: country.dialCode);
    final String formatted = UPhoneNumberUtils.formatNational(limited, countryCode: country.dialCode);
    _lastText = formatted;
    if (country.dialCode != _selectedCountry.dialCode) _selectedCountry = country;
    _phoneController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    if (notify && mounted) setState(() {});
  }

  void _onPhoneChanged() {
    final String raw = _phoneController.text;
    if (raw == _lastText) return;
    if (raw.startsWith("+") || raw.startsWith("00")) {
      final UCountry country = UPhoneNumberUtils.countryOf(raw) ?? _selectedCountry;
      _setNational(UPhoneNumberUtils.nationalNumber(raw, countryCode: country.dialCode), country);
      _emit();
      return;
    }
    _lastText = raw;
    if (mounted) setState(() {});
    _emit();
  }

  void _onControllerChanged() {
    final String external = widget.controller!.text;
    if (external == _e164) return;
    final UCountry country = UPhoneNumberUtils.countryOf(external) ?? _selectedCountry;
    _setNational(UPhoneNumberUtils.nationalNumber(external, countryCode: country.dialCode), country);
    _emit();
  }

  void _selectCountry(UCountry country) {
    _setNational(_national, country);
    _emit();
  }

  String? _validate(String? value) {
    if (widget.validator != null) return widget.validator!(value);
    if (_national.isEmpty) return widget.required ? U.s.required : null;
    return _isComplete ? null : U.s.invalidPhoneNumber;
  }

  Future<void> _openPicker() async {
    if (widget.readOnly) return;
    _searchController.clear();
    final Widget picker = _UCountryPicker(selected: _selectedCountry, searchController: _searchController);
    final UCountry? picked = widget.pickerMode == UCountryPickerMode.bottomSheet
        ? await UNavigator.bottomSheet<UCountry>(
            picker,
            showDragHandle: true,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          )
        : await UNavigator.dialog<UCountry>(
            Dialog(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: picker,
            ),
          );
    if (picked != null) _selectCountry(picked);
  }

  @override
  Widget build(BuildContext context) => UTextField(
    controller: _phoneController,
    focusNode: widget.focusNode,
    text: widget.text,
    labelText: widget.labelText,
    hintText: widget.hintText ?? UPhoneNumberUtils.placeholder(_selectedCountry.dialCode),
    required: widget.required,
    readOnly: widget.readOnly,
    validator: _validate,
    keyboardType: TextInputType.phone,
    formatters: <TextInputFormatter>[UPhoneInputFormatter(countryCode: _selectedCountry.dialCode)],
    autoFillHints: const <String>[AutofillHints.telephoneNumber],
    contentPadding: widget.contentPadding ?? const EdgeInsets.only(left: 4, right: 12, top: 14, bottom: 14),
    margin: widget.margin,
    visible: widget.visible,
    opacity: widget.opacity,
    fit: widget.fit,
    fitAlignment: widget.fitAlignment,
    scale: widget.scale,
    rotate: widget.rotate,
    translate: widget.translate,
    center: widget.center,
    safeArea: widget.safeArea,
    expanded: widget.expanded,
    flexible: widget.flexible,
    positioned: widget.positioned,
    left: widget.left,
    top: widget.top,
    right: widget.right,
    bottom: widget.bottom,
    positionedWidth: widget.positionedWidth,
    positionedHeight: widget.positionedHeight,
    suffix: AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder: (Widget child, Animation<double> animation) => ScaleTransition(scale: animation, child: child),
      child: _isComplete
          ? Icon(Icons.check_circle_rounded, key: const ValueKey<String>("valid"), size: 20, color: Theme.of(context).colorScheme.primary)
          : const SizedBox.shrink(key: ValueKey<String>("empty")),
    ),
    prefix: _CountrySelector(
      country: _selectedCountry,
      enabled: !widget.readOnly,
      onTap: _openPicker,
    ),
  ).ltr();
}

class _CountrySelector extends StatelessWidget {
  const _CountrySelector({required this.country, required this.enabled, required this.onTap});

  final UCountry country;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => UContainer(
    onTap: enabled ? onTap : null,
    splash: true,
    radius: 10,
    padding: const EdgeInsets.only(left: 10, right: 6, top: 6, bottom: 6),
    margin: const EdgeInsets.only(left: 4),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        UCountryFlag(country: country),
        const SizedBox(width: 6),
        UTextBodyMedium(country.dialCode, fontWeight: FontWeight.w600, textDirection: TextDirection.ltr),
        if (enabled) Icon(Icons.expand_more_rounded, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        SizedBox(
          height: 24,
          child: VerticalDivider(width: 1, thickness: 1, color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ],
    ),
  );
}

class UCountryFlag extends StatelessWidget {
  const UCountryFlag({required this.country, super.key, this.width = 26});

  final UCountry country;
  final double width;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(4),
    child: Image.asset(
      "packages/u/lib/assets/flags/${country.flag}",
      width: width,
      height: width * 0.72,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Icon(Icons.flag_outlined, size: width, color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

class _UCountryPicker extends StatefulWidget {
  const _UCountryPicker({required this.selected, required this.searchController});

  final UCountry selected;
  final TextEditingController searchController;

  @override
  State<_UCountryPicker> createState() => _UCountryPickerState();
}

class _UCountryPickerState extends UState<_UCountryPicker> {
  List<UCountry> _countries = UCountries.countries;

  void _filter(String query) {
    final String q = query.trim().toLowerCase();
    setState(
      () => _countries = q.isEmpty
          ? UCountries.countries
          : UCountries.countries
                .where(
                  (UCountry i) =>
                      i.nameEn.toLowerCase().contains(q) || i.nameFa.contains(query.trim()) || i.dialCode.contains(q) || i.isoCode.toLowerCase().contains(q) || i.capitalEn.toLowerCase().contains(q),
                )
                .toList(),
    );
  }

  @override
  Widget build(BuildContext context) => UContainer(
    constraints: const BoxConstraints(maxHeight: 620, maxWidth: 460),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        UTextTitleMedium(U.s.selectCountry, fontWeight: FontWeight.w600).pOnly(top: 16),
        UTextField(
          controller: widget.searchController,
          hintText: U.s.searchCountryCodeOrDialCode,
          prefix: const Icon(Icons.search_rounded, size: 20),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          onChanged: _filter,
        ),
        if (_countries.isEmpty)
          UTextBodyMedium(U.s.noItemsFound(U.s.country), color: scheme.onSurfaceVariant).pAll(32).expanded()
        else
          ListView.separated(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            itemCount: _countries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 2),
            itemBuilder: (BuildContext context, int index) {
              final UCountry country = _countries[index];
              final bool selected = country.dialCode == widget.selected.dialCode && country.isoCode == widget.selected.isoCode;
              return UContainer(
                onTap: () => Navigator.pop(context, country),
                splash: true,
                radius: 12,
                color: selected ? scheme.primaryContainer : null,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: <Widget>[
                    UCountryFlag(country: country, width: 30),
                    const SizedBox(width: 12),
                    UColumn(
                      expanded: 1,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        UTextBodyMedium(
                          isFa ? country.nameFa : country.nameEn,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        UTextBodySmall(isFa ? country.capitalFa : country.capitalEn, color: scheme.onSurfaceVariant, maxLines: 1),
                      ],
                    ),
                    const SizedBox(width: 8),
                    UTextBodyMedium(country.dialCode, color: scheme.onSurfaceVariant, textDirection: TextDirection.ltr),
                    if (selected) Icon(Icons.check_rounded, size: 18, color: scheme.primary).pOnly(left: 8, right: 8),
                  ],
                ),
              );
            },
          ).expanded(),
      ],
    ),
  );
}

enum UCountryPickerMode { dropdown, dialog, bottomSheet }

class UPhoneNumberData {
  final String countryCode;
  final String phoneNumber;
  final String phoneWithoutCode;
  final String countryName;
  final String capital;
  final String continent;
  final String primaryReligion;
  final String currency;
  final String primaryLanguage;

  UPhoneNumberData({
    required this.countryCode,
    required this.phoneNumber,
    required this.phoneWithoutCode,
    required this.countryName,
    required this.capital,
    required this.continent,
    required this.primaryReligion,
    required this.currency,
    required this.primaryLanguage,
  });
}
