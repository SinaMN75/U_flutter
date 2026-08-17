import "package:u/utilities.dart";

class UNavAction<T> {
  const UNavAction({
    required this.label,
    required this.value,
    this.icon,
    this.isDestructive = false,
    this.enabled = true,
  });

  final String label;
  final T value;
  final IconData? icon;
  final bool isDestructive;
  final bool enabled;
}

abstract class UNavigator {
  static BuildContext get context => navigatorKey.currentContext!;

  static bool get canPop => Navigator.of(context).canPop();

  static String? get currentRouteName => ModalRoute.of(context)?.settings.name;

  static Future<T?> push<T>(
    Widget page, {
    bool fullscreenDialog = false,
    bool preventDuplicates = true,
    bool opaque = true,
    bool maintainState = true,
    RouteTransitions transition = RouteTransitions.rightToLeft,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
    RouteSettings? settings,
    Object? arguments,
    VoidCallback? onDismiss,
  }) {
    if (preventDuplicates && ModalRoute.of(navigatorKey.currentContext!)?.settings.name == page.runtimeType.toString()) {
      return Future<T?>.value();
    }

    return Navigator.push<T>(
      navigatorKey.currentContext!,
      PageRouteBuilder<T>(
        pageBuilder: (BuildContext context, Animation<double> _, Animation<double> __) => page,
        transitionsBuilder: _getTransition(transition, curve),
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        settings: settings ?? RouteSettings(arguments: arguments),
        fullscreenDialog: fullscreenDialog,
        opaque: opaque,
        maintainState: maintainState,
      ),
    ).then((T? value) {
      onDismiss?.call();
      return value;
    });
  }

  static Future<T?> off<T>(
    Widget page, {
    RouteTransitions transition = RouteTransitions.fade,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
    bool fullscreenDialog = false,
    RouteSettings? settings,
    Object? arguments,
    T? result,
    VoidCallback? onDismiss,
  }) =>
      Navigator.pushReplacement<T, dynamic>(
        navigatorKey.currentContext!,
        PageRouteBuilder<T>(
          pageBuilder: (BuildContext context, Animation<double> _, Animation<double> __) => page,
          transitionsBuilder: _getTransition(transition, curve),
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          settings: settings ?? RouteSettings(arguments: arguments),
          fullscreenDialog: fullscreenDialog,
        ),
        result: result,
      ).then((T? value) {
        onDismiss?.call();
        return value;
      });

  static Future<void> offAll(
    Widget page, {
    RouteTransitions transition = RouteTransitions.fade,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
    RouteSettings? settings,
    Object? arguments,
    VoidCallback? onDismiss,
  }) async {
    await Navigator.pushAndRemoveUntil(
      navigatorKey.currentContext!,
      PageRouteBuilder<dynamic>(
        pageBuilder: (BuildContext context, Animation<double> _, Animation<double> __) => page,
        transitionsBuilder: _getTransition(transition, curve),
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        settings: settings ?? RouteSettings(arguments: arguments),
      ),
      (Route<dynamic> route) => false,
    ).then((_) => onDismiss?.call());
  }

  static Future<T?> offUntil<T>(
    Widget page, {
    required String untilRouteName,
    RouteTransitions transition = RouteTransitions.rightToLeft,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
    RouteSettings? settings,
    Object? arguments,
  }) => Navigator.pushAndRemoveUntil<T>(
    navigatorKey.currentContext!,
    PageRouteBuilder<T>(
      pageBuilder: (BuildContext context, Animation<double> _, Animation<double> __) => page,
      transitionsBuilder: _getTransition(transition, curve),
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      settings: settings ?? RouteSettings(arguments: arguments),
    ),
    (Route<dynamic> route) => route.settings.name == untilRouteName,
  );

  static void back<T>([T? result]) {
    if (Navigator.of(navigatorKey.currentContext!).canPop()) {
      Navigator.pop<T>(navigatorKey.currentContext!, result);
    }
  }

  static Future<bool> maybeBack<T>([T? result]) => Navigator.of(context).maybePop<T>(result);

  static void backUntil(String routeName) => Navigator.of(context).popUntil((Route<dynamic> route) => route.settings.name == routeName);

