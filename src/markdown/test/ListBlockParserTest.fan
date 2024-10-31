//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Oct 2024  Matthew Giannini  Creation
//

@Js
class ListBlockParserTest : Test
{
  Parser? parser

  override Void setup()
  {
    super.setup
    this.parser = Parser()
  }

  Void testBulletListIndents()
  {
    verifyListItemIndents("* foo", 0, 2)
    verifyListItemIndents(" * foo", 1, 3)
    verifyListItemIndents("  * foo", 2, 4)
    verifyListItemIndents("   * foo", 3, 5)

    verifyListItemIndents("*  foo", 0, 3)
    verifyListItemIndents("*   foo", 0, 4)
    verifyListItemIndents("*    foo", 0, 5)
    verifyListItemIndents(" *  foo", 1, 4)
    verifyListItemIndents("   *    foo", 3, 8)

    // tab counts as 3 spaces here (to the nex tabl stop column of 4) -> content indent is 1+3
    verifyListItemIndents("*\tfoo", 0, 4)

    // empty list, content indent is expected to be 2
    verifyListItemIndents("-\n", 0, 2)

    // the indent is realtive to any contain blocks
    verifyListItemIndents("> * foo", 0, 2)
    verifyListItemIndents(">  * foo", 1, 3)
    verifyListItemIndents(">  *  foo", 1, 4)
  }

  Void testOrderedListIndents()
  {
    verifyListItemIndents("1. foo", 0, 3)
    verifyListItemIndents(" 1. foo", 1, 4)
    verifyListItemIndents("  1. foo", 2, 5)
    verifyListItemIndents("   1. foo", 3, 6)

    verifyListItemIndents("1.  foo", 0, 4)
    verifyListItemIndents("1.   foo", 0, 5)
    verifyListItemIndents("1.    foo", 0, 6)
    verifyListItemIndents(" 1.  foo", 1, 5)
    verifyListItemIndents("  1.    foo", 2, 8)

    verifyListItemIndents("1.\tfoo", 0, 4)

    verifyListItemIndents("> 1. foo", 0, 3)
    verifyListItemIndents(">  1. foo", 1, 4)
    verifyListItemIndents(">  1.  foo", 1, 5)
  }

  private Void verifyListItemIndents(Str input, Int expectedMarkerIndent, Int expectedContentIndent)
  {
    doc := parser.parse(input)
    listItem := Node.find(doc, ListItem#) as ListItem
    verifyEq(expectedMarkerIndent, listItem.markerIndent)
    verifyEq(expectedContentIndent, listItem.contentIndent)
  }
}