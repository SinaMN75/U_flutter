import "package:u/utilities.dart";

/// Result of the version check: none, optional (can skip) or force (must update).
enum UpdateType { none, optional, force }

/// Shows "Update available / required" from `UAppSettingsResponse.appVersions`, comparing build numbers.
/// `UUpdateDialog.checkAndShow(U.appSettings.appVersions, () => UNavigator.offAll(HomePage()))`
class UUpdateDialog {
  static const String _skipKey = "skip_update_version";

  /// Shows the dialog when needed; [onSkipOrNotAvailable] runs when there is nothing to do, or the user taps Later / Skip this version.
  static Future<void> checkAndShow(List<UAppVersionResponse> versions, VoidCallback onSkipOrNotAvailable) async {
    final UAppVersionResponse? info = versions.firstWhereOrNull((UAppVersionResponse i) => i.platform == TagAppVersion.current);
    final UpdateType type = info == null ? UpdateType.none : _checkUpdate(info);

    if (info == null || type == UpdateType.none || (type == UpdateType.optional && ULocalStorage.getInt(_skipKey) == info.latestBuildNumber)) {
      onSkipOrNotAvailable();
      return;
    }

    await showDialog(
      barrierDismissible: false,
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) => PopScope(
        canPop: false,
        child: _UUpdateDialogView(
          info: info,
          force: type == UpdateType.force,
          onSkip: () {
            ULocalStorage.set(_skipKey, info.latestBuildNumber);
            UNavigator.back();
            onSkipOrNotAvailable();
          },
          onLater: () {
            UNavigator.back();
            onSkipOrNotAvailable();
          },
        ),
      ),
    );
  }

  static UpdateType _checkUpdate(UAppVersionResponse info) {
    final int? build = int.tryParse(UApp.buildNumber);
    if (build == null) return UpdateType.none;
    if (build < info.minBuildNumber) return UpdateType.force;
    if (build < info.latestBuildNumber) return UpdateType.optional;
    return UpdateType.none;
  }
}

class _UUpdateDialogView extends StatelessWidget {
  const _UUpdateDialogView({required this.info, required this.force, required this.onSkip, required this.onLater});

  final UAppVersionResponse info;
  final bool force;
  final VoidCallback onSkip;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color accent = force ? cs.error : cs.primary;
    final List<UAppVersionLink> links = info.jsonData.links.where((UAppVersionLink i) => i.url.isNotNullOrEmpty()).toList();

    return Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: UColumn(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _header(context, cs, accent),
              UColumn(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: <Widget>[
                  if (info.jsonData.description.isNotNullOrEmpty()) _whatsNew(cs),
                  if (links.isNotEmpty) ...<Widget>[
                    UTextLabelLarge(U.s.downloadLinks, color: cs.onSurfaceVariant),
                    UColumn(spacing: 8, children: links.map((UAppVersionLink i) => _linkTile(cs, i)).toList()),
                  ],
                  if (force)
                    TextButton.icon(
                      onPressed: UApp.exit,
                      style: TextButton.styleFrom(foregroundColor: cs.error),
                      icon: const Icon(Icons.power_settings_new_rounded, size: 20),
                      label: Text(U.s.exitApp),
                    )
                  else
                    URow(
                      spacing: 8,
                      children: <Widget>[
                        TextButton(onPressed: onSkip, child: Text(U.s.skipThisVersion)).expanded(),
                        FilledButton.tonal(onPressed: onLater, child: Text(U.s.later)).expanded(),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, ColorScheme cs, Color accent) => UContainer(
    padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[accent.withValues(alpha: 0.16), accent.withValues(alpha: 0)],
    ),
    child: UColumn(
      spacing: 10,
      children: <Widget>[
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.14),
            border: Border.all(color: accent.withValues(alpha: 0.28), width: 6, strokeAlign: BorderSide.strokeAlignOutside),
          ),
          child: Icon(force ? Icons.priority_high_rounded : Icons.rocket_launch_rounded, size: 36, color: accent),
        ),
        UTextTitleLarge(force ? U.s.updateRequired : U.s.updateAvailable, fontWeight: FontWeight.w700, textAlign: TextAlign.center),
        if (info.jsonData.latestVersionName.isNotNullOrEmpty())
          UContainer(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            radius: 100,
            color: accent.withValues(alpha: 0.12),
            child: UTextLabelMedium("${U.s.version} ${info.jsonData.latestVersionName}", color: accent, fontWeight: FontWeight.w600),
          ),
        UTextBodyMedium(force ? U.s.updateRequiredDescription : U.s.updateAvailableDescription, textAlign: TextAlign.center, color: cs.onSurfaceVariant, overflow: TextOverflow.visible),
      ],
    ),
  );

  Widget _whatsNew(ColorScheme cs) => UContainer(
    padding: const EdgeInsets.all(14),
    radius: 16,
    color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
    child: UColumn(
      spacing: 6,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        URow(
          spacing: 6,
          children: <Widget>[
            Icon(Icons.auto_awesome_rounded, size: 18, color: cs.primary),
            UTextTitleSmall(U.s.whatsNew, fontWeight: FontWeight.w700),
          ],
        ),
        UTextBodySmall(info.jsonData.description!, color: cs.onSurfaceVariant, overflow: TextOverflow.visible),
      ],
    ),
  );

  Widget _linkTile(ColorScheme cs, UAppVersionLink i) => Material(
    color: cs.surfaceContainerLow,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: cs.outlineVariant),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => ULaunch.url(i.url!, mode: ULaunchMode.external),
      child: URow(
        spacing: 12,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        children: <Widget>[
          UContainer(
            width: 40,
            height: 40,
            radius: 10,
            color: cs.surface,
            clipBehavior: Clip.antiAlias,
            child: i.iconBase64.isNullOrEmpty()
                ? Icon(Icons.storefront_rounded, color: cs.primary)
                : UImage(
                    "",
                    fileData: UFileData(bytes: i.iconBase64!.split(",").last.toBytesFromBase64()),
                    fit: BoxFit.cover,
                  ),
          ),
          UTextBodyLarge(i.title ?? i.url!, fontWeight: FontWeight.w600, maxLines: 1, overflow: TextOverflow.ellipsis, expanded: 1),
          UContainer(
            padding: const EdgeInsets.all(6),
            radius: 100,
            color: cs.primary,
            child: Icon(Icons.download_rounded, size: 18, color: cs.onPrimary),
          ),
        ],
      ),
    ),
  );
}
