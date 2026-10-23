import "package:u/utilities.dart";

/// Country → province → city drop-downs (Iran data built in). `UCountryProvincePicker(onCityChanged: (c) => city = c)`
class UCountryProvincePicker extends StatefulWidget {
  const UCountryProvincePicker({
    super.key,
    this.initialCountry,
    this.initialProvince,
    this.initialCity,
    this.onCountryChanged,
    this.onProvinceChanged,
    this.onCityChanged,
    this.spacing = 6,
  });

  /// Country selected at start.
  final UCountry? initialCountry;

  /// Province selected at start.
  final UProvince? initialProvince;

  /// City selected at start.
  final UCity? initialCity;

  /// Called with the chosen country.
  final void Function(UCountry country)? onCountryChanged;

  /// Called with the chosen province.
  final void Function(UProvince province)? onProvinceChanged;

  /// Called with the chosen city.
  final void Function(UCity? city)? onCityChanged;

  /// Gap between items.
  final double spacing;

  @override
  State<UCountryProvincePicker> createState() => _UCountryProvincePickerState();
}

class _UCountryProvincePickerState extends State<UCountryProvincePicker> {
  late final URx<UCountry> country = (widget.initialCountry ?? UCountries.iran()).obs;
  late final URxList<UProvince> provinces = country.value.provinces.obs;
  late final URxList<UCity> cities = province.value.cities.obs;
  late final URx<UProvince> province = (widget.initialProvince ?? country.value.provinces.first).obs;
  late final URxn<UCity?> city = URxn<UCity>(widget.initialCity ?? province.value.cities.firstOrNull);

  void _selectCountry(UCountry? i) {
    if (i == null) return;
    country(i);
    provinces(i.provinces);
    cities(i.provinces.first.cities);
    province(i.provinces.first);
    city(i.provinces.first.cities.firstOrNull);
    widget.onCountryChanged?.call(i);
    widget.onProvinceChanged?.call(i.provinces.first);
    widget.onCityChanged?.call(i.provinces.first.cities.firstOrNull);
    if (mounted) setState(() {});
  }

  void _selectProvince(UProvince? i) {
    if (i == null) return;
    province(i);
    city(i.cities.firstOrNull);
    cities(i.cities);
    widget.onProvinceChanged?.call(i);
    // Province change resets the city, so notify the parent (matches _selectCountry).
    widget.onCityChanged?.call(i.cities.firstOrNull);
    if (mounted) setState(() {});
  }

  void _selectCity(UCity? i) {
    if (i == null) return;
    city(i);
    widget.onCityChanged?.call(i);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      UObx(
        () => UTextFieldAutoComplete<UCountry>(
          items: UCountries.countries,
          labelBuilder: (UCountry i) => i.nameFa,
          onChanged: _selectCountry,
          selectedItem: country.value,
        ),
      ).pSymmetric(vertical: widget.spacing),
      UObx(
        () => UTextFieldAutoComplete<UProvince>(
          items: provinces,
          labelBuilder: (UProvince i) => i.nameFa,
          onChanged: _selectProvince,
          selectedItem: province.value,
        ),
      ).pSymmetric(vertical: widget.spacing),
      UObx(
        () {
          if (cities.isNotNullOrEmpty()) {
            return UTextFieldAutoComplete<UCity>(
              items: cities,
              labelBuilder: (UCity i) => i.nameFa,
              onChanged: _selectCity,
              selectedItem: city.value!,
            );
          }
          return const SizedBox.shrink();
        },
      ).pSymmetric(vertical: widget.spacing),
    ],
  );
}
