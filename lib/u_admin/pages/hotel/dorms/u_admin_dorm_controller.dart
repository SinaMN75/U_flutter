part of "../../../u_admin.dart";

class UAdminDormController extends UBaseController {
  List<UDormResponse> list = <UDormResponse>[];
  final TextEditingController titleFilterController = TextEditingController();

  // ---------------------------------------------------------------- form (create and edit)

  /// The dorm being edited; null while creating.
  UDormResponse? editing;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController nearbyUniversityController = TextEditingController();
  final TextEditingController universityWalkMinutesController = TextEditingController();
  final TextEditingController visitingHoursController = TextEditingController();
  final TextEditingController curfewTimeController = TextEditingController();
  final TextEditingController minimumStayMonthsController = TextEditingController();
  final TextEditingController policiesController = TextEditingController();
  final TextEditingController rulesController = TextEditingController();
  final TextEditingController requiredDocumentsController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController whatsappController = TextEditingController();
  final TextEditingController instagramController = TextEditingController();
  final TextEditingController telegramController = TextEditingController();
  final TextEditingController howToGetThereController = TextEditingController();
  String cityCode = "";
  List<int> tags = <int>[];
  List<String> highlights = <String>[];
  List<UPlaceNearby> nearby = <UPlaceNearby>[];
  List<UPlaceFaq> faqs = <UPlaceFaq>[];
  List<UUserResponse> admins = <UUserResponse>[];
  List<UMediaResponse> media = <UMediaResponse>[];
  UFilePickerController photos = UFilePickerController();

  void init() => read();

  Future<void> read() async {
    state.loading();
    await UServices.hotel.readDorms(
      p: UDormReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        title: titleFilterController.valueOrNull(),
        selectorArgs: const UDormSelectorArgs(rooms: UDormRoomSelectorArgs()),
      ),
      onOk: (UResponse<List<UDormResponse>> r) {
        list = r.result ?? <UDormResponse>[];
        setTotalPages(r.totalCount);
        setListState(isEmpty: list.isEmpty);
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: (String e) => setError(),
    );
  }

  void applyFilters() => reloadFirstPage(read);

  void clearFilters() {
    titleFilterController.clear();
    reloadFirstPage(read);
  }

  /// Fills the form: empty for [item] == null, otherwise with the full dorm (photos and admins included).
  Future<void> loadForm(UDormResponse? item) async {
    final UDormResponse? h = item == null
        ? null
        : (await UServices.hotel.readDormById(
                p: UIdParams(
                  id: item.id,
                  selectorArgs: const UDormSelectorArgs(media: UMediaSelectorArgs()),
                ),
              )).$1?.result ??
              item;
    final UDormJson? d = h?.jsonData;
    editing = h;
    titleController.text = h?.title ?? "";
    descriptionController.text = d?.description ?? "";
    addressController.text = h?.address ?? "";
    phoneController.text = h?.phoneNumber ?? "";
    nearbyUniversityController.text = d?.nearbyUniversity ?? "";
    universityWalkMinutesController.text = d?.universityWalkMinutes?.toString() ?? "";
    visitingHoursController.text = d?.visitingHours ?? "";
    curfewTimeController.text = d?.curfewTime ?? "";
    minimumStayMonthsController.text = d?.minimumStayMonths?.toString() ?? "";
    policiesController.text = d?.policies ?? "";
    rulesController.text = d?.rules.join("، ") ?? "";
    requiredDocumentsController.text = d?.requiredDocuments.join("، ") ?? "";
    latitudeController.text = d?.latitude?.toString() ?? "";
    longitudeController.text = d?.longitude?.toString() ?? "";
    websiteController.text = d?.website ?? "";
    whatsappController.text = d?.whatsapp ?? "";
    instagramController.text = d?.instagram ?? "";
    telegramController.text = d?.telegram ?? "";
    howToGetThereController.text = d?.howToGetThere ?? "";
    cityCode = h?.cityCode ?? UCountries.iran().provinces.first.cities.firstOrNull?.code ?? "";
    tags = List<int>.from(h?.tags ?? <int>[TagDorm.girls.number, TagDorm.active.number]);
    highlights = List<String>.from(d?.highlights ?? <String>[]);
    nearby = List<UPlaceNearby>.from(d?.nearby ?? <UPlaceNearby>[]);
    faqs = List<UPlaceFaq>.from(d?.faqs ?? <UPlaceFaq>[]);
    media = (h?.media ?? <UMediaResponse>[]).sortedForGallery();
    photos.dispose();
    photos = UFilePickerController.fromMedia(media);
    admins = await readUsersById(h?.adminUserIds ?? <String>[]);
  }

