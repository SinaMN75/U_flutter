import "package:u/utilities.dart";

class UAdminPnTesterPage extends StatefulWidget {
  const UAdminPnTesterPage({super.key});

  @override
  State<UAdminPnTesterPage> createState() => _UAdminPnTesterPageState();
}

class _UAdminPnTesterPageState extends State<UAdminPnTesterPage> {
  final TextEditingController _apiKeyController = TextEditingController(text: U.apiKey);
  final Map<String, TextEditingController> _controllers = <String, TextEditingController>{};

  late List<_PnEndpoint> _endpoints;
  int _selected = 0;

  bool _loading = false;
  int? _statusCode;
  String? _responseBody;
  String? _exception;
  int _latencyMs = 0;

  @override
  void initState() {
    super.initState();
    _endpoints = _buildEndpoints();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    for (final TextEditingController c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // A controller is created lazily per field key and reused across rebuilds.
  TextEditingController _controllerFor(String key) => _controllers.putIfAbsent(key, TextEditingController.new);

  List<_PnEndpoint> _buildEndpoints() => <_PnEndpoint>[
    _PnEndpoint(
      name: "Auth",
      description: "Create or update an end user by phone number.",
      icon: Icons.person_add_alt_1_rounded,
      call: UServices.pn.auth,
      fields: <_PnField>[
        _PnField(key: "phoneNumber", label: U.s.phoneNumber, required: true, keyboardType: TextInputType.phone),
        _PnField(key: "firstName", label: U.s.firstName),
        _PnField(key: "lastName", label: U.s.lastName),
        _PnField(key: "fatherName", label: U.s.fatherName),
        _PnField(key: "nationalCode", label: U.s.nationalCode, keyboardType: TextInputType.number),
        _PnField(key: "email", label: U.s.email, keyboardType: TextInputType.emailAddress),
      ],
    ),
    _PnEndpoint(
      name: "CreateMerchant",
      description: "Register a merchant for a fully verified user.",
      icon: Icons.storefront_rounded,
      call: UServices.pn.createMerchant,
      fields: <_PnField>[
        _PnField(key: "userPhoneNumber", label: U.s.phoneNumber, required: true, keyboardType: TextInputType.phone),
        _PnField(key: "zipCode", label: U.s.zipCode, required: true, keyboardType: TextInputType.number),
        _PnField(key: "cityCode", label: U.s.cityCode, required: true),
        _PnField(key: "phoneNumber", label: U.s.phoneNumber, required: true, keyboardType: TextInputType.phone),
        _PnField(key: "title", label: U.s.title, required: true),
        _PnField(key: "landline", label: U.s.landline, required: true),
        _PnField(key: "nationalCode", label: U.s.nationalCode, required: true, keyboardType: TextInputType.number),
        _PnField(key: "ownerPhoneNumber", label: U.s.ownerPhoneNumber, required: true, keyboardType: TextInputType.phone),
        _PnField(key: "ownerName", label: U.s.ownerName, required: true),
        _PnField(key: "mcc", label: U.s.mcc, required: true),
        _PnField(key: "address", label: U.s.address, required: true, lines: 2),
        _PnField(key: "businessTitle", label: U.s.businessTitle),
        _PnField(key: "bankAccountId", label: U.s.bankAccountid),
      ],
    ),
    _PnEndpoint(
      name: "CreateTerminal",
      description: "Bind an existing terminal to a merchant.",
      icon: Icons.point_of_sale_rounded,
      call: UServices.pn.createTerminal,
      fields: <_PnField>[
        _PnField(key: "serial", label: U.s.serial, required: true),
        _PnField(key: "simCardSerial", label: U.s.simCardSerial, required: true),
        _PnField(key: "imei", label: U.s.imei, required: true, keyboardType: TextInputType.number),
        _PnField(key: "merchantId", label: U.s.merchantId, required: true),
      ],
    ),
    _PnEndpoint(
      name: "UserStatus",
      description: "Read a user's verification status and merchants.",
      icon: Icons.verified_user_rounded,
      call: UServices.pn.userStatus,
      fields: <_PnField>[
        _PnField(key: "phoneNumber", label: U.s.phoneNumber, required: true, keyboardType: TextInputType.phone),
      ],
    ),
    _PnEndpoint(
      name: "ReadTerminalSupportPassword",
      description: "Generate the support password for a bound terminal.",
      icon: Icons.password_rounded,
      call: UServices.pn.readTerminalSupportPassword,
      fields: <_PnField>[
        _PnField(key: "terminalId", label: U.s.terminalId, required: true),
      ],
    ),
    _PnEndpoint(
      name: "ZipCodeToAddress",
      description: "Resolve a full address from a 10-digit postal code.",
      icon: Icons.location_on_rounded,
      call: UServices.pn.zipCodeToAddress,
      fields: <_PnField>[
        _PnField(key: "zipCode", label: U.s.zipCode, required: true, keyboardType: TextInputType.number),
      ],
    ),
  ];

  Future<void> _send() async {
    final _PnEndpoint endpoint = _endpoints[_selected];

    if (_apiKeyController.text.trim().isEmpty) {
      UToast.error(message: U.s.apiKey);
      return;
    }

    final Map<String, dynamic> body = <String, dynamic>{"apiKey": _apiKeyController.text.trim()};
    for (final _PnField f in endpoint.fields) {
      final String value = _controllerFor(f.key).text.trim();
      if (f.required && value.isEmpty) {
        UToast.error(message: f.label);
        return;
      }
      if (value.isNotEmpty) body[f.key] = value;
    }

    setState(() {
      _loading = true;
      _statusCode = null;
      _responseBody = null;
      _exception = null;
    });

    final Stopwatch watch = Stopwatch()..start();
    await endpoint.call(
      body: body,
      onResponse: (int status, String responseBody) {
        watch.stop();
        setState(() {
          _statusCode = status;
          _responseBody = responseBody;
          _latencyMs = watch.elapsedMilliseconds;
          _loading = false;
        });
      },
      onException: (String e) {
        watch.stop();
        setState(() {
          _exception = e;
          _latencyMs = watch.elapsedMilliseconds;
          _loading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return UScaffold(
      padding: const EdgeInsets.all(20),
      body: SingleChildScrollView(
        child: UColumn(
          spacing: 20,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _header(cs),
            _apiKeyCard(cs),
            _endpointSelector(cs),
            _requestCard(cs),
            if (_statusCode != null || _exception != null) _responseCard(cs),
          ],
        ),
      ),
    );
  }

  Widget _header(ColorScheme cs) => URow(
    spacing: 14,
    children: <Widget>[
      Icon(Icons.api_rounded, size: 34, color: cs.primary).container(
        padding: const EdgeInsets.all(12),
        backgroundColor: cs.primary.withValues(alpha: 0.12),
        radius: 16,
      ),
      UColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          UTextHeadlineSmall(U.s.pnapiTester, fontWeight: FontWeight.bold),
          UTextBodySmall("${U.baseUrl}/Pn", color: cs.onSurface.withValues(alpha: 0.6)),
        ],
      ).expanded(),
    ],
  );

  Widget _apiKeyCard(ColorScheme cs) => UCard(
    child: URow(
      spacing: 12,
      children: <Widget>[
        Icon(Icons.key_rounded, color: cs.primary),
        UTextField(controller: _apiKeyController, labelText: U.s.apiKey, hintText: U.s.apiKey).expanded(),
      ],
    ).pAll(16),
  );

  Widget _endpointSelector(ColorScheme cs) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: List<Widget>.generate(_endpoints.length, (int i) {
      final bool active = i == _selected;
      final _PnEndpoint e = _endpoints[i];
      return URow(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UContainer(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: (active ? cs.onPrimary : cs.primary).withValues(alpha: active ? 0.22 : 0.12),
                radius: 4,
                child: UTextLabelSmall("POST", color: active ? cs.onPrimary : cs.primary, fontWeight: FontWeight.bold),
              ),
              UTextLabelLarge(e.name, color: active ? cs.onPrimary : cs.onSurface, fontWeight: FontWeight.w600),
            ],
          )
          .pSymmetric(horizontal: 14, vertical: 10)
          .container(
            backgroundColor: active ? cs.primary : cs.surfaceContainerHighest.withValues(alpha: 0.5),
            radius: 12,
            borderColor: active ? cs.primary : cs.outlineVariant,
          )
          .onTap(() => setState(() => _selected = i));
    }),
  );

  Widget _requestCard(ColorScheme cs) {
    final _PnEndpoint endpoint = _endpoints[_selected];
    return UCard(
      child: UColumn(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          URow(
            spacing: 10,
            children: <Widget>[
              Icon(endpoint.icon, color: cs.primary),
              UColumn(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  UTextTitleMedium(endpoint.name, fontWeight: FontWeight.bold),
                  UTextBodySmall(endpoint.description, color: cs.onSurface.withValues(alpha: 0.6)),
                ],
              ).expanded(),
            ],
          ),
          const Divider(height: 1),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              // Two fields per row on wide viewports, one on narrow.
              final bool twoColumns = constraints.maxWidth > 640;
              final double fieldWidth = twoColumns ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;
              return Wrap(
                spacing: 16,
                runSpacing: 14,
                children: endpoint.fields
                    .map(
                      (_PnField f) => SizedBox(
                        width: f.lines > 1 ? constraints.maxWidth : fieldWidth,
                        child: UTextField(
                          controller: _controllerFor(f.key),
                          labelText: f.label,
                          hintText: f.key,
                          required: f.required,
                          lines: f.lines,
                          keyboardType: f.keyboardType,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          UButton(
            title: U.s.sendRequest,
            icon: const Icon(Icons.send_rounded),
            isLoading: _loading,
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            onTap: _send,
          ).alignAtCenterRight(),
        ],
      ).pAll(20),
    );
  }

  Widget _responseCard(ColorScheme cs) {
    final bool isException = _exception != null;
    final bool ok = !isException && (_statusCode ?? 0) >= 200 && (_statusCode ?? 0) < 300;
    final Color accent = isException || !ok ? cs.error : UAdminTheme.green;
    return UCard(
      child: UColumn(
        margin: const EdgeInsets.all(20),
        spacing: 14,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          URow(
            spacing: 10,
            children: <Widget>[
              UTextTitleMedium(U.s.response, fontWeight: FontWeight.bold),
              UContainer(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                color: accent.withValues(alpha: 0.14),
                radius: 20,
                child: UTextLabelMedium(
                  isException ? "EXCEPTION" : "HTTP ${_statusCode ?? "-"}",
                  color: accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              URow(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: <Widget>[
                  Icon(Icons.timer_outlined, size: 16, color: cs.onSurface.withValues(alpha: 0.6)),
                  UTextLabelMedium("$_latencyMs ms", color: cs.onSurface.withValues(alpha: 0.6)),
                ],
              ),
            ],
          ),
          if (isException)
            UContainer(
              padding: const EdgeInsets.all(14),
              color: cs.error.withValues(alpha: 0.08),
              radius: 8,
              child: UTextBodyMedium(_exception!, color: cs.error),
            )
          else
            UJsonViewer(jsonString: _responseBody ?? ""),
        ],
      ),
    );
  }
}

// Metadata describing one Pn endpoint the tester can call.
class _PnEndpoint {
  _PnEndpoint({required this.name, required this.description, required this.icon, required this.fields, required this.call});

  final String name;
  final String description;
  final IconData icon;
  final List<_PnField> fields;
  final Future<UHttpClientResponse> Function({
    required Map<String, dynamic> body,
    void Function(int status, String body)? onResponse,
    void Function(String e)? onException,
  })
  call;
}

// A single editable body field for an endpoint.
class _PnField {
  _PnField({required this.key, required this.label, this.required = false, this.lines = 1, this.keyboardType = TextInputType.text});

  final String key;
  final String label;
  final bool required;
  final int lines;
  final TextInputType keyboardType;
}
