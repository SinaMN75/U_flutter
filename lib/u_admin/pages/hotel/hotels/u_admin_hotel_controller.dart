part of "../../../u_admin.dart";

class UAdminHotelController extends UBaseController {
  List<UHotelResponse> list = <UHotelResponse>[];
  final TextEditingController titleFilterController = TextEditingController();

  UHotelResponse? editing;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController starsController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController checkInTimeController = TextEditingController();
  final TextEditingController checkOutTimeController = TextEditingController();
  final TextEditingController policiesController = TextEditingController();
  final TextEditingController rulesController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();
  final TextEditingController cancellationFreeHoursController = TextEditingController();
  final TextEditingController cancellationPenaltyNightsController = TextEditingController();
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
    await UServices.hotel.readHotels(
      p: UHotelReadParams(pageNumber: pageNumber.value, pageSize: pageSize, title: titleFilterController.valueOrNull()),
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
    titleFilterController.clear();
    reloadFirstPage(read);
  }

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
    titleController.text = h?.title ?? "";
    descriptionController.text = d?.description ?? d?.detail1 ?? "";
    starsController.text = h?.stars.toString() ?? "";
    addressController.text = h?.address ?? "";
    phoneController.text = h?.phoneNumber ?? "";
    emailController.text = h?.email ?? "";
    checkInTimeController.text = d?.checkInTime ?? "";
    checkOutTimeController.text = d?.checkOutTime ?? "";
    policiesController.text = d?.policies ?? "";
    rulesController.text = d?.rules.join(", ") ?? "";
    latitudeController.text = d?.latitude?.toString() ?? "";
    longitudeController.text = d?.longitude?.toString() ?? "";
    cancellationFreeHoursController.text = (d?.cancellationFreeHours ?? 24).toString();
    cancellationPenaltyNightsController.text = (d?.cancellationPenaltyNights ?? 1).toString();
    websiteController.text = d?.website ?? "";
    whatsappController.text = d?.whatsapp ?? "";
    instagramController.text = d?.instagram ?? "";
    telegramController.text = d?.telegram ?? "";
    howToGetThereController.text = d?.howToGetThere ?? "";
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

  Future<bool> save() async {
    final bool isNew = editing == null;
    String? t(TextEditingController c) => isNew ? c.text.trim().nullIfEmpty() : c.text.trim();
    final UHotelUpdateParams p = UHotelUpdateParams(
      id: editing?.id ?? "",
      tags: tags,
      title: titleController.text.trim(),
      cityCode: cityCode,
      stars: intOf(starsController),
      address: t(addressController),
      phoneNumber: phoneController.text.nullIfEmpty(),
      email: emailController.text.nullIfEmpty(),
      description: t(descriptionController),
      policies: t(policiesController),
      checkInTime: t(checkInTimeController),
      checkOutTime: t(checkOutTimeController),
      rules: splitList(rulesController.text),
      latitude: numOf(latitudeController),
      longitude: numOf(longitudeController),
      cancellationFreeHours: intOf(cancellationFreeHoursController),
      cancellationPenaltyNights: intOf(cancellationPenaltyNightsController),
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
      isNew ? UServices.hotel.createHotel(p: UHotelCreateParams.fromMap(p.toMap()..remove("id"))) : UServices.hotel.updateHotel(p: p),
      () {},
    );
    if (ok == null) return false;
    await UServices.media.syncGallery(photos, existing: media, hotelId: editing?.id ?? ok.result);
    unawaited(read());
    return true;
  }

  void setTag(UHotelResponse i, TagHotel tag, bool on, {TagHotel? opposite}) => submit(
    UServices.hotel.updateHotel(
      p: UHotelUpdateParams(
        id: i.id,
        addTags: <int>[if (on) tag.number else ?opposite?.number],
        removeTags: <int>[if (on) ?opposite?.number else tag.number],
      ),
    ),
    null,
  );

  void delete(UHotelResponse i) => confirmAction(() => UServices.hotel.deleteHotel(p: UIdParams(id: i.id)), read);

  @override
  void dispose() {
    titleFilterController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    starsController.dispose();
    addressController.dispose();
    phoneController.dispose();
    emailController.dispose();
    checkInTimeController.dispose();
    checkOutTimeController.dispose();
    policiesController.dispose();
    rulesController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    cancellationFreeHoursController.dispose();
    cancellationPenaltyNightsController.dispose();
    websiteController.dispose();
    whatsappController.dispose();
    instagramController.dispose();
    telegramController.dispose();
    howToGetThereController.dispose();
    photos.dispose();
    super.dispose();
  }
}
