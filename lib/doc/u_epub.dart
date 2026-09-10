import "dart:ui" as ui;

import "package:u/utilities.dart";

abstract class UEpubDigest {
  static Uint8List sha1(List<int> message) {
    final List<int> padded = List<int>.from(message)..add(0x80);
    while (padded.length % 64 != 56) {
      padded.add(0);
    }
    final int bitLength = message.length * 8;
    for (int i = 7; i >= 0; i--) {
      padded.add((bitLength >>> (8 * i)) & 0xFF);
    }
    int h0 = 0x67452301;
    int h1 = 0xEFCDAB89;
    int h2 = 0x98BADCFE;
    int h3 = 0x10325476;
    int h4 = 0xC3D2E1F0;
    final List<int> words = List<int>.filled(80, 0);
    for (int chunk = 0; chunk < padded.length; chunk += 64) {
      for (int i = 0; i < 16; i++) {
        words[i] = (padded[chunk + i * 4] << 24) | (padded[chunk + i * 4 + 1] << 16) | (padded[chunk + i * 4 + 2] << 8) | padded[chunk + i * 4 + 3];
      }
      for (int i = 16; i < 80; i++) {
        final int value = words[i - 3] ^ words[i - 8] ^ words[i - 14] ^ words[i - 16];
        words[i] = ((value << 1) | (value >>> 31)) & 0xFFFFFFFF;
      }
      int a = h0;
      int b = h1;
      int c = h2;
      int d = h3;
      int e = h4;
      for (int i = 0; i < 80; i++) {
        int f;
        int k;
        if (i < 20) {
          f = (b & c) | (~b & d);
          k = 0x5A827999;
        } else if (i < 40) {
          f = b ^ c ^ d;
          k = 0x6ED9EBA1;
        } else if (i < 60) {
          f = (b & c) | (b & d) | (c & d);
          k = 0x8F1BBCDC;
        } else {
          f = b ^ c ^ d;
          k = 0xCA62C1D6;
        }
        final int temp = (((a << 5) | (a >>> 27)) + (f & 0xFFFFFFFF) + e + k + words[i]) & 0xFFFFFFFF;
        e = d;
        d = c;
        c = ((b << 30) | (b >>> 2)) & 0xFFFFFFFF;
        b = a;
        a = temp;
      }
      h0 = (h0 + a) & 0xFFFFFFFF;
      h1 = (h1 + b) & 0xFFFFFFFF;
      h2 = (h2 + c) & 0xFFFFFFFF;
      h3 = (h3 + d) & 0xFFFFFFFF;
      h4 = (h4 + e) & 0xFFFFFFFF;
    }
    final Uint8List out = Uint8List(20);
    final List<int> values = <int>[h0, h1, h2, h3, h4];
    for (int i = 0; i < 5; i++) {
      out[i * 4] = (values[i] >>> 24) & 0xFF;
      out[i * 4 + 1] = (values[i] >>> 16) & 0xFF;
      out[i * 4 + 2] = (values[i] >>> 8) & 0xFF;
      out[i * 4 + 3] = values[i] & 0xFF;
    }
    return out;
  }
}

class UEpubZipEntry {
  const UEpubZipEntry({required this.name, required this.method, required this.compressedSize, required this.size, required this.headerOffset});

  final String name;
  final int method;
  final int compressedSize;
  final int size;
  final int headerOffset;
}

class UEpubArchive {
  UEpubArchive._(this.source, this.entries);

  final UCachedByteSource source;
  final Map<String, UEpubZipEntry> entries;
  final ULruCache<String, Uint8List> _cache = ULruCache<String, Uint8List>(maxBytes: 12 * 1024 * 1024, sizeOf: _size);

  static int _size(Uint8List value) => value.length;

  static Future<UEpubArchive> open(UCachedByteSource source) async {
    final int length = source.length;
    if (length < 22) throw const UDocError(code: UDocErrorCode.corrupt, message: "Not a valid archive");
    final int tailLength = length < 66000 ? length : 66000;
    final Uint8List tail = await source.read(length - tailLength, tailLength);
    final UDocCursor cursor = UDocCursor(tail);
    final int eocd = cursor.lastIndexOf(const <int>[0x50, 0x4B, 0x05, 0x06]);
    if (eocd < 0) throw const UDocError(code: UDocErrorCode.corrupt, message: "Archive directory not found");
    int total = _readU16(tail, eocd + 10);
    int directorySize = _readU32(tail, eocd + 12);
    int directoryOffset = _readU32(tail, eocd + 16);
    final int locator = cursor.lastIndexOf(const <int>[0x50, 0x4B, 0x06, 0x07]);
    if (locator >= 0 && directoryOffset == 0xFFFFFFFF) {
      final int zip64Offset = _readU64(tail, locator + 8);
      if (zip64Offset >= 0 && zip64Offset < length) {
        final Uint8List header = await source.read(zip64Offset, 56);
        if (header.length >= 56 && header[0] == 0x50 && header[1] == 0x4B && header[2] == 0x06 && header[3] == 0x06) {
          total = _readU64(header, 32);
          directorySize = _readU64(header, 40);
          directoryOffset = _readU64(header, 48);
        }
      }
    }
    if (directoryOffset < 0 || directoryOffset >= length) throw const UDocError(code: UDocErrorCode.corrupt, message: "Archive directory is out of range");
    final int readSize = directorySize <= 0 || directoryOffset + directorySize > length ? length - directoryOffset : directorySize;
    final Uint8List directory = await source.read(directoryOffset, readSize);
    final Map<String, UEpubZipEntry> entries = <String, UEpubZipEntry>{};
    int position = 0;
    int count = 0;
    while (position + 46 <= directory.length && (total <= 0 || count < total + 8)) {
      if (!(directory[position] == 0x50 && directory[position + 1] == 0x4B && directory[position + 2] == 0x01 && directory[position + 3] == 0x02)) break;
      final int method = _readU16(directory, position + 10);
      int compressedSize = _readU32(directory, position + 20);
      int uncompressedSize = _readU32(directory, position + 24);
      final int nameLength = _readU16(directory, position + 28);
      final int extraLength = _readU16(directory, position + 30);
      final int commentLength = _readU16(directory, position + 32);
      int localOffset = _readU32(directory, position + 42);
      final int nameStart = position + 46;
      if (nameStart + nameLength > directory.length) break;
      final String name = utf8.decode(Uint8List.sublistView(directory, nameStart, nameStart + nameLength), allowMalformed: true);
      final int extraStart = nameStart + nameLength;
      if (compressedSize == 0xFFFFFFFF || uncompressedSize == 0xFFFFFFFF || localOffset == 0xFFFFFFFF) {
        int extraPosition = extraStart;
        while (extraPosition + 4 <= extraStart + extraLength && extraPosition + 4 <= directory.length) {
          final int headerId = _readU16(directory, extraPosition);
          final int size = _readU16(directory, extraPosition + 2);
          if (headerId == 0x0001) {
            int field = extraPosition + 4;
            if (uncompressedSize == 0xFFFFFFFF && field + 8 <= directory.length) {
              uncompressedSize = _readU64(directory, field);
              field += 8;
            }
            if (compressedSize == 0xFFFFFFFF && field + 8 <= directory.length) {
              compressedSize = _readU64(directory, field);
              field += 8;
            }
            if (localOffset == 0xFFFFFFFF && field + 8 <= directory.length) localOffset = _readU64(directory, field);
            break;
          }
          extraPosition += 4 + size;
        }
      }
      entries[name] = UEpubZipEntry(name: name, method: method, compressedSize: compressedSize, size: uncompressedSize, headerOffset: localOffset);
      position = extraStart + extraLength + commentLength;
      count++;
    }
    if (entries.isEmpty) throw const UDocError(code: UDocErrorCode.corrupt, message: "Archive has no entries");
    return UEpubArchive._(source, entries);
  }

  static int _readU16(Uint8List bytes, int offset) => offset + 1 < bytes.length ? bytes[offset] | (bytes[offset + 1] << 8) : 0;

  static int _readU32(Uint8List bytes, int offset) => offset + 3 < bytes.length ? bytes[offset] | (bytes[offset + 1] << 8) | (bytes[offset + 2] << 16) | (bytes[offset + 3] << 24) : 0;

  static int _readU64(Uint8List bytes, int offset) {
    if (offset + 7 >= bytes.length) return 0;
    final int low = _readU32(bytes, offset);
    final int high = _readU32(bytes, offset + 4);
    return low + high * 4294967296;
  }

  bool has(String name) => entries.containsKey(name);

