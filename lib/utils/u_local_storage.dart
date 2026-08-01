import "package:u/utilities.dart";

abstract class ULocalStorage {
  static late SharedPreferences _sp;

  static Future<void> init() async => _sp = await SharedPreferences.getInstance();

  static Set<String> getKeys() => _sp.getKeys();

  static void set(String key, dynamic value, {Duration? expireTime, (String, String)? encryptKeyIv}) {
    if (value is String) {
      _sp.setString(
        key,
        encryptKeyIv == null
            ? value
            : UEncryption.aesEncrypt(
                plainText: value,
                key: encryptKeyIv.$1,
                iv: encryptKeyIv.$2,
              ),
      );
    } else if (value is bool) {
      _sp.setBool(key, value);
    } else if (value is double) {
      _sp.setDouble(key, value);
    } else if (value is int) {
      _sp.setInt(key, value);
    } else if (value is List<String>) {
      _sp.setStringList(key, value);
    } else {
      throw ArgumentError("Unsupported value type for key: $key");
    }

    if (expireTime != null) {
      _sp.setInt("_expiry_$key", DateTime.now().add(expireTime).millisecondsSinceEpoch);
    }
  }

  static Future<void> setBatch(Map<String, dynamic> keyValuePairs) async {
    for (MapEntry<String, dynamic> entry in keyValuePairs.entries) {
      set(entry.key, entry.value);
    }
  }

  static int? getInt(String key) => getIfNotExpired(key);

  static String? getString(String key, {(String, String)? encryptKeyIv}) {
    final String? value = getIfNotExpired(key);
    if (value == null) return null;
    if (encryptKeyIv == null) return value;

    return UEncryption.aesDecrypt(
      base64Encrypted: value,
      key: encryptKeyIv.$1,
      iv: encryptKeyIv.$2,
    );
  }

  static bool? getBool(String key) => getIfNotExpired(key);

  static double? getDouble(String key) => getIfNotExpired(key);

  static List<String>? getStringList(String key) => getIfNotExpired(key);

  static void setToken(String value, {Duration? expireTime}) => set(UConstants.token, value, expireTime: expireTime);

  static void setRefreshToken(String value) => set(UConstants.refreshToken, value);

  static void setLocale(String value) => set(UConstants.locale, value);

  static void setDarkMode(bool isDarkMode) => set(UConstants.isDarkMode, isDarkMode);

  static void setUserId(String userId) => set(UConstants.userId, userId);

  static String? getToken() => getIfNotExpired(UConstants.token);

  static String? getRefreshToken() => getIfNotExpired(UConstants.refreshToken);

  static String? getLocale() => getIfNotExpired(UConstants.locale);

  static bool hasToken() => getIfNotExpired(UConstants.token) != null;

  static bool isDarkMode() => getIfNotExpired(UConstants.isDarkMode) ?? false;

  static String? getUserId() => getIfNotExpired(UConstants.userId);

  static bool containsKey(String key) => _sp.containsKey(key);

  static Future<void> remove(String key) async => _sp.remove(key);

  static Future<void> clear() async => _sp.clear();

  static Map<String, dynamic> getAll() {
    final Set<String> keys = getKeys();
    final Map<String, dynamic> data = <String, dynamic>{};
    for (String key in keys) {
      data[key] = _sp.get(key);
    }
    return data;
  }

  static dynamic getIfNotExpired(String key) {
    final String expiryKey = "_expiry_$key";
    final int? expiryTime = _sp.getInt(expiryKey);
    if (expiryTime != null && DateTime.now().millisecondsSinceEpoch > expiryTime) {
      remove(key);
      remove(expiryKey);
      return null;
    }
    return _sp.get(key);
  }
}

abstract class UFileStorage {
  static late Directory _directory;
  static late Directory _bigFilesDirectory;

  /// Initializes file storage directories.
  static Future<void> init() async {
    if (!kIsWeb) {
      _directory = await getApplicationDocumentsDirectory();
      _bigFilesDirectory = Directory("${_directory.path}/big_files");
      if (!await _bigFilesDirectory.exists()) {
        await _bigFilesDirectory.create(recursive: true);
      }
    }
  }

  static Future<void> setBytes(String key, List<int> bytes) async => File("${_bigFilesDirectory.path}/$key.dat").writeAsBytes(
    bytes,
    flush: true,
  );

  static Future<Uint8List?> getBytes(String key) async {
    final File file = File("${_bigFilesDirectory.path}/$key.dat");

    if (!await file.exists()) return null;

    final int size = file.lengthSync();
    final Uint8List output = Uint8List(size);

    final RandomAccessFile raf = file.openSync();
    int offset = 0;
    const int chunkSize = 1024 * 1024;

    while (offset < size) {
      final int remaining = size - offset;
      final int readSize = remaining < chunkSize ? remaining : chunkSize;

      final List<int> chunk = raf.readSync(readSize);
      if (chunk.isEmpty) break;

      output.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }

    raf.closeSync();
    return output;
  }

