import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

@client
final class ProfileMatrix extends StatefulComponent {
  const ProfileMatrix({super.key});

  @override
  State<ProfileMatrix> createState() => _ProfileMatrixState();
}

final class _ProfileMatrixState extends State<ProfileMatrix> {
  String _filter = 'All';

  List<_ProfileItem> get _visibleProfiles {
    if (_filter == 'All') return _profiles;
    return [
      for (final profile in _profiles)
        if (profile.priority == _filter || profile.app == _filter) profile,
    ];
  }

  @override
  Component build(BuildContext context) {
    return section(classes: 'profile-matrix', [
      div(classes: 'profile-filter-row', [
        for (final filter in _filters)
          button(
            type: ButtonType.button,
            classes: filter == _filter ? 'profile-filter active' : 'profile-filter',
            attributes: {'aria-pressed': (filter == _filter).toString()},
            onClick: () {
              setState(() {
                _filter = filter;
              });
            },
            [.text(filter)],
          ),
      ]),
      div(classes: 'profile-card-grid', [
        for (final profile in _visibleProfiles)
          article(classes: 'profile-card', [
            div(classes: 'profile-card-header', [
              span(classes: 'status-badge status-badge-${profile.tone}', [.text(profile.priority)]),
              code([.text(profile.app)]),
            ]),
            h3([.text(profile.profile)]),
            p([.text(profile.description)]),
          ]),
      ]),
    ]);
  }
}

final class _ProfileItem {
  const _ProfileItem({
    required this.profile,
    required this.app,
    required this.priority,
    required this.tone,
    required this.description,
  });

  final String app;
  final String description;
  final String priority;
  final String profile;
  final String tone;
}

const _filters = [
  'All',
  'Core',
  'Future',
  'bluetoothctl',
  'evtool',
  'obexctl',
  'ofono',
];

const _profiles = [
  _ProfileItem(
    profile: 'GAP',
    app: 'bluetoothctl',
    priority: 'Core',
    tone: 'completed',
    description: 'Discovery, adapter state, pairing, trust, and connection lifecycle.',
  ),
  _ProfileItem(
    profile: 'GATT',
    app: 'bluetoothctl',
    priority: 'Core',
    tone: 'in-progress',
    description: 'BLE service discovery and characteristic read/write notes for profile work.',
  ),
  _ProfileItem(
    profile: 'A2DP',
    app: 'bluetoothctl',
    priority: 'Core',
    tone: 'in-progress',
    description: 'Bluetooth media streaming validated together with PipeWire and WirePlumber.',
  ),
  _ProfileItem(
    profile: 'HOGP',
    app: 'evtool',
    priority: 'Future',
    tone: 'upcoming',
    description: 'BLE HID input devices such as keyboards, mice, and controllers.',
  ),
  _ProfileItem(
    profile: 'OPP',
    app: 'obexctl',
    priority: 'Future',
    tone: 'upcoming',
    description: 'Object exchange through OBEX for cards, images, and similar payloads.',
  ),
  _ProfileItem(
    profile: 'FTP',
    app: 'obexctl',
    priority: 'Future',
    tone: 'upcoming',
    description: 'Bluetooth file exchange validation when OBEX integration is available.',
  ),
  _ProfileItem(
    profile: 'PBAP',
    app: 'obexctl',
    priority: 'Future',
    tone: 'upcoming',
    description: 'Phone book object access for future contacts integration.',
  ),
  _ProfileItem(
    profile: 'MAP',
    app: 'obexctl',
    priority: 'Future',
    tone: 'upcoming',
    description: 'Message object exchange for future IVI messaging UX.',
  ),
  _ProfileItem(
    profile: 'HFP',
    app: 'ofono',
    priority: 'Future',
    tone: 'upcoming',
    description: 'Hands-free call control and audio routing when telephony policy is ready.',
  ),
];
