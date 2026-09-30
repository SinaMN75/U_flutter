// Off the web these are never called; ULaunchChannel checks kIsWeb first.
abstract final class ULaunchWeb {
  static Future<bool> open(String url, String target) async => false;

  static Future<bool> canOpen(String url) async => false;

  static Future<Uri?> authenticate(String url, String callbackScheme, Duration timeout) async => null;
}
