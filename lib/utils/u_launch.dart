import "package:u/utilities.dart";

abstract class ULaunch {
  static Future<void> url(String url, {LaunchMode mode = LaunchMode.platformDefault}) async => launchUrl(
    Uri.parse(url),
    mode: mode,
    webOnlyWindowName: kIsWeb ? "_self" : null,
  );

  static Future<void> whatsApp(String number) async => url("https://api.whatsapp.com/send?phone=$number");

  static Future<void> map(double latitude, double longitude) async => url(
    Uri(scheme: "geo", queryParameters: <String, String>{"q": "$latitude,$longitude"}).toString(),
  );

  static Future<void> telegram(String id) async => url("https://t.me/$id");

  static Future<void> instagram(String username) async => url("https://instagram.com/$username");

  static Future<void> call(String phone) async => url("tel:$phone");

  static Future<void> sms(String phone, String body) async => url("sms:$phone?body=$body");

  static Future<void> shareWithTelegram(String param) async => url("tg://msg?text=$param");

  static Future<void> shareWithWhatsapp(String param) async => url("whatsapp://send?text=$param");

  static Future<void> shareWithEmail(String param) async => url("mailto:?body=$param");

  static void email(String email, String subject) => url(
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
