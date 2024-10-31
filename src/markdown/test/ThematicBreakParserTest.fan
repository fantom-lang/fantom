//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Oct 2024  Matthew Giannini  Creation
//

@Js
class ThematicBreakParserTest : Test
{
  Parser? parser

  override Void setup() { this.parser = Parser() }

  Void testLiteral()
  {
    verifyLiteral("***", "***")
    verifyLiteral("-- -", "-- -")
    verifyLiteral("  __  __  __  ", "  __  __  __  ")
    verifyLiteral("***", "> ***")
  }

  private Void verifyLiteral(Str expected, Str input)
  {
    tb := Node.find(parser.parse(input), ThematicBreak#) as ThematicBreak
    verifyNotNull(tb)
    verifyEq(expected, tb.literal)
  }
}