part of "../../u_admin.dart";

class UAdminSplashPage extends StatefulWidget {
  const UAdminSplashPage({
    required this.logo,
    required this.onError,
    required this.onFinish,
    super.key,
  });

  final VoidCallback onFinish;
  final VoidCallback onError;
  final String logo;

  @override
  State<UAdminSplashPage> createState() => _UAdminSplashPageState();
}

class _UAdminSplashPageState extends State<UAdminSplashPage> {
  final UAdminSplashController c = UAdminSplashController();

  @override
  void initState() {
    c.init(
      onFinish: widget.onFinish,
      onError: () async {
        await ULocalStorage.clear();
        widget.onError();
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    body: UColumn(
      spacing: 0,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        UImage(widget.logo, width: 200, height: 200),
        const CircularProgressIndicator(),
      ],
    ).alignAtCenter(),
  );
}