  Future<Uint8List> read(String name) async {
    final Uint8List? cached = _cache.get(name);
    if (cached != null) return cached;
    final UEpubZipEntry? entry = entries[name];
    if (entry == null) return Uint8List(0);
    final Uint8List header = await source.read(entry.headerOffset, 30);
    if (header.length < 30) return Uint8List(0);
    final int nameLength = _readU16(header, 26);
    final int extraLength = _readU16(header, 28);
    final int dataOffset = entry.headerOffset + 30 + nameLength + extraLength;
    final int available = source.length - dataOffset;
    final int take = entry.compressedSize > 0 && entry.compressedSize <= available ? entry.compressedSize : available;
    if (take <= 0) return Uint8List(0);
    final Uint8List raw = await source.read(dataOffset, take);
    final Uint8List data = entry.method == 0 ? raw : UPdfCodecs.inflate(raw);
    if (data.length < 4 * 1024 * 1024) _cache.put(name, data);
    return data;
  }

  Future<String> readText(String name) async => UDocText.decodeBytes(await read(name));

  Future<void> close() async => source.close();
}

class UEpubResource {
  const UEpubResource({required this.id, required this.href, required this.mediaType, this.properties = ""});

  final String id;
  final String href;
  final String mediaType;
  final String properties;

  bool get isImage => mediaType.startsWith("image/");

  bool get isContent => mediaType.contains("xhtml") || mediaType.contains("html");

  bool get isStyle => mediaType.contains("css");

  bool get isFont => mediaType.contains("font") || href.toLowerCase().endsWith(".ttf") || href.toLowerCase().endsWith(".otf") || href.toLowerCase().endsWith(".woff");
}

class UEpubSpineItem {
  const UEpubSpineItem({required this.idref, required this.href, this.linear = true, this.properties = ""});

  final String idref;
  final String href;
  final bool linear;
  final String properties;
}

class UEpubBook {
  UEpubBook._(this.archive, this.fingerprint);

  final UEpubArchive archive;
  final String fingerprint;

  final Map<String, UEpubResource> resources = <String, UEpubResource>{};
  final Map<String, UEpubResource> resourcesByHref = <String, UEpubResource>{};
  final List<UEpubSpineItem> spine = <UEpubSpineItem>[];
  final List<UDocOutlineNode> navigation = <UDocOutlineNode>[];
  final Map<String, String> obfuscatedFonts = <String, String>{};

  UDocMetadata metadata = const UDocMetadata();
  UDocDirection direction = UDocDirection.ltr;
  String opfPath = "";
  String opfDirectory = "";
  String? coverHref;
  bool fixedLayout = false;

  int get chapterCount => spine.length;

  static Future<UEpubBook> open({String? path, String? url, Uint8List? bytes, String? asset, Object? blob, Map<String, String>? headers}) async {
    final UCachedByteSource source = await UDocSources.open(path: path, url: url, bytes: bytes, asset: asset, blob: blob, headers: headers);
    final String fingerprint = await UDocSources.fingerprint(source);
    final UEpubArchive archive = await UEpubArchive.open(source);
    final UEpubBook book = UEpubBook._(archive, fingerprint);
    await book._load();
    return book;
  }

  Future<void> _load() async {
    final String container = await archive.readText("META-INF/container.xml");
    final UEpubNode? containerRoot = UEpubXml.parse(container);
    String rootPath = "";
    if (containerRoot != null) {
      for (final UEpubNode node in containerRoot.findAll("rootfile")) {
        final String? fullPath = node.attributes["full-path"];
        if (fullPath != null && fullPath.isNotEmpty) {
          rootPath = fullPath;
          break;
        }
      }
    }
    if (rootPath.isEmpty) {
      for (final String name in archive.entries.keys) {
        if (name.toLowerCase().endsWith(".opf")) {
          rootPath = name;
          break;
        }
      }
    }
    if (rootPath.isEmpty) throw const UDocError(code: UDocErrorCode.corrupt, message: "Book package not found");
    opfPath = rootPath;
    opfDirectory = rootPath.contains("/") ? rootPath.substring(0, rootPath.lastIndexOf("/") + 1) : "";
    final UEpubNode? package = UEpubXml.parse(await archive.readText(rootPath));
    if (package == null) throw const UDocError(code: UDocErrorCode.corrupt, message: "Book package is unreadable");
    _readMetadata(package);
    _readManifest(package);
    _readSpine(package);
    await _readNavigation(package);
    await _readEncryption();
  }

  void _readMetadata(UEpubNode package) {
    String? first(String tag) {
      for (final UEpubNode node in package.findAll(tag)) {
        final String text = node.textContent.trim();
        if (text.isNotEmpty) return text;
      }
      return null;
    }

    String? series;
    double? seriesIndex;
    for (final UEpubNode meta in package.findAll("meta")) {
      final String name = meta.attributes["name"] ?? "";
      final String property = meta.attributes["property"] ?? "";
      if (name == "calibre:series") series = meta.attributes["content"];
      if (name == "calibre:series_index") seriesIndex = double.tryParse(meta.attributes["content"] ?? "");
      if (name == "cover") {
        final String? id = meta.attributes["content"];
        if (id != null) coverHref = resources[id]?.href;
      }
      if (property == "rendition:layout" && meta.textContent.trim() == "pre-paginated") fixedLayout = true;
    }
    metadata = UDocMetadata(
      title: first("title"),
      author: first("creator"),
      subject: first("subject"),
      publisher: first("publisher"),
      language: first("language"),
      identifier: first("identifier"),
      series: series,
      seriesIndex: seriesIndex,
      creationDate: DateTime.tryParse(first("date") ?? ""),
      pageCount: spine.length,
    );
  }

  void _readManifest(UEpubNode package) {
    for (final UEpubNode item in package.findAll("item")) {
      final String id = item.attributes["id"] ?? "";
      final String href = item.attributes["href"] ?? "";
      if (id.isEmpty || href.isEmpty) continue;
      final UEpubResource resource = UEpubResource(
        id: id,
        href: resolve(href),
        mediaType: item.attributes["media-type"] ?? "",
        properties: item.attributes["properties"] ?? "",
      );
      resources[id] = resource;
      resourcesByHref[resource.href] = resource;
      if (resource.properties.contains("cover-image")) coverHref = resource.href;
    }
    if (coverHref == null) {
      for (final UEpubResource resource in resources.values) {
        if (resource.isImage && resource.href.toLowerCase().contains("cover")) {
          coverHref = resource.href;
          break;
        }
      }
    }
  }

  void _readSpine(UEpubNode package) {
    for (final UEpubNode node in package.findAll("spine")) {
      final String progression = node.attributes["page-progression-direction"] ?? "";
      if (progression == "rtl") direction = UDocDirection.rtl;
      for (final UEpubNode item in node.findAll("itemref")) {
        final String idref = item.attributes["idref"] ?? "";
        final UEpubResource? resource = resources[idref];
        if (resource == null) continue;
        spine.add(UEpubSpineItem(idref: idref, href: resource.href, linear: (item.attributes["linear"] ?? "yes") != "no", properties: item.attributes["properties"] ?? ""));
      }
      break;
    }
    if (spine.isEmpty) {
      for (final UEpubResource resource in resources.values) {
        if (resource.isContent) spine.add(UEpubSpineItem(idref: resource.id, href: resource.href));
      }
    }
    final String? language = metadata.language;
    if (language != null && direction == UDocDirection.ltr) {
      final String lower = language.toLowerCase();
      if (lower.startsWith("fa") || lower.startsWith("ar") || lower.startsWith("he") || lower.startsWith("ur")) direction = UDocDirection.rtl;
    }
    metadata = metadata.copyWith(pageCount: spine.length);
  }

  Future<void> _readNavigation(UEpubNode package) async {
    UEpubResource? nav;
    for (final UEpubResource resource in resources.values) {
      if (resource.properties.contains("nav")) {
        nav = resource;
        break;
      }
    }
    if (nav != null) {
      final UEpubNode? document = UEpubXml.parse(await archive.readText(nav.href));
      if (document != null) {
        for (final UEpubNode element in document.findAll("nav")) {
          final String type = element.attributes["epub:type"] ?? element.attributes["type"] ?? "";
          if (type.isNotEmpty && !type.contains("toc")) continue;
          navigation.addAll(_navFromList(element, nav.href, 0));
          if (navigation.isNotEmpty) return;
        }
      }
    }
    UEpubResource? ncx;
    for (final UEpubResource resource in resources.values) {
      if (resource.mediaType.contains("ncx") || resource.href.toLowerCase().endsWith(".ncx")) {
        ncx = resource;
        break;
      }
    }
    if (ncx == null) return;
    final UEpubNode? document = UEpubXml.parse(await archive.readText(ncx.href));
    if (document == null) return;
    for (final UEpubNode map in document.findAll("navMap")) {
      navigation.addAll(_navFromNcx(map, ncx.href, 0));
      break;
    }
  }

