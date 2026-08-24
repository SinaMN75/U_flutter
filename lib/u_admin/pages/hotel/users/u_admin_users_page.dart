import "package:u/utilities.dart";

class UAdminUserPage extends StatefulWidget {
  const UAdminUserPage({required this.args, super.key});

  final UAdminUsersPageArgs args;

  @override
  State<UAdminUserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UAdminUserPage> {
  final UAdminUsersController c = UAdminUsersController();

  @override
  void initState() {
    c.init(args: widget.args);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(
      title: Text(U.s.usersManagement),
      actions: <Widget>[
        IconButton(icon: const Icon(Icons.filter_alt), onPressed: _showFilterDialog),
        if (U.user.hasPermission(TagUser.permissionManageUsers))
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => UAdminPageSwitcher.userCreateUpdate().then((_) => c.read()),
          ),
      ],
    ),
    body: UColumn(
      spacing: 0,
      children: <Widget>[
        buildUserList().expanded(),
        Obx(
          () => UNumberPagination(
            currentPage: c.pageNumber.value,
            totalPages: c.totalPages.value,
            onPageChanged: (int page) {
              c.pageNumber(page);
              c.read();
            },
          ).pOnly(bottom: 16, top: 8),
        ),
      ],
    ),
  );

  Widget buildUserList() => Obx(() {
    if (c.state.isError()) return Center(child: Text(U.s.errorReadingData));
    if (c.state.isEmpty()) return Center(child: Text(U.s.noItemsFound(U.s.user)));
    if (!c.state.isLoaded()) return const Center(child: CircularProgressIndicator());
    if (MediaQuery.sizeOf(context).width >= 800) {
      return UListView(
        header: URow(
          color: Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.all(8),
          children: <Widget>[
            UTextBodyLarge(U.s.gender, color: UAdminTheme.white, textAlign: .center).expanded(),
            UTextBodyLarge(U.s.name, color: UAdminTheme.white, textAlign: .center).expanded(),
            UTextBodyLarge(U.s.username, color: UAdminTheme.white, textAlign: .center).expanded(),
            UTextBodyLarge(U.s.phoneNumber, color: UAdminTheme.white, textAlign: .center).expanded(),
            UTextBodyLarge(U.s.email, color: UAdminTheme.white, textAlign: .center).expanded(),
            UTextBodyLarge(U.s.joinedDate, color: UAdminTheme.white, textAlign: .center).expanded(),
            UTextBodyLarge(U.s.operations, color: UAdminTheme.white, textAlign: .center).expanded(),
          ],
        ),
        itemBuilder: (BuildContext context, int index) => _listItemDesktop(i: c.list[index], index: index),
        itemCount: c.list.length,
      );
    } else {
      return UListView(
        itemBuilder: (BuildContext context, int index) => _listItemResponsive(i: c.list[index], index: index),
        itemCount: c.list.length,
      );
    }
  });

