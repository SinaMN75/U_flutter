import "package:u/utilities.dart";

import "../widgets/demo_section.dart";
import "../widgets/gallery_page.dart";

/// Demonstrates the static utility classes: crypto, Persian tools, UUID,
/// clipboard, share, launch and key-value storage.
class UtilsPage extends StatelessWidget {
  const UtilsPage({super.key});

  @override
  Widget build(BuildContext context) => GalleryPage(
    title: "Utilities",
    intro: "Stateless helper classes for hashing, Persian/Iran logic, IDs, clipboard, sharing, "
        "deep-linking and persistent storage.",
    sections: <Widget>[
      DemoSection(
        title: "UEncryption",
        description: "Hashing and AES/Fernet/Salsa20 encryption plus secure key generation.",
        code: r'''
UEncryption.md5Hash("hello");
UEncryption.sha256Hash("hello");
UEncryption.randomKey();''',
        child: UColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: <Widget>[
            DemoLabel("md5('hello') = ${UEncryption.md5Hash("hello")}"),
            DemoLabel("sha256('hello') = ${UEncryption.sha256Hash("hello").maxLength(max: 32)}…"),
          ],
        ),
      ),
      DemoSection(
        title: "PersianTools",
        description: "National-code and card validation, bank lookup, number-to-words, digit conversion.",
        code: r'''
PersianTools.validateNationalCode("0067749828");
PersianTools.getBankNameFromCard("6274121122334455");
PersianTools.numberToWords(1234);''',
        child: UColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: <Widget>[
            DemoLabel("validateNationalCode('0067749828') = ${PersianTools.validateNationalCode("0067749828")}"),
            DemoLabel("numberToWords(1234) = ${PersianTools.numberToWords(1234)}"),
            DemoLabel("bank of 6274… = ${PersianTools.getBankNameFromCard("6274121122334455") ?? "unknown"}"),
          ],
        ),
      ),
      DemoSection(
        title: "UUUID",
        description: "Generate v1/v4/v5/v6/v7/v8 UUIDs.",
        code: r'''UUUID.uuidV4();''',
        child: DemoLabel("uuidV4() = ${UUUID.uuidV4()}"),
      ),
      DemoSection(
        title: "UClipboard & UShare",
        description: "Copy text to the clipboard or open the OS share sheet.",
        code: r'''
UClipboard.set("copied text");
UShare.text(text: "Check out the u plugin");''',
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            UButton(
              title: "Copy",
              type: UButtonType.outlined,
              icon: const Icon(Icons.copy, size: 16),
              onTap: () => UClipboard.set("Copied from the u gallery", snackBar: true),
            ),
            UButton(
              title: "Share",
              type: UButtonType.outlined,
              icon: const Icon(Icons.ios_share, size: 16),
              onTap: () => UShare.text(text: "Check out the u plugin"),
            ),
          ],
        ),
      ),
      DemoSection(
        title: "ULaunch",
        description: "Deep-link to phone, SMS, maps, WhatsApp, Telegram, Instagram or any URL.",
        code: r'''
ULaunch.launchURL("https://sinamn75.com");
ULaunch.call("+989120000000");''',
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            UButton(title: "Open URL", type: UButtonType.outlined, onTap: () => ULaunch.launchURL("https://sinamn75.com")),
            UButton(title: "Call", type: UButtonType.outlined, onTap: () => ULaunch.call("+989120000000")),
          ],
        ),
      ),
      DemoSection(
        title: "ULocalStorage",
        description: "Typed key-value persistence (with optional expiry and encryption).",
        code: r'''
ULocalStorage.set("nickname", "sina");
final String? name = ULocalStorage.getString("nickname");''',
        child: UButton(
          title: "Save & read back",
          onTap: () {
            ULocalStorage.set("nickname", "sina");
            final String? name = ULocalStorage.getString("nickname");
            UToast.success(message: "Stored nickname = $name");
          },
        ),
      ),
    ],
  );
}
