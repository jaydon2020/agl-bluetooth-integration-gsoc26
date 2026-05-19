import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';

import 'header_controls.dart';

final class ProjectSidebar extends StatelessComponent {
  const ProjectSidebar({
    required this.sections,
    this.links = const [],
    super.key,
  });

  final List<ProjectSidebarEntry> links;
  final List<ProjectSidebarSection> sections;

  @override
  Component build(BuildContext context) {
    final currentRoute = _normalizeRoute(context.page.url);

    return nav(classes: 'sidebar project-sidebar', [
      button(
        classes: 'sidebar-close',
        attributes: {'aria-label': 'Close navigation menu'},
        [
          const MaterialIcon('close', size: '20px'),
        ],
      ),
      div(classes: 'project-sidebar-content', [
        if (links.isNotEmpty)
          div(classes: 'project-sidebar-top-links', [
            for (final entry in links) _SidebarLink(entry: entry, currentRoute: currentRoute),
          ]),
        for (final section in sections) _SidebarSection(section: section, currentRoute: currentRoute),
      ]),
    ]);
  }
}

final class ProjectSidebarSection {
  const ProjectSidebarSection({
    required this.title,
    required this.links,
    this.expanded = false,
  });

  final bool expanded;
  final List<ProjectSidebarEntry> links;
  final String title;

  bool containsRoute(String currentRoute) => links.any((entry) => entry.containsRoute(currentRoute));
}

final class ProjectSidebarEntry {
  const ProjectSidebarEntry({
    required this.text,
    required this.href,
    this.children = const [],
  });

  final List<ProjectSidebarEntry> children;
  final String href;
  final String text;

  bool isActive(String currentRoute) => _normalizeRoute(href) == currentRoute;

  bool containsRoute(String currentRoute) {
    return isActive(currentRoute) || children.any((child) => child.containsRoute(currentRoute));
  }
}

final class _SidebarSection extends StatelessComponent {
  const _SidebarSection({
    required this.section,
    required this.currentRoute,
  });

  final String currentRoute;
  final ProjectSidebarSection section;

  @override
  Component build(BuildContext context) {
    final isActive = section.containsRoute(currentRoute);

    return details(
      open: section.expanded || isActive,
      classes: _classes([
        'project-sidebar-section',
        if (isActive) 'active-section',
      ]),
      [
        summary([
          span([.text(section.title)]),
        ]),
        ul([
          for (final entry in section.links) _SidebarListItem(entry: entry, currentRoute: currentRoute),
        ]),
      ],
    );
  }
}

final class _SidebarListItem extends StatelessComponent {
  const _SidebarListItem({
    required this.entry,
    required this.currentRoute,
  });

  final String currentRoute;
  final ProjectSidebarEntry entry;

  @override
  Component build(BuildContext context) {
    final hasChildren = entry.children.isNotEmpty;
    final isActive = entry.isActive(currentRoute);
    final hasActiveChild = !isActive && entry.containsRoute(currentRoute);

    return li(
      classes: _classes([
        if (hasChildren) 'has-children',
        if (hasActiveChild) 'has-active-child',
      ]),
      [
        _SidebarLink(
          entry: entry,
          currentRoute: currentRoute,
          nested: false,
          ancestorActive: hasActiveChild,
        ),
        if (hasChildren)
          ul(classes: 'project-sidebar-subitems', [
            for (final child in entry.children)
              _SidebarListItem(
                entry: child,
                currentRoute: currentRoute,
              ),
          ]),
      ],
    );
  }
}

final class _SidebarLink extends StatelessComponent {
  const _SidebarLink({
    required this.entry,
    required this.currentRoute,
    this.nested = false,
    this.ancestorActive = false,
  });

  final bool ancestorActive;
  final String currentRoute;
  final ProjectSidebarEntry entry;
  final bool nested;

  @override
  Component build(BuildContext context) {
    final isActive = entry.isActive(currentRoute);

    return div(
      classes: _classes([
        'project-sidebar-link',
        if (nested) 'nested-link',
        if (ancestorActive) 'ancestor-active',
        if (isActive) 'active',
      ]),
      [
        a(
          href: entry.href,
          attributes: {
            if (isActive) 'aria-current': 'page',
          },
          [
            .text(entry.text),
          ],
        ),
      ],
    );
  }
}

String _classes(List<String?> classes) {
  return classes.whereType<String>().where((className) => className.isNotEmpty).join(' ');
}

String _normalizeRoute(String route) {
  if (route == '/') return route;
  final absoluteRoute = route.startsWith('/') ? route : '/$route';
  return absoluteRoute.endsWith('/') ? absoluteRoute.substring(0, absoluteRoute.length - 1) : absoluteRoute;
}
