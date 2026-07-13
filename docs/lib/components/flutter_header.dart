import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';

import 'brand_logo.dart';
import 'flutter_menu_toggle.dart';
import 'flutter_site_switcher.dart';
import 'flutter_theme_switcher.dart';
import 'header_controls.dart';
import 'toc_scroll_spy.dart';

/// The Flutter docs style site-wide top navigation bar.
class FlutterDocsHeader extends StatelessComponent {
  const FlutterDocsHeader({super.key});

  @override
  Component build(BuildContext context) {
    final pageUrlPath = context.page.url;
    final activeEntry = _activeNavEntry(pageUrlPath);

    return .fragment([
      Document.head(
        children: [
          const link(
            rel: 'preconnect',
            href: 'https://fonts.googleapis.com',
          ),
          const link(
            rel: 'preconnect',
            href: 'https://fonts.gstatic.com',
            attributes: {'crossorigin': ''},
          ),
          const link(
            rel: 'stylesheet',
            href:
                'https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,400,0..1,0&display=block',
          ),
          const link(
            rel: 'stylesheet',
            href: 'styles/flutter_header.css',
          ),
          .element(
            tag: 'style',
            children: [
              .text(r'''
.mermaid,
pre.mermaid {
  background: #ffffff !important;
  border: 1px solid #d8dee9 !important;
  border-radius: 12px;
  color: #111827 !important;
  overflow-x: auto;
  padding: 1rem;
}

.mermaid svg {
  display: block;
  height: auto;
  max-width: 100%;
}

.mermaid svg text,
.mermaid .messageText,
.mermaid .label,
.mermaid .loopText,
.mermaid .noteText,
.mermaid .actor,
.mermaid .sequenceNumber {
  fill: #111827 !important;
  color: #111827 !important;
}

.mermaid .actor-line,
.mermaid .messageLine0,
.mermaid .messageLine1 {
  stroke: #6d28d9 !important;
}
'''),
            ],
          ),
          script(
            id: 'mermaid-renderer',
            attributes: {'type': 'module'},
            content: r'''
import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';

mermaid.initialize({
  startOnLoad: false,
  securityLevel: 'loose',
  theme: 'base',
  themeVariables: {
    background: '#ffffff',
    mainBkg: '#eef2ff',
    primaryColor: '#eef2ff',
    primaryBorderColor: '#7c3aed',
    primaryTextColor: '#111827',
    secondaryColor: '#fef3c7',
    tertiaryColor: '#f8fafc',
    lineColor: '#6d28d9',
    textColor: '#111827',
    actorBkg: '#eef2ff',
    actorBorder: '#7c3aed',
    actorTextColor: '#111827',
    actorLineColor: '#7c3aed',
    signalColor: '#374151',
    signalTextColor: '#111827',
    noteBkgColor: '#fef3c7',
    noteBorderColor: '#d97706',
    noteTextColor: '#111827',
    labelTextColor: '#111827',
    loopTextColor: '#111827',
    sequenceNumberColor: '#ffffff',
  },
  themeCSS: `
    .label,
    .messageText,
    .loopText,
    .noteText,
    .actor,
    text {
      fill: #111827 !important;
      color: #111827 !important;
    }
  `,
});

document.querySelectorAll('pre > code.language-mermaid').forEach((code) => {
  const container = document.createElement('div');
  container.className = 'mermaid';
  container.textContent = code.textContent;
  code.parentElement.replaceWith(container);
});

await mermaid.run({querySelector: '.mermaid'});
''',
          ),
        ],
      ),
      header(id: 'site-header', [
        nav(classes: 'navbar', [
          const BrandLogo(
            classes: 'site-wordmark',
            id: 'site-primary-logo',
            size: 28,
            spanClasses: 'name',
          ),
          ul(classes: 'nav-items', [
            _NavItem(
              href: './',
              label: 'Home',
              isActive: activeEntry == _ActiveNavEntry.home,
            ),
            _NavItem(
              href: 'guide/verify-bluez',
              label: 'Guides',
              isActive: activeEntry == _ActiveNavEntry.guides,
            ),
            _NavItem(
              href: 'journal',
              label: 'Journal',
              isActive: activeEntry == _ActiveNavEntry.journal,
            ),
          ]),
          div(
            classes: 'navbar-contents',
            [
              const form(
                action: 'search',
                id: 'header-search',
                attributes: {'role': 'search'},
                [
                  input(
                    classes: 'search-field',
                    type: InputType.search,
                    name: 'q',
                    id: 'q',
                    attributes: {
                      'autocomplete': 'off',
                      'placeholder': 'Search',
                      'aria-label': 'Search',
                    },
                  ),
                ],
              ),
              const a(
                id: 'fallback-search-button',
                classes: 'icon-button',
                href: 'search',
                attributes: {
                  'title': "Navigate to JianDe's GSoC 2026 search page.",
                  'aria-label': "Navigate to JianDe's GSoC 2026 search page.",
                },
                [
                  MaterialIcon('search'),
                ],
              ),
              const FlutterThemeSwitcher(),
              const FlutterSiteSwitcher(),
              const FlutterMenuToggle(),
            ],
          ),
        ]),
      ]),
      const TocScrollSpy(),
    ]);
  }
}

class _NavItem extends StatelessComponent {
  const _NavItem({
    required this.href,
    required this.label,
    this.isActive = false,
  });

  final String href;
  final String label;
  final bool isActive;

  @override
  Component build(BuildContext context) {
    return li([
      a(
        href: href,
        classes: [
          'nav-link',
          'text-button',
          if (isActive) 'active',
        ].join(' '),
        [.text(label)],
      ),
    ]);
  }
}

_ActiveNavEntry? _activeNavEntry(String pageUrlPath) {
  final normalizedPath = pageUrlPath.toLowerCase();

  if (normalizedPath == '/') {
    return _ActiveNavEntry.home;
  }
  if (normalizedPath.startsWith('/guide/')) {
    return _ActiveNavEntry.guides;
  }
  if (normalizedPath == '/journal' || normalizedPath.startsWith('/journal/')) {
    return _ActiveNavEntry.journal;
  }

  return null;
}

enum _ActiveNavEntry {
  home,
  guides,
  journal,
}
