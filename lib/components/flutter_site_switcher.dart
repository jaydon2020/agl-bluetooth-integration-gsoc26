import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'header_controls.dart';

@client
final class FlutterSiteSwitcher extends StatelessComponent {
  const FlutterSiteSwitcher({super.key});

  @override
  Component build(BuildContext context) {
    return const Dropdown(
      id: 'site-switcher',
      toggle: HeaderButton(icon: 'apps', title: 'Visit related sites.'),
      content: nav(
        classes: 'dropdown-menu',
        attributes: {'role': 'menu'},
        [
          ul([
            _SiteWordMarkListEntry(
              name: 'Flutter',
              href: 'https://flutter.dev',
            ),
            _SiteWordMarkListEntry(
              name: 'Flutter',
              subtype: 'Docs',
              href: '/',
              current: true,
            ),
            _SiteWordMarkListEntry(
              name: 'Flutter',
              subtype: 'API',
              href: 'https://api.flutter.dev',
            ),
            _SiteWordMarkListEntry(
              name: 'Flutter',
              subtype: 'Blog',
              href: 'https://blog.flutter.dev',
            ),
            Component.element(
              tag: 'li',
              classes: 'dropdown-divider',
              attributes: {'aria-hidden': 'true', 'role': 'separator'},
            ),
            _SiteWordMarkListEntry(
              name: 'Dart',
              href: 'https://dart.dev',
              dart: true,
            ),
            _SiteWordMarkListEntry(
              name: 'DartPad',
              href: 'https://dartpad.dev',
              dart: true,
            ),
            _SiteWordMarkListEntry(
              name: 'pub.dev',
              href: 'https://pub.dev',
              dart: true,
            ),
          ]),
        ],
      ),
    );
  }
}

class _SiteWordMarkListEntry extends StatelessComponent {
  const _SiteWordMarkListEntry({
    required this.href,
    required this.name,
    this.subtype,
    this.current = false,
    this.dart = false,
  });

  final bool dart;
  final String href;
  final String name;
  final String? subtype;
  final bool current;

  String get _combinedName => '$name${subtype != null ? ' $subtype' : ''}';

  @override
  Component build(BuildContext context) {
    return li(
      attributes: {'role': 'presentation'},
      [
        a(
          href: href,
          classes: headerClasses([
            'site-wordmark',
            if (current) 'current-site',
          ]),
          attributes: {
            'role': 'menuitem',
            'title': 'Navigate to the $_combinedName website.',
            'aria-label': 'Navigate to the $_combinedName website.',
          },
          [
            if (dart)
              const img(
                src: '/assets/images/branding/dart/logo.svg',
                alt: 'Dart logo',
                attributes: {'width': '28', 'height': '28'},
              )
            else
              const img(
                src: '/assets/images/branding/flutter/logo/default.svg',
                alt: 'Flutter logo',
                attributes: {'width': '28'},
              ),
            span(
              classes: 'name',
              attributes: {'translate': 'no'},
              [.text(name)],
            ),
            if (subtype != null)
              span(
                classes: 'subtype',
                [.text(subtype!)],
              ),
          ],
        ),
      ],
    );
  }
}
