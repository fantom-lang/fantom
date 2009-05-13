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

    verifyXIncompleteErr("<?")
    verifyXIncompleteErr("<?xml")
    verifyXIncompleteErr("<?xml ?")

    verifyXIncompleteErr("<!DOCTYPE")
    verifyXIncompleteErr("<!DOCTYPE foo")

    verifyXIncompleteErr("<x")
    verifyXIncompleteErr("<x/")
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

    verifyXIncompleteErr("<root><a")
    verifyXIncompleteErr("<root><a/")
    verifyXIncompleteErr("<root><a/><")
    verifyXIncompleteErr("<root><a/></")
    verifyXIncompleteErr("<root><a/></root")
    verifyXIncompleteErr("<root><root/>")
    verifyXIncompleteErr("<root>text...")
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

    verifyXIncompleteErr("<x a='")
    verifyXIncompleteErr("<x a=\"")
    verifyXIncompleteErr("<x a='xx")
    verifyXIncompleteErr("<x a=\"xx")
  }

//////////////////////////////////////////////////////////////////////////
// Namespace
//////////////////////////////////////////////////////////////////////////

  Void testNs()
  {
    // bad uri
    verifyXErr("\n<x xmlns=' '/>", 2, 4)

    // bad prefix
    verifyXErr("<p:root/>", 1, 2)
    verifyXErr("<p:root xmlns='foo'/>", 1, 2)
    verifyXErr("\n\n <p:root xmlns:P='foo'/>", 3, 3)
    verifyXErr("<r><p:x xmlns:p='foo'/><p:y/></r>", 1, 25)

    // bad end tag
    verifyXErr("<r><p:x xmlns:p='foo'></x></r>", 1, 25)
    verifyXErr("<r><p:x xmlns:p='foo'></p></r>", 1, 25)
    verifyXErr("<r><p:x xmlns:p='foo'></P:x></r>", 1, 25)

    // bad attr
    verifyXErr("<r attr:x='bad'>", 1, 2)
    verifyXErr("<r><x xmlns:p='foo'/><y p:a='v'/></r>", 1, 23)
  }

//////////////////////////////////////////////////////////////////////////
// Verifies
//////////////////////////////////////////////////////////////////////////

  Void verifyXErr(Str xml, Int line, Int col)
  {
    try
    {
      XParser(xml.in).parseDoc
      fail
    }
    catch (XErr e)
    {
      // echo("$e  $e.line,$e.col")
      verifyEq(e.line, line)
      verifyEq(e.col, col)
    }
  }

  Void verifyXIncompleteErr(Str xml)
  {
    try
    {
      XParser(xml.in).parseDoc
      fail
    }
    catch (XIncompleteErr e)
    {
      // echo("$e  $e.line,$e.col")
      lines := xml.splitLines
      verifyEq(e.line, lines.size)
      verify(e.col >= lines.last.size-1)
    }
  }


}