  static void backToRoot() => Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);

  static void backCount(int count) {
    final NavigatorState navigator = Navigator.of(context);
    for (int i = 0; i < count && navigator.canPop(); i++) {
      navigator.pop();
    }
  }

  static Future<T?> dialog<T>(
    Widget child, {
    bool barrierDismissible = true,
    bool useRootNavigator = true,
    Color? barrierColor,
    RouteSettings? settings,
    VoidCallback? onDismiss,
  }) => UApp.isIos
      ? showCupertinoDialog<T>(
          context: navigatorKey.currentContext!,
          barrierDismissible: barrierDismissible,
          useRootNavigator: useRootNavigator,
          builder: (BuildContext context) => child,
        ).then((T? value) {
          onDismiss?.call();
          return value;
        })
      : showDialog<T>(
          context: navigatorKey.currentContext!,
          barrierDismissible: barrierDismissible,
          useRootNavigator: useRootNavigator,
          barrierColor: barrierColor ?? Colors.black54,
          routeSettings: settings,
          builder: (BuildContext context) => child,
        ).then((T? value) {
          onDismiss?.call();
          return value;
        });

  static Future<T?> animatedDialog<T>(
    Widget child, {
    bool barrierDismissible = true,
    bool useRootNavigator = true,
    Color? barrierColor,
    RouteTransitions transition = RouteTransitions.fadeScale,
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.easeOut,
    Alignment alignment = Alignment.center,
    VoidCallback? onDismiss,
  }) =>
      showGeneralDialog<T>(
        context: navigatorKey.currentContext!,
        barrierDismissible: barrierDismissible,
        barrierLabel: MaterialLocalizations.of(navigatorKey.currentContext!).modalBarrierDismissLabel,
        barrierColor: barrierColor ?? Colors.black54,
        useRootNavigator: useRootNavigator,
        transitionDuration: duration,
        pageBuilder: (BuildContext context, Animation<double> _, Animation<double> __) => Align(alignment: alignment, child: child),
        transitionBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget widget) =>
            _getTransition(transition, curve)(context, animation, secondaryAnimation, widget),
      ).then((T? value) {
        onDismiss?.call();
        return value;
      });

  static Future<T?> dialogResponsive<T>({
    required Widget child,
    Widget? title,
    bool barrierDismissible = true,
    bool useRootNavigator = true,
    Color? barrierColor,
    RouteSettings? settings,
    VoidCallback? onDismiss,
    double initialChildSize = 0.5,
    double minChildSize = 0.25,
    double maxChildSize = 0.9,
    bool expand = false,
  }) {
    if (UApp.isMobileSize()) {
      return showModalBottomSheet<T>(
        context: navigatorKey.currentContext!,
        isScrollControlled: true,
        useRootNavigator: useRootNavigator,
        builder: (BuildContext context) => DraggableScrollableSheet(
          expand: expand,
          initialChildSize: initialChildSize,
          minChildSize: minChildSize,
          maxChildSize: maxChildSize,
          builder: (BuildContext context, ScrollController controller) => UScaffold(
            appBar: AppBar(title: title),
            body: SingleChildScrollView(controller: controller, child: child),
          ),
        ),
      ).then((T? value) {
        onDismiss?.call();
        return value;
      });
    }
    return dialog(
      AlertDialog(title: title, content: child),
      barrierDismissible: barrierDismissible,
      useRootNavigator: useRootNavigator,
      barrierColor: barrierColor,
      settings: settings,
      onDismiss: onDismiss,
    );
  }

  static Future<void> alert({
    required String title,
    required String message,
    String? buttonText,
    IconData? icon,
    bool barrierDismissible = true,
  }) => dialog(
    AlertDialog.adaptive(
      icon: icon != null ? Icon(icon) : null,
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        TextButton(onPressed: back, child: Text(buttonText ?? U.s.ok)),
      ],
    ),
    barrierDismissible: barrierDismissible,
  );

  static void confirm({
    required String title,
    required String message,
    bool destructive = false,
    String? confirmText,
    String? cancelText,
    IconData? icon,
    bool barrierDismissible = true,
    bool dismissOnConfirm = true,
    bool dismissOnCancel = true,
    VoidCallback? onDismiss,
    VoidCallback? onCancel,
    VoidCallback? onConfirm,
  }) => dialog(
    AlertDialog.adaptive(
      icon: icon != null ? Icon(icon) : null,
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            if (dismissOnCancel) back();
            onCancel?.call();
          },
          child: Text(cancelText ?? U.s.cancel),
        ),
        TextButton(
          onPressed: () {
            if (dismissOnConfirm) back();
            onConfirm?.call();
          },
          style: destructive ? TextButton.styleFrom(foregroundColor: Theme.of(navigatorKey.currentContext!).colorScheme.error) : null,
          child: Text(confirmText ?? U.s.ok),
        ),
      ],
    ),
    barrierDismissible: barrierDismissible,
    onDismiss: onDismiss,
  );

  static Future<bool> confirmAsync({
    required String title,
    required String message,
    bool destructive = false,
    String? confirmText,
    String? cancelText,
    IconData? icon,
    bool barrierDismissible = true,
  }) async {
    final bool? result = await dialog<bool>(
      AlertDialog.adaptive(
        icon: icon != null ? Icon(icon) : null,
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(onPressed: () => back(false), child: Text(cancelText ?? U.s.cancel)),
          TextButton(
            onPressed: () => back(true),
            style: destructive ? TextButton.styleFrom(foregroundColor: Theme.of(navigatorKey.currentContext!).colorScheme.error) : null,
            child: Text(confirmText ?? U.s.ok),
          ),
        ],
      ),
      barrierDismissible: barrierDismissible,
    );
    return result ?? false;
  }

  static Future<String?> inputDialog({
    required String title,
    required String hint,
    Function(String)? onSubmit,
    VoidCallback? onCancel,
    String defaultValue = "",
    String? submitText,
    String? cancelText,
    int lines = 4,
    TextInputType keyboardType = TextInputType.multiline,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) async {
    final TextEditingController controller = TextEditingController(text: defaultValue);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final String? text = await showDialog<String>(
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) => AlertDialog.adaptive(
        title: Text(title),
        content: Material(
          type: MaterialType.transparency,
          child: Form(
            key: formKey,
            child: UTextField(
              hintText: hint,
              lines: lines,
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              validator: validator,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: onCancel ?? back, child: Text(cancelText ?? U.s.cancel)),
          TextButton(
            onPressed: () {
              if (validator == null || (formKey.currentState?.validate() ?? true)) back(controller.text);
            },
            child: Text(submitText ?? U.s.submit),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text != null && onSubmit != null) {
      onSubmit(text);
    }
    return text;
  }

  static Future<Color?> colorPicker({
    required Color defaultColor,
    List<Color>? colors,
    String? title,
  }) async => UNavigator.dialog<Color>(
    AlertDialog(
      title: Text(title ?? U.s.selectA(U.s.color)),
      content: SizedBox(
        width: 200,
        height: 100,
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: (colors ?? <Color>[Colors.red, Colors.green, Colors.blue, Colors.yellow, Colors.orange, Colors.purple, Colors.pink, Colors.cyan, Colors.black, Colors.teal])
              .map(
                (Color color) => UContainer(
                  width: 40,
                  height: 40,
                  color: color,
                  radius: 100,
                  border: color == defaultColor ? Border.all(width: 3) : null,
                ).onTap(() => UNavigator.back(color)),
              )
              .toList(),
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: UNavigator.back, child: Text(U.s.cancel)),
      ],
    ),
  );

  static Future<DateTime?> datePicker({
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String? helpText,
    DatePickerEntryMode initialEntryMode = DatePickerEntryMode.calendar,
    DatePickerMode initialDatePickerMode = DatePickerMode.day,
  }) => showDatePicker(
    context: navigatorKey.currentContext!,
    initialDate: initialDate ?? DateTime.now(),
    firstDate: firstDate ?? DateTime(1900),
    lastDate: lastDate ?? DateTime(2100),
    helpText: helpText,
    initialEntryMode: initialEntryMode,
    initialDatePickerMode: initialDatePickerMode,
  );

  static Future<DateTimeRange?> dateRangePicker({
    DateTimeRange? initialRange,
    DateTime? firstDate,
    DateTime? lastDate,
    String? helpText,
  }) => showDateRangePicker(
    context: navigatorKey.currentContext!,
    initialDateRange: initialRange,
    firstDate: firstDate ?? DateTime(1900),
    lastDate: lastDate ?? DateTime(2100),
    helpText: helpText,
  );

  static Future<TimeOfDay?> timePicker({
    TimeOfDay? initialTime,
    String? helpText,
    TimePickerEntryMode initialEntryMode = TimePickerEntryMode.dial,
  }) => showTimePicker(
    context: navigatorKey.currentContext!,
    initialTime: initialTime ?? TimeOfDay.now(),
    helpText: helpText,
    initialEntryMode: initialEntryMode,
  );

  static Future<T?> bottomSheet<T>(
    Widget child, {
    bool isScrollControlled = true,
    bool useSafeArea = true,
    bool isDismissible = true,
    bool enableDrag = true,
    bool showDragHandle = false,
    bool useRootNavigator = true,
    double? elevation,
    Color? backgroundColor,
    Color? barrierColor,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    VoidCallback? onDismiss,
  }) {
    final Future<T?> sheetFuture = showModalBottomSheet<T>(
      context: navigatorKey.currentContext!,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      showDragHandle: showDragHandle,
      useRootNavigator: useRootNavigator,
      backgroundColor: backgroundColor ?? Theme.of(navigatorKey.currentContext!).canvasColor,
      barrierColor: barrierColor,
      elevation: elevation,
      shape:
          shape ??
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
      clipBehavior: clipBehavior ?? Clip.antiAlias,
      constraints: constraints,
      builder: (BuildContext context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(navigatorKey.currentContext!).viewInsets.bottom,
        ),
        child: child,
      ),
    );

    return sheetFuture.then((T? value) {
      onDismiss?.call();
      return value;
    });
  }

  static Future<T?> draggableSheet<T>(
    Widget child, {
    double initialChildSize = 0.5,
    double minChildSize = 0.25,
    double maxChildSize = 0.9,
    bool expand = false,
    bool snap = false,
    List<double>? snapSizes,
    bool useRootNavigator = true,
    bool showDragHandle = false,
    Color? backgroundColor,
    ShapeBorder? shape,
    VoidCallback? onDismiss,
  }) =>
      showModalBottomSheet<T>(
        context: navigatorKey.currentContext!,
        isScrollControlled: true,
        useRootNavigator: useRootNavigator,
        showDragHandle: showDragHandle,
        backgroundColor: backgroundColor,
        shape: shape,
        builder: (BuildContext context) => DraggableScrollableSheet(
          expand: expand,
          snap: snap,
          snapSizes: snapSizes,
          initialChildSize: initialChildSize,
          minChildSize: minChildSize,
          maxChildSize: maxChildSize,
          builder: (BuildContext context, ScrollController controller) => SingleChildScrollView(
            controller: controller,
            child: child,
          ),
        ),
      ).then((T? value) {
        onDismiss?.call();
        return value;
      });

  static Future<T?> actionSheet<T>({
    required List<UNavAction<T>> actions,
    String? title,
    String? message,
    bool showCancel = true,
    String? cancelText,
    bool barrierDismissible = true,
  }) {
    final BuildContext ctx = navigatorKey.currentContext!;
    if (UApp.isIos) {
      return showCupertinoModalPopup<T>(
        context: ctx,
        barrierDismissible: barrierDismissible,
        builder: (BuildContext context) => CupertinoActionSheet(
          title: title != null ? Text(title) : null,
          message: message != null ? Text(message) : null,
          actions: actions
              .map(
                (UNavAction<T> action) => CupertinoActionSheetAction(
                  isDestructiveAction: action.isDestructive,
                  onPressed: action.enabled ? () => back<T>(action.value) : () {},
                  child: Text(action.label),
                ),
              )
              .toList(),
          cancelButton: showCancel
              ? CupertinoActionSheetAction(
                  onPressed: back,
                  child: Text(cancelText ?? U.s.cancel),
                )
              : null,
        ),
      );
    }
    return showModalBottomSheet<T>(
      context: ctx,
      isDismissible: barrierDismissible,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: UColumn(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (title != null) UTextTitleMedium(title, textAlign: TextAlign.center).pOnly(bottom: 4),
            if (message != null) UTextBodySmall(message, textAlign: TextAlign.center).pOnly(bottom: 8),
            ...actions.map(
              (UNavAction<T> action) => ListTile(
                enabled: action.enabled,
                leading: action.icon != null ? Icon(action.icon, color: action.isDestructive ? Theme.of(context).colorScheme.error : null) : null,
                title: UTextBodyLarge(
                  action.label,
                  color: action.isDestructive ? Theme.of(context).colorScheme.error : null,
                ),
                onTap: () => back<T>(action.value),
              ),
            ),
            if (showCancel)
              ListTile(
                title: UTextBodyLarge(cancelText ?? U.s.cancel, textAlign: TextAlign.center),
                onTap: back,
              ),
          ],
        ),
      ),
    );
  }

  static Future<T?> fullScreenDialog<T>(
    Widget page, {
    RouteTransitions transition = RouteTransitions.upToDown,
    VoidCallback? onDismiss,
  }) => push<T>(page, fullscreenDialog: true, transition: transition).then((T? value) {
    onDismiss?.call();
    return value;
  });

  static OverlayEntry? _currentOverlay;

  static void showOverlay({
    required Widget child,
    Duration duration = const Duration(seconds: 3),
    Duration animationDuration = const Duration(milliseconds: 250),
    Alignment alignment = Alignment.topCenter,
    EdgeInsets padding = const EdgeInsets.all(20),
    bool dismissOnTap = false,
    VoidCallback? onDismiss,
  }) {
    dismissOverlay();

    final OverlayEntry overlay = OverlayEntry(
      builder: (BuildContext context) => SafeArea(
        child: Padding(
          padding: padding,
          child: Align(
            alignment: alignment,
            // Fade the overlay in for a smoother appearance
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: animationDuration,
              builder: (BuildContext context, double opacity, Widget? animatedChild) => Opacity(opacity: opacity, child: animatedChild),
              child: Material(
                color: Colors.transparent,
                child: dismissOnTap
                    ? GestureDetector(
                        onTap: () {
                          dismissOverlay();
                          onDismiss?.call();
                        },
                        child: child,
                      )
                    : child,
              ),
            ),
          ),
        ),
      ),
    );

    _currentOverlay = overlay;
    Overlay.of(navigatorKey.currentContext!).insert(overlay);

    if (duration != Duration.zero) {
      Future<void>.delayed(duration, () {
        dismissOverlay();
        onDismiss?.call();
      });
    }
  }

  static void dismissOverlay() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  static Widget Function(BuildContext, Animation<double>, Animation<double>, Widget) _getTransition(RouteTransitions transition, [Curve curve = Curves.easeOut]) {
    switch (transition) {
      case RouteTransitions.none:
        return (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) => child;
      case RouteTransitions.fade:
        return (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: curve),
          child: child,
        );
      case RouteTransitions.fadeScale:
        return (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
          final Animation<double> curved = CurvedAnimation(parent: animation, curve: curve);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(scale: Tween<double>(begin: 0.9, end: 1).animate(curved), child: child),
          );
        };
      case RouteTransitions.slideFade:
        return (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
          final Animation<double> curved = CurvedAnimation(parent: animation, curve: curve);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.15, 0), end: Offset.zero).animate(curved),
              child: child,
            ),
          );
        };
      case RouteTransitions.rightToLeft:
        return (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn)),
          child: child,
        );
      case RouteTransitions.leftToRight:
        return (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: curve)),
          child: child,
        );
      case RouteTransitions.upToDown:
        return (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: curve)),
          child: child,
        );
      case RouteTransitions.downToUp:
        return (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: curve)),
          child: child,
        );
      case RouteTransitions.scale:
        return (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) => ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: curve),
          child: child,
        );
      case RouteTransitions.rotate:
        return (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) => RotationTransition(
          turns: CurvedAnimation(parent: animation, curve: curve),
          child: child,
        );
      case RouteTransitions.size:
        return (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) => Align(
          child: SizeTransition(
            sizeFactor: CurvedAnimation(parent: animation, curve: curve),
            child: child,
          ),
        );
      case RouteTransitions.cupertino:
        return (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) => CupertinoPageTransition(
          primaryRouteAnimation: animation,
          secondaryRouteAnimation: secondaryAnimation,
          linearTransition: false,
          child: child,
        );
    }
  }
}

