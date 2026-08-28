import "package:u/u_admin/pages/payments/users/u_admin_payment_user_create_update_controller.dart";
import "package:u/utilities.dart";

class UAdminPaymentUserCreateUpdateDialog extends StatefulWidget {
  const UAdminPaymentUserCreateUpdateDialog({this.user, super.key});

  final UUserResponse? user;

  static Future<void> show({UUserResponse? user}) => UNavigator.dialog<void>(UAdminPaymentUserCreateUpdateDialog(user: user));

  @override
  State<UAdminPaymentUserCreateUpdateDialog> createState() => _PaymentUserCreateUpdateDialogState();
}

class _PaymentUserCreateUpdateDialogState extends State<UAdminPaymentUserCreateUpdateDialog> {
  final UAdminPaymentUserCreateUpdateController c = UAdminPaymentUserCreateUpdateController();

  bool get _canManageRoles => U.user.isFullAdmin();

  bool get _isEdit => widget.user != null;
  late Set<TagUser> _selectedPermissions;

  @override
  void initState() {
    c.init(args: UAdminPaymentUserCreateUpdateArgs(user: widget.user));
    final List<int> existingTags = widget.user?.tags ?? <int>[];
    _selectedPermissions = TagUser.permissions.where((TagUser t) => existingTags.contains(t.number)).toSet();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: URow(
      children: <Widget>[
        Icon(_isEdit ? Icons.manage_accounts_rounded : Icons.person_add_alt_1_rounded, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: UTextTitleSmall(_isEdit ? "${U.s.edit} · ${widget.user!.displayName}" : U.s.register, fontWeight: FontWeight.w700, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
    contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
    content: SizedBox(
      width: context.dialogWidth(max: 520),
      child: Form(
        key: c.formKey,
        child: SingleChildScrollView(
          child: UColumn(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_isEdit)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: UButton(
                    type: UButtonType.text,
                    title: U.s.userDetails,
                    icon: const Icon(Icons.link_rounded, size: 18),
                    onTap: () {
                      UNavigator.back();
                      UAdminPageSwitcher.adminUserDetail(user: widget.user!);
                    },
                  ),
                ),
              _sectionTitle(U.s.userInformation),
              _pair(
                UTextField(
                  controller: c.controllerFirstName,
                  labelText: U.s.firstName,
                  validator: UValidators.required(message: U.s.required),
                ),
                UTextField(
                  controller: c.controllerLastName,
                  labelText: U.s.lastName,
                  validator: UValidators.required(message: U.s.required),
                ),
              ),
              _pair(
                UTextField(
                  controller: c.controllerUserName,
                  labelText: U.s.username,
                  readOnly: _isEdit,
                  prefix: const Icon(Icons.alternate_email_rounded, size: 18),
                  validator: UValidators.required(message: U.s.required),
                ),
                UTextField(controller: c.controllerFatherName, labelText: U.s.fatherName),
              ),
              _pair(
                UTextField(
                  controller: c.controllerNationalCode,
                  labelText: U.s.nationalCode,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  prefix: const Icon(Icons.badge_outlined, size: 18),
                  validator: UValidators.iranianNationalCode(isRequired: false),
                ),
                UTextFieldDatePicker(
                  jalali: true,
                  controller: c.controllerBirthDate,
                  labelText: U.s.birthdate,
                  onChange: (DateTime d, Jalali j) {
                    c.birthdate = d;
                    c.controllerBirthDate.text = d.toJalaliDate();
                  },
                ),
              ),
              UTextField(
                controller: c.controllerPassword,
                labelText: U.s.password,
                keyboardType: TextInputType.visiblePassword,
                prefix: const Icon(Icons.lock_outline_rounded, size: 18),
                margin: const EdgeInsets.symmetric(vertical: 6),
              ),
              UTextBodySmall(U.s.gender, color: UAdminTheme.grey).alignAtCenterLeft(),
              Obx(
                () => USegmentedControl<int>(
                  selectedValue: c.gender.value.number,
                  items: <int, String>{
                    TagUser.male.number: U.s.male,
                    TagUser.female.number: U.s.female,
                    TagUser.unspecified.number: TagUser.unspecified.localizedTitle,
                  },
                  onValueChanged: (int? i) => c.gender(TagUser.values.fromNumber(i!) ?? c.gender.value),
                ).pOnly(top: 6, bottom: 6),
              ),
              _sectionTitle(U.s.contactInformation),
              _pair(
                UTextField(
                  controller: c.controllerPhoneNumber,
                  labelText: U.s.phoneNumber,
                  keyboardType: TextInputType.phone,
                  prefix: const Icon(Icons.phone_rounded, size: 18),
                  validator: UValidators.required(message: U.s.required),
                ),
                UTextField(
                  controller: c.controllerLandLine,
                  labelText: U.s.landline,
                  keyboardType: TextInputType.phone,
                  prefix: const Icon(Icons.phone_in_talk_outlined, size: 18),
                ),
              ),
              UTextField(
                controller: c.controllerEmail,
                labelText: U.s.email,
                keyboardType: TextInputType.emailAddress,
                prefix: const Icon(Icons.email_rounded, size: 18),
                validator: UValidators.email(isRequired: false),
                margin: const EdgeInsets.symmetric(vertical: 6),
              ),
              UTextField(controller: c.controllerBio, labelText: U.s.bio, lines: 3, margin: const EdgeInsets.symmetric(vertical: 6)),
              if (_canManageRoles) ...<Widget>[
                _sectionTitle(U.s.roles),
                Obx(
                  () => USegmentedControl<int>(
                    selectedValue: c.role.value.number,
                    items: <int, String>{
                      TagUser.superAdmin.number: U.s.admin,
                      TagUser.subAdmin.number: U.s.subAdmin,
                      TagUser.guest.number: U.s.guest,
                    },
                    onValueChanged: (int? i) => c.role(TagUser.values.fromNumber(i!) ?? c.role.value),
                  ).pOnly(top: 6, bottom: 6),
                ),
                Obx(() {
                  if (c.role.value != TagUser.subAdmin) return const SizedBox.shrink();
                  return UColumn(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: 6),
                      UTextBodySmall(U.s.permissions, color: UAdminTheme.grey),
                      ...TagUser.permissions.map(
                        (TagUser permission) => CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(permission.localizedTitle),
                          value: _selectedPermissions.contains(permission),
                          onChanged: (bool? checked) => setState(() {
                            if (checked ?? false) {
                              _selectedPermissions.add(permission);
                            } else {
                              _selectedPermissions.remove(permission);
                            }
                          }),
                        ),
                      ),
                    ],
                  );
                }),
              ],
              const SizedBox(height: 16),
              UButtonSubmitCancel(onSubmit: _submit, onCancel: UNavigator.back),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _sectionTitle(String title) => UColumn(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const Divider(height: 20),
      UTextBodySmall(title, color: UAdminTheme.grey, fontWeight: FontWeight.w700),
    ],
  );

  Widget _pair(Widget first, Widget second) => context.isMobileWidth
      ? UColumn(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          margin: const EdgeInsets.symmetric(vertical: 6),
          children: <Widget>[first, second],
        )
      : URow(
          crossAxisAlignment: CrossAxisAlignment.start,
          margin: const EdgeInsets.symmetric(vertical: 6),
          children: <Widget>[first.expanded(), const SizedBox(width: 10), second.expanded()],
        );

  void _submit() {
    if (!_isEdit) {
      c.create(
        formKey: c.formKey,
        p: UUserCreateParams(
          firstName: c.controllerFirstName.text,
          lastName: c.controllerLastName.text,
          userName: c.controllerUserName.trimmedLatin(),
          password: c.controllerPassword.trimmedLatin(),
          fatherName: c.controllerFatherName.text.nullIfEmpty(),
          nationalCode: c.controllerNationalCode.valueOrNull()?.toLatinNumber(),
          birthdate: c.birthdate,
          phoneNumber: c.controllerPhoneNumber.trimmedLatin(),
          landLine: c.controllerLandLine.valueOrNull()?.toLatinNumber(),
          email: c.controllerEmail.trimmedLatin().nullIfEmpty(),
          bio: c.controllerBio.valueOrNull(),
          tags: <int>[
            c.gender.value.number,
            if (_canManageRoles) c.role.value.number,
            if (_canManageRoles && c.role.value == TagUser.subAdmin) ..._selectedPermissions.map((TagUser t) => t.number),
          ],
        ),
      );
      return;
    }
    final List<int> genderTagNumbers = <int>[TagUser.male.number, TagUser.female.number, TagUser.unspecified.number];
    final List<int> roleTagNumbers = <int>[TagUser.superAdmin.number, TagUser.subAdmin.number, TagUser.guest.number];
    final List<int> addTags = <int>[c.gender.value.number];
    final List<int> removeTags = genderTagNumbers.where((int n) => n != c.gender.value.number).toList();
    if (_canManageRoles) {
      addTags.add(c.role.value.number);
      removeTags.addAll(roleTagNumbers.where((int n) => n != c.role.value.number));
      if (c.role.value == TagUser.subAdmin) {
        addTags.addAll(_selectedPermissions.map((TagUser t) => t.number));
        removeTags.addAll(TagUser.permissions.where((TagUser t) => !_selectedPermissions.contains(t)).map((TagUser t) => t.number));
      } else {
        removeTags.addAll(TagUser.permissions.map((TagUser t) => t.number));
      }
    }
    c.update(
      formKey: c.formKey,
      p: UUserUpdateParams(
        id: widget.user!.id,
        firstName: c.controllerFirstName.text,
        lastName: c.controllerLastName.text,
        userName: c.controllerUserName.trimmedLatin(),
        password: c.controllerPassword.text.nullIfEmpty(),
        fatherName: c.controllerFatherName.text.nullIfEmpty(),
        nationalCode: c.controllerNationalCode.valueOrNull()?.toLatinNumber(),
        birthdate: c.birthdate,
        phoneNumber: c.controllerPhoneNumber.numString(),
        landLine: c.controllerLandLine.valueOrNull()?.toLatinNumber(),
        email: c.controllerEmail.text.toLatinNumber().nullIfEmpty(),
        bio: c.controllerBio.valueOrNull(),
        addTags: addTags,
        removeTags: removeTags,
      ),
    );
  }
}
