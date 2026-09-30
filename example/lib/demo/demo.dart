import "package:u/utilities.dart";

/// A page of demos: an app bar, an optional intro line and a scrolling list of [DemoGroup]s.
class DemoPage extends StatelessWidget {
  const DemoPage({required this.title, required this.children, this.intro, super.key});

  final String title;
  final String? intro;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
      children: <Widget>[
        if (intro != null) UTextBodySmall(intro!, maxLines: 6, color: Theme.of(context).colorScheme.onSurfaceVariant).pSymmetric(horizontal: 4, vertical: 8),
        ...children,
      ],
    ),
  );
}

/// A titled card that groups related demos.
class DemoGroup extends StatelessWidget {
  const DemoGroup(this.title, this.children, {this.note, super.key});

  final String title;
  final String? note;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(vertical: 6),
    child: UColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: <Widget>[
        UTextTitleMedium(title, fontWeight: FontWeight.w700).pSymmetric(horizontal: 14, vertical: 6),
        if (note != null) UTextBodySmall(note!, maxLines: 4, color: Theme.of(context).colorScheme.onSurfaceVariant).pOnly(left: 14, right: 14, bottom: 6),
        ...children,
      ],
    ),
  );
}

/// One function you can run: shows [code], runs [run] on tap and prints what it returned.
/// Futures are awaited, streams show their first 3 events, errors show in red. [auto] runs it on open.
class Fn extends StatefulWidget {
  const Fn(this.code, this.run, {this.auto = false, this.note, super.key});

  final String code;
  final FutureOr<Object?> Function() run;
  final bool auto;
  final String? note;

  @override
  State<Fn> createState() => _FnState();
}

class _FnState extends State<Fn> {
  String? _result;
  bool _error = false;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    if (widget.auto) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _run());
    }
  }

  Future<void> _run() async {
    if (_running) return;
    setState(() => _running = true);
    try {
      Object? value = widget.run();
      if (value is Future) value = await value;
      if (value is Stream) {
        value = await value.take(3).timeout(const Duration(seconds: 6), onTimeout: (EventSink<Object?> sink) => sink.close()).toList();
      }
      _result = describe(value);
      _error = false;
    } catch (e) {
      _result = "$e";
      _error = true;
    }
    if (mounted) setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: _run,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 3,
                children: <Widget>[
                  Text(
                    widget.code,
                    style: TextStyle(fontFamily: "monospace", fontSize: 12.5, color: scheme.primary),
                  ),
                  if (widget.note != null) Text(widget.note!, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                  if (_result != null) SelectableText(_result!, maxLines: 8, style: TextStyle(fontSize: 12, color: _error ? scheme.error : scheme.onSurface)),
                ],
              ),
            ),
            SizedBox(width: 20, height: 20, child: _running ? const CircularProgressIndicator(strokeWidth: 2) : Icon(Icons.play_arrow_rounded, size: 20, color: scheme.primary)),
          ],
        ),
      ),
    );
  }
}

/// Short printable form of any value (bytes, lists, maps, objects).
String describe(Object? value) {
  if (value == null) return "null";
  if (value is String) return value.isEmpty ? '""' : '"$value"';
  if (value is Uint8List) {
    return "Uint8List(${value.length}) ${value.take(12).toList()}${value.length > 12 ? "…" : ""}";
  }
  if (value is Iterable) {
    final List<Object?> list = value.toList();
    return "[${list.take(8).map(describe).join(", ")}${list.length > 8 ? ", … (${list.length})" : ""}]";
  }
  if (value is Map) {
    final List<String> entries = value.entries.take(8).map((MapEntry<Object?, Object?> e) => "${e.key}: ${describe(e.value)}").toList();
    return "{${entries.join(", ")}${value.length > 8 ? ", … (${value.length})" : ""}}";
  }
  final String text = value.toString();
  return text.length > 400 ? "${text.substring(0, 400)}…" : text;
}

/// A widget demo: the code on top and the live widget under it.
class Demo extends StatelessWidget {
  const Demo(this.code, {required this.child, this.note, super.key});

  final String code;
  final String? note;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: <Widget>[
          Text(
            code,
            style: TextStyle(fontFamily: "monospace", fontSize: 12.5, color: scheme.primary),
          ),
          if (note != null) Text(note!, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
          child,
        ],
      ),
    );
  }
}

/// A button row demo: tap [label] to run [onTap] (for actions that show UI, like dialogs and toasts).
class Act extends StatelessWidget {
  const Act(this.code, this.onTap, {this.note, super.key});

  final String code;
  final String? note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Fn(code, () {
    onTap();
    return "done";
  }, note: note);
}
