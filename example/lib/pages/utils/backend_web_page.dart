import "package:u/utilities.dart";

import "../../demo/demo.dart";

/// UHttpClient, UAuth, UCrashlytics, UUpdateDialog, UWeb*, UIso / UIsoClient.
class BackendWebPage extends StatelessWidget {
  const BackendWebPage({super.key});

  static const String _api = "https://jsonplaceholder.typicode.com";

  @override
  Widget build(BuildContext context) => DemoPage(
    title: "HTTP, auth, web, ISO8583",
    children: <Widget>[
      DemoGroup("HTTP", <Widget>[
        Fn("UHttpClient.send(GET)", () async {
          String? status;
          final UHttpClientResponse r = await UHttpClient.send(
            method: "GET",
            endpoint: "$_api/todos/1",
            onSuccess: (Response res) => status = "ok ${res.statusCode} success=${res.isSuccessful()} server=${res.isServerError()}",
            onError: (Response res) => status = "error ${res.statusCode}",
            onException: (String e) => status = "exception $e",
          );
          return "$status · ${r.isSuccessful}";
        }),
        Fn("UHttpClient.send(POST, body, onProgress)", () async {
          final UHttpClientResponse r = await UHttpClient.send(
            method: "POST",
            endpoint: "$_api/posts",
            body: const <String, dynamic>{"title": "u", "body": null},
            onProgress: (int p) {},
            onSuccess: (Response res) {},
            onError: (Response res) {},
            onException: (String e) {},
          );
          return r.response;
        }, note: "The null field is removed before sending"),
        Fn(
          "UHttpClient.removeNullEntries({...})",
          () => UHttpClient.removeNullEntries(const <String, dynamic>{
            "a": 1,
            "b": null,
            "c": <dynamic>[1, null],
          }),
          auto: true,
        ),
        Fn("UHttpClient.multipartFileFromUint8List('file', bytes)", () async => (await UHttpClient.multipartFileFromUint8List("file", Uint8List.fromList(<int>[1, 2]), filename: "a.bin")).length),
        Fn("UHttpClient.multipartFileFromFile('file', File(path))", () async {
          if (kIsWeb) return "not on web";
          final File f = await UFile.writeToFile(Uint8List.fromList(<int>[1, 2, 3]), extension: "bin");
          return (await UHttpClient.multipartFileFromFile("file", f)).filename;
        }),
        Fn("UHttpClient.upload(endpoint, files: …)", () async {
          String status = "";
          await UHttpClient.upload(
            endpoint: "https://httpbin.org/post",
            files: <MultipartFile>[await UHttpClient.multipartFileFromUint8List("file", Uint8List.fromList(utf8.encode("hello")), filename: "hello.txt")],
            fields: const <String, dynamic>{"note": "u"},
            onProgress: (int p) {},
            onSuccess: (Response r) => status = "uploaded ${r.statusCode}",
            onError: (Response r) => status = "error ${r.statusCode}",
            onException: () => status = "exception",
          );
          return status;
        }),
        Fn("response.prettyLog()", () async {
          final Response r = await get(Uri.parse("$_api/todos/1"));
          r.prettyLog();
          return "logged to the debug console";
        }),
      ]),
      DemoGroup("Auth session", <Widget>[
        Fn("UAuth.isSignedIn / canRefresh", () => <bool>[UAuth.isSignedIn, UAuth.canRefresh], auto: true),
        Fn("UAuth.accessTokenExpiresAt() / isAccessTokenExpired()", () => <Object?>[UAuth.accessTokenExpiresAt(), UAuth.isAccessTokenExpired()]),
        Fn("UAuth.hasRefreshToken / isRefreshTokenExpired", () => <bool>[UAuth.hasRefreshToken, UAuth.isRefreshTokenExpired]),
        Fn("UAuth.epoch / isSessionEnded", () => <Object>[UAuth.epoch, UAuth.isSessionEnded]),
        Fn('UAuth.isTokenIssuingEndpoint("/auth/Login")', () => UAuth.isTokenIssuingEndpoint("/auth/Login")),
        Fn("UAuth.onTokensIssued()", UAuth.onTokensIssued),
        Fn("UAuth.diagnostics()", UAuth.diagnostics),
        Fn("await UAuth.ensureFreshToken()", UAuth.ensureFreshToken),
        Fn("await UAuth.refresh()", UAuth.refresh, note: "Calls your backend's refresh endpoint"),
        Fn("UAuth.clear() (tokens only)", () => UNavigator.confirmAsync(title: "Clear tokens?", message: "").then((bool ok) => ok ? UAuth.clear() : null)),
        Fn("UAuth.signOut()", () => UNavigator.confirmAsync(title: "Sign out?", message: "Clears storage, keeps language/theme").then((bool ok) => ok ? UAuth.signOut() : null)),
        Fn("UAuth.handleAuthFailure()", () => UNavigator.confirmAsync(title: "Simulate expired session?", message: "").then((bool ok) => ok ? UAuth.handleAuthFailure() : null)),
      ]),
      DemoGroup("Crash reports & updates", <Widget>[
        Fn(
          "UCrashlytics.initialize(onCrash: …)",
          () => UCrashlytics.initialize(onCrash: (Map<String, dynamic> report) => UToast.error(message: "Crash: ${(report["error"] as Map<String, dynamic>?)?["message"] ?? report["type"]}")),
        ),
        Fn("UCrashlytics.reportError(e, stack)", () {
          UCrashlytics.reportError(Exception("demo error"), StackTrace.current);
          return "reported";
        }),
        Fn(
          "UUpdateDialog.checkAndShow(data, onSkip)",
          () => UUpdateDialog.checkAndShow(
            <UAppVersionResponse>[
              UAppVersionResponse(
                id: "demo",
                tags: <int>[TagAppVersion.current.number],
                latestBuildNumber: 999999,
                minBuildNumber: 1,
                jsonData: UAppVersionJson(
                  latestVersionName: "9.9.9",
                  description: "Faster startup\nNew wallet screen\nBug fixes",
                  links: <UAppVersionLink>[
                    UAppVersionLink(title: "Google Play", url: "https://play.google.com"),
                    UAppVersionLink(title: "Direct download", url: "https://example.com/app.apk"),
                  ],
                ),
              ),
            ],
            () => UToast.info(message: "Skipped / nothing to update"),
          ),
        ),
      ]),
      DemoGroup("Web (no-ops elsewhere)", <Widget>[
        Fn("UWebMessage.listen((origin, data) => …)", () {
          final void Function() stop = UWebMessage.listen((String origin, Map<String, dynamic> data) => UToast.info(message: "$origin: $data"));
          stop();
          return "listened and stopped";
        }),
        Fn(
          "UPwa.isStandalone / isIphoneBrowser / isIosBrowser / isAndroidBrowser / isIosSafari",
          () => <bool>[UPwa.isStandalone, UPwa.isIphoneBrowser, UPwa.isIosBrowser, UPwa.isAndroidBrowser, UPwa.isIosSafari],
        ),
        Fn("UPwa.canPromptIosInstall", () => UPwa.canPromptIosInstall),
        Fn("UPwa.promptIosInstall(force: true)", () => UPwa.promptIosInstall(force: true)),
        Fn("await UWebUpdate.serverBuild() / cachedBuild()", () async => <Object?>[(await UWebUpdate.serverBuild())?.id, (await UWebUpdate.cachedBuild())?.id]),
        Fn("UWebUpdate.runningServiceWorkerVersion()", UWebUpdate.runningServiceWorkerVersion),
        Fn("await UWebUpdate.hasUpdate()", UWebUpdate.hasUpdate),
        Fn("UWebUpdate.checkAndRefresh()", UWebUpdate.checkAndRefresh),
        Fn("UWebUpdate.stopWatching() / startWatching()", () {
          UWebUpdate.stopWatching();
          UWebUpdate.startWatching(silent: true);
          return "restarted";
        }),
        Fn("UWebUpdate.refresh()", () => UNavigator.confirmAsync(title: "Reload the web app?", message: "").then((bool ok) => ok ? UWebUpdate.refresh() : null)),
      ]),
      DemoGroup("ISO8583 (POS switch)", <Widget>[
        Fn("UIso.init(config: …, context: …, securityModule: …)", () {
          UIso.init(
            config: HostConfig(
              nii: "0003",
              bin: "123456",
              version: "1.0.0",
              initKeySetting: const TerminalInitKeySetting(ktmIndex: 1, mpkIndex: 2),
              sessionKeyIndexSetting: const TerminalSessionKeyIndexSetting(mpkIndex: 3, ppkIndex: 4, dpkIndex: 5),
              allConnectionInfo: <String, HostConnectionInfo>{"lan": HostConnectionInfo(hostIp: "127.0.0.1", hostPort: 9)},
              activeConnectionType: "lan",
            ),
            context: HostContext(),
            securityModule: _DemoSecurityModule(),
            nextTraceNumber: () async => DateTime.now().millisecond + 1,
          );
          return "ready";
        }),
        Fn("UIso.isLoggedOn / pinKeyIndex / link", () => <Object>[UIso.isLoggedOn, UIso.pinKeyIndex, UIso.link.runtimeType], note: "Run UIso.init first"),
        Fn("UIso.storeSessionKeys({...})", () => UIso.storeSessionKeys(<IsoKeyType, IsoSessionKey>{IsoKeyType.ppk: IsoSessionKey(Uint8List(16), null)})),
        Fn("UIsoClient.send(mti: '0800', …)", () async {
          String result = "";
          await UIsoClient.send(
            mti: "0800",
            processingCode: "920000",
            sendTerminalId: false,
            timeout: 2.seconds,
            onSuccess: (UIsoResult r) => result = "approved ${r.traceNumber}",
            onError: (UIsoResult r) => result = "declined ${r.status} ${r.message}",
            onException: (String e) => result = "link error: $e",
          );
          return result;
        }, note: "No host at 127.0.0.1:9, so this shows a link error"),
        Fn("UIso.reset()", UIso.reset),
      ]),
    ],
  );
}

