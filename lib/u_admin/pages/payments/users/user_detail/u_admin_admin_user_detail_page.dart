import "package:u/utilities.dart";

enum _DocStatus { verified, rejected, awaiting, missing }

class _Doc {
  _Doc({required this.title, required this.base64, required this.verifiedTag, required this.awaitingTag, required this.rejectionReason, this.isVideo = false});

  final String title;
  final String? base64;
  final TagUser verifiedTag;
  final TagUser awaitingTag;
  final String? rejectionReason;
  final bool isVideo;
}

class UAdminUserDetailPage extends StatefulWidget {
  const UAdminUserDetailPage({required this.user, super.key});

  final UUserResponse user;

  @override
  State<UAdminUserDetailPage> createState() => _AdminUserDetailPageState();
}

class _AdminUserDetailPageState extends State<UAdminUserDetailPage> {
  final UAdminUserDetailController c = UAdminUserDetailController();

  @override
  void initState() {
    c.init(user: widget.user);
    super.initState();
  }

  List<_Doc> get _docs => <_Doc>[
    _Doc(
      title: U.s.nationalCardFront,
      base64: c.user.nationalCardFront,
      verifiedTag: TagUser.nationalCardFrontVerified,
      awaitingTag: TagUser.nationalCardFrontAwaitingVerification,
      rejectionReason: c.user.jsonData.nationalCardFrontRejectionReason,
    ),
    _Doc(
      title: U.s.nationalCardBack,
      base64: c.user.nationalCardBack,
      verifiedTag: TagUser.nationalCardBackVerified,
      awaitingTag: TagUser.nationalCardBackAwaitingVerification,
      rejectionReason: c.user.jsonData.nationalCardBackRejectionReason,
    ),
    _Doc(
      title: U.s.birthCertificate,
      base64: c.user.birthCertificateFirst,
      verifiedTag: TagUser.birthCertificateFirstVerified,
      awaitingTag: TagUser.birthCertificateFirstAwaitingVerification,
      rejectionReason: c.user.jsonData.birthCertificateFirstRejectionReason,
    ),
    _Doc(
      title: U.s.signature,
      base64: c.user.eSignature,
      verifiedTag: TagUser.eSignatureVerified,
      awaitingTag: TagUser.eSignatureAwaitingVerification,
      rejectionReason: c.user.jsonData.eSignatureRejectionReason,
    ),
    _Doc(
      title: U.s.video,
      base64: c.user.visualAuthentication,
      verifiedTag: TagUser.visualAuthenticationVerified,
      awaitingTag: TagUser.visualAuthenticationAwaitingVerification,
      rejectionReason: c.user.jsonData.visualAuthenticationRejectionReason,
      isVideo: true,
    ),
  ];

  _DocStatus _statusOf(_Doc d) {
    if (c.user.tags.contains(d.verifiedTag.number)) return _DocStatus.verified;
    if (d.rejectionReason.isNotNullOrEmpty()) return _DocStatus.rejected;
    if (d.base64 != null) return _DocStatus.awaiting;
    return _DocStatus.missing;
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    appBar: AppBar(
      title: Text(U.s.userDetails),
      elevation: 0,
      actions: <Widget>[UButton(type: UButtonType.text, title: U.s.downloadData, icon: const Icon(Icons.download_outlined), onTap: _downloadData)],
    ),
    body: SingleChildScrollView(
      child: Obx(() {
        if (c.state.isLoading() || c.state.isInitial()) return const CircularProgressIndicator().alignAtCenter().pOnly(top: 80);
        if (c.state.isError()) return UAdminAppErrorRetry(onTap: c.read).pOnly(top: 80);
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: UColumn(
              spacing: 0,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 12),
                _statusCard(),
                const SizedBox(height: 16),
                _userInfo(),
                const SizedBox(height: 16),
                _documentsSection(),
                const SizedBox(height: 20),
                URow(
                  spacing: 0,
                  children: <Widget>[
                    UButton(title: U.s.approve, icon: const Icon(Icons.check_circle_outline), onTap: _confirmApprove).expanded(flex: 2),
                    const SizedBox(width: 12),
                    UButton(title: U.s.reject, icon: const Icon(Icons.cancel_outlined), backgroundColor: Theme.of(context).colorScheme.error, onTap: _showRejectDialog).expanded(),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }),
    ),
  );

  Widget _statusCard() {
    final bool verified = c.isFullyVerified;
    final Color color = verified ? UAdminTheme.green : UAdminTheme.orange;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: <Color>[color.withValues(alpha: 0.08), color.withValues(alpha: 0.20)], begin: Alignment.topRight, end: Alignment.bottomLeft),
        borderRadius: BorderRadius.circular(16),
      ),
      child: URow(
        spacing: 0,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12)),
            child: Icon(verified ? Icons.verified_rounded : Icons.pending_actions_rounded, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: UColumn(
              spacing: 0,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                UTextBodySmall(U.s.verificationStatus, color: UAdminTheme.grey),
                const SizedBox(height: 4),
                UTextBodyLarge(verified ? U.s.verified : U.s.pendingVerification, fontWeight: FontWeight.bold, color: color),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20)),
            child: UTextBodySmall(verified ? U.s.approved : U.s.needsReview, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _userInfo() => UColumn(
    spacing: 0,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      _sectionHeader(U.s.userInformation, Icons.person_outline, UAdminTheme.orange),
      const SizedBox(height: 12),
      DecoratedBox(
        decoration: _cardDecoration(),
        child: UColumn(
          spacing: 0,
          children: <Widget>[
            _infoRow(Icons.person, U.s.username, c.user.userName, UAdminTheme.orange),
            const Divider(height: 1),
            _infoRow(Icons.badge, U.s.firstName, c.user.firstName ?? U.s.notUploaded, UAdminTheme.orange),
            const Divider(height: 1),
            _infoRow(Icons.badge_outlined, U.s.lastName, c.user.lastName ?? U.s.notUploaded, UAdminTheme.orange),
            const Divider(height: 1),
            _infoRow(Icons.card_membership, U.s.nationalCode, c.user.nationalCode ?? U.s.notUploaded, UAdminTheme.orange),
            const Divider(height: 1),
            _infoRow(Icons.phone, U.s.phoneNumber, c.user.phoneNumber ?? U.s.notUploaded, UAdminTheme.orange),
            const Divider(height: 1),
            _infoRow(Icons.email, U.s.email, c.user.email ?? U.s.notUploaded, UAdminTheme.orange),
            const Divider(height: 1),
            _infoRow(Icons.person_2, U.s.fatherName, c.user.jsonData.fatherName ?? U.s.notUploaded, UAdminTheme.orange),
          ],
        ),
      ),
    ],
  );

