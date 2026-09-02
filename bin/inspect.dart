// ignore_for_file: avoid_print
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

const headers = {
  'User-Agent':
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
  'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
};

void main() async {
  await inspectSeries('https://weebcentral.com/series/01J76XYD7E91K8QP6CY0Y53900/Blue-Lock');
}

Future<void> inspectSeries(String seriesUrl) async {
  print('\n=== FETCHING SERIES PAGE: $seriesUrl ===');
  final res = await http.get(Uri.parse(seriesUrl), headers: headers);
  if (res.statusCode == 200) {
    final doc = html_parser.parse(res.body);
    print('Title: ${doc.query選取or('h1')?.text.trim()}');

    print('\n--- LEFT SIDEBAR METADATA ONLY ---');
    final leftSidebar = doc.querySelector('section.md\\:w-4\\/12') ?? doc.querySelector('section');
    if (leftSidebar != null) {
      final details = <String, List<String>>{};
      for (final li in leftSidebar.querySelectorAll('li, div.flex, div.grid')) {
        final strong = li.querySelector('strong, b, span.font-bold');
        if (strong == null) continue;
        final label = strong.text.trim().replaceAll(':', '').replaceAll('(s)', '').trim();
        if (label.isEmpty) continue;

        final links = li.querySelectorAll('a');
        List<String> values = [];
        if (links.isNotEmpty) {
          values = links.map((a) => a.text.trim()).where((t) => t.isNotEmpty).toList();
        } else {
          String t = li.text.trim();
          if (t.startsWith(strong.text.trim())) {
            t = t.substring(strong.text.trim().length).trim();
          }
          t = t.replaceAll(RegExp(r'^\s*:\s*'), '').trim();
          if (t.isNotEmpty) values = [t];
        }

        if (values.isNotEmpty && !details.containsKey(label)) {
          details[label] = values;
        }
      }

      print('PARSED METADATA FROM LEFT SIDEBAR:');
      details.forEach((k, v) => print('  - $k: $v'));
    }

    final seriesIdMatch = RegExp(r'/series/([A-Z0-9]{26})').firstMatch(seriesUrl);
    if (seriesIdMatch != null) {
      final seriesId = seriesIdMatch.group(1)!;
      await inspectChapters(seriesId);
    }
  } else {
    print('影集 page failed with status ${res.statusCode}');
  }
}

Future<void> inspectChapters(String seriesId) async {
  final url = 'https://weebcentral.com/series/$seriesId/full-chapter-list';
  print('\n=== FETCHING CHAPTER LIST: $url ===');
  final res = await http.get(Uri.parse(url), headers: headers);
  if (res.statusCode == 200) {
    final doc = html_parser.parse(res.body);
    final links = doc.querySelectorAll('a[href*="/chapters/"]');
    print('Found ${links.length} chapter links.');
    for (int i = 0; i < (links.length < 5 ? links.length : 5); i++) {
      final a = links[i];
      print('\n--- CHAPTER LINK #$i ---');
      print('Href: ${a.attributes['href']}');
      print('Full Outer HTML:\n${a.outerHtml}');
      print('Inner Text: "${a.text.trim().replaceAll(RegExp(r'\s+'), ' ')}"');
      final chapterSpan = a.querySelector('.grow > span:first-child') ?? a.querySelector('span:not([class*="link-info"]):not([class*="me-2"])');
      print('   -> PERFECT CHAPTER TEXT: "${chapterSpan?.text.trim()}"');
    }
  } else {
    print('Chapter list failed with status ${res.statusCode}');
  }
}
