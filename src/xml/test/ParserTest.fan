//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    11 Nov 08  Brian Frank  Creation
//

**
** ParserTest
**
class ParserTest : XmlTest
{

//////////////////////////////////////////////////////////////////////////
// DocType
//////////////////////////////////////////////////////////////////////////

  Void testDocType()
  {
    verifyParse(
      "<!DOCTYPE foo>
       <foo/>",
      XDoc
      {
        docType = XDocType { rootElem="foo"; publicId=null; systemId=null }
        root = XElem("foo")
      })

    verifyParse(
      "<!DOCTYPE  foo >
       <foo/>",
      XDoc
      {
        docType = XDocType { rootElem="foo"; publicId=null; systemId=null }
        root = XElem("foo")
      })

    verifyParse(
      "<!DOCTYPE foo SYSTEM 'foo.dtd'>
       <foo/>",
      XDoc
      {
        docType = XDocType { rootElem="foo"; publicId=null; systemId=`foo.dtd` }
        root = XElem("foo")
      })

    verifyParse(
      "<!DOCTYPE  HTML  PUBLIC  \"-//IETF//DTD HTML 3.0//EN\">
       <HTML/>",
      XDoc
      {
        docType = XDocType
        {
          rootElem="HTML"
          publicId="-//IETF//DTD HTML 3.0//EN"
          systemId=null
        }
        root = XElem("HTML")
      })

    verifyParse(
      "<!DOCTYPE html PUBLIC
        '-//W3C//DTD XHTML 1.0 Strict//EN'
        'http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd' >
       <HTML/>",
      XDoc
      {
        docType = XDocType
        {
         rootElem="html"
         publicId="-//W3C//DTD XHTML 1.0 Strict//EN"
         systemId=`http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd`
        }
        root = XElem("HTML")
      })

    verifyParse(
      "<!DOCTYPE TVSCHEDULE [
        <!ELEMENT TVSCHEDULE (CHANNEL+)>
        <!ELEMENT CHANNEL (BANNER,DAY+)>
        <!ELEMENT BANNER (#PCDATA)>
        <!ELEMENT DAY (#PCDATA)>
        <!ATTLIST CHANNEL CHAN CDATA #REQUIRED>
        <!ENTITY FOO \"BAR\">
       ]>
       <TVSCHEDULE/>",
      XDoc
      {
        docType = XDocType { rootElem="TVSCHEDULE"; publicId=null; systemId=null; }
        root = XElem("TVSCHEDULE")
      })
  }

//////////////////////////////////////////////////////////////////////////
// Elem
//////////////////////////////////////////////////////////////////////////

  Void testElem()
  {
    verifyParse(
      "<root/>",
      XDoc
      {
        root = XElem("root")
      })

    verifyParse(
      "<root>
        <alpha>
          <beta/>
        </alpha>
        <gamma></gamma>
       </root>",
      XDoc
      {
        root = XElem("root")
        {
          XElem("alpha") { XElem("beta") }
          XElem("gamma")
        }
      })
  }

//////////////////////////////////////////////////////////////////////////
// Attr
//////////////////////////////////////////////////////////////////////////

  Void testAttr()
  {
    verifyParse(
      "<root a='aval' b=\"bval\"/>",
      XDoc
      {
        root = XElem("root") { addAttr("a", "aval"); addAttr("b", "bval") }
      })

    verifyParse(
      "<root foo='&lt;&#x20;&gt;'/>",
      XDoc
      {
        root = XElem("root") { addAttr("foo", "< >") }
      })
  }

//////////////////////////////////////////////////////////////////////////
// Mixed
//////////////////////////////////////////////////////////////////////////

  Void testMixed()
  {
    verifyParse(
      "<r>hello</r>",
      XDoc
      {
        root = XElem("r") { XText("hello") }
      })

    verifyParse(
      " <r>&amp;\n&#x1234;</r> ",
      XDoc
      {
        root = XElem("r") { XText("&\n\u1234") }
      })

    verifyParse(
      "<r>this is <b>bold</b> for real!</r>",
      XDoc
      {
        root = XElem("r")
        {
          XText("this is ")
          XElem("b") { XText("bold") }
          XText(" for real!")
        }
      })
  }

//////////////////////////////////////////////////////////////////////////
// CDATA
//////////////////////////////////////////////////////////////////////////

  Void testCdata()
  {
    verifyParse(
      "<r><![CDATA[]]></r>\n",
      XDoc
      {
        root = XElem("r")
        {
          XText("") { cdata=true }
        }
      })

    verifyParse(
      "<r><![CDATA[x]]></r>",
      XDoc
      {
        root = XElem("r")
        {
          XText("x") { cdata=true }
        }
      })

    verifyParse(
      "<r><![CDATA[ <&]> ]]></r>",
      XDoc
      {
        root = XElem("r")
        {
          XText(" <&]> ") { cdata=true }
        }
      })
  }

//////////////////////////////////////////////////////////////////////////
// Namespaces
//////////////////////////////////////////////////////////////////////////

  Void testNs()
  {
    def  := XNs("", `urn:def`)
    q    := XNs("q", `urn:foo`)
    rx   := XNs("rx", `urn:bar`)

    // simple prefix
    verifyParse(
      "<q:foo xmlns:q='urn:foo'/>",
      XDoc
      {
        root = XElem("foo", q) { XAttr.makeNs(q) }
      })

    // simple default
    verifyParse(
      "<foo xmlns='urn:def'/>",
      XDoc
      {
        root = XElem("foo", def) { XAttr.makeNs(def) }
      })

    // prefix and default
    verifyParse(
      "<root xmlns='urn:def' xmlns:q='urn:foo'>
         <a><q:b/></a>
       </root>",
      XDoc
      {
        root = XElem("root", def)
        {
          XAttr.makeNs(def)
          XAttr.makeNs(q)
          XElem("a", def) { XElem("b", q) }
        }
      })

    // various nested combos
    verifyParse(
      "<root xmlns:q='urn:foo' xmlns:rx='urn:bar'>
         <a><inner/></a>
         <b xmlns='urn:def'><inner/></b>
         <q:c><inner/></q:c>
         <rx:d><inner/></rx:d>
       </root>",
      XDoc
      {
        root = XElem("root", null)
        {
          XAttr.makeNs(q)
          XAttr.makeNs(rx)
          XElem("a", null) { XElem("inner", null) }
          XElem("b", def)  { XAttr.makeNs(def); XElem("inner", def) }
          XElem("c", q)    { XElem("inner", null) }
          XElem("d", rx)   { XElem("inner", null) }
        }
      })
  }

  Void testNestedDefaultNs()
  {
    def1 := XNs("", `urn:def1`)
    def2 := XNs("", `urn:def2`)
    def3 := XNs("", `urn:def3`)
    xyz  := XNs("xyz", `urn:xyz`)

    verifyParse(
      "<root xmlns='urn:def1'>
         <a/>
         <b xmlns='urn:def2' xmlns:xyz='urn:xyz'>
           <none xmlns=''>
             <innerNone/>
             <def2 xmlns='urn:def2'><inner/></def2>
             <def3 xmlns='urn:def3'><xyz:inner/></def3>
           </none>
         </b>
         <c xmlns='urn:def3'><inner/></c>
         <d/>
       </root>",
      XDoc
      {
        root = XElem("root", def1)
        {
          XAttr.makeNs(def1)
          XElem("a", def1)
          XElem("b", def2)
          {
            XAttr.makeNs(def2)
            XAttr.makeNs(xyz)
            XElem("none", null)
            {
              addAttr("xmlns", "")
              XElem("innerNone", null)
              XElem("def2", def2) { XAttr.makeNs(def2); XElem("inner", def2) }
              XElem("def3", def3) { XAttr.makeNs(def3); XElem("inner", xyz) }
            }
          }
          XElem("c", def3)
          {
            XAttr.makeNs(def3)
            XElem("inner", def3)
          }
          XElem("d", def1)
        }
      })
  }

//////////////////////////////////////////////////////////////////////////
// Verifies
//////////////////////////////////////////////////////////////////////////

  Void verifyParse(Str xml, XDoc expected)
  {
    // parse
    actual := XParser(InStream.makeForStr(xml)).parseDoc

    // verify actual is expected
    verifyDoc(actual, expected)

    // verify round trip
    buf := Buf()
    actual.write(buf.out)
    roundtrip := XParser(InStream.makeForStr(buf.flip.readAllStr)).parseDoc
    verifyDoc(roundtrip, expected)
  }


}