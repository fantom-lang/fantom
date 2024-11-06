//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   06 Nov 2024  Matthew Giannini  Creation
//

@Js
class MarkdownRendererTest : Test
{
  // Leaf blocks

  Void testThematicBreaks()
  {
    verifyRoundTrip("___\n")
    verifyRoundTrip("___\n\nfoo\n")
    // list item with hr -> hr needs to not use the same as the marker
    verifyRoundTrip("* ___\n")
    verifyRoundTrip("- ___\n")

    // preserve the literal
    verifyRoundTrip("----\n")
    verifyRoundTrip("*****\n")

    // apply fallback for null iteral
    node := ThematicBreak()
    verifyEq("___", render(node))
  }

  Void testHeadings()
  {
    // type of heading is currently not preserved
    verifyRoundTrip("# foo\n")
    verifyRoundTrip("## foo\n")
    verifyRoundTrip("### foo\n")
    verifyRoundTrip("#### foo\n")
    verifyRoundTrip("##### foo\n")
    verifyRoundTrip("###### foo\n")

    verifyRoundTrip("Foo\nbar\n===\n")
    verifyRoundTrip("Foo  \nbar\n===\n")
    verifyRoundTrip("[foo\nbar](/url)\n===\n")

    verifyRoundTrip("# foo\n\nbar\n")
  }

  Void testIndentedCodeBlocks()
  {
    verifyRoundTrip("    hi\n")
    verifyRoundTrip("    hi\n    code\n")
    verifyRoundTrip(">     hi\n>     code\n")
  }

  Void testFencedCodeBlocks()
  {
    verifyRoundTrip("```\ntest\n```\n")
    verifyRoundTrip("~~~~\ntest\n~~~~\n")
    verifyRoundTrip("```info\ntest\n```\n")
    verifyRoundTrip(" ```\n test\n ```\n")
    verifyRoundTrip("```\n```\n")

    // Preserve the length
    verifyRoundTrip("````\ntest\n````\n")
    verifyRoundTrip("~~~\ntest\n~~~~~~\n")
  }

  Void testFencedCodeBlocksFromAst()
  {
    doc := Document()
    code := FencedCode()
    code.literal = "hi code"
    doc.appendChild(code)

    verifyRendering("", "```\nhi code\n```\n", render(doc))

    code.literal = "hi`\n```\n``test"
    verifyRendering("", "````\nhi`\n```\n``test\n````\n", render(doc))
  }

  Void testHtmlBlocks()
  {
    verifyRoundTrip("<div>test</div>\n")
    verifyRoundTrip("> <div\n> test\n> </div>\n")
  }

  Void testParagraphs()
  {
    verifyRoundTrip("foo\n")
    verifyRoundTrip("foo\n\nbar\n")
  }

  // Container blocks

  Void testBlockQuotes()
  {
    verifyRoundTrip("> test\n")
    verifyRoundTrip("> foo\n> bar\n")
    verifyRoundTrip("> > foo\n> > bar\n")
    verifyRoundTrip("> # Foo\n> \n> bar\n> baz\n")
  }

  Void testBulletListItems()
  {
    verifyRoundTrip("* foo\n")
    verifyRoundTrip("- foo\n")
    verifyRoundTrip("+ foo\n")
    verifyRoundTrip("* foo\n  bar\n")
    verifyRoundTrip("* ```\n  code\n  ```\n")
    verifyRoundTrip("* foo\n\n* bar\n")

    // Note that the "  " in the second line is not necessary, but it's not wrong either.
    // We could try to avoid it in a future change, but not sure if necessary.
    verifyRoundTrip("* foo\n  \n  bar\n")

    // Tight list
    verifyRoundTrip("* foo\n* bar\n")
    // Tight list where the second item contains a loose list
    verifyRoundTrip("- Foo\n  - Bar\n  \n  - Baz\n")

    // List item indent. This is a tricky one, but here the amount of space between the
    // list marker and "one" determines whether "two" is part of the list item or an
    // indented code block.
    //
    // In this case, it's an indented code block because it's not indented enough to be
    // part of the list item. If the renderer would just use "- one", then "two" would
    // change from being an indented code block to being a paragraph in the list item!
    // So it is important for the renderer to preserve the content indent of the list item
    verifyRoundTrip(" -    one\n\n     two\n")

    // Empty list
    verifyRoundTrip("- \n\nFoo\n");
  }

  Void testBulletListItemsFromAst()
  {
    doc := Document()
    list := BulletList()
    item := ListItem(null, null)
    item.appendChild(Text("Test"))
    list.appendChild(item)
    doc.appendChild(list)

    verifyRendering("", "- Test\n", render(doc))

    list.marker = "*"
    verifyRendering("", "* Test\n", render(doc))
  }

  Void testOrderedListItems()
  {
    verifyRoundTrip("1. foo\n")
    verifyRoundTrip("2. foo\n\n3. bar\n")

    // Tight list
    verifyRoundTrip("1. foo\n2. bar\n")
    // Tight list where the second item contains a loose list
    verifyRoundTrip("1. Foo\n   1. Bar\n   \n   2. Baz\n")

    verifyRoundTrip(" 1.  one\n\n    two\n")
  }

  Void testOrderedListItemsFromAst()
  {
    doc := Document()
    list := OrderedList(null, null)
    item := ListItem(null, null)
    item.appendChild(Text("Test"))
    list.appendChild(item)
    doc.appendChild(list)

    verifyRendering("", "1. Test\n", render(doc))

    list.startNumber = 2
    list.markerDelim = ")"
    verifyRendering("", "2) Test\n", render(doc))
  }

