//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   01 Nov 2024  Matthew Giannini  Creation
//

@Js
class ImgAttrsExtTest : RenderingTest
{
  private static const MarkdownExt[] exts := [ImgAttrsExt()]
  private static const Parser parser := Parser.builder.extensions(exts).build
  private static const HtmlRenderer renderer := HtmlRenderer.builder.extensions(exts).build
  private static const MarkdownRenderer md := MarkdownRenderer.builder.extensions(exts).build

  Void testBaseCase()
  {
    verifyRendering("![text](/url.png){height=5}",
      "<p><img src=\"/url.png\" alt=\"text\" height=\"5\" /></p>\n")

    verifyRendering("![text](/url.png){height=5 width=6}",
      "<p><img src=\"/url.png\" alt=\"text\" height=\"5\" width=\"6\" /></p>\n")

    verifyRendering("![text](/url.png){height=99px   width=100px}",
      "<p><img src=\"/url.png\" alt=\"text\" height=\"99px\" width=\"100px\" /></p>\n")

    verifyRendering("![text](/url.png){width=100 height=100}",
      "<p><img src=\"/url.png\" alt=\"text\" width=\"100\" height=\"100\" /></p>\n")

    verifyRendering("![text](/url.png){height=4.8 width=3.14}",
      "<p><img src=\"/url.png\" alt=\"text\" height=\"4.8\" width=\"3.14\" /></p>\n")

    verifyRendering("![text](/url.png){Width=18 HeIgHt=1001}",
      "<p><img src=\"/url.png\" alt=\"text\" Width=\"18\" HeIgHt=\"1001\" /></p>\n")

    verifyRendering("![text](/url.png){height=green width=blue}",
      "<p><img src=\"/url.png\" alt=\"text\" height=\"green\" width=\"blue\" /></p>\n")
  }

  Void testDoubleDelimiters()
  {
    verifyRendering("![text](/url.png){{height=5}}",
      "<p><img src=\"/url.png\" alt=\"text\" />{{height=5}}</p>\n")
  }

  Void testMismatchingDelimitersAreIgnored()
  {
    verifyRendering("![text](/url.png){",
      "<p><img src=\"/url.png\" alt=\"text\" />{</p>\n")
  }

  Void testUnsupportedStyleNamesAreLeftUnchanged()
  {
    verifyRendering("![text](/url.png){j=502 K=101 img=2 url=5}",
      "<p><img src=\"/url.png\" alt=\"text\" />{j=502 K=101 img=2 url=5}</p>\n");
    verifyRendering("![foo](/url.png){height=3 invalid}\n",
      "<p><img src=\"/url.png\" alt=\"foo\" />{height=3 invalid}</p>\n");
    verifyRendering("![foo](/url.png){height=3 *test*}\n",
      "<p><img src=\"/url.png\" alt=\"foo\" />{height=3 <em>test</em>}</p>\n");
  }

  Void testStyleWithNoValueIsIgnored()
  {
    verifyRendering("![text](/url.png){height}",
      "<p><img src=\"/url.png\" alt=\"text\" />{height}</p>\n");
  }

  Void testImageAltTextWithSpaces()
  {
    verifyRendering("![Android SDK Manager](/contrib/android-sdk-manager.png){height=502 width=101}",
      "<p><img src=\"/contrib/android-sdk-manager.png\" alt=\"Android SDK Manager\" height=\"502\" width=\"101\" /></p>\n");
  }

  Void testImageAltTextWithSoftLineBreak() {
    verifyRendering("![foo\nbar](/url){height=101 width=202}\n",
      "<p><img src=\"/url\" alt=\"foo\nbar\" height=\"101\" width=\"202\" /></p>\n");
  }


  Void testImageAltTextWithHardLineBreak() {
    verifyRendering("![foo  \nbar](/url){height=506 width=1}\n",
      "<p><img src=\"/url\" alt=\"foo\nbar\" height=\"506\" width=\"1\" /></p>\n");
  }


  Void testImageAltTextWithEntities() {
    verifyRendering("![foo &auml;](/url){height=99 width=100}\n",
      "<p><img src=\"/url\" alt=\"foo \u00E4\" height=\"99\" width=\"100\" /></p>\n");
  }

  Void testTextNodesAreUnchanged() {
      verifyRendering("x{height=3 width=4}\n", "<p>x{height=3 width=4}</p>\n");
      verifyRendering("x {height=3 width=4}\n", "<p>x {height=3 width=4}</p>\n");
      verifyRendering("\\documentclass[12pt]{article}\n", "<p>\\documentclass[12pt]{article}</p>\n");
      verifyRendering("some *text*{height=3 width=4}\n", "<p>some <em>text</em>{height=3 width=4}</p>\n");
      verifyRendering("{NN} text", "<p>{NN} text</p>\n");
      verifyRendering("{}", "<p>{}</p>\n");
  }

    // TODO:source spans test

  override protected Str render(Str source)
  {
    doc  := parser.parse(source)
    html := renderer.render(doc)

    // while we're in here round-trip to markdown and verify
    mark := md.render(doc)
    verifyEq(html, renderer.render(parser.parse(mark)))

    return html
  }
}