//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    7 Nov 08  Brian Frank  Creation
//

**
** WriteTest
**
class WriteTest : XmlTest
{

  Void testWrites()
  {
    x := XElem("x")
    verifyWrite(x, "<x/>")

    x.addAttr("a", "aval")
    verifyWrite(x, "<x a='aval'/>")

    x.addAttr("b", "bval")
    verifyWrite(x, "<x a='aval' b='bval'/>")

    withText := XElem("withText").add(XText("some text"))
    verifyWrite(withText, "<withText>some text</withText>")

    x.add(withText)
    verifyWrite(x,
      "<x a='aval' b='bval'>
        <withText>some text</withText>
       </x>")

    a := XElem("a").add(XPi("pi", "name='val'"))
    b := XElem("b").addAttr("foo", "bar")
    x.add(a).add(b)
    verifyWrite(x,
      "<x a='aval' b='bval'>
        <withText>some text</withText>
        <a>
         <?pi name='val'?>
        </a>
        <b foo='bar'/>
       </x>")

    c := XElem("c").add(XText("text of c!"))
    x.add(c)
    verifyWrite(x,
      "<x a='aval' b='bval'>
        <withText>some text</withText>
        <a>
         <?pi name='val'?>
        </a>
        <b foo='bar'/>
        <c>text of c!</c>
       </x>")

    mixed := XElem("mixed")
    {
      XText("the "),
      XElem("b") { XText("real"), },
      XText(" deal"),
    }
    verifyWrite(mixed, "<mixed>the <b>real</b> deal</mixed>")

    x.add(mixed)
    verifyWrite(x,
      "<x a='aval' b='bval'>
        <withText>some text</withText>
        <a>
         <?pi name='val'?>
        </a>
        <b foo='bar'/>
        <c>text of c!</c>
        <mixed>the <b>real</b> deal</mixed>
       </x>")

    seq := XElem("seq").add(XText("a")).add(XText("b")).add(XText("c"))
    verifyWrite(seq, "<seq>abc</seq>", false)

    multi := XElem("multi").add(XText("line1\nline2"))
    verifyWrite(multi, "<multi>line1\nline2</multi>")
  }

  Void testDoc()
  {
    doc := XDoc()
    verifyWrite(doc,
      "<?xml version='1.0' encoding='UTF-8'?>
       <undefined/>\n")

    doc.root = XElem("root").addAttr("foo", "bar").add(XText("how, how"))
    verifyWrite(doc,
      "<?xml version='1.0' encoding='UTF-8'?>
       <root foo='bar'>how, how</root>\n")

    doc.docType = XDocType { rootElem="root"; systemId=`root.dtd` }
    verifyWrite(doc,
      "<?xml version='1.0' encoding='UTF-8'?>
       <!DOCTYPE root SYSTEM 'root.dtd'>
       <root foo='bar'>how, how</root>\n")

    // publicId without systemId isn't technically correct
    doc.docType = XDocType { rootElem="root"; publicId="foo" }
    verifyWrite(doc,
      "<?xml version='1.0' encoding='UTF-8'?>
       <!DOCTYPE root PUBLIC 'foo'>
       <root foo='bar'>how, how</root>\n")

    doc.docType = XDocType { rootElem="root";
      publicId = "-//W3C//DTD XHTML 1.0 Transitional//EN"
      systemId=`http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd` }
    verifyWrite(doc,
      "<?xml version='1.0' encoding='UTF-8'?>
       <!DOCTYPE root PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'>
       <root foo='bar'>how, how</root>\n")

    doc = XDoc
    {
      XPi("xml-stylesheet", "type='text/xsl' href='simple.xsl'"),
      XElem("foo"),
    }
    verifyWrite(doc,
      "<?xml version='1.0' encoding='UTF-8'?>
       <?xml-stylesheet type='text/xsl' href='simple.xsl'?>
       <foo/>\n")

    doc = XDoc
    {
      docType = XDocType { rootElem="foo"; systemId=`foo.dtd` }
      XPi("alpha", "foo bar"),
      XPi("beta",  "foo=bar"),
      XElem("foo"),
    }
    verifyWrite(doc,
      "<?xml version='1.0' encoding='UTF-8'?>
       <!DOCTYPE foo SYSTEM 'foo.dtd'>
       <?alpha foo bar?>
       <?beta foo=bar?>
       <foo/>\n")
  }

  Void testEsc()
  {
    x := XElem("x").addAttr("foo", "<AT&T>")
    verifyWrite(x, "<x foo='&lt;AT&amp;T>'/>")

    x = XElem("x").addAttr("foo", "quot=\" \n apos='")
    verifyWrite(x, "<x foo='quot=&quot; &#x0a; apos=&apos;'/>")

    x = XElem("x").add(XText("'hi' & <there>\n \"line2\""))
    verifyWrite(x, "<x>'hi' &amp; &lt;there>\n \"line2\"</x>")
  }

  Void testCdata()
  {
    x := XElem("x").add(XText("'hi' & <there>\n \"line2\"") { cdata=true })
    verifyWrite(x, "<x><![CDATA['hi' & <there>\n \"line2\"]]></x>")

    x = XElem("x").add(XText("]]>") { cdata=true })
    verifyErr(IOErr#) { verifyWrite(x, "?") }
  }

  Void testNs()
  {
    nsdef := XNs("", `http://foo/def`)
    nsq   := XNs("q", `http://foo/q`)
    x := XElem("root", nsdef)
    {
      XAttr.makeNs(nsdef),
      XAttr.makeNs(nsq),
      XElem("a", nsdef),
      XElem("b", nsq)
      {
        XAttr("x", "xv"),
        XAttr("y", "yv", nsq),
      }
    }
    verifyWrite(x,
      "<root xmlns='http://foo/def' xmlns:q='http://foo/q'>
        <a/>
        <q:b x='xv' q:y='yv'/>
       </root>")
  }

  Void verifyWrite(XNode xml, Str expected, Bool testRoundtrip := true)
  {
    // write to string
    buf := Buf()
    xml.write(buf.out)
    actual := buf.flip.readAllStr
    verifyEq(actual, expected)

    // write using string buffer
    strBuf := StrBuf()
    xml.write(strBuf.out)
    actual = strBuf.toStr
    verifyEq(actual, expected)

    // writeToStr convenience
    verifyEq(xml.writeToStr, expected)

    // verify roundtrip using parser if doc or elem
    if (!testRoundtrip) return
    if (xml is XDoc)
      verifyDoc(XParser(expected.in).parseDoc, xml)
    else if (xml is XElem)
      verifyElem(XParser(expected.in).parseDoc.root, xml)
  }
}