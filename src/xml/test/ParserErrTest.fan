//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    11 Nov 08  Brian Frank  Creation
//

**
** ParserErrTest verifies docs not well formed
**
class ParserErrTest : XmlTest
{

//////////////////////////////////////////////////////////////////////////
// Bad Starts
//////////////////////////////////////////////////////////////////////////

  Void testBadStarts()
  {
    verifyXErr("", 1, 1)
    verifyXErr(" ", 1, 2)
    verifyXErr("x", 1, 1)
    verifyXErr("xyz <r/>", 1, 1)

    verifyIOErr("<?")
    verifyIOErr("<?xml")
    verifyIOErr("<?xml ?")

    verifyIOErr("<!DOCTYPE")
    verifyIOErr("<!DOCTYPE foo")

    verifyIOErr("<x")
    verifyIOErr("<x/")
  }

//////////////////////////////////////////////////////////////////////////
// Elements
//////////////////////////////////////////////////////////////////////////

  Void testElems()
  {
    verifyXErr("</x>", 1, 3)
    verifyXErr("<x</x>", 1, 3)
    verifyXErr("<  />", 1, 3)
    verifyXErr("< x />", 1, 3)

    verifyXErr("<root></rootx>", 1, 9)
    verifyXErr("<r><x></y></r>", 1, 9)
    verifyXErr("<r><x><y></x></y></r>", 1, 12)
    verifyXErr("<r><x><y/></x></y></r>", 1, 17)
    verifyXErr("<r>\n</x></r>", 2, 3)
    verifyXErr("<r>\n\n </>\n</r>", 3, 5)
    verifyXErr("<r>\n\n <  />\n</r>", 3, 4)

    verifyXErr("<r>foo</x>", 1, 9)

    verifyIOErr("<root><a")
    verifyIOErr("<root><a/")
    verifyIOErr("<root><a/><")
    verifyIOErr("<root><a/></")
    verifyIOErr("<root><a/></root")
    verifyIOErr("<root><root/>")
    verifyIOErr("<root>text...")
  }

//////////////////////////////////////////////////////////////////////////
// Attributes
//////////////////////////////////////////////////////////////////////////

  Void testAttrs()
  {
    verifyXErr("<x a=x/>", 1, 6)
    verifyXErr("<x a=/>", 1, 6)
    verifyXErr("<x a=>", 1, 6)
    verifyXErr("<x a=<", 1, 6)
    verifyXErr("<x\n a = x/>", 2, 6)
    verifyXErr("<x a''/>", 1, 5)
    verifyXErr("<x\na\n ''/>", 3, 2)

    verifyIOErr("<x a='")
    verifyIOErr("<x a=\"")
    verifyIOErr("<x a='xx")
    verifyIOErr("<x a=\"xx")
  }

//////////////////////////////////////////////////////////////////////////
// Verifies
//////////////////////////////////////////////////////////////////////////

  Void verifyXErr(Str xml, Int line, Int col)
  {
    try
    {
      XParser(InStream.makeForStr(xml)).parseDoc
      fail
    }
    catch (XErr e)
    {
      // echo("$e  $e.line,$e.col")
      verifyEq(e.line, line)
      verifyEq(e.col, col)
    }
  }

  Void verifyIOErr(Str xml)
  {
    try
    {
      XParser(InStream.makeForStr(xml)).parseDoc
      fail
    }
    catch (IOErr e)
    {
      verify(true)
    }
  }


}