//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Dec 2025  Matthew Giannini  Creation
//

// TODO: add these tests
@Js
class BlockParserFactoryTest : Test
{
  Void testCustomBlockParserFactory()
  {
    parser := Parser.builder.customBlockParserFactory(TestDashBlockParserFactory()).build

    // the dashes would normally be a ThematicBreak
    doc := parser.parse("hey\n\n---\n")

    verifyType(doc.firstChild, Paragraph#)
    verifyEq("hey", ((Text)doc.firstChild.firstChild).literal)
    verifyType(doc.lastChild, TestDashBlock#)
  }

  Void testReplaceActiveBlockParser()
  {
    // TODO:Add this test
  }
}

@Js internal class TestDashBlock : CustomBlock { }

@Js internal class TestDashBlockParser : BlockParser
{
  override TestDashBlock block := TestDashBlock() { private set }
  override BlockContinue? tryContinue(ParserState state) { BlockContinue.none }
}

@Js internal const class TestDashBlockParserFactory : BlockParserFactory
{
  override BlockStart? tryStart(ParserState state, MatchedBlockParser parser)
  {
    if (state.line.content == "---") return BlockStart.of([TestDashBlockParser()])
    return BlockStart.none
  }

}

