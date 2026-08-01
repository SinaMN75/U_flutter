import "package:u/utilities.dart";

typedef OnUrlChanged = void Function(String url, Map<String, String> queryParameters);

class UWebView extends StatefulWidget {
  final String initialUrl;
  final String? userAgent;
  final String desktopUserAgent;
  final Color? backgroundColor;
  final OnUrlChanged? onUrlChanged;
  final List<String> allowedHosts;
  final Widget? loadingIndicator;
  final bool enableJavaScript;
  final bool enablePinchZoom;
  final bool enableJavaScriptDialogs;
  final bool restrictToAllowedHosts;
  final bool autoGrantMediaPermissions;
  final bool showTopBar;
  final bool showUrlBar;
  final bool showBackButton;
  final bool showForwardButton;
  final bool showRefreshButton;
  final bool showHomeButton;
  final bool showProgressBar;
  final bool showMoreMenu;
  final bool showShareAction;
  final bool showOpenInBrowserAction;
  final bool showCopyLinkAction;
  final bool showDesktopModeAction;
  final bool showZoomActions;
  final Map<String, void Function(String message)>? javaScriptChannels;
  final Map<String, String>? initialHeaders;
  final Widget Function(BuildContext context, String message, VoidCallback retry)? errorBuilder;
  final Future<void> Function(WebViewPermissionRequest request)? onPermissionRequest;
  final void Function(String url)? onPageStarted;
  final void Function(String url)? onPageFinished;
  final void Function(WebResourceError error)? onWebResourceError;
  final void Function(WebViewController controller)? onWebViewCreated;
  final bool Function(String url)? onNavigationRequest;
  final void Function(String url)? onShareRequested;
  final void Function(String url)? onOpenInBrowserRequested;

  const UWebView({
    required this.initialUrl,
    super.key,
    this.initialHeaders,
    this.backgroundColor,
    this.onUrlChanged,
    this.onPageStarted,
    this.onPageFinished,
    this.onWebResourceError,
    this.onWebViewCreated,
    this.onNavigationRequest,
    this.showTopBar = false,
    this.showUrlBar = false,
    this.showBackButton = false,
    this.showForwardButton = false,
    this.showRefreshButton = false,
    this.showHomeButton = false,
    this.showProgressBar = false,
    this.showMoreMenu = false,
    this.showShareAction = false,
    this.showOpenInBrowserAction = false,
    this.showCopyLinkAction = false,
    this.showDesktopModeAction = false,
    this.showZoomActions = false,
    this.onShareRequested,
    this.onOpenInBrowserRequested,
    this.enableJavaScript = true,
    this.enablePinchZoom = false,
    this.enableJavaScriptDialogs = true,
    this.userAgent,
    this.desktopUserAgent =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    this.restrictToAllowedHosts = false,
    this.allowedHosts = const <String>[],
    this.onPermissionRequest,
    this.autoGrantMediaPermissions = true,
    this.javaScriptChannels,
    this.errorBuilder,
    this.loadingIndicator,
  });

  @override
  State<UWebView> createState() => UWebViewState();
}

class UWebViewState extends State<UWebView> {
  late final WebViewController controller;

  final ValueNotifier<String> currentUrl = ValueNotifier<String>("");
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<double> progress = ValueNotifier<double>(0);
  final ValueNotifier<bool> canGoBack = ValueNotifier<bool>(false);
  final ValueNotifier<bool> canGoForward = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isDesktopMode = ValueNotifier<bool>(false);
  final ValueNotifier<String?> loadError = ValueNotifier<String?>(null);
  final TextEditingController urlFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller =
        WebViewController(
            onPermissionRequest:
                widget.onPermissionRequest ??
                (WebViewPermissionRequest request) async {
                  if (widget.autoGrantMediaPermissions) {
                    await request.grant();
                  } else {
                    await request.deny();
                  }
                },
          )
          ..setJavaScriptMode(widget.enableJavaScript ? JavaScriptMode.unrestricted : JavaScriptMode.disabled)
          ..enableZoom(widget.enablePinchZoom)
          ..setNavigationDelegate(_buildNavigationDelegate());

    if (widget.backgroundColor != null) {
      controller.setBackgroundColor(widget.backgroundColor!);
    }
    if (widget.userAgent != null) {
      controller.setUserAgent(widget.userAgent);
    }
    if (widget.enableJavaScriptDialogs) {
      _wireJavaScriptDialogs();
    }
    widget.javaScriptChannels?.forEach((String name, void Function(String) handler) {
      controller.addJavaScriptChannel(
        name,
        onMessageReceived: (JavaScriptMessage message) => handler(message.message),
      );
    });

