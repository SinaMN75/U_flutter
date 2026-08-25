import "package:u/utilities.dart";

class UAdminCryptoTesterPage extends StatefulWidget {
  const UAdminCryptoTesterPage({super.key});

  @override
  State<UAdminCryptoTesterPage> createState() => _UAdminCryptoTesterPageState();
}

class _UAdminCryptoTesterPageState extends State<UAdminCryptoTesterPage> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _ivController = TextEditingController();

  late List<_CryptoAlgo> _algos;
  int _selected = 0;

  UAesMode _aesMode = UAesMode.cbc;
  bool _padding = true;
  UByteEncoding _keyEncoding = UByteEncoding.utf8;
  UByteEncoding _ivEncoding = UByteEncoding.utf8;
  int _aesKeyBytes = 32;

  String? _output;
  String? _error;

  @override
  void initState() {
    super.initState();
    _algos = _buildAlgos();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _keyController.dispose();
    _ivController.dispose();
    super.dispose();
  }

  _CryptoAlgo get _algo => _algos[_selected];

  List<_CryptoAlgo> _buildAlgos() => <_CryptoAlgo>[
    _CryptoAlgo(id: "aes", label: "AES", category: _Category.symmetric, icon: Icons.lock_rounded, needsKey: true, needsIv: true, isAes: true),
    _CryptoAlgo(id: "salsa20", label: "Salsa20", category: _Category.symmetric, icon: Icons.lock_outline_rounded, needsKey: true, needsIv: true),
    _CryptoAlgo(id: "fernet", label: "Fernet", category: _Category.symmetric, icon: Icons.enhanced_encryption_rounded, needsKey: true),
    _CryptoAlgo(id: "xor", label: "XOR", category: _Category.symmetric, icon: Icons.bolt_rounded, needsKey: true),
    _CryptoAlgo(id: "base64", label: "Base64", category: _Category.encoding, icon: Icons.data_object_rounded),
    _CryptoAlgo(id: "base64url", label: "Base64 URL", category: _Category.encoding, icon: Icons.link_rounded),
    _CryptoAlgo(id: "hex", label: "Hex", category: _Category.encoding, icon: Icons.tag_rounded),
    _CryptoAlgo(id: "base32", label: "Base32", category: _Category.encoding, icon: Icons.grid_4x4_rounded),
    _CryptoAlgo(id: "rot13", label: "ROT13", category: _Category.encoding, icon: Icons.rotate_right_rounded),
    _CryptoAlgo(id: "caesar", label: "Caesar", category: _Category.encoding, icon: Icons.text_rotation_none_rounded, needsKey: true),
    _CryptoAlgo(id: "md5", label: "MD5", category: _Category.hash, icon: Icons.fingerprint_rounded),
    _CryptoAlgo(id: "sha1", label: "SHA-1", category: _Category.hash, icon: Icons.fingerprint_rounded),
    _CryptoAlgo(id: "sha224", label: "SHA-224", category: _Category.hash, icon: Icons.fingerprint_rounded),
    _CryptoAlgo(id: "sha256", label: "SHA-256", category: _Category.hash, icon: Icons.fingerprint_rounded),
    _CryptoAlgo(id: "sha384", label: "SHA-384", category: _Category.hash, icon: Icons.fingerprint_rounded),
    _CryptoAlgo(id: "sha512", label: "SHA-512", category: _Category.hash, icon: Icons.fingerprint_rounded),
    _CryptoAlgo(id: "hmac", label: "HMAC-SHA256", category: _Category.hash, icon: Icons.vpn_key_rounded, needsKey: true),
  ];

  // Maps the current UI selection to the matching reusable UEncryption call.
  String _process(bool forward) {
    final String text = _inputController.text;
    final String key = _keyController.text;
    final String iv = _ivController.text;
    switch (_algo.id) {
      case "aes":
        return forward
            ? UEncryption.aesEncrypt(plainText: text, key: key, iv: iv, mode: _aesMode, padding: _padding, keyEncoding: _keyEncoding, ivEncoding: _ivEncoding)
            : UEncryption.aesDecrypt(base64Encrypted: text, key: key, iv: iv, mode: _aesMode, padding: _padding, keyEncoding: _keyEncoding, ivEncoding: _ivEncoding);
      case "salsa20":
        return forward
            ? UEncryption.salsa20Encrypt(plainText: text, key: key, iv: iv, keyEncoding: _keyEncoding, ivEncoding: _ivEncoding)
            : UEncryption.salsa20Decrypt(base64Encrypted: text, key: key, iv: iv, keyEncoding: _keyEncoding, ivEncoding: _ivEncoding);
      case "fernet":
        return forward ? UEncryption.fernetEncrypt(plainText: text, key: key, keyEncoding: _keyEncoding) : UEncryption.fernetDecrypt(base64Encrypted: text, key: key, keyEncoding: _keyEncoding);
      case "xor":
        return forward ? UEncryption.xorEncrypt(plainText: text, key: key, keyEncoding: _keyEncoding) : UEncryption.xorDecrypt(base64Encrypted: text, key: key, keyEncoding: _keyEncoding);
      case "base64":
        return forward ? UEncryption.base64EncodeText(text) : UEncryption.base64DecodeText(text);
      case "base64url":
        return forward ? UEncryption.base64UrlEncodeText(text) : UEncryption.base64UrlDecodeText(text);
      case "hex":
        return forward ? UEncryption.hexEncodeText(text) : UEncryption.hexDecodeText(text);
      case "base32":
        return forward ? UEncryption.base32EncodeText(text) : UEncryption.base32DecodeText(text);
      case "rot13":
        return UEncryption.rot13(text);
      case "caesar":
        {
          final int shift = int.tryParse(key) ?? 3;
          return forward ? UEncryption.caesarShift(text, shift) : UEncryption.caesarShift(text, -shift);
        }
      case "md5":
        return UEncryption.md5Hash(text);
      case "sha1":
        return UEncryption.sha1Hash(text);
      case "sha224":
        return UEncryption.sha224Hash(text);
      case "sha256":
        return UEncryption.sha256Hash(text);
      case "sha384":
        return UEncryption.sha384Hash(text);
      case "sha512":
        return UEncryption.sha512Hash(text);
      case "hmac":
        return UEncryption.hmacSha256(text, key);
      default:
        throw Exception("Unsupported algorithm");
    }
  }

  void _run(bool forward) {
    if (_inputController.text.isEmpty) {
      setState(() {
        _output = null;
        _error = U.s.pleaseEnterSomeInputText;
      });
      return;
    }
    try {
      final String result = _process(forward);
      setState(() {
        _output = result;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _output = null;
        _error = e.toString();
      });
    }
  }

  void _generateKey() {
    final int bytes = _algo.id == "aes" ? _aesKeyBytes : 32;
    setState(() {
      _keyEncoding = UByteEncoding.base64;
      _keyController.text = UEncryption.randomKey(bytes: bytes);
    });
  }

  void _generateIv() {
    final int bytes = _algo.id == "salsa20"
        ? 8
        : _aesMode == UAesMode.gcm
        ? 12
        : 16;
    setState(() {
      _ivEncoding = UByteEncoding.base64;
      _ivController.text = UEncryption.randomIv(bytes: bytes);
    });
  }

  void _copy(String value) {
    UClipboard.set(value);
    UToast.snackBar(message: U.s.copiedToClipboard);
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
            _algoSelector(cs),
            _configCard(cs),
            _inputCard(cs),
            _actions(cs),
            if (_output != null || _error != null) _outputCard(cs),
          ],
        ),
      ),
    );
  }

  Widget _header(ColorScheme cs) => URow(
    spacing: 14,
    children: <Widget>[
      Icon(Icons.security_rounded, size: 34, color: cs.primary).container(
        padding: const EdgeInsets.all(12),
        backgroundColor: cs.primary.withValues(alpha: 0.12),
        radius: 16,
      ),
      UColumn(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          UTextHeadlineSmall(U.s.cryptoTester, fontWeight: FontWeight.bold),
          UTextBodySmall(U.s.encryptDecryptEncodeAndHashTextLocallyNoServerCalls, color: cs.onSurface.withValues(alpha: 0.6)),
        ],
      ).expanded(),
    ],
  );

  Widget _algoSelector(ColorScheme cs) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: List<Widget>.generate(_algos.length, (int i) {
      final bool active = i == _selected;
      final _CryptoAlgo a = _algos[i];
      return URow(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: <Widget>[
              Icon(a.icon, size: 16, color: active ? cs.onPrimary : cs.primary),
              UTextLabelLarge(a.label, color: active ? cs.onPrimary : cs.onSurface, fontWeight: FontWeight.w600),
            ],
          )
          .pSymmetric(horizontal: 14, vertical: 10)
          .container(
            backgroundColor: active ? cs.primary : cs.surfaceContainerHighest.withValues(alpha: 0.5),
            radius: 12,
            borderColor: active ? cs.primary : cs.outlineVariant,
          )
          .onTap(
            () => setState(() {
              _selected = i;
              _output = null;
              _error = null;
            }),
          );
    }),
  );

  Widget _configCard(ColorScheme cs) {
    final List<Widget> rows = <Widget>[];
    if (_algo.isAes) rows.add(_aesConfig(cs));
    if (_algo.needsKey) rows.add(_keyField(cs));
    if (_algo.needsIv) rows.add(_ivField(cs));
    if (rows.isEmpty) return const SizedBox.shrink();
    return UCard(
      child: UColumn(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          URow(
            spacing: 10,
            children: <Widget>[
              Icon(Icons.tune_rounded, color: cs.primary),
              UTextTitleMedium(U.s.configuration, fontWeight: FontWeight.bold),
            ],
          ),
          const Divider(height: 1),
          ...rows,
        ],
      ).pAll(20),
    );
  }

  Widget _aesConfig(ColorScheme cs) => Wrap(
    spacing: 16,
    runSpacing: 14,
    children: <Widget>[
      SizedBox(
        width: 180,
        child: UDropDownField<UAesMode>(
          initialValue: _aesMode,
          labelText: U.s.mode,
          items: UAesMode.values.map((UAesMode m) => DropdownMenuItem<UAesMode>(value: m, child: UTextBodyMedium(_aesModeLabel(m)))).toList(),
          onChanged: (UAesMode? m) => setState(() => _aesMode = m ?? UAesMode.cbc),
        ),
      ),
      SizedBox(
        width: 150,
        child: UDropDownField<bool>(
          initialValue: _padding,
          labelText: U.s.padding,
          items: <DropdownMenuItem<bool>>[
            const DropdownMenuItem<bool>(value: true, child: UTextBodyMedium("PKCS7")),
            DropdownMenuItem<bool>(value: false, child: UTextBodyMedium(U.s.none)),
          ],
          onChanged: (bool? p) => setState(() => _padding = p ?? true),
        ),
      ),
      SizedBox(
        width: 150,
        child: UDropDownField<int>(
          initialValue: _aesKeyBytes,
          labelText: U.s.keySize,
          items: const <DropdownMenuItem<int>>[
            DropdownMenuItem<int>(value: 16, child: UTextBodyMedium("128-bit")),
            DropdownMenuItem<int>(value: 24, child: UTextBodyMedium("192-bit")),
            DropdownMenuItem<int>(value: 32, child: UTextBodyMedium("256-bit")),
          ],
          onChanged: (int? b) => setState(() => _aesKeyBytes = b ?? 32),
        ),
      ),
    ],
  );

  Widget _keyField(ColorScheme cs) {
    final bool mobile = context.isMobileWidth;
    final Widget field = UTextField(controller: _keyController, labelText: U.s.secretKey, hintText: U.s.secretKey);
    if (_algo.id == "hmac" || _algo.id == "caesar") return field;
    final Widget encoding = _encodingDropdown(_keyEncoding, (UByteEncoding e) => setState(() => _keyEncoding = e), U.s.keyEncoding);
    final Widget generateBtn = IconButton(
      tooltip: U.s.generate,
      onPressed: _generateKey,
      icon: Icon(Icons.casino_rounded, color: cs.primary),
    );
    if (mobile) {
      return UColumn(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          field,
          URow(spacing: 8, crossAxisAlignment: CrossAxisAlignment.end, children: <Widget>[encoding.expanded(), generateBtn]),
        ],
      );
    }
    return URow(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        field.expanded(),
        SizedBox(width: 130, child: encoding),
        generateBtn,
      ],
    );
  }

  Widget _ivField(ColorScheme cs) {
    final bool mobile = context.isMobileWidth;
    final Widget field = UTextField(controller: _ivController, labelText: U.s.ivInitializationVector, hintText: U.s.ivInitializationVector);
    final Widget encoding = _encodingDropdown(_ivEncoding, (UByteEncoding e) => setState(() => _ivEncoding = e), U.s.ivEncoding);
    final Widget generateBtn = IconButton(
      tooltip: U.s.generate,
      onPressed: _generateIv,
      icon: Icon(Icons.casino_rounded, color: cs.primary),
    );
    if (mobile) {
      return UColumn(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          field,
          URow(spacing: 10, crossAxisAlignment: CrossAxisAlignment.end, children: <Widget>[encoding.expanded(), generateBtn]),
        ],
      );
    }
    return URow(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        field.expanded(),
        SizedBox(width: 130, child: encoding),
        generateBtn,
      ],
    );
  }

  Widget _encodingDropdown(UByteEncoding value, ValueChanged<UByteEncoding> onChanged, String label) => UDropDownField<UByteEncoding>(
    initialValue: value,
    labelText: label,
    items: const <DropdownMenuItem<UByteEncoding>>[
      DropdownMenuItem<UByteEncoding>(value: UByteEncoding.utf8, child: UTextBodyMedium("UTF-8")),
      DropdownMenuItem<UByteEncoding>(value: UByteEncoding.base64, child: UTextBodyMedium("Base64")),
      DropdownMenuItem<UByteEncoding>(value: UByteEncoding.hex, child: UTextBodyMedium("Hex")),
    ],
    onChanged: (UByteEncoding? e) => onChanged(e ?? UByteEncoding.utf8),
  );

  Widget _inputCard(ColorScheme cs) => UCard(
    child: UColumn(
      margin: const EdgeInsets.all(20),
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        URow(
          spacing: 10,
          children: <Widget>[
            Icon(Icons.edit_note_rounded, color: cs.primary),
            UTextTitleMedium(U.s.inputText, fontWeight: FontWeight.bold),
            const Spacer(),
            if (_output != null)
              TextButton.icon(
                onPressed: () => setState(() {
                  _inputController.text = _output ?? "";
                  _output = null;
                  _error = null;
                }),
                icon: const Icon(Icons.swap_vert_rounded, size: 18),
                label: UTextLabelMedium(U.s.useOutputAsInput),
              ),
          ],
        ),
        UTextField(controller: _inputController, hintText: U.s.inputText, lines: 4, contentPadding: const EdgeInsets.all(16)),
      ],
    ),
  );

  Widget _actions(ColorScheme cs) {
    if (_algo.category == _Category.hash) {
      return UButton(
        title: U.s.hash,
        icon: const Icon(Icons.fingerprint_rounded),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        onTap: () => _run(true),
      );
    }
    final bool encoding = _algo.category == _Category.encoding;
    return URow(
      spacing: 12,
      children: <Widget>[
        UButton(
          title: encoding ? U.s.encode : U.s.encrypt,
          icon: Icon(encoding ? Icons.arrow_downward_rounded : Icons.lock_rounded),
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          onTap: () => _run(true),
        ).expanded(),
        UButton(
          title: encoding ? U.s.decode : U.s.decrypt,
          icon: Icon(encoding ? Icons.arrow_upward_rounded : Icons.lock_open_rounded),
          backgroundColor: cs.surfaceContainerHighest,
          foregroundColor: cs.onSurface,
          onTap: () => _run(false),
        ).expanded(),
      ],
    );
  }

  Widget _outputCard(ColorScheme cs) {
    if (_error != null) {
      return UCard(
        child: UColumn(
          margin: const EdgeInsets.all(20),
          spacing: 14,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            UTextTitleMedium(U.s.error, fontWeight: FontWeight.bold, color: cs.error),
            UContainer(
              padding: const EdgeInsets.all(14),
              color: cs.error.withValues(alpha: 0.08),
              radius: 8,
              child: SelectableText(
                _error!,
                style: TextStyle(fontFamily: "monospace", fontSize: 13, height: 1.5, color: cs.error),
              ).ltr(),
            ),
          ],
        ),
      );
    }
    final String output = _output ?? "";
    return UCard(
      child: UColumn(
        margin: const EdgeInsets.all(20),
        spacing: 14,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _resultBlock(cs, U.s.output, output),
          _resultBlock(cs, "Base64", UEncryption.base64EncodeText(output)),
        ],
      ),
    );
  }

  Widget _resultBlock(ColorScheme cs, String label, String value) => UColumn(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      URow(
        spacing: 10,
        children: <Widget>[
          UTextTitleMedium(label, fontWeight: FontWeight.bold, color: UAdminTheme.green),
          const Spacer(),
          IconButton(
            tooltip: U.s.copyToClipboard,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.copy_rounded, size: 18, color: cs.primary),
            onPressed: () => _copy(value),
          ),
        ],
      ),
      UContainer(
        padding: const EdgeInsets.all(14),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        radius: 8,
        child: SelectableText(
          value,
          style: TextStyle(fontFamily: "monospace", fontSize: 13, height: 1.5, color: cs.onSurface),
        ).ltr(),
      ),
    ],
  );

  String _aesModeLabel(UAesMode mode) => switch (mode) {
    UAesMode.cbc => "CBC",
    UAesMode.cfb64 => "CFB-64",
    UAesMode.ctr => "CTR",
    UAesMode.ecb => "ECB",
    UAesMode.ofb64 => "OFB-64",
    UAesMode.ofb64Gctr => "OFB-64/GCTR",
    UAesMode.sic => "SIC",
    UAesMode.gcm => "GCM",
  };
}

enum _Category { symmetric, encoding, hash }

// Static description of one algorithm the tester exposes and which inputs it needs.
class _CryptoAlgo {
  _CryptoAlgo({
    required this.id,
    required this.label,
    required this.category,
    required this.icon,
    this.needsKey = false,
    this.needsIv = false,
    this.isAes = false,
  });

  final String id;
  final String label;
  final _Category category;
  final IconData icon;
  final bool needsKey;
  final bool needsIv;
  final bool isAes;
}