  List<UDocOutlineNode> _navFromList(UEpubNode element, String baseHref, int depth) {
    if (depth > 8) return const <UDocOutlineNode>[];
    final List<UDocOutlineNode> out = <UDocOutlineNode>[];
    for (final UEpubNode list in element.children.where((UEpubNode node) => node.tag == "ol" || node.tag == "ul")) {
      for (final UEpubNode item in list.children.where((UEpubNode node) => node.tag == "li")) {
        String title = "";
        String? href;
        for (final UEpubNode anchor in item.findAll("a")) {
          title = anchor.textContent.trim();
          href = anchor.attributes["href"];
          break;
        }
        if (title.isEmpty) title = item.textContent.trim();
        final List<UDocOutlineNode> children = _navFromList(item, baseHref, depth + 1);
        final int index = href == null ? -1 : spineIndexFor(_relative(baseHref, href));
        out.add(
          UDocOutlineNode(
            title: title,
            destination: index < 0 ? null : UDocDestination(pageIndex: index, anchor: _anchorOf(href)),
            children: children,
          ),
        );
      }
    }
    return out;
  }

  List<UDocOutlineNode> _navFromNcx(UEpubNode element, String baseHref, int depth) {
    if (depth > 8) return const <UDocOutlineNode>[];
    final List<UDocOutlineNode> out = <UDocOutlineNode>[];
    for (final UEpubNode point in element.children.where((UEpubNode node) => node.tag == "navpoint")) {
      String title = "";
      String? href;
      for (final UEpubNode label in point.findAll("navlabel")) {
        title = label.textContent.trim();
        break;
      }
      for (final UEpubNode content in point.findAll("content")) {
        href = content.attributes["src"];
        break;
      }
      final int index = href == null ? -1 : spineIndexFor(_relative(baseHref, href));
      out.add(
        UDocOutlineNode(
          title: title,
          destination: index < 0 ? null : UDocDestination(pageIndex: index, anchor: _anchorOf(href)),
          children: _navFromNcx(point, baseHref, depth + 1),
        ),
      );
    }
    return out;
  }

  String? _anchorOf(String? href) {
    if (href == null) return null;
    final int hash = href.indexOf("#");
    return hash < 0 ? null : href.substring(hash + 1);
  }

  Future<void> _readEncryption() async {
    if (!archive.has("META-INF/encryption.xml")) return;
    final UEpubNode? document = UEpubXml.parse(await archive.readText("META-INF/encryption.xml"));
    if (document == null) return;
    for (final UEpubNode data in document.findAll("encrypteddata")) {
      String algorithm = "";
      String target = "";
      for (final UEpubNode method in data.findAll("encryptionmethod")) {
        algorithm = method.attributes["algorithm"] ?? "";
        break;
      }
      for (final UEpubNode reference in data.findAll("cipherreference")) {
        target = reference.attributes["uri"] ?? "";
        break;
      }
      if (target.isEmpty) continue;
      obfuscatedFonts[Uri.decodeFull(target)] = algorithm;
    }
  }

  String resolve(String href) {
    final String cleaned = href.split("#").first;
    if (cleaned.startsWith("/")) return cleaned.substring(1);
    return _normalize("$opfDirectory$cleaned");
  }

  String _relative(String baseHref, String href) {
    final String cleaned = href.split("#").first;
    if (cleaned.startsWith("/")) return cleaned.substring(1);
    final String directory = baseHref.contains("/") ? baseHref.substring(0, baseHref.lastIndexOf("/") + 1) : "";
    return _normalize("$directory$cleaned");
  }

  static String _normalize(String path) {
    final List<String> parts = <String>[];
    for (final String segment in path.split("/")) {
      if (segment.isEmpty || segment == ".") continue;
      if (segment == "..") {
        if (parts.isNotEmpty) parts.removeLast();
        continue;
      }
      parts.add(segment);
    }
    return parts.join("/");
  }

  int spineIndexFor(String href) {
    final String target = _normalize(href.split("#").first);
    for (int i = 0; i < spine.length; i++) {
      if (spine[i].href == target) return i;
    }
    return -1;
  }

  Future<Uint8List> resource(String href) async {
    final String path = _normalize(href.split("#").first);
    final Uint8List data = await archive.read(path);
    final String? algorithm = obfuscatedFonts[path];
    if (algorithm == null || data.isEmpty) return data;
    return _deobfuscate(data, algorithm);
  }

  Uint8List _deobfuscate(Uint8List data, String algorithm) {
    final String identifier = metadata.identifier ?? "";
    if (identifier.isEmpty) return data;
    final bool adobe = algorithm.contains("adobe");
    final Uint8List key = adobe ? _adobeKey(identifier) : UEpubDigest.sha1(utf8.encode(identifier.trim()));
    if (key.isEmpty) return data;
    final int length = adobe ? 1024 : 1040;
    final Uint8List out = Uint8List.fromList(data);
    for (int i = 0; i < length && i < out.length; i++) {
      out[i] = out[i] ^ key[i % key.length];
    }
    return out;
  }

  Uint8List _adobeKey(String identifier) {
    String uuid = identifier;
    final int index = uuid.toLowerCase().indexOf("urn:uuid:");
    if (index >= 0) uuid = uuid.substring(index + 9);
    uuid = uuid.replaceAll("-", "").trim();
    final List<int> bytes = <int>[];
    for (int i = 0; i + 1 < uuid.length && bytes.length < 16; i += 2) {
      final int? value = int.tryParse(uuid.substring(i, i + 2), radix: 16);
      if (value == null) return Uint8List(0);
      bytes.add(value);
    }
    return Uint8List.fromList(bytes);
  }

  Future<UEpubChapter> chapter(int index) async {
    if (index < 0 || index >= spine.length) return UEpubChapter(spineIndex: index, href: "", blocks: const <UEpubBlock>[], title: "", text: "");
    final UEpubSpineItem item = spine[index];
    final String html = UDocText.decodeBytes(await resource(item.href));
    final UEpubNode? document = UEpubXml.parse(html);
    if (document == null) return UEpubChapter(spineIndex: index, href: item.href, blocks: const <UEpubBlock>[], title: "", text: "");
    final UEpubStyleSheet sheet = UEpubStyleSheet();
    for (final UEpubNode link in document.findAll("link")) {
      final String rel = (link.attributes["rel"] ?? "").toLowerCase();
      final String href = link.attributes["href"] ?? "";
      if (!rel.contains("stylesheet") || href.isEmpty) continue;
      sheet.parse(UDocText.decodeBytes(await resource(_relative(item.href, href))));
    }
    for (final UEpubNode style in document.findAll("style")) {
      sheet.parse(style.textContent);
    }
    final UEpubBlockBuilder builder = UEpubBlockBuilder(sheet: sheet, baseHref: item.href, book: this);
    UEpubNode body = document;
    for (final UEpubNode node in document.findAll("body")) {
      body = node;
      break;
    }
    builder.walk(body);
    return UEpubChapter(spineIndex: index, href: item.href, blocks: builder.blocks, title: builder.title, text: builder.plainText);
  }

  Future<void> close() async => archive.close();
}

class UEpubNode {
  UEpubNode({required this.tag, Map<String, String>? attributes, this.text = ""}) : attributes = attributes ?? <String, String>{}, children = <UEpubNode>[];

  final String tag;
  final Map<String, String> attributes;
  final List<UEpubNode> children;
  final String text;

  UEpubNode? parent;

  bool get isText => tag == "#text";

  String get id => attributes["id"] ?? "";

  List<String> get classes => (attributes["class"] ?? "").split(RegExp(r"\s+")).where((String value) => value.isNotEmpty).toList();

  String get textContent {
    if (isText) return text;
    final StringBuffer buffer = StringBuffer();
    for (final UEpubNode child in children) {
      buffer.write(child.textContent);
    }
    return buffer.toString();
  }

  Iterable<UEpubNode> findAll(String tag, {int depth = 0}) sync* {
    if (depth > 64) return;
    for (final UEpubNode child in children) {
      if (child.tag == tag) yield child;
      yield* child.findAll(tag, depth: depth + 1);
    }
  }
}

