import "package:u/utilities.dart";

import "../../demo/demo.dart";

/// Layout boxes, text, buttons, general widgets, badges, progress, loading states.
class LayoutComponentsPage extends StatefulWidget {
  const LayoutComponentsPage({super.key});

  @override
  State<LayoutComponentsPage> createState() => _LayoutComponentsPageState();
}

class _LayoutComponentsPageState extends State<LayoutComponentsPage> {
  bool _open = false;
  bool _saving = false;
  int _plan = 1;
  final UFlipCardController _flip = UFlipCardController();

  Future<List<String>> _loadNames() async {
    await Future<void>.delayed(1.seconds);
    return <String>["Sina", "Sara", "Ali"];
  }

  Future<List<int>> _page(int page) async {
    await Future<void>.delayed(600.ms);
    return page > 3 ? <int>[] : List<int>.generate(20, (int i) => (page - 1) * 20 + i);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return DemoPage(
      title: "Layout & basics",
      children: <Widget>[
        DemoGroup("Boxes", <Widget>[
          Demo(
            "UContainer(radius: 12, color: …, padding: …, onTap: …, tooltip: …)",
            child: UContainer(
              radius: 12,
              color: scheme.primaryContainer,
              padding: const EdgeInsets.all(16),
              onTap: () => UToast.toast(message: "tapped"),
              tooltip: "UContainer",
              child: const Text("Tap me"),
            ),
          ),
          Demo(
            "UColumn(spacing: 8) / URow(spacing: 8)",
            child: UColumn(
              spacing: 8,
              children: <Widget>[
                URow(spacing: 8, children: const <Widget>[Icon(Icons.star), Text("row"), Text("items")]),
                const Text("column item"),
              ],
            ),
          ),
          Demo(
            "UStack / UCenter / UAspectRatio",
            child: UAspectRatio(
              aspectRatio: 16 / 5,
              child: UStack(
                color: scheme.surfaceContainerHighest,
                radius: 12,
                children: const <Widget>[UCenter(child: Text("centered in a 16:5 stack"))],
              ),
            ),
          ),
          Demo("UWrap(spacing: 8, runSpacing: 8)", child: UWrap(spacing: 8, runSpacing: 8, children: List<Widget>.generate(8, (int i) => UPill("tag $i")))),
          Demo(
            "UIconTextHorizontal / UIconTextVertical",
            child: URow(
              spacing: 24,
              children: const <Widget>[
                UIconTextHorizontal(leading: Icon(Icons.phone), trailing: Text("0912 123 4567")),
                UIconTextVertical(leading: Icon(Icons.home), trailing: Text("Home")),
              ],
            ),
          ),
          Demo(
            "UKeyValue(leading: …, trailing: …)",
            child: UKeyValue(leading: const Text("Total"), trailing: Text(1500000.toman())),
          ),
          Demo(
            "UCard(onTap: …)",
            child: UCard(
              onTap: () => UToast.toast(message: "card"),
              child: const Padding(padding: EdgeInsets.all(16), child: Text("UCard")),
            ),
          ),
          Demo(
            "UAnimatedContainer(duration: 300.ms, width: open ? 220 : 80)",
            child: UAnimatedContainer(
              duration: 300.ms,
              width: _open ? 220 : 80,
              height: 40,
              radius: 20,
              color: scheme.primary,
              onTap: () => setState(() => _open = !_open),
              child: const Center(child: Icon(Icons.touch_app, color: Colors.white)),
            ),
          ),
          Demo("UConstrained(maxWidth: 200)", child: UConstrained(maxWidth: 200, child: const Text("This text is kept inside 200 logical pixels however wide the screen is."))),
          Demo(
            "UDivider() / UDivider(axis: vertical)",
            child: SizedBox(
              height: 40,
              child: URow(
                children: const <Widget>[
                  Expanded(child: UDivider()),
                  SizedBox(height: 30, child: UDivider(axis: Axis.vertical)),
                  Expanded(child: UDivider()),
                ],
              ),
            ),
          ),
          Demo(
            "UResponsive(mobile: …, tablet: …, desktop: …)",
            child: const UResponsive(mobile: Text("📱 mobile layout"), tablet: Text("📟 tablet layout"), desktop: Text("🖥 desktop layout")),
          ),
          Demo(
            "uWrap(widget, onTap: …, tooltip: …)",
            child: uWrap(
              const Text("wrapped text"),
              onTap: () => UToast.toast(message: "uWrap"),
              tooltip: "uWrap adds box/tap options",
            ),
          ),
        ]),
        DemoGroup("Lists & grids", <Widget>[
          Demo(
            "UListView(itemCount: …, itemBuilder: …, separatorBuilder: …)",
            child: SizedBox(
              height: 120,
              child: UListView(
                itemCount: 10,
                itemBuilder: (BuildContext c, int i) => ListTile(dense: true, title: Text("Row $i")),
                separatorBuilder: (BuildContext c, int i) => const Divider(height: 1),
              ),
            ),
          ),
          Demo(
            "UGridView(crossAxisCount: 4, …)",
            child: SizedBox(
              height: 120,
              child: UGridView(
                crossAxisCount: 4,
                itemCount: 12,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                itemBuilder: (BuildContext c, int i) => UContainer(
                  color: scheme.secondaryContainer,
                  radius: 8,
                  child: Center(child: Text("$i")),
                ),
              ),
            ),
          ),
          Demo(
            "USliverList / USliverGrid in a CustomScrollView",
            child: SizedBox(
              height: 160,
              child: CustomScrollView(
                slivers: <Widget>[
                  USliverGrid(crossAxisCount: 6, itemCount: 12, itemBuilder: (BuildContext c, int i) => Center(child: Text("g$i"))),
                  USliverList(itemCount: 5, itemBuilder: (BuildContext c, int i) => ListTile(dense: true, title: Text("sliver row $i"))),
                ],
              ),
            ),
          ),
          Demo(
            "UScaffold + UDefaultTabBar",
            child: UButton(
              title: "Open",
              onTap: () => UNavigator.push<void>(
                UScaffold(
                  appBar: AppBar(title: const Text("UScaffold")),
                  body: const UDefaultTabBar(
                    tabBar: TabBar(
                      tabs: <Widget>[
                        Tab(text: "One"),
                        Tab(text: "Two"),
                      ],
                    ),
                    children: <Widget>[
                      Center(child: Text("Page one")),
                      Center(child: Text("Page two")),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ]),
        DemoGroup("Text", <Widget>[
          const Demo(
            "UTextDisplayLarge / Medium / Small",
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[UTextDisplayLarge("Display L"), UTextDisplayMedium("Display M"), UTextDisplaySmall("Display S")]),
          ),
          const Demo(
            "UTextHeadlineLarge / Medium / Small",
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[UTextHeadlineLarge("Headline L"), UTextHeadlineMedium("Headline M"), UTextHeadlineSmall("Headline S")]),
          ),
          const Demo(
            "UTextTitleLarge / Medium / Small",
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[UTextTitleLarge("Title L"), UTextTitleMedium("Title M"), UTextTitleSmall("Title S")]),
          ),
          const Demo(
            "UTextBodyLarge / Medium / Small",
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[UTextBodyLarge("Body L"), UTextBodyMedium("Body M"), UTextBodySmall("Body S")]),
          ),
          const Demo(
            "UTextLabelLarge / Medium / Small",
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[UTextLabelLarge("Label L"), UTextLabelMedium("Label M"), UTextLabelSmall("Label S")]),
          ),
          Demo("UAnimatedCounter(value: 1250000, builder: …)", child: UAnimatedCounter(value: 1250000, builder: (BuildContext c, double v) => UTextHeadlineMedium(v.toInt().toman()))),
          Demo(
            "UReadMoreText(text, trimLines: 2)",
            child: UReadMoreText(
              "Flutter is Google's UI toolkit for building beautiful, natively compiled applications for mobile, web, desktop and embedded devices from a single codebase. Visit https://flutter.dev to learn more.",
              trimLines: 2,
              trimMode: UTrimMode.line,
              onLinkPressed: (String url) => ULaunch.url(url),
            ),
          ),
          Demo(
            "UScrollingText(text: …)",
            child: const SizedBox(height: 24, child: UScrollingText(text: "Breaking: this long headline scrolls sideways because it does not fit on one line of the screen.")),
          ),
          Demo('UJsonViewer(jsonString: …)', child: const UJsonViewer(jsonString: '{"user":{"id":1,"name":"Sina","roles":["admin","dev"]},"active":true}')),
        ]),
        DemoGroup("Buttons", <Widget>[
          Demo(
            "UButton(title: …, type: …)",
            child: UWrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final UButtonType t in <UButtonType>[UButtonType.elevated, UButtonType.filled, UButtonType.filledTonal, UButtonType.outlined, UButtonType.text])
                  UButton(
                    title: t.name,
                    type: t,
                    onTap: () => UToast.toast(message: t.name),
                  ),
                UButton(title: "icon", icon: const Icon(Icons.send), onTap: () {}),
              ],
            ),
          ),
          Demo(
            "UButton(isLoading: …)",
            child: UButton(
              title: "Save",
              isLoading: _saving,
              onTap: () async {
                setState(() => _saving = true);
                await Future<void>.delayed(1500.ms);
                if (mounted) setState(() => _saving = false);
              },
            ),
          ),
          Demo(
            "UButton(counter: 10, …) resend countdown",
            child: UButton(
              title: "Resend code",
              counter: 10,
              counterDescription: "to resend",
              onTap: () => UToast.success(message: "Sent"),
            ),
          ),
          Demo(
            "USendAgainCountDown(counter: 10, …)",
            child: USendAgainCountDown(
              counter: 10,
              onSendAgainTap: () => UToast.success(message: "Sent"),
              buttonTitle: "Resend",
              counterDescription: "until resend",
            ),
          ),
          Demo(
            "UButtonSubmitCancel(onSubmit: …)",
            child: UButtonSubmitCancel(
              onSubmit: () => UToast.success(message: "Submitted"),
              onCancel: () => UToast.info(message: "Cancelled"),
            ),
          ),
          Demo(
            "UPressable(onTap: …, child: …)",
            child: UPressable(
              onTap: () => UToast.toast(message: "pressed"),
              child: const UPill("press me", icon: Icons.touch_app),
            ),
          ),
        ]),
        DemoGroup("General widgets", <Widget>[
          Demo(
            "UListTile(icon: …, title: …, onTap: …)",
            child: UListTile(icon: Icons.person, title: "Profile", subtitle: "Edit your info", onTap: () {}),
          ),
          Demo(
            "UIconBackground / UImageBackground",
            child: URow(
              spacing: 12,
              children: <Widget>[
                UIconBackground(Icons.wallet, color: scheme.primary),
                const UImageBackground("assets/icons/phone.svg", color: Colors.teal),
              ],
            ),
          ),
          Demo(
            "UGlassCard(child: …)",
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(gradient: LinearGradient(colors: <Color>[Colors.purple, Colors.orange])),
              child: const UGlassCard(
                child: Padding(padding: EdgeInsets.all(16), child: Text("Frosted glass")),
              ),
            ),
          ),
          Demo(
            "UHeaderCard(icon: …, title: …, subtitle: …)",
            child: const UHeaderCard(icon: Icons.info_outline, title: "Welcome", subtitle: "Start by completing your profile"),
          ),
          Demo(
            "UEmptyState(icon: …, title: …, action: …) / UErrorRetry(onTap: …)",
            child: URow(
              children: <Widget>[
                Expanded(
                  child: UEmptyState(
                    icon: Icons.inbox,
                    title: "No orders yet",
                    action: UButton(title: "Shop", onTap: () {}),
                  ),
                ),
                Expanded(
                  child: UErrorRetry(onTap: () => UToast.info(message: "Retrying")),
                ),
              ],
            ),
          ),
          Demo(
            "UPill(label, color: …, icon: …)",
            child: const URow(
              spacing: 8,
              children: <Widget>[
                UPill("Paid", color: Colors.green, icon: Icons.check),
                UPill("Pending", color: Colors.orange),
              ],
            ),
          ),
          Demo(
            "USelectionCard(title: …, isSelected: …, onTap: …)",
            child: UColumn(
              spacing: 8,
              children: <Widget>[
                USelectionCard(title: "Monthly", subtitle: "Cancel anytime", isSelected: _plan == 1, onTap: () => setState(() => _plan = 1), pills: const <Widget>[UPill("Popular")]),
                USelectionCard(title: "Yearly", subtitle: "2 months free", isSelected: _plan == 2, onTap: () => setState(() => _plan = 2)),
              ],
            ),
          ),
          Demo(
            "UInfoRow(label, value: …) / UStatTile(caption: …, value: …)",
            child: UColumn(
              spacing: 8,
              children: <Widget>[
                const UInfoRow("Subtotal", value: "1,200,000 تومان"),
                const UInfoRow("Total", value: "1,350,000 تومان", isStrong: true),
                const URow(
                  spacing: 8,
                  children: <Widget>[
                    Expanded(
                      child: UStatTile(caption: "Sales", value: "128", unit: "orders"),
                    ),
                    Expanded(
                      child: UStatTile(caption: "Stock", value: "42", secondaryValue: "100"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Demo(
            "UActionTile(icon: …, title: …, onTap: …)",
            child: UActionTile(icon: Icons.qr_code, title: "Scan to pay", subtitle: "Point the camera at a QR code", onTap: () {}),
          ),
          Demo(
            "UAlertBanner(title: …, tone: …)",
            child: const UColumn(
              spacing: 8,
              children: <Widget>[
                UAlertBanner(title: "Heads up", message: "Info banner"),
                UAlertBanner(title: "Payment failed", tone: UAlertTone.danger),
              ],
            ),
          ),
          Demo(
            "UAvatar(url: …, name: …) · UAvatar.initialsOf",
            child: URow(
              spacing: 12,
              children: <Widget>[
                const UAvatar(name: "Sina Mohammadzadeh"),
                const UAvatar(url: "https://i.pravatar.cc/150?img=3", name: "Photo"),
                Text(UAvatar.initialsOf("سینا محمدزاده")),
              ],
            ),
          ),
          Demo(
            "USearchField(onSearch: …)",
            child: USearchField(onSearch: (String q) => UToast.toast(message: "search: $q")),
          ),
          Demo("UCopyText(text, copyValue: …)", child: const UCopyText("IR06 2960 0000 0010 0324 2000 01", copyValue: "IR062960000000100324200001")),
          Demo(
            "UBadgeWidget(badgeContent: …) / ULetterBadge / UBadgePositioned",
            child: URow(
              spacing: 24,
              children: <Widget>[
                const UBadgeWidget(
                  badgeContent: Text("3", style: TextStyle(color: Colors.white, fontSize: 10)),
                  child: Icon(Icons.shopping_cart),
                ),
                const ULetterBadge("Sina", background: Colors.teal, foreground: Colors.white),
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: Stack(
                    children: <Widget>[
                      Icon(Icons.mail),
                      UBadgePositioned(child: Icon(Icons.circle, size: 8, color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Demo(
            "UFlipCard(front: …, back: …) + UFlipCardController",
            child: UColumn(
              spacing: 8,
              children: <Widget>[
                UFlipCard(
                  controller: _flip,
                  front: UContainer(
                    height: 60,
                    color: scheme.primaryContainer,
                    radius: 12,
                    child: const Center(child: Text("Front — tap")),
                  ),
                  back: UContainer(
                    height: 60,
                    color: scheme.tertiaryContainer,
                    radius: 12,
                    child: const Center(child: Text("Back")),
                  ),
                ),
                UWrap(
                  spacing: 8,
                  children: <Widget>[
                    UButton(title: "toggleCard", onTap: _flip.toggleCard),
                    UButton(title: "without animation", onTap: _flip.toggleCardWithoutAnimation),
                    UButton(title: "skew", onTap: () => _flip.skew(0.2)),
                    UButton(title: "hint", onTap: _flip.hint),
                  ],
                ),
              ],
            ),
          ),
          Demo("UAnimationCard (one side during the flip)", child: const UAnimationCard(child: Text("animation card"))),
        ]),
        DemoGroup("Progress & loading", <Widget>[
          const Demo("UProgressLinear(value: 40) / indeterminate", child: UColumn(spacing: 8, children: <Widget>[UProgressLinear(value: 40), UProgressLinear()])),
          const Demo("UProgressCircular(value: 70) / indeterminate", child: URow(spacing: 16, children: <Widget>[UProgressCircular(value: 70), UProgressCircular()])),
          Demo(
            "UCircularPercentIndicator(radius: 30, percent: 0.7)",
            child: UCircularPercentIndicator(radius: 30, lineWidth: 6, percent: 0.7, center: const Text("70%"), circularStrokeCap: UCircularStrokeCap.round),
          ),
          Demo("ULinearPercentIndicator(percent: 0.4)", child: ULinearPercentIndicator(percent: 0.4, lineHeight: 8, barRadius: const Radius.circular(8))),
          Fn("UCircularStrokeCap.round.strokeCap / radians(90)", () => <Object>[UCircularStrokeCap.round.strokeCap, radians(90)], auto: true),
          Demo(
            "USkeleton(width: 120) / USkeleton.circle(40) / USkeleton.lines(3)",
            child: URow(
              spacing: 12,
              children: <Widget>[
                const USkeleton.circle(40),
                const USkeleton(width: 60),
                Expanded(child: USkeleton.lines(3)),
              ],
            ),
          ),
          Demo("USkeleton.listTile() / USkeleton.list(count: 3)", child: SizedBox(height: 180, child: USkeleton.list(count: 3))),
          Demo(
            "USkeleton.wrap(child: Text(…))",
            child: USkeleton.wrap(child: const Text("Shimmers in the shape of this text", style: TextStyle(fontSize: 18))),
          ),
          Demo(
            "UAsyncBuilder(load: …, builder: …)",
            child: SizedBox(
              height: 80,
              child: UAsyncBuilder<List<String>>(load: _loadNames, builder: (BuildContext c, List<String> names) => Text(names.join(", "))),
            ),
          ),
          Demo(
            "UStreamView(stream: …, builder: …)",
            child: UStreamView<int>(stream: Stream<int>.periodic(1.seconds, (int i) => i).take(100), builder: (BuildContext c, int v) => Text("tick $v")),
          ),
          Demo(
            "UPaginatedList(fetch: (page) => …, itemBuilder: …)",
            child: SizedBox(
              height: 200,
              child: UPaginatedList<int>(
                fetch: _page,
                itemBuilder: (BuildContext c, int item, int i) => ListTile(dense: true, title: Text("Item $item")),
              ),
            ),
          ),
          Demo(
            "UOnlineBuilder(builder: (c, online) => …)",
            child: UOnlineBuilder(builder: (BuildContext c, bool online) => UPill(online ? "Online" : "Offline", color: online ? Colors.green : Colors.red)),
          ),
          Demo(
            "UOfflineBanner(child: …)",
            child: SizedBox(
              height: 60,
              child: UOfflineBanner(
                child: Container(
                  color: scheme.surfaceContainerHighest,
                  child: const Center(child: Text("page under the banner")),
                ),
              ),
            ),
          ),
        ]),
      ],
    );
  }
}
