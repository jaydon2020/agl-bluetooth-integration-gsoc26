// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/client.dart';

import 'package:agl_docs_main/components/clicker.dart' deferred as _clicker;
import 'package:agl_docs_main/components/flutter_menu_toggle.dart'
    deferred as _flutter_menu_toggle;
import 'package:agl_docs_main/components/flutter_site_switcher.dart'
    deferred as _flutter_site_switcher;
import 'package:agl_docs_main/components/flutter_theme_switcher.dart'
    deferred as _flutter_theme_switcher;
import 'package:agl_docs_main/components/site_search.dart'
    deferred as _site_search;
import 'package:agl_docs_main/components/toc_scroll_spy.dart'
    deferred as _toc_scroll_spy;
import 'package:jaspr_content/components/_internal/code_block_copy_button.dart'
    deferred as _code_block_copy_button;
import 'package:jaspr_content/components/_internal/zoomable_image.dart'
    deferred as _zoomable_image;
import 'package:jaspr_content/components/sidebar_toggle_button.dart'
    deferred as _sidebar_toggle_button;

/// Default [ClientOptions] for use with your Jaspr project.
///
/// Use this to initialize Jaspr **before** calling [runApp].
///
/// Example:
/// ```dart
/// import 'main.client.options.dart';
///
/// void main() {
///   Jaspr.initializeApp(
///     options: defaultClientOptions,
///   );
///
///   runApp(...);
/// }
/// ```
ClientOptions get defaultClientOptions => ClientOptions(
  clients: {
    'clicker': ClientLoader(
      (p) => _clicker.Clicker(),
      loader: _clicker.loadLibrary,
    ),
    'flutter_menu_toggle': ClientLoader(
      (p) => _flutter_menu_toggle.FlutterMenuToggle(),
      loader: _flutter_menu_toggle.loadLibrary,
    ),
    'flutter_site_switcher': ClientLoader(
      (p) => _flutter_site_switcher.FlutterSiteSwitcher(),
      loader: _flutter_site_switcher.loadLibrary,
    ),
    'flutter_theme_switcher': ClientLoader(
      (p) => _flutter_theme_switcher.FlutterThemeSwitcher(),
      loader: _flutter_theme_switcher.loadLibrary,
    ),
    'site_search': ClientLoader(
      (p) => _site_search.SiteSearch(indexJson: p['indexJson'] as String),
      loader: _site_search.loadLibrary,
    ),
    'toc_scroll_spy': ClientLoader(
      (p) => _toc_scroll_spy.TocScrollSpy(),
      loader: _toc_scroll_spy.loadLibrary,
    ),
    'jaspr_content:code_block_copy_button': ClientLoader(
      (p) => _code_block_copy_button.CodeBlockCopyButton(),
      loader: _code_block_copy_button.loadLibrary,
    ),
    'jaspr_content:zoomable_image': ClientLoader(
      (p) => _zoomable_image.ZoomableImage(
        src: p['src'] as String,
        alt: p['alt'] as String?,
        caption: p['caption'] as String?,
      ),
      loader: _zoomable_image.loadLibrary,
    ),
    'jaspr_content:sidebar_toggle_button': ClientLoader(
      (p) => _sidebar_toggle_button.SidebarToggleButton(),
      loader: _sidebar_toggle_button.loadLibrary,
    ),
  },
);
