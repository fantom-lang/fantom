//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Apr 2025  Matthew Giannini  Creation
//

class TableTextTest : Test
{
  private static const MarkdownExt[] exts := [TablesExt()]
  private static const Parser parser := Parser.builder.extensions(exts).build
  private static TextRenderer compactRenderer()
  {
    TextRenderer.builder.extensions(exts).build
  }
  private static TextRenderer separateRenderer()
  {
    TextRenderer.builder
      .withLineBreakRendering(LineBreakRendering.separate_blocks)
      .extensions(exts)
      .build
  }

  private static TextRenderer strippedRenderer()
  {
    TextRenderer.builder
      .withLineBreakRendering(LineBreakRendering.strip)
      .extensions(exts)
      .build
  }

  Void testOneHeadNoBody()
  {
    verifyCompact("Abc|Def\n---|---", "Abc| Def")
  }

  Void testOneColumnOneHeadNoBody()
  {
    expected := "Abc"
    verifyCompact("|Abc\n|---\n", expected)
    verifyCompact("|Abc|\n|---|\n", expected)
    verifyCompact("Abc|\n---|\n", expected)

    // pipe required on separator
    verifyCompact("|Abc\n---\n", "|Abc")
    // pipe required on head
    verifyCompact("Abc\n|---\n", "Abc\n|---")
  }

  Void testOneColumnOneHeadOneBody()
  {
    expected := "Abc\n1"
    verifyCompact("|Abc\n|---\n|1", expected)
    verifyCompact("|Abc|\n|---|\n|1", expected)
    verifyCompact("Abc|\n---|\n|1", expected)

    // pipe required on separator
    verifyCompact("Abc\n---\n|1", "Abc\n|1")
  }

  Void testOneHeadOneBody()
  {
    verifyCompact("Abc|Def\n---|---\n1|2", "Abc| Def\n1| 2")
  }

  Void testSeparatorMustNotHaveLessPartsThanHead()
  {
    verifyCompact("Abc|Def|Ghi\n---|---\n1|2|3", "Abc|Def|Ghi\n---|---\n1|2|3")
  }

  Void testPadding()
  {
    verifyCompact(" Abc  | Def \n --- | --- \n 1 | 2 ", "Abc| Def\n1| 2")
  }

  Void testPaddingWithCodeBlockIndentation()
  {
    verifyCompact("Abc|Def\n---|---\n    1|2", "Abc| Def\n1| 2");
  }

  Void testPipesOnOutside()
  {
    verifyCompact("|Abc|Def|\n|---|---|\n|1|2|", "Abc| Def\n1| 2");
  }

  Void testInlineElements()
  {
    verifyCompact("*Abc*|Def\n---|---\n1|2", "Abc| Def\n1| 2");
  }

  Void testEscapedPipe()
  {
    verifyCompact("Abc|Def\n---|---\n1\\|2|20", "Abc| Def\n1|2| 20");
  }

  Void testAlignLeft()
  {
    verifyCompact("Abc|Def\n:---|---\n1|2", "Abc| Def\n1| 2");
  }

  Void testAlignRight()
  {
    verifyCompact("Abc|Def\n:---|---\n1|2", "Abc| Def\n1| 2");
  }

  Void testAlignCenter()
  {
    verifyCompact("Abc|Def\n:---:|---\n1|2", "Abc| Def\n1| 2");
  }

  Void testAlignCenterSecond()
  {
    verifyCompact("Abc|Def\n---|:---:\n1|2", "Abc| Def\n1| 2");
  }

  Void testAlignLeftWithSpaces()
  {
    verifyCompact("Abc|Def\n :--- |---\n1|2", "Abc| Def\n1| 2");
  }

  Void testAlignmentMarkerMustBeNextToDashes()
  {
    verifyCompact("Abc|Def\n: ---|---", "Abc|Def\n: ---|---");
    verifyCompact("Abc|Def\n--- :|---", "Abc|Def\n--- :|---");
    verifyCompact("Abc|Def\n---|: ---", "Abc|Def\n---|: ---");
    verifyCompact("Abc|Def\n---|--- :", "Abc|Def\n---|--- :");
  }

  Void testBodyCanNotHaveMoreColumnsThanHead()
  {
    verifyCompact("Abc|Def\n---|---\n1|2|3", "Abc| Def\n1| 2");
  }

  Void testInsideBlockQuote()
  {
    verifyCompact("> Abc|Def\n> ---|---\n> 1|2", "«Abc| Def\n1| 2»");
  }

  Void testTableWithLazyContinuationLine()
  {
    verifyCompact("Abc|Def\n---|---\n1|2\nlazy", "Abc| Def\n1| 2\nlazy| ");
  }

  Void testTableBetweenOtherBlocks()
  {
    s := "Foo\n\nAbc|Def\n---|---\n1|2\n\nBar"
    verifyCompact(s, "Foo\nAbc| Def\n1| 2\nBar")
    verifySeparate(s, "Foo\n\nAbc| Def\n1| 2\n\nBar")
    verifyStripped(s, "Foo Abc| Def 1| 2 Bar")
  }

  private Void verifyCompact(Str source, Str expected)
  {
    doc := parser.parse(source)
    actual := compactRenderer.render(doc)
    verifyEq(expected, actual)
  }

  private Void verifySeparate(Str source, Str expected)
  {
    doc := parser.parse(source)
    actual := separateRenderer.render(doc)
    verifyEq(expected, actual)
  }

  private Void verifyStripped(Str source, Str expected)
  {
    doc := parser.parse(source)
    actual := strippedRenderer.render(doc)
    verifyEq(expected, actual)
  }
}
