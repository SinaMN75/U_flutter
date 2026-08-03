import "package:u/utilities.dart";

class UAdminUsersPage extends StatefulWidget {
  const UAdminUsersPage({super.key, this.actions});

  final UAdminActionBuilder<UUserResponse>? actions;

  @override
  State<UAdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<UAdminUsersPage> {
  final UAdminPaymentUsersController c = UAdminPaymentUsersController();

  @override
  void initState() {
    c.init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: U.s.usersManagement,
    onFilter: _showFilterDialog,
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
      emptyText: U.s.noUserFound,
      desktopHeader: () => UAdminTable.header(
        <String>[
          U.s.name,
          U.s.username,
          U.s.phoneNumber,
          U.s.nationalCode,
          U.s.verificationStatus,
          U.s.joinedDate,
          U.s.operations,
        ],
      ),
      desktopRow: _itemDesktop,
      mobileRow: _itemResponsive,
    ),
  );

  Widget _statusChip(UUserResponse i) {
    final bool verified = i.tags.containsAny(
      <int>[
        TagUser.nationalCardFrontVerified.number,
        TagUser.nationalCardBackVerified.number,
        TagUser.birthCertificateFirstVerified.number,
        TagUser.eSignatureVerified.number,
        TagUser.visualAuthenticationVerified.number,
      ],
    );
    final bool awaiting = i.tags.containsAny(
      <int>[
        TagUser.nationalCardFrontAwaitingVerification.number,
        TagUser.nationalCardBackAwaitingVerification.number,
        TagUser.birthCertificateFirstAwaitingVerification.number,
        TagUser.eSignatureAwaitingVerification.number,
        TagUser.visualAuthenticationAwaitingVerification.number,
      ],
    );
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
      child: UTextBodySmall(label, color: color, fontWeight: FontWeight.w600),
    );
  }

  Widget _itemDesktop(UUserResponse i, int index) => URow(
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      UAdminTable.cell("${i.firstName ?? ""} ${i.lastName ?? ""}".trim()),
      UAdminTable.cell(i.userName),
      UTextBodyMedium(i.phoneNumber ?? "-", textAlign: TextAlign.center, textDirection: TextDirection.ltr).expanded(),
      UAdminTable.cell(i.nationalCode ?? "-"),
      _statusChip(i).alignAtCenter().expanded(),
      UAdminTable.cell(i.createdAt.toJalaliDate()),
      _menu(i).expanded(),
    ],
  );

  Widget _itemResponsive(UUserResponse i, int index) => UAdminTable.mobileCard(
    context,
    icon: Icons.person_rounded,
    title: "${i.firstName ?? ""} ${i.lastName ?? ""}".trim().nullIfEmpty() ?? i.userName,
    subtitle: i.userName,
    badge: _statusChip(i),
    onTap: () => UAdminPageSwitcher.adminUserDetail(user: i),
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.phoneNumber, null, valueWidget: UTextBodyMedium(i.phoneNumber ?? "-", textAlign: TextAlign.end, textDirection: TextDirection.ltr, fontWeight: FontWeight.w500)),
      UAdminField(U.s.nationalCode, i.nationalCode ?? "-"),
      UAdminField(U.s.joinedDate, i.createdAt.toJalaliDate()),
    ],
  );

  Widget _menu(UUserResponse i) => UAdminOps.menu<UUserResponse>(
    context,
    item: i,
    actions: widget.actions,
    handlers: UAdminActionHandlers<UUserResponse>(onDelete: c.delete),
    fallback: (UAdminActionContext<UUserResponse> ctx) => <UAdminAction>[
      UAdminLinks.adminUserDetail(ctx.item),
      UAdminLinks.userMerchants(ctx.item),
      UAdminLinks.userContracts(ctx.item),
      ctx.delete(roles: <TagUser>[TagUser.permissionDeleteUsers]),
    ],
  );

  void _showFilterDialog() => UNavigator.dialog(
    AlertDialog(
      title: Text(U.s.filterUsers),
      content: SizedBox(
        width: context.dialogWidth(),
        child: SingleChildScrollView(
          child: UColumn(
            spacing: 0,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Obx(
                () => UDropDownField<TagUser?>(
                  initialValue: c.verificationStatus.value,
                  onChanged: c.verificationStatus.call,
                  items: <DropdownMenuItem<TagUser?>>[
                    DropdownMenuItem<TagUser>(value: TagUser.verified, child: Text(TagUser.verified.localizedTitle)),
                    DropdownMenuItem<TagUser>(value: TagUser.awaitingVerification, child: Text(TagUser.awaitingVerification.localizedTitle)),
                    const DropdownMenuItem<TagUser?>(child: Text("---")),
                  ],
                ),
              ).pSymmetric(vertical: 6),
              UTextField(controller: c.firstNameFilterController, labelText: U.s.firstName).pSymmetric(vertical: 6),
              UTextField(controller: c.lastNameFilterController, labelText: U.s.lastName).pSymmetric(vertical: 6),
              UTextField(controller: c.userNameFilterController, labelText: U.s.username).pSymmetric(vertical: 6),
              UTextField(controller: c.phoneNumberFilterController, labelText: U.s.phoneNumber, keyboardType: TextInputType.phone).pSymmetric(vertical: 6),
              UTextField(controller: c.nationalCodeFilterController, labelText: U.s.nationalCode).pSymmetric(vertical: 6),
              UTextField(controller: c.emailFilterController, labelText: U.s.email, keyboardType: TextInputType.emailAddress).pSymmetric(vertical: 6),
              UTextField(controller: c.landLineFilterController, labelText: U.s.landline).pSymmetric(vertical: 6),
              UTextField(controller: c.bioFilterController, labelText: U.s.bio).pSymmetric(vertical: 6),
              UTextFieldDatePicker(
                jalali: true,
                controller: c.fromCreatedController,
                labelText: U.s.fromDate,
                onChange: (DateTime d, Jalali j) {
                  c.fromCreatedController.text = j.formatCompactDate();
                  c.fromCreatedAt = d;
                },
              ).pSymmetric(vertical: 6),
              UTextFieldDatePicker(
                jalali: true,
                controller: c.toCreatedController,
                labelText: U.s.toDate,
                onChange: (DateTime d, Jalali j) {
                  c.toCreatedController.text = j.formatCompactDate();
                  c.toCreatedAt = d;
                },
              ).pSymmetric(vertical: 6),
              UTextFieldDatePicker(
                jalali: true,
                controller: c.fromBirthController,
                labelText: U.s.fromBirthDate,
                onChange: (DateTime d, Jalali j) {
                  c.fromBirthController.text = j.formatCompactDate();
                  c.fromBirthDate = d;
                },
              ).pSymmetric(vertical: 6),
              UTextFieldDatePicker(
                jalali: true,
                controller: c.toBirthController,
                labelText: U.s.toBirthDate,
                onChange: (DateTime d, Jalali j) {
                  c.toBirthController.text = j.formatCompactDate();
                  c.toBirthDate = d;
                },
              ).pSymmetric(vertical: 6),
              const SizedBox(height: 20),
              UButtonSubmitCancel(
                submitTitle: U.s.filter,
                cancelTitle: U.s.clearFilters,
                onSubmit: () {
                  c.applyFilters();
                  UNavigator.back();
                },
                onCancel: () {
                  c.clearFilters();
                  UNavigator.back();
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
