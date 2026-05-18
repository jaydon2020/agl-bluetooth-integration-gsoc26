import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

String headerClasses(Iterable<String?> classes) => classes.whereType<String>().where((c) => c.isNotEmpty).join(' ');

/// A Material Symbols icon rendered as a span element.
class MaterialIcon extends StatelessComponent {
  const MaterialIcon(
    this.id, {
    this.title,
    this.label,
    this.size,
    this.filled = false,
    this.classes = const [],
    super.key,
  });

  final String id;
  final String? title;
  final String? label;
  final String? size;
  final bool filled;
  final List<String> classes;

  @override
  Component build(BuildContext context) {
    final attributes = <String, String>{
      'translate': 'no',
      if (title != null) 'title': title!,
      if (size != null) 'style': 'font-size: $size;',
    };
    final labelToUse = label ?? title;
    if (labelToUse != null) {
      attributes['aria-label'] = labelToUse;
    } else {
      attributes['aria-hidden'] = 'true';
    }

    return span(
      classes: headerClasses([
        'material-symbols',
        if (filled) 'ms-filled',
        ...classes,
      ]),
      attributes: attributes,
      [.text(id)],
    );
  }
}

class HeaderButton extends StatelessComponent {
  const HeaderButton({
    this.icon,
    this.href,
    this.content,
    this.style = HeaderButtonStyle.text,
    this.id,
    this.attributes = const {},
    this.classes,
    this.disabled = false,
    this.title,
    this.onClick,
    super.key,
  }) : assert(content != null || icon != null);

  final String? content;
  final String? title;
  final HeaderButtonStyle style;
  final String? icon;
  final String? id;
  final String? href;
  final Map<String, String> attributes;
  final bool disabled;
  final List<String>? classes;
  final void Function()? onClick;

  @override
  Component build(BuildContext context) {
    final mergedAttributes = <String, String>{
      ...attributes,
      if (disabled) 'disabled': 'disabled',
      if (title != null) 'title': title!,
    };

    final mergedClasses = headerClasses([
      style.cssClass,
      if (icon != null && content == null) 'icon-button',
      ...?classes,
    ]);

    final children = <Component>[
      if (icon != null) MaterialIcon(icon!),
      if (content != null) .text(content!),
    ];

    if (href != null) {
      return a(
        id: id,
        href: href!,
        classes: mergedClasses,
        attributes: mergedAttributes,
        onClick: onClick,
        children,
      );
    }

    return button(
      id: id,
      classes: mergedClasses,
      attributes: mergedAttributes,
      onClick: onClick,
      children,
    );
  }
}

enum HeaderButtonStyle {
  filled,
  outlined,
  text
  ;

  String get cssClass => switch (this) {
    HeaderButtonStyle.filled => 'filled-button',
    HeaderButtonStyle.outlined => 'outlined-button',
    HeaderButtonStyle.text => 'text-button',
  };
}

final class GlobalEventListener extends StatefulComponent {
  const GlobalEventListener(
    this.child, {
    this.onClick,
    this.onKeyDown,
    this.onScroll,
    super.key,
  });

  final Component child;
  final void Function(web.MouseEvent)? onClick;
  final void Function(web.KeyboardEvent)? onKeyDown;
  final void Function(web.Event)? onScroll;

  @override
  State<GlobalEventListener> createState() => _GlobalEventListenerState();
}

class _GlobalEventListenerState extends State<GlobalEventListener> {
  StreamSubscription<web.MouseEvent>? _clickSubscription;
  StreamSubscription<web.KeyboardEvent>? _keyDownSubscription;
  StreamSubscription<web.Event>? _scrollSubscription;

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) return;
    if (component.onClick != null) {
      _clickSubscription = web.EventStreamProviders.clickEvent.forTarget(web.document).listen(component.onClick!);
    }
    if (component.onKeyDown != null) {
      _keyDownSubscription = web.EventStreamProviders.keyDownEvent.forTarget(web.document).listen(component.onKeyDown!);
    }
    if (component.onScroll != null) {
      _scrollSubscription = web.EventStreamProviders.scrollEvent.forTarget(web.document).listen(component.onScroll!);
    }
  }

  @override
  void dispose() {
    unawaited(_clickSubscription?.cancel());
    unawaited(_keyDownSubscription?.cancel());
    unawaited(_scrollSubscription?.cancel());
    super.dispose();
  }

  @override
  Component build(BuildContext context) => component.child;
}

final class Dropdown extends StatefulComponent {
  const Dropdown({
    required this.id,
    required this.toggle,
    required this.content,
    super.key,
  });

  final String id;
  final Component toggle;
  final Component content;

  @override
  State<Dropdown> createState() => DropdownState();
}

final class DropdownState extends State<Dropdown> {
  bool _expanded = false;

  void toggle({bool? to}) {
    setState(() {
      _expanded = to ?? !_expanded;
    });
  }

  @override
  Component build(BuildContext context) {
    return GlobalEventListener(
      onClick: (event) {
        if (!_expanded) return;
        final target = event.target as web.HTMLElement?;
        if (target == null || target.closest('#${component.id}') == null) {
          toggle(to: false);
        }
      },
      div(
        id: component.id,
        classes: 'dropdown',
        attributes: {'data-expanded': _expanded.toString()},
        events: {
          'keydown': (event) {
            final keydownEvent = event as web.KeyboardEvent;
            if (_expanded && keydownEvent.key == 'Escape') {
              toggle(to: false);
            }
          },
          'focusout': (event) {
            final relatedTarget = (event as web.FocusEvent).relatedTarget as web.HTMLElement?;
            if (relatedTarget == null || relatedTarget.closest('#${component.id}') == null) {
              toggle(to: false);
            }
          },
        },
        [
          Component.wrapElement(
            classes: 'dropdown-button',
            events: {
              'click': (event) {
                toggle();
              },
            },
            attributes: {
              'aria-controls': '${component.id}-content',
              'aria-expanded': _expanded.toString(),
            },
            child: component.toggle,
          ),
          div(id: '${component.id}-content', classes: 'dropdown-content', [
            component.content,
          ]),
        ],
      ),
    );
  }
}