/// Stand-in security module for the demo; a real terminal injects its PED here.
class _DemoSecurityModule implements IsoSecurityModule {
  @override
  String get name => "demo";

  @override
  Future<Uint8List> generateMac({required int keyIndex, required Uint8List data, required IsoMacAlgorithm algorithm, required int macLength, required bool useDefaultMac}) async =>
      Uint8List(macLength);

  @override
  Future<Uint8List> encryptData({required int keyIndex, required Uint8List data, required IsoCipherMode cipherMode, required IsoEncryptionStandard standard, Uint8List? icv}) async => data;

  @override
  Future<Uint8List> decryptData({required int keyIndex, required Uint8List data, required IsoCipherMode cipherMode, required IsoEncryptionStandard standard, Uint8List? icv}) async => data;

  @override
  Future<void> injectKtm({required int ktmIndex, required Uint8List ktm, Uint8List? kvc, IsoKeyLength keyLength = IsoKeyLength.des3TwoKey}) async {}

  @override
  Future<void> storeSessionKey({
    required int keyIndex,
    required int ktmIndex,
    required IsoKeyType keyType,
    required Uint8List sessionKey,
    Uint8List? kvc,
    IsoKeyLength keyLength = IsoKeyLength.des3TwoKey,
    bool useDefaultMac = false,
  }) async {}

  @override
  Future<Uint8List?> getKvc({required IsoKeyType keyType, required int keyIndex}) async => null;

  @override
  Stream<PinInputEvent> getPinBlock({required String pan, required String hint, required int ppkIndex, int min = 4, int max = 4, int timeoutMillis = 60000}) => const Stream<PinInputEvent>.empty();

  @override
  Future<void> close() async {}
}
