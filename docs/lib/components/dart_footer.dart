import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'brand_logo.dart';
import 'constants.dart';

final class DartStyleFooter extends StatelessComponent {
  const DartStyleFooter({super.key});

  @override
  Component build(BuildContext context) {
    return footer(
      id: 'page-footer',
      attributes: {'data-nosnippet': 'true'},
      [
        div(classes: 'footer-shell', [
          div(classes: 'footer-brand-panel', [
            const BrandLogo(
              classes: 'brand',
              size: 42,
            ),
            p([
              .text(
                'AGL Bluetooth Integration project portfolio for BlueZ, PipeWire, WirePlumber, C++ D-Bus, and Flutter.',
              ),
            ]),
          ]),
          nav(
            classes: 'footer-nav-panel',
            attributes: {'aria-label': 'Footer navigation'},
            [
              div(classes: 'footer-social-links', [
                const _FooterExternalLink(
                  href: gsocProjectUrl,
                  label: 'GSoC Project',
                ),
                const _FooterExternalLink(
                  href: githubUrl,
                  label: 'GitHub',
                ),
                const _FooterExternalLink(
                  href: aglLinuxUrl,
                  label: 'AGL Linux',
                ),
              ]),
              ul(classes: 'footer-utility-links', [
                li([
                  a(href: '/', [.text('Home')]),
                ]),
                li([
                  a(href: '/bluetooth/verify-bluez', [.text('Guides')]),
                ]),
                li([
                  a(href: '/journal', [.text('Journal')]),
                ]),
                li([
                  a(href: '/report/midterm', [.text('Report')]),
                ]),
              ]),
            ],
          ),
          div(classes: 'footer-legal-card', [
            p(classes: 'footer-licenses', [
              .text(
                "JianDe's GSoC26 project documentation for Google Summer of Code 2026. Except as otherwise noted, this site is licensed under a ",
              ),
              a(
                href: 'https://creativecommons.org/licenses/by/4.0/',
                attributes: {'target': '_blank', 'rel': 'noopener'},
                [.text('Creative Commons Attribution 4.0 International License')],
              ),
              .text(', and code samples are licensed under the '),
              a(
                href: 'https://opensource.org/licenses/BSD-3-Clause',
                attributes: {'target': '_blank', 'rel': 'noopener'},
                [.text('3-Clause BSD License')],
              ),
              .text('.'),
            ]),
            p(classes: 'footer-trademark-note', [
              .text('Program and organization logos are used for identification of the project context.'),
            ]),
            div(classes: 'footer-technology', [
              a(
                classes: 'jaspr-badge-link',
                href: 'https://jaspr.site',
                attributes: {
                  'target': '_blank',
                  'rel': 'noopener',
                  'title': 'This site is built with the Jaspr web framework for Dart.',
                },
                [
                  span([JasprBadge.light()]),
                  span([JasprBadge.lightTwoTone()]),
                ],
              ),
            ]),
          ]),
        ]),
      ],
    );
  }
}

final class _FooterExternalLink extends StatelessComponent {
  const _FooterExternalLink({
    required this.href,
    required this.label,
  });

  final String href;
  final String label;

  @override
  Component build(BuildContext context) {
    return a(
      href: href,
      attributes: {
        'target': '_blank',
        'rel': 'noopener',
        'title': label,
        'aria-label': label,
      },
      [
        .text(label),
      ],
    );
  }
}
