import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

final class DartStyleFooter extends StatelessComponent {
  const DartStyleFooter({super.key});

  @override
  Component build(BuildContext context) {
    return footer(
      id: 'page-footer',
      attributes: {'data-nosnippet': 'true'},
      [
        div(classes: 'footer-section footer-main', [
          a(
            classes: 'brand',
            href: '/',
            attributes: {
              'aria-label': 'Go to the Flutter docs homepage.',
              'title': 'Flutter Docs',
            },
            [
              const img(
                src: '/assets/images/branding/flutter/logo/default.svg',
                alt: 'Flutter logo',
                attributes: {'width': '50', 'height': '50'},
              ),
              span([.text('Flutter Docs')]),
            ],
          ),
          div(classes: 'footer-social-links', [
            _SocialLink(
              href: 'https://github.com/flutter/flutter',
              title: 'Flutter on GitHub',
              icon: _SocialIcon.github,
            ),
            _SocialLink(
              href: 'https://bsky.app/profile/flutter.dev',
              title: 'Flutter on Bluesky',
              icon: _SocialIcon.bluesky,
            ),
            _SocialLink(
              href: 'https://x.com/flutterdev',
              title: 'Flutter on X',
              icon: _SocialIcon.x,
            ),
          ]),
        ]),
        div(classes: 'footer-section footer-tray', [
          div(classes: 'footer-licenses', [
            .text(
              'Except as otherwise noted, this site is licensed under a ',
            ),
            a(
              href: 'https://creativecommons.org/licenses/by/4.0/',
              attributes: {'target': '_blank', 'rel': 'noopener'},
              [.text('Creative Commons Attribution 4.0 International License,')],
            ),
            .text(' and code samples are licensed under the '),
            a(
              href: 'https://opensource.org/licenses/BSD-3-Clause',
              attributes: {'target': '_blank', 'rel': 'noopener'},
              [.text('3-Clause BSD License.')],
            ),
          ]),
          div(classes: 'footer-utility-links', [
            ul([
              li([
                a(
                  href: 'https://policies.google.com/terms',
                  attributes: {'target': '_blank', 'rel': 'noopener'},
                  [.text('Terms')],
                ),
              ]),
              li([
                a(
                  href: 'https://policies.google.com/privacy',
                  attributes: {'target': '_blank', 'rel': 'noopener'},
                  [.text('Privacy')],
                ),
              ]),
              li([
                a(
                  href: 'https://flutter.dev/security',
                  attributes: {'target': '_blank', 'rel': 'noopener'},
                  [.text('Security')],
                ),
              ]),
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

final class _SocialLink extends StatelessComponent {
  const _SocialLink({
    required this.href,
    required this.icon,
    required this.title,
  });

  final String href;
  final _SocialIcon icon;
  final String title;

  @override
  Component build(BuildContext context) {
    return a(
      href: href,
      attributes: {
        'target': '_blank',
        'rel': 'noopener',
        'title': title,
        'aria-label': title,
      },
      [
        _SocialSvg(icon),
      ],
    );
  }
}

final class _SocialSvg extends StatelessComponent {
  const _SocialSvg(this.icon);

  final _SocialIcon icon;

  @override
  Component build(BuildContext context) {
    return svg(
      attributes: {
        'viewBox': icon.viewBox,
        'aria-hidden': 'true',
        'focusable': 'false',
      },
      [
        path(
          [],
          d: icon.path,
          attributes: {'fill': 'currentColor'},
        ),
      ],
    );
  }
}

enum _SocialIcon {
  github(
    '0 0 16 16',
    'M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0016 8c0-4.42-3.58-8-8-8z',
  ),
  bluesky(
    '0 0 600 530',
    'm135.72 44.03c66.496 49.921 138.02 151.14 164.28 205.46 26.262-54.316 97.782-155.54 164.28-205.46 47.98-36.021 125.72-63.892 125.72 24.795 0 17.712-10.155 148.79-16.111 170.07-20.703 73.984-96.144 92.854-163.25 81.433 117.3 19.964 147.14 86.092 82.697 152.22-122.39 125.59-175.91-31.511-189.63-71.766-2.514-7.3797-3.6904-10.832-3.7077-7.8964-0.0174-2.9357-1.1937 0.51669-3.7077 7.8964-13.714 40.255-67.233 197.36-189.63 71.766-64.444-66.128-34.605-132.26 82.697-152.22-67.108 11.421-142.55-7.4491-163.25-81.433-5.9562-21.282-16.111-152.36-16.111-170.07 0-88.687 77.742-60.816 125.72-24.795z',
  ),
  x(
    '0 0 38 38',
    'M22.1175 16.0821 35.9526 0h-3.2785l-12.013 13.9639L11.0664 0H0l14.5091 21.1159L0 37.9805h3.27865L15.9647 23.2341l10.1327 14.7464h11.0664L22.1167 16.0821h.0008Zm-4.4906 5.2198-1.47-2.1026L4.46 2.46812h5.03582L18.9353 15.9707l1.4701 2.1027 12.2703 17.5512h-5.0359L17.6269 21.3027v-.0008Z',
  )
  ;

  const _SocialIcon(this.viewBox, this.path);

  final String path;
  final String viewBox;
}
