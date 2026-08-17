import "package:u/utilities.dart";

/// A single documented demo block: a title, a plain-language description of what
/// the `u` API does, the live widget/result, and (optionally) the exact code
/// that produced it. Every gallery page is a list of these.
class DemoSection extends StatelessWidget {
  const DemoSection({
    required this.title,
    required this.description,
    required this.child,
    this.code,
    super.key,
  });

  final String title;
  final String description;
  final Widget child;
  final String? code;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          UTextTitleMedium(title, fontWeight: FontWeight.w700),
          UTextBodySmall(description, color: scheme.onSurfaceVariant),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: child),
          if (code != null) _CodeBlock(code: code!),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: SelectableText(
        code.trim(),
        style: TextStyle(
          fontFamily: "monospace",
          fontSize: 12.5,
          height: 1.5,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}

/// Small labelled swatch used to caption a live example inside a row.
class DemoLabel extends StatelessWidget {
  const DemoLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => UTextLabelSmall(
    text,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );
}
