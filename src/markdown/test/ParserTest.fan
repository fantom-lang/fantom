//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Oct 2024  Matthew Giannini  Creation
//

@Js
class ParserTest : Test
{
  Void testEnabledBlockTypes()
  {
    given := "# heading 1\n\nnot a heading"

    parser := Parser()
    doc := parser.parse(given)
    verifyType(doc.firstChild, Heading#)

    // only enable heading blocks
    parser = Parser.builder.withEnabledBlockTypes([Heading#]).build
    doc = parser.parse(given)
    verifyType(doc.firstChild, Heading#)

    // no core types
    parser = Parser.builder.withEnabledBlockTypes([,]).build
    doc = parser.parse(given)
    verify(doc.firstChild isnot Heading)
  }

  Void testEnabledBlockTypesThrowsWhenGivenUnknownType()
  {
    // BulletList can't be enabled separately at the moment, only all ListBlock types
    verifyErr(ArgErr#) {
      Parser.builder.withEnabledBlockTypes([Heading#, BulletList#]).build
    }
  }

  Void testIndentation()
  {
    given := " - 1 space\n   - 3 spaces\n     - 5 spaces\n\t - tab + space";
    doc := Parser().parse(given)

    verifyType(doc.firstChild, BulletList#)

    // first level list
    list := doc.firstChild
    verifySame(list.firstChild, list.lastChild)
    verifyEq("1 space", firstText(list.firstChild))

    // second level list
    list = list.firstChild.lastChild
    verifySame(list.firstChild, list.lastChild)
    verifyEq("3 spaces", firstText(list.firstChild))

    // third level list
    list = list.firstChild.lastChild
    verifyEq("5 spaces", firstText(list.firstChild))
    verifyEq("tab + space", firstText(list.firstChild.next))
  }

  // TODO:test for inline parser factory if we ever enable that feature

  private Str firstText(Node n)
  {
    while (!(n is Text))
    {
      verifyNotNull(n)
      n = n.firstChild
    }
    return ((Text)n).literal
  }
}

