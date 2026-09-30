import "package:u/utilities.dart";

/// Card details typed in UCreditCardForm (number, expiry, holder, CVV).
class UCreditCardModel {
  UCreditCardModel({
    this.cardNumber = "",
    this.expiryDate = "",
    this.cardHolderName = "",
    this.cvvCode = "",
    this.isCvvFocused = false,
  });

  /// Card number.
  String cardNumber;

  /// Expiry "MM/YY".
  String expiryDate;

  /// Holder name.
  String cardHolderName;

  /// CVV / CVV2.
  String cvvCode;

  /// True while the CVV field is focused (card flips).
  bool isCvvFocused;
}

/// Card network or Iranian bank detected from the number.
enum UCardBrand { visa, mastercard, amex, discover, dinersClub, jcb, unionPay, maestro, mir, unknown }

/// Detects card brand/bank from the first digits and gives its colors.
class UCardBrandDetector {
  /// Brand from a (partial) card number. `UCardBrandDetector.detect("6037")`
  static UCardBrand detect(String input) {
    final String n = input.replaceAll(RegExp(r"\D"), "");
    if (n.isEmpty) return UCardBrand.unknown;
    if (RegExp("^220[0-4]").hasMatch(n)) return UCardBrand.mir;
    if (RegExp("^4").hasMatch(n)) return UCardBrand.visa;
    if (RegExp("^3[47]").hasMatch(n)) return UCardBrand.amex;
    if (RegExp("^3(0[0-5]|[68])").hasMatch(n)) return UCardBrand.dinersClub;
    if (RegExp("^35").hasMatch(n)) return UCardBrand.jcb;
    if (RegExp("^(5018|5020|5038|56|57|58|6304|6759|676[1-3])").hasMatch(n)) return UCardBrand.maestro;
    if (RegExp("^(5[1-5]|2[2-7])").hasMatch(n)) return UCardBrand.mastercard;
    if (RegExp("^62").hasMatch(n)) return UCardBrand.unionPay;
    if (RegExp("^6(011|5|4[4-9]|22)").hasMatch(n)) return UCardBrand.discover;
    return UCardBrand.unknown;
  }

  /// Brand display name.
  static String label(UCardBrand brand) {
    switch (brand) {
      case UCardBrand.visa:
        return "VISA";
      case UCardBrand.mastercard:
        return "Mastercard";
      case UCardBrand.amex:
        return "AMEX";
      case UCardBrand.discover:
        return "Discover";
      case UCardBrand.dinersClub:
        return "Diners Club";
      case UCardBrand.jcb:
        return "JCB";
      case UCardBrand.unionPay:
        return "UnionPay";
      case UCardBrand.maestro:
        return "Maestro";
      case UCardBrand.mir:
        return "MIR";
      case UCardBrand.unknown:
        return "";
    }
  }

  /// Card background colors of a brand.
  static List<Color> gradientColors(UCardBrand brand) {
    switch (brand) {
      case UCardBrand.visa:
        return const <Color>[Color(0xFF1A1F71), Color(0xFF3B4BA0)];
      case UCardBrand.mastercard:
        return const <Color>[Color(0xFFEB001B), Color(0xFFF79E1B)];
      case UCardBrand.amex:
        return const <Color>[Color(0xFF2E7D9E), Color(0xFF16506B)];
      case UCardBrand.discover:
        return const <Color>[Color(0xFFF48120), Color(0xFF2A2E33)];
      case UCardBrand.dinersClub:
        return const <Color>[Color(0xFF0079BE), Color(0xFF00456B)];
      case UCardBrand.jcb:
        return const <Color>[Color(0xFF1D3F8B), Color(0xFFB01030)];
      case UCardBrand.unionPay:
        return const <Color>[Color(0xFF00447C), Color(0xFF007B84)];
      case UCardBrand.maestro:
        return const <Color>[Color(0xFF0099DF), Color(0xFFCC0000)];
      case UCardBrand.mir:
        return const <Color>[Color(0xFF0F754C), Color(0xFF0A4732)];
      case UCardBrand.unknown:
        return const <Color>[Color(0xFF2C3E50), Color(0xFF4CA1AF)];
    }
  }

