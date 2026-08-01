import "package:u/utilities.dart";

import "../widgets/demo_section.dart";
import "../widgets/gallery_page.dart";

/// Demonstrates `UTextField`, `UOtpField` and `UValidators` in a real form.
class InputsPage extends StatefulWidget {
  const InputsPage({super.key});

  @override
  State<InputsPage> createState() => _InputsPageState();
}

class _InputsPageState extends State<InputsPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  String _otp = "";
  String _size = "m";
  int _chip = 0;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GalleryPage(
    title: "Inputs",
    intro: "UTextField pairs with UValidators for validation and TextEditingController "
        "extensions (numString/numInt) for parsing. UOtpField handles one-time codes.",
    sections: <Widget>[
      DemoSection(
        title: "Validated form",
        description: "Wrap fields in a Form; each validator comes from UValidators. "
            "Tap Submit to run them.",
        code: r'''
UTextField(
  labelText: "Email",
  hasClearButton: true,
  keyboardType: TextInputType.emailAddress,
  validator: UValidators.email(),
  controller: _email,
);''',
        child: Form(
          key: _formKey,
          child: UColumn(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: <Widget>[
              UTextField(
                labelText: "Email",
                hintText: "you@example.com",
                hasClearButton: true,
                keyboardType: TextInputType.emailAddress,
                controller: _email,
                validator: UValidators.email(),
              ),
              UTextField(
                labelText: "Password",
                obscureText: true,
                required: true,
                controller: _password,
                validator: UValidators.minLength(minLength: 6, message: "At least 6 characters"),
              ),
              UButton(
                title: "Submit",
                onTap: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    UToast.success(message: "Form is valid");
                  } else {
                    UToast.error(message: "Fix the errors above");
                  }
                },
              ),
            ],
          ),
        ),
      ),
      DemoSection(
        title: "UOtpField",
        description: "A segmented one-time-code field; onCompleted fires when every box is filled.",
        code: r'''
UOtpField(
  length: 5,
  onCompleted: (String code) => UToast.success(message: "Code: $code"),
);''',
        child: UColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: <Widget>[
            UOtpField(
              length: 5,
              onChanged: (String v) => setState(() => _otp = v),
              onCompleted: (String code) => UToast.success(message: "Code: $code"),
            ),
            DemoLabel("Current value: $_otp"),
          ],
        ),
      ),
      DemoSection(
        title: "USegmentedControl",
        description: "A single-choice segmented selector backed by a Map of value → label.",
        code: r'''
USegmentedControl<String>(
  items: <String, String>{"s": "Small", "m": "Medium", "l": "Large"},
  selectedValue: size,
  onValueChanged: (String? v) => setState(() => size = v ?? "m"),
);''',
        child: USegmentedControl<String>(
          items: const <String, String>{"s": "Small", "m": "Medium", "l": "Large"},
          selectedValue: _size,
          onValueChanged: (String? v) => setState(() => _size = v ?? "m"),
        ),
      ),
      DemoSection(
        title: "UChipChoice",
        description: "Selectable chips (single or multi) built from a list of options.",
        code: r'''
UChipChoice<String>(
  options: <String>["All", "Active", "Archived"],
  selected: index,
  onChanged: (int i, bool sel, String item) => setState(() => index = i),
);''',
        child: UChipChoice<String>(
          options: const <String>["All", "Active", "Archived"],
          selected: _chip,
          onChanged: (int i, bool sel, String item) => setState(() => _chip = i),
        ),
      ),
      DemoSection(
        title: "UPlateField",
        description: "An Iranian license-plate input with the correct layout and validation.",
        code: r'''UPlateField(onPlateChange: (String plate) => setState(...));''',
        child: UPlateField(onPlateChange: (String plate) {}),
      ),
    ],
  );
}