  Void testTabs()
  {
    verifyRoundTrip("a\tb\n")
  }

  Void testEscaping()
  {
    // These are a bit tricky. We always escape some characters, even though they only need escaping if they would
    // otherwise result in a different parse result (e.g. a link):
    verifyRoundTrip("\\[a\\](/uri)\n")
    verifyRoundTrip("\\`abc\\`\n")

    // Some characters only need to be escaped at the beginning of the line
    verifyRoundTrip("\\- Test\n")
    verifyRoundTrip("\\-\n")
    verifyRoundTrip("Test -\n")
    verifyRoundTrip("Abc\n\n\\- Test\n")
    verifyRoundTrip("\\# Test\n")
    verifyRoundTrip("\\## Test\n")
    verifyRoundTrip("\\#\n")
    verifyRoundTrip("Foo\n\\===\n")
    // Only needs to be escaped after some text, not at beginning of paragraph
    verifyRoundTrip("===\n")
    verifyRoundTrip("a\n\n===\n")
    // The beginning of the line within the block, so disregarding prefixes
    verifyRoundTrip("> \\- Test\n")
    verifyRoundTrip("- \\- Test\n")
    // That's not the beginning of the line
    verifyRoundTrip("`a`- foo\n")

    // This is a bit more tricky as we need to check for a list start
    verifyRoundTrip("1\\. Foo\n")
    verifyRoundTrip("999\\. Foo\n")
    verifyRoundTrip("1\\.\n")
    verifyRoundTrip("1\\) Foo\n")

    // Escaped whitespace, wow
    verifyRoundTrip("&#9;foo\n")
    verifyRoundTrip("&#32;   foo\n")
    verifyRoundTrip("foo&#10;&#10;bar\n")
  }

  Void testCodeSpans()
  {
    verifyRoundTrip("`foo`\n")
    verifyRoundTrip("``foo ` bar``\n")
    verifyRoundTrip("```foo `` ` bar```\n")

    verifyRoundTrip("`` `foo ``\n")
    verifyRoundTrip("``  `  ``\n")
    verifyRoundTrip("` `\n")
  }

  Void testEmphasis()
  {
    verifyRoundTrip("*foo*\n")
    verifyRoundTrip("foo*bar*\n")
    // When nesting, a different delimiter needs to be used
    verifyRoundTrip("*_foo_*\n")
    verifyRoundTrip("*_*foo*_*\n")
    verifyRoundTrip("_*foo*_\n")

    // Not emphasis (needs * inside words)
    verifyRoundTrip("foo\\_bar\\_\n")

    // Even when rendering a manually constructed tree, the emphasis delimiter needs to be chosen correctly.
    // NOTE - the java Emphasis node allows a null delim, but we do not. the parser will
    // know it at parse time, so if manually constructing an AST, you need to set the delim
    doc := Document()
    p := Paragraph()
    doc.appendChild(p)
    e1 := Emphasis("*")
    p.appendChild(e1)
    e2 := Emphasis("_")
    e1.appendChild(e2)
    e2.appendChild(Text("hi"))
    verifyEq("*_hi_*\n", render(doc))
  }

  Void testStrongEmphasis()
  {
    verifyRoundTrip("**foo**\n")
    verifyRoundTrip("foo**bar**\n")
  }

  Void testLinks()
  {
    verifyRoundTrip("[link](/uri)\n")
    verifyRoundTrip("[link](/uri \"title\")\n")
    verifyRoundTrip("[link](</my uri>)\n")
    verifyRoundTrip("[a](<b)c>)\n")
    verifyRoundTrip("[a](<b(c>)\n")
    verifyRoundTrip("[a](<b\\>c>)\n")
    verifyRoundTrip("[a](<b\\\\\\>c>)\n")
    verifyRoundTrip("[a](/uri \"foo \\\" bar\")\n")
    verifyRoundTrip("[link](/uri \"tes\\\\\")\n")
    verifyRoundTrip("[link](/url \"test&#10;&#10;\")\n")
    verifyRoundTrip("[link](</url&#10;&#10;>)\n")
  }

  Void testImages()
  {
    verifyRoundTrip("![link](/uri)\n")
    verifyRoundTrip("![link](/uri \"title\")\n")
    verifyRoundTrip("![link](</my uri>)\n")
    verifyRoundTrip("![a](<b)c>)\n")
    verifyRoundTrip("![a](<b(c>)\n")
    verifyRoundTrip("![a](<b\\>c>)\n")
    verifyRoundTrip("![a](<b\\\\\\>c>)\n")
    verifyRoundTrip("![a](/uri \"foo \\\" bar\")\n")
  }

  Void testHtmlInline()
  {
    verifyRoundTrip("<del>*foo*</del>\n")
  }

  Void testHardBreak()
  {
    verifyRoundTrip("foo  \nbar\n")
  }

  Void testSoftBreak()
  {
    verifyRoundTrip("foo\nbar\n")
  }

  private Void verifyRoundTrip(Str input)
  {
    rendered := parseAndRender(input)
    verifyEq(input, rendered)
  }

  private Str parseAndRender(Str source)
  {
    parsed := parse(source)
    return render(parsed)
  }

  private Node parse(Str source) { Parser().parse(source) }
  private Str render(Node node) { MarkdownRenderer().render(node) }

  private Void verifyRendering(Str source, Str expected, Str actual)
  {
    verifyEq(expected, actual)
  }
}