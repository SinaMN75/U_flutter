part of "../data.dart";

class UMediaService {
  Future<(UResponse<String>?, UEmptyResponse?, String?)> create({
    required UMediaCreateParams p,
    required Function(UResponse<String> r)? onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) async {
    (UResponse<String>?, UEmptyResponse?, String?) result = (null, null, null);
    final List<MultipartFile> files = <MultipartFile>[
      if (p.file.bytes != null) await UHttpClient.multipartFileFromUint8List("File", p.file.bytes!, filename: p.file.name ?? "file.${p.file.extension ?? "png"}"),
    ];
    await UHttpClient.upload(
      endpoint: "${U.baseUrl}/Media/Create",
      files: files,
      fields: p.toMap()..addAll(<String, dynamic>{"apiKey": U.apiKey, "token": ULocalStorage.getToken()}),
      onSuccess: (Response r) {
        final UResponse<String> ok = UResponse<String>.fromJson(r.body, (dynamic i) => i);
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError(err);
      },
      onException: () {
        result = (null, null, "");
        onException("");
      },
    );
    return result;
  }

  Future<(UResponse<List<UMediaResponse>>?, UEmptyResponse?, String?)> read({
    required UMediaReadParams p,
    required Function(UResponse<List<UMediaResponse>> r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) => _Api.call("/Media/Read", p.toMap(), _Api.list(UMediaResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> update({
    required UMediaUpdateParams p,
    required Function(UEmptyResponse r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) => _Api.call("/Media/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> delete({
    required UIdParams p,
    required Function(UEmptyResponse r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) => _Api.call("/Media/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteRange({
    required UIdListParams p,
    required Function(UEmptyResponse r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) => _Api.call("/Media/DeleteRange", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  /// Saves a [UFilePicker.gallery]: deletes removed photos, uploads new ones (category = first tag) and moves the cover mark.
  Future<void> syncGallery(
    UFilePickerController photos, {
    required List<UMediaResponse> existing,
    String? hotelId,
    String? hotelRoomId,
    String? dormId,
    String? dormRoomId,
    String? dormBedId,
  }) async {
    if (!photos.hasChanges) return;
    void ignore(_) {}

    final Set<String> deletedIds = photos.removedFiles.map((UFileData f) => f.id!).toSet();
    for (final String id in deletedIds) {
      await delete(p: UIdParams(id: id), onOk: ignore, onError: ignore, onException: ignore);
    }

    final List<UFileData> newFiles = photos.files;
    final UFileData? cover = photos.coverChanged ? photos.cover : null;
    final int coverNewIndex = cover != null && cover.id == null ? newFiles.indexOf(cover) : -1;
    final List<String?> uploadedIds = <String?>[];
    for (int i = 0; i < newFiles.length; i++) {
      final (UResponse<String>? ok, _, _) = await create(
        p: UMediaCreateParams(
          file: newFiles[i],
          tag1: TagMedia.image.number,
          tag2: newFiles[i].tags?.firstOrNull,
          tag3: coverNewIndex == i ? TagMedia.cover.number : null,
          hotelId: hotelId,
          hotelRoomId: hotelRoomId,
          dormId: dormId,
          dormRoomId: dormRoomId,
          dormBedId: dormBedId,
        ),
        onOk: ignore,
        onError: ignore,
        onException: ignore,
      );
      uploadedIds.add(ok?.result);
    }

    // The cover mark lives on exactly one photo.
    final String? newCoverId = cover?.id ?? (coverNewIndex < 0 ? null : uploadedIds[coverNewIndex]);
    if (newCoverId == null) return;
    for (final UMediaResponse m in existing.where((UMediaResponse m) => m.tags.contains(TagMedia.cover.number) && m.id != newCoverId && !deletedIds.contains(m.id))) {
      await update(p: UMediaUpdateParams(id: m.id, removeTags: <int>[TagMedia.cover.number]), onOk: ignore, onError: ignore, onException: ignore);
    }
    if (cover?.id != null) await update(p: UMediaUpdateParams(id: newCoverId, addTags: <int>[TagMedia.cover.number]), onOk: ignore, onError: ignore, onException: ignore);
  }
}
