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
              logo: 'images/gsoc-sun.svg',
              label: 'GSoC Project',
              href: gsocProjectUrl,
            ),
            _ExternalSiteLinkEntry(
              logo: 'images/github-mark.svg',
              label: 'GitHub',
              href: githubUrl,
            ),
            _ExternalSiteLinkEntry(
              logo: 'https://wiki.automotivelinux.org/_media/wiki/logo.png',
              logoWide: true,
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
    required this.label,
    required this.logo,
    this.logoWide = false,
  });

  final String href;
  final String label;
  final String logo;
  final bool logoWide;

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
            span(classes: logoWide ? 'external-site-logo-frame wide-logo' : 'external-site-logo-frame', [
              img(
                src: logo,
                alt: '',
                classes: 'external-site-logo',
                attributes: {'aria-hidden': 'true'},
              ),
            ]),
            span([.text(label)]),
          ],
        ),
      ],
    );
  }
}
