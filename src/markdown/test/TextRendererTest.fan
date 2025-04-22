//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Apr 2025  Matthew Giannini  Creation
//

@Js
class TextRendererTest : Test
{
  private static Node parse(Str source) { Parser().parse(source) }
  private static TextRenderer compactRenderer() { TextRenderer() }
  private static TextRenderer strippedRenderer()
  {
    TextRenderer.builder.withLineBreakRendering(LineBreakRendering.strip).build
  }
  private static TextRenderer separateRenderer()
  {
    TextRenderer.builder.withLineBreakRendering(LineBreakRendering.separate_blocks).build
  }

  Void testContextText()
  {
    s := "foo bar"
    verifyCompact(s, "foo bar")
    verifyStripped(s, "foo bar")

    s = "foo foo\n\nbar\nbar"
    verifyCompact(s, "foo foo\nbar\nbar")
    verifySeparate(s, "foo foo\n\nbar\nbar")
    verifyStripped(s, "foo foo bar bar")
  }

  Void testContentHeading()
  {
    verifyCompact("# Heading\n\nFoo", "Heading\nFoo")
    verifySeparate("# Heading\n\nFoo", "Heading\n\nFoo")
    verifyStripped("# Heading\n\nFoo", "Heading: Foo")
  }

  Void testContentEmphasis()
  {
    s := "***foo***"
    verifyCompact(s, "foo")
    verifyStripped(s, "foo")

    s = "foo ***foo*** bar ***bar***"
    verifyCompact(s, "foo foo bar bar")
    verifyStripped(s, "foo foo bar bar")

    s = "foo\n***foo***\nbar\n\n***bar***"
    verifyCompact(s, "foo\nfoo\nbar\nbar")
    verifySeparate(s, "foo\nfoo\nbar\n\nbar")
    verifyStripped(s, "foo foo bar bar")
  }

  Void testContentQuotes()
  {
    s := "foo\n>foo\nbar\n\nbar"
    verifyCompact(s, "foo\n\u00ABfoo\nbar\u00BB\nbar")
    verifySeparate(s, "foo\n\n\u00ABfoo\nbar\u00BB\n\nbar")
    verifyStripped(s, "foo \u00ABfoo bar\u00BB bar")
  }

  Void testContentLinks()
  {
    verifyAll("""foo [text](http://link "title") bar""", """foo "text" (title: http://link) bar""")
    verifyAll("""foo [text](http://link "http://link") bar""", """foo "text" (http://link) bar""")
    verifyAll("""foo [text](http://link) bar""", """foo "text" (http://link) bar""")
    verifyAll("""foo [text]() bar""", """foo "text" bar""")
    verifyAll("""foo http://link bar""", """foo http://link bar""")
  }

  Void testContentImages()
  {
    verifyAll("""foo ![text](http://link "title") bar""", """foo "text" (title: http://link) bar""")
    verifyAll("""foo ![text](http://link) bar""", """foo "text" (http://link) bar""")
    verifyAll("""foo ![text]() bar""", """foo "text" bar""")
  }

