part of "../data.dart";

class UIpgWebViewPage extends StatefulWidget {
  const UIpgWebViewPage({required this.url, required this.trackingNumber, super.key});

  final String url;
  final String trackingNumber;

  @override
  State<UIpgWebViewPage> createState() => _UIpgWebViewPageState();
}

class _UIpgWebViewPageState extends State<UIpgWebViewPage> {
  late final UIpgWebViewController c;

  @override
  void initState() {
    c = UIpgWebViewController(trackingNumber: widget.trackingNumber);
    super.initState();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (bool didPop, Object? _) {
      if (!didPop && !c.finished) c.cancel();
    },
    child: UScaffold(
      appBar: AppBar(title: Text(U.s.payment)),
      body: UWebView(initialUrl: widget.url, showUrlBar: true, onUrlChanged: (String url, Map<String, String> queryParameters) => c.onPageFinished(url)),
    ),
  );
}
