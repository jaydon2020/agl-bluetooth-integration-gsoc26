import 'dart:convert';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';

import 'site_search.dart';

class SearchIndex extends StatelessComponent {
  const SearchIndex({super.key});

  @override
  Component build(BuildContext context) {
    final entries = [
      for (final page in context.pages)
        if (_isSearchable(page.url))
          {
            'title': _pageTitle(page),
            'description': _pageDescription(page),
            'href': page.url,
            'body': _plainText(page.content),
          },
    ]..sort((a, b) => a['title']!.compareTo(b['title']!));

    return SiteSearch(indexJson: jsonEncode(entries));
  }
}

bool _isSearchable(String url) => url != '/search' && !url.endsWith('.xml');

String _pageTitle(Page page) {
  final title = page.data.page['title'];
  if (title is String && title.trim().isNotEmpty) return title.trim();
  if (page.url == '/') return 'Home';
  return page.url.split('/').where((part) => part.isNotEmpty).map(_titleCase).join(' / ');
}

String _pageDescription(Page page) {
  final description = page.data.page['description'];
  return description is String ? description.trim() : '';
}

String _titleCase(String value) {
  final words = value.replaceAll('-', ' ').split(RegExp(r'\s+'));
  return [
    for (final word in words)
      if (word.isNotEmpty) '${word.substring(0, 1).toUpperCase()}${word.substring(1)}',
  ].join(' ');
}

String _plainText(String content) {
  return content
      .replaceAll(RegExp(r'^---[\s\S]*?---', multiLine: true), ' ')
      .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll(RegExp(r'[#*_>`\[\]()]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