abstract class UEpubXml {
  static const Set<String> _void = <String>{"area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "param", "source", "track", "wbr"};

  static UEpubNode? parse(String source) {
    if (source.trim().isEmpty) return null;
    final UEpubNode root = UEpubNode(tag: "#root");
    final List<UEpubNode> stack = <UEpubNode>[root];
    int index = 0;
    int guard = 0;
    while (index < source.length && guard < 2000000) {
      guard++;
      final int open = source.indexOf("<", index);
      if (open < 0) {
        _addText(stack.last, source.substring(index));
        break;
      }
      if (open > index) _addText(stack.last, source.substring(index, open));
      if (source.startsWith("<!--", open)) {
        final int end = source.indexOf("-->", open);
        index = end < 0 ? source.length : end + 3;
        continue;
      }
      if (source.startsWith("<![CDATA[", open)) {
        final int end = source.indexOf("]]>", open);
        final int stop = end < 0 ? source.length : end;
        _addText(stack.last, source.substring(open + 9, stop));
        index = end < 0 ? source.length : end + 3;
        continue;
      }
      if (source.startsWith("<!", open) || source.startsWith("<?", open)) {
        final int end = source.indexOf(">", open);
        index = end < 0 ? source.length : end + 1;
        continue;
      }
      final int close = _findTagEnd(source, open);
      if (close < 0) {
        _addText(stack.last, source.substring(open));
        break;
      }
      final String raw = source.substring(open + 1, close).trim();
      index = close + 1;
      if (raw.isEmpty) continue;
      if (raw.startsWith("/")) {
        final String name = _localName(raw.substring(1).trim());
        for (int i = stack.length - 1; i > 0; i--) {
          if (stack[i].tag == name) {
            stack.removeRange(i, stack.length);
            break;
          }
        }
        continue;
      }
      final bool selfClosing = raw.endsWith("/");
      final String body = selfClosing ? raw.substring(0, raw.length - 1) : raw;
      final int space = body.indexOf(RegExp(r"\s"));
      final String name = _localName(space < 0 ? body : body.substring(0, space));
      final Map<String, String> attributes = space < 0 ? <String, String>{} : _attributes(body.substring(space + 1));
      final UEpubNode node = UEpubNode(tag: name, attributes: attributes);
      node.parent = stack.last;
      stack.last.children.add(node);
      if (!selfClosing && !_void.contains(name)) stack.add(node);
      if (stack.length > 200) stack.removeRange(1, stack.length - 100);
    }
    return root;
  }

  static String _localName(String raw) {
    final String lower = raw.trim().toLowerCase();
    final int colon = lower.lastIndexOf(":");
    return colon < 0 ? lower : lower.substring(colon + 1);
  }

  static int _findTagEnd(String source, int open) {
    bool inSingle = false;
    bool inDouble = false;
    for (int i = open + 1; i < source.length; i++) {
      final String character = source[i];
      if (character == "'" && !inDouble) inSingle = !inSingle;
      if (character == "\"" && !inSingle) inDouble = !inDouble;
      if (character == ">" && !inSingle && !inDouble) return i;
    }
    return -1;
  }

  static void _addText(UEpubNode parent, String raw) {
    if (raw.isEmpty) return;
    final String decoded = decodeEntities(raw);
    if (decoded.isEmpty) return;
    final UEpubNode node = UEpubNode(tag: "#text", text: decoded);
    node.parent = parent;
    parent.children.add(node);
  }

  static Map<String, String> _attributes(String source) {
    final Map<String, String> out = <String, String>{};
    final RegExp pattern = RegExp("([:A-Za-z_][-:A-Za-z0-9_.]*)\\s*(?:=\\s*(\"[^\"]*\"|'[^']*'|[^\\s>]+))?");
    for (final RegExpMatch match in pattern.allMatches(source)) {
      final String key = (match.group(1) ?? "").toLowerCase();
      if (key.isEmpty) continue;
      String value = match.group(2) ?? "";
      if (value.length >= 2 && (value.startsWith("\"") || value.startsWith("'"))) value = value.substring(1, value.length - 1);
      out[key] = decodeEntities(value);
    }
    return out;
  }

  static const Map<String, String> _entities = <String, String>{
    "amp": "&",
    "lt": "<",
    "gt": ">",
    "quot": "\"",
    "apos": "'",
    "nbsp": "\u00A0",
    "mdash": "\u2014",
    "ndash": "\u2013",
    "hellip": "\u2026",
    "rsquo": "\u2019",
    "lsquo": "\u2018",
    "ldquo": "\u201C",
    "rdquo": "\u201D",
    "laquo": "\u00AB",
    "raquo": "\u00BB",
    "copy": "\u00A9",
    "reg": "\u00AE",
    "trade": "\u2122",
    "deg": "\u00B0",
    "middot": "\u00B7",
    "bull": "\u2022",
    "shy": "",
    "zwnj": "\u200C",
    "zwj": "\u200D",
  };

  static String decodeEntities(String source) {
    if (!source.contains("&")) return source;
    return source.replaceAllMapped(RegExp("&(#x?[0-9A-Fa-f]+|[A-Za-z]+);"), (Match match) {
      final String token = match.group(1) ?? "";
      if (token.startsWith("#x") || token.startsWith("#X")) {
        final int? code = int.tryParse(token.substring(2), radix: 16);
        return code == null ? match.group(0) ?? "" : String.fromCharCode(code);
      }
      if (token.startsWith("#")) {
        final int? code = int.tryParse(token.substring(1));
        return code == null ? match.group(0) ?? "" : String.fromCharCode(code);
      }
      return _entities[token.toLowerCase()] ?? match.group(0) ?? "";
    });
  }
}

class UEpubRule {
  const UEpubRule(this.selector, this.declarations, this.specificity);

  final List<UEpubSelectorPart> selector;
  final Map<String, String> declarations;
  final int specificity;
}

class UEpubSelectorPart {
  const UEpubSelectorPart({this.tag = "", this.className = "", this.id = ""});

  final String tag;
  final String className;
  final String id;

  bool matches(UEpubNode node) {
    if (tag.isNotEmpty && tag != "*" && node.tag != tag) return false;
    if (id.isNotEmpty && node.id != id) return false;
    if (className.isNotEmpty && !node.classes.contains(className)) return false;
    return true;
  }
}

class UEpubStyleSheet {
  final List<UEpubRule> rules = <UEpubRule>[];
  final Map<String, Map<String, String>> fontFaces = <String, Map<String, String>>{};

  void parse(String source) {
    if (source.trim().isEmpty) return;
    final String cleaned = source.replaceAll(RegExp(r"/\*.*?\*/", dotAll: true), "");
    int index = 0;
    int guard = 0;
    while (index < cleaned.length && guard < 20000) {
      guard++;
      final int brace = cleaned.indexOf("{", index);
      if (brace < 0) break;
      final int end = cleaned.indexOf("}", brace);
      if (end < 0) break;
      final String selectorText = cleaned.substring(index, brace).trim();
      final String body = cleaned.substring(brace + 1, end);
      index = end + 1;
      if (selectorText.startsWith("@")) {
        if (selectorText.toLowerCase().startsWith("@font-face")) {
          final Map<String, String> declarations = _declarations(body);
          final String family = (declarations["font-family"] ?? "").replaceAll("\"", "").replaceAll("'", "").trim();
          if (family.isNotEmpty) fontFaces[family.toLowerCase()] = declarations;
        }
        continue;
      }
      final Map<String, String> declarations = _declarations(body);
      if (declarations.isEmpty) continue;
      for (final String selector in selectorText.split(",")) {
        final List<UEpubSelectorPart> parts = <UEpubSelectorPart>[];
        int specificity = 0;
        for (final String piece in selector.trim().split(RegExp(r"\s+"))) {
          if (piece.isEmpty || piece == ">" || piece == "+" || piece == "~") continue;
          final String withoutPseudo = piece.split(":").first;
          final RegExpMatch? match = RegExp(r"^([A-Za-z][A-Za-z0-9]*|\*)?(?:#([-\w]+))?(?:\.([-\w]+))?").firstMatch(withoutPseudo);
          if (match == null) continue;
          final String tag = (match.group(1) ?? "").toLowerCase();
          final String id = match.group(2) ?? "";
          final String className = match.group(3) ?? "";
          if (tag.isEmpty && id.isEmpty && className.isEmpty) continue;
          if (id.isNotEmpty) specificity += 100;
          if (className.isNotEmpty) specificity += 10;
          if (tag.isNotEmpty && tag != "*") specificity += 1;
          parts.add(UEpubSelectorPart(tag: tag, className: className, id: id));
        }
        if (parts.isEmpty) continue;
        rules.add(UEpubRule(parts, declarations, specificity));
      }
    }
  }

  Map<String, String> _declarations(String body) {
    final Map<String, String> out = <String, String>{};
    for (final String piece in body.split(";")) {
      final int colon = piece.indexOf(":");
      if (colon <= 0) continue;
      final String key = piece.substring(0, colon).trim().toLowerCase();
      final String value = piece.substring(colon + 1).trim();
      if (key.isEmpty || value.isEmpty) continue;
      out[key] = value;
    }
    return out;
  }

  Map<String, String> declarationsFor(List<UEpubNode> chain) {
    if (chain.isEmpty) return const <String, String>{};
    final List<UEpubRule> matched = <UEpubRule>[];
    for (final UEpubRule rule in rules) {
      if (_matches(rule.selector, chain)) matched.add(rule);
    }
    matched.sort((UEpubRule a, UEpubRule b) => a.specificity.compareTo(b.specificity));
    final Map<String, String> out = <String, String>{};
    for (final UEpubRule rule in matched) {
      out.addAll(rule.declarations);
    }
    final String? inline = chain.last.attributes["style"];
    if (inline != null && inline.isNotEmpty) out.addAll(_declarations(inline));
    return out;
  }