  /// Creates or updates the dorm, then saves its photos. Returns true when the dialog can close.
  Future<bool> save() async {
    final bool isNew = editing == null;
    // On edit an empty text is sent as "" so a field can be cleared; on create it is simply left out.
    String? t(TextEditingController c) => isNew ? c.text.trim().nullIfEmpty() : c.text.trim();
    final UDormUpdateParams p = UDormUpdateParams(
      id: editing?.id ?? "",
      tags: tags,
      title: titleController.text.trim(),
      cityCode: cityCode,
      address: t(addressController),
      phoneNumber: phoneController.text.nullIfEmpty(),
      description: t(descriptionController),
      nearbyUniversity: t(nearbyUniversityController),
      universityWalkMinutes: intOf(universityWalkMinutesController),
      visitingHours: t(visitingHoursController),
      curfewTime: t(curfewTimeController),
      minimumStayMonths: intOf(minimumStayMonthsController),
      policies: t(policiesController),
      rules: splitList(rulesController.text),
      requiredDocuments: splitList(requiredDocumentsController.text),
      latitude: numOf(latitudeController),
      longitude: numOf(longitudeController),
      adminUserIds: admins.map((UUserResponse u) => u.id).toList(),
      highlights: highlights,
      website: t(websiteController),
      whatsapp: t(whatsappController),
      instagram: t(instagramController),
      telegram: t(telegramController),
      howToGetThere: t(howToGetThereController),
      nearby: nearby,
      faqs: faqs,
    );
    final dynamic ok = await submit(
      isNew ? UServices.hotel.createDorm(p: UDormCreateParams.fromMap(p.toMap()..remove("id"))) : UServices.hotel.updateDorm(p: p),
      () {},
    );
    if (ok == null) return false;
    await UServices.media.syncGallery(photos, existing: media, dormId: editing?.id ?? ok.result);
    unawaited(read());
    return true;
  }

  /// Quick switch from the list: turns [tag] on or off; [opposite] is swapped the other way (active ↔ inactive).
  void setTag(UDormResponse i, TagDorm tag, bool on, {TagDorm? opposite}) => submit(
    UServices.hotel.updateDorm(
      p: UDormUpdateParams(
        id: i.id,
        addTags: <int>[if (on) tag.number else ?opposite?.number],
        removeTags: <int>[if (on) ?opposite?.number else tag.number],
      ),
    ),
    read,
  );

  void delete(UDormResponse i) => confirmAction(() => UServices.hotel.deleteDorm(p: UIdParams(id: i.id)), read);

  @override
  void dispose() {
    titleFilterController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    phoneController.dispose();
    nearbyUniversityController.dispose();
    universityWalkMinutesController.dispose();
    visitingHoursController.dispose();
    curfewTimeController.dispose();
    minimumStayMonthsController.dispose();
    policiesController.dispose();
    rulesController.dispose();
    requiredDocumentsController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    websiteController.dispose();
    whatsappController.dispose();
    instagramController.dispose();
    telegramController.dispose();
    howToGetThereController.dispose();
    photos.dispose();
    super.dispose();
  }
}
