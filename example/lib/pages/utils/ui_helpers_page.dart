import "package:u/utilities.dart";

import "../../demo/demo.dart";

/// UNavigator, UToast, ULoading, UValidators, UDebouncer/UThrottler/URetry, delay.
class UiHelpersPage extends StatefulWidget {
  const UiHelpersPage({super.key});

  @override
  State<UiHelpersPage> createState() => _UiHelpersPageState();
}

class _UiHelpersPageState extends State<UiHelpersPage> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _password = TextEditingController();
  final UDebouncer _debouncer = UDebouncer(delay: 500.ms);
  final UThrottler _throttler = UThrottler(interval: 1.seconds);
  int _debounced = 0;
  int _throttled = 0;

  @override
  void dispose() {
    _password.dispose();
    _debouncer.dispose();
    _throttler.dispose();
    super.dispose();
  }

  Widget _page(String text) => UScaffold(
    appBar: AppBar(title: Text(text)),
    body: Center(
      child: UButton(title: "Back", onTap: UNavigator.back),
    ),
  );

  @override
  Widget build(BuildContext context) => DemoPage(
    title: "Navigation, feedback, forms",
    children: <Widget>[
      DemoGroup("Pages", <Widget>[
        Fn("UNavigator.context / canPop / currentRouteName", () => <Object?>[UNavigator.context.runtimeType, UNavigator.canPop, UNavigator.currentRouteName]),
        Fn("await UNavigator.push(page)", () => UNavigator.push<void>(_page("Pushed"))),
        Fn("UNavigator.push(page, transition: fadeScale)", () => UNavigator.push<void>(_page("Fade"), transition: URouteTransitions.fadeScale)),
        Fn("UNavigator.fullScreenDialog(page)", () => UNavigator.fullScreenDialog<void>(_page("Full screen dialog"))),
        Act(
          "UNavigator.off(page) (replace)",
          () => UNavigator.push<void>(
            UScaffold(
              appBar: AppBar(),
              body: Center(
                child: UButton(title: "off()", onTap: () => UNavigator.off<void>(_page("Replaced"))),
              ),
            ),
          ),
        ),
        Act(
          "UNavigator.offUntil(page, untilRouteName: …)",
          () => UNavigator.push<void>(
            UScaffold(
              appBar: AppBar(),
              body: Center(
                child: UButton(
                  title: "offUntil()",
                  onTap: () => UNavigator.offUntil<void>(_page("offUntil"), untilRouteName: "/"),
                ),
              ),
            ),
          ),
        ),
        Act(
          "UNavigator.offAll(page)",
          () =>
              UNavigator.confirm(title: "offAll?", message: "Clears the stack; use back to return is not possible. Continue?", onConfirm: () => UNavigator.offAll(_page("Restart the app to go back"))),
        ),
        Act(
          "UNavigator.back() / maybeBack() / backCount(1)",
          () => UNavigator.push<void>(
            UScaffold(
              appBar: AppBar(),
              body: Center(
                child: UColumn(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: <Widget>[
                    UButton(title: "back()", onTap: UNavigator.back),
                    UButton(title: "maybeBack()", onTap: UNavigator.maybeBack),
                    UButton(title: "backCount(1)", onTap: () => UNavigator.backCount(1)),
                  ],
                ),
              ),
            ),
          ),
        ),
        Act(
          'UNavigator.backUntil("/") / backToRoot()',
          () => UNavigator.push<void>(
            UScaffold(
              appBar: AppBar(),
              body: Center(
                child: UColumn(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: <Widget>[
                    UButton(title: 'backUntil("/")', onTap: () => UNavigator.backUntil("/")),
                    UButton(title: "backToRoot()", onTap: UNavigator.backToRoot),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
      DemoGroup("Dialogs & sheets", <Widget>[
        Fn('UNavigator.alert(title: "Done", message: "Saved")', () => UNavigator.alert(title: "Done", message: "Saved")),
        Act(
          "UNavigator.confirm(…, onConfirm: …)",
          () => UNavigator.confirm(
            title: "Delete?",
            message: "Cannot be undone",
            destructive: true,
            onConfirm: () => UToast.success(message: "Deleted"),
          ),
        ),
        Fn("await UNavigator.confirmAsync(…)", () => UNavigator.confirmAsync(title: "Logout?", message: "You will need to sign in again")),
        Fn('await UNavigator.inputDialog(title: "Name", hint: "…")', () => UNavigator.inputDialog(title: "Name", hint: "Your name", lines: 1)),
        Fn("await UNavigator.colorPicker(defaultColor: …)", () => UNavigator.colorPicker(defaultColor: Colors.blue)),
        Fn("await UNavigator.datePicker()", UNavigator.datePicker),
        Fn("await UNavigator.dateRangePicker()", UNavigator.dateRangePicker),
        Fn("await UNavigator.timePicker()", UNavigator.timePicker),
        Fn("UNavigator.dialog(AlertDialog(…))", () => UNavigator.dialog<void>(const AlertDialog(title: Text("Plain dialog"), content: Text("Tap outside to close")))),
        Fn(
          "UNavigator.animatedDialog(child, transition: …)",
          () => UNavigator.animatedDialog<void>(
            const Card(
              child: Padding(padding: EdgeInsets.all(24), child: Text("Animated")),
            ),
            transition: URouteTransitions.downToUp,
          ),
        ),
        Fn(
          "UNavigator.dialogResponsive(child: …)",
          () => UNavigator.dialogResponsive<void>(
            title: const Text("Responsive"),
            child: const Padding(padding: EdgeInsets.all(16), child: Text("Bottom sheet on phones, dialog on wide screens")),
          ),
        ),
        Fn(
          "UNavigator.bottomSheet(child)",
          () => UNavigator.bottomSheet<void>(
            const SafeArea(
              child: Padding(padding: EdgeInsets.all(24), child: Text("Bottom sheet")),
            ),
            showDragHandle: true,
          ),
        ),
        Fn("UNavigator.draggableSheet(child)", () => UNavigator.draggableSheet<void>(Column(children: List<Widget>.generate(30, (int i) => ListTile(title: Text("Row $i")))), showDragHandle: true)),
        Fn(
          "UNavigator.actionSheet(actions: …)",
          () => UNavigator.actionSheet<void>(
            title: "Photo",
            actions: <UNavAction>[
              UNavAction(label: "Edit", icon: Icons.edit, onTap: UNavigator.back),
              UNavAction(label: "Delete", icon: Icons.delete, isDestructive: true, onTap: UNavigator.back),
            ],
          ),
        ),
        Act("UNavigator.showOverlay(child: …)", () => UNavigator.showOverlay(child: const UPill("Overlay for 3 s", icon: Icons.info))),
        Act("UNavigator.dismissOverlay()", UNavigator.dismissOverlay),
      ]),
      DemoGroup("Toasts & snackbars", <Widget>[
        Fn("UToast.theme.brightness", () => UToast.theme.brightness),
        Act(
          'UToast.snackBar(message: …, actionLabel: "Undo")',
          () => UToast.snackBar(
            message: "Item removed",
            actionLabel: "Undo",
            onAction: () => UToast.info(message: "Restored"),
          ),
        ),
        Act("UToast.success / warning / info / error", () {
          UToast.success(message: "Saved");
          UToast.warning(message: "Check your input");
          UToast.info(message: "New version");
          UToast.error(message: "Could not connect");
        }),
        Act("UToast.clearSnackBars()", UToast.clearSnackBars),
        Act("UToast.banner(message: …)", () => UToast.banner(message: "You are offline", type: UToastType.warning)),
        Act("UToast.dismissBanner()", UToast.dismissBanner),
        Act('UToast.toast(message: "Copied", position: top)', () => UToast.toast(message: "Copied", position: UToastPosition.top)),
        Act("UToast.successToast / errorToast / warningToast / infoToast", () {
          UToast.successToast(message: "Done");
          Future<void>.delayed(1.seconds, () => UToast.errorToast(message: "Failed"));
          Future<void>.delayed(2.seconds, () => UToast.warningToast(message: "Careful"));
          Future<void>.delayed(3.seconds, () => UToast.infoToast(message: "FYI"));
        }),
        Act("UToast.clearToast()", UToast.clearToast),
      ]),
      DemoGroup("Loading overlay", <Widget>[
        Fn("ULoading.show(text: …); 2 s; dismiss()", () async {
          ULoading.show(text: "Please wait");
          await Future<void>.delayed(2.seconds);
          ULoading.dismiss();
          return ULoading.isShowing();
        }),
        Fn("ULoading.show(percent: 0) … setPercent … update", () async {
          ULoading.show(text: "Uploading", percent: 0);
          for (int p = 10; p <= 100; p += 10) {
            await Future<void>.delayed(150.ms);
            ULoading.setPercent(p);
          }
          ULoading.update(text: "Done");
          await Future<void>.delayed(500.ms);
          ULoading.dismiss();
          return ULoading.percent;
        }),
        Fn("ULoading.settings", () => ULoading.settings.blurAmount),
        Fn("ULoading.initialize(settings: …)", () => ULoading.initialize(settings: ULoading.settings)),
      ]),
      DemoGroup("Form validators", <Widget>[
        Demo(
          "UValidators.* on UTextField + validateForm",
          child: Form(
            key: _form,
            child: UColumn(
              spacing: 8,
              children: <Widget>[
                UTextField(labelText: "Required", validator: UValidators.required()),
                UTextField(labelText: "Email", validator: UValidators.email()),
                UTextField(labelText: "Phone", validator: UValidators.phone()),
                UTextField(labelText: "Number 4-6 digits", validator: UValidators.number(minLength: 4, maxLength: 6)),
                UTextField(labelText: "National code", validator: UValidators.iranianNationalCode()),
                UTextField(labelText: "Tax memory id", validator: UValidators.iranianTaxPayerCode(isRequired: false)),
                UTextField(labelText: "Card number", validator: UValidators.cardNumber(isRequired: false)),
                UTextField(labelText: "IBAN", validator: UValidators.iban(isRequired: false)),
                UTextField(
                  labelText: "1-100",
                  validator: UValidators.numberRange(min: 1, max: 100, rangeMessage: "1-100", invalidNumberMessage: "Not a number"),
                ),
                UTextField(labelText: "URL", validator: UValidators.url(isRequired: false)),
                UTextField(labelText: "Username", validator: UValidators.alphanumeric(isRequired: false)),
                UTextField(
                  labelText: "Mobile (09…)",
                  validator: UValidators.pattern(pattern: RegExp(r"^09\d{9}$"), message: "Invalid", isRequired: false),
                ),
                UTextField(
                  labelText: "Min 3 / max 10 / exact",
                  validator: UValidators.combineValidators(<FormFieldValidator<String>>[
                    UValidators.minLength(minLength: 3, message: "Too short"),
                    UValidators.maxLength(maxLength: 10, message: "Too long"),
                  ]),
                ),
                UTextField(
                  labelText: "Exactly 5",
                  validator: UValidators.exactLength(length: 5, message: "Must be 5"),
                ),
                UTextField(
                  labelText: "Password",
                  controller: _password,
                  obscureText: true,
                  validator: UValidators.password(weakMessage: "Too weak", isRequired: false),
                ),
                UTextField(
                  labelText: "Repeat password",
                  obscureText: true,
                  validator: UValidators.matchController(controller: _password, mismatchMessage: "Not the same"),
                ),
                UTextField(
                  labelText: 'Type "yes"',
                  validator: UValidators.match(otherValue: "yes", mismatchMessage: "Type yes"),
                ),
                UTextField(labelText: "Complex password", obscureText: true, validator: UValidators.complexPassword()),
                UButton(
                  title: "Validate",
                  onTap: () => UValidators.validateForm(
                    key: _form,
                    action: () => UToast.success(message: "Valid"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
      DemoGroup("Timing helpers", <Widget>[
        Demo(
          "UDebouncer(delay: 500.ms).run(…) · isPending · cancel()",
          child: UTextField(hintText: "Type fast… ($_debounced runs)", onChanged: (String _) => _debouncer.run(() => setState(() => _debounced++))),
        ),
        Fn("UDebouncer.isPending / cancel()", () {
          final bool pending = _debouncer.isPending;
          _debouncer.cancel();
          return pending;
        }),
        Demo(
          "UThrottler(interval: 1.seconds).run(…)",
          child: UButton(title: "Tap many times ($_throttled accepted)", onTap: () => _throttler.run(() => setState(() => _throttled++))),
        ),
        Fn("UThrottler.cancel()", () {
          _throttler.cancel();
          return "reset";
        }),
        Fn("URetry.run(flaky, attempts: 3)", () {
          int tries = 0;
          return URetry.run(() async {
            tries++;
            if (tries < 3) throw Exception("try $tries failed");
            return "ok after $tries tries";
          }, delay: 200.ms);
        }),
        Fn('delay(500, () => UToast.info(message: "later"))', () => delay(500, () => UToast.info(message: "later"))),
      ]),
    ],
  );
}
