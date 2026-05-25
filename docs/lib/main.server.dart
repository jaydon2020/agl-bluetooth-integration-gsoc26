/// The entrypoint for the **server** environment.
///
/// The [main] method will only be executed on the server during pre-rendering.
/// To run code on the client, check the `main.client.dart` file.
library;

import 'dart:io';

// Server-specific Jaspr import.
import 'package:jaspr/dom.dart' show Color;
import 'package:jaspr/server.dart';

import 'package:jaspr_content/components/callout.dart';
import 'package:jaspr_content/components/code_block.dart';
import 'package:jaspr_content/components/image.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_content/theme.dart';

import 'components/clicker.dart';
import 'components/dart_footer.dart';
import 'components/flutter_header.dart';
import 'components/profile_matrix.dart';
import 'components/project_dashboard.dart';
import 'components/project_sidebar.dart';
import 'components/search_index.dart';

// This file is generated automatically by Jaspr, do not remove or edit.
import 'main.server.options.dart';

void main() {
  // Initializes the server environment with the generated default options.
  Jaspr.initializeApp(
    options: defaultServerOptions,
  );

  // Starts the app.
  //
  // [ContentApp] spins up the content rendering pipeline from jaspr_content to render
  // your markdown files in the content/ directory to a beautiful documentation site.
  runApp(
    ContentApp(
      eagerlyLoadAllPages: true,
      // Enables mustache templating inside the markdown files.
      templateEngine: MustacheTemplateEngine(),
      parsers: [
        MarkdownParser(),
      ],
      extensions: [
        // Adds heading anchors to each heading.
        HeadingAnchorsExtension(),
        // Generates a table of contents for each page.
        TableOfContentsExtension(),
      ],
      components: [
        // The <Info> block and other callouts.
        Callout(),
        // Adds syntax highlighting to code blocks.
        CodeBlock(),
        // Adds a custom Jaspr component to be used as <Clicker/> in markdown.
        CustomComponent(
          pattern: 'Clicker',
          builder: (_, _, _) => Clicker(),
        ),
        CustomComponent(
          pattern: 'SearchIndex',
          builder: (_, _, _) => const SearchIndex(),
        ),
        CustomComponent(
          pattern: 'ProjectDashboard',
          builder: (_, _, _) => const ProjectDashboard(),
        ),
        CustomComponent(
          pattern: 'ProfileMatrix',
          builder: (_, _, _) => const ProfileMatrix(),
        ),
        // Adds zooming and caption support to images.
        Image(zoom: true),
      ],
      layouts: [
        // Out-of-the-box layout for documentation sites.
        DocsLayout(
          header: const FlutterDocsHeader(),
          footer: const DartStyleFooter(),
          sidebar: ProjectSidebar(
            links: const [
              ProjectSidebarEntry(text: "Home", href: './'),
            ],
            sections: _buildSidebarSections(),
          ),
        ),
      ],
      theme: ContentTheme(
        // Customizes the default theme colors.
        primary: const ThemeColor(Color('#00A63F'), dark: Color('#4ADE80')),
        background: ThemeColor(ThemeColors.slate.$50, dark: ThemeColors.zinc.$950),
        colors: [
          ContentColors.quoteBorders.apply(const Color('#00A63F')),
        ],
      ),
    ),
  );
}

List<ProjectSidebarSection> _buildSidebarSections() {
  return [
    ProjectSidebarSection(
      title: 'Guides',
      links: [
        _entryForPage(
          'content/bluetooth/overview.md',
          fallbackText: 'Architecture Overview',
          href: 'bluetooth/overview',
        ),
        _entryForPage(
          'content/bluetooth/verify-bluez.md',
          fallbackText: 'Verify BlueZ Stack',
          href: 'bluetooth/verify-bluez',
          children: _entriesForDirectory(
            'content/bluetooth/verify-bluez',
            routePrefix: 'bluetooth/verify-bluez',
            preferredOrder: const [
              'profile-gap',
              'profile-a2dp',
              'profile-hfp',
              'profile-pbap',
              'profile-map',
            ],
          ),
        ),
        _entryForPage(
          'content/bluetooth/remote-dbus.md',
          fallbackText: 'Remote D-Bus Inspection',
          href: 'bluetooth/remote-dbus',
        ),
      ],
    ),
    ProjectSidebarSection(
      title: 'Journal',
      links: [
        _entryForPage(
          'content/journal/index.md',
          fallbackText: 'Journal Overview',
          href: 'journal',
          children: _entriesForDirectory(
            'content/journal',
            routePrefix: 'journal',
            preferredOrder: const [
              'week-1',
            ],
          ),
        ),
      ],
    ),
    ProjectSidebarSection(
      title: 'Report',
      links: _entriesForDirectory(
        'content/report',
        routePrefix: 'report',
        preferredOrder: const [
          'midterm',
          'final',
        ],
      ),
    ),
  ];
}

List<ProjectSidebarEntry> _entriesForDirectory(
  String directoryPath, {
  required String routePrefix,
  List<String> preferredOrder = const [],
}) {
  final directory = Directory(directoryPath);
  if (!directory.existsSync()) return const [];

  final entries = directory
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.md'))
      .where((file) => !_basenameWithoutExtension(file.path).startsWith('_'))
      .where((file) => _basenameWithoutExtension(file.path) != 'index')
      .map((file) {
        final slug = _basenameWithoutExtension(file.path);
        return _entryForPage(
          file.path,
          fallbackText: _titleFromSlug(slug),
          href: '$routePrefix/$slug',
        );
      })
      .toList();

  entries.sort((a, b) {
    final aOrder = preferredOrder.indexOf(_lastSegment(a.href));
    final bOrder = preferredOrder.indexOf(_lastSegment(b.href));

    if (aOrder != -1 || bOrder != -1) {
      if (aOrder == -1) return 1;
      if (bOrder == -1) return -1;
      return aOrder.compareTo(bOrder);
    }

    return a.text.compareTo(b.text);
  });

  return entries;
}

ProjectSidebarEntry _entryForPage(
  String filePath, {
  required String fallbackText,
  required String href,
  List<ProjectSidebarEntry> children = const [],
}) {
  return ProjectSidebarEntry(
    text: _readFrontMatterTitle(filePath) ?? fallbackText,
    href: href,
    children: children,
  );
}

String? _readFrontMatterTitle(String filePath) {
  final file = File(filePath);
  if (!file.existsSync()) return null;

  final lines = file.readAsLinesSync();
  if (lines.isEmpty || lines.first.trim() != '---') return null;

  String? title;

  for (final line in lines.skip(1)) {
    if (line.trim() == '---') break;

    final match = RegExp(r'^(navTitle|title):\s*(.+)$').firstMatch(line);
    if (match != null) {
      final value = match.group(2)!.trim().replaceAll(RegExp(r'''^['"]|['"]$'''), '');
      if (match.group(1) == 'navTitle') return value;
      title = value;
    }
  }

  return title;
}

String _basenameWithoutExtension(String path) {
  final normalized = path.replaceAll(r'\', '/');
  final basename = normalized.split('/').last;
  final extensionIndex = basename.lastIndexOf('.');
  return extensionIndex == -1 ? basename : basename.substring(0, extensionIndex);
}

String _lastSegment(String href) {
  final normalized = href.endsWith('/') ? href.substring(0, href.length - 1) : href;
  return normalized.split('/').last;
}

String _titleFromSlug(String slug) {
  final words = slug.split('-').where((word) => word.isNotEmpty);
  return words.map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
}
