import "package:u/u_admin/pages/hotel/users/u_admin_user_create_update_controller.dart";
import "package:u/utilities.dart";

class UAdminUserCreateUpdateDialog extends StatefulWidget {
  const UAdminUserCreateUpdateDialog({this.user, super.key});

  final UUserResponse? user;

  static Future<void> show({UUserResponse? user}) => UNavigator.dialog<void>(UAdminUserCreateUpdateDialog(user: user));

  @override
  State<UAdminUserCreateUpdateDialog> createState() => _UserCreateUpdateDialogState();
}

class _UserCreateUpdateDialogState extends State<UAdminUserCreateUpdateDialog> {
  final UAdminUserCreateUpdateController c = UAdminUserCreateUpdateController();

  bool get _canManageRoles => U.user.isFullAdmin();

  bool get _isEdit => widget.user != null;

  bool get _isFa => ULocalStorage.getLocale() == "fa";

  late Set<TagUser> _selectedPermissions;

  @override
  void initState() {
    c.init(args: UAdminUserCreateUpdateArgs(user: widget.user));
    final List<int> existingTags = widget.user?.tags ?? <int>[];
    _selectedPermissions = TagUser.permissions.where((TagUser t) => existingTags.contains(t.number)).toSet();
    if (widget.user?.isSubAdmin() ?? false) c.role(TagUser.subAdmin);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: URow(
      spacing: 0,
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
      width: 440,
      child: Form(
        key: c.formKey,
        child: SingleChildScrollView(
          child: UColumn(
            spacing: 0,
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
                      UAdminPageSwitcher.hotelUserDetail(user: widget.user!);
                    },
                  ),
                ),
              URow(
                spacing: 0,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  UTextField(
                    controller: c.controllerFirstName,
                    labelText: U.s.firstName,
                    validator: UValidators.required(message: U.s.required),
                  ).expanded(),
                  const SizedBox(width: 10),
                  UTextField(
                    controller: c.controllerLastName,
                    labelText: U.s.lastName,
                    validator: UValidators.required(message: U.s.required),
                  ).expanded(),
                ],
              ).pSymmetric(vertical: 6),
              UTextField(
                controller: c.controllerUserName,
                labelText: U.s.username,
                readOnly: _isEdit,
                prefix: const Icon(Icons.alternate_email_rounded, size: 18),
                validator: UValidators.required(message: U.s.required),
              ).pSymmetric(vertical: 6),
              UTextField(
                controller: c.controllerFatherName,
                labelText: U.s.fatherName,
                validator: UValidators.required(message: U.s.required),
              ).pSymmetric(vertical: 6),
              UTextField(
                controller: c.controllerPhoneNumber,
                labelText: U.s.phoneNumber,
                keyboardType: TextInputType.phone,
                prefix: const Icon(Icons.phone_rounded, size: 18),
                validator: UValidators.required(message: U.s.required),
              ).pSymmetric(vertical: 6),
              UTextField(
                controller: c.controllerEmail,
                labelText: U.s.email,
                keyboardType: TextInputType.emailAddress,
                prefix: const Icon(Icons.email_rounded, size: 18),
              ).pSymmetric(vertical: 6),
              UTextFieldDatePicker(
                jalali: true,
                controller: c.controllerBirthDate,
                labelText: U.s.birthdate,
                validator: UValidators.required(message: U.s.required),
                onChange: (DateTime d, Jalali j) {
                  c.birthdate = d;
                  c.controllerBirthDate.text = d.toJalaliDate();
                },
              ).pSymmetric(vertical: 6),
              UTextField(
                controller: c.controllerPassword,
                labelText: U.s.password,
                keyboardType: TextInputType.visiblePassword,
                prefix: const Icon(Icons.lock_outline_rounded, size: 18),
              ).pSymmetric(vertical: 6),
              const Divider(height: 20),
              UTextBodySmall(U.s.gender, color: UAdminTheme.grey).alignAtCenterLeft(),
              Obx(
                () => USegmentedControl<int>(
                  selectedValue: c.gender.value.number,
                  items: <int, String>{TagUser.male.number: U.s.male, TagUser.female.number: U.s.female},
                  onValueChanged: (int? i) => c.gender(TagUser.values.fromNumber(i!) ?? c.gender.value),
                ).pOnly(top: 6, bottom: 6),
              ),
              if (_canManageRoles) ...<Widget>[
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
                    spacing: 0,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: 6),
                      UTextBodySmall(U.s.permissions, color: UAdminTheme.grey),
                      ...TagUser.permissions.map(
                        (TagUser permission) => CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(_isFa ? permission.titleFa : permission.titleEn),
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

  void _submit() {
    if (!_isEdit) {
      c.create(
        formKey: c.formKey,
        p: UUserCreateParams(
          firstName: c.controllerFirstName.text,
          lastName: c.controllerLastName.text,
          password: c.controllerPassword.text,
          email: c.controllerEmail.text.toLatinNumber(),
          phoneNumber: c.controllerPhoneNumber.numString(),
          userName: c.controllerUserName.text.numberString(),
          birthdate: c.birthdate,
          fatherName: c.controllerFatherName.text,
          tags: <int>[
            c.gender.value.number,
            if (_canManageRoles) c.role.value.number,
            if (_canManageRoles && c.role.value == TagUser.subAdmin) ..._selectedPermissions.map((TagUser t) => t.number),
          ],
        ),
      );
      return;
    }
    final List<int> roleTagNumbers = <int>[TagUser.superAdmin.number, TagUser.subAdmin.number, TagUser.guest.number];
    final List<int> addTags = <int>[c.gender.value.number];
    final List<int> removeTags = <int>[c.gender.value == TagUser.male ? TagUser.female.number : TagUser.male.number];
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
        password: c.controllerPassword.text,
        email: c.controllerEmail.text.toLatinNumber(),
        phoneNumber: c.controllerPhoneNumber.numString(),
        userName: c.controllerUserName.numString(),
        birthdate: c.birthdate,
        fatherName: c.controllerFatherName.text,
        addTags: addTags,
        removeTags: removeTags,
      ),
    );
  }
}
