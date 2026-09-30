import "package:u/src/share/u_share_channel.dart";

// Off the web these are never called; UShareChannel checks kIsWeb first.
abstract final class UShareWeb {
  static Future<UShareResult> share({String? text, String? subject, String? title, String? url, List<UShareFile> files = const <UShareFile>[]}) async => const UShareResult(UShareStatus.unavailable);

  static void listenLaunchQueue(void Function(UReceivedShare share) onShare) {}
}
