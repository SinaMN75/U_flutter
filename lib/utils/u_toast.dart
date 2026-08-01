import "package:u/utilities.dart";

/// Semantic intent of a toast/snackbar/banner, driving its default color and icon.
enum UToastType { neutral, info, success, warning, error }

/// Where an overlay toast is anchored on screen.
enum UToastPosition { top, center, bottom }

abstract class UToast {
  static ThemeData get theme => Theme.of(navigatorKey.currentContext!);

  static ColorScheme get _scheme => theme.colorScheme;

  // Success/warning have no dedicated Material ColorScheme roles, so these act as
  // semantic fallbacks. error/info/neutral are derived from the active theme.
  static const Color _successColor = Color(0xFF2E7D32);
  static const Color _warningColor = Color(0xFFF9A825);
  static const Color _onSuccessColor = Color(0xFFFFFFFF);
  static const Color _onWarningColor = Color(0xFF1A1A1A);

  static Color _backgroundFor(UToastType type) {
    switch (type) {
      case UToastType.neutral:
        return theme.snackBarTheme.backgroundColor ?? _scheme.inverseSurface;
      case UToastType.info:
        return _scheme.primary;
      case UToastType.success:
        return _successColor;
      case UToastType.warning:
        return _warningColor;
      case UToastType.error:
        return _scheme.error;
    }
  }

  static Color _foregroundFor(UToastType type) {
    switch (type) {
      case UToastType.neutral:
        return theme.snackBarTheme.contentTextStyle?.color ?? _scheme.onInverseSurface;
      case UToastType.info:
        return _scheme.onPrimary;
      case UToastType.success:
        return _onSuccessColor;
      case UToastType.warning:
        return _onWarningColor;
      case UToastType.error:
        return _scheme.onError;
    }
  }

  static IconData? _iconFor(UToastType type) {
    switch (type) {
      case UToastType.neutral:
        return null;
      case UToastType.info:
        return Icons.info_outline_rounded;
      case UToastType.success:
        return Icons.check_circle_outline_rounded;
      case UToastType.warning:
        return Icons.warning_amber_rounded;
      case UToastType.error:
        return Icons.error_outline_rounded;
    }
  }

  // ---------------------------------------------------------------------------
  // SnackBars
  // ---------------------------------------------------------------------------

