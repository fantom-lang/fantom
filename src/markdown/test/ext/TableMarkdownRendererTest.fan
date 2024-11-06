//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   06 Nov 2024  Matthew Giannini  Creation
//

@Js
class TableMarkdownRendererTest : Test
{
  private static const MarkdownExt[] exts := [TablesExt()]
  private static const Parser parser := Parser.builder.extensions(exts).build
  private static const MarkdownRenderer renderer := MarkdownRenderer.builder.extensions(exts).build

  Void testHeadNoBody()
  {
    verifyRoundTrip("|Abc|\n|---|\n")
    verifyRoundTrip("|Abc|Def|\n|---|---|\n|1|2|\n")
  }

  Void testBodyHasFewerColumns()
  {
    // could try not to write empty trailing cells, but this is fine too
    verifyRoundTrip("|Abc|Def|\n|---|---|\n|1||\n")
  }

  Void testAlignment()
  {
    verifyRoundTrip("|Abc|Def|\n|:---|---|\n|1|2|\n")
    verifyRoundTrip("|Abc|Def|\n|---|---:|\n|1|2|\n")
    verifyRoundTrip("|Abc|Def|\n|:---:|:---:|\n|1|2|\n")
  }

  Void testInsideBlockQuote()
  {
    verifyRoundTrip("> |Abc|Def|\n> |---|---|\n> |1|2|\n")
  }

  Void testMultipleTables()
  {
    verifyRoundTrip("|Abc|Def|\n|---|---|\n\n|One|\n|---|\n|Only|\n")
  }

  Void testEscaping()
  {
    verifyRoundTrip("|Abc|Def|\n|---|---|\n|Pipe in|text \\||\n")
    verifyRoundTrip("|Abc|Def|\n|---|---|\n|Pipe in|code `\\|`|\n")
    verifyRoundTrip("|Abc|Def|\n|---|---|\n|Inline HTML|<span>Foo\\|bar</span>|\n")
  }

  Void testEscaped()
  {
    // '|' in text nodes needs to be escaped, otherwise the generated markdown does not
    // get parsed back as a table
    verifyRoundTrip("\\|Abc\\|\n\\|---\\|\n")
  }

  protected Str render(Str source) { renderer.render(parser.parse(source)) }

  private Void verifyRoundTrip(Str input)
  {
    rendered := render(input)
    verifyEq(input, rendered)
  }
}