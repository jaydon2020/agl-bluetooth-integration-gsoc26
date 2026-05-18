import 'dart:convert';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

@client
class SiteSearch extends StatefulComponent {
  const SiteSearch({
    required this.indexJson,
    super.key,
  });

  final String indexJson;

  @override
  State<SiteSearch> createState() => _SiteSearchState();
}

class _SiteSearchState extends State<SiteSearch> {
  late final List<_SearchEntry> _entries = _decodeEntries();
  String _query = '';

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) return;
    final search = web.window.location.search;
    if (search.length <= 1) return;
    _query = Uri.splitQueryString(search.substring(1))['q'] ?? '';
  }

  List<_SearchEntry> _decodeEntries() {
    final decoded = jsonDecode(component.indexJson) as List<dynamic>;
    return [
      for (final item in decoded.cast<Map<String, Object?>>())
        _SearchEntry(
          title: item['title']! as String,
          description: item['description'] as String? ?? '',
          href: item['href']! as String,
          body: item['body'] as String? ?? '',
        ),
    ];
  }

  List<_SearchEntry> get _results {
    final needle = _query.trim().toLowerCase();
    if (needle.isEmpty) return _entries;

    return [
      for (final entry in _entries)
        if (entry.matches(needle)) entry,
    ];
  }

  @override
  Component build(BuildContext context) {
    final results = _results;

    return section(classes: 'site-search', [
      div(classes: 'search-row', [
        div(classes: 'search-wrapper', [
          const span(
            classes: 'material-symbols leading-icon',
            attributes: {
              'aria-hidden': 'true',
              'translate': 'no',
            },
            [.text('search')],
          ),
          input(
            type: InputType.search,
            value: _query,
            attributes: {
              'placeholder': 'Search docs',
              'aria-label': 'Search docs',
              'autocomplete': 'off',
            },
            onInput: (value) {
              setState(() {
                _query = value as String;
              });
            },
          ),
        ]),
      ]),
      div(classes: 'search-summary', [
        .text(
          _query.trim().isEmpty
              ? 'Showing all pages'
              : '${results.length} result${results.length == 1 ? '' : 's'} for "$_query"',
        ),
      ]),
      if (results.isEmpty)
        div(classes: 'empty-search-results', [
          h2([.text('No results found')]),
          p([.text('Try a different search term.')]),
        ])
      else
        ul(classes: 'search-results', [
          for (final result in results)
            li([
              a(href: result.href, [
                span(classes: 'result-title', [.text(result.title)]),
                if (result.description.isNotEmpty)
                  span(
                    classes: 'result-description',
                    [.text(result.description)],
                  ),
              ]),
            ]),
        ]),
    ]);
  }
}

class _SearchEntry {
  const _SearchEntry({
    required this.title,
    required this.description,
    required this.href,
    required this.body,
  });

  final String title;
  final String description;
  final String href;
  final String body;

  bool matches(String query) {
    final haystack = '$title $description $href $body'.toLowerCase();
    return query.split(RegExp(r'\s+')).where((term) => term.isNotEmpty).every(haystack.contains);
  }
}