  static void snackBar({
    required String message,
    String? title,
    UToastType type = UToastType.neutral,
    IconData? icon,
    Duration duration = const Duration(seconds: 4),
    Color? backgroundColor,
    Color? foregroundColor,
    TextStyle? textStyle,
    SnackBarAction? action,
    String? actionLabel,
    VoidCallback? onAction,
    bool showCloseIcon = false,
    SnackBarBehavior? behavior,
    double? borderRadius,
    ShapeBorder? shape,
    double? elevation,
    DismissDirection dismissDirection = DismissDirection.down,
    EdgeInsets? margin,
    double? width,
    bool clearQueue = false,
    VoidCallback? onDismiss,
  }) {
    if (message.isNullOrEmpty()) return;
    final BuildContext ctx = navigatorKey.currentContext!;
    // Resolve visuals from explicit overrides first, then the semantic type
    final Color background = backgroundColor ?? _backgroundFor(type);
    final Color foreground = foregroundColor ?? _foregroundFor(type);
    final IconData? resolvedIcon = icon ?? _iconFor(type);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(ctx);
    if (clearQueue) messenger.clearSnackBars();

    // Build an action from either a ready SnackBarAction or a label+callback pair
    final SnackBarAction? resolvedAction = action ??
        (actionLabel != null
            ? SnackBarAction(label: actionLabel, textColor: foreground, onPressed: onAction ?? () {})
            : null);

    messenger
        .showSnackBar(
          SnackBar(
            content: Row(
              children: <Widget>[
                if (resolvedIcon != null) Icon(resolvedIcon, color: foreground).pOnly(right: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (title != null) UTextTitleSmall(title, color: foreground),
                      textStyle != null ? Text(message, style: textStyle) : UTextBodyMedium(message, color: foreground),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: background,
            duration: duration,
            action: resolvedAction,
            showCloseIcon: showCloseIcon,
            closeIconColor: foreground,
            dismissDirection: dismissDirection,
            behavior: behavior ?? ((margin != null || width != null) ? SnackBarBehavior.floating : null),
            margin: margin,
            width: width,
            elevation: elevation,
            shape: shape ?? (borderRadius != null ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)) : null),
          ),
        )
        .closed
        .then((_) => onDismiss?.call());
  }

  static void success({
    required String message,
    String? title,
    IconData? icon,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
    bool showCloseIcon = false,
    VoidCallback? onDismiss,
  }) =>
      snackBar(
        message: message,
        title: title,
        type: UToastType.success,
        icon: icon,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
        showCloseIcon: showCloseIcon,
        onDismiss: onDismiss,
      );

  static void warning({
    required String message,
    String? title,
    IconData? icon,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
    bool showCloseIcon = false,
    VoidCallback? onDismiss,
  }) =>
      snackBar(
        message: message,
        title: title,
        type: UToastType.warning,
        icon: icon,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
        showCloseIcon: showCloseIcon,
        onDismiss: onDismiss,
      );

  static void info({
    required String message,
    String? title,
    IconData? icon,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
    bool showCloseIcon = false,
    VoidCallback? onDismiss,
  }) =>
      snackBar(
        message: message,
        title: title,
        type: UToastType.info,
        icon: icon,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
        showCloseIcon: showCloseIcon,
        onDismiss: onDismiss,
      );

  static void error({
    required String message,
    String? title,
    IconData? icon,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
    bool showCloseIcon = false,
    VoidCallback? onDismiss,
  }) =>
      snackBar(
        message: message,
        title: title,
        type: UToastType.error,
        icon: icon,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
        showCloseIcon: showCloseIcon,
        onDismiss: onDismiss,
      );

  // Remove any queued/visible snackbars immediately
  static void clearSnackBars() => ScaffoldMessenger.of(navigatorKey.currentContext!).clearSnackBars();

  // ---------------------------------------------------------------------------
  // Material banners (persistent, top-anchored)
  // ---------------------------------------------------------------------------

  static void banner({
    required String message,
    String? title,
    UToastType type = UToastType.neutral,
    IconData? icon,
    List<Widget>? actions,
    String? actionLabel,
    VoidCallback? onAction,
    bool showDismiss = true,
    String? dismissLabel,
    Color? backgroundColor,
    Color? foregroundColor,
    bool clearQueue = true,
  }) {
    if (message.isNullOrEmpty()) return;
    final BuildContext ctx = navigatorKey.currentContext!;
    final Color background = backgroundColor ?? (type == UToastType.neutral ? _scheme.surfaceContainerHighest : _backgroundFor(type));
    final Color foreground = foregroundColor ?? (type == UToastType.neutral ? _scheme.onSurface : _foregroundFor(type));
    final IconData? resolvedIcon = icon ?? _iconFor(type);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(ctx);
    if (clearQueue) messenger.clearMaterialBanners();

    // Ensure the banner always has at least one action (MaterialBanner requires it)
    final List<Widget> resolvedActions = actions ??
        <Widget>[
          if (actionLabel != null)
            TextButton(
              onPressed: () {
                dismissBanner();
                onAction?.call();
              },
              style: TextButton.styleFrom(foregroundColor: foreground),
              child: Text(actionLabel),
            ),
          if (showDismiss || actionLabel == null)
            TextButton(
              onPressed: dismissBanner,
              style: TextButton.styleFrom(foregroundColor: foreground),
              child: Text(dismissLabel ?? U.s.close),
            ),
        ];

    messenger.showMaterialBanner(
      MaterialBanner(
        backgroundColor: background,
        leading: resolvedIcon != null ? Icon(resolvedIcon, color: foreground) : null,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (title != null) UTextTitleSmall(title, color: foreground),
            UTextBodyMedium(message, color: foreground),
          ],
        ),
        actions: resolvedActions,
      ),
    );
  }

  static void dismissBanner() => ScaffoldMessenger.of(navigatorKey.currentContext!).hideCurrentMaterialBanner();

  // ---------------------------------------------------------------------------
  // Overlay toasts (floating, animated, position-aware)
  // ---------------------------------------------------------------------------

  static OverlayEntry? _toastEntry;

  static void toast({
    required String message,
    String? title,
    UToastType type = UToastType.neutral,
    IconData? icon,
    UToastPosition position = UToastPosition.bottom,
    Duration duration = const Duration(seconds: 3),
    Duration animationDuration = const Duration(milliseconds: 300),
    Color? backgroundColor,
    Color? foregroundColor,
    EdgeInsets margin = const EdgeInsets.all(24),
    double borderRadius = 12,
    double elevation = 6,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
  }) {
    if (message.isNullOrEmpty()) return;
    final BuildContext ctx = navigatorKey.currentContext!;
    clearToast();

    final Color background = backgroundColor ?? (type == UToastType.neutral ? _scheme.inverseSurface : _backgroundFor(type));
    final Color foreground = foregroundColor ?? (type == UToastType.neutral ? _scheme.onInverseSurface : _foregroundFor(type));
    final IconData? resolvedIcon = icon ?? _iconFor(type);

    final OverlayEntry entry = OverlayEntry(
      builder: (BuildContext context) =>
          _UToastCard(
            message: message,
            title: title,
            icon: resolvedIcon,
            background: background,
            foreground: foreground,
            position: position,
            margin: margin,
            borderRadius: borderRadius,
            elevation: elevation,
            animationDuration: animationDuration,
            onTap: onTap,
          ),
    );

    _toastEntry = entry;
    Overlay.of(ctx).insert(entry);

    if (duration != Duration.zero) {
      Future<void>.delayed(duration, () {
        clearToast();
        onDismiss?.call();
      });
    }
  }

  static void successToast({required String message, String? title, IconData? icon, UToastPosition position = UToastPosition.bottom, Duration duration = const Duration(
      seconds: 3), VoidCallback? onTap, VoidCallback? onDismiss}) =>
      toast(message: message,
          title: title,
          type: UToastType.success,
          icon: icon,
          position: position,
          duration: duration,
          onTap: onTap,
          onDismiss: onDismiss);

  static void errorToast({required String message, String? title, IconData? icon, UToastPosition position = UToastPosition.bottom, Duration duration = const Duration(
      seconds: 3), VoidCallback? onTap, VoidCallback? onDismiss}) =>
      toast(message: message,
          title: title,
          type: UToastType.error,
          icon: icon,
          position: position,
          duration: duration,
          onTap: onTap,
          onDismiss: onDismiss);

  static void warningToast({required String message, String? title, IconData? icon, UToastPosition position = UToastPosition.bottom, Duration duration = const Duration(
      seconds: 3), VoidCallback? onTap, VoidCallback? onDismiss}) =>
      toast(message: message,
          title: title,
          type: UToastType.warning,
          icon: icon,
          position: position,
          duration: duration,
          onTap: onTap,
          onDismiss: onDismiss);

  static void infoToast({required String message, String? title, IconData? icon, UToastPosition position = UToastPosition.bottom, Duration duration = const Duration(
      seconds: 3), VoidCallback? onTap, VoidCallback? onDismiss}) =>
      toast(message: message,
          title: title,
          type: UToastType.info,
          icon: icon,
          position: position,
          duration: duration,
          onTap: onTap,
          onDismiss: onDismiss);

  static void clearToast() {
    _toastEntry?.remove();
    _toastEntry = null;
  }
}

