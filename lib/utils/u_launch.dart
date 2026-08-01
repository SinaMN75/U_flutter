import "package:u/utilities.dart";

abstract class ULaunch {
  static Future<void> launchURL(final String url, {final LaunchMode mode = LaunchMode.platformDefault}) async => launchUrl(
    Uri.parse(url),
    mode: mode,
    webOnlyWindowName: kIsWeb ? "_self" : null,
  );

  static Future<void> launchWhatsApp(final String number) async => launchURL("https://api.whatsapp.com/send?phone=$number");

  static Future<void> launchMap(final double latitude, final double longitude) async => launchURL(
    Uri(scheme: "geo", queryParameters: <String, String>{"q": "$latitude,$longitude"}).toString(),
  );

  static Future<void> launchTelegram(final String id) async => launchURL("https://t.me/$id");

  static Future<void> launchInstagram(final String username) async => launchURL("https://instagram.com/$username");

  static Future<void> call(final String phone) async => launchURL("tel:$phone");

  static Future<void> sms(final String phone, final String body) async => launchURL("sms:$phone?body=$body");

  static Future<void> shareWithTelegram(final String param) async => launchURL("tg://msg?text=$param");

  static Future<void> shareWithWhatsapp(final String param) async => launchURL("whatsapp://send?text=$param");

  static Future<void> shareWithEmail(final String param) async => launchURL("mailto:?body=$param");

  static void email(final String email, final String subject) => launchURL(
    Uri(
      scheme: "mailto",
      path: email,
      query: <String, String>{"subject": subject}.entries
          .map(
            (final MapEntry<String, String> e) => "${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}",
          )
          .join("&"),
    ).toString(),
  );

  static void shareText(final String text, {final String? subject}) => SharePlus.instance.share(ShareParams(text: text, subject: subject));

  static void shareFile(final List<String> file, final String text) => SharePlus.instance.share(ShareParams(text: text, files: file.map(XFile.new).toList()));
}
