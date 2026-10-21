//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   01 Nov 2024  Matthew Giannini  Creation
//

@Js
class XetodocExtTest : Test
{
  Xetodoc? xetodoc

  override Void setup() { this.xetodoc = Xetodoc() }

  private Str toHtml(Str src) { xetodoc.toHtml(src) }

  Void testInlineCode()
  {
    // sanity check that backticks renders as inline code
    verifyEq(toHtml("`code`"), "<p><code>code</code></p>\n")
  }

  Void testBracketLinks()
  {
    verifyEq(toHtml("[a]"), """<p><a href="a">a</a></p>\n""")
    verifyEq(toHtml("Use [now()] for timestamp"), """<p>Use <a href="now()">now()</a> for timestamp</p>\n""")
    verifyEq(toHtml("Str[]"), """<p>Str[]</p>\n""")
  }

  // Void testBacktickLinks()
  // {
  //   // doc := parser.parse("`url`\n\n[url](url)\n\n![imgUrl](imgUrl)")
  //   // Node.dumpTree(doc)
  //   // echo("===")
  //   // echo(renderer.render(doc))
  // }

  Void testHeadingAnchor()
  {
    // simple test
    verifyEq(toHtml("# Intro"), """<h1 id="intro">Intro</h1>\n""")

    // ignore formatting
    verifyEq(toHtml("# _Intro_ Section"), """<h1 id="intro-section"><em>Intro</em> Section</h1>\n""")

    // handle duplicate section ids
    verifyEq(toHtml("# Intro\n# Intro"), """<h1 id="intro">Intro</h1>\n<h1 id="intro-1">Intro</h1>\n""")

    // text and code mixed
    verifyEq(toHtml("## `Heading` 2"), """<h2 id="heading-2"><code>Heading</code> 2</h2>\n""")

    // whacky symbols and spacing
    verifyEq(toHtml("# Heading#!\tNoSpace!!!  "), """<h1 id="headingnospace">Heading#!\tNoSpace!!!</h1>\n""")

    // hyphens and underscores are kept
    verifyAnchor("foo-bar_baz",          "foo-bar_baz")
    verifyAnchor("Hello, World! (v2.0)", "hello-world-v20")

    // unicode letters are kept and lower cased
    verifyAnchor("Café Résumé",  "café-résumé")
    verifyAnchor("Über alles",   "über-alles")
    verifyAnchor("Привет Мир",   "привет-мир")
    verifyAnchor("日本語",        "日本語")
    verifyAnchor("हिन्दी",          "हिन्दी")
    verifyAnchor("\u{1d49c}bc",  "\u{1d49c}bc")

    // emoji, symbols, and presentation selectors are removed
    verifyAnchor("\u{1f3e2} Building",   "-building")
    verifyAnchor("\u2705\uFE0F Done",    "-done")
    verifyAnchor("a\u00b2b \u00bd",      "ab-")

    // nothing left uses default id
    verifyEq(toHtml("# \u{1f5d1}\n# !!!"), """<h1 id="id">\u{1f5d1}</h1>\n<h1 id="id-1">!!!</h1>\n""")
  }

  Void testChapterAnchors()
  {
    src := Str<|# Intro
                ## _Intro_ Section
                ## [Foo](bar) Link
                ## `Code` and *stars*
                ## 🗑 Trash
                ## Café
                ## Intro
                |>
    chapter := XetodocChapter.parse(src)
    verifyEq(chapter.byId.keys.sort, ["intro", "intro-section", "foo-link", "code-and-stars", "-trash", "café", "intro-1"].sort)

    // chapter anchors match the ids rendered in the html
    html := toHtml(src)
    chapter.byId.keys.each |id| { verify(html.contains("id=\"${id}\""), id) }
  }

  private Void verifyAnchor(Str heading, Str anchor)
  {
    verifyEq(Parser().parse("# ${heading}").firstChild->anchor, anchor)
  }

  Void testIgnoreHtml()
  {
    // xetodoc.onWarn |node, msg| { echo("${node.loc}: ${msg}") }
    verifyEq(toHtml("Foo<h1>H1</h1>\n<h2>H2</h2>\n\nText"), "<p>FooH1</p>\n<p>Text</p>\n")
  }
}

@Js
@NoDoc class TestLinkResolver : LinkResolver
{
  override Void resolve(LinkNode node)
  {
    node.destination = "/resolved"
    node.isCode = node is Link
    node.setText("resolved")
  }
}