  bool _matches(List<UEpubSelectorPart> parts, List<UEpubNode> chain) {
    if (!parts.last.matches(chain.last)) return false;
    int partIndex = parts.length - 2;
    int nodeIndex = chain.length - 2;
    while (partIndex >= 0) {
      bool found = false;
      while (nodeIndex >= 0) {
        if (parts[partIndex].matches(chain[nodeIndex])) {
          found = true;
          nodeIndex--;
          break;
        }
        nodeIndex--;
      }
      if (!found) return false;
      partIndex--;
    }
    return true;
  }
}

enum UEpubBlockKind { paragraph, heading, image, rule, listItem, blockquote, preformatted, tableRow, pageBreak }

class UEpubSpan {
  const UEpubSpan({
    required this.text,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.monospace = false,
    this.superscript = false,
    this.subscript = false,
    this.color,
    this.background,
    this.sizeFactor = 1,
    this.href,
    this.anchorId,
    this.fontFamily,
  });

  final String text;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final bool monospace;
  final bool superscript;
  final bool subscript;
  final Color? color;
  final Color? background;
  final double sizeFactor;
  final String? href;
  final String? anchorId;
  final String? fontFamily;
}

class UEpubBlock {
  const UEpubBlock({
    required this.kind,
    this.spans = const <UEpubSpan>[],
    this.imageHref,
    this.level = 0,
    this.align,
    this.indent = 0,
    this.marginTop = 0,
    this.marginBottom = 0,
    this.listMarker = "",
    this.anchorId,
    this.rtl = false,
    this.cells = const <List<UEpubSpan>>[],
  });

  final UEpubBlockKind kind;
  final List<UEpubSpan> spans;
  final String? imageHref;
  final int level;
  final TextAlign? align;
  final double indent;
  final double marginTop;
  final double marginBottom;
  final String listMarker;
  final String? anchorId;
  final bool rtl;
  final List<List<UEpubSpan>> cells;

  String get text {
    final StringBuffer buffer = StringBuffer();
    for (final UEpubSpan span in spans) {
      buffer.write(span.text);
    }
    return buffer.toString();
  }

  bool get isEmpty => spans.isEmpty && imageHref == null && cells.isEmpty && kind != UEpubBlockKind.rule && kind != UEpubBlockKind.pageBreak;
}

class UEpubChapter {
  const UEpubChapter({required this.spineIndex, required this.href, required this.blocks, required this.title, required this.text});

  final int spineIndex;
  final String href;
  final List<UEpubBlock> blocks;
  final String title;
  final String text;

  bool get isEmpty => blocks.isEmpty;

  int anchorBlock(String anchor) {
    for (int i = 0; i < blocks.length; i++) {
      if (blocks[i].anchorId == anchor) return i;
    }
    return -1;
  }
}

class UEpubBlockBuilder {
  UEpubBlockBuilder({required this.sheet, required this.baseHref, required this.book});

  final UEpubStyleSheet sheet;
  final String baseHref;
  final UEpubBook book;

  final List<UEpubBlock> blocks = <UEpubBlock>[];
  final List<UEpubSpan> _inline = <UEpubSpan>[];
  final StringBuffer _plain = StringBuffer();
  final List<UEpubNode> _chain = <UEpubNode>[];
  final List<String> _listStack = <String>[];
  final List<int> _listCounters = <int>[];

  String title = "";
  final List<List<UEpubSpan>> _row = <List<UEpubSpan>>[];
  bool _inCell = false;
  bool _inRow = false;
  String? _pendingAnchor;
  TextAlign? _pendingAlign;
  double _pendingIndent = 0;
  int _pendingLevel = 0;
  UEpubBlockKind _pendingKind = UEpubBlockKind.paragraph;
  bool _rtl = false;

  String get plainText => _plain.toString();

  static const Set<String> _blockTags = <String>{
    "p",
    "div",
    "section",
    "article",
    "header",
    "footer",
    "aside",
    "nav",
    "main",
    "figure",
    "figcaption",
    "h1",
    "h2",
    "h3",
    "h4",
    "h5",
    "h6",
    "blockquote",
    "pre",
    "ul",
    "ol",
    "li",
    "table",
    "tr",
    "td",
    "th",
    "hr",
    "br",
    "body",
    "html",
    "dl",
    "dt",
    "dd",
    "center",
  };

  static const Set<String> _skipTags = <String>{"script", "style", "head", "title", "meta", "link", "svg", "audio", "video", "iframe"};

  void walk(UEpubNode node) {
    _visit(node, 0);
    _flush();
  }

  void _visit(UEpubNode node, int depth) {
    if (depth > 96) return;
    if (_skipTags.contains(node.tag)) return;
    if (node.isText) {
      _appendText(node.text);
      return;
    }
    _chain.add(node);
    final Map<String, String> declarations = sheet.declarationsFor(_chain);
    final String display = (declarations["display"] ?? "").toLowerCase();
    if (display == "none") {
      _chain.removeLast();
      return;
    }
    final String direction = (declarations["direction"] ?? node.attributes["dir"] ?? "").toLowerCase();
    final bool previousRtl = _rtl;
    if (direction == "rtl") _rtl = true;
    if (direction == "ltr") _rtl = false;

    final bool isBlock = _blockTags.contains(node.tag) || display == "block" || display == "list-item";
    if (isBlock) _flush();

    switch (node.tag) {
      case "br":
        _appendText("\n");
        break;
      case "hr":
        blocks.add(const UEpubBlock(kind: UEpubBlockKind.rule, marginTop: 12, marginBottom: 12));
        break;
      case "img":
      case "image":
        {
          final String href = node.attributes["src"] ?? node.attributes["xlink:href"] ?? node.attributes["href"] ?? "";
          if (href.isNotEmpty) {
            blocks.add(UEpubBlock(kind: UEpubBlockKind.image, imageHref: _resolve(href), anchorId: node.id.isEmpty ? null : node.id, marginTop: 8, marginBottom: 8));
          }
          final String alt = node.attributes["alt"] ?? "";
          if (alt.isNotEmpty) _plain.writeln(alt);
        }
        break;
      case "ul":
      case "ol":
        _listStack.add(node.tag);
        _listCounters.add(0);
        break;
      case "tr":
        _flush();
        _row.clear();
        _inRow = true;
        break;
      case "td":
      case "th":
        _flush();
        _inCell = true;
        break;
      case "li":
        if (_listStack.isNotEmpty) {
          _listCounters[_listCounters.length - 1]++;
          _pendingKind = UEpubBlockKind.listItem;
        }
        break;
      case "h1":
      case "h2":
      case "h3":
      case "h4":
      case "h5":
      case "h6":
        _pendingKind = UEpubBlockKind.heading;
        _pendingLevel = int.tryParse(node.tag.substring(1)) ?? 1;
        break;
      case "blockquote":
        _pendingKind = UEpubBlockKind.blockquote;
        break;
      case "pre":
        _pendingKind = UEpubBlockKind.preformatted;
        break;
      default:
        break;
    }

    if (node.id.isNotEmpty) _pendingAnchor ??= node.id;
    final String? align = declarations["text-align"];
    if (align != null) _pendingAlign = _alignFor(align);
    final String? indent = declarations["text-indent"];
    if (indent != null) _pendingIndent = _length(indent, 0);

    for (final UEpubNode child in node.children) {
      _visit(child, depth + 1);
    }

    if (isBlock) {
      if (node.tag == "td" || node.tag == "th") {
        _row.add(List<UEpubSpan>.from(_inline));
        _inline.clear();
        _inCell = false;
      } else if (node.tag == "tr") {
        if (_inline.isNotEmpty) {
          _row.add(List<UEpubSpan>.from(_inline));
          _inline.clear();
        }
        if (_row.isNotEmpty) {
          blocks.add(UEpubBlock(kind: UEpubBlockKind.tableRow, cells: List<List<UEpubSpan>>.from(_row), marginTop: 2, marginBottom: 2, rtl: _rtl));
          for (final List<UEpubSpan> cell in _row) {
            for (final UEpubSpan span in cell) {
              _plain.write("${span.text} ");
            }
          }
          _plain.writeln();
        }
        _row.clear();
        _inRow = false;
      } else {
        _flush();
      }
      if (node.tag == "ul" || node.tag == "ol") {
        if (_listStack.isNotEmpty) _listStack.removeLast();
        if (_listCounters.isNotEmpty) _listCounters.removeLast();
      }
      _pendingKind = UEpubBlockKind.paragraph;
      _pendingLevel = 0;
      _pendingAlign = null;
      _pendingIndent = 0;
    }
    _rtl = previousRtl;
    _chain.removeLast();
  }