  Void testContentLists()
  {
    s := "foo\n* foo\n* bar\n\nbar"
    verifyCompact(s, "foo\n* foo\n* bar\nbar")
    verifySeparate(s, "foo\n\n* foo\n* bar\n\nbar")
    verifyStripped(s, "foo foo bar bar")

    s = "foo\n- foo\n- bar\n\nbar"
    verifyCompact(s, "foo\n- foo\n- bar\nbar")
    verifySeparate(s, "foo\n\n- foo\n- bar\n\nbar")
    verifyStripped(s, "foo foo bar bar")

    s = "foo\n1. foo\n2. bar\n\nbar"
    verifyCompact(s, "foo\n1. foo\n2. bar\nbar")
    verifySeparate(s, "foo\n\n1. foo\n2. bar\n\nbar")
    verifyStripped(s, "foo 1. foo 2. bar bar")

    s = "foo\n0) foo\n1) bar\n\nbar"
    verifyCompact(s, "foo\n0) foo\n1) bar\nbar")
    verifySeparate(s, "foo\n0) foo\n\n1) bar\n\nbar")
    verifyStripped(s, "foo 0) foo 1) bar bar")

    s = "bar\n1. foo\n   1. bar\n2. foo";
    verifyCompact(s, "bar\n1. foo\n   1. bar\n2. foo")
    verifySeparate(s, "bar\n\n1. foo\n   1. bar\n2. foo")
    verifyStripped(s, "bar 1. foo 1. bar 2. foo")

    s = "bar\n* foo\n   - bar\n* foo"
    verifyCompact(s, "bar\n* foo\n   - bar\n* foo")
    verifySeparate(s, "bar\n\n* foo\n   - bar\n* foo")
    verifyStripped(s, "bar foo bar foo")

    s = "bar\n* foo\n   1. bar\n   2. bar\n* foo"
    verifyCompact(s, "bar\n* foo\n   1. bar\n   2. bar\n* foo")
    verifySeparate(s, "bar\n\n* foo\n   1. bar\n   2. bar\n* foo")
    verifyStripped(s, "bar foo 1. bar 2. bar foo")

    s = "bar\n1. foo\n   * bar\n   * bar\n2. foo"
    verifyCompact(s, "bar\n1. foo\n   * bar\n   * bar\n2. foo")
    verifySeparate(s, "bar\n\n1. foo\n   * bar\n   * bar\n2. foo")
    verifyStripped(s, "bar 1. foo bar bar 2. foo")

    // For a loose list (not tight)
    s = "foo\n\n* bar\n\n* baz"
    // Compact ignores loose
    verifyCompact(s, "foo\n* bar\n* baz")
    // Separate preserves it
    verifySeparate(s, "foo\n\n* bar\n\n* baz")
    verifyStripped(s, "foo bar baz")
  }

  Void testContentCode()
  {
    verifyAll("foo `code` bar", """foo "code" bar""")
  }

  Void testContentCodeBlock()
  {
    s := "foo\n```\nfoo\nbar\n```\nbar"
    verifyCompact(s, "foo\nfoo\nbar\nbar")
    verifySeparate(s, "foo\n\nfoo\nbar\n\nbar")
    verifyStripped(s, "foo foo bar bar")

    s = "foo\n\n    foo\n     bar\nbar"
    verifyCompact(s, "foo\nfoo\n bar\nbar")
    verifySeparate(s, "foo\n\nfoo\n bar\n\nbar")
    verifyStripped(s, "foo foo bar bar")
  }

  Void testContentBreaks()
  {
    s := "foo\nbar"
    verifyCompact(s, "foo\nbar")
    verifySeparate(s, "foo\nbar")
    verifyStripped(s, "foo bar")

    s = "foo  \nbar"
    verifyCompact(s, "foo\nbar")
    verifySeparate(s, "foo\nbar")
    verifyStripped(s, "foo bar")

    s = "foo\n___\nbar"
    verifyCompact(s, "foo\n***\nbar")
    verifySeparate(s, "foo\n\n***\n\nbar")
    verifyStripped(s, "foo bar")
  }

  Void testContentHtml()
  {
    html :=
      "<table>\n" +
      "  <tr>\n" +
      "    <td>\n" +
      "           foobar\n" +
      "    </td>\n" +
      "  </tr>\n" +
      "</table>"
    verifyCompact(html, html)
    verifySeparate(html, html)

    html = "foo <foo>foobar</foo> bar"
    verifyAll(html, html)
}

  private Void verifyCompact(Str source, Str expected)
  {
    node   := parse(source)
    actual := compactRenderer.render(node)
    verifyEq(expected, actual)
  }

  private Void verifyStripped(Str source, Str expected)
  {
    node   := parse(source)
    actual := strippedRenderer.render(node)
    verifyEq(expected, actual)
  }

  private Void verifySeparate(Str source, Str expected)
  {
    node   := parse(source)
    actual := separateRenderer.render(node)
    verifyEq(expected, actual)
  }

  private Void verifyAll(Str source, Str expected)
  {
    verifyCompact(source, expected)
    verifySeparate(source, expected)
    verifyStripped(source, expected)
  }
}