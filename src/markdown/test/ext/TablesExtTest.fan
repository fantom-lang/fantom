//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   04 Nov 2024  Matthew Giannini  Creation
//

@Js
class TablesExtTest : RenderingTest
{
  private static const MarkdownExt[] exts := [TablesExt()]
  private static const Parser parser := Parser.builder.extensions(exts).build
  private static const HtmlRenderer renderer := HtmlRenderer.builder.extensions(exts).build
  private static const MarkdownRenderer md := MarkdownRenderer.builder.extensions(exts).build

  Void testMustHaveHeaderAndSeparator()
  {
    verifyRendering("Abc|Def", "<p>Abc|Def</p>\n")
    verifyRendering("Abc | Def", "<p>Abc | Def</p>\n")
  }

  Void testSeparatorMustBeOneOrMore()
  {
    verifyRendering("Abc|Def\n-|-",
      Str<|<table>
           <thead>
           <tr>
           <th>Abc</th>
           <th>Def</th>
           </tr>
           </thead>
           </table>
          |>)
    verifyRendering("Abc|Def\n--|--",
      Str<|<table>
           <thead>
           <tr>
           <th>Abc</th>
           <th>Def</th>
           </tr>
           </thead>
           </table>
          |>)
  }

  Void testSeparatorMustNotContainInvalidChars()
  {
    verifyRendering("Abc|Def\n |-a-|---", "<p>Abc|Def\n|-a-|---</p>\n")
    verifyRendering("Abc|Def\n |:--a|---", "<p>Abc|Def\n|:--a|---</p>\n")
    verifyRendering("Abc|Def\n |:--a--:|---", "<p>Abc|Def\n|:--a--:|---</p>\n")
  }

  Void testSeparatorCanHaveLeadingSpaceThenPipe()
  {
    verifyRendering("Abc|Def\n |---|---",
      Str<|<table>
           <thead>
           <tr>
           <th>Abc</th>
           <th>Def</th>
           </tr>
           </thead>
           </table>
          |>)
  }

  Void testSeparatorCanNotHaveAdjacentPipes()
  {
    verifyRendering("Abc|Def\n---||---", "<p>Abc|Def\n---||---</p>\n")
  }

  Void testSeparatorNeedsPipes()
  {
    verifyRendering("Abc|Def\n|--- ---", "<p>Abc|Def\n|--- ---</p>\n")
  }

  Void testOneHeadNoBody()
  {
    verifyRendering("Abc|Def\n---|---",
      Str<|<table>
           <thead>
           <tr>
           <th>Abc</th>
           <th>Def</th>
           </tr>
           </thead>
           </table>
          |>)
  }

  Void testOneColumnOneHeadNoBody()
  {
    expected := Str<|<table>
                     <thead>
                     <tr>
                     <th>Abc</th>
                     </tr>
                     </thead>
                     </table>
                    |>
    verifyRendering("|Abc\n|---\n", expected)
    verifyRendering("|Abc|\n|---|\n", expected)
    verifyRendering("Abc|\n---|\n", expected)

    // pipe required on separator
    verifyRendering("|Abc\n---\n", "<h2>|Abc</h2>\n")
    // pipe required on head
    verifyRendering("Abc\n|---\n", "<p>Abc\n|---</p>\n")
  }

  Void testOneColumnOneHeadOneBody()
  {
    expected := Str<|<table>
                     <thead>
                     <tr>
                     <th>Abc</th>
                     </tr>
                     </thead>
                     <tbody>
                     <tr>
                     <td>1</td>
                     </tr>
                     </tbody>
                     </table>
                    |>
    verifyRendering("|Abc\n|---\n|1", expected)
    verifyRendering("|Abc|\n|---|\n|1|", expected)
    verifyRendering("Abc|\n---|\n1|", expected)

    // pipe required on separator
    verifyRendering("|Abc\n---\n|1", "<h2>|Abc</h2>\n<p>|1</p>\n")
  }

  private static const Str expected2cells :=
      Str<|<table>
           <thead>
           <tr>
           <th>Abc</th>
           <th>Def</th>
           </tr>
           </thead>
           <tbody>
           <tr>
           <td>1</td>
           <td>2</td>
           </tr>
           </tbody>
           </table>
          |>

  Void testOneHeadOneBody()
  {
    verifyRendering("Abc|Def\n---|---\n1|2", expected2cells)
  }

  Void testSpaceBeforeSeparator()
  {
    verifyRendering("  |Abc|Def|\n  |---|---|\n  |1|2|", expected2cells)
  }

  Void testSeparatorMustNotHaveLessPartsThanHead()
  {
    verifyRendering("Abc|Def|Ghi\n---|---\n1|2|3", "<p>Abc|Def|Ghi\n---|---\n1|2|3</p>\n")
  }