  String _resolve(String href) {
    final String cleaned = href.split("#").first;
    if (cleaned.startsWith("/")) return cleaned.substring(1);
    final String directory = baseHref.contains("/") ? baseHref.substring(0, baseHref.lastIndexOf("/") + 1) : "";
    return UEpubBook._normalize("$directory$cleaned");
  }

  TextAlign? _alignFor(String value) {
    switch (value.trim().toLowerCase()) {
      case "center":
        return TextAlign.center;
      case "right":
        return TextAlign.right;
      case "left":
        return TextAlign.left;
      case "justify":
        return TextAlign.justify;
      default:
        return null;
    }
  }

  double _length(String value, double fallback) {
    final RegExpMatch? match = RegExp(r"(-?[\d.]+)\s*(px|pt|em|rem|%)?").firstMatch(value.trim());
    if (match == null) return fallback;
    final double number = double.tryParse(match.group(1) ?? "") ?? fallback;
    switch (match.group(2)) {
      case "pt":
        return number * 1.333;
      case "em":
      case "rem":
        return number * 16;
      case "%":
        return number * 0.16;
      default:
        return number;
    }
  }

  Color? _color(String? value) {
    if (value == null) return null;
    final String text = value.trim().toLowerCase();
    if (text.startsWith("#")) {
      final String hex = text.substring(1);
      if (hex.length == 3) {
        final int? value16 = int.tryParse("${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}", radix: 16);
        return value16 == null ? null : Color(0xFF000000 | value16);
      }
      if (hex.length == 6) {
        final int? value24 = int.tryParse(hex, radix: 16);
        return value24 == null ? null : Color(0xFF000000 | value24);
      }
      return null;
    }
    final RegExpMatch? rgb = RegExp(r"rgba?\(([^)]*)\)").firstMatch(text);
    if (rgb != null) {
      final List<String> parts = (rgb.group(1) ?? "").split(",");
      if (parts.length >= 3) {
        final int r = int.tryParse(parts[0].trim()) ?? 0;
        final int g = int.tryParse(parts[1].trim()) ?? 0;
        final int b = int.tryParse(parts[2].trim()) ?? 0;
        return Color.fromARGB(255, r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255));
      }
    }
    const Map<String, int> named = <String, int>{
      "black": 0xFF000000,
      "white": 0xFFFFFFFF,
      "red": 0xFFF44336,
      "green": 0xFF4CAF50,
      "blue": 0xFF2196F3,
      "gray": 0xFF9E9E9E,
      "grey": 0xFF9E9E9E,
      "silver": 0xFFC0C0C0,
      "maroon": 0xFF800000,
      "navy": 0xFF000080,
      "olive": 0xFF808000,
      "purple": 0xFF800080,
      "teal": 0xFF008080,
      "yellow": 0xFFFFEB3B,
      "orange": 0xFFFF9800,
    };
    final int? value32 = named[text];
    return value32 == null ? null : Color(value32);
  }

  void _appendText(String raw) {
    if (raw.isEmpty) return;
    final bool preformatted = _pendingKind == UEpubBlockKind.preformatted;
    final String text = preformatted ? raw : raw.replaceAll(RegExp(r"[\r\n\t]+"), " ").replaceAll(RegExp(" {2,}"), " ");
    if (text.trim().isEmpty && !preformatted) {
      if (_inline.isNotEmpty && !_inline.last.text.endsWith(" ")) _inline.add(const UEpubSpan(text: " "));
      return;
    }
    final Map<String, String> declarations = sheet.declarationsFor(_chain);
    bool bold = false;
    bool italic = false;
    bool underline = false;
    bool strike = false;
    bool monospace = false;
    bool superscript = false;
    bool subscript = false;
    String? href;
    for (final UEpubNode node in _chain) {
      switch (node.tag) {
        case "b":
        case "strong":
          bold = true;
          break;
        case "i":
        case "em":
        case "cite":
        case "dfn":
          italic = true;
          break;
        case "u":
        case "ins":
          underline = true;
          break;
        case "s":
        case "strike":
        case "del":
          strike = true;
          break;
        case "code":
        case "kbd":
        case "samp":
        case "tt":
        case "pre":
          monospace = true;
          break;
        case "sup":
          superscript = true;
          break;
        case "sub":
          subscript = true;
          break;
        case "a":
          href = node.attributes["href"] ?? href;
          break;
        default:
          break;
      }
    }
    final String weight = (declarations["font-weight"] ?? "").toLowerCase();
    if (weight == "bold" || weight == "bolder" || (int.tryParse(weight) ?? 400) >= 600) bold = true;
    if (weight == "normal" || weight == "400") bold = false;
    final String style = (declarations["font-style"] ?? "").toLowerCase();
    if (style == "italic" || style == "oblique") italic = true;
    final String decoration = (declarations["text-decoration"] ?? "").toLowerCase();
    if (decoration.contains("underline")) underline = true;
    if (decoration.contains("line-through")) strike = true;
    double factor = 1;
    final String? size = declarations["font-size"];
    if (size != null) {
      final String lower = size.trim().toLowerCase();
      if (lower.endsWith("%")) {
        factor = (double.tryParse(lower.substring(0, lower.length - 1)) ?? 100) / 100;
      } else if (lower.endsWith("em") || lower.endsWith("rem")) {
        factor = double.tryParse(lower.replaceAll(RegExp("r?em"), "")) ?? 1;
      } else if (lower == "larger" || lower == "large" || lower == "x-large" || lower == "xx-large") {
        factor = 1.25;
      } else if (lower == "smaller" || lower == "small" || lower == "x-small") {
        factor = 0.85;
      }
    }
    _inline.add(
      UEpubSpan(
        text: text,
        bold: bold,
        italic: italic,
        underline: underline || href != null,
        strike: strike,
        monospace: monospace,
        superscript: superscript,
        subscript: subscript,
        color: _color(declarations["color"]),
        background: _color(declarations["background-color"]),
        sizeFactor: factor.clamp(0.5, 3).toDouble(),
        href: href,
        fontFamily: declarations["font-family"],
      ),
    );
    _plain.write(text);
  }

  void _flush() {
    if (_inCell || _inRow && _inline.isEmpty) return;
    if (_inline.isEmpty) return;
    final String joined = _inline.map((UEpubSpan span) => span.text).join();
    if (joined.trim().isEmpty) {
      _inline.clear();
      return;
    }
    String marker = "";
    if (_pendingKind == UEpubBlockKind.listItem && _listStack.isNotEmpty) {
      marker = _listStack.last == "ol" ? "${_listCounters.last}." : "•";
    }
    if (_pendingKind == UEpubBlockKind.heading && title.isEmpty) title = joined.trim();
    final bool rtl = _rtl || UDocText.isRtl(joined);
    blocks.add(
      UEpubBlock(
        kind: _pendingKind,
        spans: List<UEpubSpan>.from(_inline),
        level: _pendingLevel,
        align: _pendingAlign,
        indent: _pendingIndent,
        marginTop: _pendingKind == UEpubBlockKind.heading ? 16 : 6,
        marginBottom: _pendingKind == UEpubBlockKind.heading ? 8 : 6,
        listMarker: marker,
        anchorId: _pendingAnchor,
        rtl: rtl,
      ),
    );
    _plain.writeln();
    _pendingAnchor = null;
    _inline.clear();
  }
}

class UEpubPosition {
  const UEpubPosition({required this.spineIndex, this.blockIndex = 0, this.charOffset = 0});

  final int spineIndex;
  final int blockIndex;
  final int charOffset;

  String encode() => "u-epub:$spineIndex/$blockIndex:$charOffset";

  static UEpubPosition? decode(String? value) {
    if (value == null || !value.startsWith("u-epub:")) return null;
    final RegExpMatch? match = RegExp(r"^u-epub:(\d+)/(\d+):(\d+)$").firstMatch(value);
    if (match == null) return null;
    return UEpubPosition(
      spineIndex: int.tryParse(match.group(1) ?? "0") ?? 0,
      blockIndex: int.tryParse(match.group(2) ?? "0") ?? 0,
      charOffset: int.tryParse(match.group(3) ?? "0") ?? 0,
    );
  }
}

class UEpubHighlight {
  const UEpubHighlight({required this.id, required this.position, required this.text, required this.createdAt, this.note = "", this.color = 0xFFFFEB3B});

  final String id;
  final UEpubPosition position;
  final String text;
  final DateTime createdAt;
  final String note;
  final int color;

  Map<String, Object?> toJson() => <String, Object?>{
    "id": id,
    "position": position.encode(),
    "text": text,
    "createdAt": createdAt.toIso8601String(),
    "note": note,
    "color": color,
  };

