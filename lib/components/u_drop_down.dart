import "package:u/utilities.dart";

class UCategorySelector extends StatefulWidget {
  const UCategorySelector({
    required this.onCategorySelected,
    required this.onSubCategorySelected,
    this.hint1,
    this.hint2,
    this.category,
    this.subCategory,
    super.key,
  });

  final String? hint1;
  final String? hint2;
  final Function(UCategoryResponse? category) onCategorySelected;
  final Function(UCategoryResponse? subCategory) onSubCategorySelected;

  final UCategoryResponse? category;
  final UCategoryResponse? subCategory;

  @override
  State<UCategorySelector> createState() => _UCategorySelectorState();
}

class _UCategorySelectorState extends State<UCategorySelector> {
  final RxState pageState = RxState();

  final RxList<UCategoryResponse> categories = <UCategoryResponse>[].obs;
  final RxList<UCategoryResponse> subCategories = <UCategoryResponse>[].obs;

  final Rxn<UCategoryResponse> selectedCategory = Rxn<UCategoryResponse>();
  final Rxn<UCategoryResponse> selectedSubCategory = Rxn<UCategoryResponse>();

  final UCategoryResponse nullCategory = UCategoryResponse(
    id: "___",
    createdAt: DateTime.now(),
    jsonData: UCategoryJson(),
    tags: <int>[],
    title: "___",
    adminUserIds: <String>[],
  );

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    pageState.loading();
    UServices.category.read(
      p: UCategoryReadParams(
        tags: <int>[TagCategory.dorm.number],
        selectorArgs: const CategorySelectorArgs(
          children: CategorySelectorArgs(),
          childrenDebt: 2,
        ),
      ),
      onOk: (UResponse<List<UCategoryResponse>> res) {
        if (res.result.isNullOrEmpty()) {
          pageState.loaded();
          return;
        }

        categories.assignAll(res.result!);
        categories.insert(0, nullCategory);
        _selectCategory(categories.first);
        pageState.loaded();
        if (widget.category != null) {
          selectedCategory(widget.category);
          subCategories.assignAll(widget.category!.children ?? <UCategoryResponse>[]);
        }
        if (widget.subCategory != null) {
          selectedSubCategory(widget.subCategory);
        }
      },
      onError: (UEmptyResponse res) {
        pageState.error();
        UToast.snackBar(message: res.message);
      },
      onException: (String msg) {
        pageState.error();
        UToast.snackBar(message: msg);
      },
    );
  }

  void _selectCategory(UCategoryResponse category) {
    if (category.id == "___") {
      selectedCategory(category);
      selectedSubCategory(null);
      widget.onCategorySelected(null);
      _selectSubCategory(null);
      return;
    }
    selectedCategory(category);
    widget.onCategorySelected(category);

    final List<UCategoryResponse> children = category.children ?? <UCategoryResponse>[];
    subCategories.assignAll(children);
    subCategories.insert(0, nullCategory);

    if (children.isNotEmpty) {
      _selectSubCategory(children.first);
    } else {
      selectedSubCategory.value = null;
      _selectSubCategory(null);
    }
  }

  void _selectSubCategory(UCategoryResponse? subCategory) {
    selectedSubCategory.value = subCategory;
    widget.onSubCategorySelected(subCategory);
  }

  @override
  Widget build(BuildContext context) => Obx(
    () {
      if (pageState.isLoading()) {
        return const CircularProgressIndicator().alignAtCenter();
      }

      // No category selected yet (empty result or load error) — avoid the null-check crash on selectedCategory.value!.
      if (selectedCategory.value == null) {
        return const SizedBox.shrink();
      }

      return Column(
        children: <Widget>[
          UTextFieldAutoComplete<UCategoryResponse>(
            hintText: widget.hint1,
            selectedItem: selectedCategory.value!,
            items: categories,
            labelBuilder: (UCategoryResponse i) => i.title,
            onChanged: (UCategoryResponse? i) {
              if (i != null) {
                _selectCategory(i);
              }
            },
          ).pSymmetric(vertical: 4),
          if (subCategories.isNotEmpty && selectedSubCategory.value != null)
            UTextFieldAutoComplete<UCategoryResponse>(
              hintText: widget.hint2,
              selectedItem: selectedSubCategory.value!,
              items: subCategories,
              labelBuilder: (UCategoryResponse i) => i.title,
              onChanged: (UCategoryResponse? i) {
                if (i != null) {
                  _selectSubCategory(i);
                }
              },
            ).pSymmetric(vertical: 4),
        ],
      );
    },
  );
}

class UCountryProvincePicker extends StatefulWidget {
  const UCountryProvincePicker({
    super.key,
    this.initialCountry,
    this.initialProvince,
    this.onCountryChanged,
    this.onProvinceChanged,
    this.onCityChanged,
    this.spacing = 6,
  });

  final UCountry? initialCountry;
  final UProvince? initialProvince;
  final void Function(UCountry country)? onCountryChanged;
  final void Function(UProvince province)? onProvinceChanged;
  final void Function(UCity? city)? onCityChanged;
  final double spacing;

  @override
  State<UCountryProvincePicker> createState() => _UCountryProvincePickerState();
}

class _UCountryProvincePickerState extends State<UCountryProvincePicker> {
  late final Rx<UCountry> country = (widget.initialCountry ?? UCountries.iran()).obs;
  late final RxList<UProvince> provinces = country.value.provinces.obs;
  late final RxList<UCity> cities = province.value.cities.obs;
  late final Rx<UProvince> province = (widget.initialProvince ?? country.value.provinces.first).obs;
  late final Rxn<UCity?> city = Rxn<UCity>(province.value.cities.firstOrNull);

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
      Obx(
        () => UTextFieldAutoComplete<UCountry>(
          items: UCountries.countries,
          labelBuilder: (UCountry i) => i.nameFa,
          onChanged: _selectCountry,
          selectedItem: country.value,
        ),
      ).pSymmetric(vertical: widget.spacing),
      Obx(
        () => UTextFieldAutoComplete<UProvince>(
          items: provinces,
          labelBuilder: (UProvince i) => i.nameFa,
          onChanged: _selectProvince,
          selectedItem: province.value,
        ),
      ).pSymmetric(vertical: widget.spacing),
      Obx(
        () {
          if (cities.isNotNullOrEmpty())
            return UTextFieldAutoComplete<UCity>(
              items: cities,
              labelBuilder: (UCity i) => i.nameFa,
              onChanged: _selectCity,
              selectedItem: city.value!,
            );
          return const SizedBox.shrink();
        },
      ).pSymmetric(vertical: widget.spacing),
    ],
  );
}
