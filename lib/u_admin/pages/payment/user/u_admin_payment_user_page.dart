part of "../../../u_admin.dart";

enum _DocStatus { verified, rejected, awaiting, missing }

class _Doc {
  _Doc({required this.title, required this.url, required this.verifiedTag, required this.awaitingTag, required this.rejectionReason, this.isVideo = false});

  final String title;
  final String? url;
  final TagUser verifiedTag;
  final TagUser awaitingTag;
  final String? rejectionReason;
  final bool isVideo;
}

class UAdminPaymentUserPage extends StatefulWidget {
  const UAdminPaymentUserPage({super.key});

  static UAdminModule module({List<TagUser>? roles}) => UAdminModule(
    title: U.s.usersManagement,
    icon: Icons.manage_accounts_rounded,
    page: () => const UAdminPaymentUserPage(),
    roles: roles,
  );

  @override
  State<UAdminPaymentUserPage> createState() => _UAdminPaymentUserPageState();
}

class _UAdminPaymentUserPageState extends State<UAdminPaymentUserPage> {
  final UAdminPaymentUserController c = UAdminPaymentUserController();

  @override
  void initState() {
    c.init();
    super.initState();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: U.s.usersManagement,
    onFilter: _filter,
    onCreate: U.user.hasPermission(TagUser.permissionManageUsers) ? _form : null,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: UAdminListView<UUserResponse>(
      state: c.state,
      items: () => c.list,
      totalCount: () => c.totalCount,
      onRetry: c.read,
      emptyText: U.s.noItemsFound(U.s.users),
      desktopHeader: () => <Widget>[
        UAdminTable.headerCell(U.s.name),
        UAdminTable.headerCell(U.s.username),
        UAdminTable.headerCell(U.s.phoneNumber),
        UAdminTable.headerCell(U.s.nationalCode),
        UAdminTable.headerCell(U.s.verificationStatus),
        UAdminTable.headerCell(U.s.joinedDate),
        UAdminTable.headerCell(U.s.operations),
      ],
      desktopRow: _itemDesktop,
      mobileRow: _itemMobile,
    ),
  );

  Widget _statusChip(UUserResponse i) {
    final bool verified = i.tags.containsAny(UAdminPaymentUserController.verifiedTags.map((TagUser t) => t.number).toList());
    final bool awaiting = i.tags.containsAny(UAdminPaymentUserController.awaitingTags.map((TagUser t) => t.number).toList());
    final Color color = verified
        ? UAdminTheme.green
        : awaiting
        ? UAdminTheme.orange
        : UAdminTheme.grey;
    final String label = verified
        ? U.s.verified
        : awaiting
        ? U.s.pendingVerification
        : U.s.notUploaded;
    return UContainer(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      color: color.withValues(alpha: 0.15),
      radius: 20,
      child: UTextBodySmall(label, color: color, fontWeight: FontWeight.w600),
    );
  }

