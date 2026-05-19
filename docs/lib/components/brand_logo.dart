import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

class BrandLogo extends StatelessComponent {
  const BrandLogo({
    required this.classes,
    this.id,
    required this.size,
    this.spanClasses,
    super.key,
  });

  final String classes;
  final String? id;
  final int size;
  final String? spanClasses;

  @override
  Component build(BuildContext context) {
    return a(
      id: id,
      classes: classes,
      href: './',
      attributes: {
        'aria-label': "Go to JianDe's GSoC26 home page.",
        'title': "JianDe's GSoC26",
      },
      [
        img(
          src: 'images/gsoc-sun.svg',
          alt: 'Google Summer of Code sun logo',
          attributes: {'width': size.toString()},
        ),
        span(
          classes: spanClasses,
          attributes: const {'translate': 'no'},
          [.text("JianDe's GSoC26")],
        ),
      ],
    );
  }
}
