import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';

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
            href: '/styles/flutter_header.css',
          ),
        ],
      ),
      header(id: 'site-header', [
        nav(classes: 'navbar', [
          const a(
            id: 'site-primary-logo',
            classes: 'site-wordmark',
            href: '/',
            attributes: {
              'aria-label': 'Go to the Flutter docs homepage.',
              'title': 'Go to the Flutter docs homepage.',
            },
            [
              img(
                src: '/assets/images/branding/flutter/logo/default.svg',
                alt: 'Flutter logo',
                attributes: {'width': '28'},
              ),
              span(
                classes: 'name',
                attributes: {'translate': 'no'},
                [.text('Flutter')],
              ),
              span(
                classes: 'subtype',
                [.text('Docs')],
              ),
            ],
          ),
          ul(classes: 'nav-items', [
            _NavItem(
              href: '/',
              label: 'Home',
              isActive: activeEntry == _ActiveNavEntry.home,
            ),
            _NavItem(
              href: '/learn',
              label: 'Learn',
              isActive: activeEntry == _ActiveNavEntry.learn,
            ),
            const _NavItem(
              href: 'https://api.flutter.dev',
              label: 'Reference',
            ),
          ]),
          div(
            classes: 'navbar-contents',
            [
              const form(
                action: '/search/',
                id: 'header-search',
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
                href: '/search',
                attributes: {
                  'aria-label': 'Navigate to the docs.flutter.dev search page.',
                  'title': 'Navigate to the docs.flutter.dev search page.',
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

_ActiveNavEntry _activeNavEntry(String pageUrlPath) {
  String? firstFragment;
  for (final fragment in pageUrlPath.split('/')) {
    final trimmed = fragment.trim();
    if (trimmed.isNotEmpty) {
      firstFragment = trimmed.toLowerCase();
      break;
    }
  }

  return switch (firstFragment) {
    'learn' || 'tutorial' => _ActiveNavEntry.learn,
    _ => _ActiveNavEntry.home,
  };
}

enum _ActiveNavEntry {
  home,
  learn,
}