  Widget _itemDesktop(UUserResponse i, int index) => URow(
    spacing: 8,
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      UAdminTable.cell("${i.firstName ?? ""} ${i.lastName ?? ""}".trim()),
      UAdminTable.cell(i.userName),
      UTextBodyMedium(i.phoneNumber ?? "-", textAlign: TextAlign.center, textDirection: TextDirection.ltr, expanded: 1),
      UAdminTable.cell(i.nationalCode ?? "-"),
      _statusChip(i).alignAtCenter().expanded(),
      UAdminTable.cell(i.createdAt.toJalaliDate()),
      _menu(i).expanded(),
    ],
  );

  Widget _itemMobile(UUserResponse i, int index) => UAdminTable.mobileCard(
    icon: Icons.person_rounded,
    title: "${i.firstName ?? ""} ${i.lastName ?? ""}".trim().nullIfEmpty() ?? i.userName,
    subtitle: i.userName,
    badge: _statusChip(i),
    onTap: () => _form(i),
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(
        U.s.phoneNumber,
        null,
        valueWidget: UTextBodyMedium(i.phoneNumber ?? "-", textAlign: TextAlign.end, textDirection: TextDirection.ltr, fontWeight: FontWeight.w500),
      ),
      UAdminField(U.s.nationalCode, i.nationalCode ?? "-"),
      UAdminField(U.s.joinedDate, i.createdAt.toJalaliDate()),
    ],
  );

  /// The one user dialog: register a new user, or show an existing user's verification and documents with the edit fields below them.
  Future<void> _form([UUserResponse? user]) {
    c.loadForm(user);
    if (user != null) c.readDetail(user);
    final bool canEdit = U.user.hasPermission(TagUser.permissionManageUsers);
    return UFormDialog.show(
      title: user == null ? U.s.register : user.displayName.nullIfEmpty() ?? user.userName,
      maxWidth: user == null ? 520 : 960,
      onSubmit: user == null || canEdit
          ? () async {
              final bool ok = await c.save();
              if (ok) unawaited(c.read());
              return ok;
            }
          : null,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        if (user != null) ...<Widget>[
          UObx(() {
            if (c.detailState.isError()) {
              return UColumn(
                spacing: 12,
                children: <Widget>[
                  Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                  UTextBodyMedium(U.s.errorReadingData),
                  UButton(title: U.s.tryAgain, onTap: () => c.readDetail(user), width: 160),
                ],
              ).alignAtCenter();
            }
            if (!c.detailState.isLoaded()) return const CircularProgressIndicator().alignAtCenter().pAll(24);
            return UColumn(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: UButton(type: UButtonType.text, title: U.s.downloadData, icon: const Icon(Icons.download_outlined), onTap: c.downloadDetailData),
                ),
                _detailStatusCard(),
                const SizedBox(height: 16),
                if (!canEdit) ...<Widget>[_detailUserInfo(), const SizedBox(height: 16)],
                _detailDocuments(),
                const SizedBox(height: 20),
                URow(
                  children: <Widget>[
                    UButton(title: U.s.approve, icon: const Icon(Icons.check_circle_outline), onTap: c.approveDocuments, expanded: 2),
                    const SizedBox(width: 12),
                    UButton(title: U.s.reject, icon: const Icon(Icons.cancel_outlined), backgroundColor: Theme.of(context).colorScheme.error, onTap: _rejectDocuments, expanded: 1),
                  ],
                ),
              ],
            );
          }),
        ],
        if (user == null || canEdit) ...<Widget>[
            const Divider(height: 20),
            UTextBodySmall(U.s.userInformation, color: UAdminTheme.grey, fontWeight: FontWeight.w700),
            UFieldPair(
              UTextField(controller: c.firstNameController, labelText: U.s.firstName, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
              UTextField(controller: c.lastNameController, labelText: U.s.lastName, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
            ),
            UFieldPair(UTextField(
                controller: c.userNameController,
                labelText: U.s.username,
                readOnly: user != null,
                prefix: const Icon(Icons.alternate_email_rounded, size: 18),
                validator: UValidators.required(message: U.s.required),
              ), UTextField(controller: c.fatherNameController, labelText: U.s.fatherName)),
            UFieldPair(UTextField(
                controller: c.nationalCodeController,
                labelText: U.s.nationalCode,
                keyboardType: TextInputType.number,
                maxLength: 10,
                prefix: const Icon(Icons.badge_outlined, size: 18),
                validator: UValidators.iranianNationalCode(isRequired: false),
              ), UTextFieldDatePicker(
                controller: c.birthDateController,
                labelText: U.s.birthdate,
                jalali: true,
                margin: const EdgeInsets.symmetric(vertical: 6),
                onChange: (DateTime d, UJalali j) {
                  c.birthdate = d;
                  c.birthDateController.text = d.toJalaliDate();
                },
              )),
            UTextField(
              controller: c.passwordController,
              labelText: U.s.password,
              keyboardType: TextInputType.visiblePassword,
              prefix: const Icon(Icons.lock_outline_rounded, size: 18),
              margin: const EdgeInsets.symmetric(vertical: 6),
            ),
            UTextBodySmall(U.s.gender, color: UAdminTheme.grey).alignAtCenterLeft(),
            USegmentedControl<TagUser>(
              selectedValue: c.gender,
              items: <TagUser, String>{TagUser.male: U.s.male, TagUser.female: U.s.female, TagUser.unspecified: TagUser.unspecified.localizedTitle},
              onValueChanged: (TagUser? v) => setState(() => c.gender = v ?? c.gender),
            ).pOnly(top: 6, bottom: 6),
            const Divider(height: 20),
            UTextBodySmall(U.s.contactInformation, color: UAdminTheme.grey, fontWeight: FontWeight.w700),
            UFieldPair(
              UTextFieldPhoneNumber(controller: c.phoneNumberController, labelText: U.s.phoneNumber, required: true),
              UTextFieldPhoneNumber(controller: c.landLineController, labelText: U.s.landline),
            ),
            UTextField(
              controller: c.emailController,
              labelText: U.s.email,
              keyboardType: TextInputType.emailAddress,
              prefix: const Icon(Icons.email_rounded, size: 18),
              validator: UValidators.email(isRequired: false),
              margin: const EdgeInsets.symmetric(vertical: 6),
            ),
            UTextField(controller: c.bioController, labelText: U.s.bio, lines: 3, margin: const EdgeInsets.symmetric(vertical: 6)),
            if (c.canManageRoles) ...<Widget>[
              const Divider(height: 20),
              UTextBodySmall(U.s.roles, color: UAdminTheme.grey, fontWeight: FontWeight.w700),
              USegmentedControl<TagUser>(
                selectedValue: c.role,
                items: <TagUser, String>{TagUser.superAdmin: U.s.admin, TagUser.subAdmin: U.s.subAdmin, TagUser.guest: U.s.guest},
                onValueChanged: (TagUser? v) => setState(() => c.role = v ?? c.role),
              ).pOnly(top: 6, bottom: 6),
              if (c.role == TagUser.subAdmin) ...<Widget>[
                UTextBodySmall(U.s.permissions, color: UAdminTheme.grey).pOnly(top: 6),
                ...TagUser.permissions.map(
                  (TagUser t) => CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(t.localizedTitle),
                    value: c.permissions.contains(t),
                    onChanged: (bool? v) => setState(() => c.togglePermission(t, v ?? false)),
                  ),
                ),
              ],
            ],
        ],
      ],
    );
  }

  List<_Doc> get _detailDocs => <_Doc>[
    _Doc(
      title: U.s.nationalCardFront,
      url: c.detailUser.nationalCardFront,
      verifiedTag: TagUser.nationalCardFrontVerified,
      awaitingTag: TagUser.nationalCardFrontAwaitingVerification,
      rejectionReason: c.detailUser.jsonData.nationalCardFrontRejectionReason,
    ),
    _Doc(
      title: U.s.nationalCardBack,
      url: c.detailUser.nationalCardBack,
      verifiedTag: TagUser.nationalCardBackVerified,
      awaitingTag: TagUser.nationalCardBackAwaitingVerification,
      rejectionReason: c.detailUser.jsonData.nationalCardBackRejectionReason,
    ),
    _Doc(
      title: U.s.birthCertificate,
      url: c.detailUser.birthCertificateFirst,
      verifiedTag: TagUser.birthCertificateFirstVerified,
      awaitingTag: TagUser.birthCertificateFirstAwaitingVerification,
      rejectionReason: c.detailUser.jsonData.birthCertificateFirstRejectionReason,
    ),
    _Doc(
      title: U.s.signature,
      url: c.detailUser.eSignature,
      verifiedTag: TagUser.eSignatureVerified,
      awaitingTag: TagUser.eSignatureAwaitingVerification,
      rejectionReason: c.detailUser.jsonData.eSignatureRejectionReason,
    ),
    _Doc(
      title: U.s.video,
      url: c.detailUser.visualAuthentication,
      verifiedTag: TagUser.visualAuthenticationVerified,
      awaitingTag: TagUser.visualAuthenticationAwaitingVerification,
      rejectionReason: c.detailUser.jsonData.visualAuthenticationRejectionReason,
      isVideo: true,
    ),
  ];

  _DocStatus _detailDocStatus(_Doc d) {
    if (c.detailUser.tags.contains(d.verifiedTag.number)) return _DocStatus.verified;
    if (d.rejectionReason.isNotNullOrEmpty()) return _DocStatus.rejected;
    if (d.url != null) return _DocStatus.awaiting;
    return _DocStatus.missing;
  }

  Widget _detailStatusCard() {
    final bool verified = c.isDetailVerified;
    final Color color = verified ? UAdminTheme.green : UAdminTheme.orange;
    return UContainer(
      padding: const EdgeInsets.all(16),
      gradient: LinearGradient(colors: <Color>[color.withValues(alpha: 0.08), color.withValues(alpha: 0.20)], begin: Alignment.topRight, end: Alignment.bottomLeft),
      radius: 16,
      child: URow(
        children: <Widget>[
          UContainer(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surface,
            radius: 12,
            child: Icon(verified ? Icons.verified_rounded : Icons.pending_actions_rounded, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: UColumn(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                UTextBodySmall(U.s.verificationStatus, color: UAdminTheme.grey),
                const SizedBox(height: 4),
                UTextBodyLarge(verified ? U.s.verified : U.s.pendingVerification, fontWeight: FontWeight.bold, color: color),
              ],
            ),
          ),
          UContainer(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: color.withValues(alpha: 0.18),
            radius: 20,
            child: UTextBodySmall(verified ? U.s.approved : U.s.needsReview, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _detailUserInfo() => UColumn(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      _sectionHeader(U.s.userInformation, Icons.person_outline, UAdminTheme.orange),
      const SizedBox(height: 12),
      DecoratedBox(
        decoration: _cardDecoration(),
        child: UColumn(
          children: <Widget>[
            _infoRow(Icons.person, U.s.username, c.detailUser.userName, UAdminTheme.orange),
            const Divider(height: 1),
            _infoRow(Icons.badge, U.s.firstName, c.detailUser.firstName ?? U.s.notUploaded, UAdminTheme.orange),
            const Divider(height: 1),
            _infoRow(Icons.badge_outlined, U.s.lastName, c.detailUser.lastName ?? U.s.notUploaded, UAdminTheme.orange),
            const Divider(height: 1),
            _infoRow(Icons.card_membership, U.s.nationalCode, c.detailUser.nationalCode ?? U.s.notUploaded, UAdminTheme.orange),
            const Divider(height: 1),
            _infoRow(Icons.phone, U.s.phoneNumber, c.detailUser.phoneNumber ?? U.s.notUploaded, UAdminTheme.orange),
            const Divider(height: 1),
            _infoRow(Icons.email, U.s.email, c.detailUser.email ?? U.s.notUploaded, UAdminTheme.orange),
            const Divider(height: 1),
            _infoRow(Icons.person_2, U.s.fatherName, c.detailUser.jsonData.fatherName ?? U.s.notUploaded, UAdminTheme.orange),
          ],
        ),
      ),
    ],
  );

  Widget _detailDocuments() => UColumn(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      _sectionHeader(U.s.userDocuments, Icons.folder_outlined, UAdminTheme.red),
      const SizedBox(height: 12),
      Wrap(spacing: 12, runSpacing: 12, children: _detailDocs.map(_detailDocumentCard).toList()),
    ],
  );

  Widget _detailDocumentCard(_Doc d) {
    final _DocStatus status = _detailDocStatus(d);
    final bool hasData = d.url != null;
    return SizedBox(
      width: 190,
      child: DecoratedBox(
        decoration: _cardDecoration(),
        child: UColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Stack(
              children: <Widget>[
                UContainer(
                  width: double.infinity,
                  height: 150,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: hasData && !d.isVideo
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: UImage(
                            d.url!,
                            placeholder: UAdmin.logo,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: UColumn(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(d.isVideo ? (hasData ? Icons.play_circle_outline : Icons.videocam_off_outlined) : Icons.insert_drive_file, size: 44, color: UAdminTheme.grey.shade400),
                              const SizedBox(height: 6),
                              UTextBodySmall(hasData ? U.s.videoAvailable : U.s.notUploaded, color: UAdminTheme.grey),
                            ],
                          ),
                        ),
                ),
                Positioned(top: 8, right: 8, child: _detailDocBadge(status)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: UColumn(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  URow(
                    children: <Widget>[
                      Expanded(
                        child: UTextBodySmall(d.title, fontWeight: FontWeight.w600, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      IconButton(
                        onPressed: hasData && !d.isVideo ? () => UNavigator.push(UImageViewer(fileData: UFileData(url: d.url))) : null,
                        icon: Icon(Icons.zoom_out_map, size: 18, color: hasData && !d.isVideo ? UAdminTheme.blue.shade700 : UAdminTheme.grey.shade400),
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

  Widget _detailDocBadge(_DocStatus status) {
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
    return UContainer(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: color,
      radius: 20,
      child: URow(
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
    leading: UContainer(
      padding: const EdgeInsets.all(8),
      color: color.withValues(alpha: 0.1),
      radius: 10,
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
    children: <Widget>[
      UContainer(
        padding: const EdgeInsets.all(8),
        color: color.withValues(alpha: 0.1),
        radius: 10,
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

  void _rejectDocuments() {
    c.loadRejectForm();
    UFormDialog.show(
      title: U.s.rejectDocuments,
      onSubmit: c.rejectDocuments,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UTextField(controller: c.frontReasonController, labelText: U.s.reasonForRejectingItem(U.s.nationalCardFront), margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.backReasonController, labelText: U.s.reasonForRejectingItem(U.s.nationalCardBack), margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.birthReasonController, labelText: U.s.reasonForRejectingItem(U.s.birthCertificate), margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.videoReasonController, labelText: U.s.reasonForRejectingItem(U.s.video), margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.signatureReasonController, labelText: U.s.reasonForRejectingItem(U.s.signature), margin: const EdgeInsets.symmetric(vertical: 6)),
      ],
    );
  }

  Widget _menu(UUserResponse i) => UPopupMenu(
    items: <UPopupMenuItem>[
      UPopupMenuItem(label: U.s.viewItem(U.s.details), icon: Icons.visibility_outlined, onTap: () => _form(i)),
      UPopupMenuItem(label: U.s.merchants, icon: Icons.storefront_outlined, onTap: () => UAdminPaymentMerchantPage.module(user: i).open()),
      UPopupMenuItem(label: U.s.contracts, icon: Icons.description_outlined, onTap: () => UAdminHotelContractPage.module(user: i).open()),
      UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionDeleteUsers]), onTap: () => c.delete(i)),
    ],
  );

  void _filter() => UFilterDialog.show(
    title: U.s.filterItem(U.s.users),
    onApply: c.applyFilters,
    onClear: c.clearFilters,
    children: (StateSetter setState) => <Widget>[
      UDropDownField<TagUser?>(
        initialValue: c.verificationStatus,
        onChanged: (TagUser? v) => c.verificationStatus = v,
        items: <DropdownMenuItem<TagUser?>>[
          DropdownMenuItem<TagUser>(value: TagUser.verified, child: Text(TagUser.verified.localizedTitle)),
          DropdownMenuItem<TagUser>(value: TagUser.awaitingVerification, child: Text(TagUser.awaitingVerification.localizedTitle)),
          const DropdownMenuItem<TagUser?>(child: Text("---")),
        ],
      ).pSymmetric(vertical: 6),
      UTextField(controller: c.firstNameFilterController, labelText: U.s.firstName, margin: const EdgeInsets.symmetric(vertical: 6)),
      UTextField(controller: c.lastNameFilterController, labelText: U.s.lastName, margin: const EdgeInsets.symmetric(vertical: 6)),
      UTextField(controller: c.userNameFilterController, labelText: U.s.username, margin: const EdgeInsets.symmetric(vertical: 6)),
      UTextFieldPhoneNumber(controller: c.phoneNumberFilterController, labelText: U.s.phoneNumber, margin: const EdgeInsets.symmetric(vertical: 6)),
      UTextField(controller: c.nationalCodeFilterController, labelText: U.s.nationalCode, margin: const EdgeInsets.symmetric(vertical: 6)),
      UTextField(controller: c.emailFilterController, labelText: U.s.email, margin: const EdgeInsets.symmetric(vertical: 6)),
      UTextFieldPhoneNumber(controller: c.landLineFilterController, labelText: U.s.landline, margin: const EdgeInsets.symmetric(vertical: 6)),
      UTextField(controller: c.bioFilterController, labelText: U.s.bio, margin: const EdgeInsets.symmetric(vertical: 6)),
      UTextFieldDatePicker(
        controller: c.startDateController,
        labelText: U.s.fromDate,
        jalali: true,
        margin: const EdgeInsets.symmetric(vertical: 6),
        onChange: (DateTime d, UJalali j) {
          c.startDate = d;
          c.startDateController.text = d.toJalaliDate();
        },
      ),
      UTextFieldDatePicker(
        controller: c.endDateController,
        labelText: U.s.toDate,
        jalali: true,
        margin: const EdgeInsets.symmetric(vertical: 6),
        onChange: (DateTime d, UJalali j) {
          c.endDate = d;
          c.endDateController.text = d.toJalaliDate();
        },
      ),
      UTextFieldDatePicker(
        controller: c.fromBirthController,
        labelText: U.s.fromBirthDate,
        jalali: true,
        margin: const EdgeInsets.symmetric(vertical: 6),
        onChange: (DateTime d, UJalali j) {
          c.fromBirthDate = d;
          c.fromBirthController.text = d.toJalaliDate();
        },
      ),
      UTextFieldDatePicker(
        controller: c.toBirthController,
        labelText: U.s.toBirthDate,
        jalali: true,
        margin: const EdgeInsets.symmetric(vertical: 6),
        onChange: (DateTime d, UJalali j) {
          c.toBirthDate = d;
          c.toBirthController.text = d.toJalaliDate();
        },
      ),
    ],
  );
}
