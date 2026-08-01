import "package:u/utilities.dart";

/// Shared scaffold for every demo page: a titled app bar over a scrolling list
/// of [DemoSection]s, with an intro blurb at the top.
class GalleryPage extends StatelessWidget {
  const GalleryPage({
    required this.title,
    required this.intro,
    required this.sections,
    super.key,
  });

  final String title;
  final String intro;
  final List<Widget> sections;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UScaffold(
      appBar: AppBar(title: UTextTitleLarge(title, fontWeight: FontWeight.w700)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: UTextBodyMedium(intro, color: scheme.onSurfaceVariant),
          ),
          ...sections,
        ],
      ),
    );
  }
}
