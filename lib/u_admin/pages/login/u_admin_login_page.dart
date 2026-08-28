import "package:u/utilities.dart";

class UAdminLoginPage extends StatefulWidget {
  const UAdminLoginPage({super.key});

  @override
  State<UAdminLoginPage> createState() => _UAdminLoginPageState();
}

class _UAdminLoginPageState extends State<UAdminLoginPage> {
  final UAdminLoginController c = UAdminLoginController();

  @override
  Widget build(BuildContext context) => UScaffold(
    decoration: UAdmin.loginBackground == null
        ? null
        : BoxDecoration(
            image: DecorationImage(image: AssetImage(UAdmin.loginBackground!), fit: BoxFit.cover),
          ),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Form(
            key: c.formKey,
            child: UColumn(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                UImage(UAdmin.logo, width: 100, height: 100, margin: const EdgeInsets.symmetric(vertical: 8)),
                UTextField(
                  hintText: U.s.username,
                  controller: c.controllerUserName,
                  validator: UValidators.required(message: ""),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                ),
                UTextField(
                  hintText: U.s.password,
                  controller: c.controllerPassword,
                  validator: UValidators.required(message: ""),
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: true,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                ),
                UButton(
                  width: 1000,
                  onTap: () => c.login(
                    onFinish: (UUserResponse i) {
                      U.user = i;
                      UNavigator.offAll(const UAdminShell());
                    },
                  ),
                  title: U.s.enter,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                ),
              ],
            ),
          ).pAll(40),
        ).container(width: context.dialogWidth()),
      ),
    ),
  );
}
