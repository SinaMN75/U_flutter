part of "../../../u_admin.dart";

class UAdminHotelController extends UBaseController {
  List<UHotelResponse> list = <UHotelResponse>[];
  final TextEditingController titleFilter = TextEditingController();

  // ---------------------------------------------------------------- form (create and edit)

  /// The hotel being edited; null while creating.
  UHotelResponse? editing;
  late final TextEditingController title = fields.text();
  late final TextEditingController description = fields.text();
  late final TextEditingController stars = fields.text();
  late final TextEditingController address = fields.text();
  late final TextEditingController phone = fields.text();
  late final TextEditingController email = fields.text();
  late final TextEditingController checkInTime = fields.text();
  late final TextEditingController checkOutTime = fields.text();
  late final TextEditingController policies = fields.text();
  late final TextEditingController rules = fields.text();
  late final TextEditingController latitude = fields.text();
  late final TextEditingController longitude = fields.text();
  late final TextEditingController cancellationFreeHours = fields.text();
  late final TextEditingController cancellationPenaltyNights = fields.text();
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
    await UServices.hotel.readHotels(
      p: UHotelReadParams(pageNumber: pageNumber.value, pageSize: pageSize, title: titleFilter.valueOrNull()),
      onOk: (UResponse<List<UHotelResponse>> r) {
        list = r.result ?? <UHotelResponse>[];
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

  /// Fills the form: empty for [item] == null, otherwise with the full hotel (photos and admins included).
  Future<void> loadForm(UHotelResponse? item) async {
    final UHotelResponse? h = item == null
        ? null
        : (await UServices.hotel.readHotelById(
                p: UIdParams(
                  id: item.id,
                  selectorArgs: const UHotelSelectorArgs(media: UMediaSelectorArgs()),
                ),
              )).$1?.result ??
              item;
    final UHotelJson? d = h?.jsonData;
    editing = h;
    title.text = h?.title ?? "";
    description.text = d?.description ?? d?.detail1 ?? "";
    stars.text = h?.stars.toString() ?? "";
    address.text = h?.address ?? "";
    phone.text = h?.phoneNumber ?? "";
    email.text = h?.email ?? "";
    checkInTime.text = d?.checkInTime ?? "";
    checkOutTime.text = d?.checkOutTime ?? "";
    policies.text = d?.policies ?? "";
    rules.text = d?.rules.join(", ") ?? "";
    latitude.text = d?.latitude?.toString() ?? "";
    longitude.text = d?.longitude?.toString() ?? "";
    cancellationFreeHours.text = (d?.cancellationFreeHours ?? 24).toString();
    cancellationPenaltyNights.text = (d?.cancellationPenaltyNights ?? 1).toString();
    website.text = d?.website ?? "";
    whatsapp.text = d?.whatsapp ?? "";
    instagram.text = d?.instagram ?? "";
    telegram.text = d?.telegram ?? "";
    howToGetThere.text = d?.howToGetThere ?? "";
    cityCode = h?.cityCode ?? UCountries.iran().provinces.first.cities.firstOrNull?.code ?? "";
    tags = List<int>.from(h?.tags ?? <int>[TagHotel.hotel.number, TagHotel.active.number]);
    highlights = List<String>.from(d?.highlights ?? <String>[]);
    nearby = List<UPlaceNearby>.from(d?.nearby ?? <UPlaceNearby>[]);
    faqs = List<UPlaceFaq>.from(d?.faqs ?? <UPlaceFaq>[]);
    media = (h?.media ?? <UMediaResponse>[]).sortedForGallery();
    photos.dispose();
    photos = UFilePickerController.fromMedia(media);
    admins = await readUsersById(h?.adminUserIds ?? <String>[]);
  }

  /// Creates or updates the hotel, then saves its photos. Returns true when the dialog can close.
  Future<bool> save() async {
    final bool isNew = editing == null;
    // On edit an empty text is sent as "" so a field can be cleared; on create it is simply left out.
    String? t(TextEditingController c) => isNew ? c.text.trim().nullIfEmpty() : c.text.trim();
    final UHotelUpdateParams p = UHotelUpdateParams(
      id: editing?.id ?? "",
      tags: tags,
      title: title.text.trim(),
      cityCode: cityCode,
      stars: intOf(stars),
      address: t(address),
      phoneNumber: phone.text.nullIfEmpty(),
      email: email.text.nullIfEmpty(),
      description: t(description),
      policies: t(policies),
      checkInTime: t(checkInTime),
      checkOutTime: t(checkOutTime),
      rules: splitList(rules.text),
      latitude: numOf(latitude),
      longitude: numOf(longitude),
      cancellationFreeHours: intOf(cancellationFreeHours),
      cancellationPenaltyNights: intOf(cancellationPenaltyNights),
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
      isNew ? UServices.hotel.createHotel(p: UHotelCreateParams.fromMap(p.toMap()..remove("id"))) : UServices.hotel.updateHotel(p: p),
      () {},
    );
    if (ok == null) return false;
    await UServices.media.syncGallery(photos, existing: media, hotelId: editing?.id ?? ok.result);
    unawaited(read());
    return true;
  }

  /// Quick switch from the list: turns [tag] on or off; [opposite] is swapped the other way (active ↔ inactive).
  void setTag(UHotelResponse i, TagHotel tag, bool on, {TagHotel? opposite}) => submit(
    UServices.hotel.updateHotel(
      p: UHotelUpdateParams(
        id: i.id,
        addTags: <int>[if (on) tag.number else ?opposite?.number],
        removeTags: <int>[if (on) ?opposite?.number else tag.number],
      ),
    ),
    read,
  );

  void delete(UHotelResponse i) => confirmAction(() => UServices.hotel.deleteHotel(p: UIdParams(id: i.id)), read);

  @override
  void dispose() {
    titleFilter.dispose();
    photos.dispose();
    super.dispose();
  }
}