  void _showFilterDialog() => UNavigator.dialog(
    AlertDialog(
      title: Text(U.s.filterItem(U.s.users)),
      content: Form(
        key: c.filterFormKey,
        child: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (BuildContext context, void Function(void Function()) setLocal) => UColumn(
              spacing: 0,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                UTextField(controller: c.queryController, labelText: U.s.search, prefix: const Icon(Icons.search)).pSymmetric(vertical: 8),
                UTextField(controller: c.userNameController, labelText: U.s.username).pSymmetric(vertical: 8),
                UTextField(controller: c.phoneNumberController, labelText: U.s.phoneNumber, keyboardType: TextInputType.phone).pSymmetric(vertical: 8),
                UTextField(controller: c.emailController, labelText: U.s.email, keyboardType: TextInputType.emailAddress).pSymmetric(vertical: 8),
                UTextField(controller: c.firstNameController, labelText: U.s.firstName).pSymmetric(vertical: 8),
                UTextField(controller: c.lastNameController, labelText: U.s.lastName).pSymmetric(vertical: 8),
                UTextField(controller: c.nationalCodeController, labelText: U.s.nationalCode, keyboardType: TextInputType.number).pSymmetric(vertical: 8),
                DropdownButtonFormField<TagUser?>(
                  decoration: InputDecoration(labelText: U.s.gender, border: const OutlineInputBorder()),
                  isExpanded: true,
                  initialValue: c.selectedGender,
                  items: <DropdownMenuItem<TagUser?>>[
                    DropdownMenuItem<TagUser?>(child: Text(U.s.all)),
                    DropdownMenuItem<TagUser?>(value: TagUser.male, child: Text(U.s.male)),
                    DropdownMenuItem<TagUser?>(value: TagUser.female, child: Text(U.s.female)),
                  ],
                  onChanged: (TagUser? value) => setLocal(() => c.selectedGender = value),
                ).pSymmetric(vertical: 8),
                UTextFieldDatePicker(
                  jalali: true,
                  controller: c.fromCreatedAtController,
                  labelText: U.s.fromDate,
                  onChange: (DateTime d, Jalali j) {
                    c.fromCreatedAtController.text = j.formatCompactDate();
                    c.fromCreatedAt = d;
                  },
                ).pSymmetric(vertical: 8),
                UTextFieldDatePicker(
                  jalali: true,
                  controller: c.toCreatedAtController,
                  labelText: U.s.toDate,
                  onChange: (DateTime d, Jalali j) {
                    c.toCreatedAtController.text = j.formatCompactDate();
                    c.toCreatedAt = d;
                  },
                ).pSymmetric(vertical: 8),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(labelText: U.s.createdDate, border: const OutlineInputBorder()),
                  isExpanded: true,
                  items: <DropdownMenuItem<int>>[
                    DropdownMenuItem<int>(value: 0, child: Text(U.s.accenting)),
                    DropdownMenuItem<int>(value: 1, child: Text(U.s.descending)),
                  ],
                  onChanged: (int? i) => setLocal(() {
                    c.orderByCreatedAt = i == 0;
                    c.orderByCreatedAtDesc = i == 1;
                  }),
                  initialValue: c.orderByCreatedAtDesc ? 1 : 0,
                ).pSymmetric(vertical: 8),
                DropdownButtonFormField<TagUser>(
                  decoration: InputDecoration(labelText: U.s.tags, border: const OutlineInputBorder()),
                  isExpanded: true,
                  items: TagUser.values.map((TagUser tag) => DropdownMenuItem<TagUser>(value: tag, child: Text(c.isFa ? tag.titleFa : tag.titleEn))).toList(),
                  onChanged: (TagUser? value) => setLocal(() => c.selectedTag = value),
                  initialValue: c.selectedTag,
                ).pSymmetric(vertical: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(U.s.verified),
                  value: c.verifiedOnly,
                  onChanged: (bool v) => setLocal(() => c.verifiedOnly = v),
                ),
                const SizedBox(height: 20),
                UButtonSubmitCancel(
                  submitTitle: U.s.filter,
                  cancelTitle: U.s.clearFilters,
                  onSubmit: () {
                    if (c.filterFormKey.currentState?.validate() ?? false) {
                      c.applyFilters();
                      UNavigator.back();
                    }
                  },
                  onCancel: () {
                    c.clearFilters();
                    c.filterFormKey.currentState?.reset();
                    UNavigator.back();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _roleChip(UUserResponse i) {
    final String label = i.isFullAdmin()
        ? U.s.admin
        : i.isSubAdmin()
        ? U.s.subAdmin
        : i.tags.contains(TagUser.guest.number)
        ? U.s.guest
        : U.s.user;
    final Color color = i.isFullAdmin()
        ? UAdminTheme.indigo
        : i.isSubAdmin()
        ? UAdminTheme.blue
        : i.tags.contains(TagUser.guest.number)
        ? UAdminTheme.blueGrey
        : UAdminTheme.grey;
    return UContainer(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      color: color.withValues(alpha: 0.16),
      radius: 20,
      child: UTextBodySmall(label, color: color, fontWeight: FontWeight.w600),
    );
  }

  Widget _listItemResponsive({required UUserResponse i, required int index}) => Card(
    elevation: 1,
    margin: const EdgeInsets.all(8),
    child: UColumn(
      margin: const EdgeInsets.all(16),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        UKeyValue(
          leading: UIconTextHorizontal(
            leading: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (BuildContext context) => _menuItems(i),
            ),
            trailing: _roleChip(i),
          ),
          trailing: UTextBodyMedium("${i.firstName ?? "-"} ${i.lastName ?? "-"}", fontWeight: FontWeight.bold),
        ),
        const Divider(height: 24, endIndent: 20, indent: 20),
        UKeyValue(
          leading: UTextBodyMedium("${U.s.phoneNumber}:"),
          trailing: UTextBodyMedium(i.phoneNumber ?? "---", fontWeight: FontWeight.bold),
        ),
        const Divider(height: 24, endIndent: 20, indent: 20),
        UKeyValue(
          leading: UTextBodyMedium("${U.s.email}:"),
          trailing: UTextBodyMedium(i.email ?? "---", fontWeight: FontWeight.bold),
        ),
        const Divider(height: 24, endIndent: 20, indent: 20),
        UKeyValue(
          leading: UTextBodyMedium("${U.s.createdAt}:"),
          trailing: UTextBodyMedium(i.createdAt.toJalaliDateTime(), fontWeight: FontWeight.bold),
        ),
        const Divider(height: 24, endIndent: 20, indent: 20),
      ],
    ),
  );

  Widget _listItemDesktop({required UUserResponse i, required int index}) => URow(
    color: index.isOdd ? UAdminTheme.transparent : Theme.of(context).colorScheme.primary.withValues(alpha: 0.16),
    children: <Widget>[
      Center(child: _genderIcon(i)).expanded(),
      URow(
        onTap: () => UAdminPageSwitcher.hotelUserDetail(user: i),
        spacing: 0,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _roleChip(i),
          const SizedBox(width: 6),
          Flexible(
            child: UTextBodyMedium("${i.firstName ?? ""} ${i.lastName ?? ""}".trim(), textAlign: .center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ).expanded(),
      UTextBodyMedium(i.userName, textAlign: .center).onTap(() => UClipboard.set(i.userName)).expanded(),
      UTextBodyMedium(i.phoneNumber ?? "", textAlign: .center).expanded(),
      UTextBodyMedium(i.email ?? "", textAlign: .center).expanded(),
      UTextBodyMedium(i.createdAt.toJalaliDate(), textAlign: .center).expanded(),
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        itemBuilder: (BuildContext context) => _menuItems(i),
      ).expanded(),
    ],
  );

  Widget _genderIcon(UUserResponse i) {
    final bool male = i.isMale();
    final bool female = i.isFemaleMale();
    return Icon(
      male
          ? Icons.male_rounded
          : female
          ? Icons.female_rounded
          : Icons.person_outline_rounded,
      color: male
          ? UAdminTheme.blue
          : female
          ? UAdminTheme.pink
          : UAdminTheme.grey,
      size: 20,
    );
  }

  List<PopupMenuEntry<String>> _menuItems(UUserResponse i) => <PopupMenuEntry<String>>[
    PopupMenuItem<String>(
      child: UIconTextHorizontal(leading: const Icon(Icons.badge_outlined, size: 20), trailing: Text(U.s.details)),
      onTap: () => UAdminPageSwitcher.hotelUserDetail(user: i),
    ),
    PopupMenuItem<String>(
      child: UIconTextHorizontal(leading: const Icon(Icons.description_outlined, size: 20), trailing: Text(U.s.contracts)),
      onTap: () => UAdminPageSwitcher.contracts(user: i),
    ),
    if (U.user.hasPermission(TagUser.permissionManageUsers))
      PopupMenuItem<String>(
        child: UIconTextHorizontal(leading: const Icon(Icons.edit, size: 20), trailing: Text(U.s.edit)),
        onTap: () => UAdminPageSwitcher.userCreateUpdate(user: i).then((_) => c.read()),
      ),
    if (U.user.hasPermission(TagUser.permissionDeleteUsers))
      PopupMenuItem<String>(
        child: UIconTextHorizontal(
          leading: const Icon(Icons.delete, color: UAdminTheme.red, size: 20),
          trailing: Text(U.s.delete, style: const TextStyle(color: UAdminTheme.red)),
        ),
        onTap: () => c.delete(i),
      ),
  ];
}