  Widget _documentsSection() => UColumn(
    spacing: 0,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      _sectionHeader(U.s.userDocuments, Icons.folder_outlined, UAdminTheme.red),
      const SizedBox(height: 12),
      Wrap(spacing: 12, runSpacing: 12, children: _docs.map(_documentCard).toList()),
    ],
  );

  Widget _documentCard(_Doc d) {
    final _DocStatus status = _statusOf(d);
    final bool hasData = d.base64 != null;
    return SizedBox(
      width: 190,
      child: DecoratedBox(
        decoration: _cardDecoration(),
        child: UColumn(
          spacing: 0,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Stack(
              children: <Widget>[
                Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: hasData && !d.isVideo
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: UImage(
                            "",
                            fileData: FileData(bytes: d.base64!.toBytesFromBase64()),
                            placeholder: UAdmin.logo,
                            fit: BoxFit.cover,
                          ),
                        )
                      : hasData && d.isVideo
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: UVideoPlayer(
                            base64: d.base64,
                            fit: BoxFit.cover,
                            muted: true,
                            allowFullScreen: false,
                            borderRadius: 0,
                            accentColor: UAdminTheme.orange,
                          ),
                        )
                      : Center(
                          child: UColumn(
                            spacing: 0,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(d.isVideo ? Icons.videocam_off_outlined : Icons.insert_drive_file, size: 44, color: UAdminTheme.grey.shade400),
                              const SizedBox(height: 6),
                              UTextBodySmall(U.s.notUploaded, color: UAdminTheme.grey),
                            ],
                          ),
                        ),
                ),
                Positioned(top: 8, right: 8, child: _docStatusBadge(status)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: UColumn(
                spacing: 0,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  URow(
                    spacing: 0,
                    children: <Widget>[
                      Expanded(
                        child: UTextBodySmall(d.title, fontWeight: FontWeight.w600, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      IconButton(
                        onPressed: hasData ? (d.isVideo ? () => _openVideo(d.base64!) : () => _openImage(d.base64!)) : null,
                        icon: Icon(hasData && d.isVideo ? Icons.fullscreen : Icons.zoom_out_map, size: 18, color: hasData ? UAdminTheme.blue.shade700 : UAdminTheme.grey.shade400),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                  if (status == _DocStatus.rejected && d.rejectionReason.isNotNullOrEmpty())
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: UTextBodySmall("${U.s.rejectionReason}: ${d.rejectionReason}", color: Theme.of(context).colorScheme.error),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _docStatusBadge(_DocStatus status) {
    late final Color color;
    late final IconData icon;
    late final String label;
    switch (status) {
      case _DocStatus.verified:
        color = UAdminTheme.green;
        icon = Icons.check_circle;
        label = U.s.approved;
      case _DocStatus.rejected:
        color = Theme.of(context).colorScheme.error;
        icon = Icons.cancel;
        label = U.s.rejected;
      case _DocStatus.awaiting:
        color = UAdminTheme.orange;
        icon = Icons.schedule;
        label = U.s.pendingVerification;
      case _DocStatus.missing:
        color = UAdminTheme.grey;
        icon = Icons.remove_circle_outline;
        label = U.s.notUploaded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: URow(
        spacing: 0,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: UAdminTheme.white),
          const SizedBox(width: 4),
          UTextBodySmall(label, color: UAdminTheme.white, fontWeight: FontWeight.w600),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) => ListTile(
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: 20, color: color),
    ),
    title: UTextBodySmall(label, color: UAdminTheme.grey),
    subtitle: UTextBodyMedium(value, fontWeight: FontWeight.w500),
    trailing: Icon(Icons.copy, color: Theme.of(context).disabledColor, size: 18),
    onTap: () {
      UClipboard.set(value);
      UToast.snackBar(message: U.s.copiedToClipboard);
    },
  );

  Widget _sectionHeader(String title, IconData icon, Color color) => URow(
    spacing: 0,
    children: <Widget>[
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 20, color: color),
      ),
      const SizedBox(width: 12),
      UTextBodyLarge(title, fontWeight: FontWeight.bold),
    ],
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
    boxShadow: <BoxShadow>[BoxShadow(color: UAdminTheme.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
  );

  void _openImage(String base64) => UNavigator.push(UImageViewer(fileData: FileData(bytes: base64.toBytesFromBase64())));

  void _openVideo(String base64) => UVideo.show(base64: base64);

  void _confirmApprove() => UNavigator.confirm(
    title: U.s.finalApproval,
    message: U.s.areYouSureYouWantToApproveThisUserWithAllOfTheirDocuments,
    onConfirm: () {
      UNavigator.back();
      c.approve();
    },
    onCancel: UNavigator.back,
  );

  void _downloadData() => UServices.user.downloadUserData(
    p: UIdParams(id: c.user.id),
    onOk: (UResponse<String> r) => UToast.snackBar(message: r.message),
    onError: (UEmptyResponse r) => UToast.error(message: r.message),
    onException: (String e) => UToast.error(message: e),
  );

  void _showRejectDialog() {
    final TextEditingController frontReason = TextEditingController(text: c.user.jsonData.nationalCardFrontRejectionReason);
    final TextEditingController backReason = TextEditingController(text: c.user.jsonData.nationalCardBackRejectionReason);
    final TextEditingController birthReason = TextEditingController(text: c.user.jsonData.birthCertificateFirstRejectionReason);
    final TextEditingController videoReason = TextEditingController(text: c.user.jsonData.visualAuthenticationRejectionReason);
    final TextEditingController signatureReason = TextEditingController(text: c.user.jsonData.eSignatureRejectionReason);

    UNavigator.dialog(
      AlertDialog(
        title: Text(U.s.rejectDocuments),
        content: SingleChildScrollView(
          child: UColumn(
            spacing: 0,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UTextField(labelText: U.s.reasonForRejectingNationalCardFront, controller: frontReason).pSymmetric(vertical: 6),
              UTextField(labelText: U.s.reasonForRejectingNationalCardBack, controller: backReason).pSymmetric(vertical: 6),
              UTextField(labelText: U.s.reasonForRejectingBirthCertificate, controller: birthReason).pSymmetric(vertical: 6),
              UTextField(labelText: U.s.reasonForRejectingVideo, controller: videoReason).pSymmetric(vertical: 6),
              UTextField(labelText: U.s.reasonForRejectingSignature, controller: signatureReason).pSymmetric(vertical: 6),
            ],
          ),
        ),
        actions: <Widget>[
          UButton(type: UButtonType.text, title: U.s.cancel, onTap: UNavigator.back),
          UButton(
            title: U.s.reject,
            backgroundColor: Theme.of(context).colorScheme.error,
            onTap: () {
              final List<int> removeTags = <int>[];
              if (frontReason.text.isNotNullOrEmpty()) removeTags.add(TagUser.nationalCardFrontAwaitingVerification.number);
              if (backReason.text.isNotNullOrEmpty()) removeTags.add(TagUser.nationalCardBackAwaitingVerification.number);
              if (birthReason.text.isNotNullOrEmpty()) removeTags.add(TagUser.birthCertificateFirstAwaitingVerification.number);
              if (videoReason.text.isNotNullOrEmpty()) removeTags.add(TagUser.visualAuthenticationAwaitingVerification.number);
              if (signatureReason.text.isNotNullOrEmpty()) removeTags.add(TagUser.eSignatureAwaitingVerification.number);
              UNavigator.back();
              c.reject(
                p: UUserUpdateParams(
                  id: c.user.id,
                  nationalCardFrontRejectionReason: frontReason.valueOrNull(),
                  nationalCardBackRejectionReason: backReason.valueOrNull(),
                  birthCertificateFirstRejectionReason: birthReason.valueOrNull(),
                  visualAuthenticationRejectionReason: videoReason.valueOrNull(),
                  eSignatureRejectionReason: signatureReason.valueOrNull(),
                  removeTags: removeTags,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class UAdminAppErrorRetry extends StatelessWidget {
  const UAdminAppErrorRetry({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => UColumn(
    spacing: 0,
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
      const SizedBox(height: 12),
      UTextBodyMedium(U.s.errorReadingData),
      const SizedBox(height: 12),
      UButton(title: U.s.tryAgain, onTap: onTap, width: 160),
    ],
  ).alignAtCenter();
}