  factory UEpubHighlight.fromJson(Map<String, Object?> json) => UEpubHighlight(
    id: (json["id"] as String?) ?? "",
    position: UEpubPosition.decode(json["position"] as String?) ?? const UEpubPosition(spineIndex: 0),
    text: (json["text"] as String?) ?? "",
    createdAt: DateTime.tryParse((json["createdAt"] as String?) ?? "") ?? DateTime.now(),
    note: (json["note"] as String?) ?? "",
    color: (json["color"] as num?)?.toInt() ?? 0xFFFFEB3B,
  );
}

class UEpubTypography {
  const UEpubTypography({
    this.fontScale = 1,
    this.lineHeight = 1.6,
    this.fontFamily,
    this.horizontalMargin = 20,
    this.verticalMargin = 16,
    this.justify = true,
    this.paragraphSpacing = 8,
    this.letterSpacing = 0,
    this.wordSpacing = 0,
    this.hyphenate = false,
  });

  final double fontScale;
  final double lineHeight;
  final String? fontFamily;
  final double horizontalMargin;
  final double verticalMargin;
  final bool justify;
  final double paragraphSpacing;
  final double letterSpacing;
  final double wordSpacing;
  final bool hyphenate;

  double get baseFontSize => 16 * fontScale;

  UEpubTypography copyWith({
    double? fontScale,
    double? lineHeight,
    String? fontFamily,
    double? horizontalMargin,
    double? verticalMargin,
    bool? justify,
    double? paragraphSpacing,
    double? letterSpacing,
    double? wordSpacing,
    bool? hyphenate,
  }) => UEpubTypography(
    fontScale: fontScale ?? this.fontScale,
    lineHeight: lineHeight ?? this.lineHeight,
    fontFamily: fontFamily ?? this.fontFamily,
    horizontalMargin: horizontalMargin ?? this.horizontalMargin,
    verticalMargin: verticalMargin ?? this.verticalMargin,
    justify: justify ?? this.justify,
    paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
    letterSpacing: letterSpacing ?? this.letterSpacing,
    wordSpacing: wordSpacing ?? this.wordSpacing,
    hyphenate: hyphenate ?? this.hyphenate,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    "fontScale": fontScale,
    "lineHeight": lineHeight,
    "fontFamily": fontFamily,
    "horizontalMargin": horizontalMargin,
    "verticalMargin": verticalMargin,
    "justify": justify,
    "paragraphSpacing": paragraphSpacing,
    "letterSpacing": letterSpacing,
    "wordSpacing": wordSpacing,
    "hyphenate": hyphenate,
  };

  factory UEpubTypography.fromJson(Map<String, Object?> json) => UEpubTypography(
    fontScale: (json["fontScale"] as num?)?.toDouble() ?? 1,
    lineHeight: (json["lineHeight"] as num?)?.toDouble() ?? 1.6,
    fontFamily: json["fontFamily"] as String?,
    horizontalMargin: (json["horizontalMargin"] as num?)?.toDouble() ?? 20,
    verticalMargin: (json["verticalMargin"] as num?)?.toDouble() ?? 16,
    justify: json["justify"] as bool? ?? true,
    paragraphSpacing: (json["paragraphSpacing"] as num?)?.toDouble() ?? 8,
    letterSpacing: (json["letterSpacing"] as num?)?.toDouble() ?? 0,
    wordSpacing: (json["wordSpacing"] as num?)?.toDouble() ?? 0,
    hyphenate: json["hyphenate"] as bool? ?? false,
  );
}

class UEpubController extends UDocController {
  UEpubController();

  UEpubBook? _book;
  UDocTextIndex? _index;

  final Map<int, UEpubChapter> _chapters = <int, UEpubChapter>{};
  final ULruCache<String, Uint8List> _images = ULruCache<String, Uint8List>(maxBytes: 24 * 1024 * 1024, sizeOf: _imageSize);
  final List<UEpubHighlight> highlights = <UEpubHighlight>[];

  UEpubTypography typography = const UEpubTypography();
  List<UDocOutlineNode> outline = <UDocOutlineNode>[];
  int _searchToken = 0;

  static int _imageSize(Uint8List value) => value.length;

  UEpubBook? get book => _book;

  @override
  String get documentId => _book?.fingerprint ?? "epub";

  @override
  UDocKind get kind => UDocKind.epub;

  Future<void> open({String? path, String? url, Uint8List? bytes, String? asset, Object? blob, Map<String, String>? headers}) async {
    emit(value.copyWith(state: UDocState.opening, isBusy: true, clearError: true));
    try {
      final UEpubBook book = await UEpubBook.open(path: path, url: url, bytes: bytes, asset: asset, blob: blob, headers: headers);
      _book = book;
      _index = await UDocTextIndex.open(book.fingerprint);
      outline = book.navigation;
      await UDocProgressStore.instance.load();
      final UDocProgress? progress = UDocProgressStore.instance.get(book.fingerprint);
      emit(
        value.copyWith(
          state: UDocState.ready,
          kind: UDocKind.epub,
          pageCount: book.chapterCount,
          metadata: book.metadata,
          settings: settings.copyWith(direction: book.direction, scrollMode: UDocScrollMode.verticalContinuous),
          pageIndex: progress != null && progress.pageIndex < book.chapterCount ? progress.pageIndex : 0,
          isBusy: false,
          loadedPercent: 1,
          clearError: true,
        ),
      );
      await _loadHighlights();
    } on UDocError catch (error) {
      failWith(error);
    } on Object catch (error) {
      failWith(UDocError(code: UDocErrorCode.corrupt, message: "Could not open the book", detail: "$error"));
    }
  }

  Future<UEpubChapter> chapter(int index) async {
    final UEpubChapter? cached = _chapters[index];
    if (cached != null) return cached;
    final UEpubBook? book = _book;
    if (book == null) return UEpubChapter(spineIndex: index, href: "", blocks: const <UEpubBlock>[], title: "", text: "");
    final UEpubChapter chapter = await book.chapter(index);
    if (_chapters.length > 12) _chapters.clear();
    _chapters[index] = chapter;
    unawaited(_index?.writePage(index, chapter.text) ?? Future<void>.value());
    return chapter;
  }

  Future<Uint8List?> image(String href) async {
    final Uint8List? cached = _images.get(href);
    if (cached != null) return cached;
    final UEpubBook? book = _book;
    if (book == null) return null;
    final Uint8List data = await book.resource(href);
    if (data.isEmpty) return null;
    _images.put(href, data);
    return data;
  }

  void setTypography(UEpubTypography next) {
    typography = next;
    notifyListeners();
    unawaited(_saveTypography());
  }

  Future<void> _saveTypography() async {
    try {
      ULocalStorage.set("u_epub_typography", jsonEncode(typography.toJson()));
    } on Object {
      return;
    }
  }

