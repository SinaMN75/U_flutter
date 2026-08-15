import "package:u/utilities.dart";

abstract class UOtp {
  static const List<List<int>> _d = <List<int>>[
    <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    <int>[1, 2, 3, 4, 0, 6, 7, 8, 9, 5],
    <int>[2, 3, 4, 0, 1, 7, 8, 9, 5, 6],
    <int>[3, 4, 0, 1, 2, 8, 9, 5, 6, 7],
    <int>[4, 0, 1, 2, 3, 9, 5, 6, 7, 8],
    <int>[5, 9, 8, 7, 6, 0, 4, 3, 2, 1],
    <int>[6, 5, 9, 8, 7, 1, 0, 4, 3, 2],
    <int>[7, 6, 5, 9, 8, 2, 1, 0, 4, 3],
    <int>[8, 7, 6, 5, 9, 3, 2, 1, 0, 4],
    <int>[9, 8, 7, 6, 5, 4, 3, 2, 1, 0],
  ];

  static const List<List<int>> _p = <List<int>>[
    <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    <int>[1, 5, 7, 6, 2, 8, 3, 0, 9, 4],
    <int>[5, 8, 0, 3, 7, 9, 6, 1, 4, 2],
    <int>[8, 9, 1, 6, 0, 4, 3, 5, 2, 7],
    <int>[9, 4, 5, 3, 1, 2, 6, 8, 7, 0],
    <int>[4, 2, 8, 6, 5, 7, 3, 9, 0, 1],
    <int>[2, 7, 9, 3, 8, 0, 6, 4, 1, 5],
    <int>[7, 0, 4, 6, 9, 1, 3, 2, 5, 8],
  ];

  static const List<int> _inv = <int>[0, 4, 3, 2, 1, 5, 6, 7, 8, 9];

  static String generateVerhoeff(String num) {
    int c = 0;
    final List<int> reversed = num.split("").reversed.map(int.parse).toList();
    for (int i = 0; i < reversed.length; i++) {
      c = _d[c][_p[(i + 1) % 8][reversed[i]]];
    }
    return _inv[c].toString();
  }

  static String _digitsOnly(String s) => s.split("").where((String ch) => RegExp(r"\d").hasMatch(ch)).join();

  static String _nowDate() {
    final DateTime now = DateTime.now();
    final String m = now.month.toString().padLeft(2, "0");
    final String d = now.day.toString().padLeft(2, "0");
    return "${now.year}$m$d";
  }

  static String _generate(String posSerial, int length, {required bool admin}) {
    final String serialNo = _digitsOnly(posSerial);
    final int max = pow(10, length - 3).toInt() - 1;
    final String randomString = Random().nextInt(max).toString().padLeft(length - 3, "0");
    final String nowDate = _nowDate();
    final String serialCD = generateVerhoeff(admin ? serialNo : "$randomString$serialNo");
    final String nowCD = generateVerhoeff("$randomString$nowDate");
    final String randomCD = generateVerhoeff(randomString);
    return "$randomString$serialCD$nowCD$randomCD";
  }

  static bool _verify(String posSerial, String otp, {required bool admin}) {
    final String serialNo = _digitsOnly(posSerial);
    final int rIndex = otp.length - 3;
    if (rIndex < 1) return false;
    final String randomString = otp.substring(0, rIndex);
    final String pinSerialCD = otp.substring(rIndex, rIndex + 1);
    final String pinNowCD = otp.substring(rIndex + 1, rIndex + 2);
    final String pinRandomCD = otp.substring(rIndex + 2);
    final String nowDate = _nowDate();
    final String serialCD = generateVerhoeff(admin ? serialNo : "$randomString$serialNo");
    final String nowCD = generateVerhoeff("$randomString$nowDate");
    final String randomCD = generateVerhoeff(randomString);
    return pinSerialCD == serialCD && pinRandomCD == randomCD && pinNowCD == nowCD;
  }

  static String generateOtp(String posSerial, int length) => _generate(posSerial, length, admin: false);

  static String generateAdminOtp(String posSerial, int length) => _generate(posSerial, length, admin: true);

  static bool verifyOtp(String posSerial, String otp) => _verify(posSerial, otp, admin: false);

  static bool verifyAdminOtp(String posSerial, String otp) => _verify(posSerial, otp, admin: true);
}
