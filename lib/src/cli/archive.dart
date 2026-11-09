import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:u/src/cli/core.dart";
import "package:u/src/cli/image.dart";

/// Zips the contents of [dir] into [zipPath] (or [dir] itself as the top folder when [keepParent]).
/// Keeps Unix permissions and symlinks, so zipped Linux bundles still run after unzipping.
void zipFolder(String dir, String zipPath, {bool keepParent = false}) {
  final Directory root = Directory(dir);
  if (!root.existsSync()) {
    throw CliException("Folder not found: $dir");
  }
  final String base = keepParent ? root.parent.path : root.path;
  final List<FileSystemEntity> items = <FileSystemEntity>[if (keepParent) root, ...root.listSync(recursive: true, followLinks: false)]
    ..sort((FileSystemEntity a, FileSystemEntity b) => a.path.compareTo(b.path));
  final BytesBuilder body = BytesBuilder(copy: false);
  final BytesBuilder central = BytesBuilder(copy: false);
  int count = 0;
  for (final FileSystemEntity e in items) {
    String name = e.path.substring(base.length).replaceAll("\\", "/");
    while (name.startsWith("/")) {
      name = name.substring(1);
    }
    final FileStat stat = FileStat.statSync(e.path);
    final FileSystemEntityType type = FileSystemEntity.typeSync(e.path, followLinks: false);
    final int perm = Platform.isWindows ? (type == FileSystemEntityType.directory ? 0x1ED : 0x1A4) : stat.mode & 0xFFF;
    late final List<int> data;
    late final int mode;
    if (type == FileSystemEntityType.link) {
      data = utf8.encode(Link(e.path).targetSync());
      mode = 0xA000 | 0x1FF;
    } else if (type == FileSystemEntityType.directory) {
      name = "$name/";
      data = const <int>[];
      mode = 0x4000 | perm;
    } else {
      data = File(e.path).readAsBytesSync();
      mode = 0x8000 | perm;
    }
    final List<int> packed = data.isEmpty ? const <int>[] : ZLibEncoder(raw: true).convert(data);
    final bool deflate = packed.length < data.length;
    final List<int> stored = deflate ? packed : data;
    final List<int> nameBytes = utf8.encode(name);
    final int crc = crc32(data);
    final (int time, int date) = _dosTime(stat.modified);
    final int offset = body.length;
    if (offset > 0xFFFFFFFF || stored.length > 0xFFFFFFFF || count >= 0xFFFF) {
      throw CliException("$dir is too big for a zip file without ZIP64.");
    }
    final ByteData local = ByteData(30)
      ..setUint32(0, 0x04034b50, Endian.little)
      ..setUint16(4, 20, Endian.little)
      ..setUint16(6, 0x0800, Endian.little)
      ..setUint16(8, deflate ? 8 : 0, Endian.little)
      ..setUint16(10, time, Endian.little)
      ..setUint16(12, date, Endian.little)
      ..setUint32(14, crc, Endian.little)
      ..setUint32(18, stored.length, Endian.little)
      ..setUint32(22, data.length, Endian.little)
      ..setUint16(26, nameBytes.length, Endian.little);
    body
      ..add(local.buffer.asUint8List())
      ..add(nameBytes)
      ..add(stored);
    final ByteData entry = ByteData(46)
      ..setUint32(0, 0x02014b50, Endian.little)
      ..setUint16(4, 0x0314, Endian.little)
      ..setUint16(6, 20, Endian.little)
      ..setUint16(8, 0x0800, Endian.little)
      ..setUint16(10, deflate ? 8 : 0, Endian.little)
      ..setUint16(12, time, Endian.little)
      ..setUint16(14, date, Endian.little)
      ..setUint32(16, crc, Endian.little)
      ..setUint32(20, stored.length, Endian.little)
      ..setUint32(24, data.length, Endian.little)
      ..setUint16(28, nameBytes.length, Endian.little)
      ..setUint32(38, (mode << 16) | (type == FileSystemEntityType.directory ? 0x10 : 0), Endian.little)
      ..setUint32(42, offset, Endian.little);
    central
      ..add(entry.buffer.asUint8List())
      ..add(nameBytes);
    count++;
  }
  final int cdOffset = body.length;
  final int cdSize = central.length;
  final ByteData end = ByteData(22)
    ..setUint32(0, 0x06054b50, Endian.little)
    ..setUint16(8, count, Endian.little)
    ..setUint16(10, count, Endian.little)
    ..setUint32(12, cdSize, Endian.little)
    ..setUint32(16, cdOffset, Endian.little);
  final File out = File(zipPath);
  out.parent.createSync(recursive: true);
  out.writeAsBytesSync(
    (BytesBuilder(copy: false)
          ..add(body.takeBytes())
          ..add(central.takeBytes())
          ..add(end.buffer.asUint8List()))
        .takeBytes(),
  );
}

(int, int) _dosTime(DateTime t) {
  final DateTime d = t.year < 1980 ? DateTime(1980) : t;
  return ((d.hour << 11) | (d.minute << 5) | (d.second ~/ 2), ((d.year - 1980) << 9) | (d.month << 5) | d.day);
}
