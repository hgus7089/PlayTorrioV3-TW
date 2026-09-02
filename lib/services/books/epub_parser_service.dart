import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as p;

class EpubTocItem {
  final String title;
  final String contentSrc;
  final int chapterIndex;
  final List<EpubTocItem> children;

  const EpubTocItem({
    required this.title,
    required this.contentSrc,
    this.chapterIndex = 0,
    this.children = const [],
  });
}

class EpubChapterData {
  final String id;
  final String title;
  final String href;
  final String htmlContent;
  final String textPreview;
  final int orderIndex;
  final int wordCount;

  const EpubChapterData({
    required this.id,
    required this.title,
    required this.href,
    required this.htmlContent,
    this.textPreview = '',
    required this.orderIndex,
    this.wordCount = 0,
  });
}

class EpubBookData {
  final String title;
  final String author;
  final String description;
  final String publisher;
  final String language;
  final Uint8List? coverBytes;
  final List<EpubChapterData> chapters;
  final List<EpubTocItem> tableOfContents;
  final Map<String, Uint8List> images;

  const EpubBookData({
    required this.title,
    required this.author,
    this.description = '',
    this.publisher = '',
    this.language = '',
    this.coverBytes,
    required this.chapters,
    required this.tableOfContents,
    required this.images,
  });

  int get totalChapters => chapters.length;

  /// Resolves an image's bytes from an <img> src tag relative to chapter's href.
  Uint8List? resolveImage(String src, String chapterHref) {
    if (src.isEmpty) return null;

    if (images.containsKey(src)) return images[src];

    final cleanSrc = src.startsWith('#') ? src.substring(1) : src;
    if (images.containsKey(cleanSrc)) return images[cleanSrc];

    final decodedSrc = Uri.decodeComponent(src);
    if (images.containsKey(decodedSrc)) return images[decodedSrc];

    final embedMatch = RegExp(r'(?:kindle:embed:|recindex=)["0]*(\d+)').firstMatch(src);
    if (embedMatch != null) {
      final recNum = embedMatch.group(1);
      if (recNum != null && images.containsKey(recNum)) {
        return images[recNum];
      }
    }

    final chapterDir = p.dirname(chapterHref);
    final resolved = p.normalize(p.join(chapterDir, decodedSrc)).replaceAll(r'\', '/');
    if (images.containsKey(resolved)) return images[resolved];

    final cleanPath = resolved.replaceFirst(RegExp(r'^\.?/+'), '');
    if (images.containsKey(cleanPath)) return images[cleanPath];

    final fileName = p.basename(decodedSrc);
    for (final entry in images.entries) {
      if (p.basename(entry.key) == fileName) {
        return entry.value;
      }
    }

    return null;
  }
}

class EpubParserService {
  static EpubParserService? _instance;
  static EpubParserService get instance => _instance ??= EpubParserService._();
  EpubParserService._();

  /// Parses any supported book format asynchronously.
  Future<EpubBookData> parseBook(File file, String format) async {
    final bytes = await file.readAsBytes();
    final fmt = format.toLowerCase().trim();

    return compute(_parseBookInBackground, _ParseBookPayload(bytes, fmt, p.basename(file.path)));
  }
}

class _ParseBookPayload {
  final Uint8List bytes;
  final String format;
  final String fileName;