enum RouteTransitions {
  none,
  fade,
  fadeScale,
  slideFade,
  rightToLeft,
  leftToRight,
  upToDown,
  downToUp,
  scale,
  rotate,
  size,
  cupertino,
}

// -----------------------------------------------------------------------------
// USAGE EXAMPLES
// -----------------------------------------------------------------------------
//
// Page navigation
// ---------------
//   // Push with a transition and read the result the pushed page returns via back(result).
//   final bool? saved = await UNavigator.push<bool>(
//     const EditProfilePage(),
//     transition: RouteTransitions.cupertino,
//     arguments: <String, dynamic>{"id": 12},
//   );
//
//   // Replace the current page (e.g. splash -> home).
//   UNavigator.off(const HomePage(), transition: RouteTransitions.fade);
//
//   // Clear the whole stack (e.g. after logout).
//   UNavigator.offAll(const LoginPage());
//
//   // Push a page and remove everything above a known route.
//   UNavigator.offUntil(const CheckoutPage(), untilRouteName: "CartPage");
//
//   // Pop helpers.
//   UNavigator.back();                 // pop top
//   UNavigator.back<int>(42);          // pop and return a value
//   UNavigator.backUntil("HomePage");  // pop down to a named route
//   UNavigator.backToRoot();           // pop everything to the first route
//   await UNavigator.maybeBack();      // pop respecting PopScope guards
//   if (UNavigator.canPop) UNavigator.back();
//
// Dialogs
// -------
//   // Info alert with one button.
//   await UNavigator.alert(title: U.s.success, message: U.s.savedSuccessfully);
//
//   // Fire-and-forget confirm with callbacks.
//   UNavigator.confirm(
//     title: U.s.delete,
//     message: U.s.areYouSureYouWantToDelete,
//     destructive: true,
//     icon: Icons.warning_amber_rounded,
//     onConfirm: () => controller.delete(),
//   );
//
//   // Awaitable confirm.
//   if (await UNavigator.confirmAsync(title: U.s.logout, message: U.s.areYouSureYouWantToLogOut)) {
//     UNavigator.offAll(const LoginPage());
//   }
//
//   // Text input.
//   final String? name = await UNavigator.inputDialog(
//     title: U.s.name,
//     hint: U.s.enterName,
//     lines: 1,
//     validator: UValidators.required,
//   );
//
//   // Custom dialog with its own enter/exit animation.
//   UNavigator.animatedDialog(const MyCard(), transition: RouteTransitions.fadeScale);
//
// Pickers
// -------
//   final DateTime? date = await UNavigator.datePicker(initialDate: DateTime.now());
//   final TimeOfDay? time = await UNavigator.timePicker();
//   final DateTimeRange? range = await UNavigator.dateRangePicker();
//   final Color? color = await UNavigator.colorPicker(defaultColor: Theme.of(context).colorScheme.primary);
//
// Bottom sheets
// -------------
//   // Simple modal sheet.
//   UNavigator.bottomSheet(const FilterPanel(), showDragHandle: true);
//
//   // Draggable, resizable sheet.
//   UNavigator.draggableSheet(const CommentsList(), initialChildSize: 0.6, snap: true);
//
//   // Adaptive action sheet returning the chosen value.
//   final String? choice = await UNavigator.actionSheet<String>(
//     title: U.s.select,
//     actions: <UNavAction<String>>[
//       UNavAction<String>(label: U.s.edit, value: "edit", icon: Icons.edit),
//       UNavAction<String>(label: U.s.delete, value: "delete", icon: Icons.delete, isDestructive: true),
//     ],
//   );
//
// Overlays
// --------
//   // Transient toast-like overlay (auto-dismisses after `duration`).
//   UNavigator.showOverlay(child: const MyBanner(), dismissOnTap: true);
//   UNavigator.dismissOverlay(); // dismiss manually
// -----------------------------------------------------------------------------
