// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/server.dart';
import 'package:agl_docs_main/components/clicker.dart' as _clicker;
import 'package:agl_docs_main/components/flutter_menu_toggle.dart'
    as _flutter_menu_toggle;
import 'package:agl_docs_main/components/flutter_site_switcher.dart'
    as _flutter_site_switcher;
import 'package:agl_docs_main/components/flutter_theme_switcher.dart'
    as _flutter_theme_switcher;
import 'package:agl_docs_main/components/site_search.dart' as _site_search;
import 'package:agl_docs_main/components/toc_scroll_spy.dart'
    as _toc_scroll_spy;
import 'package:jaspr_content/components/_internal/code_block_copy_button.dart'
    as _code_block_copy_button;
import 'package:jaspr_content/components/_internal/zoomable_image.dart'
    as _zoomable_image;
import 'package:jaspr_content/components/callout.dart' as _callout;
import 'package:jaspr_content/components/code_block.dart' as _code_block;
import 'package:jaspr_content/components/image.dart' as _image;
import 'package:jaspr_content/components/sidebar_toggle_button.dart'
    as _sidebar_toggle_button;

/// Default [ServerOptions] for use with your Jaspr project.
///
/// Use this to initialize Jaspr **before** calling [runApp].
///
/// Example:
/// ```dart
/// import 'main.server.options.dart';
///
/// void main() {
///   Jaspr.initializeApp(
///     options: defaultServerOptions,
///   );
///
///   runApp(...);
/// }
/// ```
ServerOptions get defaultServerOptions => ServerOptions(
  clientId: 'main.client.dart.js',
  clients: {
    _clicker.Clicker: ClientTarget<_clicker.Clicker>('clicker'),
    _flutter_menu_toggle.FlutterMenuToggle:
        ClientTarget<_flutter_menu_toggle.FlutterMenuToggle>(
          'flutter_menu_toggle',
        ),
    _flutter_site_switcher.FlutterSiteSwitcher:
        ClientTarget<_flutter_site_switcher.FlutterSiteSwitcher>(
          'flutter_site_switcher',
        ),
    _flutter_theme_switcher.FlutterThemeSwitcher:
        ClientTarget<_flutter_theme_switcher.FlutterThemeSwitcher>(
          'flutter_theme_switcher',
        ),
    _site_search.SiteSearch: ClientTarget<_site_search.SiteSearch>(
      'site_search',
      params: __site_searchSiteSearch,
    ),
    _toc_scroll_spy.TocScrollSpy: ClientTarget<_toc_scroll_spy.TocScrollSpy>(
      'toc_scroll_spy',
    ),
    _code_block_copy_button.CodeBlockCopyButton:
        ClientTarget<_code_block_copy_button.CodeBlockCopyButton>(
          'jaspr_content:code_block_copy_button',
        ),
    _zoomable_image.ZoomableImage: ClientTarget<_zoomable_image.ZoomableImage>(
      'jaspr_content:zoomable_image',
      params: __zoomable_imageZoomableImage,
    ),
    _sidebar_toggle_button.SidebarToggleButton:
        ClientTarget<_sidebar_toggle_button.SidebarToggleButton>(
          'jaspr_content:sidebar_toggle_button',
        ),
  },
  styles: () => [
    ..._clicker.ClickerState.styles,
    ..._callout.Callout.styles,
    ..._code_block.CodeBlock.styles,
    ..._image.Image.styles,
    ..._zoomable_image.ZoomableImage.styles,
  ],
);

Map<String, Object?> __site_searchSiteSearch(_site_search.SiteSearch c) => {
  'indexJson': c.indexJson,
};
Map<String, Object?> __zoomable_imageZoomableImage(
  _zoomable_image.ZoomableImage c,
) => {'src': c.src, 'alt': c.alt, 'caption': c.caption};