    widget.onWebViewCreated?.call(controller);
    _load(widget.initialUrl, headers: widget.initialHeaders);
  }

  NavigationDelegate _buildNavigationDelegate() => NavigationDelegate(
    onProgress: (int p) => progress.value = p / 100.0,
    onPageStarted: (String url) {
      isLoading.value = true;
      loadError.value = null;
      _publishUrl(url);
      widget.onPageStarted?.call(url);
    },
    onPageFinished: (String url) async {
      isLoading.value = false;
      _publishUrl(url);
      await _refreshNavState();
      widget.onPageFinished?.call(url);
    },
    onUrlChange: (UrlChange change) {
      if (change.url != null) _publishUrl(change.url!);
    },
    onWebResourceError: (WebResourceError error) {
      isLoading.value = false;
      loadError.value = error.description.isNotEmpty ? error.description : "Failed to load page";
      widget.onWebResourceError?.call(error);
    },
    onNavigationRequest: (NavigationRequest request) {
      if (!_isHostAllowed(request.url)) {
        UToast.snackBar(message: "This link is blocked");
        return NavigationDecision.prevent;
      }
      final bool allowed = widget.onNavigationRequest?.call(request.url) ?? true;
      return allowed ? NavigationDecision.navigate : NavigationDecision.prevent;
    },
  );

  void _wireJavaScriptDialogs() {
    controller.setOnJavaScriptAlertDialog((JavaScriptAlertDialogRequest request) async {
      if (!mounted) return;
      await UNavigator.dialog(
        AlertDialog(
          content: Text(request.message),
          actions: const <Widget>[TextButton(onPressed: UNavigator.back, child: Text("OK"))],
        ),
      );
    });

    controller.setOnJavaScriptConfirmDialog((JavaScriptConfirmDialogRequest request) async {
      if (!mounted) return false;
      final bool? result = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          content: Text(request.message),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text("Cancel")),
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text("OK")),
          ],
        ),
      );
      return result ?? false;
    });

    controller.setOnJavaScriptTextInputDialog((JavaScriptTextInputDialogRequest request) async {
      if (!mounted) return request.defaultText ?? "";
      final TextEditingController inputController = TextEditingController(text: request.defaultText);
      final String? result = await showDialog<String>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(request.message),
              TextField(controller: inputController, autofocus: true),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(request.defaultText),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(inputController.text),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      inputController.dispose();
      return result ?? request.defaultText ?? "";
    });
  }

  bool _isHostAllowed(String url) {
    if (!widget.restrictToAllowedHosts) return true;
    final String? host = Uri.tryParse(url)?.host;
    if (host == null || host.isEmpty) return false;
    final List<String> hosts = widget.allowedHosts.isNotEmpty ? widget.allowedHosts : <String>[Uri.tryParse(widget.initialUrl)?.host ?? ""];
    return hosts.any((String allowed) => host == allowed || host.endsWith(".$allowed"));
  }

  Future<void> _load(String url, {Map<String, String>? headers}) => controller.loadRequest(
    Uri.parse(url),
    headers: headers ?? const <String, String>{},
  );

  void _publishUrl(String url) {
    currentUrl.value = url;
    urlFieldController.text = url;
    final Uri? uri = Uri.tryParse(url);
    widget.onUrlChanged?.call(url, uri?.queryParameters ?? const <String, String>{});
  }

  Future<void> _refreshNavState() async {
    canGoBack.value = await controller.canGoBack();
    canGoForward.value = await controller.canGoForward();
  }

  Future<void> loadUrl(String url) => _load(url);

  Future<void> reload() => controller.reload();

  Future<void> goBack() => controller.goBack();

  Future<void> goForward() => controller.goForward();

  Future<void> goHome() => _load(widget.initialUrl, headers: widget.initialHeaders);

  Future<void> toggleDesktopMode() async {
    isDesktopMode.value = !isDesktopMode.value;
    await controller.setUserAgent(isDesktopMode.value ? widget.desktopUserAgent : widget.userAgent);
    await controller.reload();
  }

  Future<void> zoomIn() => controller.runJavaScript(
    "document.body.style.zoom = (parseFloat(document.body.style.zoom || 1) + 0.1).toString();",
  );

  Future<void> zoomOut() => controller.runJavaScript(
    "document.body.style.zoom = Math.max(0.5, parseFloat(document.body.style.zoom || 1) - 0.1).toString();",
  );

  void _submitUrlField() {
    String text = urlFieldController.text.trim();
    if (text.isEmpty) return;
    if (!text.contains("://")) text = "https://$text";
    loadUrl(text);
  }

  void _share() {
    if (widget.onShareRequested != null) {
      widget.onShareRequested!(currentUrl.value);
    } else {
      UClipboard.set(currentUrl.value, snackBar: true);
    }
  }

  void _openInBrowser() {
    widget.onOpenInBrowserRequested?.call(currentUrl.value);
  }

  @override
  void dispose() {
    currentUrl.dispose();
    isLoading.dispose();
    progress.dispose();
    canGoBack.dispose();
    canGoForward.dispose();
    isDesktopMode.dispose();
    loadError.dispose();
    urlFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      if (widget.showTopBar) _buildTopBar(context),
      if (widget.showProgressBar) _buildProgressBar(),
      Expanded(
        child: Stack(
          children: <Widget>[
            WebViewWidget(controller: controller),
            ValueListenableBuilder<String?>(
              valueListenable: loadError,
              builder: (BuildContext context, String? error, _) {
                if (error == null) return const SizedBox.shrink();
                return widget.errorBuilder?.call(context, error, reload) ?? _buildDefaultError(error);
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: isLoading,
              builder: (BuildContext context, bool loading, _) {
                if (!loading || widget.loadingIndicator == null) return const SizedBox.shrink();
                return widget.loadingIndicator!;
              },
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildDefaultError(String message) => ColoredBox(
    color: Theme.of(context).colorScheme.surface,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.error_outline, size: 40, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(message, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: reload, child: const Text("Retry")),
        ],
      ),
    ),
  );

  Widget _buildProgressBar() => ValueListenableBuilder<bool>(
    valueListenable: isLoading,
    builder: (BuildContext context, bool loading, _) => loading
        ? ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (BuildContext context, double p, _) => LinearProgressIndicator(value: p <= 0 ? null : p, minHeight: 2),
          )
        : const SizedBox(height: 2),
  );

  Widget _buildTopBar(BuildContext context) => Material(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: <Widget>[
          if (widget.showBackButton)
            ValueListenableBuilder<bool>(
              valueListenable: canGoBack,
              builder: (BuildContext context, bool can, _) => IconButton(
                tooltip: "Back",
                icon: const Icon(Icons.arrow_back),
                onPressed: can ? goBack : null,
              ),
            ),
          if (widget.showForwardButton)
            ValueListenableBuilder<bool>(
              valueListenable: canGoForward,
              builder: (BuildContext context, bool can, _) => IconButton(
                tooltip: "Forward",
                icon: const Icon(Icons.arrow_forward),
                onPressed: can ? goForward : null,
              ),
            ),
          if (widget.showRefreshButton)
            IconButton(
              tooltip: "Refresh",
              icon: const Icon(Icons.refresh),
              onPressed: reload,
            ),
          if (widget.showHomeButton)
            IconButton(
              tooltip: "Home",
              icon: const Icon(Icons.home_outlined),
              onPressed: goHome,
            ),
          if (widget.showUrlBar)
            Expanded(
              child: TextField(
                controller: urlFieldController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.go,
                onSubmitted: (_) => _submitUrlField(),
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  hintText: "Enter URL",
                ),
              ),
            )
          else
            const Spacer(),
          if (widget.showMoreMenu) _buildMoreMenu(context),
        ],
      ),
    ),
  );

  Widget _buildMoreMenu(BuildContext context) => PopupMenuButton<_MenuAction>(
    onSelected: (_MenuAction action) {
      switch (action) {
        case _MenuAction.share:
          _share();
        case _MenuAction.openInBrowser:
          _openInBrowser();
        case _MenuAction.copyLink:
          UClipboard.set(currentUrl.value, snackBar: true);
        case _MenuAction.desktopMode:
          toggleDesktopMode();
        case _MenuAction.zoomIn:
          zoomIn();
        case _MenuAction.zoomOut:
          zoomOut();
      }
    },
    itemBuilder: (BuildContext context) => <PopupMenuEntry<_MenuAction>>[
      if (widget.showShareAction) const PopupMenuItem<_MenuAction>(value: _MenuAction.share, child: Text("Share")),
      if (widget.showOpenInBrowserAction && widget.onOpenInBrowserRequested != null)
        const PopupMenuItem<_MenuAction>(
          value: _MenuAction.openInBrowser,
          child: Text("Open in browser"),
        ),
      if (widget.showCopyLinkAction) const PopupMenuItem<_MenuAction>(value: _MenuAction.copyLink, child: Text("Copy link")),
      if (widget.showDesktopModeAction)
        PopupMenuItem<_MenuAction>(
          value: _MenuAction.desktopMode,
          child: ValueListenableBuilder<bool>(
            valueListenable: isDesktopMode,
            builder: (BuildContext context, bool desktop, _) => Row(
              children: <Widget>[
                const Expanded(child: Text("Desktop site")),
                Checkbox(value: desktop, onChanged: (_) => toggleDesktopMode()),
              ],
            ),
          ),
        ),
      if (widget.showZoomActions) ...<PopupMenuEntry<_MenuAction>>[
        const PopupMenuItem<_MenuAction>(value: _MenuAction.zoomIn, child: Text("Zoom in")),
        const PopupMenuItem<_MenuAction>(value: _MenuAction.zoomOut, child: Text("Zoom out")),
      ],
    ],
  );
}

enum _MenuAction { share, openInBrowser, copyLink, desktopMode, zoomIn, zoomOut }
