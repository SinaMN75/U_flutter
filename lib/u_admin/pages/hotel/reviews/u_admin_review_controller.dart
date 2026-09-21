part of "../../../u_admin.dart";

/// Moderation of the reviews guests write about hotels and dorms.
class UAdminReviewController extends UBaseController {
  List<UCommentResponse> list = <UCommentResponse>[];

  /// Which reviews are listed: waiting for approval by default.
  TagComment status = TagComment.inQueue;

  void init() => read();

  Future<void> read() async {
    state.loading();
    await UServices.comment.read(
      p: UCommentReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        tags: <int>[status.number],
        selectorArgs: const UCommentSelectorArgs(user: UUserSelectorArgs()),
        orderBy: TagOrderBy.createdAtDescending.number,
      ),
      onOk: (UResponse<List<UCommentResponse>> r) {
        // The comment table also holds product and blog comments; only hotel and dorm reviews belong here.
        list = (r.result ?? <UCommentResponse>[]).where((UCommentResponse c) => c.hotelId != null || c.dormId != null).toList();
        setTotalPages(r.totalCount);
        setListState(isEmpty: list.isEmpty);
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: (String e) => setError(),
    );
  }

  void changeStatus(TagComment value) {
    status = value;
    reloadFirstPage(read);
  }

  void _setStatus(UCommentResponse c, TagComment to) => UServices.comment.update(
    p: UCommentUpdateParams(
      id: c.id,
      addTags: <int>[to.number],
      removeTags: <int>[TagComment.released.number, TagComment.inQueue.number, TagComment.rejected.number].where((int t) => t != to.number).toList(),
    ),
    onOk: (UEmptyResponse r) => okCallback(r.message, read),
    onError: (UEmptyResponse r) => errorCallBack(r.message, read),
    onException: (String e) => errorCallBack(U.s.errorSubmittingForm, read),
  );

  void approve(UCommentResponse c) => _setStatus(c, TagComment.released);

  void reject(UCommentResponse c) => _setStatus(c, TagComment.rejected);

  void delete(UCommentResponse c) => UNavigator.confirm(
    title: U.s.delete,
    message: U.s.areYouSureYouWantToDelete,
    onConfirm: () => UServices.comment.delete(
      p: UIdParams(id: c.id),
      onOk: (UEmptyResponse r) {
        UNavigator.back();
        okCallback(r.message, read);
      },
      onError: (UEmptyResponse r) {
        UNavigator.back();
        errorCallBack(r.message, read);
      },
      onException: (String e) {
        UNavigator.back();
        UToast.error(message: e);
      },
    ),
  );
}
