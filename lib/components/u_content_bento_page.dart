import "package:u/utilities.dart";

class UContentBentoPage extends StatelessWidget {
  const UContentBentoPage({
    required this.content,
    super.key,
    this.title,
    this.padding = const EdgeInsets.all(16),
  });

  final UContentResponse? content;
  final String? title;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(title ?? _text(content?.jsonData.title) ?? U.s.contents)),
    body: _buildBody(context),
  );

  Widget _buildBody(BuildContext context) {
    final UContentResponse? c = content;
    if (c == null) return const Center(child: UEmptyState());

    final List<_Bento> tiles = _tiles(context, c);
    if (tiles.isEmpty) return const Center(child: UEmptyState());

    final int columns = MediaQuery.of(context).size.width >= 1000 ? 3 : 2;

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _pack(tiles, columns),
      ),
    );
  }

  List<Widget> _pack(List<_Bento> tiles, int columns) {
    final List<Widget> out = <Widget>[];
    List<_Bento> rowBuffer = <_Bento>[];
    int used = 0;

    void flush() {
      if (rowBuffer.isEmpty) return;
      final List<Widget> cells = <Widget>[
        for (final _Bento b in rowBuffer) Expanded(flex: b.span, child: b.child),
      ];
      final int remaining = columns - used;
      if (remaining > 0) cells.add(Expanded(flex: remaining, child: const SizedBox()));
      out.add(
        IntrinsicHeight(
          child: Row(spacing: 12, crossAxisAlignment: CrossAxisAlignment.stretch, children: cells),
        ),
      );
      rowBuffer = <_Bento>[];
      used = 0;
    }

    for (final _Bento b in tiles) {
      if (b.span >= columns) {
        flush();
        out.add(b.child);
        continue;
      }
      if (used + b.span > columns) flush();
      rowBuffer.add(b);
      used += b.span;
    }
    flush();
    return out;
  }

  List<_Bento> _tiles(BuildContext context, UContentResponse c) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final UContentJson j = c.jsonData;
    final List<_Bento> tiles = <_Bento>[];

    final Widget? hero = _hero(context, c);
    if (hero != null) tiles.add(_Bento(child: hero, span: 99));

    if (_has(j.description)) {
      tiles.add(_Bento(child: _richTile(context, j.description!), span: 99));
    }

    if (_has(j.detail1)) tiles.add(_Bento(child: _detailTile(context, j.detail1!, Icons.article_outlined, scheme.primary), span: 1));
    if (_has(j.detail2)) tiles.add(_Bento(child: _detailTile(context, j.detail2!, Icons.notes_outlined, scheme.tertiary), span: 1));

    for (final UContentItem item in j.items) {
      final Widget? tile = _itemTile(context, item);
      if (tile != null) tiles.add(_Bento(child: tile, span: 1));
    }

    if (j.links.isNotEmpty) {
      final Widget? links = _linksTile(context, j.links);
      if (links != null) tiles.add(_Bento(child: links, span: 99));
    }

    if (_has(j.phone)) tiles.add(_Bento(child: _contactTile(context, j.phone!), span: 1));

    final Widget? follow = _followTile(context, j);
    if (follow != null) tiles.add(_Bento(child: follow, span: 1));

    if (_has(j.link)) tiles.add(_Bento(child: _websiteTile(context, j.link!), span: 1));

    if (_has(j.buttonText) && _has(j.buttonLink)) {
      tiles.add(_Bento(child: _ctaTile(context, j.buttonText!, j.buttonLink!), span: 99));
    }

    return tiles;
  }

  // ---- Tiles -------------------------------------------------------------

  Widget? _hero(BuildContext context, UContentResponse c) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final UContentJson j = c.jsonData;
    final String? mediaUrl = c.media.firstOrNull?.url;
    final Uint8List? imageBytes = _decodeBase64(j.imageBase64);
    final bool hasNetwork = mediaUrl != null && mediaUrl.length > 10;
    final bool hasImage = hasNetwork || imageBytes != null;

    if (!hasImage && !_has(j.title) && !_has(j.subTitle)) return null;

    const double height = 210;
    final Color foreground = hasImage ? const Color(0xFFFFFFFF) : scheme.onPrimary;

    final Widget background = hasImage
        ? (hasNetwork
              ? UImageNetwork(mediaUrl, width: double.infinity, height: height, fit: BoxFit.cover, borderRadius: 24)
              : UImageMemory(imageBytes!, width: double.infinity, height: height, fit: BoxFit.cover, borderRadius: 24))
        : DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[scheme.primary, scheme.primaryContainer],
              ),
            ),
          );

    final Uint8List? icon = _decodeBase64(j.iconBase64);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            background,
            if (hasImage)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[scheme.scrim.withValues(alpha: 0), scheme.scrim.withValues(alpha: 0.65)],
                  ),
                ),
              ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (icon != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: UContainer(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        radius: 14,
                        color: foreground.withValues(alpha: 0.18),
                        child: UImageMemory(icon, width: 26, height: 26),
                      ),
                    ),
                  if (_has(j.title)) UTextTitleLarge(j.title!, color: foreground, fontWeight: FontWeight.bold, maxLines: 2),
                  if (_has(j.subTitle))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: UTextBodySmall(j.subTitle!, color: foreground.withValues(alpha: 0.9), maxLines: 2),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _richTile(BuildContext context, String value) => _surface(
    context,
    child: _looksLikeHtml(value) ? UHtmlView(html: value, selectable: true, onLinkTap: ULaunch.launchURL) : UTextBodyMedium(value, overflow: TextOverflow.visible, height: 1.5),
  );

  Widget _detailTile(BuildContext context, String value, IconData icon, Color accent) => _surface(
    context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        UIconBackground(icon, color: accent, size: 40),
        const SizedBox(height: 12),
        UTextBodyMedium(value, overflow: TextOverflow.visible, maxLines: 8, height: 1.45),
      ],
    ),
  );

  Widget? _itemTile(BuildContext context, UContentItem item) {
    if (!_has(item.title) && !_has(item.subTitle) && !_has(item.description) && item.imageBase64 == null && item.iconBase64 == null) {
      return null;
    }
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Uint8List? image = _decodeBase64(item.imageBase64);
    final Uint8List? icon = _decodeBase64(item.iconBase64);
    final String? tapLink = _text(item.link);

    return _surface(
      context,
      onTap: tapLink == null ? null : () => ULaunch.launchURL(tapLink),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (image != null)
            UImageMemory(image, width: double.infinity, height: 96, fit: BoxFit.cover, borderRadius: 14)
          else if (icon != null)
            UContainer(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              radius: 12,
              color: scheme.primary.withValues(alpha: 0.14),
              child: UImageMemory(icon, width: 26, height: 26),
            )
          else
            UIconBackground(Icons.widgets_outlined, color: scheme.primary, size: 44),
          const SizedBox(height: 10),
          if (_has(item.title)) UTextTitleSmall(item.title!, fontWeight: FontWeight.bold, maxLines: 1),
          if (_has(item.subTitle))
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: UTextBodySmall(item.subTitle!, color: scheme.onSurfaceVariant, maxLines: 2),
            ),
          if (_has(item.description))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: UTextBodySmall(item.description!, color: scheme.onSurfaceVariant, maxLines: 3, overflow: TextOverflow.visible),
            ),
        ],
      ),
    );
  }

  Widget? _linksTile(BuildContext context, List<UContentLink> links) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<Widget> chips = <Widget>[];
    for (final UContentLink link in links) {
      final String? url = _text(link.url);
      if (url == null) continue;
      final Uint8List? icon = _decodeBase64(link.iconBase64);
      chips.add(
        Material(
          color: scheme.secondaryContainer,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => ULaunch.launchURL(url),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (icon != null)
                    Padding(padding: const EdgeInsets.only(right: 8), child: UImageMemory(icon, width: 18, height: 18))
                  else
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(Icons.link_rounded, size: 18, color: scheme.onSecondaryContainer),
                    ),
                  UTextLabelMedium(_text(link.title) ?? url, color: scheme.onSecondaryContainer, maxLines: 1),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (chips.isEmpty) return null;

    return _surface(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          UTextLabelLarge(U.s.links, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ),
    );
  }

  Widget _contactTile(BuildContext context, String phone) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return _surface(
      context,
      background: scheme.primaryContainer,
      border: scheme.primaryContainer,
      onTap: () => ULaunch.call(phone),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const UImage(UIcons.phone, package: "u"),
          const SizedBox(height: 12),
          UTextLabelMedium(U.s.contactUs, color: scheme.onPrimaryContainer.withValues(alpha: 0.7)),
          const SizedBox(height: 2),
          UTextTitleSmall(phone, color: scheme.onPrimaryContainer, fontWeight: FontWeight.bold, maxLines: 1, textDirection: TextDirection.ltr),
        ],
      ),
    );
  }

  Widget? _followTile(BuildContext context, UContentJson j) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<Widget> buttons = <Widget>[];
    if (_has(j.instagram)) buttons.add(_socialButton(UIcons.instagram, () => _openSocial(j.instagram!, ULaunch.launchInstagram)));
    if (_has(j.telegram)) buttons.add(_socialButton(UIcons.telegram, () => _openSocial(j.telegram!, ULaunch.launchTelegram)));
    if (_has(j.whatsapp)) buttons.add(_socialButton(UIcons.whatsapp, () => _openSocial(j.whatsapp!, ULaunch.launchWhatsApp)));
    if (buttons.isEmpty) return null;

    return _surface(
      context,
      background: scheme.secondaryContainer,
      border: scheme.secondaryContainer,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          UTextLabelMedium(U.s.followUs, color: scheme.onSecondaryContainer.withValues(alpha: 0.7)),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: buttons),
        ],
      ),
    );
  }

  Widget _websiteTile(BuildContext context, String link) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return _surface(
      context,
      background: scheme.tertiaryContainer,
      border: scheme.tertiaryContainer,
      onTap: () => ULaunch.launchURL(link),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.language_rounded, color: scheme.onTertiaryContainer),
          const SizedBox(height: 12),
          UTextTitleSmall(U.s.visitWebsite, color: scheme.onTertiaryContainer, fontWeight: FontWeight.bold, maxLines: 1),
        ],
      ),
    );
  }

  Widget _ctaTile(BuildContext context, String label, String link) => UButton(
    title: label,
    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
    iconPosition: UButtonIconPosition.trailing,
    height: 52,
    borderRadius: 18,
    onTap: () => ULaunch.launchURL(link),
  );

  // ---- Shared building blocks -------------------------------------------

  Widget _surface(
    BuildContext context, {
    required Widget child,
    Color? background,
    Color? border,
    VoidCallback? onTap,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      color: background ?? scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: border ?? scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }

  Widget _socialButton(String icon, VoidCallback onTap) => UImage(icon, width: 22, package: "u").pAll(12).onPress(onTap);

  // ---- Helpers ----------------------------------------------------------

  static bool _has(String? value) => value != null && value.trim().isNotEmpty;

  static String? _text(String? value) => _has(value) ? value!.trim() : null;

  static bool _looksLikeHtml(String value) => value.contains("<") && value.contains(">");

  static void _openSocial(String value, Future<void> Function(String) fallback) {
    if (value.startsWith("http")) {
      ULaunch.launchURL(value);
    } else {
      fallback(value);
    }
  }

  static Uint8List? _decodeBase64(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      String data = raw.trim();
      final int comma = data.indexOf(",");
      if (data.startsWith("data:") && comma != -1) data = data.substring(comma + 1);
      if (data.length < 16) return null;
      return base64Decode(data);
    } on FormatException {
      return null;
    }
  }
}

class _Bento {
  const _Bento({required this.child, required this.span});

  final Widget child;
  final int span;
}
