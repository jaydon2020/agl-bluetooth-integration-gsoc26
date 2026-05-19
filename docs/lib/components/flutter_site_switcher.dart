import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'constants.dart';
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
            _ExternalSiteLinkEntry(
              icon: 'school',
              label: 'GSoC Project',
              href: gsocProjectUrl,
            ),
            _ExternalSiteLinkEntry(
              icon: 'code',
              label: 'GitHub',
              href: githubUrl,
            ),
            _ExternalSiteLinkEntry(
              icon: 'directions_car',
              label: 'AGL Linux',
              href: aglLinuxUrl,
            ),
          ]),
        ],
      ),
    );
  }
}

class _ExternalSiteLinkEntry extends StatelessComponent {
  const _ExternalSiteLinkEntry({
    required this.href,
    required this.icon,
    required this.label,
  });

  final String href;
  final String icon;
  final String label;

  @override
  Component build(BuildContext context) {
    return li(
      attributes: {'role': 'presentation'},
      [
        a(
          href: href,
          classes: 'external-site-link',
          attributes: {
            'role': 'menuitem',
            'target': '_blank',
            'rel': 'noopener',
            'title': 'Open $label.',
            'aria-label': 'Open $label.',
          },
          [
            MaterialIcon(icon, classes: const ['external-site-icon']),
            span([.text(label)]),
          ],
        ),
      ],
    );
  }
}