  Void testPadding()
  {
    verifyRendering(" Abc  | Def \n --- | --- \n 1 | 2 ", expected2cells)
  }

  Void testPaddingWithCodeBlockIndentation()
  {
    verifyRendering("Abc|Def\n---|---\n    1|2", expected2cells)
  }

  Void testPipesOnOutside()
  {
    verifyRendering("|Abc|Def|\n|---|---|\n|1|2|", expected2cells)
  }

  Void testPipesOnOutsideWhitespaceAfterHeader()
  {
    verifyRendering("|Abc|Def| \n|---|---|\n|1|2|", expected2cells)
  }

  Void testPipesOnOutsideZeroLengthHeaders()
  {
    verifyRendering("""||center header||
                       -|-------------|-
                       1|      2      |3""",
                    """<table>
                       <thead>
                       <tr>
                       <th></th>
                       <th>center header</th>
                       <th></th>
                       </tr>
                       </thead>
                       <tbody>
                       <tr>
                       <td>1</td>
                       <td>2</td>
                       <td>3</td>
                       </tr>
                       </tbody>
                       </table>
                       """)

  }

  Void testInlineElements()
  {
    verifyRendering("*Abc*|Def\n---|---\n1|2",
      Str<|<table>
           <thead>
           <tr>
           <th><em>Abc</em></th>
           <th>Def</th>
           </tr>
           </thead>
           <tbody>
           <tr>
           <td>1</td>
           <td>2</td>
           </tr>
           </tbody>
           </table>
          |>)
  }

  Void testEscapedPipe()
  {
    verifyRendering("Abc|Def\n---|---\n1\\|2|20",
      Str<|<table>
           <thead>
           <tr>
           <th>Abc</th>
           <th>Def</th>
           </tr>
           </thead>
           <tbody>
           <tr>
           <td>1|2</td>
           <td>20</td>
           </tr>
           </tbody>
           </table>
          |>)
  }

  Void testEscapedBackslash()
  {
    // This is a bit weird in the GFM spec IMO. `1\\|2` looks like an escaped backslash, followed by a pipe
    // (so two cells). Instead, the `\|` is parsed as an escaped pipe first, so just a single cell. The inline
    // parser then gets `1\|2` which renders as `1|2`.
    verifyRendering("Abc|Def\n---|---\n1\\\\|2",
      Str<|<table>
           <thead>
           <tr>
           <th>Abc</th>
           <th>Def</th>
           </tr>
           </thead>
           <tbody>
           <tr>
           <td>1|2</td>
           <td></td>
           </tr>
           </tbody>
           </table>
          |>)
  }

  Void testEscapedOther()
  {
    // This is a tricky one. For \`, we don't want to remove the backslash when we parse the table, otherwise
    // inline parsing is wrong. So we have to be careful where we do/don't consume the backslash.
    verifyRendering("Abc|Def\n---|---\n1|\\`not code`",
      Str<|<table>
           <thead>
           <tr>
           <th>Abc</th>
           <th>Def</th>
           </tr>
           </thead>
           <tbody>
           <tr>
           <td>1</td>
           <td>`not code`</td>
           </tr>
           </tbody>
           </table>
          |>)
  }

  Void testBackslashAtEnd()
  {
    // this fails round-trip, but i think the error is in the parser, not the renderer
    // see note in TableParser.split - backslash escaping apparently not supported
    this.doRoundTrip = false
    verifyRendering("Abc|Def\n---|---\n1|2\\",
      Str<|<table>
           <thead>
           <tr>
           <th>Abc</th>
           <th>Def</th>
           </tr>
           </thead>
           <tbody>
           <tr>
           <td>1</td>
           <td>2\</td>
           </tr>
           </tbody>
           </table>
          |>)
  }

  Void testAlignLeft()
  {
    expect :=
      Str<|<table>
           <thead>
           <tr>
           <th align="left">Abc</th>
           <th>Def</th>
           </tr>
           </thead>
           <tbody>
           <tr>
           <td align="left">1</td>
           <td>2</td>
           </tr>
           </tbody>
           </table>
          |>
    verifyRendering("Abc|Def\n:-|-\n1|2", expect)
    verifyRendering("Abc|Def\n:--|--\n1|2", expect)
    verifyRendering("Abc|Def\n:---|---\n1|2", expect)
  }