class _UToastCard extends StatefulWidget {
  const _UToastCard({
    required this.message,
    required this.background,
    required this.foreground,
    required this.position,
    required this.margin,
    required this.borderRadius,
    required this.elevation,
    required this.animationDuration,
    this.title,
    this.icon,
    this.onTap,
  });

  final String message;
  final String? title;
  final IconData? icon;
  final Color background;
  final Color foreground;
  final UToastPosition position;
  final EdgeInsets margin;
  final double borderRadius;
  final double elevation;
  final Duration animationDuration;
  final VoidCallback? onTap;

  @override
  State<_UToastCard> createState() => _UToastCardState();
}

class _UToastCardState extends State<_UToastCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.animationDuration)
    ..forward();

  Alignment get _alignment =>
      switch (widget.position) {
        UToastPosition.top => Alignment.topCenter,
        UToastPosition.center => Alignment.center,
        UToastPosition.bottom => Alignment.bottomCenter,
      };

  Offset get _beginOffset =>
      switch (widget.position) {
        UToastPosition.top => const Offset(0, -1),
        UToastPosition.center => const Offset(0, 0.2),
        UToastPosition.bottom => const Offset(0, 1),
      };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CurvedAnimation curved = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    return SafeArea(
      child: Align(
        alignment: _alignment,
        child: Padding(
          padding: widget.margin,
          child: SlideTransition(
            position: Tween<Offset>(begin: _beginOffset, end: Offset.zero).animate(curved),
            child: FadeTransition(
              opacity: _controller,
              child: Material(
                type: MaterialType.transparency,
                child: UContainer(
                  color: widget.background,
                  radius: widget.borderRadius,
                  boxShadow: <BoxShadow>[BoxShadow(color: const Color(0x33000000), blurRadius: widget.elevation, offset: Offset(0, widget.elevation / 2))],
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (widget.icon != null) Icon(widget.icon, color: widget.foreground).pOnly(right: 12),
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (widget.title != null) UTextTitleSmall(widget.title!, color: widget.foreground),
                            UTextBodyMedium(widget.message, color: widget.foreground),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).onTap(widget.onTap ?? () {}),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// USAGE EXAMPLES
// -----------------------------------------------------------------------------
//
// SnackBars (bottom, anchored to Scaffold, queue-based)
// -----------------------------------------------------
//   UToast.snackBar(message: U.s.submitted);                 // neutral, backward-compatible
//   UToast.success(message: U.s.savedSuccessfully);
//   UToast.error(message: U.s.errorSubmittingForm);
//   UToast.warning(message: U.s.pleaseCheckYourInput, showCloseIcon: true);
//   UToast.info(message: U.s.syncing, actionLabel: U.s.cancel, onAction: controller.cancelSync);
//
//   // Fully custom snackbar (floating, rounded, with title + action).
//   UToast.snackBar(
//     title: U.s.newMessage,
//     message: senderName,
//     type: UToastType.info,
//     behavior: SnackBarBehavior.floating,
//     margin: const EdgeInsets.all(16),
//     borderRadius: 16,
//     actionLabel: U.s.open,
//     onAction: () => UNavigator.push(const ChatPage()),
//   );
//
//   UToast.clearSnackBars(); // drop everything currently queued
//
// Material banners (top, persistent until dismissed)
// --------------------------------------------------
//   UToast.banner(
//     message: U.s.youAreOffline,
//     type: UToastType.warning,
//     actionLabel: U.s.retry,
//     onAction: controller.reconnect,
//   );
//   UToast.dismissBanner();
//
// Overlay toasts (floating, animated, position-aware, not tied to a Scaffold)
// ---------------------------------------------------------------------------
//   UToast.successToast(message: U.s.copied, position: UToastPosition.top);
//   UToast.errorToast(message: U.s.somethingWentWrong);
//   UToast.toast(
//     title: U.s.download,
//     message: U.s.completed,
//     type: UToastType.success,
//     position: UToastPosition.center,
//     duration: const Duration(seconds: 2),
//     onTap: () => UNavigator.push(const DownloadsPage()),
//   );
//   UToast.clearToast();
// -----------------------------------------------------------------------------
