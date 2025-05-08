//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   01 May 2025  Matthew Giannini  Creation
//

@Js
class SourceSpansTest : Test
{
  private static const Parser parser := Parser.builder().withIncludeSourceSpans(IncludeSourceSpans.blocks).build
  private static const Parser inlines := Parser.builder().withIncludeSourceSpans(IncludeSourceSpans.blocks_and_inlines).build

  Void testParagraph()
  {
    verifySpans("foo\n", Paragraph#, [SourceSpan.of(0,0,0,3)])
    verifySpans("foo\nbar\n", Paragraph#, [SourceSpan.of(0, 0, 0, 3), SourceSpan.of(1, 0, 4, 3)]);
    verifySpans("  foo\n  bar\n", Paragraph#, [SourceSpan.of(0, 0, 0, 5), SourceSpan.of(1, 0, 6, 5)]);
    verifySpans("> foo\n> bar\n", Paragraph#, [SourceSpan.of(0, 2, 2, 3), SourceSpan.of(1, 2, 8, 3)]);
    verifySpans("* foo\n  bar\n", Paragraph#, [SourceSpan.of(0, 2, 2, 3), SourceSpan.of(1, 2, 8, 3)]);
    verifySpans("* foo\nbar\n", Paragraph#, [SourceSpan.of(0, 2, 2, 3), SourceSpan.of(1, 0, 6, 3)]);
  }

  Void testThematicBreak()
  {
    verifySpans("---\n", ThematicBreak#, [SourceSpan.of(0, 0, 0, 3)])
    verifySpans("  ---\n", ThematicBreak#, [SourceSpan.of(0, 0, 0, 5)])
    verifySpans("> ---\n", ThematicBreak#, [SourceSpan.of(0, 2, 2, 3)])
  }

  Void testAtxHeading()
  {
    verifySpans("# foo", Heading#, [SourceSpan.of(0, 0, 0, 5)])
    verifySpans(" # foo", Heading#, [SourceSpan.of(0, 0, 0, 6)])
    verifySpans("## foo ##", Heading#, [SourceSpan.of(0, 0, 0, 9)])
    verifySpans("> # foo", Heading#, [SourceSpan.of(0, 2, 2, 5)])
  }

  Void testSetextHeading()
  {
    verifySpans("foo\n===\n", Heading#, [SourceSpan.of(0, 0, 0, 3), SourceSpan.of(1, 0, 4, 3)])
    verifySpans("foo\nbar\n====\n", Heading#, [SourceSpan.of(0, 0, 0, 3), SourceSpan.of(1, 0, 4, 3), SourceSpan.of(2, 0, 8, 4)])
    verifySpans("  foo\n  ===\n", Heading#, [SourceSpan.of(0, 0, 0, 5), SourceSpan.of(1, 0, 6, 5)])
    verifySpans("> foo\n> ===\n", Heading#, [SourceSpan.of(0, 2, 2, 3), SourceSpan.of(1, 2, 8, 3)])
  }

  Void testIndentedCode()
  {
    verifySpans("    foo\n", IndentedCode#, [SourceSpan.of(0, 0, 0, 7)])
    verifySpans("     foo\n", IndentedCode#, [SourceSpan.of(0, 0, 0, 8)])
    verifySpans("\tfoo\n", IndentedCode#, [SourceSpan.of(0, 0, 0, 4)])
    verifySpans(" \tfoo\n", IndentedCode#, [SourceSpan.of(0, 0, 0, 5)])
    verifySpans("  \tfoo\n", IndentedCode#, [SourceSpan.of(0, 0, 0, 6)])
    verifySpans("   \tfoo\n", IndentedCode#, [SourceSpan.of(0, 0, 0, 7)])
    verifySpans("    \tfoo\n", IndentedCode#, [SourceSpan.of(0, 0, 0, 8)])
    verifySpans("    \t foo\n", IndentedCode#, [SourceSpan.of(0, 0, 0, 9)])
    verifySpans("\t foo\n", IndentedCode#, [SourceSpan.of(0, 0, 0, 5)])
    verifySpans("\t  foo\n", IndentedCode#, [SourceSpan.of(0, 0, 0, 6)])
    verifySpans("    foo\n     bar\n", IndentedCode#, [SourceSpan.of(0, 0, 0, 7), SourceSpan.of(1, 0, 8, 8)])
    verifySpans("    foo\n\tbar\n", IndentedCode#, [SourceSpan.of(0, 0, 0, 7), SourceSpan.of(1, 0, 8, 4)])
    verifySpans("    foo\n    \n     \n", IndentedCode#, [SourceSpan.of(0, 0, 0, 7), SourceSpan.of(1, 0, 8, 4), SourceSpan.of(2, 0, 13, 5)])
    verifySpans(">     foo\n", IndentedCode#, [SourceSpan.of(0, 2, 2, 7)])
  }

  Void testFencedCodeBlock()
  {
    verifySpans("```\nfoo\n```\n", FencedCode#,
            [SourceSpan.of(0, 0, 0, 3), SourceSpan.of(1, 0, 4, 3), SourceSpan.of(2, 0, 8, 3)])
    verifySpans("```\n foo\n```\n", FencedCode#,
            [SourceSpan.of(0, 0, 0, 3), SourceSpan.of(1, 0, 4, 4), SourceSpan.of(2, 0, 9, 3)])
    verifySpans("```\nfoo\nbar\n```\n", FencedCode#,
            [SourceSpan.of(0, 0, 0, 3), SourceSpan.of(1, 0, 4, 3), SourceSpan.of(2, 0, 8, 3), SourceSpan.of(3, 0, 12, 3)])
    verifySpans("   ```\n   foo\n   ```\n", FencedCode#,
            [SourceSpan.of(0, 0, 0, 6), SourceSpan.of(1, 0, 7, 6), SourceSpan.of(2, 0, 14, 6)])
    verifySpans(" ```\n foo\nfoo\n```\n", FencedCode#,
            [SourceSpan.of(0, 0, 0, 4), SourceSpan.of(1, 0, 5, 4), SourceSpan.of(2, 0, 10, 3), SourceSpan.of(3, 0, 14, 3)])
    verifySpans("```info\nfoo\n```\n", FencedCode#,
            [SourceSpan.of(0, 0, 0, 7), SourceSpan.of(1, 0, 8, 3), SourceSpan.of(2, 0, 12, 3)])
    verifySpans("* ```\n  foo\n  ```\n", FencedCode#,
            [SourceSpan.of(0, 2, 2, 3), SourceSpan.of(1, 2, 8, 3), SourceSpan.of(2, 2, 14, 3)])
    verifySpans("> ```\n> foo\n> ```\n", FencedCode#,
            [SourceSpan.of(0, 2, 2, 3), SourceSpan.of(1, 2, 8, 3), SourceSpan.of(2, 2, 14, 3)])


    doc := parser.parse("```\nfoo\n```\nbar\n")
    para := (Paragraph)doc.lastChild
    verifyEq(SourceSpan[SourceSpan.of(3,0,12,3)], para.sourceSpans)
  }

  Void testHtmlBlock()
  {
    verifySpans("<div>\n", HtmlBlock#, [SourceSpan.of(0, 0, 0, 5)])
    verifySpans(" <div>\n foo\n </div>\n", HtmlBlock#,
            [SourceSpan.of(0, 0, 0, 6),
            SourceSpan.of(1, 0, 7, 4),
            SourceSpan.of(2, 0, 12, 7)])
    verifySpans("* <div>\n", HtmlBlock#, [SourceSpan.of(0, 2, 2, 5)])
  }

  Void testBlockQuote()
  {
    verifySpans(">foo\n", BlockQuote#, [SourceSpan.of(0, 0, 0, 4)])
    verifySpans("> foo\n", BlockQuote#, [SourceSpan.of(0, 0, 0, 5)])
    verifySpans(">  foo\n", BlockQuote#, [SourceSpan.of(0, 0, 0, 6)])
    verifySpans(" > foo\n", BlockQuote#, [SourceSpan.of(0, 0, 0, 6)])
    verifySpans("   > foo\n  > bar\n", BlockQuote#, [SourceSpan.of(0, 0, 0, 8), SourceSpan.of(1, 0, 9, 7)])
    // Lazy continuations
    verifySpans("> foo\nbar\n", BlockQuote#, [SourceSpan.of(0, 0, 0, 5), SourceSpan.of(1, 0, 6, 3)])
    verifySpans("> foo\nbar\n> baz\n", BlockQuote#, [SourceSpan.of(0, 0, 0, 5), SourceSpan.of(1, 0, 6, 3), SourceSpan.of(2, 0, 10, 5)])
    verifySpans("> > foo\nbar\n", BlockQuote#, [SourceSpan.of(0, 0, 0, 7), SourceSpan.of(1, 0, 8, 3)])
  }

  Void testListBlock()
  {
    verifySpans("* foo\n", ListBlock#, [SourceSpan.of(0, 0, 0, 5)])
    verifySpans("* foo\n  bar\n", ListBlock#, [SourceSpan.of(0, 0, 0, 5), SourceSpan.of(1, 0, 6, 5)])
    verifySpans("* foo\n* bar\n", ListBlock#, [SourceSpan.of(0, 0, 0, 5), SourceSpan.of(1, 0, 6, 5)])
    verifySpans("* foo\n  # bar\n", ListBlock#, [SourceSpan.of(0, 0, 0, 5), SourceSpan.of(1, 0, 6, 7)])
    verifySpans("* foo\n  * bar\n", ListBlock#, [SourceSpan.of(0, 0, 0, 5), SourceSpan.of(1, 0, 6, 7)])
    verifySpans("* foo\n> bar\n", ListBlock#, [SourceSpan.of(0, 0, 0, 5)])
    verifySpans("> * foo\n", ListBlock#, [SourceSpan.of(0, 2, 2, 5)])

    // Lazy continuations
    verifySpans("* foo\nbar\nbaz", ListBlock#, [SourceSpan.of(0, 0, 0, 5), SourceSpan.of(1, 0, 6, 3), SourceSpan.of(2, 0, 10, 3)])
    verifySpans("* foo\nbar\n* baz", ListBlock#, [SourceSpan.of(0, 0, 0, 5), SourceSpan.of(1, 0, 6, 3), SourceSpan.of(2, 0, 10, 5)])
    verifySpans("* foo\n  * bar\nbaz", ListBlock#, [SourceSpan.of(0, 0, 0, 5), SourceSpan.of(1, 0, 6, 7), SourceSpan.of(2, 0, 14, 3)])

    doc := parser.parse("* foo\n  * bar\n")
    listBlock := (ListBlock)doc.firstChild.firstChild.lastChild
    verifyEq(SourceSpan[SourceSpan.of(1,2,8,5)], listBlock.sourceSpans)
  }

  Void testListItem()
  {
    verifySpans("* foo\n", ListItem#, [SourceSpan.of(0, 0, 0, 5)])
    verifySpans(" * foo\n", ListItem#, [SourceSpan.of(0, 0, 0, 6)])
    verifySpans("  * foo\n", ListItem#, [SourceSpan.of(0, 0, 0, 7)])
    verifySpans("   * foo\n", ListItem#, [SourceSpan.of(0, 0, 0, 8)])
    verifySpans("*\n  foo\n", ListItem#, [SourceSpan.of(0, 0, 0, 1), SourceSpan.of(1, 0, 2, 5)])
    verifySpans("*\n  foo\n  bar\n", ListItem#, [SourceSpan.of(0, 0, 0, 1), SourceSpan.of(1, 0, 2, 5), SourceSpan.of(2, 0, 8, 5)])
    verifySpans("> * foo\n", ListItem#, [SourceSpan.of(0, 2, 2, 5)])

    // Lazy continuations
    verifySpans("* foo\nbar\n", ListItem#, [SourceSpan.of(0, 0, 0, 5), SourceSpan.of(1, 0, 6, 3)])
    verifySpans("* foo\nbar\nbaz\n", ListItem#, [SourceSpan.of(0, 0, 0, 5), SourceSpan.of(1, 0, 6, 3), SourceSpan.of(2, 0, 10, 3)])
  }

  Void testLinkRefDef()
  {
    // this is tricky due to how link reference definition parsing works. it is stripped
    // from the paragraph if it's successfully parsed, otherwise it stays part of the
    // paragraph
    doc := parser.parse("[foo]: /url\ntext\n")

    linkRefDef := (LinkReferenceDefinition)doc.firstChild
    verifyEq(SourceSpan[SourceSpan.of(0,0,0,11)], linkRefDef.sourceSpans)

    p := (Paragraph)doc.lastChild
    verifyEq(SourceSpan[SourceSpan.of(1,0,12,4)], p.sourceSpans)
  }

  Void testLinkRefDefMultiple()
  {
    doc := parser.parse("[foo]: /foo\n[bar]: /bar\n")
    def1 := doc.firstChild
    def2 := doc.lastChild
    verifyEq(SourceSpan[SourceSpan.of(0,0,0,11)], def1.sourceSpans)
    verifyEq(SourceSpan[SourceSpan.of(1,0,12,11)], def2.sourceSpans)
  }

  Void testLinkRefDefWithTitle()
  {
    doc  := parser.parse("[1]: #not-code \"Text\"\n[foo]: /foo\n")
    def1 := (LinkReferenceDefinition) doc.firstChild
    def2 := (LinkReferenceDefinition) doc.lastChild
    verifyEq(SourceSpan[SourceSpan.of(0, 0, 0, 21)], def1.sourceSpans)
    verifyEq(SourceSpan[SourceSpan.of(1, 0, 22, 11)], def2.sourceSpans)
  }

  Void testLinkRefDefWithTitleInvalid()
  {
    doc := parser.parse("[foo]: /url\n\"title\" ok\n")
    def := doc.find(LinkReferenceDefinition#)
    p  := doc.find(Paragraph#)
    verifyEq(SourceSpan[SourceSpan.of(0,0,0,11)], def.sourceSpans)
    verifyEq(SourceSpan[SourceSpan.of(1,0,12,10)], p.sourceSpans)
  }

  Void testLinkRefDefHeading()
  {
    // this is probably the trickiest because we have a link reference definition
    // at the start of a paragraph that gets replaced because of a heading. Phew!
    doc := parser.parse("[foo]: /url\nHeading\n===\n")

    def := (LinkReferenceDefinition)doc.firstChild
    verifyEq(SourceSpan[SourceSpan.of(0,0,0,11)], def.sourceSpans)

    heading := (Heading) doc.lastChild
    verifyEq(SourceSpan[SourceSpan.of(1,0,12,7), SourceSpan.of(2,0,20,3)], heading.sourceSpans)
  }

  Void testLazyContinuationLines()
  {
    // From https://spec.commonmark.org/0.31.2/#example-250
    // Wrong source span for the inner block quote for the second line.
    doc := parser.parse("> > > foo\nbar\n");

    bq1 := (BlockQuote) doc.lastChild
    verifyEq(SourceSpan[SourceSpan.of(0, 0, 0, 9), SourceSpan.of(1, 0, 10, 3)], bq1.sourceSpans)
    bq2 := (BlockQuote) bq1.lastChild
    verifyEq(SourceSpan[SourceSpan.of(0, 2, 2, 7), SourceSpan.of(1, 0, 10, 3)], bq2.sourceSpans)
    bq3 := (BlockQuote) bq2.lastChild
    verifyEq(SourceSpan[SourceSpan.of(0, 4, 4, 5), SourceSpan.of(1, 0, 10, 3)], bq3.sourceSpans)
    paragraph := (Paragraph) bq3.lastChild
    verifyEq(SourceSpan[SourceSpan.of(0, 6, 6, 3), SourceSpan.of(1, 0, 10, 3)], paragraph.sourceSpans)

    // adding one character to the last line remove bq3 source for the second line
    doc = parser.parse("> > > foo\nbars\n")

    bq1 = (BlockQuote) doc.lastChild
    verifyEq(SourceSpan[SourceSpan.of(0, 0, 0, 9), SourceSpan.of(1, 0, 10, 4)], bq1.sourceSpans)
    bq2 = (BlockQuote) bq1.lastChild
    verifyEq(SourceSpan[SourceSpan.of(0, 2, 2, 7), SourceSpan.of(1, 0, 10, 4)], bq2.sourceSpans)
    bq3 = (BlockQuote) bq2.lastChild
    verifyEq(SourceSpan[SourceSpan.of(0, 4, 4, 5), SourceSpan.of(1, 0, 10, 4)], bq3.sourceSpans)
    paragraph = (Paragraph) bq3.lastChild
    verifyEq(SourceSpan[SourceSpan.of(0, 6, 6, 3), SourceSpan.of(1, 0, 10, 4)], paragraph.sourceSpans)

    // From https://spec.commonmark.org/0.31.2/#example-292
    doc = parser.parse("> 1. > Blockquote\ncontinued here.")

    bq1 = (BlockQuote) doc.lastChild
    verifyEq(SourceSpan[SourceSpan.of(0, 0, 0, 17), SourceSpan.of(1, 0, 18, 15)], bq1.sourceSpans)
    orderedList := (OrderedList) bq1.lastChild
    verifyEq(SourceSpan[SourceSpan.of(0, 2, 2, 15), SourceSpan.of(1, 0, 18, 15)], orderedList.sourceSpans)
    listItem := (ListItem) orderedList.lastChild
    verifyEq(SourceSpan[SourceSpan.of(0, 2, 2, 15), SourceSpan.of(1, 0, 18, 15)], listItem.sourceSpans)
    bq2 = (BlockQuote) listItem.lastChild
    verifyEq(SourceSpan[SourceSpan.of(0, 5, 5, 12), SourceSpan.of(1, 0, 18, 15)], bq2.sourceSpans)
    paragraph = (Paragraph) bq2.lastChild
    verifyEq(SourceSpan[SourceSpan.of(0, 7, 7, 10), SourceSpan.of(1, 0, 18, 15)], paragraph.sourceSpans)

    // Lazy continuation line for nested blockquote
    doc = parser.parse("> > foo\n> bar\n")

    bq1 = (BlockQuote) doc.lastChild
    verifyEq(SourceSpan[SourceSpan.of(0, 0, 0, 7), SourceSpan.of(1, 0, 8, 5)], bq1.sourceSpans)
    bq2 = (BlockQuote) bq1.lastChild
    verifyEq(SourceSpan[SourceSpan.of(0, 2, 2, 5), SourceSpan.of(1, 2, 10, 3)], bq2.sourceSpans)
    paragraph = (Paragraph) bq2.lastChild
    verifyEq(SourceSpan[SourceSpan.of(0, 4, 4, 3), SourceSpan.of(1, 2, 10, 3)], paragraph.sourceSpans)
  }

  // TODO: visualCheck

  Void testInlineText()
  {
    verifyInline("foo", Text#, [SourceSpan.of(0, 0, 0, 3)])
    verifyInline("> foo", Text#, [SourceSpan.of(0, 2, 2, 3)])
    verifyInline("* foo", Text#, [SourceSpan.of(0, 2, 2, 3)])

    // SourceSpans should be merged: ` is a separate Text node while inline parsing and gets merged at the end
    verifyInline("foo`bar", Text#, [SourceSpan.of(0, 0, 0, 7)])
    verifyInline("foo[bar", Text#, [SourceSpan.of(0, 0, 0, 7)])
    verifyInline("> foo`bar", Text#, [SourceSpan.of(0, 2, 2, 7)])

    verifyInline("[foo](/url)", Text#, [SourceSpan.of(0, 1, 1, 3)])
    verifyInline("*foo*", Text#, [SourceSpan.of(0, 1, 1, 3)])
  }

  Void testInlineHeading()
  {
    verifyInline("# foo", Text#, [SourceSpan.of(0, 2, 2, 3)])
    verifyInline(" # foo", Text#, [SourceSpan.of(0, 3, 3, 3)])
    verifyInline("> # foo", Text#, [SourceSpan.of(0, 4, 4, 3)])
  }

  Void testInlineAutoLink()
  {
    verifyInline("see <https://example.org>", Link#, [SourceSpan.of(0, 4, 4, 21)])
  }

  Void testInlineBackslash()
  {
     verifyInline("\\!", Text#, [SourceSpan.of(0, 0, 0, 2)])
  }

  Void testInlineBackticks()
  {
    verifyInline("see `code`", Code#, [SourceSpan.of(0, 4, 4, 6)])
    verifyInline("`multi\nline`", Code#,
            [SourceSpan.of(0, 0, 0, 6),
             SourceSpan.of(1, 0, 7, 5)])
    verifyInline("text ```", Text#, [SourceSpan.of(0, 0, 0, 8)])
  }

  Void testInlineEntity()
  {
    verifyInline("&amp;", Text#, [SourceSpan.of(0, 0, 0, 5)])
  }

  Void testInlineHtml()
  {
    verifyInline("hi <strong>there</strong>", HtmlInline#, [SourceSpan.of(0, 3, 3, 8)])
  }

  Void testLinks()
  {
    verifyInline("\n[text](/url)", Link#, [SourceSpan.of(1, 0, 1, 12)])
    verifyInline("\n[text](/url)", Text#, [SourceSpan.of(1, 1, 2, 4)])

    verifyInline("\n[text]\n\n[text]: /url", Link#, [SourceSpan.of(1, 0, 1, 6)])
    verifyInline("\n[text]\n\n[text]: /url", Text#, [SourceSpan.of(1, 1, 2, 4)])
    verifyInline("\n[text][]\n\n[text]: /url", Link#, [SourceSpan.of(1, 0, 1, 8)])
    verifyInline("\n[text][]\n\n[text]: /url", Text#, [SourceSpan.of(1, 1, 2, 4)])
    verifyInline("\n[text][ref]\n\n[ref]: /url", Link#, [SourceSpan.of(1, 0, 1, 11)])
    verifyInline("\n[text][ref]\n\n[ref]: /url", Text#, [SourceSpan.of(1, 1, 2, 4)])
    verifyInline("\n[notalink]", Text#, [SourceSpan.of(1, 0, 1, 10)])
  }

  Void testInlineEmphasis()
  {
    verifyInline("\n*hey*", Emphasis#, [SourceSpan.of(1, 0, 1, 5)])
    verifyInline("\n*hey*", Text#, [SourceSpan.of(1, 1, 2, 3)])
    verifyInline("\n**hey**", StrongEmphasis#, [SourceSpan.of(1, 0, 1, 7)])
    verifyInline("\n**hey**", Text#, [SourceSpan.of(1, 2, 3, 3)])

    // This is an interesting one. It renders like this:
    // <p>*<em>hey</em></p>
    // The delimiter processor only uses one of the asterisks.
    // So the first Text node should be the `*` at the beginning with the correct span.
    verifyInline("\n**hey*", Text#, [SourceSpan.of(1, 0, 1, 1)])
    verifyInline("\n**hey*", Emphasis#, [SourceSpan.of(1, 1, 2, 5)])

    verifyInline("\n***hey**", Text#, [SourceSpan.of(1, 0, 1, 1)])
    verifyInline("\n***hey**", StrongEmphasis#, [SourceSpan.of(1, 1, 2, 7)])

    doc := inlines.parse("*hey**")
    lastText := doc.firstChild.lastChild
    verifyEq(SourceSpan[SourceSpan.of(0,5,5,1)], lastText.sourceSpans)
  }

  Void testTabExpansion()
  {
    verifyInline(">\tfoo", BlockQuote#, [SourceSpan.of(0, 0, 0, 5)])
    verifyInline(">\tfoo", Text#, [SourceSpan.of(0, 2, 2, 3)])

    verifyInline("a\tb", Text#, [SourceSpan.of(0, 0, 0, 3)])
  }

  Void testDifferentLineTerminators()
  {
    input := "foo\nbar\rbaz\r\nqux\r\n\r\n> *hi*"
    verifySpans(input, Paragraph#,
            [SourceSpan.of(0, 0, 0, 3),
             SourceSpan.of(1, 0, 4, 3),
             SourceSpan.of(2, 0, 8, 3),
             SourceSpan.of(3, 0, 13, 3)])
    verifySpans(input, BlockQuote#,
            [SourceSpan.of(5, 0, 20, 6)])

    verifyInline(input, Emphasis#, [SourceSpan.of(5, 2, 22, 4)])
  }

  private Void verifySpans(Str input, Type nodeType, SourceSpan[] expected)
  {
    doVerifySpans(parser.parse(input), nodeType, expected)
  }

  private Void doVerifySpans(Node rootNode, Type nodeType, SourceSpan[] expected)
  {
    // need to do this to force non-nullable
    exp := SourceSpan[,].addAll(expected)
    node := rootNode.find(nodeType)
    verifyEq(exp, node.sourceSpans)
  }

  private Void verifyInline(Str input, Type nodeType, SourceSpan[] expected)
  {
    doVerifySpans(inlines.parse(input), nodeType, expected)
  }
}