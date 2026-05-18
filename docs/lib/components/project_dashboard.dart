import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

const _checklistStorageKey = 'jiandeGSoC26DashboardChecklist';

@client
final class ProjectDashboard extends StatefulComponent {
  const ProjectDashboard({super.key});

  @override
  State<ProjectDashboard> createState() => _ProjectDashboardState();
}

final class _ProjectDashboardState extends State<ProjectDashboard> {
  final Set<String> _completed = {};

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;

    final saved = web.window.localStorage.getItem(_checklistStorageKey);
    if (saved == null || saved.trim().isEmpty) return;
    _completed
      ..clear()
      ..addAll(saved.split(',').where((id) => id.isNotEmpty));
  }

  void _toggle(String id, bool checked) {
    setState(() {
      if (checked) {
        _completed.add(id);
      } else {
        _completed.remove(id);
      }
      if (kIsWeb) {
        web.window.localStorage.setItem(_checklistStorageKey, _completed.join(','));
      }
    });
  }

  int get _progress => ((_completed.length / _checklistItems.length) * 100).round();

  @override
  Component build(BuildContext context) {
    return section(classes: 'project-dashboard', [
      div(classes: 'dashboard-status-grid', [
        for (final card in _statusCards)
          article(classes: 'dashboard-status-card', [
            span(classes: 'dashboard-card-icon material-symbols', attributes: {'translate': 'no'}, [.text(card.icon)]),
            p(classes: 'dashboard-card-label', [.text(card.label)]),
            h3([.text(card.title)]),
            p([.text(card.description)]),
          ]),
      ]),
      div(classes: 'dashboard-panels', [
        article(classes: 'dashboard-panel dashboard-checklist-card', [
          div(classes: 'dashboard-panel-heading', [
            div([
              p(classes: 'dashboard-card-label', [.text('Local checklist')]),
              h2([.text('Bring-up progress')]),
            ]),
            strong([.text('$_progress%')]),
          ]),
          div(classes: 'dashboard-progress', [
            div(
              classes: 'dashboard-progress-bar',
              attributes: {'style': 'width: $_progress%;'},
              [],
            ),
          ]),
          ul(classes: 'dashboard-checklist', [
            for (final item in _checklistItems)
              li([
                label([
                  input<bool>(
                    type: InputType.checkbox,
                    checked: _completed.contains(item.id),
                    onChange: (checked) => _toggle(item.id, checked),
                  ),
                  span([.text(item.label)]),
                ]),
              ]),
          ]),
        ]),
        article(classes: 'dashboard-panel dashboard-links-card', [
          p(classes: 'dashboard-card-label', [.text('Jump in')]),
          h2([.text('Project links')]),
          div(classes: 'dashboard-link-grid', [
            for (final linkItem in _quickLinks)
              a(
                href: linkItem.href,
                classes: 'dashboard-link-card',
                attributes: linkItem.external ? {'target': '_blank', 'rel': 'noopener'} : null,
                [
                  span(classes: 'material-symbols', attributes: {'translate': 'no'}, [.text(linkItem.icon)]),
                  span([.text(linkItem.label)]),
                ],
              ),
          ]),
        ]),
      ]),
    ]);
  }
}

final class _StatusCard {
  const _StatusCard({
    required this.icon,
    required this.label,
    required this.title,
    required this.description,
  });

  final String description;
  final String icon;
  final String label;
  final String title;
}

final class _ChecklistItem {
  const _ChecklistItem(this.id, this.label);

  final String id;
  final String label;
}

final class _QuickLink {
  const _QuickLink({
    required this.icon,
    required this.label,
    required this.href,
    this.external = false,
  });

  final bool external;
  final String href;
  final String icon;
  final String label;
}

const _statusCards = [
  _StatusCard(
    icon: 'bluetooth',
    label: 'Core stack',
    title: 'BlueZ bring-up',
    description: 'Adapter, discovery, pairing, trust, connection, and profile checks for the target image.',
  ),
  _StatusCard(
    icon: 'graphic_eq',
    label: 'Audio path',
    title: 'PipeWire routing',
    description: 'A2DP validation with PipeWire and WirePlumber as the modern AGL audio graph.',
  ),
  _StatusCard(
    icon: 'terminal',
    label: 'Native bridge',
    title: 'C++ D-Bus plugin',
    description: 'Typed Flutter access to BlueZ through a native plugin instead of legacy afb-daemon mappings.',
  ),
  _StatusCard(
    icon: 'flag',
    label: 'Milestones',
    title: 'Reports upcoming',
    description: 'Midterm and final reports stay visible while validation evidence is collected.',
  ),
];

const _checklistItems = [
  _ChecklistItem('target-image', 'Confirm AGL target image and board revision'),
  _ChecklistItem('bluez-service', 'Verify bluetooth.service and local adapter'),
  _ChecklistItem('pair-connect', 'Pair, trust, connect, disconnect, and reconnect a phone'),
  _ChecklistItem('a2dp-pipewire', 'Verify A2DP PipeWire nodes and audio route'),
  _ChecklistItem('logs', 'Capture btmon, journalctl, and busctl evidence'),
  _ChecklistItem('report-notes', 'Draft report notes from validation results'),
];

const _quickLinks = [
  _QuickLink(icon: 'architecture', label: 'Architecture Overview', href: '/bluetooth/overview'),
  _QuickLink(icon: 'fact_check', label: 'BlueZ Verification', href: '/bluetooth/verify-bluez'),
  _QuickLink(icon: 'timeline', label: 'Weekly Journal', href: '/journal'),
  _QuickLink(icon: 'assignment', label: 'Milestones', href: '/report/midterm'),
  _QuickLink(
    icon: 'school',
    label: 'GSoC Project',
    href: 'https://summerofcode.withgoogle.com/programs/2026/projects/jkzcDIbh',
    external: true,
  ),
  _QuickLink(
    icon: 'code',
    label: 'GitHub',
    href: 'https://github.com/jaydon2020/agl-bluetooth-integration-gsoc26',
    external: true,
  ),
];
