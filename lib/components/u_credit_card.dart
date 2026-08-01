// Self-contained credit card UI + form for Flutter. No external packages.
// Provides: CreditCardModel, CardBrand detection, CreditCardWidget (flip card),
// and CreditCardForm (validated, masked inputs). Pure Flutter/Dart.

import "package:flutter/material.dart";
import "package:flutter/services.dart";

// ---------------------------------------------------------------------------
// MODEL
// ---------------------------------------------------------------------------

// Holds the current state of a card; mutated as the user types in the form.
class CreditCardModel {
  CreditCardModel({
    this.cardNumber = "",
    this.expiryDate = "",
    this.cardHolderName = "",
    this.cvvCode = "",
    this.isCvvFocused = false,
  });

  String cardNumber;
  String expiryDate;
  String cardHolderName;
  String cvvCode;
  bool isCvvFocused; // when true, the card shows its back (CVV) side
}

// ---------------------------------------------------------------------------
// BRAND DETECTION
// ---------------------------------------------------------------------------

// Supported card brands the detector can recognize from the number prefix.
enum CardBrand { visa, mastercard, amex, discover, dinersClub, jcb, unknown }

// Detects the brand purely from the digit prefix of the card number.
class CardBrandDetector {
  static CardBrand detect(String input) {
    final String number = input.replaceAll(RegExp(r"\D"), "");
    if (number.isEmpty) return CardBrand.unknown;

    if (RegExp(r"^4").hasMatch(number)) return CardBrand.visa;
    if (RegExp(r"^(5[1-5]|2[2-7])").hasMatch(number)) return CardBrand.mastercard;
    if (RegExp(r"^3[47]").hasMatch(number)) return CardBrand.amex;
    if (RegExp(r"^6(011|5|4[4-9]|22)").hasMatch(number)) return CardBrand.discover;
    if (RegExp(r"^3(0[0-5]|[68])").hasMatch(number)) return CardBrand.dinersClub;
    if (RegExp(r"^35").hasMatch(number)) return CardBrand.jcb;
    return CardBrand.unknown;
  }

  // Human-readable label used on the card face.
  static String label(CardBrand brand) {
    switch (brand) {
      case CardBrand.visa:
        return "VISA";
      case CardBrand.mastercard:
        return "Mastercard";
      case CardBrand.amex:
        return "AMEX";
      case CardBrand.discover:
        return "Discover";
      case CardBrand.dinersClub:
        return "Diners Club";
      case CardBrand.jcb:
        return "JCB";
      case CardBrand.unknown:
        return "";
    }
  }

  // Amex uses a 4-6-5 grouping and a 4-digit CVV; everyone else 4-4-4-4 / 3-digit.
  static bool isAmex(CardBrand brand) => brand == CardBrand.amex;
}

// ---------------------------------------------------------------------------
// INPUT FORMATTERS
// ---------------------------------------------------------------------------

// Groups card number digits (4-4-4-4, or 4-6-5 for Amex) and caps the length.
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final String digits = newValue.text.replaceAll(RegExp(r"\D"), "");
    final bool isAmex = CardBrandDetector.isAmex(CardBrandDetector.detect(digits));
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

// Formats expiry as MM/YY and caps to 4 digits.
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

// ---------------------------------------------------------------------------
// CARD WIDGET (front + back with smooth 3D flip)
// ---------------------------------------------------------------------------

// The visual card that flips to reveal the CVV when [showBackView] is true.
class CreditCardWidget extends StatefulWidget {
  const CreditCardWidget({
    required this.cardNumber,
    required this.expiryDate,
    required this.cardHolderName,
    required this.cvvCode,
    required this.showBackView,
    super.key,
    this.height,
    this.width,
    this.gradient,
    this.animationDuration = const Duration(milliseconds: 500),
    this.obscureCardNumber = true,
    this.onBrandChanged,
  });

  final String cardNumber;
  final String expiryDate;
  final String cardHolderName;
  final String cvvCode;
  final bool showBackView;
  final double? height;
  final double? width;
  final Gradient? gradient;
  final Duration animationDuration;
  final bool obscureCardNumber;
  final ValueChanged<CardBrand>? onBrandChanged;

  @override
  State<CreditCardWidget> createState() => _CreditCardWidgetState();
}

