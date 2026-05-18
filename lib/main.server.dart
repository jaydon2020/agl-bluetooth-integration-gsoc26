/// The entrypoint for the **server** environment.
///
/// The [main] method will only be executed on the server during pre-rendering.
/// To run code on the client, check the `main.client.dart` file.
library;

// Server-specific Jaspr import.
import 'package:jaspr/server.dart';

import 'package:jaspr_content/components/callout.dart';
import 'package:jaspr_content/components/code_block.dart';
import 'package:jaspr_content/components/image.dart';
import 'package:jaspr_content/components/sidebar.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_content/theme.dart';

import 'components/clicker.dart';
import 'components/dart_footer.dart';
import 'components/flutter_header.dart';
import 'components/search_index.dart';

// This file is generated automatically by Jaspr, do not remove or edit.
import 'main.server.options.dart';

void main() {
  // Initializes the server environment with the generated default options.
  Jaspr.initializeApp(
    options: defaultServerOptions,
  );

  // Starts the app.
  //
  // [ContentApp] spins up the content rendering pipeline from jaspr_content to render
  // your markdown files in the content/ directory to a beautiful documentation site.
  runApp(
    ContentApp(
      eagerlyLoadAllPages: true,
      // Enables mustache templating inside the markdown files.
      templateEngine: MustacheTemplateEngine(),
      parsers: [
        MarkdownParser(),
      ],
      extensions: [
        // Adds heading anchors to each heading.
        HeadingAnchorsExtension(),
        // Generates a table of contents for each page.
        TableOfContentsExtension(),
      ],
      components: [
        // The <Info> block and other callouts.
        Callout(),
        // Adds syntax highlighting to code blocks.
        CodeBlock(),
        // Adds a custom Jaspr component to be used as <Clicker/> in markdown.
        CustomComponent(
          pattern: 'Clicker',
          builder: (_, _, _) => Clicker(),
        ),
        CustomComponent(
          pattern: 'SearchIndex',
          builder: (_, _, _) => const SearchIndex(),
        ),
        // Adds zooming and caption support to images.
        Image(zoom: true),
      ],
      layouts: [
        // Out-of-the-box layout for documentation sites.
        DocsLayout(
          header: const FlutterDocsHeader(),
          footer: const DartStyleFooter(),
          sidebar: Sidebar(
            groups: [
              // Adds navigation links to the sidebar.
              SidebarGroup(
                links: [
                  SidebarLink(text: "Overview", href: '/'),
                  SidebarLink(text: "Learn", href: '/learn'),
                  SidebarLink(text: "Search", href: '/search'),
                ],
              ),
              SidebarGroup(
                title: 'Content',
                links: [
                  SidebarLink(text: "About", href: '/about'),
                  SidebarLink(text: "Get Started", href: '/get-started/quick'),
                ],
              ),
              SidebarGroup(
                title: 'Bluetooth Integration',
                links: [
                  SidebarLink(text: "Overview", href: '/bluetooth/overview'),
                  SidebarLink(text: "Verify BlueZ", href: '/bluetooth/verify-bluez'),
                ],
              ),
            ],
          ),
        ),
      ],
      theme: ContentTheme(
        // Customizes the default theme colors.
        primary: ThemeColor(ThemeColors.blue.$500, dark: ThemeColors.blue.$300),
        background: ThemeColor(ThemeColors.slate.$50, dark: ThemeColors.zinc.$950),
        colors: [
          ContentColors.quoteBorders.apply(ThemeColors.blue.$400),
        ],
      ),
    ),
  );
}
