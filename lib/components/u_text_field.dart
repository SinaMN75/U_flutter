import "package:u/components/persian_date_picker.dart";
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

  @override
  Widget build(final BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      if (widget.text != null)
        UIconTextHorizontal(
          leading: Text(widget.text!, style: Theme.of(context).textTheme.titleSmall),
          trailing: widget.required ? UTextBodyMedium("*", color: Theme.of(context).colorScheme.error) : const SizedBox(),
        ).pSymmetric(vertical: 8),
      TextFormField(
        autofillHints: widget.autoFillHints,
        textDirection: widget.keyboardType == TextInputType.number ? TextDirection.ltr : null,
        inputFormatters: widget.formatters,
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
          isDense: widget.isDense,
          helperStyle: const TextStyle(fontSize: 0),
          hintText: widget.hintText,
          contentPadding: widget.contentPadding ?? const EdgeInsets.fromLTRB(10, 0, 10, 0),
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
  );
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
  });

  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
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

  @override
  State<UDropDownField<T>> createState() => _UDropDownFieldState<T>();
}

class _UDropDownFieldState<T> extends State<UDropDownField<T>> {
  @override
  Widget build(BuildContext context) => Column(
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
        onChanged: widget.onChanged,
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
  });

  final Function(DateTime, Jalali) onChange;
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
    onTap: () async {
      if (!widget.readOnly) {
        if (widget.date) {
          if (widget.jalali) {
            await UNavigator.dialog(
              JalaliDatePickerDialog(
                startYear: widget.startYear ?? 1350,
                endYear: widget.endYear ?? 1420,
                initialDate: Jalali.now(),
                onDateSelected: (DateTime d, Jalali j) {
                  selectedDateTime = d;
                  setState(() {});
                  widget.onChange(selectedDateTime, j);
                },
              ),
            );
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
              final Jalali jalali = Jalali.fromDateTime(selectedDateTime);
              widget.onChange(selectedDateTime, jalali);
            }
          }

          if (widget.time) {
            final TimeOfDay? timeOfDay = await showTimePicker(
              context: context,
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
              final Jalali jalali = Jalali.fromDateTime(selectedDateTime);
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
  });

  final List<T> items;
  final String Function(T) labelBuilder;
  final void Function(T?) onChanged;
  final T selectedItem;
  final String? hintText;
  final String? title;

  @override
  State<UTextFieldAutoComplete<T>> createState() => _UTextFieldAutoCompleteState<T>();
}

class _UTextFieldAutoCompleteState<T> extends State<UTextFieldAutoComplete<T>> {
  late RxList<T> filteredItems = widget.items.obs;

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
                onChanged: (final String? i) => filteredItems(
                  widget.items.where((T item) => widget.labelBuilder(item).toLowerCase().contains(i!.toLowerCase())).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Obx(
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
  Widget build(BuildContext context) => widget.title == null
      ? _input()
      : UIconTextVertical(
          crossAxisAlignment: CrossAxisAlignment.start,
          leading: UTextBodySmall(widget.title ?? ""),
          trailing: _input(),
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
  });

  final String Function(T) labelBuilder;
  final void Function(T?) onChanged;
  final T? selectedItem;
  final String? hintText;
  final Duration debounceDuration;
  final Future<List<T>> Function(String query) fetchData;

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
  Widget build(BuildContext context) => InkWell(
    onTap: _openSearchDialog,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: widget.hintText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      child: _selectedItem == null ? const Text("___") : Text(widget.labelBuilder(_selectedItem as T)),
    ),
  );
}

class UTextFieldPhoneNumber extends StatefulWidget {
  final CountryPickerMode pickerMode;
  final Function(PhoneNumberData) onChanged;

  const UTextFieldPhoneNumber({
    required this.pickerMode,
    required this.onChanged,
    super.key,
  });

  @override
  _UTextFieldPhoneNumberState createState() => _UTextFieldPhoneNumberState();
}

class _UTextFieldPhoneNumberState extends State<UTextFieldPhoneNumber> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  UCountry _selectedCountry = UCountries.countries[0];
  List<UCountry> _filteredCountries = UCountries.countries;
  String _phoneNumber = "";

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onPhoneChanged() {
    setState(() {
      _phoneNumber = _phoneController.text;
      widget.onChanged(
        PhoneNumberData(
          countryCode: _selectedCountry.dialCode,
          phoneNumber: "${_selectedCountry.dialCode}$_phoneNumber",
          phoneWithoutCode: _phoneNumber,
          countryName: _selectedCountry.nameEn,
          capital: _selectedCountry.capitalEn,
          continent: _selectedCountry.continentEn,
          primaryReligion: _selectedCountry.primaryReligionEn,
          currency: _selectedCountry.currency,
          primaryLanguage: _selectedCountry.primaryLanguageEn,
        ),
      );
    });
  }

  void _showCountryPickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              Text(U.s.selectCountry),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: U.s.searchCountryCodeOrDialCode,
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _filterCountries,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredCountries.length,
                  itemBuilder: (BuildContext context, int index) {
                    final UCountry country = _filteredCountries[index];
                    return Card(
                      elevation: 0,
                      color: _selectedCountry == country ? Colors.blue[50] : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: Image.asset(
                          "packages/u/lib/assets/flags/${country.flag}",
                          width: 32,
                          height: 32,
                          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) => const Icon(Icons.flag, size: 32),
                        ),
                        title: Text(country.nameEn),
                        subtitle: Text("${country.dialCode} • ${country.capitalEn}"),
                        onTap: () {
                          setState(() {
                            _selectedCountry = country;
                            _onPhoneChanged();
                          });
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCountryPickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (BuildContext context, ScrollController scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(U.s.selectCountry),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: UTextField(
                  controller: _searchController,
                  hintText: U.s.searchCountryCodeOrDialCode,
                  prefix: Icon(Icons.search, color: Colors.grey[600]),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  onChanged: _filterCountries,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _filteredCountries.length,
                  itemBuilder: (BuildContext context, int index) {
                    final UCountry country = _filteredCountries[index];
                    return Card(
                      elevation: 0,
                      color: _selectedCountry == country ? Colors.blue[50] : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: Image.asset(
                          "packages/u/lib/assets/flags/${country.flag}",
                          width: 32,
                          height: 32,
                          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) => const Icon(Icons.flag, size: 32),
                        ),
                        title: Text(country.nameEn),
                        subtitle: Text("${country.dialCode} • ${country.capitalEn}"),
                        onTap: () {
                          setState(() {
                            _selectedCountry = country;
                            _onPhoneChanged();
                          });
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _filterCountries(String query) => setState(
    () => _filteredCountries = UCountries.countries
        .where(
          (UCountry i) =>
              i.nameEn.toLowerCase().contains(query.toLowerCase()) ||
              i.dialCode.contains(query) ||
              i.code.toLowerCase().contains(query.toLowerCase()) ||
              i.capitalEn.toLowerCase().contains(
                query.toLowerCase(),
              ),
        )
        .toList(),
  );

  @override
  Widget build(BuildContext context) => UTextField(
    controller: _phoneController,
    hintText: U.s.enterPhoneNumber,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    prefix: Builder(
      builder: (_) => widget.pickerMode == CountryPickerMode.dropdown
          ? DropdownButton<UCountry>(
              value: _selectedCountry,
              items: UCountries.countries
                  .map(
                    (UCountry i) => DropdownMenuItem<UCountry>(
                      value: i,
                      child: Row(
                        children: <Widget>[
                          Image.asset(
                            "packages/u/lib/assets/flags/${i.flag}",
                            width: 24,
                            height: 24,
                            errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) => const Icon(Icons.flag, size: 24),
                          ),
                          const SizedBox(width: 8),
                          Text(i.dialCode),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (UCountry? country) {
                if (country != null) {
                  setState(() {
                    _selectedCountry = country;
                    _onPhoneChanged();
                  });
                }
              },
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
            )
          : GestureDetector(
              onTap: widget.pickerMode == CountryPickerMode.dialog ? _showCountryPickerDialog : _showCountryPickerBottomSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Image.asset(
                      "packages/u/lib/assets/flags/${_selectedCountry.flag}",
                      width: 24,
                      height: 24,
                      errorBuilder: (_, __, ___) => const Icon(Icons.flag, size: 24),
                    ),
                    const SizedBox(width: 8),
                    Text(_selectedCountry.dialCode),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                  ],
                ),
              ),
            ),
    ),
  );
}

enum CountryPickerMode { dropdown, dialog, bottomSheet }

class PhoneNumberData {
  final String countryCode;
  final String phoneNumber;
  final String phoneWithoutCode;
  final String countryName;
  final String capital;
  final String continent;
  final String primaryReligion;
  final String currency;
  final String primaryLanguage;

  PhoneNumberData({
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