  /// True for American Express (4-digit CVV).
  static bool isAmex(UCardBrand brand) => brand == UCardBrand.amex;
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final String digits = newValue.text.replaceAll(RegExp(r"\D"), "");
    final bool isAmex = UCardBrandDetector.isAmex(UCardBrandDetector.detect(digits));
    final int maxLen = isAmex ? 15 : 16;
    final String trimmed = digits.length > maxLen ? digits.substring(0, maxLen) : digits;
    final List<int> groups = isAmex ? <int>[4, 6, 5] : <int>[4, 4, 4, 4];
    final StringBuffer buffer = StringBuffer();
    int index = 0;
    for (final int size in groups) {
      if (index >= trimmed.length) break;
      if (index != 0) buffer.write(" ");
      final int end = (index + size).clamp(0, trimmed.length);
      buffer.write(trimmed.substring(index, end));
      index = end;
    }
    final String text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final String digits = newValue.text.replaceAll(RegExp(r"\D"), "");
    final String trimmed = digits.length > 4 ? digits.substring(0, 4) : digits;
    final String text = trimmed.length >= 3 ? "${trimmed.substring(0, 2)}/${trimmed.substring(2)}" : trimmed;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Animated bank card that flips to the back for CVV, with brand colors. `UCreditCardWidget(cardNumber: n, expiryDate: e, cardHolderName: h, cvvCode: c, showBackView: false)`
class UCreditCardWidget extends StatefulWidget {
  const UCreditCardWidget({
    required this.cardNumber,
    required this.expiryDate,
    required this.cardHolderName,
    required this.cvvCode,
    required this.showBackView,
    super.key,
    this.height,
    this.width,
    this.gradient,
    this.title,
    this.logo,
    this.brandLabel,
    this.animationDuration = const Duration(milliseconds: 500),
    this.obscureCardNumber = true,
    this.onBrandChanged,
    this.chipColor = const Color(0xFFD4AF37),
    this.borderRadius = 18,
    this.boxShadow = const <BoxShadow>[BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6))],
    this.padding = const EdgeInsets.all(20),
    this.numberStyle,
    this.spreadNumberGroups = false,
    this.showCvvOnFront = false,
    this.cardHolderLabel = "",
    this.expiryLabel = "EXP",
    this.cvvLabel = "CVV",
    this.labelStyle,
    this.valueStyle,
    this.digitsFormatter,
  });

  /// Card number to show.
  final String cardNumber;

  /// Expiry to show.
  final String expiryDate;

  /// Holder name to show.
  final String cardHolderName;

  /// CVV to show on the back.
  final String cvvCode;

  /// Flips to the back.
  final bool showBackView;

  /// Height in logical pixels (null = size to content).
  final double? height;

  /// Width in logical pixels (null = size to content).
  final double? width;

  /// Background gradient (overrides the color).
  final Gradient? gradient;

  /// Title text.
  final String? title;

  /// Your own brand logo.
  final Widget? logo;

  /// Brand text override.
  final String? brandLabel;

  /// Length of the animation.
  final Duration animationDuration;

  /// Hides the middle digits.
  final bool obscureCardNumber;

  /// Called when the detected brand changes.
  final ValueChanged<UCardBrand>? onBrandChanged;

  /// Chip color.
  final Color chipColor;

  /// Corner radius.
  final double borderRadius;

  /// Shadows under it.
  final List<BoxShadow>? boxShadow;

  /// Space inside, around the content.
  final EdgeInsetsGeometry padding;

  /// Number text style.
  final TextStyle? numberStyle;

  /// Spreads the 4-digit groups across the card.
  final bool spreadNumberGroups;

  /// Shows CVV on the front (some Iranian cards).
  final bool showCvvOnFront;

  /// Label above the holder name.
  final String cardHolderLabel;

  /// Label above the expiry.
  final String expiryLabel;

  /// Label of the CVV.
  final String cvvLabel;

  /// Label style.
  final TextStyle? labelStyle;

  /// Value style.
  final TextStyle? valueStyle;

  /// Formats digits for display (e.g. Persian digits).
  final String Function(String value)? digitsFormatter;

  @override
  State<UCreditCardWidget> createState() => _CreditCardWidgetState();
}

