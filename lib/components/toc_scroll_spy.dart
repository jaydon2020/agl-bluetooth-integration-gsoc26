import 'dart:async';

import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

@client
final class TocScrollSpy extends StatefulComponent {
  const TocScrollSpy({super.key});

  @override
  State<TocScrollSpy> createState() => _TocScrollSpyState();
}

final class _TocScrollSpyState extends State<TocScrollSpy> {
  StreamSubscription<web.Event>? _resizeSubscription;
  StreamSubscription<web.Event>? _scrollSubscription;

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) return;
    _scrollSubscription = web.EventStreamProviders.scrollEvent
        .forTarget(web.document)
        .listen((_) => _updateActiveItem());
    _resizeSubscription = web.EventStreamProviders.resizeEvent.forTarget(web.window).listen((_) => _updateActiveItem());
    Timer.run(_updateActiveItem);
  }

  @override
  void dispose() {
    unawaited(_scrollSubscription?.cancel());
    unawaited(_resizeSubscription?.cancel());
    super.dispose();
  }

  void _updateActiveItem() {
    if (!kIsWeb) return;

    final links = web.document.querySelectorAll('aside.toc a[href*="#"]');
    if (links.length == 0) return;

    web.Element? activeLink;
    final activationOffset = _headerHeight() + 24;

    for (var index = 0; index < links.length; index++) {
      final link = links.item(index) as web.HTMLAnchorElement?;
      if (link == null) continue;

      final href = link.getAttribute('href') ?? '';
      final fragmentIndex = href.indexOf('#');
      if (fragmentIndex < 0 || fragmentIndex == href.length - 1) continue;

      final id = Uri.decodeComponent(href.substring(fragmentIndex + 1));
      final heading = web.document.getElementById(id);
      if (heading == null) continue;

      final headingTop = heading.getBoundingClientRect().top;
      if (headingTop <= activationOffset) {
        activeLink = link;
      } else if (activeLink == null) {
        activeLink = link;
        break;
      } else {
        break;
      }
    }

    activeLink ??= links.item(0) as web.Element?;

    for (var index = 0; index < links.length; index++) {
      final link = links.item(index) as web.Element?;
      link?.closest('li')?.classList.remove('active');
    }

    activeLink?.closest('li')?.classList.add('active');
  }

  double _headerHeight() {
    final header = web.document.querySelector('#site-header');
    if (header == null) return 64;
    return header.getBoundingClientRect().height;
  }

  @override
  Component build(BuildContext context) => Component.empty();
}
