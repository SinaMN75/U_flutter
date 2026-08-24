import "package:u/utilities.dart";

class UAdminSettingsPage extends StatefulWidget {
  const UAdminSettingsPage({super.key});

  @override
  State<UAdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<UAdminSettingsPage> {
  late String _themeMode = ULocalStorage.getString("themeMode") ?? (ULocalStorage.isDarkMode() ? "dark" : "light");
  late String _locale = ULocalStorage.getLocale() ?? "fa";

  void _applyTheme(String mode) {
    setState(() => _themeMode = mode);
    ULocalStorage.set("themeMode", mode);
    switch (mode) {
      case "light":
        ULocalStorage.setDarkMode(false);
        UAppState.changeThemeMode(ThemeMode.light);
      case "dark":
        ULocalStorage.setDarkMode(true);
        UAppState.changeThemeMode(ThemeMode.dark);
      default:
        UAppState.changeThemeMode(ThemeMode.system);
    }
  }

  void _applyLocale(String code) {
    setState(() => _locale = code);
    ULocalStorage.setLocale(code);
    UApp.updateLocale(Locale(code));
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.settings)),
    body: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: UColumn(
            spacing: 0,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _accountCard(),
              const SizedBox(height: 16),
              _section(U.s.appearance, Icons.palette_outlined, <Widget>[
                _rowLabel(U.s.theme, Icons.dark_mode_outlined),
                const SizedBox(height: 8),
                USegmentedControl<String>(
                  selectedValue: _themeMode,
                  items: <String, String>{"light": U.s.light, "dark": U.s.dark, "system": U.s.system},
                  onValueChanged: (String? v) => _applyTheme(v ?? _themeMode),
                ),
              ]),
              const SizedBox(height: 16),
              _section(U.s.language, Icons.language_outlined, <Widget>[
                USegmentedControl<String>(selectedValue: _locale, items: <String, String>{"fa": U.s.persian, "en": U.s.english}, onValueChanged: (String? v) => _applyLocale(v ?? _locale)),
              ]),
              const SizedBox(height: 16),
              _section(U.s.general, Icons.tune_rounded, <Widget>[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cleaning_services_outlined),
                  title: Text(U.s.clearCache),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await UFileStorage.clear();
                    UToast.snackBar(message: U.s.cacheCleared);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline),
                  title: Text(U.s.appVersion),
                  trailing: Text("v${UApp.version}", style: Theme.of(context).textTheme.bodyMedium),
                ),
              ]),
              const SizedBox(height: 24),
              UButton(
                title: U.s.logout,
                icon: const Icon(Icons.logout_rounded),
                backgroundColor: Theme.of(context).colorScheme.error,
                onTap: () => UNavigator.confirm(
                  title: U.s.logout,
                  message: U.s.areYouSureYouWantToLogOut,
                  destructive: true,
                  onConfirm: () {
                    ULocalStorage.remove(UConstants.token);
                    UNavigator.offAll(const UAdminLoginPage());
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _accountCard() => UContainer(
    padding: const EdgeInsets.all(16),
    gradient: LinearGradient(
      colors: <Color>[Theme.of(context).colorScheme.primary.withValues(alpha: 0.15), Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    ),
    radius: 16,
    child: URow(
      spacing: 0,
      children: <Widget>[
        CircleAvatar(radius: 28, backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2), child: UImage(UAdmin.logo)),
        const SizedBox(width: 16),
        Expanded(
          child: UColumn(
            spacing: 0,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              UTextBodyLarge("${U.user.firstName ?? ""} ${U.user.lastName ?? ""}".trim(), fontWeight: FontWeight.bold),
              const SizedBox(height: 4),
              UTextBodySmall(U.user.email ?? U.user.phoneNumber ?? U.user.userName, color: UAdminTheme.grey),
            ],
          ),
        ),
        UContainer(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
          radius: 20,
          child: UTextBodySmall(U.s.account, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  Widget _section(String title, IconData icon, List<Widget> children) => UContainer(
    padding: const EdgeInsets.all(16),
    color: Theme.of(context).colorScheme.surface,
    radius: 16,
    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
    child: UColumn(
      spacing: 0,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        URow(
          spacing: 0,
          children: <Widget>[
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            UTextBodyLarge(title, fontWeight: FontWeight.bold),
          ],
        ),
        const SizedBox(height: 14),
        ...children,
      ],
    ),
  );

  Widget _rowLabel(String text, IconData icon) => URow(
    spacing: 0,
    children: <Widget>[
      Icon(icon, size: 18, color: UAdminTheme.grey),
      const SizedBox(width: 8),
      UTextBodyMedium(text),
    ],
  );
}
