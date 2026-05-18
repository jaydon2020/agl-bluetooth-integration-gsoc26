import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import 'header_controls.dart';

@client
final class FlutterMenuToggle extends StatefulComponent {
  const FlutterMenuToggle({super.key});

  @override
  State<FlutterMenuToggle> createState() => _FlutterMenuToggleState();
}

final class _FlutterMenuToggleState extends State<FlutterMenuToggle> {
  StreamSubscription<void>? _closeSubscription;
  StreamSubscription<void>? _barrierSubscription;
  bool _open = false;

  @override
  void dispose() {
    unawaited(_closeSubscription?.cancel());
    unawaited(_barrierSubscription?.cancel());
    super.dispose();
  }

  void _close() {
    if (!kIsWeb) return;
    _closeSubscription?.cancel();
    _barrierSubscription?.cancel();
    web.document.querySelector('.sidebar-container')?.classList.remove('open');
    if (_open) {
      setState(() {
        _open = false;
      });
    }
  }

  void _toggle() {
    if (!kIsWeb) return;

    if (_open) {
      _close();
      return;
    }

    final sidebar = web.document.querySelector('.sidebar-container');
    sidebar?.classList.add('open');
    _closeSubscription = web.document.querySelector('.sidebar-close')?.onClick.listen((_) => _close());
    _barrierSubscription = web.document.querySelector('.sidebar-barrier')?.onClick.listen((_) => _close());

    setState(() {
      _open = true;
    });
  }

  @override
  Component build(BuildContext context) {
    return button(
      id: 'menu-toggle',
      classes: headerClasses(['icon-button', if (_open) 'open']),
      type: ButtonType.button,
      attributes: {
        'aria-controls': 'sidenav',
        'aria-label': 'Toggle navigation menu.',
        'title': 'Toggle navigation menu.',
      },
      onClick: _toggle,
      const [
        MaterialIcon('menu', classes: ['menu-closed']),
        MaterialIcon('close', classes: ['menu-open']),
      ],
    );
  }
}