  Void testAlignRight()
  {
    expect :=
      Str<|<table>
           <thead>
           <tr>
           <th align="right">Abc</th>
           <th>Def</th>
           </tr>
           </thead>
           <tbody>
           <tr>
           <td align="right">1</td>
           <td>2</td>
           </tr>
           </tbody>
           </table>
          |>
    verifyRendering("Abc|Def\n-:|-\n1|2", expect)
    verifyRendering("Abc|Def\n--:|--\n1|2", expect)
    verifyRendering("Abc|Def\n---:|---\n1|2", expect)
  }

  Void testAlignCenter()
  {
    expect :=
      Str<|<table>
           <thead>
           <tr>
           <th align="center">Abc</th>
           <th>Def</th>
           </tr>
           </thead>
           <tbody>
           <tr>
           <td align="center">1</td>
           <td>2</td>
           </tr>
           </tbody>
           </table>
          |>
    verifyRendering("Abc|Def\n:-:|-\n1|2", expect)
    verifyRendering("Abc|Def\n:--:|--\n1|2", expect)
    verifyRendering("Abc|Def\n:---:|---\n1|2", expect)
  }

  Void testAlignCenterSecond()
  {
    verifyRendering("Abc|Def\n---|:---:\n1|2",
      Str<|<table>
           <thead>
           <tr>
           <th>Abc</th>
           <th align="center">Def</th>
           </tr>
           </thead>
           <tbody>
           <tr>
           <td>1</td>
           <td align="center">2</td>
           </tr>
           </tbody>
           </table>
          |>)
  }

  Void testAlignLeftWithSpaces()
  {
    verifyRendering("Abc|Def\n :--- |---\n1|2",
      Str<|<table>
           <thead>
           <tr>
           <th align="left">Abc</th>
           <th>Def</th>
           </tr>
           </thead>
           <tbody>
           <tr>
           <td align="left">1</td>
           <td>2</td>
           </tr>
           </tbody>
           </table>
          |>)
  }

  Void testAlignmentMarkerMustBeNextToDashs()
  {
    verifyRendering("Abc|Def\n: ---|---", "<p>Abc|Def\n: ---|---</p>\n")
    verifyRendering("Abc|Def\n--- :|---", "<p>Abc|Def\n--- :|---</p>\n")
    verifyRendering("Abc|Def\n---|: ---", "<p>Abc|Def\n---|: ---</p>\n")
    verifyRendering("Abc|Def\n---|--- :", "<p>Abc|Def\n---|--- :</p>\n")
  }

  Void testBodyCanNotHaveMoreColumnsThanHead()
  {
    verifyRendering("Abc|Def\n---|---\n1|2|3", expected2cells)
  }

  Void testBodyWithFewerColumnsThanHeadresultsInEmptyCells()
  {
    verifyRendering("Abc|Def|Ghi\n---|---|---\n1|2",
      Str<|<table>
           <thead>
           <tr>
           <th>Abc</th>
           <th>Def</th>
           <th>Ghi</th>
           </tr>
           </thead>
           <tbody>
           <tr>
           <td>1</td>
           <td>2</td>
           <td></td>
           </tr>
           </tbody>
           </table>
          |>)
  }

  Void testInsideBlockQuote()
  {
    verifyRendering("> Abc|Def\n> ---|---\n> 1|2",
      """<blockquote>
         ${expected2cells.trim}
         </blockquote>
         """)
  }

  Void testTableWithLazyContinuationLine()
  {
    verifyRendering("Abc|Def\n---|---\n1|2\nlazy",
      Str<|<table>
           <thead>
           <tr>
           <th>Abc</th>
           <th>Def</th>
           </tr>
           </thead>
           <tbody>
           <tr>
           <td>1</td>
           <td>2</td>
           </tr>
           <tr>
           <td>lazy</td>
           <td></td>
           </tr>
           </tbody>
           </table>
          |>)
  }

  // Cannot do this test because of utf-8 encoding issue
  // Void testIssue142()
  // {
  // }

  Void testDanglingPipe()
  {
    verifyRendering("Abc|Def\n---|---\n1|2\n|",
      """${expected2cells.trim}
         <p>|</p>\n""")
    verifyRendering("Abc|Def\n---|---\n1|2\n  |  ",
      """${expected2cells.trim}
         <p>|</p>\n""")
  }

  Void testInterruptsParagraph()
  {
    verifyRendering("text\n|a  |\n|---|\n|b  |",
      Str<|<p>text</p>
           <table>
           <thead>
           <tr>
           <th>a</th>
           </tr>
           </thead>
           <tbody>
           <tr>
           <td>b</td>
           </tr>
           </tbody>
           </table>
          |>)
  }