class _CreditCardWidgetState extends State<UCreditCardWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  UCardBrand _brand = UCardBrand.unknown;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.animationDuration);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    if (widget.showBackView) _controller.value = 1.0;
    _brand = UCardBrandDetector.detect(widget.cardNumber);
  }

  @override
  void didUpdateWidget(covariant UCreditCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showBackView != oldWidget.showBackView) {
      widget.showBackView ? _controller.forward() : _controller.reverse();
    }
    final UCardBrand newBrand = UCardBrandDetector.detect(widget.cardNumber);
    if (newBrand != _brand) {
      _brand = newBrand;
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onBrandChanged?.call(newBrand));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = widget.width ?? MediaQuery.of(context).size.width * 0.9;
    final double height = widget.height ?? width * 0.62;
    return AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext context, _) {
        final double angle = _animation.value * 3.1415926535;
        final bool isBack = angle > 1.5707963267;
        final Matrix4 transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(angle);
        return Transform(
          alignment: Alignment.center,
          transform: transform,
          child: isBack
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(3.1415926535),
                  child: _buildBack(width, height),
                )
              : _buildFront(width, height),
        );
      },
    );
  }

  Gradient get _gradient =>
      widget.gradient ??
      LinearGradient(
        colors: UCardBrandDetector.gradientColors(_brand),
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      );

  Widget _buildFront(double width, double height) {
    final Widget mark =
        widget.logo ??
        Text(
          widget.brandLabel ?? UCardBrandDetector.label(_brand),
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        );
    final String expiry = widget.expiryDate.isEmpty ? "MM/YY" : _digits(widget.expiryDate);
    return UContainer(
      width: width,
      height: height,
      padding: widget.padding,
      gradient: _gradient,
      radius: widget.borderRadius,
      boxShadow: widget.boxShadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              UContainer(
                width: 42,
                height: 30,
                color: widget.chipColor,
                radius: 6,
              ),
              mark,
            ],
          ),
          if (widget.title != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              widget.title!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
          const Spacer(),
          _number(),
          const Spacer(),
          if (widget.showCvvOnFront)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(flex: 2, child: _labelled(widget.cardHolderLabel, widget.cardHolderName.isEmpty ? "—" : widget.cardHolderName)),
                Expanded(child: _labelled(widget.expiryLabel, expiry)),
                Expanded(child: _labelled(widget.cvvLabel, widget.cvvCode.isEmpty ? "***" : _digits(widget.cvvCode))),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(child: _labelled(widget.cardHolderLabel, widget.cardHolderName.isEmpty ? "—" : widget.cardHolderName)),
                _labelled(widget.expiryLabel, expiry),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBack(double width, double height) => UContainer(
    width: width,
    height: height,
    gradient: _gradient,
    radius: widget.borderRadius,
    boxShadow: widget.boxShadow,
    child: Column(
      children: <Widget>[
        const SizedBox(height: 20),
        const UContainer(height: 44, color: Colors.black87),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              const Text("CVV", style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(width: 8),
              UContainer(
                width: 70,
                height: 30,
                alignment: Alignment.center,
                color: Colors.white,
                child: Text(
                  widget.cvvCode.isEmpty ? "***" : widget.cvvCode,
                  style: const TextStyle(color: Colors.black, fontSize: 16, letterSpacing: 2),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(right: 20, bottom: 16),
          child: Align(
            alignment: Alignment.centerRight,
            child:
                widget.logo ??
                Text(
                  widget.brandLabel ?? UCardBrandDetector.label(_brand),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
          ),
        ),
      ],
    ),
  );

  Widget _labelled(String caption, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(caption, style: widget.labelStyle ?? const TextStyle(color: Colors.white70, fontSize: 9, letterSpacing: 1)),
      const SizedBox(height: 4),
      Text(
        value,
        style: widget.valueStyle ?? const TextStyle(color: Colors.white, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );

  String _digits(String value) => widget.digitsFormatter?.call(value) ?? value;

  Widget _number() {
    final TextStyle style = widget.numberStyle ?? const TextStyle(color: Colors.white, fontSize: 20, fontFamily: "monospace");
    final String number = _displayNumber();
    if (!widget.spreadNumberGroups) return Text(_digits(number), style: style);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: number.trim().split(RegExp(r"\s+")).map((String group) => Text(_digits(group), style: style)).toList(),
    );
  }

  String _displayNumber() {
    if (widget.cardNumber.isEmpty) {
      return UCardBrandDetector.isAmex(_brand) ? "#### ###### #####" : "#### #### #### ####";
    }
    if (!widget.obscureCardNumber) return widget.cardNumber;
    return widget.cardNumber.replaceAllMapped(RegExp(r"\d(?=\d{4,}$)"), (_) => "*");
  }
}

/// Card number / expiry / holder / CVV fields that fill a UCreditCardModel. `UCreditCardForm(model: model, onChanged: (m) => setState(() {}))`
class UCreditCardForm extends StatefulWidget {
  const UCreditCardForm({
    required this.model,
    required this.onChanged,
    super.key,
    this.formKey,
    this.obscureCvv = true,
  });

  /// The model the fields fill.
  final UCreditCardModel model;

  /// Called with the new value when the user changes it.
  final ValueChanged<UCreditCardModel> onChanged;

  /// Form key for validation.
  final GlobalKey<FormState>? formKey;

  /// Hides the CVV while typing.
  final bool obscureCvv;

  @override
  State<UCreditCardForm> createState() => _CreditCardFormState();
}

class _CreditCardFormState extends State<UCreditCardForm> {
  late final TextEditingController _numberCtrl;
  late final TextEditingController _expiryCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _cvvCtrl;
  final FocusNode _cvvFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _numberCtrl = TextEditingController(text: widget.model.cardNumber);
    _expiryCtrl = TextEditingController(text: widget.model.expiryDate);
    _nameCtrl = TextEditingController(text: widget.model.cardHolderName);
    _cvvCtrl = TextEditingController(text: widget.model.cvvCode);
    _cvvFocus.addListener(() {
      widget.model.isCvvFocused = _cvvFocus.hasFocus;
      widget.onChanged(widget.model);
    });
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _expiryCtrl.dispose();
    _nameCtrl.dispose();
    _cvvCtrl.dispose();
    _cvvFocus.dispose();
    super.dispose();
  }

  void _emit() {
    widget.model
      ..cardNumber = _numberCtrl.text
      ..expiryDate = _expiryCtrl.text
      ..cardHolderName = _nameCtrl.text
      ..cvvCode = _cvvCtrl.text;
    widget.onChanged(widget.model);
  }

  bool _luhnValid(String number) {
    final String digits = number.replaceAll(RegExp(r"\D"), "");
    if (digits.length < 13) return false;
    int sum = 0;
    bool alt = false;
    for (int i = digits.length - 1; i >= 0; i--) {
      int d = int.parse(digits[i]);
      if (alt) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      sum += d;
      alt = !alt;
    }
    return sum % 10 == 0;
  }

  @override
  Widget build(BuildContext context) {
    final bool isAmex = UCardBrandDetector.isAmex(UCardBrandDetector.detect(_numberCtrl.text));
    return Form(
      key: widget.formKey,
      child: Column(
        children: <Widget>[
          TextFormField(
            controller: _numberCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[_CardNumberFormatter()],
            decoration: const InputDecoration(labelText: "Card Number", hintText: "XXXX XXXX XXXX XXXX", border: OutlineInputBorder()),
            onChanged: (_) => _emit(),
            validator: (String? v) => _luhnValid(v ?? "") ? null : "Enter a valid card number",
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: "Card Holder", hintText: "NAME ON CARD", border: OutlineInputBorder()),
            onChanged: (_) => _emit(),
            validator: (String? v) => (v == null || v.trim().isEmpty) ? "Enter the card holder name" : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  controller: _expiryCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[_ExpiryFormatter()],
                  decoration: const InputDecoration(labelText: "Expiry", hintText: "MM/YY", border: OutlineInputBorder()),
                  onChanged: (_) => _emit(),
                  validator: _validateExpiry,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _cvvCtrl,
                  focusNode: _cvvFocus,
                  keyboardType: TextInputType.number,
                  obscureText: widget.obscureCvv,
                  maxLength: isAmex ? 4 : 3,
                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: "CVV", hintText: "XXX", border: OutlineInputBorder(), counterText: ""),
                  onChanged: (_) => _emit(),
                  validator: (String? v) {
                    final int len = isAmex ? 4 : 3;
                    return (v != null && v.length == len) ? null : "Enter a valid CVV";
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _validateExpiry(String? v) {
    if (v == null || v.length != 5) return "Invalid date";
    final List<String> parts = v.split("/");
    final int? month = int.tryParse(parts[0]);
    final int? year = int.tryParse(parts[1]);
    if (month == null || year == null || month < 1 || month > 12) return "Invalid date";
    final DateTime now = DateTime.now();
    final int fullYear = 2000 + year;
    final DateTime expiry = DateTime(fullYear, month + 1);
    return expiry.isAfter(now) ? null : "Card expired";
  }
}
