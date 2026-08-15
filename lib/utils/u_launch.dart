import "package:u/utilities.dart";

abstract class ULaunch {
  static Future<void> launchURL(String url, {LaunchMode mode = LaunchMode.platformDefault}) async => launchUrl(
    Uri.parse(url),
    mode: mode,
    webOnlyWindowName: kIsWeb ? "_self" : null,
  );

  static Future<void> launchWhatsApp(String number) async => launchURL("https://api.whatsapp.com/send?phone=$number");

  static Future<void> launchMap(double latitude, double longitude) async => launchURL(
    Uri(scheme: "geo", queryParameters: <String, String>{"q": "$latitude,$longitude"}).toString(),
  );

  static Future<void> launchTelegram(String id) async => launchURL("https://t.me/$id");

  static Future<void> launchInstagram(String username) async => launchURL("https://instagram.com/$username");

  static Future<void> call(String phone) async => launchURL("tel:$phone");

  static Future<void> sms(String phone, String body) async => launchURL("sms:$phone?body=$body");

  static Future<void> shareWithTelegram(String param) async => launchURL("tg://msg?text=$param");

  static Future<void> shareWithWhatsapp(String param) async => launchURL("whatsapp://send?text=$param");

  static Future<void> shareWithEmail(String param) async => launchURL("mailto:?body=$param");

  static void email(String email, String subject) => launchURL(
    Uri(
      scheme: "mailto",
      path: email,
      query: <String, String>{"subject": subject}.entries
          .map(
            (MapEntry<String, String> e) => "${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}",
          )
          .join("&"),
    ).toString(),
  );

  static void shareText(String text, {String? subject}) => SharePlus.instance.share(ShareParams(text: text, subject: subject));

  static void shareFile(List<String> file, String text) => SharePlus.instance.share(ShareParams(text: text, files: file.map(XFile.new).toList()));
}