class _CreditCardWidgetState extends State<CreditCardWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  CardBrand _brand = CardBrand.unknown;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.animationDuration);
    // Eased curve makes the flip feel fluid rather than linear.
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    if (widget.showBackView) _controller.value = 1.0;
    _brand = CardBrandDetector.detect(widget.cardNumber);
  }

  @override
  void didUpdateWidget(covariant CreditCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Drive the flip whenever the requested side changes.
    if (widget.showBackView != oldWidget.showBackView) {
      widget.showBackView ? _controller.forward() : _controller.reverse();
    }
    // Re-detect brand and notify the parent only when it actually changes.
    final CardBrand newBrand = CardBrandDetector.detect(widget.cardNumber);
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
        // angle goes 0 -> pi; we swap faces at the halfway point.
        final double angle = _animation.value * 3.1415926535;
        final bool isBack = angle > 1.5707963267;
        final Matrix4 transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001) // perspective
          ..rotateY(angle);

        return Transform(
          alignment: Alignment.center,
          transform: transform,
          child: isBack
              // Counter-rotate the back face so its text isn't mirrored.
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

  // Default gradient if the caller doesn't supply one.
  Gradient get _gradient =>
      widget.gradient ??
      const LinearGradient(
        colors: <Color>[Color(0xFF2C3E50), Color(0xFF4CA1AF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // Front face: chip, brand, number, holder, expiry.
  Widget _buildFront(double width, double height) {
    final String number = _displayNumber();
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: _gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              // Stylized chip drawn with plain containers.
              Container(
                width: 44,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Text(
                CardBrandDetector.label(_brand),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Spacer(),
          Text(
            number,
            style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 2, fontFamily: "monospace"),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: _labelled("CARD HOLDER", widget.cardHolderName.isEmpty ? "YOUR NAME" : widget.cardHolderName.toUpperCase()),
              ),
              _labelled("EXPIRES", widget.expiryDate.isEmpty ? "MM/YY" : widget.expiryDate),
            ],
          ),
        ],
      ),
    );
  }

  // Back face: magnetic stripe and CVV box.
  Widget _buildBack(double width, double height) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      gradient: _gradient,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const <BoxShadow>[BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6))],
    ),
    child: Column(
      children: <Widget>[
        const SizedBox(height: 20),
        Container(height: 44, color: Colors.black87), // magnetic stripe
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              const Text("CVV", style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(width: 8),
              Container(
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
          padding: const EdgeInsets.only(right: 22, bottom: 16),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              CardBrandDetector.label(_brand),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    ),
  );

  // Small two-line caption/value pair used on the front face.
  Widget _labelled(String caption, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(caption, style: const TextStyle(color: Colors.white70, fontSize: 9, letterSpacing: 1)),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );

  // Masks all but the last 4 digits when obscuring is enabled.
  String _displayNumber() {
    if (widget.cardNumber.isEmpty) {
      return CardBrandDetector.isAmex(_brand) ? "#### ###### #####" : "#### #### #### ####";
    }
    if (!widget.obscureCardNumber) return widget.cardNumber;
    return widget.cardNumber.replaceAllMapped(RegExp(r"\d(?=\d{4,}$)"), (_) => "*");
  }
}

// ---------------------------------------------------------------------------
// FORM (validated inputs that drive the card model)
// ---------------------------------------------------------------------------

// Editable form for card details; reports every change via [onChanged].
class CreditCardForm extends StatefulWidget {
  const CreditCardForm({
    required this.model,
    required this.onChanged,
    super.key,
    this.formKey,
    this.obscureCvv = true,
  });

  final CreditCardModel model;
  final ValueChanged<CreditCardModel> onChanged;
  final GlobalKey<FormState>? formKey;
  final bool obscureCvv;

  @override
  State<CreditCardForm> createState() => _CreditCardFormState();
}

class _CreditCardFormState extends State<CreditCardForm> {
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
    // Flip the card to its back while the CVV field is focused.
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

  // Pushes the latest field values back through the callback.
  void _emit() {
    widget.model
      ..cardNumber = _numberCtrl.text
      ..expiryDate = _expiryCtrl.text
      ..cardHolderName = _nameCtrl.text
      ..cvvCode = _cvvCtrl.text;
    widget.onChanged(widget.model);
  }

  // Luhn checksum so obviously-invalid numbers are rejected.
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
    final bool isAmex = CardBrandDetector.isAmex(CardBrandDetector.detect(_numberCtrl.text));
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

  // Validates MM/YY format and that the date is not in the past.
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

// ---------------------------------------------------------------------------
// DEMO PAGE (delete if you only want the components)
// ---------------------------------------------------------------------------

// Minimal screen wiring the card and form together.
class CreditCardDemoPage extends StatefulWidget {
  const CreditCardDemoPage({super.key});

  @override
  State<CreditCardDemoPage> createState() => _CreditCardDemoPageState();
}

class _CreditCardDemoPageState extends State<CreditCardDemoPage> {
  final CreditCardModel _model = CreditCardModel();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Credit Card")),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          CreditCardWidget(
            cardNumber: _model.cardNumber,
            expiryDate: _model.expiryDate,
            cardHolderName: _model.cardHolderName,
            cvvCode: _model.cvvCode,
            showBackView: _model.isCvvFocused,
          ),
          const SizedBox(height: 24),
          CreditCardForm(
            model: _model,
            formKey: _formKey,
            onChanged: (CreditCardModel m) => setState(() {}),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Card is valid")));
              }
            },
            child: const Text("Validate"),
          ),
        ],
      ),
    ),
  );
}