  Future<void> loadTypography() async {
    try {
      final String? raw = ULocalStorage.getString("u_epub_typography");
      if (raw == null || raw.isEmpty) return;
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) {
        typography = UEpubTypography.fromJson(decoded);
        notifyListeners();
      }
    } on Object {
      return;
    }
  }

  String get _highlightKey => "u_epub_highlights_${_book?.fingerprint ?? ""}";

  Future<void> _loadHighlights() async {
    try {
      final String? raw = ULocalStorage.getString(_highlightKey);
      if (raw == null || raw.isEmpty) return;
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List<Object?>) return;
      highlights.clear();
      for (final Object? entry in decoded) {
        if (entry is Map<String, Object?>) highlights.add(UEpubHighlight.fromJson(entry));
      }
      notifyListeners();
    } on Object {
      return;
    }
  }

  Future<void> saveHighlights() async {
    try {
      ULocalStorage.set(_highlightKey, jsonEncode(highlights.map((UEpubHighlight highlight) => highlight.toJson()).toList()));
    } on Object {
      return;
    }
  }

  void addHighlight(UEpubHighlight highlight) {
    highlights.add(highlight);
    notifyListeners();
    unawaited(saveHighlights());
  }

  void removeHighlight(String id) {
    highlights.removeWhere((UEpubHighlight highlight) => highlight.id == id);
    notifyListeners();
    unawaited(saveHighlights());
  }

  @override
  UDocPageInfo pageInfo(int pageIndex) => UDocPageInfo(index: pageIndex, size: const Size(600, 900));

  @override
  Future<UDocTextPage> textPage(int pageIndex) async {
    final UEpubChapter chapter = await this.chapter(pageIndex);
    return UDocTextPage(pageIndex: pageIndex, runs: const <UDocTextRun>[], text: chapter.text, size: const Size(600, 900));
  }

  @override
  Future<ui.Picture?> renderPage(int pageIndex, {double scale = 1, Rect? clip}) async => null;

  @override
  Future<ui.Image?> renderThumbnail(int pageIndex, {int maxSize = 240}) async => null;

  Future<List<UDocSearchHit>> search(String query, {UDocSearchOptions options = const UDocSearchOptions()}) async {
    final UEpubBook? book = _book;
    final String trimmed = query.trim();
    if (book == null || trimmed.isEmpty) {
      clearSearch();
      return const <UDocSearchHit>[];
    }
    final int token = ++_searchToken;
    emit(value.copyWith(searchQuery: trimmed, isSearching: true, searchHits: const <UDocSearchHit>[], searchHitIndex: -1));
    final String needle = options.normalizePersian ? UDocText.forSearch(trimmed) : trimmed.toLowerCase();
    final List<UDocSearchHit> hits = <UDocSearchHit>[];
    for (int index = 0; index < book.chapterCount; index++) {
      if (token != _searchToken || isDisposed) return hits;
      final UEpubChapter chapter = await this.chapter(index);
      if (chapter.text.isEmpty) continue;
      final UDocNormalizedText normalized = options.normalizePersian
          ? UDocNormalizedText.build(chapter.text)
          : UDocNormalizedText(chapter.text.toLowerCase(), List<int>.generate(chapter.text.length, (int i) => i));
      for (final int position in UDocText.findAll(normalized.text, needle, wholeWord: options.wholeWord)) {
        final int start = normalized.sourceAt(position);
        final int end = normalized.sourceAt(position + needle.length - 1) + 1;
        final int snippetStart = start - 48 < 0 ? 0 : start - 48;
        final int snippetEnd = end + 48 > chapter.text.length ? chapter.text.length : end + 48;
        hits.add(
          UDocSearchHit(pageIndex: index, start: start, end: end, snippet: chapter.text.substring(snippetStart, snippetEnd).replaceAll("\n", " "), rects: const <Rect>[], matchIndex: hits.length),
        );
        if (hits.length >= options.maxHits) break;
      }
      liveHits.value = List<UDocSearchHit>.from(hits);
      if (hits.length >= options.maxHits) break;
    }
    if (token != _searchToken || isDisposed) return hits;
    emit(value.copyWith(searchHits: hits, isSearching: false, searchHitIndex: hits.isEmpty ? -1 : 0));
    return hits;
  }

  void saveProgress({double percent = 0, String? position}) {
    final UEpubBook? book = _book;
    if (book == null) return;
    UDocProgressStore.instance.put(
      UDocProgress(
        fingerprint: book.fingerprint,
        updatedAt: DateTime.now(),
        pageIndex: value.pageIndex,
        percent: percent,
        cfi: position,
        colorMode: settings.colorMode,
      ),
    );
  }

  @override
  Future<void> close() async {
    saveProgress();
    _chapters.clear();
    _images.clear();
    await _index?.close();
    await _book?.close();
    _book = null;
    emit(value.copyWith(state: UDocState.closed));
  }

  @override
  void dispose() {
    unawaited(close());
    super.dispose();
  }
}

class UEpubPage {
  const UEpubPage({required this.spineIndex, required this.pageIndex, required this.blocks, required this.startBlock});

  final int spineIndex;
  final int pageIndex;
  final List<UEpubBlock> blocks;
  final int startBlock;
}

class UEpubPaginator {
  UEpubPaginator({required this.typography, required this.size, required this.textScaler});

  final UEpubTypography typography;
  final Size size;
  final TextScaler textScaler;

  double _blockHeight(UEpubBlock block, double width) {
    if (block.kind == UEpubBlockKind.rule) return 24;
    if (block.kind == UEpubBlockKind.image) return size.height * 0.6;
    if (block.kind == UEpubBlockKind.pageBreak) return 0;
    if (block.kind == UEpubBlockKind.tableRow) {
      double tallest = 0;
      final double cellWidth = block.cells.isEmpty ? width : width / block.cells.length;
      for (final List<UEpubSpan> cell in block.cells) {
        final double height = _measure(cell.map((UEpubSpan span) => span.text).join(), cellWidth, typography.baseFontSize);
        if (height > tallest) tallest = height;
      }
      return tallest + block.marginTop + block.marginBottom;
    }
    final double base = typography.baseFontSize * (block.kind == UEpubBlockKind.heading ? _headingScale(block.level) : 1);
    return _measure(block.text, width - block.indent, base) + block.marginTop + block.marginBottom + typography.paragraphSpacing / 2;
  }

  double _headingScale(int level) {
    switch (level) {
      case 1:
        return 1.7;
      case 2:
        return 1.45;
      case 3:
        return 1.28;
      case 4:
        return 1.15;
      case 5:
        return 1.08;
      default:
        return 1;
    }
  }

  double _measure(String text, double width, double fontSize) {
    if (text.isEmpty || width <= 0) return 0;
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, height: typography.lineHeight, fontFamily: typography.fontFamily, letterSpacing: typography.letterSpacing),
      ),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout(maxWidth: width);
    final double height = painter.height;
    painter.dispose();
    return height;
  }

  List<UEpubPage> paginate(UEpubChapter chapter) {
    final double width = size.width - typography.horizontalMargin * 2;
    final double limit = size.height - typography.verticalMargin * 2;
    if (width <= 0 || limit <= 0 || chapter.blocks.isEmpty) {
      return <UEpubPage>[UEpubPage(spineIndex: chapter.spineIndex, pageIndex: 0, blocks: chapter.blocks, startBlock: 0)];
    }
    final List<UEpubPage> pages = <UEpubPage>[];
    List<UEpubBlock> current = <UEpubBlock>[];
    int startBlock = 0;
    double used = 0;
    for (int index = 0; index < chapter.blocks.length; index++) {
      final UEpubBlock block = chapter.blocks[index];
      final double height = _blockHeight(block, width);
      if (height > limit && block.spans.isNotEmpty) {
        if (current.isNotEmpty) {
          pages.add(UEpubPage(spineIndex: chapter.spineIndex, pageIndex: pages.length, blocks: current, startBlock: startBlock));
          current = <UEpubBlock>[];
          used = 0;
          startBlock = index;
        }
        for (final UEpubBlock piece in _splitBlock(block, width, limit)) {
          pages.add(UEpubPage(spineIndex: chapter.spineIndex, pageIndex: pages.length, blocks: <UEpubBlock>[piece], startBlock: index));
        }
        startBlock = index + 1;
        continue;
      }
      if (used + height > limit && current.isNotEmpty) {
        pages.add(UEpubPage(spineIndex: chapter.spineIndex, pageIndex: pages.length, blocks: current, startBlock: startBlock));
        current = <UEpubBlock>[];
        used = 0;
        startBlock = index;
      }
      current.add(block);
      used += height;
    }
    if (current.isNotEmpty) pages.add(UEpubPage(spineIndex: chapter.spineIndex, pageIndex: pages.length, blocks: current, startBlock: startBlock));
    if (pages.isEmpty) pages.add(UEpubPage(spineIndex: chapter.spineIndex, pageIndex: 0, blocks: chapter.blocks, startBlock: 0));
    return pages;
  }

  List<UEpubBlock> _splitBlock(UEpubBlock block, double width, double limit) {
    final String text = block.text;
    final double base = typography.baseFontSize * (block.kind == UEpubBlockKind.heading ? _headingScale(block.level) : 1);
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: base, height: typography.lineHeight, fontFamily: typography.fontFamily, letterSpacing: typography.letterSpacing),
      ),
      textDirection: block.rtl ? TextDirection.rtl : TextDirection.ltr,
      textScaler: textScaler,
    )..layout(maxWidth: width);
    final List<ui.LineMetrics> lines = painter.computeLineMetrics();
    final List<UEpubBlock> out = <UEpubBlock>[];
    if (lines.isEmpty) {
      painter.dispose();
      return <UEpubBlock>[block];
    }
    double consumed = 0;
    int startOffset = 0;
    for (int i = 0; i < lines.length; i++) {
      consumed += lines[i].height;
      final bool last = i == lines.length - 1;
      if (consumed <= limit && !last) continue;
      final double bottom = lines[i].baseline + lines[i].descent;
      final int endOffset = last ? text.length : painter.getPositionForOffset(Offset(width, bottom - lines[i].height / 2)).offset;
      final int safeEnd = endOffset.clamp(startOffset + 1, text.length);
      out.add(
        UEpubBlock(
          kind: block.kind,
          spans: <UEpubSpan>[UEpubSpan(text: text.substring(startOffset, safeEnd))],
          level: block.level,
          align: block.align,
          rtl: block.rtl,
        ),
      );
      startOffset = safeEnd;
      consumed = 0;
      if (startOffset >= text.length) break;
    }
    if (startOffset < text.length) {
      out.add(
        UEpubBlock(
          kind: block.kind,
          spans: <UEpubSpan>[UEpubSpan(text: text.substring(startOffset))],
          level: block.level,
          align: block.align,
          rtl: block.rtl,
        ),
      );
    }
    painter.dispose();
    return out.isEmpty ? <UEpubBlock>[block] : out;
  }
}