  Void testAttrProviderIsApplied()
  {
    renderer := HtmlRenderer.builder
      .attrProviderFactory(|cx->AttrProvider| { TablesTestAttrProvider() })
      .extensions(exts)
      .build
    verifyEq(renderer.render(parser.parse("Abc|Def\n-----|---\n1|2")),
      Str<|<table test="block">
           <thead test="head">
           <tr test="row">
           <th test="cell" width="5em">Abc</th>
           <th test="cell" width="3em">Def</th>
           </tr>
           </thead>
           <tbody test="body">
           <tr test="row">
           <td test="cell">1</td>
           <td test="cell">2</td>
           </tr>
           </tbody>
           </table>
          |>)
  }

  // TODO: test source spans

//////////////////////////////////////////////////////////////////////////
// GFM Spec Tests - python tool not working to extract these teset
// and there are only a few so handcode them
//////////////////////////////////////////////////////////////////////////

  Void testGfmSpec()
  {
    verifyRendering(
      Str<|| foo | bar |
           | --- | --- |
           | baz | bim ||>,
      Str<|<table>
           <thead>
           <tr>
           <th>foo</th>
           <th>bar</th>
           </tr>
           </thead>
           <tbody>
           <tr>
           <td>baz</td>
           <td>bim</td>
           </tr>
           </tbody>
           </table>
          |>)

    verifyRendering(
      Str<|| abc | defghi |
           :-: | -----------:
           bar | baz|>,
      Str<|<table>
           <thead>
           <tr>
           <th align="center">abc</th>
           <th align="right">defghi</th>
           </tr>
           </thead>
           <tbody>
           <tr>
           <td align="center">bar</td>
           <td align="right">baz</td>
           </tr>
           </tbody>
           </table>
          |>)

    verifyRendering(
      Str<|| f\|oo  |
           | ------ |
           | b `\|` az |
           | b **\|** im |>,
      Str<|<table>
           <thead>
           <tr>
           <th>f|oo</th>
           </tr>
           </thead>
           <tbody>
           <tr>
           <td>b <code>|</code> az</td>
           </tr>
           <tr>
           <td>b <strong>|</strong> im</td>
           </tr>
           </tbody>
           </table>
          |>)

    verifyRendering(
      Str<|| abc | def |
           | --- | --- |
           | bar | baz |
           > bar|>,
      Str<|<table>
           <thead>
           <tr>
           <th>abc</th>
           <th>def</th>
           </tr>
           </thead>
           <tbody>
           <tr>
           <td>bar</td>
           <td>baz</td>
           </tr>
           </tbody>
           </table>
           <blockquote>
           <p>bar</p>
           </blockquote>
          |>)

    verifyRendering(
      Str<|| abc | def |
           | --- | --- |
           | bar | baz |
           bar

           bar|>,
      Str<|<table>
           <thead>
           <tr>
           <th>abc</th>
           <th>def</th>
           </tr>
           </thead>
           <tbody>
           <tr>
           <td>bar</td>
           <td>baz</td>
           </tr>
           <tr>
           <td>bar</td>
           <td></td>
           </tr>
           </tbody>
           </table>
           <p>bar</p>
          |>)

    verifyRendering(
      Str<|| abc | def |
           | --- |
           | bar ||>,
      Str<|<p>| abc | def |
           | --- |
           | bar |</p>
          |>)

    verifyRendering(
      Str<|| abc | def |
           | --- | --- |
           | bar |
           | bar | baz | bool ||>,
      Str<|<table>
           <thead>
           <tr>
           <th>abc</th>
           <th>def</th>
           </tr>
           </thead>
           <tbody>
           <tr>
           <td>bar</td>
           <td></td>
           </tr>
           <tr>
           <td>bar</td>
           <td>baz</td>
           </tr>
           </tbody>
           </table>
          |>)

    verifyRendering(
      Str<|| abc | def |
           | --- | --- ||>,
      Str<|<table>
           <thead>
           <tr>
           <th>abc</th>
           <th>def</th>
           </tr>
           </thead>
           </table>
          |>)
  }


  protected override Str render(Str source)
  {
    doc  := parser.parse(source)
    html := renderer.render(doc)
    mark := md.render(doc)
    if (doRoundTrip) verifyEq(html, renderer.render(parser.parse(mark)))
    // always reset after a render
    doRoundTrip = true
    return html
  }
  private Bool doRoundTrip := true

}

@Js internal class TablesTestAttrProvider : AttrProvider
{
  override Void setAttrs(Node node, Str tagName, [Str:Str?] attrs)
  {
    switch (node.typeof)
    {
      case Table#:     attrs["test"] = "block"
      case TableHead#: attrs["test"] = "head"
      case TableBody#: attrs["test"] = "body"
      case TableRow#:  attrs["test"] = "row"
      case TableCell#:
        attrs["test"] = "cell"
        if ("th" == tagName) attrs["width"] = "${((TableCell)node).width}em"
    }
  }
}