  _ParseBookPayload(this.bytes, this.format, this.fileName);
}

EpubBookData _parseBookInBackground(_ParseBookPayload payload) {
  final fmt = payload.format;
  if (fmt == 'epub') {
    return _parseEpubSync(payload.bytes, payload.fileName);
  } else if (fmt == 'fb2' || fmt == 'fb2.zip') {
    return _parseFb2Sync(payload.bytes, payload.fileName);
  } else if (fmt == 'mobi' || fmt == 'azw3' || fmt == 'azw' || fmt == 'kf8') {
    return _parseMobiSync(payload.bytes, payload.fileName);
  } else if (fmt == 'txt') {
    return _parseTxtSync(payload.bytes, payload.fileName);
  } else if (fmt == 'cbz' || fmt == 'cbr') {
    return _parseComicSync(payload.bytes, payload.fileName);
  } else {
    return _parseLegacyFallbackSync(payload.bytes, payload.fileName, fmt);
  }
}

// ============================================================================
// EPUB PARSER
// ============================================================================

EpubBookData _parseEpubSync(Uint8List bytes, String fileName) {
  final archive = ZipDecoder().decodeBytes(bytes, verify: false);

  String? opfPath;
  for (final file in archive.files) {
    if (file.name == 'META-INF/container.xml') {
      final xmlContent = utf8.decode(file.content as List<int>, allowMalformed: true);
      final match = RegExp(r'full-path="([^"]+)"').firstMatch(xmlContent);
      if (match != null) {
        opfPath = match.group(1);
        break;
      }
    }
  }

  ArchiveFile? opfFile;
  if (opfPath != null) {
    opfFile = archive.files.firstWhere(
      (f) => f.name == opfPath || f.name == opfPath?.replaceAll(r'\', '/'),
      orElse: () => archive.files.firstWhere((f) => f.name.endsWith('.opf'), orElse: () => archive.files.first),
    );
  } else {
    opfFile = archive.files.firstWhere((f) => f.name.endsWith('.opf'), orElse: () => archive.files.first);
  }

  final opfDir = p.dirname(opfFile.name);
  final opfXml = utf8.decode(opfFile.content as List<int>, allowMalformed: true);
  final opfDoc = html_parser.parse(opfXml);

  final title = opfDoc.querySelector('title, dc\\:title')?.text.trim() ??
      p.basenameWithoutExtension(fileName).replaceAll(RegExp(r'[_\-]+'), ' ');
  final author = opfDoc.querySelector('creator, dc\\:creator')?.text.trim() ?? 'Unknown Author';
  final description = opfDoc.querySelector('description, dc\\:description')?.text.trim() ?? '';
  final publisher = opfDoc.querySelector('publisher, dc\\:publisher')?.text.trim() ?? '';
  final language = opfDoc.querySelector('language, dc\\:language')?.text.trim() ?? 'en';

  final manifestItems = <String, String>{};
  final manifestTypes = <String, String>{};
  for (final item in opfDoc.querySelectorAll('manifest > item, item')) {
    final id = item.attributes['id'];
    final href = item.attributes['href'];
    final mediaType = item.attributes['media-type'] ?? '';
    if (id != null && href != null) {
      final fullPath = p.normalize(p.join(opfDir, href)).replaceAll(r'\', '/');
      manifestItems[id] = fullPath;
      manifestTypes[id] = mediaType;
    }
  }

  final spineItemIds = <String>[];
  for (final itemref in opfDoc.querySelectorAll('spine > itemref, itemref')) {
    final idref = itemref.attributes['idref'];
    if (idref != null && manifestItems.containsKey(idref)) {
      spineItemIds.add(idref);
    }
  }

  final images = <String, Uint8List>{};
  Uint8List? coverBytes;

  for (final file in archive.files) {
    if (file.isFile) {
      final normalizedName = file.name.replaceAll(r'\', '/');
      final content = Uint8List.fromList(file.content as List<int>);

      final lowerName = normalizedName.toLowerCase();
      if (lowerName.endsWith('.jpg') ||
          lowerName.endsWith('.jpeg') ||
          lowerName.endsWith('.png') ||
          lowerName.endsWith('.webp') ||
          lowerName.endsWith('.gif') ||
          lowerName.endsWith('.svg')) {
        images[normalizedName] = content;
        images[p.basename(normalizedName)] = content;

        if (lowerName.contains('cover') && coverBytes == null) {
          coverBytes = content;
        }
      }
    }
  }

  final toc = <EpubTocItem>[];
  String? ncxPath;
  for (final entry in manifestTypes.entries) {
    if (entry.value.contains('x-dtbncx+xml') || entry.key == 'ncx') {
      ncxPath = manifestItems[entry.key];
      break;
    }
  }

  if (ncxPath != null) {
    final ncxFile = archive.files.firstWhere(
      (f) => f.name == ncxPath || f.name == ncxPath?.replaceAll(r'\', '/'),
      orElse: () => archive.files.firstWhere((f) => f.name.endsWith('.ncx'), orElse: () => archive.files.first),
    );
    if (ncxFile.name.endsWith('.ncx')) {
      final ncxXml = utf8.decode(ncxFile.content as List<int>, allowMalformed: true);
      final ncxDoc = html_parser.parse(ncxXml);
      int navIdx = 0;
      for (final navPoint in ncxDoc.querySelectorAll('navPoint')) {
        final label = navPoint.querySelector('navLabel > text, text')?.text.trim() ?? 'Chapter ${navIdx + 1}';
        final src = navPoint.querySelector('content')?.attributes['src'] ?? '';
        toc.add(EpubTocItem(
          title: label,
          contentSrc: src,
          chapterIndex: navIdx,
        ));
        navIdx++;
      }
    }
  }

  final chapters = <EpubChapterData>[];
  final chapterPaths = spineItemIds.isNotEmpty
      ? spineItemIds.map((id) => manifestItems[id]!).toList()
      : archive.files
          .where((f) => f.name.endsWith('.xhtml') || f.name.endsWith('.html') || f.name.endsWith('.htm'))
          .map((f) => f.name)
          .toList();

  for (int idx = 0; idx < chapterPaths.length; idx++) {
    final path = chapterPaths[idx];
    final file = archive.files.firstWhere(
      (f) => f.name == path || f.name == path.replaceAll(r'\', '/'),
      orElse: () => archive.files.first,
    );

    if (file.name == path || file.name == path.replaceAll(r'\', '/')) {
      final rawHtml = utf8.decode(file.content as List<int>, allowMalformed: true);
      final doc = html_parser.parse(rawHtml);

      String chapterTitle = '';
      final h1 = doc.querySelector('h1, h2, h3, title');
      if (h1 != null && h1.text.trim().isNotEmpty) {
        chapterTitle = h1.text.trim();
      }

      if (chapterTitle.isEmpty && idx < toc.length) {
        chapterTitle = toc[idx].title;
      }
      if (chapterTitle.isEmpty) {
        chapterTitle = 'Chapter ${idx + 1}';
      }

      final text = doc.body?.text.trim() ?? '';
      final preview = text.length > 200 ? '${text.substring(0, 200)}...' : text;
      final wordCount = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

      chapters.add(EpubChapterData(
        id: 'ch_$idx',
        title: chapterTitle,
        href: path,
        htmlContent: rawHtml,
        textPreview: preview,
        orderIndex: idx,
        wordCount: wordCount,
      ));

      if (toc.length <= idx) {
        toc.add(EpubTocItem(
          title: chapterTitle,
          contentSrc: path,
          chapterIndex: idx,
        ));
      }
    }
  }

  return EpubBookData(
    title: title,
    author: author,
    description: description,
    publisher: publisher,
    language: language,
    coverBytes: coverBytes,
    chapters: chapters,
    tableOfContents: toc,
    images: images,
  );
}

// ============================================================================
// FB2 PARSER (FictionBook 2.0)
// ============================================================================

EpubBookData _parseFb2Sync(Uint8List bytes, String fileName) {
  String xmlString;
  try {
    if (bytes.length > 4 && bytes[0] == 0x50 && bytes[1] == 0x4B) {
      final archive = ZipDecoder().decodeBytes(bytes, verify: false);
      final fb2File = archive.files.firstWhere(
        (f) => f.name.toLowerCase().endsWith('.fb2'),
        orElse: () => archive.files.first,
      );
      xmlString = utf8.decode(fb2File.content as List<int>, allowMalformed: true);
    } else {
      xmlString = utf8.decode(bytes, allowMalformed: true);
    }
  } catch (_) {
    xmlString = latin1.decode(bytes);
  }

  final images = <String, Uint8List>{};
  Uint8List? coverBytes;

  final binaryMatches = RegExp(r'<binary[\s\S]*?id="([^"]+)"[\s\S]*?>([\s\S]*?)<\/binary>', caseSensitive: false).allMatches(xmlString);
  for (final match in binaryMatches) {
    final id = match.group(1)?.trim() ?? '';
    final base64Data = match.group(2)?.replaceAll(RegExp(r'\s+'), '') ?? '';
    if (id.isNotEmpty && base64Data.isNotEmpty) {
      try {
        final decoded = base64Decode(base64Data);
        images[id] = decoded;
        images['#$id'] = decoded;
        if (id.toLowerCase().contains('cover') && coverBytes == null) {
          coverBytes = decoded;
        }
      } catch (_) {}
    }
  }

  String title = p.basenameWithoutExtension(fileName).replaceAll(RegExp(r'[_\-]+'), ' ');
  String author = 'Unknown Author';
  String description = '';

  final descMatch = RegExp(r'<description>([\s\S]*?)<\/description>', caseSensitive: false).firstMatch(xmlString);
  if (descMatch != null) {
    final descXml = descMatch.group(1)!;

    final titleMatch = RegExp(r'<book-title>([\s\S]*?)<\/book-title>', caseSensitive: false).firstMatch(descXml);
    if (titleMatch != null && titleMatch.group(1)!.trim().isNotEmpty) {
      title = titleMatch.group(1)!.trim();
    }

    final authorMatches = RegExp(r'<author>([\s\S]*?)<\/author>', caseSensitive: false).allMatches(descXml);
    final authorNames = <String>[];
    for (final aMatch in authorMatches) {
      final aBlock = aMatch.group(1)!;
      final first = RegExp(r'<first-name>([\s\S]*?)<\/first-name>', caseSensitive: false).firstMatch(aBlock)?.group(1)?.trim() ?? '';
      final last = RegExp(r'<last-name>([\s\S]*?)<\/last-name>', caseSensitive: false).firstMatch(aBlock)?.group(1)?.trim() ?? '';
      final full = '$first $last'.trim();
      if (full.isNotEmpty) authorNames.add(full);
    }
    if (authorNames.isNotEmpty) {
      author = authorNames.join(', ');
    }

    final annotMatch = RegExp(r'<annotation>([\s\S]*?)<\/annotation>', caseSensitive: false).firstMatch(descXml);
    if (annotMatch != null) {
      description = annotMatch.group(1)!.replaceAll(RegExp(r'<[^>]+>'), ' ').trim();
    }
  }

  final chapters = <EpubChapterData>[];
  final toc = <EpubTocItem>[];

  final bodyMatches = RegExp(r'<body[^>]*>([\s\S]*?)<\/body>', caseSensitive: false).allMatches(xmlString);
  int sectionCounter = 0;

  for (final bMatch in bodyMatches) {
    final bodyContent = bMatch.group(1)!;
    final sectionMatches = RegExp(r'<section[^>]*>([\s\S]*?)<\/section>', caseSensitive: false).allMatches(bodyContent);

    if (sectionMatches.isNotEmpty) {
      for (final sMatch in sectionMatches) {
        final secRaw = sMatch.group(1)!;
        final ch = _convertFb2SectionToChapter(secRaw, sectionCounter, images);
        if (ch != null) {
          chapters.add(ch);
          toc.add(EpubTocItem(
            title: ch.title,
            contentSrc: ch.href,
            chapterIndex: chapters.length - 1,
          ));
          sectionCounter++;
        }
      }
    } else {
      final ch = _convertFb2SectionToChapter(bodyContent, sectionCounter, images);
      if (ch != null) {
        chapters.add(ch);
        toc.add(EpubTocItem(
          title: ch.title,
          contentSrc: ch.href,
          chapterIndex: chapters.length - 1,
        ));
        sectionCounter++;
      }
    }
  }

  if (chapters.isEmpty) {
    final cleanXml = _cleanFb2XmlToHtml(xmlString);
    chapters.add(EpubChapterData(
      id: 'ch_0',
      title: title,
      href: 'ch_0.html',
      htmlContent: cleanXml,
      textPreview: title,
      orderIndex: 0,
      wordCount: 100,
    ));
    toc.add(EpubTocItem(title: title, contentSrc: 'ch_0.html', chapterIndex: 0));
  }

  return EpubBookData(
    title: title,
    author: author,
    description: description,
    coverBytes: coverBytes,
    chapters: chapters,
    tableOfContents: toc,
    images: images,
  );
}

EpubChapterData? _convertFb2SectionToChapter(String secXml, int index, Map<String, Uint8List> images) {
  String title = 'Chapter ${index + 1}';
  final titleMatch = RegExp(r'<title>([\s\S]*?)<\/title>', caseSensitive: false).firstMatch(secXml);
  String bodyXml = secXml;

  if (titleMatch != null) {
    final titleBlock = titleMatch.group(1)!;
    final cleanTitle = titleBlock.replaceAll(RegExp(r'<[^>]+>'), ' ').trim();
    if (cleanTitle.isNotEmpty) {
      title = cleanTitle;
    }
    bodyXml = bodyXml.replaceFirst(titleMatch.group(0)!, '');
  }

  final htmlContent = '<h2>$title</h2>\n${_cleanFb2XmlToHtml(bodyXml)}';
  final doc = html_parser.parse(htmlContent);
  final text = doc.body?.text.trim() ?? '';
  if (text.isEmpty && !htmlContent.contains('<img')) return null;

  return EpubChapterData(
    id: 'ch_$index',
    title: title,
    href: 'ch_$index.html',
    htmlContent: htmlContent,
    textPreview: text.length > 200 ? '${text.substring(0, 200)}...' : text,
    orderIndex: index,
    wordCount: text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length,
  );
}

String _cleanFb2XmlToHtml(String xml) {
  var s = xml;
  s = s.replaceAllMapped(RegExp(r'<image[^>]+(?:l:href|xlink:href|href)="([^"]+)"[^>]*\/?>', caseSensitive: false), (m) {
    final href = m.group(1)!;
    return '<p align="center"><img src="$href" /></p>';
  });

  s = s.replaceAll(RegExp(r'<empty-line\s*\/?>', caseSensitive: false), '<br/><br/>');
  s = s.replaceAll(RegExp(r'<subtitle>', caseSensitive: false), '<h3>');
  s = s.replaceAll(RegExp(r'<\/subtitle>', caseSensitive: false), '</h3>');
  s = s.replaceAll(RegExp(r'<(?:epigraph|cite)>', caseSensitive: false), '<blockquote>');
  s = s.replaceAll(RegExp(r'<\/(?:epigraph|cite)>', caseSensitive: false), '</blockquote>');
  s = s.replaceAll(RegExp(r'<\/?(?:poem|stanza)>', caseSensitive: false), '');
  s = s.replaceAll(RegExp(r'<v>', caseSensitive: false), '<p>');
  s = s.replaceAll(RegExp(r'<\/v>', caseSensitive: false), '</p>');

  return s;
}

// ============================================================================
// MOBI & AZW3 / KF8 PARSER (With PalmDOC LZ77 + HUFF/CDIC Decompression)
// ============================================================================

int _readUint16(Uint8List data, int offset) {
  if (offset + 2 > data.length) return 0;
  return (data[offset] << 8) | data[offset + 1];
}

int _readUint32(Uint8List data, int offset) {
  if (offset + 4 > data.length) return 0;
  return (data[offset] << 24) |
      (data[offset + 1] << 16) |
      (data[offset + 2] << 8) |
      data[offset + 3];
}

int _getMobiTrailingBytesCount(Uint8List record, int flags) {
  int trim = 0;
  int pos = record.length - 1;

  if ((flags & 2) != 0) {
    int v = 0;
    for (int i = 0; i < 4 && pos >= 0; i++) {
      int b = record[pos--];
      v |= (b & 0x7F) << (i * 7);
      if ((b & 0x80) != 0) break;
    }
    trim += v;
  }

  if ((flags & 1) != 0) {
    trim += (record.isNotEmpty ? (record.last & 3) : 0);
  }

  if ((flags & 4) != 0) {
    trim += 2;
  }

  return trim.clamp(0, record.length);
}

Uint8List _decompressPalmDocRecord(Uint8List input, int extraFlags) {
  final trim = _getMobiTrailingBytesCount(input, extraFlags);
  final end = input.length - trim;
  if (end <= 0) return Uint8List(0);

  final output = BytesBuilder(copy: false);
  int i = 0;
  while (i < end) {
    final byte = input[i++];
    if (byte >= 1 && byte <= 8) {
      final take = byte;
      final actualTake = (i + take <= end) ? take : (end - i);
      if (actualTake > 0) {
        output.add(input.sublist(i, i + actualTake));
        i += actualTake;
      }
    } else if (byte <= 0x7F) {
      output.addByte(byte);
    } else if (byte >= 0xC0) {
      output.addByte(0x20);
      output.addByte(byte ^ 0x80);
    } else {
      if (i >= end) break;
      final byte2 = input[i++];
      final token = (byte << 8) | byte2;
      final offset = (token >> 3) & 0x07FF;
      final length = (token & 0x07) + 3;

      final current = output.toBytes();
      final start = current.length - offset;
      if (start >= 0) {
        for (int k = 0; k < length; k++) {
          final srcIdx = start + k;
          if (srcIdx >= 0 && srcIdx < current.length) {
            output.addByte(current[srcIdx]);
          } else {
            output.addByte(0x20);
          }
        }
      }
    }
  }
  return output.toBytes();
}

class _HuffCdicReader {
  final List<int> _table1 = List.filled(256, 0);
  final List<int> _minCodeTable = List.filled(33, 0);
  final List<int> _maxCodeTable = List.filled(33, 0);
  final List<Uint8List> _dictionary = [];

  _HuffCdicReader(Uint8List huffRecord, List<Uint8List> cdicRecords) {
    _parseHuff(huffRecord);
    for (final cdic in cdicRecords) {
      _parseCdic(cdic);
    }
  }

  void _parseHuff(Uint8List record) {
    final table1Offset = _readUint32(record, 8);
    final table2Offset = _readUint32(record, 12);

    for (int i = 0; i < 256; i++) {
      _table1[i] = _readUint32(record, table1Offset + (i * 4));
    }

    _minCodeTable[0] = 0;
    _maxCodeTable[0] = 0xFFFFFFFF;
    for (int i = 1; i <= 32; i++) {
      final off = table2Offset + ((i - 1) * 8);
      final minCode = _readUint32(record, off);
      final maxCode = _readUint32(record, off + 4);
      _minCodeTable[i] = (minCode << (32 - i)) & 0xFFFFFFFF;
      _maxCodeTable[i] = (((maxCode + 1) << (32 - i)) - 1) & 0xFFFFFFFF;
    }
  }

  void _parseCdic(Uint8List record) {
    final phrasesCount = _readUint32(record, 8);
    for (int i = 0; i < phrasesCount; i++) {
      final off = 16 + (i * 2);
      if (off + 2 <= record.length) {
        final phraseOff = _readUint16(record, off);
        final base = 16 + (phrasesCount * 2);
        final phrasePos = base + phraseOff;
        if (phrasePos + 2 <= record.length) {
          final phraseLen = _readUint16(record, phrasePos);
          final len = phraseLen & 0x7FFF;
          final isCompressed = (phraseLen & 0x8000) == 0;
          final start = phrasePos + 2;
          final end = math.min(start + len, record.length);
          if (start <= end) {
            final slice = record.sublist(start, end);
            final entry = Uint8List(slice.length + 1);
            entry[0] = isCompressed ? 1 : 0;
            entry.setRange(1, entry.length, slice);
            _dictionary.add(entry);
          }
        }
      }
    }
  }

  Uint8List decompress(Uint8List input, int extraFlags) {
    final trim = _getMobiTrailingBytesCount(input, extraFlags);
    final validEnd = input.length - trim;
    if (validEnd <= 0) return Uint8List(0);
    final slice = input.sublist(0, validEnd);

    final output = BytesBuilder(copy: false);
    _unpack(slice, output, 0);
    return output.toBytes();
  }

  void _unpack(Uint8List input, BytesBuilder output, int depth) {
    if (depth > 32) return;
    int bitPos = 0;
    final totalBits = input.length * 8;

    while (bitPos < totalBits) {
      int bits = 0;
      final byteOffset = bitPos ~/ 8;
      final bitOffset = bitPos % 8;

      for (int i = 0; i < 4; i++) {
        final idx = byteOffset + i;
        final b = (idx < input.length) ? input[idx] : 0;
        bits = (bits << 8) | b;
      }
      bits = ((bits << bitOffset) & 0xFFFFFFFF);

      int codeLen = 0;
      int code = 0;
      for (int len = 1; len <= 32; len++) {
        if (bits <= _maxCodeTable[len]) {
          codeLen = len;
          code = _table1[len - 1] + ((bits - _minCodeTable[len]) >> (32 - len));
          break;
        }
      }

      if (codeLen == 0 || bitPos + codeLen > totalBits) break;
      bitPos += codeLen;

      if (code >= 0 && code < _dictionary.length) {
        final entry = _dictionary[code];
        final isCompressed = entry[0] == 1;
        final slice = entry.sublist(1);
        if (isCompressed) {
          _unpack(slice, output, depth + 1);
        } else {
          output.add(slice);
        }
      }
    }
  }
}

EpubBookData _parseMobiSync(Uint8List bytes, String fileName) {
  String title = p.basenameWithoutExtension(fileName).replaceAll(RegExp(r'[_\-]+'), ' ');
  String author = 'Kindle Author';
  final images = <String, Uint8List>{};
  Uint8List? coverBytes;

  if (bytes.length < 80) {
    return _parseLegacyFallbackSync(bytes, fileName, 'mobi');
  }

  final numRecords = _readUint16(bytes, 76);
  final recordOffsets = <int>[];
  for (int i = 0; i < numRecords; i++) {
    recordOffsets.add(_readUint32(bytes, 78 + (i * 8)));
  }

  if (recordOffsets.isEmpty) {
    return _parseLegacyFallbackSync(bytes, fileName, 'mobi');
  }

  // Record 0
  final r0Offset = recordOffsets[0];
  final r0End = (recordOffsets.length > 1) ? recordOffsets[1] : bytes.length;
  final r0 = bytes.sublist(r0Offset, r0End);

  final compression = _readUint16(r0, 0);
  final textRecordCount = _readUint16(r0, 8);

  int extraFlags = 0;
  if (r0.length > 242) {
    extraFlags = _readUint16(r0, 242);
  }

  if (r0.length > 88) {
    final titleOffset = _readUint32(r0, 84);
    final titleLen = _readUint32(r0, 88);
    if (titleOffset + titleLen <= r0.length && titleLen > 0) {
      title = utf8.decode(r0.sublist(titleOffset, titleOffset + titleLen), allowMalformed: true).trim();
    }
  }

  int firstImageIndex = numRecords;
  int huffIndex = 0;
  int huffCount = 0;

  if (r0.length > 112) {
    firstImageIndex = _readUint32(r0, 108);
  }
  if (r0.length > 120) {
    huffIndex = _readUint32(r0, 112);
    huffCount = _readUint32(r0, 116);
  }

  if (firstImageIndex < numRecords) {
    int imgCounter = 1;
    for (int rIdx = firstImageIndex; rIdx < numRecords; rIdx++) {
      final start = recordOffsets[rIdx];
      final end = (rIdx + 1 < recordOffsets.length) ? recordOffsets[rIdx + 1] : bytes.length;
      final recData = bytes.sublist(start, end);

      if (recData.length > 4) {
        final isJpg = recData[0] == 0xFF && recData[1] == 0xD8;
        final isPng = recData[0] == 0x89 && recData[1] == 0x50;
        final isGif = recData[0] == 0x47 && recData[1] == 0x49;

        if (isJpg || isPng || isGif) {
          final strIdx = imgCounter.toString().padLeft(4, '0');
          final strIdx5 = imgCounter.toString().padLeft(5, '0');
          images['$imgCounter'] = recData;
          images[strIdx] = recData;
          images[strIdx5] = recData;
          images['kindle:embed:$strIdx?mime=image/jpg'] = recData;
          images['kindle:embed:$strIdx?mime=image/png'] = recData;
          images['recindex="$strIdx"'] = recData;
          images['recindex="$strIdx5"'] = recData;

          if (imgCounter == 1 && coverBytes == null) {
            coverBytes = recData;
          }
          imgCounter++;
        }
      }
    }
  }

  final fullTextBuilder = BytesBuilder();

  if (compression == 17480 && huffIndex > 0 && huffCount > 1 && huffIndex + huffCount <= recordOffsets.length) {
    try {
      final huffRec = bytes.sublist(recordOffsets[huffIndex], (huffIndex + 1 < recordOffsets.length) ? recordOffsets[huffIndex + 1] : bytes.length);
      final cdicRecs = <Uint8List>[];
      for (int c = 1; c < huffCount; c++) {
        final cIdx = huffIndex + c;
        cdicRecs.add(bytes.sublist(recordOffsets[cIdx], (cIdx + 1 < recordOffsets.length) ? recordOffsets[cIdx + 1] : bytes.length));
      }

      final huffReader = _HuffCdicReader(huffRec, cdicRecs);
      for (int i = 1; i <= textRecordCount && i < recordOffsets.length; i++) {
        final start = recordOffsets[i];
        final end = (i + 1 < recordOffsets.length) ? recordOffsets[i + 1] : bytes.length;
        final rec = bytes.sublist(start, end);
        final decompressed = huffReader.decompress(rec, extraFlags);
        fullTextBuilder.add(decompressed);
      }
    } catch (_) {}
  } else {
    for (int i = 1; i <= textRecordCount && i < recordOffsets.length; i++) {
      final start = recordOffsets[i];
      final end = (i + 1 < recordOffsets.length) ? recordOffsets[i + 1] : bytes.length;
      final rec = bytes.sublist(start, end);

      if (compression == 1) {
        final trim = _getMobiTrailingBytesCount(rec, extraFlags);
        final validEnd = rec.length - trim;
        if (validEnd > 0) fullTextBuilder.add(rec.sublist(0, validEnd));
      } else if (compression == 2) {
        final decompressed = _decompressPalmDocRecord(rec, extraFlags);
        fullTextBuilder.add(decompressed);
      } else {
        fullTextBuilder.add(rec);
      }
    }
  }

  final fullHtml = utf8.decode(fullTextBuilder.toBytes(), allowMalformed: true);

  final chapters = <EpubChapterData>[];
  final toc = <EpubTocItem>[];

  final rawChapters = fullHtml
      .split(RegExp(r'<mbp:pagebreak\s*\/?>|<div[^>]+class="[^"]*chapter[^"]*"[^>]*>', caseSensitive: false));

  if (rawChapters.length > 1) {
    for (int idx = 0; idx < rawChapters.length; idx++) {
      final chHtml = rawChapters[idx].trim();
      if (chHtml.isEmpty || chHtml == '</div>') continue;

      final doc = html_parser.parse(chHtml);
      final h1 = doc.querySelector('h1, h2, h3, title, b');
      final chTitle = (h1 != null && h1.text.trim().isNotEmpty && h1.text.trim().length < 80)
          ? h1.text.trim()
          : 'Chapter ${chapters.length + 1}';

      final text = doc.body?.text.trim() ?? '';
      chapters.add(EpubChapterData(
        id: 'ch_${chapters.length}',
        title: chTitle,
        href: 'ch_${chapters.length}.html',
        htmlContent: chHtml,
        textPreview: text.length > 200 ? '${text.substring(0, 200)}...' : text,
        orderIndex: chapters.length,
        wordCount: text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length,
      ));
      toc.add(EpubTocItem(
        title: chTitle,
        contentSrc: 'ch_${chapters.length - 1}.html',
        chapterIndex: chapters.length - 1,
      ));
    }
  } else {
    final doc = html_parser.parse(fullHtml);
    final text = doc.body?.text.trim() ?? '';
    chapters.add(EpubChapterData(
      id: 'ch_0',
      title: title,
      href: 'ch_0.html',
      htmlContent: fullHtml,
      textPreview: text.length > 200 ? '${text.substring(0, 200)}...' : text,
      orderIndex: 0,
      wordCount: text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length,
    ));
    toc.add(EpubTocItem(title: title, contentSrc: 'ch_0.html', chapterIndex: 0));
  }

  return EpubBookData(
    title: title,
    author: author,
    coverBytes: coverBytes,
    chapters: chapters,
    tableOfContents: toc,
    images: images,
  );
}

// ============================================================================
// TXT PARSER
// ============================================================================

EpubBookData _parseTxtSync(Uint8List bytes, String fileName) {
  final text = utf8.decode(bytes, allowMalformed: true);
  final title = p.basenameWithoutExtension(fileName).replaceAll(RegExp(r'[_\-]+'), ' ');

  final chapterRegex = RegExp(r'^(?:Chapter|Section|Book|Part)\s+[0-9IVXLCDM]+', caseSensitive: false, multiLine: true);
  final matches = chapterRegex.allMatches(text).toList();

  final chapters = <EpubChapterData>[];
  final toc = <EpubTocItem>[];

  if (matches.length > 1) {
    for (int i = 0; i < matches.length; i++) {
      final start = matches[i].start;
      final end = (i + 1 < matches.length) ? matches[i + 1].start : text.length;
      final chunk = text.substring(start, end).trim();

      final lines = chunk.split('\n');
      final chTitle = lines.first.trim();
      final bodyText = lines.skip(1).join('\n\n');
      final paragraphs = bodyText.split(RegExp(r'\n\s*\n')).map((p) => '<p>${htmlEscape.convert(p.trim())}</p>').join('\n');
      final html = '<h2>${htmlEscape.convert(chTitle)}</h2>\n$paragraphs';

      chapters.add(EpubChapterData(
        id: 'ch_$i',
        title: chTitle,
        href: 'ch_$i.html',
        htmlContent: html,
        textPreview: chunk.length > 200 ? '${chunk.substring(0, 200)}...' : chunk,
        orderIndex: i,
        wordCount: chunk.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length,
      ));
      toc.add(EpubTocItem(title: chTitle, contentSrc: 'ch_$i.html', chapterIndex: i));
    }
  } else {
    final paragraphs = text.split(RegExp(r'\n\s*\n')).map((p) => '<p>${htmlEscape.convert(p.trim())}</p>').join('\n');
    final html = '<h1>${htmlEscape.convert(title)}</h1>\n$paragraphs';
    chapters.add(EpubChapterData(
      id: 'ch_0',
      title: title,
      href: 'ch_0.html',
      htmlContent: html,
      textPreview: text.length > 200 ? '${text.substring(0, 200)}...' : text,
      orderIndex: 0,
      wordCount: text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length,
    ));
    toc.add(EpubTocItem(title: title, contentSrc: 'ch_0.html', chapterIndex: 0));
  }

  return EpubBookData(
    title: title,
    author: 'Unknown Author',
    chapters: chapters,
    tableOfContents: toc,
    images: const {},
  );
}

// ============================================================================
// COMIC (CBZ / CBR) PARSER
// ============================================================================

List<Uint8List> _extractRawComicImages(Uint8List bytes) {
  final images = <Uint8List>[];
  int i = 0;
  while (i < bytes.length - 4) {
    if (bytes[i] == 0xFF && bytes[i + 1] == 0xD8 && bytes[i + 2] == 0xFF) {
      final start = i;
      int j = start + 2;
      while (j < bytes.length - 1) {
        if (bytes[j] == 0xFF && bytes[j + 1] == 0xD9) {
          final end = j + 2;
          final imgLen = end - start;
          if (imgLen >= 1024) {
            images.add(bytes.sublist(start, end));
            i = end;
            break;
          }
        }
        j++;
      }
      if (j >= bytes.length - 1) i += 2;
    } else if (bytes[i] == 0x89 && bytes[i + 1] == 0x50 && bytes[i + 2] == 0x4E && bytes[i + 3] == 0x47) {
      final start = i;
      int j = start + 8;
      while (j < bytes.length - 8) {
        if (bytes[j] == 0x49 && bytes[j + 1] == 0x45 && bytes[j + 2] == 0x4E && bytes[j + 3] == 0x44) {
          final end = j + 8;
          final imgLen = end - start;
          if (imgLen >= 1024) {
            images.add(bytes.sublist(start, end));
            i = end;
            break;
          }
        }
        j++;
      }
      if (j >= bytes.length - 8) i += 4;
    } else {
      i++;
    }
  }
  return images;
}

EpubBookData _parseComicSync(Uint8List bytes, String fileName) {
  final title = p.basenameWithoutExtension(fileName).replaceAll(RegExp(r'[_\-]+'), ' ');
  final images = <String, Uint8List>{};
  final chapters = <EpubChapterData>[];
  final toc = <EpubTocItem>[];
  Uint8List? coverBytes;

  final rawPages = <Uint8List>[];

  // 1. Try Zip decoding (CBZ)
  if (bytes.length > 4 && bytes[0] == 0x50 && bytes[1] == 0x4B) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes, verify: false);
      final imageFiles = archive.files.where((f) {
        final lower = f.name.toLowerCase();
        return lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png') || lower.endsWith('.webp');
      }).toList();
      imageFiles.sort((a, b) => a.name.compareTo(b.name));
      for (final file in imageFiles) {
        rawPages.add(Uint8List.fromList(file.content as List<int>));
      }
    } catch (_) {}
  }

  // 2. Try RAR decoding (CBR)
  if (rawPages.isEmpty && bytes.length > 7 && bytes[0] == 0x52 && bytes[1] == 0x61 && bytes[2] == 0x72) {
    try {
      int pos = 7;
      final rarFiles = <String, Uint8List>{};
      while (pos + 7 <= bytes.length) {
        final headType = bytes[pos + 2];
        final headFlags = _readUint16(bytes, pos + 3);
        final headSize = _readUint16(bytes, pos + 5);

        if (headSize < 7 || pos + headSize > bytes.length) break;

        if (headType == 0x74) {
          final packSize = _readUint32(bytes, pos + 7);
          final nameSize = _readUint16(bytes, pos + 26);
          int nameOffset = pos + 32;
          if (nameOffset + nameSize <= pos + headSize) {
            final filename = utf8.decode(bytes.sublist(nameOffset, nameOffset + nameSize), allowMalformed: true);
            final dataOffset = pos + headSize;
            if (dataOffset + packSize <= bytes.length && packSize > 0) {
              final fileBytes = bytes.sublist(dataOffset, dataOffset + packSize);
              final lower = filename.toLowerCase();
              if (lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png') || lower.endsWith('.webp')) {
                rarFiles[filename] = fileBytes;
              }
            }
          }
          pos += headSize + packSize;
        } else {
          int addSize = 0;
          if ((headFlags & 0x8000) != 0 && pos + 11 <= bytes.length) {
            addSize = _readUint32(bytes, pos + 7);
          }
          pos += headSize + addSize;
        }
      }
      final sortedKeys = rarFiles.keys.toList()..sort();
      for (final k in sortedKeys) {
        rawPages.add(rarFiles[k]!);
      }
    } catch (_) {}
  }

  // 3. Fallback: extract images from raw byte stream
  if (rawPages.isEmpty) {
    rawPages.addAll(_extractRawComicImages(bytes));
  }

  for (int i = 0; i < rawPages.length; i++) {
    final imgBytes = rawPages[i];
    final key = 'page_$i.jpg';
    images[key] = imgBytes;
    if (i == 0) coverBytes = imgBytes;

    final html = '<div align="center"><img src="$key" style="max-width: 100%; border-radius: 8px;" /></div>';
    final pageTitle = 'Page ${i + 1}';

    chapters.add(EpubChapterData(
      id: 'page_$i',
      title: pageTitle,
      href: '$key.html',
      htmlContent: html,
      textPreview: pageTitle,
      orderIndex: i,
      wordCount: 0,
    ));
    toc.add(EpubTocItem(title: pageTitle, contentSrc: '$key.html', chapterIndex: i));
  }

  if (chapters.isEmpty) {
    final html = '<div align="center"><h2>$title</h2><p>No comic pages found in this archive.</p></div>';
    chapters.add(EpubChapterData(
      id: 'page_0',
      title: title,
      href: 'page_0.html',
      htmlContent: html,
      textPreview: title,
      orderIndex: 0,
      wordCount: 0,
    ));
    toc.add(EpubTocItem(title: title, contentSrc: 'page_0.html', chapterIndex: 0));
  }

  return EpubBookData(
    title: title,
    author: 'Comic Book',
    coverBytes: coverBytes,
    chapters: chapters,
    tableOfContents: toc,
    images: images,
  );
}

// ============================================================================
// LEGACY FORMAT FALLBACK PARSER (LIT, LRF, ETC.)
// ============================================================================

bool _isLegitimateTextLine(String line) {
  final trimmed = line.trim();
  if (trimmed.length < 8) return false;

  if (trimmed.startsWith('/data/') ||
      trimmed.startsWith('::DataSpace') ||
      trimmed.startsWith('ITOL') ||
      trimmed.startsWith('JFIF') ||
      trimmed.startsWith('Transform') ||
      trimmed.startsWith('generatorR') ||
      trimmed.startsWith('calibre_pb_') ||
      trimmed.startsWith('rwver-')) {
    return false;
  }

  int weirdSymbols = 0;
  for (int i = 0; i < trimmed.length; i++) {
    final code = trimmed.codeUnitAt(i);
    final isGood = (code >= 65 && code <= 90) ||
        (code >= 97 && code <= 122) ||
        (code >= 48 && code <= 57) ||
        code == 32 ||
        code == 44 || code == 46 || code == 33 || code == 63 ||
        code == 39 || code == 34 || code == 45 || code == 58 || code == 59;
    if (!isGood) {
      weirdSymbols++;
    }
  }

  if (weirdSymbols > 0 && (weirdSymbols / trimmed.length) > 0.12) {
    return false;
  }

  final words = trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.length < 3) return false;

  int realWords = 0;
  for (final w in words) {
    final alphaOnly = w.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    if (alphaOnly.length >= 2 && alphaOnly.length <= 20) {
      realWords++;
    }
  }

  return (realWords / words.length) >= 0.7;
}

EpubBookData _parseLegacyFallbackSync(Uint8List bytes, String fileName, String fmt) {
  final title = p.basenameWithoutExtension(fileName).replaceAll(RegExp(r'[_\-]+'), ' ');

  // Extract readable text chunks
  final chunks = <String>[];
  final buffer = StringBuffer();

  for (int i = 0; i < bytes.length; i++) {
    final b = bytes[i];
    if (b == 0x0A || b == 0x0D || (b >= 0x20 && b <= 0x7E)) {
      buffer.writeCharCode(b);
    } else {
      if (buffer.length >= 20) {
        chunks.add(buffer.toString());
      }
      buffer.clear();
    }
  }
  if (buffer.length >= 20) {
    chunks.add(buffer.toString());
  }

  final validParagraphs = <String>[];
  for (final chunk in chunks) {
    final lines = chunk.split(RegExp(r'[\r\n]+'));
    for (final line in lines) {
      if (_isLegitimateTextLine(line)) {
        validParagraphs.add(line.trim());
      }
    }
  }

  String html;
  if (validParagraphs.length >= 5) {
    final pTags = validParagraphs.map((p) => '<p>${htmlEscape.convert(p)}</p>').join('\n');
    html = '<h1>${htmlEscape.convert(title)}</h1>\n$pTags';
  } else {
    // Legacy format notice
    html = '''
<div align="center" style="padding: 32px 16px;">
  <h2>${htmlEscape.convert(title)}</h2>
  <br/>
  <div style="background: rgba(255, 255, 255, 0.08); border-radius: 12px; padding: 24px; text-align: left; max-width: 550px;">
    <h3 style="margin-top: 0;">📖 Legacy Format (${fmt.toUpperCase()})</h3>
    <p>This file is in the obsolete <strong>${fmt.toUpperCase()}</strong> format (${fmt == 'lrf' ? 'Sony BBeB' : 'Microsoft Reader'}), which uses proprietary encrypted DRM.</p>
    <p>For the best reading experience with full formatting, chapters, and illustrations, please download this book in <strong>EPUB</strong>, <strong>PDF</strong>, <strong>MOBI</strong>, <strong>AZW3</strong>, or <strong>FB2</strong> format from the catalog.</p>
  </div>
</div>
''';
  }

  final chapters = [
    EpubChapterData(
      id: 'ch_0',
      title: title,
      href: 'ch_0.html',
      htmlContent: html,
      textPreview: title,
      orderIndex: 0,
      wordCount: validParagraphs.length * 15,
    )
  ];

  return EpubBookData(
    title: title,
    author: 'Unknown Author',
    chapters: chapters,
    tableOfContents: [EpubTocItem(title: title, contentSrc: 'ch_0.html', chapterIndex: 0)],
    images: const {},
  );
}
