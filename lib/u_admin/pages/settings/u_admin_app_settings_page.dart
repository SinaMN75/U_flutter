import "package:u/utilities.dart";

class UAdminAppSettingsPage extends StatefulWidget {
  const UAdminAppSettingsPage({super.key});

  @override
  State<UAdminAppSettingsPage> createState() => _UAdminAppSettingsPageState();
}

class _UAdminAppSettingsPageState extends State<UAdminAppSettingsPage> {
  UAppSettings? _m;
  bool _loading = true;
  bool _saving = false;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await UServices.appSettings.readAll(
      onOk: (UResponse<UAppSettings> r) => setState(() {
        _m = r.result;
        _loading = false;
        _tick++;
      }),
      onError: (UEmptyResponse e) => setState(() {
        _loading = false;
        UToast.error(message: e.message);
      }),
      onException: (String e) => setState(() {
        _loading = false;
        UToast.error(message: e);
      }),
    );
  }

  Future<void> _save() async {
    if (_m == null) return;
    setState(() => _saving = true);
    await UServices.appSettings.update(
      p: UAppSettingsUpdateParams(settings: _m!),
      onOk: (UEmptyResponse r) {
        setState(() => _saving = false);
        UToast.snackBar(message: r.message);
        _load();
      },
      onError: (UEmptyResponse e) {
        setState(() => _saving = false);
        UToast.error(message: e.message);
      },
      onException: (String e) {
        setState(() => _saving = false);
        UToast.error(message: e);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return UScaffold(
      appBar: AppBar(
        title: Text(U.s.appSettings),
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.refresh_rounded), tooltip: U.s.refresh, onPressed: _loading ? null : _load),
        ],
      ),
      body: _loading || _m == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    key: ValueKey<int>(_tick),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Center(
                      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 880), child: _form(cs)),
                    ),
                  ),
                ),
                _saveBar(cs),
              ],
            ),
    );
  }

  Widget _form(ColorScheme cs) {
    final UAppSettings m = _m!;
    return UColumn(
      spacing: 14,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _note(cs),
        _section(U.s.general, Icons.tune_rounded, cs, <Widget>[
          _text("BaseUrl", m.baseUrl, (String v) => m.baseUrl = v),
          _text("ApiKey", m.apiKey, (String v) => m.apiKey = v, secret: true),
          _switch("Test", m.test, (bool v) => m.test = v, cs),
        ]),
        _section("Database", Icons.storage_rounded, cs, <Widget>[
          _text("ConnectionStrings.Server", m.connectionServer, (String v) => m.connectionServer = v, secret: true, lines: 2),
        ]),
        _section("JWT", Icons.vpn_key_rounded, cs, <Widget>[
          _text("Key", m.jwt.key, (String v) => m.jwt.key = v, secret: true),
          _text("Issuer", m.jwt.issuer, (String v) => m.jwt.issuer = v),
          _text("Audience", m.jwt.audience, (String v) => m.jwt.audience = v),
          _text("Expires (minutes)", m.jwt.expires, (String v) => m.jwt.expires = v, kt: TextInputType.number),
        ]),
        _section("Middleware", Icons.filter_alt_rounded, cs, <Widget>[
          _switch("RequireApiKey", m.middleware.requireApiKey, (bool v) => m.middleware.requireApiKey = v, cs),
          _switch("RequireRefreshToken", m.middleware.requireRefreshToken, (bool v) => m.middleware.requireRefreshToken = v, cs),
          _switch("Log", m.middleware.log, (bool v) => m.middleware.log = v, cs),
          _switch("LogSuccess", m.middleware.logSuccess, (bool v) => m.middleware.logSuccess = v, cs),
          _switch("LogHeaders", m.middleware.logHeaders, (bool v) => m.middleware.logHeaders = v, cs),
        ]),
        _section("SMS Panel", Icons.sms_rounded, cs, <Widget>[
          _enum<TagSmsPanel>("Provider", m.smsPanel.tag, TagSmsPanel.values, (TagSmsPanel v) => m.smsPanel.tag = v),
          _text("LoginOtpPattern", m.smsPanel.loginOtpPattern, (String v) => m.smsPanel.loginOtpPattern = v),
          _text("SupportPasswordOtp", m.smsPanel.supportPasswordOtp, (String v) => m.smsPanel.supportPasswordOtp = v),
          _text("ApiKey", m.smsPanel.apiKey, (String v) => m.smsPanel.apiKey = v, secret: true),
        ]),
        _section("ITHub", Icons.hub_rounded, cs, <Widget>[
          _text("ClientId", m.itHub.clientId, (String v) => m.itHub.clientId = v),
          _text("ClientSecret", m.itHub.clientSecret, (String v) => m.itHub.clientSecret = v, secret: true),
          _text("UserName", m.itHub.userName, (String v) => m.itHub.userName = v),
          _text("Password", m.itHub.password, (String v) => m.itHub.password = v, secret: true),
        ]),
        _section("Mobtakeran", Icons.cell_tower_rounded, cs, <Widget>[
          _text("UserName", m.mobtakeran.userName, (String v) => m.mobtakeran.userName = v),
          _text("Password", m.mobtakeran.password, (String v) => m.mobtakeran.password = v, secret: true),
          _text("ApiKey", m.mobtakeran.apiKey, (String v) => m.mobtakeran.apiKey = v, secret: true),
          _text("BaseUrl", m.mobtakeran.baseUrl, (String v) => m.mobtakeran.baseUrl = v),
        ]),
        _section("Basic Settings", Icons.settings_suggest_rounded, cs, <Widget>[
          _text("DefaultVerificationKey", m.basicSettings.defaultVerificationKey, (String v) => m.basicSettings.defaultVerificationKey = v, secret: true),
          _text(
            "VerificationCodeLength",
            "${m.basicSettings.verificationCodeLenght}",
            (String v) => m.basicSettings.verificationCodeLenght = int.tryParse(v) ?? m.basicSettings.verificationCodeLenght,
            kt: TextInputType.number,
          ),
        ]),
        _section("IPG", Icons.payment_rounded, cs, <Widget>[
          _text("IpgUserId", m.ipg.ipgUserId, (String v) => m.ipg.ipgUserId = v),
          _enum<TagIpg>("Provider", m.ipg.tag, TagIpg.values, (TagIpg v) => m.ipg.tag = v),
          _text("Title", m.ipg.title, (String v) => m.ipg.title = v),
          _text("Token", m.ipg.token, (String v) => m.ipg.token = v, secret: true),
          _text("CallBackUrl", m.ipg.callBackUrl, (String v) => m.ipg.callBackUrl = v),
        ]),
        _section("Avreen", Icons.cloud_rounded, cs, <Widget>[
          _text("AuthHeader", m.avreen.authHeader, (String v) => m.avreen.authHeader = v, secret: true),
          _text("BaseUrl", m.avreen.baseUrl, (String v) => m.avreen.baseUrl = v),
        ]),
        _section("PN", Icons.api_rounded, cs, <Widget>[
          _text("ApiKey", m.pnApiKey, (String v) => m.pnApiKey = v, secret: true),
        ]),
        _section("API Call Costs", Icons.request_quote_rounded, cs, <Widget>[
          _num("MobileAndNationalCodeVerification", m.apiCallCosts.mobileAndNationalCodeVerification, (double v) => m.apiCallCosts.mobileAndNationalCodeVerification = v),
          _num("ZipCodeToAddressDetail", m.apiCallCosts.zipCodeToAddressDetail, (double v) => m.apiCallCosts.zipCodeToAddressDetail = v),
          _num("VehicleViolationsDetail", m.apiCallCosts.vehicleViolationsDetail, (double v) => m.apiCallCosts.vehicleViolationsDetail = v),
          _num("DrivingLicenceStatus", m.apiCallCosts.drivingLicenceStatus, (double v) => m.apiCallCosts.drivingLicenceStatus = v),
          _num("FreewayToll", m.apiCallCosts.freewayToll, (double v) => m.apiCallCosts.freewayToll = v),
          _num("LicencePlateDetail", m.apiCallCosts.licencePlateDetail, (double v) => m.apiCallCosts.licencePlateDetail = v),
          _num("DrivingLicenceNegativePoint", m.apiCallCosts.drivingLicenceNegativePoint, (double v) => m.apiCallCosts.drivingLicenceNegativePoint = v),
          _num("IBanToBankAccountDetail", m.apiCallCosts.iBanToBankAccountDetail, (double v) => m.apiCallCosts.iBanToBankAccountDetail = v),
        ]),
        _chargeInternetSection(m, cs),
      ],
    );
  }

  Widget _note(ColorScheme cs) => URow(
    spacing: 10,
    children: <Widget>[
      Icon(Icons.info_outline_rounded, size: 18, color: cs.primary),
      UTextBodySmall(U.s.changesApplyLiveAndResetToDefaultsOnServerRestart, color: cs.onSurface.withValues(alpha: 0.75)).expanded(),
    ],
  ).pAll(14).container(backgroundColor: cs.primary.withValues(alpha: 0.08), radius: 12);

  Widget _section(String title, IconData icon, ColorScheme cs, List<Widget> children) => UCard(
    child: UColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: <Widget>[
        URow(
          spacing: 10,
          children: <Widget>[
            Icon(icon, size: 20, color: cs.primary),
            UTextTitleMedium(title, fontWeight: FontWeight.bold),
          ],
        ),
        const Divider(height: 18),
        ...children,
      ],
    ).pAll(16),
  );

  Widget _text(String label, String initial, ValueChanged<String> onChanged, {bool secret = false, TextInputType? kt, int lines = 1}) => UTextField(
    labelText: label,
    initialValue: initial,
    hintText: secret ? U.s.leaveMaskedToKeepTheCurrentValue : null,
    keyboardType: kt ?? TextInputType.text,
    lines: lines,
    onChanged: onChanged,
  ).pSymmetric(vertical: 6);

  Widget _num(String label, double initial, ValueChanged<double> onChanged) => _text(
    label,
    initial == initial.roundToDouble() ? initial.toStringAsFixed(0) : initial.toString(),
    (String v) => onChanged(double.tryParse(v) ?? 0),
    kt: const TextInputType.numberWithOptions(decimal: true),
  );

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged, ColorScheme cs) => URow(
    children: <Widget>[
      UTextBodyMedium(label).expanded(),
      Switch(value: value, onChanged: (bool v) => setState(() => onChanged(v))),
    ],
  ).pSymmetric(vertical: 2);

  Widget _enum<T extends Enum>(String label, T value, List<T> values, ValueChanged<T> onChanged) => UDropDownField<T>(
    labelText: label,
    initialValue: value,
    items: values.map((T e) => DropdownMenuItem<T>(value: e, child: Text((e as dynamic).localizedTitle as String))).toList(),
    onChanged: (T? v) {
      if (v != null) setState(() => onChanged(v));
    },
  ).pSymmetric(vertical: 6);

  // ---- Charge Internet (nested list) ----

  Widget _chargeInternetSection(UAppSettings m, ColorScheme cs) => UCard(
    child: UColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: <Widget>[
        URow(
          spacing: 10,
          children: <Widget>[
            Icon(Icons.sim_card_rounded, size: 20, color: cs.primary),
            const UTextTitleMedium("Charge Internet", fontWeight: FontWeight.bold).expanded(),
            UButton(
              title: U.s.addItem(""),
              icon: const Icon(Icons.add_rounded, size: 18),
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              onTap: () => setState(() => m.chargeInternet.add(USettingsChargeInternet(operator: TagSimOperator.values.first, title: "", logo: "", preDefinedAmountsList: <USettingsChargeAmount>[]))),
            ),
          ],
        ),
        const Divider(height: 4),
        ...m.chargeInternet.asMap().entries.map((MapEntry<int, USettingsChargeInternet> e) => _operatorCard(m, e.key, e.value, cs)),
      ],
    ).pAll(16),
  );

  Widget _operatorCard(UAppSettings m, int index, USettingsChargeInternet c, ColorScheme cs) => UContainer(
    margin: const EdgeInsets.symmetric(vertical: 6),
    padding: const EdgeInsets.all(12),
    color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
    radius: 12,
    child: UColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: <Widget>[
        URow(
          children: <Widget>[
            _enum<TagSimOperator>("Operator", c.operator, TagSimOperator.values, (TagSimOperator v) => c.operator = v).expanded(),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: cs.error),
              tooltip: U.s.delete,
              onPressed: () => setState(() => m.chargeInternet.removeAt(index)),
            ),
          ],
        ),
        _text("Title", c.title, (String v) => c.title = v),
        _text("Logo", c.logo, (String v) => c.logo = v),
        const SizedBox(height: 4),
        URow(
          children: <Widget>[
            UTextLabelLarge("Amounts", color: cs.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.bold).expanded(),
            TextButton.icon(
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(U.s.addItem("")),
              onPressed: () => setState(() => c.preDefinedAmountsList.add(USettingsChargeAmount(title: "", amount: 0))),
            ),
          ],
        ),
        ...c.preDefinedAmountsList.asMap().entries.map(
          (MapEntry<int, USettingsChargeAmount> a) => URow(
            children: <Widget>[
              _text("Title", a.value.title, (String v) => a.value.title = v).expanded(),
              _text(
                "Amount",
                a.value.amount == a.value.amount.roundToDouble() ? a.value.amount.toStringAsFixed(0) : a.value.amount.toString(),
                (String v) => a.value.amount = double.tryParse(v) ?? 0,
                kt: const TextInputType.numberWithOptions(decimal: true),
              ).expanded(),
              IconButton(
                icon: Icon(Icons.remove_circle_outline_rounded, color: cs.error, size: 20),
                onPressed: () => setState(() => c.preDefinedAmountsList.removeAt(a.key)),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _saveBar(ColorScheme cs) => UContainer(
    padding: const EdgeInsets.all(14),
    color: cs.surface,
    child: URow(
      children: <Widget>[
        UTextBodySmall(U.baseUrl, color: cs.onSurface.withValues(alpha: 0.5)).expanded(),
        UButton(
          title: U.s.save,
          icon: const Icon(Icons.save_rounded, size: 18),
          isLoading: _saving,
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          onTap: _save,
        ),
      ],
    ),
  );
}