  static Uint8List? getBytesSync(String key) {
    final File file = File("${_bigFilesDirectory.path}/$key.dat");

    if (!file.existsSync()) return null;

    final int size = file.lengthSync();
    final Uint8List output = Uint8List(size);

    final RandomAccessFile raf = file.openSync();
    int offset = 0;
    const int chunkSize = 1024 * 1024;

    while (offset < size) {
      final int remaining = size - offset;
      final int readSize = remaining < chunkSize ? remaining : chunkSize;

      final List<int> chunk = raf.readSync(readSize);
      if (chunk.isEmpty) break;

      output.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }

    raf.closeSync();
    return output;
  }

  static Future<bool> fileExists(String key) async {
    try {
      final File file = File("${_bigFilesDirectory.path}/$key.dat");
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  static Future<int> fileSize(String key) async {
    try {
      final File file = File("${_bigFilesDirectory.path}/$key.dat");
      if (await file.exists()) {
        final FileStat stat = await file.stat();
        return stat.size;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  static int totalStorageUsed() {
    try {
      final List<FileSystemEntity> files = _bigFilesDirectory.listSync();
      int totalSize = 0;
      for (final FileSystemEntity file in files) {
        if (file is File && file.path.endsWith(".dat")) {
          final FileStat stat = file.statSync();
          totalSize += stat.size;
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  static Map<String, int> allFilesStorageInfo() {
    try {
      final List<FileSystemEntity> files = _bigFilesDirectory.listSync();
      final Map<String, int> storageInfo = <String, int>{};
      for (final FileSystemEntity file in files) {
        if (file is File && file.path.endsWith(".dat")) {
          final String fileName = file.uri.pathSegments.last;
          final String key = fileName.substring(0, fileName.length - 4); // Remove '.dat'
          final FileStat stat = file.statSync();
          storageInfo[key] = stat.size;
        }
      }
      return storageInfo;
    } catch (e) {
      return <String, int>{};
    }
  }

  static Future<void> remove(String key) async {
    try {
      final File datFile = File("${_bigFilesDirectory.path}/$key.dat");
      if (await datFile.exists()) {
        await datFile.delete();
      }
      final File txtFile = File("${_directory.path}/$key.txt");
      if (await txtFile.exists()) {
        await txtFile.delete();
      }
    } catch (e) {
      return;
    }
  }

  static Future<void> clear() async {
    try {
      final List<FileSystemEntity> files = _bigFilesDirectory.listSync();
      for (final FileSystemEntity file in files) {
        if (file is File) {
          await file.delete();
        }
      }
      final List<FileSystemEntity> legacyFiles = _directory.listSync();
      for (final FileSystemEntity file in legacyFiles) {
        if (file is File && file.path.endsWith(".txt")) {
          await file.delete();
        }
      }
    } catch (e) {
      return;
    }
  }

  static Future<void> set(String key, String value) async {
    try {
      await File("${_directory.path}/$key.txt").writeAsString(value);
    } catch (e) {
      return;
    }
  }

  static Future<String?> getString(String key) async {
    try {
      final File file = File("${_directory.path}/$key.txt");
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<String>> getKeys() async {
    try {
      final List<FileSystemEntity> files = _directory.listSync();
      return files.where((FileSystemEntity file) => file is File && file.path.endsWith(".txt")).map((FileSystemEntity file) {
        final String fileName = file.uri.pathSegments.last;
        return fileName.substring(0, fileName.length - 4);
      }).toList();
    } catch (e) {
      return <String>[];
    }
  }

  static Future<void> setJson(String key, Map<String, dynamic> jsonData) async {
    try {
      final String jsonString = jsonEncode(jsonData);
      await File("${_bigFilesDirectory.path}/$key.dat").writeAsString(jsonString);
    } catch (e) {
      return;
    }
  }

  static Future<Map<String, dynamic>?> getJson(String key) async {
    try {
      final File file = File("${_bigFilesDirectory.path}/$key.dat");
      if (await file.exists()) {
        final String jsonString = await file.readAsString();
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<String>> getDatKeys() async {
    try {
      final List<FileSystemEntity> files = _bigFilesDirectory.listSync();
      return files.where((FileSystemEntity file) => file is File && file.path.endsWith(".dat")).map((FileSystemEntity file) {
        final String fileName = file.uri.pathSegments.last;
        return fileName.substring(0, fileName.length - 4);
      }).toList();
    } catch (e) {
      return <String>[];
    }
  }

  static Future<List<String>> getDatPaths() async {
    try {
      return _bigFilesDirectory
          .listSync()
          .where((FileSystemEntity file) => file is File && file.path.endsWith(".dat"))
          .map(
            (FileSystemEntity file) => file.uri.pathSegments.last,
          )
          .toList();
    } catch (e) {
      return <String>[];
    }
  }

  static Future<void> copyFile(String sourceKey, String destinationKey) async {
    final File sourceFile = File("${_bigFilesDirectory.path}/$sourceKey.dat");
    if (await sourceFile.exists()) {
      await sourceFile.copy("${_bigFilesDirectory.path}/$destinationKey.dat");
    }
  }
}
