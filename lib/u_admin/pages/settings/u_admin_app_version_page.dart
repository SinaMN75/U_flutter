part of "../../u_admin.dart";

class UAdminAppVersionPage extends StatefulWidget {
  const UAdminAppVersionPage({super.key});

  static UAdminModule module({List<TagUser>? roles}) => UAdminModule(
    title: U.s.appVersions,
    icon: Icons.system_update_outlined,
    page: () => const UAdminAppVersionPage(),
    roles: roles,
  );

  @override
  State<UAdminAppVersionPage> createState() => _UAdminAppVersionPageState();
}

class _UAdminAppVersionPageState extends State<UAdminAppVersionPage> {
  List<UAppVersionResponse> _list = <UAppVersionResponse>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final (UResponse<UAppSettingsResponse>? ok, UEmptyResponse? error, String? exception) = await UServices.appSettings.read();
    if (ok == null) UToast.error(message: error?.message ?? exception ?? "");
    setState(() {
      _list = ok?.result?.appVersions ?? <UAppVersionResponse>[];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(
      title: Text(U.s.appVersions),
      actions: <Widget>[IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loading ? null : _load)],
    ),
    body: UAdminPageBody(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: TagAppVersion.values.map((TagAppVersion p) => _card(p, _list.firstWhereOrNull((UAppVersionResponse i) => i.platform == p))).toList(),
              ),
            ),
    ),
  );

  static IconData _platformIcon(TagAppVersion p) => switch (p) {
    TagAppVersion.android => Icons.android_rounded,
    TagAppVersion.ios => Icons.apple_rounded,
    TagAppVersion.windows => Icons.window_rounded,
    TagAppVersion.macOs => Icons.laptop_mac_rounded,
    TagAppVersion.linux => Icons.terminal_rounded,
    TagAppVersion.web => Icons.language_rounded,
  };

  Widget _card(TagAppVersion p, UAppVersionResponse? v) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<UAppVersionLink> links = v?.jsonData.links ?? <UAppVersionLink>[];
    return SizedBox(
      width: 320,
      child: Material(
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cs.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _form(p, v),
          child: UColumn(
            spacing: 14,
            crossAxisAlignment: CrossAxisAlignment.start,
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              URow(
                spacing: 12,
                children: <Widget>[
                  UContainer(
                    padding: const EdgeInsets.all(10),
                    radius: 14,
                    color: cs.primary.withValues(alpha: 0.12),
                    child: Icon(_platformIcon(p), color: cs.primary),
                  ),
                  UColumn(
                    expanded: 1,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      UTextTitleMedium(p.localizedTitle, fontWeight: FontWeight.w700),
                      UTextBodySmall(v?.jsonData.latestVersionName.nullIfEmpty() ?? "---", color: cs.onSurfaceVariant),
                    ],
                  ),
                  Icon(Icons.edit_outlined, size: 20, color: cs.onSurfaceVariant),
                ],
              ),
              URow(
                spacing: 8,
                children: <Widget>[
                  _stat(cs, U.s.latestBuildNumber, (v?.latestBuildNumber ?? 0).toString(), cs.primary).expanded(),
                  _stat(cs, U.s.minBuildNumber, (v?.minBuildNumber ?? 0).toString(), cs.error).expanded(),
                ],
              ),
              URow(
                spacing: 6,
                children: <Widget>[
                  UTextLabelMedium("${U.s.downloadLinks} (${links.length})", color: cs.onSurfaceVariant, expanded: 1),
                  ...links
                      .take(5)
                      .map(
                        (UAppVersionLink i) => Tooltip(
                          message: i.title ?? "",
                          child: UContainer(
                            width: 28,
                            height: 28,
                            radius: 8,
                            color: cs.surface,
                            clipBehavior: Clip.antiAlias,
                            child: i.iconBase64.isNullOrEmpty()
                                ? Icon(Icons.storefront_rounded, size: 16, color: i.url.isNullOrEmpty() ? cs.outline : cs.primary)
                                : UImage(
                                    "",
                                    fileData: UFileData(bytes: i.iconBase64!.split(",").last.toBytesFromBase64()),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(ColorScheme cs, String label, String value, Color color) => UContainer(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    radius: 12,
    color: color.withValues(alpha: 0.08),
    child: UColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        UTextTitleMedium(value, color: color, fontWeight: FontWeight.w700),
        UTextLabelSmall(label, color: cs.onSurfaceVariant, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    ),
  );

  Future<void> _form(TagAppVersion platform, UAppVersionResponse? v) async {
    final TextEditingController name = TextEditingController(text: v?.jsonData.latestVersionName);
    final TextEditingController latest = TextEditingController(text: (v?.latestBuildNumber ?? 0).toString());
    final TextEditingController min = TextEditingController(text: (v?.minBuildNumber ?? 0).toString());
    final TextEditingController description = TextEditingController(text: v?.jsonData.description);
    final List<_UAdminAppVersionLinkForm> links = <_UAdminAppVersionLinkForm>[...?v?.jsonData.links.map(_UAdminAppVersionLinkForm.new)];

    await UFormDialog.show(
      title: "${U.s.appVersion} - ${platform.localizedTitle}",
      maxWidth: 520,
      onSubmit: () async {
        final (UEmptyResponse? ok, UEmptyResponse? error, String? exception) = await UServices.appSettings.updateAppVersion(
          p: UAppVersionUpdateParams(
            platform: platform,
            latestBuildNumber: latest.numInt(),
            minBuildNumber: min.numInt(),
            latestVersionName: name.text.nullIfEmpty(),
            description: description.text.nullIfEmpty(),
            links: links.map((_UAdminAppVersionLinkForm i) => i.toModel()).toList(),
          ),
        );
        if (ok == null) {
          UToast.error(message: error?.message ?? exception ?? "");
          return false;
        }
        UToast.snackBar(message: ok.message);
        unawaited(_load());
        return true;
      },
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UTextField(controller: name, labelText: U.s.latestVersionName, hintText: "1.0.0", margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: latest, labelText: U.s.latestBuildNumber, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: min, labelText: U.s.minBuildNumber, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: description, labelText: U.s.whatsNew, lines: 4, margin: const EdgeInsets.symmetric(vertical: 6)),
        URow(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            UTextBodyLarge(U.s.downloadLinks),
            TextButton.icon(onPressed: () => setState(() => links.add(_UAdminAppVersionLinkForm())), icon: const Icon(Icons.add, size: 18), label: Text(U.s.addItem(U.s.link))),
          ],
        ),
        ...links.mapIndexed(
          (int index, _UAdminAppVersionLinkForm e) => UContainer(
            key: ObjectKey(e),
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(vertical: 6),
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
            radius: 8,
            child: UColumn(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: IconButton(
                    icon: Icon(Icons.close, size: 18, color: Theme.of(context).colorScheme.error),
                    onPressed: () => setState(() => links.removeAt(index)),
                  ),
                ),
                UTextField(controller: e.title, labelText: U.s.title, margin: const EdgeInsets.symmetric(vertical: 4)),
                UTextField(controller: e.url, labelText: U.s.url, hintText: "https://", margin: const EdgeInsets.symmetric(vertical: 4)),
                UBase64ImagePicker(label: U.s.icon, initial: e.iconBase64, onChanged: (String? i) => e.iconBase64 = i),
              ],
            ),
          ),
        ),
      ],
    );
    for (final TextEditingController i in <TextEditingController>[
      name,
      latest,
      min,
      description,
      ...links.expand((_UAdminAppVersionLinkForm l) => <TextEditingController>[l.title, l.url]),
    ]) {
      i.dispose();
    }
  }
}

class _UAdminAppVersionLinkForm {
  _UAdminAppVersionLinkForm([UAppVersionLink? m]) : title = TextEditingController(text: m?.title), url = TextEditingController(text: m?.url), iconBase64 = m?.iconBase64;

  final TextEditingController title;
  final TextEditingController url;
  String? iconBase64;

  UAppVersionLink toModel() => UAppVersionLink(title: title.text.nullIfEmpty(), url: url.text.nullIfEmpty(), iconBase64: iconBase64);
}
