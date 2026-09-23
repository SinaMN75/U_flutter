part of "../../../u_admin.dart";

// "Details & photos" editors of hotels, hotel rooms, dorms, dorm rooms and dorm beds.
// Every choice (amenities, meal plans, policies, view...) is a tag: the chips edit one `tags` list that is saved with the normal update endpoint.
// Free texts (highlights, nearby places, FAQs...) go to the Json fields. Photo changes are applied after the update.

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

  /// An empty text is sent as "" so the admin can clear a field.
  static String _str(TextEditingController c) => c.text.trim();

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
          content: SizedBox(
            width: context.dialogWidth(max: 760),
            child: SingleChildScrollView(child: body(context, setState)),
          ),
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
    final (UResponse<UHotelResponse>? fetched, _, _) = await UServices.hotel.readHotelById(
      p: UIdParams(
        id: item.id,
        selectorArgs: const UHotelSelectorArgs(media: UMediaSelectorArgs()),
      ),
    );
    final UHotelResponse h = fetched?.result ?? item;
    final UHotelJson d = h.jsonData;

    final List<int> tags = List<int>.from(h.tags);
    List<String> highlights = List<String>.from(d.highlights);
    List<UPlaceNearby> nearby = List<UPlaceNearby>.from(d.nearby);
    List<UPlaceFaq> faqs = List<UPlaceFaq>.from(d.faqs);
    final TextEditingController website = TextEditingController(text: d.website);
    final TextEditingController whatsapp = TextEditingController(text: d.whatsapp);
    final TextEditingController instagram = TextEditingController(text: d.instagram);
    final TextEditingController telegram = TextEditingController(text: d.telegram);
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
              UAdminTagChips<TagHotel>(title: U.s.featured, options: const <TagHotel>[TagHotel.featured], tags: tags),
              UAdminTagChips<TagHotel>(title: U.s.approval, options: TagHotel.values.group(400), tags: tags, single: true),
            ],
          ),
          UAdminSection(
            title: U.s.photos,
            children: <Widget>[UAdminMediaManager(media: media, draft: draft)],
          ),
          UAdminSection(
            title: U.s.details,
            children: <Widget>[UAdminStringList(title: U.s.highlights, items: highlights, addLabel: U.s.addHighlight, onChanged: (List<String> v) => highlights = v)],
          ),
          UAdminSection(
            title: U.s.amenities,
            children: <Widget>[UAdminTagChips<TagHotel>(title: U.s.amenities, options: TagHotel.values.group(500), tags: tags)],
          ),
          UAdminSection(
            title: U.s.policies,
            children: <Widget>[
              UAdminTagChips<TagHotel>(title: U.s.mealPlans, options: TagHotel.values.group(600), tags: tags),
              UAdminTagChips<TagHotel>(title: U.s.policies, options: TagHotel.values.group(300), tags: tags),
            ],
          ),
          UAdminSection(title: U.s.socialMedia, children: <Widget>[_text(website, U.s.website), _text(whatsapp, U.s.whatsapp), _text(instagram, U.s.instagram), _text(telegram, U.s.telegram)]),
          UAdminSection(
            title: U.s.nearbyPlaces,
            children: <Widget>[
              _text(howToGetThere, U.s.howToGetThere, lines: 2),
              UAdminNearbyEditor(items: nearby, onChanged: (List<UPlaceNearby> v) => nearby = v),
            ],
          ),
          UAdminSection(
            title: U.s.faqs,
            children: <Widget>[UAdminFaqEditor(items: faqs, onChanged: (List<UPlaceFaq> v) => faqs = v)],
          ),
        ],
      ),
      save: () async {
        final (UEmptyResponse? ok, UEmptyResponse? error, String? exception) = await UServices.hotel.updateHotel(
          p: UHotelUpdateParams(
            id: h.id,
            tags: tags,
            highlights: highlights,
            website: _str(website),
            whatsapp: _str(whatsapp),
            instagram: _str(instagram),
            telegram: _str(telegram),
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
    final (UResponse<UHotelRoomResponse>? fetched, _, _) = await UServices.hotel.readHotelRoomById(
      p: UIdParams(
        id: item.id,
        selectorArgs: const UHotelRoomSelectorArgs(media: UMediaSelectorArgs()),
      ),
    );
    final UHotelRoomResponse r = fetched?.result ?? item;

    final List<int> tags = List<int>.from(r.tags);
    final UAdminMediaDraft draft = UAdminMediaDraft();
    final List<UMediaResponse> media = (r.media ?? <UMediaResponse>[]).sortedForGallery();

    await _open(
      title: "${U.s.detailsAndPhotos} — ${r.title}",
      onDone: onDone,
      body: (BuildContext context, StateSetter setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          UAdminSection(
            title: U.s.photos,
            children: <Widget>[UAdminMediaManager(media: media, draft: draft)],
          ),
          UAdminSection(
            title: U.s.details,
            children: <Widget>[
              UAdminTagChips<TagRoom>(title: U.s.roomView, options: TagRoom.values.group(400), tags: tags, single: true),
              UAdminTagChips<TagRoom>(title: U.s.policies, options: TagRoom.values.group(300), tags: tags),
            ],
          ),
          UAdminSection(
            title: U.s.amenities,
            children: <Widget>[UAdminTagChips<TagRoom>(title: U.s.amenities, options: TagRoom.values.group(500), tags: tags)],
          ),
        ],
      ),
      save: () async {
        final (UEmptyResponse? ok, UEmptyResponse? error, String? exception) = await UServices.hotel.updateHotelRoom(
          p: UHotelRoomUpdateParams(id: r.id, tags: tags),
        );
        if (!_isOk(ok, error, exception)) return false;
        await UAdminMediaSync.apply(draft: draft, existing: media, hotelRoomId: r.id);
        return true;
      },
    );
  }

  // ---------------------------------------------------------------- dorm

  static Future<void> dorm(UDormResponse item, {VoidCallback? onDone}) async {
    final (UResponse<UDormResponse>? fetched, _, _) = await UServices.hotel.readDormById(
      p: UIdParams(
        id: item.id,
        selectorArgs: const UDormSelectorArgs(media: UMediaSelectorArgs()),
      ),
    );
    final UDormResponse dorm = fetched?.result ?? item;
    final UDormJson d = dorm.jsonData;

    final List<int> tags = List<int>.from(dorm.tags);
    List<String> highlights = List<String>.from(d.highlights);
    List<UPlaceNearby> nearby = List<UPlaceNearby>.from(d.nearby);
    List<UPlaceFaq> faqs = List<UPlaceFaq>.from(d.faqs);
    final TextEditingController website = TextEditingController(text: d.website);
    final TextEditingController whatsapp = TextEditingController(text: d.whatsapp);
    final TextEditingController instagram = TextEditingController(text: d.instagram);
    final TextEditingController telegram = TextEditingController(text: d.telegram);
    final TextEditingController curfew = TextEditingController(text: d.curfewTime);
    final TextEditingController minStay = TextEditingController(text: d.minimumStayMonths?.toString());
    final TextEditingController walk = TextEditingController(text: d.universityWalkMinutes?.toString());
    final TextEditingController policies = TextEditingController(text: d.policies);
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
              UAdminTagChips<TagDorm>(title: U.s.featured, options: const <TagDorm>[TagDorm.featured], tags: tags),
              UAdminTagChips<TagDorm>(title: U.s.approval, options: TagDorm.values.group(400), tags: tags, single: true),
            ],
          ),
          UAdminSection(
            title: U.s.photos,
            children: <Widget>[UAdminMediaManager(media: media, draft: draft)],
          ),
          UAdminSection(
            title: U.s.details,
            children: <Widget>[
              UAdminStringList(title: U.s.highlights, items: highlights, addLabel: U.s.addHighlight, onChanged: (List<String> v) => highlights = v),
              URow(
                children: <Widget>[
                  UTextField(expanded: 1, controller: curfew, labelText: U.s.curfewTime, margin: const EdgeInsets.symmetric(vertical: 6)),
                  const SizedBox(width: 8),
                  UTextField(expanded: 1, controller: walk, labelText: U.s.universityWalkMinutes, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)),
                ],
              ),
              UAdminTagChips<TagDorm>(title: U.s.acceptedResidents, options: TagDorm.values.group(300), tags: tags),
            ],
          ),
          UAdminSection(
            title: U.s.amenities,
            children: <Widget>[UAdminTagChips<TagDorm>(title: U.s.amenities, options: TagDorm.values.group(500), tags: tags)],
          ),
          UAdminSection(
            title: U.s.servicesIncluded,
            children: <Widget>[
              UAdminTagChips<TagDorm>(title: U.s.includedInRent, options: TagDorm.values.group(700), tags: tags),
              UAdminTagChips<TagDorm>(title: U.s.mealServices, options: TagDorm.values.group(600), tags: tags),
            ],
          ),
          UAdminSection(
            title: U.s.policies,
            children: <Widget>[
              _text(minStay, U.s.minimumStayMonths, number: true),
              _text(policies, U.s.policies, lines: 3),
            ],
          ),
          UAdminSection(title: U.s.socialMedia, children: <Widget>[_text(website, U.s.website), _text(whatsapp, U.s.whatsapp), _text(instagram, U.s.instagram), _text(telegram, U.s.telegram)]),
          UAdminSection(
            title: U.s.nearbyPlaces,
            children: <Widget>[
              _text(howToGetThere, U.s.howToGetThere, lines: 2),
              UAdminNearbyEditor(items: nearby, onChanged: (List<UPlaceNearby> v) => nearby = v),
            ],
          ),
          UAdminSection(
            title: U.s.faqs,
            children: <Widget>[UAdminFaqEditor(items: faqs, onChanged: (List<UPlaceFaq> v) => faqs = v)],
          ),
        ],
      ),
      save: () async {
        final (UEmptyResponse? ok, UEmptyResponse? error, String? exception) = await UServices.hotel.updateDorm(
          p: UDormUpdateParams(
            id: dorm.id,
            tags: tags,
            highlights: highlights,
            website: _str(website),
            whatsapp: _str(whatsapp),
            instagram: _str(instagram),
            telegram: _str(telegram),
            curfewTime: _str(curfew),
            minimumStayMonths: _int(minStay),
            universityWalkMinutes: _int(walk),
            policies: _str(policies),
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
    final (UResponse<UDormRoomResponse>? fetched, _, _) = await UServices.hotel.readDormRoomById(
      p: UIdParams(
        id: item.id,
        selectorArgs: const UDormRoomSelectorArgs(media: UMediaSelectorArgs()),
      ),
    );
    final UDormRoomResponse r = fetched?.result ?? item;

    final List<int> tags = List<int>.from(r.tags);
    final UAdminMediaDraft draft = UAdminMediaDraft();
    final List<UMediaResponse> media = (r.media ?? <UMediaResponse>[]).sortedForGallery();

    await _open(
      title: "${U.s.detailsAndPhotos} — ${r.title}",
      onDone: onDone,
      body: (BuildContext context, StateSetter setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          UAdminSection(
            title: U.s.photos,
            children: <Widget>[UAdminMediaManager(media: media, draft: draft)],
          ),
          UAdminSection(
            title: U.s.amenities,
            children: <Widget>[
              UAdminTagChips<TagDormRoom>(title: U.s.details, options: TagDormRoom.values.group(300), tags: tags),
              UAdminTagChips<TagDormRoom>(title: U.s.amenities, options: TagDormRoom.values.group(500), tags: tags),
            ],
          ),
        ],
      ),
      save: () async {
        final (UEmptyResponse? ok, UEmptyResponse? error, String? exception) = await UServices.hotel.updateDormRoom(
          p: UDormRoomUpdateParams(id: r.id, tags: tags),
        );
        if (!_isOk(ok, error, exception)) return false;
        await UAdminMediaSync.apply(draft: draft, existing: media, dormRoomId: r.id);
        return true;
      },
    );
  }

  // ---------------------------------------------------------------- dorm bed

  static Future<void> dormBed(UDormBedResponse item, {VoidCallback? onDone}) async {
    final (UResponse<UDormBedResponse>? fetched, _, _) = await UServices.hotel.readDormBedById(
      p: UIdParams(
        id: item.id,
        selectorArgs: const UDormBedSelectorArgs(media: UMediaSelectorArgs()),
      ),
    );
    final UDormBedResponse b = fetched?.result ?? item;

    final List<int> tags = List<int>.from(b.tags);
    final UAdminMediaDraft draft = UAdminMediaDraft();
    final List<UMediaResponse> media = (b.media ?? <UMediaResponse>[]).sortedForGallery();

    await _open(
      title: "${U.s.detailsAndPhotos} — ${b.title}",
      onDone: onDone,
      body: (BuildContext context, StateSetter setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          UAdminSection(
            title: U.s.photos,
            children: <Widget>[UAdminMediaManager(media: media, draft: draft)],
          ),
          UAdminSection(
            title: U.s.details,
            children: <Widget>[
              UAdminTagChips<TagDormBed>(title: U.s.bedLevel, options: TagDormBed.values.group(200), tags: tags, single: true),
              UAdminTagChips<TagDormBed>(title: U.s.bedAmenities, options: TagDormBed.values.group(500), tags: tags),
            ],
          ),
        ],
      ),
      save: () async {
        final (UEmptyResponse? ok, UEmptyResponse? error, String? exception) = await UServices.hotel.updateDormBed(
          p: UDormBedUpdateParams(id: b.id, tags: tags),
        );
        if (!_isOk(ok, error, exception)) return false;
        await UAdminMediaSync.apply(draft: draft, existing: media, dormBedId: b.id);
        return true;
      },
    );
  }
}
