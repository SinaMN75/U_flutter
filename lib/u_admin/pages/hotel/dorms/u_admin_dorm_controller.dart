part of "../../../u_admin.dart";

class UAdminDormController extends UBaseController {
  List<UDormResponse> list = <UDormResponse>[];
  final TextEditingController titleFilter = TextEditingController();

  // ---------------------------------------------------------------- form (create and edit)

  /// The dorm being edited; null while creating.
  UDormResponse? editing;
  late final TextEditingController title = fields.text();
  late final TextEditingController description = fields.text();
  late final TextEditingController address = fields.text();
  late final TextEditingController phone = fields.text();
  late final TextEditingController nearbyUniversity = fields.text();
  late final TextEditingController universityWalkMinutes = fields.text();
  late final TextEditingController visitingHours = fields.text();
  late final TextEditingController curfewTime = fields.text();
  late final TextEditingController minimumStayMonths = fields.text();
  late final TextEditingController policies = fields.text();
  late final TextEditingController rules = fields.text();
  late final TextEditingController requiredDocuments = fields.text();
  late final TextEditingController latitude = fields.text();
  late final TextEditingController longitude = fields.text();
  late final TextEditingController website = fields.text();
  late final TextEditingController whatsapp = fields.text();
  late final TextEditingController instagram = fields.text();
  late final TextEditingController telegram = fields.text();
  late final TextEditingController howToGetThere = fields.text();
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
        title: titleFilter.valueOrNull(),
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
    titleFilter.clear();
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
    title.text = h?.title ?? "";
    description.text = d?.description ?? "";
    address.text = h?.address ?? "";
    phone.text = h?.phoneNumber ?? "";
    nearbyUniversity.text = d?.nearbyUniversity ?? "";
    universityWalkMinutes.text = d?.universityWalkMinutes?.toString() ?? "";
    visitingHours.text = d?.visitingHours ?? "";
    curfewTime.text = d?.curfewTime ?? "";
    minimumStayMonths.text = d?.minimumStayMonths?.toString() ?? "";
    policies.text = d?.policies ?? "";
    rules.text = d?.rules.join("، ") ?? "";
    requiredDocuments.text = d?.requiredDocuments.join("، ") ?? "";
    latitude.text = d?.latitude?.toString() ?? "";
    longitude.text = d?.longitude?.toString() ?? "";
    website.text = d?.website ?? "";
    whatsapp.text = d?.whatsapp ?? "";
    instagram.text = d?.instagram ?? "";
    telegram.text = d?.telegram ?? "";
    howToGetThere.text = d?.howToGetThere ?? "";
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
      title: title.text.trim(),
      cityCode: cityCode,
      address: t(address),
      phoneNumber: phone.text.nullIfEmpty(),
      description: t(description),
      nearbyUniversity: t(nearbyUniversity),
      universityWalkMinutes: intOf(universityWalkMinutes),
      visitingHours: t(visitingHours),
      curfewTime: t(curfewTime),
      minimumStayMonths: intOf(minimumStayMonths),
      policies: t(policies),
      rules: splitList(rules.text),
      requiredDocuments: splitList(requiredDocuments.text),
      latitude: numOf(latitude),
      longitude: numOf(longitude),
      adminUserIds: admins.map((UUserResponse u) => u.id).toList(),
      highlights: highlights,
      website: t(website),
      whatsapp: t(whatsapp),
      instagram: t(instagram),
      telegram: t(telegram),
      howToGetThere: t(howToGetThere),
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
    titleFilter.dispose();
    photos.dispose();
    super.dispose();
  }
}
