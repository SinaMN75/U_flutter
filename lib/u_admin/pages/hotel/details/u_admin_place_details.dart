part of "../../../u_admin.dart";

// "Details & photos" editors of hotels, hotel rooms, dorms, dorm rooms and dorm beds.
// Each one opens a dialog with the rich details (highlights, amenities, policies, nearby places, FAQs...) and the photo manager.
// Saving writes the details with the normal update endpoint and then applies the photo changes.

abstract class UAdminPlaceDetails {
  // ---------------------------------------------------------------- shared helpers

  static Widget _text(TextEditingController c, String label, {int lines = 1, bool number = false}) => UTextField(
    controller: c,
    labelText: label,
    lines: lines,
    keyboardType: number ? TextInputType.number : TextInputType.text,
    margin: const EdgeInsets.symmetric(vertical: 6),
  );

  static int? _int(TextEditingController c) => int.tryParse(c.text.toLatinNumber().trim());

  static String? _str(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  /// A row of on/off chips (featured, verified, hidden...).
  static Widget _flags(List<(String, bool, ValueChanged<bool>)> flags) => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: flags.map(((String, bool, ValueChanged<bool>) f) => FilterChip(label: Text(f.$1), selected: f.$2, onSelected: f.$3)).toList(),
  );

  /// Opens the dialog. [body] draws the fields, [save] returns true when the update succeeded.
  static Future<void> _open({
    required String title,
    required Widget Function(BuildContext context, StateSetter setState) body,
    required Future<bool> Function() save,
    VoidCallback? onDone,
  }) async {
    bool saving = false;
    await UNavigator.dialog(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) => AlertDialog(
          title: Text(title),
          content: SizedBox(width: context.dialogWidth(max: 760), child: SingleChildScrollView(child: body(context, setState))),
          actions: <Widget>[
            TextButton(onPressed: saving ? null : UNavigator.back, child: Text(U.s.cancel)),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      setState(() => saving = true);
                      final bool ok = await save();
                      if (!context.mounted) return;
                      if (ok) {
                        UNavigator.back();
                        UToast.success(message: U.s.detailsSaved);
                        onDone?.call();
                      } else {
                        setState(() => saving = false);
                      }
                    },
              child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(U.s.save),
            ),
          ],
        ),
      ),
    );
  }

  static bool _isOk(UEmptyResponse? ok, UEmptyResponse? error, String? exception) {
    if (ok != null) return true;
    UToast.error(message: error?.message ?? exception ?? U.s.errorSubmittingForm);
    return false;
  }

  // ---------------------------------------------------------------- hotel

  static Future<void> hotel(UHotelResponse item, {VoidCallback? onDone}) async {
    final (UResponse<UHotelResponse>? fetched, _, _) = await UServices.hotel.readHotelById(p: UIdParams(id: item.id, selectorArgs: const HotelSelectorArgs(media: MediaSelectorArgs())));
    final UHotelResponse h = fetched?.result ?? item;
    final UHotelJson d = h.jsonData;

    String? type = d.type;
    List<String> highlights = List<String>.from(d.highlights);
    List<String> amenities = List<String>.from(h.jsonData.amenities);
    List<String> languages = List<String>.from(d.languages);
    List<String> mealPlans = List<String>.from(d.mealPlans);
    List<String> paymentMethods = List<String>.from(d.paymentMethods);
    List<UPlaceNearby> nearby = List<UPlaceNearby>.from(d.nearby);
    List<UPlaceFaq> faqs = List<UPlaceFaq>.from(d.faqs);
    bool? pets = d.petsAllowed;
    bool? smoking = d.smokingAllowed;
    bool? children = d.childrenAllowed;
    bool? extraBed = d.extraBedAvailable;
    bool? includesTax = d.priceIncludesTax;
    bool featured = h.tags.contains(TagHotel.featured.number);
    bool verified = h.tags.contains(TagHotel.verified.number);
    final TextEditingController website = TextEditingController(text: d.website);
    final TextEditingController whatsapp = TextEditingController(text: d.whatsapp);
    final TextEditingController instagram = TextEditingController(text: d.instagram);
    final TextEditingController telegram = TextEditingController(text: d.telegram);
    final TextEditingController yearBuilt = TextEditingController(text: d.yearBuilt?.toString());
    final TextEditingController yearRenovated = TextEditingController(text: d.yearRenovated?.toString());
    final TextEditingController floorCount = TextEditingController(text: d.floorCount?.toString());
    final TextEditingController childrenPolicy = TextEditingController(text: d.childrenPolicy);
    final TextEditingController howToGetThere = TextEditingController(text: d.howToGetThere);
    final UAdminMediaDraft draft = UAdminMediaDraft();
    final List<UMediaResponse> media = (h.media ?? <UMediaResponse>[]).sortedForGallery();

    await _open(
      title: "${U.s.detailsAndPhotos} — ${h.title}",
      onDone: onDone,
      body: (BuildContext context, StateSetter setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          UAdminSection(
            title: U.s.visibility,
            children: <Widget>[
              _flags(<(String, bool, ValueChanged<bool>)>[
                (U.s.featured, featured, (bool v) => setState(() => featured = v)),
                (U.s.verifiedOnSite, verified, (bool v) => setState(() => verified = v)),
              ]),
            ],
          ),
          UAdminSection(title: U.s.photos, children: <Widget>[UAdminMediaManager(media: media, draft: draft)]),
          UAdminSection(
            title: U.s.details,
            children: <Widget>[
              UAdminSingleChoice(title: U.s.propertyType, options: UPlaceCatalog.hotelTypes, selected: type, onChanged: (String? v) => type = v),
              UAdminStringList(title: U.s.highlights, items: highlights, addLabel: U.s.addHighlight, onChanged: (List<String> v) => highlights = v),
              URow(children: <Widget>[UTextField(expanded: 1, controller: yearBuilt, labelText: U.s.yearBuilt, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)), const SizedBox(width: 8), UTextField(expanded: 1, controller: yearRenovated, labelText: U.s.yearRenovated, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)), const SizedBox(width: 8), UTextField(expanded: 1, controller: floorCount, labelText: U.s.floorCount, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6))]),
              UAdminOptionPicker(title: U.s.staffLanguages, options: UPlaceCatalog.languages, selected: languages, onChanged: (List<String> v) => languages = v),
            ],
          ),
          UAdminSection(
            title: U.s.amenities,
            children: <Widget>[UAdminOptionPicker(title: U.s.amenities, options: UPlaceCatalog.amenities, categories: UPlaceCatalog.amenityCategories, selected: amenities, allowCustom: true, onChanged: (List<String> v) => amenities = v)],
          ),
          UAdminSection(
            title: U.s.policies,
            children: <Widget>[
              UAdminOptionPicker(title: U.s.mealPlans, options: UPlaceCatalog.mealPlans, selected: mealPlans, onChanged: (List<String> v) => mealPlans = v),
              UAdminOptionPicker(title: U.s.paymentMethods, options: UPlaceCatalog.paymentMethods, selected: paymentMethods, onChanged: (List<String> v) => paymentMethods = v),
              UAdminTriState(title: U.s.pets, value: pets, onChanged: (bool? v) => pets = v),
              UAdminTriState(title: U.s.smoking, value: smoking, onChanged: (bool? v) => smoking = v),
              UAdminTriState(title: U.s.children, value: children, onChanged: (bool? v) => children = v),
              UAdminTriState(title: U.s.extraBed, value: extraBed, onChanged: (bool? v) => extraBed = v),
              UAdminTriState(title: U.s.priceIncludesTax, value: includesTax, onChanged: (bool? v) => includesTax = v),
              _text(childrenPolicy, U.s.childrenPolicy, lines: 2),
            ],
          ),
          UAdminSection(title: U.s.socialMedia, children: <Widget>[_text(website, U.s.website), _text(whatsapp, U.s.whatsapp), _text(instagram, U.s.instagram), _text(telegram, U.s.telegram)]),
          UAdminSection(title: U.s.nearbyPlaces, children: <Widget>[_text(howToGetThere, U.s.howToGetThere, lines: 2), UAdminNearbyEditor(items: nearby, onChanged: (List<UPlaceNearby> v) => nearby = v)]),
          UAdminSection(title: U.s.faqs, children: <Widget>[UAdminFaqEditor(items: faqs, onChanged: (List<UPlaceFaq> v) => faqs = v)]),
        ],
      ),
      save: () async {
        final (UEmptyResponse? ok, UEmptyResponse? error, String? exception) = await UServices.hotel.updateHotel(
          p: UHotelUpdateParams(
            id: h.id,
            addTags: <int>[if (featured) TagHotel.featured.number, if (verified) TagHotel.verified.number],
            removeTags: <int>[if (!featured) TagHotel.featured.number, if (!verified) TagHotel.verified.number],
            amenities: amenities,
            type: type,
              highlights: highlights,
              website: _str(website),
              whatsapp: _str(whatsapp),
              instagram: _str(instagram),
              telegram: _str(telegram),
              yearBuilt: _int(yearBuilt),
              yearRenovated: _int(yearRenovated),
              floorCount: _int(floorCount),
              languages: languages,
              mealPlans: mealPlans,
              paymentMethods: paymentMethods,
              petsAllowed: pets,
              smokingAllowed: smoking,
              childrenAllowed: children,
              extraBedAvailable: extraBed,
              priceIncludesTax: includesTax,
              childrenPolicy: _str(childrenPolicy),
              howToGetThere: _str(howToGetThere),
              nearby: nearby,
              faqs: faqs,
          ),
        );
        if (!_isOk(ok, error, exception)) return false;
        await UAdminMediaSync.apply(draft: draft, existing: media, hotelId: h.id);
        return true;
      },
    );
  }

  // ---------------------------------------------------------------- hotel room

  static Future<void> hotelRoom(UHotelRoomResponse item, {VoidCallback? onDone}) async {
    final (UResponse<UHotelRoomResponse>? fetched, _, _) = await UServices.hotel.readHotelRoomById(p: UIdParams(id: item.id, selectorArgs: const HotelRoomSelectorArgs(media: MediaSelectorArgs())));
    final UHotelRoomResponse r = fetched?.result ?? item;
    final UHotelRoomJson d = r.jsonData;

    String? view = d.view;
    String? bathroom = d.bathroomType;
    String? mealPlan = d.mealPlan;
    List<String> highlights = List<String>.from(d.highlights);
    List<String> amenities = List<String>.from(r.jsonData.amenities);
    bool? smoking = d.smokingAllowed;
    bool? nonRefundable = d.nonRefundable;
    final TextEditingController maxAdults = TextEditingController(text: d.maxAdults?.toString());
    final TextEditingController maxChildren = TextEditingController(text: d.maxChildren?.toString());
    final UAdminMediaDraft draft = UAdminMediaDraft();
    final List<UMediaResponse> media = (r.media ?? <UMediaResponse>[]).sortedForGallery();

    await _open(
      title: "${U.s.detailsAndPhotos} — ${r.title}",
      onDone: onDone,
      body: (BuildContext context, StateSetter setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          UAdminSection(title: U.s.photos, children: <Widget>[UAdminMediaManager(media: media, draft: draft)]),
          UAdminSection(
            title: U.s.details,
            children: <Widget>[
              UAdminSingleChoice(title: U.s.roomView, options: UPlaceCatalog.roomViews, selected: view, onChanged: (String? v) => view = v),
              UAdminSingleChoice(title: U.s.bathroomType, options: UPlaceCatalog.bathroomTypes, selected: bathroom, onChanged: (String? v) => bathroom = v),
              UAdminSingleChoice(title: U.s.mealPlan, options: UPlaceCatalog.mealPlans, selected: mealPlan, onChanged: (String? v) => mealPlan = v),
              URow(children: <Widget>[UTextField(expanded: 1, controller: maxAdults, labelText: U.s.maxAdults, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)), const SizedBox(width: 8), UTextField(expanded: 1, controller: maxChildren, labelText: U.s.maxChildren, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6))]),
              UAdminTriState(title: U.s.smoking, value: smoking, onChanged: (bool? v) => smoking = v),
              UAdminTriState(title: U.s.nonRefundable, value: nonRefundable, onChanged: (bool? v) => nonRefundable = v),
              UAdminStringList(title: U.s.highlights, items: highlights, addLabel: U.s.addHighlight, onChanged: (List<String> v) => highlights = v),
            ],
          ),
          UAdminSection(
            title: U.s.amenities,
            children: <Widget>[UAdminOptionPicker(title: U.s.amenities, options: UPlaceCatalog.amenities, categories: UPlaceCatalog.amenityCategories, selected: amenities, allowCustom: true, onChanged: (List<String> v) => amenities = v)],
          ),
        ],
      ),
      save: () async {
        final (UEmptyResponse? ok, UEmptyResponse? error, String? exception) = await UServices.hotel.updateHotelRoom(
          p: UHotelRoomUpdateParams(
            id: r.id,
            amenities: amenities,
            view: view, bathroomType: bathroom, mealPlan: mealPlan, maxAdults: _int(maxAdults), maxChildren: _int(maxChildren), smokingAllowed: smoking, nonRefundable: nonRefundable, highlights: highlights,
          ),
        );
        if (!_isOk(ok, error, exception)) return false;
        await UAdminMediaSync.apply(draft: draft, existing: media, hotelRoomId: r.id);
        return true;
      },
    );
  }

  // ---------------------------------------------------------------- dorm

  static Future<void> dorm(UDormResponse item, {VoidCallback? onDone}) async {
    final (UResponse<UDormResponse>? fetched, _, _) = await UServices.hotel.readDormById(p: UIdParams(id: item.id, selectorArgs: const DormSelectorArgs(media: MediaSelectorArgs())));
    final UDormResponse dorm = fetched?.result ?? item;
    final UDormJson d = dorm.jsonData;

    List<String> highlights = List<String>.from(d.highlights);
    List<String> amenities = List<String>.from(dorm.jsonData.amenities);
    List<String> mealServices = List<String>.from(d.mealServices);
    List<String> servicesIncluded = List<String>.from(d.servicesIncluded);
    List<String> residentTypes = List<String>.from(d.residentTypes);
    List<UPlaceNearby> nearby = List<UPlaceNearby>.from(d.nearby);
    List<UPlaceFaq> faqs = List<UPlaceFaq>.from(d.faqs);
    bool featured = dorm.tags.contains(TagDorm.featured.number);
    bool verified = dorm.tags.contains(TagDorm.verified.number);
    bool hidden = dorm.tags.contains(TagDorm.inactive.number);
    final TextEditingController website = TextEditingController(text: d.website);
    final TextEditingController whatsapp = TextEditingController(text: d.whatsapp);
    final TextEditingController instagram = TextEditingController(text: d.instagram);
    final TextEditingController telegram = TextEditingController(text: d.telegram);
    final TextEditingController yearBuilt = TextEditingController(text: d.yearBuilt?.toString());
    final TextEditingController floorCount = TextEditingController(text: d.floorCount?.toString());
    final TextEditingController curfew = TextEditingController(text: d.curfewTime);
    final TextEditingController minStay = TextEditingController(text: d.minimumStayMonths?.toString());
    final TextEditingController wifi = TextEditingController(text: d.wifiSpeedMbps?.toString());
    final TextEditingController walk = TextEditingController(text: d.universityWalkMinutes?.toString());
    final TextEditingController paymentSchedule = TextEditingController(text: d.paymentSchedule);
    final TextEditingController depositPolicy = TextEditingController(text: d.depositPolicy);
    final TextEditingController earlyTermination = TextEditingController(text: d.earlyTerminationPolicy);
    final TextEditingController visitors = TextEditingController(text: d.visitorsPolicy);
    final TextEditingController howToGetThere = TextEditingController(text: d.howToGetThere);
    final UAdminMediaDraft draft = UAdminMediaDraft();
    final List<UMediaResponse> media = (dorm.media ?? <UMediaResponse>[]).sortedForGallery();

    await _open(
      title: "${U.s.detailsAndPhotos} — ${dorm.title}",
      onDone: onDone,
      body: (BuildContext context, StateSetter setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          UAdminSection(
            title: U.s.visibility,
            children: <Widget>[
              _flags(<(String, bool, ValueChanged<bool>)>[
                (U.s.featured, featured, (bool v) => setState(() => featured = v)),
                (U.s.verifiedOnSite, verified, (bool v) => setState(() => verified = v)),
                (U.s.inactive, hidden, (bool v) => setState(() => hidden = v)),
              ]),
            ],
          ),
          UAdminSection(title: U.s.photos, children: <Widget>[UAdminMediaManager(media: media, draft: draft)]),
          UAdminSection(
            title: U.s.details,
            children: <Widget>[
              UAdminStringList(title: U.s.highlights, items: highlights, addLabel: U.s.addHighlight, onChanged: (List<String> v) => highlights = v),
              URow(children: <Widget>[UTextField(expanded: 1, controller: yearBuilt, labelText: U.s.yearBuilt, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)), const SizedBox(width: 8), UTextField(expanded: 1, controller: floorCount, labelText: U.s.floorCount, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)), const SizedBox(width: 8), UTextField(expanded: 1, controller: wifi, labelText: U.s.wifiSpeed, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6))]),
              URow(children: <Widget>[UTextField(expanded: 1, controller: curfew, labelText: U.s.curfewTime, margin: const EdgeInsets.symmetric(vertical: 6)), const SizedBox(width: 8), UTextField(expanded: 1, controller: walk, labelText: U.s.universityWalkMinutes, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6))]),
              UAdminOptionPicker(title: U.s.residentTypes, options: UPlaceCatalog.residentTypes, selected: residentTypes, onChanged: (List<String> v) => residentTypes = v),
            ],
          ),
          UAdminSection(
            title: U.s.amenities,
            children: <Widget>[UAdminOptionPicker(title: U.s.amenities, options: UPlaceCatalog.amenities, categories: UPlaceCatalog.amenityCategories, selected: amenities, allowCustom: true, onChanged: (List<String> v) => amenities = v)],
          ),
          UAdminSection(
            title: U.s.servicesIncluded,
            children: <Widget>[
              UAdminOptionPicker(title: U.s.servicesIncluded, options: UPlaceCatalog.dormServices, selected: servicesIncluded, onChanged: (List<String> v) => servicesIncluded = v),
              UAdminOptionPicker(title: U.s.mealServices, options: UPlaceCatalog.mealServices, selected: mealServices, onChanged: (List<String> v) => mealServices = v),
            ],
          ),
          UAdminSection(
            title: U.s.policies,
            children: <Widget>[
              _text(minStay, U.s.minimumStayMonths, number: true),
              _text(paymentSchedule, U.s.paymentSchedule, lines: 2),
              _text(depositPolicy, U.s.depositPolicy, lines: 2),
              _text(earlyTermination, U.s.earlyTerminationPolicy, lines: 2),
              _text(visitors, U.s.visitorsPolicy, lines: 2),
            ],
          ),
          UAdminSection(title: U.s.socialMedia, children: <Widget>[_text(website, U.s.website), _text(whatsapp, U.s.whatsapp), _text(instagram, U.s.instagram), _text(telegram, U.s.telegram)]),
          UAdminSection(title: U.s.nearbyPlaces, children: <Widget>[_text(howToGetThere, U.s.howToGetThere, lines: 2), UAdminNearbyEditor(items: nearby, onChanged: (List<UPlaceNearby> v) => nearby = v)]),
          UAdminSection(title: U.s.faqs, children: <Widget>[UAdminFaqEditor(items: faqs, onChanged: (List<UPlaceFaq> v) => faqs = v)]),
        ],
      ),
      save: () async {
        final (UEmptyResponse? ok, UEmptyResponse? error, String? exception) = await UServices.hotel.updateDorm(
          p: UDormUpdateParams(
            id: dorm.id,
            addTags: <int>[if (featured) TagDorm.featured.number, if (verified) TagDorm.verified.number, if (hidden) TagDorm.inactive.number],
            removeTags: <int>[if (!featured) TagDorm.featured.number, if (!verified) TagDorm.verified.number, if (!hidden) TagDorm.inactive.number],
            amenities: amenities,
            highlights: highlights,
              website: _str(website),
              whatsapp: _str(whatsapp),
              instagram: _str(instagram),
              telegram: _str(telegram),
              yearBuilt: _int(yearBuilt),
              floorCount: _int(floorCount),
              curfewTime: _str(curfew),
              mealServices: mealServices,
              servicesIncluded: servicesIncluded,
              residentTypes: residentTypes,
              minimumStayMonths: _int(minStay),
              paymentSchedule: _str(paymentSchedule),
              depositPolicy: _str(depositPolicy),
              earlyTerminationPolicy: _str(earlyTermination),
              visitorsPolicy: _str(visitors),
              wifiSpeedMbps: _int(wifi),
              universityWalkMinutes: _int(walk),
              howToGetThere: _str(howToGetThere),
              nearby: nearby,
              faqs: faqs,
          ),
        );
        if (!_isOk(ok, error, exception)) return false;
        await UAdminMediaSync.apply(draft: draft, existing: media, dormId: dorm.id);
        return true;
      },
    );
  }

  // ---------------------------------------------------------------- dorm room

  static Future<void> dormRoom(UDormRoomResponse item, {VoidCallback? onDone}) async {
    final (UResponse<UDormRoomResponse>? fetched, _, _) = await UServices.hotel.readDormRoomById(p: UIdParams(id: item.id, selectorArgs: const DormRoomSelectorArgs(media: MediaSelectorArgs())));
    final UDormRoomResponse r = fetched?.result ?? item;
    final UDormRoomJson d = r.jsonData;

    String? view = d.view;
    String? bathroom = d.bathroomType;
    bool? furnished = d.furnished;
    List<String> highlights = List<String>.from(d.highlights);
    List<String> amenities = List<String>.from(r.jsonData.amenities);
    final UAdminMediaDraft draft = UAdminMediaDraft();
    final List<UMediaResponse> media = (r.media ?? <UMediaResponse>[]).sortedForGallery();

    await _open(
      title: "${U.s.detailsAndPhotos} — ${r.title}",
      onDone: onDone,
      body: (BuildContext context, StateSetter setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          UAdminSection(title: U.s.photos, children: <Widget>[UAdminMediaManager(media: media, draft: draft)]),
          UAdminSection(
            title: U.s.details,
            children: <Widget>[
              UAdminSingleChoice(title: U.s.bathroomType, options: UPlaceCatalog.bathroomTypes, selected: bathroom, onChanged: (String? v) => bathroom = v),
              UAdminSingleChoice(title: U.s.roomView, options: UPlaceCatalog.roomViews, selected: view, onChanged: (String? v) => view = v),
              UAdminTriState(title: U.s.furnished, value: furnished, onChanged: (bool? v) => furnished = v),
              UAdminStringList(title: U.s.highlights, items: highlights, addLabel: U.s.addHighlight, onChanged: (List<String> v) => highlights = v),
            ],
          ),
          UAdminSection(
            title: U.s.amenities,
            children: <Widget>[UAdminOptionPicker(title: U.s.amenities, options: UPlaceCatalog.amenities, categories: UPlaceCatalog.amenityCategories, selected: amenities, allowCustom: true, onChanged: (List<String> v) => amenities = v)],
          ),
        ],
      ),
      save: () async {
        final (UEmptyResponse? ok, UEmptyResponse? error, String? exception) = await UServices.hotel.updateDormRoom(
          p: UDormRoomUpdateParams(id: r.id, amenities: amenities, bathroomType: bathroom, view: view, furnished: furnished, highlights: highlights),
        );
        if (!_isOk(ok, error, exception)) return false;
        await UAdminMediaSync.apply(draft: draft, existing: media, dormRoomId: r.id);
        return true;
      },
    );
  }

  // ---------------------------------------------------------------- dorm bed

  static Future<void> dormBed(UDormBedResponse item, {VoidCallback? onDone}) async {
    final (UResponse<UDormBedResponse>? fetched, _, _) = await UServices.hotel.readDormBedById(p: UIdParams(id: item.id, selectorArgs: const DormBedSelectorArgs(media: MediaSelectorArgs())));
    final UDormBedResponse b = fetched?.result ?? item;
    final UDormBedJson d = b.jsonData;

    String? level = d.level;
    List<String> amenities = List<String>.from(d.amenities);
    final TextEditingController description = TextEditingController(text: d.description);
    final UAdminMediaDraft draft = UAdminMediaDraft();
    final List<UMediaResponse> media = (b.media ?? <UMediaResponse>[]).sortedForGallery();

    await _open(
      title: "${U.s.detailsAndPhotos} — ${b.title}",
      onDone: onDone,
      body: (BuildContext context, StateSetter setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          UAdminSection(title: U.s.photos, children: <Widget>[UAdminMediaManager(media: media, draft: draft)]),
          UAdminSection(
            title: U.s.details,
            children: <Widget>[
              UAdminSingleChoice(title: U.s.bedLevel, options: UPlaceCatalog.bedLevels, selected: level, onChanged: (String? v) => level = v),
              UAdminOptionPicker(title: U.s.bedAmenities, options: UPlaceCatalog.bedAmenities, selected: amenities, onChanged: (List<String> v) => amenities = v),
              _text(description, U.s.description, lines: 2),
            ],
          ),
        ],
      ),
      save: () async {
        final (UEmptyResponse? ok, UEmptyResponse? error, String? exception) = await UServices.hotel.updateDormBed(
          p: UDormBedUpdateParams(id: b.id, level: level, description: _str(description), amenities: amenities),
        );
        if (!_isOk(ok, error, exception)) return false;
        await UAdminMediaSync.apply(draft: draft, existing: media, dormBedId: b.id);
        return true;
      },
    );
  }
}
