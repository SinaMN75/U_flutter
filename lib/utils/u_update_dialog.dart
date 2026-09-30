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

    final bool force = type == UpdateType.force;
    await showDialog(
      barrierDismissible: false,
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(force ? U.s.updateRequired : U.s.updateAvailable),
          content: SingleChildScrollView(
            child: UColumn(
              spacing: 8,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                UTextBodyMedium(force ? U.s.updateRequiredDescription : U.s.updateAvailableDescription),
                if (info.jsonData.latestVersionName.isNotNullOrEmpty()) UTextLabelLarge("${U.s.version} ${info.jsonData.latestVersionName}"),
                if (info.jsonData.description.isNotNullOrEmpty()) ...<Widget>[
                  UTextTitleSmall(U.s.whatsNew),
                  UTextBodySmall(info.jsonData.description!),
                ],
                ...info.jsonData.links
                    .where((UAppVersionLink i) => i.url.isNotNullOrEmpty())
                    .map(
                      (UAppVersionLink i) => ListTile(
                        onTap: () => ULaunch.url(i.url!, mode: ULaunchMode.external),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                        ),
                        leading: SizedBox.square(
                          dimension: 32,
                          child: i.iconBase64.isNullOrEmpty()
                              ? const Icon(Icons.shop_outlined)
                              : UImage("", fileData: UFileData(bytes: i.iconBase64!.split(",").last.toBytesFromBase64()), borderRadius: 6),
                        ),
                        title: Text(i.title ?? i.url!),
                        trailing: const Icon(Icons.download_rounded),
                      ),
                    ),
              ],
            ),
          ),
          actions: force
              ? <Widget>[
                  TextButton(
                    onPressed: UApp.exit,
                    child: Text(U.s.exitApp, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                ]
              : <Widget>[
                  TextButton(
                    onPressed: () {
                      ULocalStorage.set(_skipKey, info.latestBuildNumber);
                      UNavigator.back();
                      onSkipOrNotAvailable();
                    },
                    child: Text(U.s.skipThisVersion),
                  ),
                  TextButton(
                    onPressed: () {
                      UNavigator.back();
                      onSkipOrNotAvailable();
                    },
                    child: Text(U.s.later),
                  ),
                ],
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
