import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import 'header_controls.dart';

@client
final class FlutterThemeSwitcher extends StatefulComponent {
  const FlutterThemeSwitcher({super.key});

  @override
  State<FlutterThemeSwitcher> createState() => _FlutterThemeSwitcherState();
}

enum _Theme {
  light('Light', 'Switch to the light theme.', 'light_mode'),
  dark('Dark', 'Switch to the dark theme.', 'dark_mode'),
  auto('Automatic', 'Match theme to device theme.', 'night_sight_auto')
  ;

  const _Theme(this.label, this.description, this.iconId);

  final String label;
  final String description;
  final String iconId;

  String get id => '$name-mode';
}

final class _FlutterThemeSwitcherState extends State<FlutterThemeSwitcher> {
  _Theme _currentTheme = _Theme.light;

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) return;
    _currentTheme = _readThemePreference();
    _applyTheme(_currentTheme, persist: false);
  }

  _Theme _readThemePreference() {
    String? savedTheme;
    try {
      savedTheme = web.window.localStorage.getItem('theme') ?? web.window.localStorage.getItem('jaspr:theme');
    } catch (_) {
      savedTheme = null;
    }

    return switch (savedTheme) {
      'dark' || 'dark-mode' => _Theme.dark,
      'auto' || 'auto-mode' => _Theme.auto,
      'light' || 'light-mode' => _Theme.light,
      _ when web.document.documentElement?.getAttribute('data-theme') == 'dark' => _Theme.dark,
      _ => _Theme.light,
    };
  }

  String _resolvedTheme(_Theme theme) {
    if (theme == _Theme.auto) {
      return web.window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
    }
    return theme == _Theme.dark ? 'dark' : 'light';
  }

  void _applyTheme(_Theme theme, {bool persist = true}) {
    if (!kIsWeb) return;

    final resolvedTheme = _resolvedTheme(theme);
    web.document.documentElement?.setAttribute('data-theme', resolvedTheme);

    final classList = web.document.body?.classList;
    if (classList != null) {
      for (final mode in _Theme.values) {
        classList.remove(mode.id);
      }
      classList.remove('light-mode');
      classList.remove('dark-mode');
      classList.add(theme.id);
      classList.add('$resolvedTheme-mode');
    }

    if (persist) {
      try {
        web.window.localStorage.setItem('theme', theme.id);
        web.window.localStorage.setItem('jaspr:theme', resolvedTheme);
      } catch (error) {
        if (kDebugMode) {
          print('Failed to save theme preference: $error');
        }
      }
    }
  }

  void _setTheme(_Theme newTheme) {
    if (newTheme == _currentTheme) return;

    _applyTheme(newTheme);
    setState(() {
      _currentTheme = newTheme;
    });
  }

  @override
  Component build(BuildContext context) {
    return .fragment([
      if (!kIsWeb)
        Document.head(
          children: [
            script(
              id: 'flutter-docs-theme-script',
              content: r'''
(function () {
  const modes = ['light-mode', 'dark-mode', 'auto-mode'];

  function normalize(value) {
    switch (value) {
      case 'dark':
      case 'dark-mode':
        return 'dark-mode';
      case 'auto':
      case 'auto-mode':
        return 'auto-mode';
      case 'light':
      case 'light-mode':
      default:
        return 'light-mode';
    }
  }

  function resolve(mode) {
    if (mode === 'auto-mode') {
      return window.matchMedia('(prefers-color-scheme: dark)').matches
        ? 'dark'
        : 'light';
    }
    return mode === 'dark-mode' ? 'dark' : 'light';
  }

  function apply(value) {
    const mode = normalize(value);
    const resolved = resolve(mode);
    document.documentElement.setAttribute('data-theme', resolved);

    if (document.body) {
      modes.forEach((item) => document.body.classList.remove(item));
      document.body.classList.remove('light-mode', 'dark-mode');
      document.body.classList.add(mode, `${resolved}-mode`);
    }

    return mode;
  }

  let saved = 'light-mode';
  try {
    saved = localStorage.getItem('theme') ||
      localStorage.getItem('jaspr:theme') ||
      saved;
  } catch (_) {}

  const mode = apply(saved);
  if (!document.body) {
    document.addEventListener('DOMContentLoaded', () => apply(mode), {
      once: true,
    });
  }
})();
''',
            ),
          ],
        ),
      Dropdown(
        id: 'theme-switcher',
        toggle: const HeaderButton(icon: 'routine', title: 'Select a theme.'),
        content: div(classes: 'dropdown-menu', [
          ul(
            attributes: {'role': 'listbox'},
            [
              for (final mode in _Theme.values)
                _ThemeButtonEntry(
                  mode: mode,
                  selected: _currentTheme == mode,
                  setMode: _setTheme,
                ),
            ],
          ),
        ]),
      ),
    ]);
  }
}

final class _ThemeButtonEntry extends StatelessComponent {
  const _ThemeButtonEntry({
    required this.mode,
    required this.selected,
    required this.setMode,
  });

  final _Theme mode;
  final bool selected;
  final void Function(_Theme) setMode;

  @override
  Component build(BuildContext context) {
    return li([
      button(
        onClick: () {
          setMode(mode);
        },
        attributes: {
          'title': mode.description,
          'aria-label': mode.description,
          'aria-selected': selected.toString(),
        },
        [
          MaterialIcon(mode.iconId),
          span([.text(mode.label)]),
        ],
      ),
    ]);
  }
}
