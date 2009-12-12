//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    13 Nov 08  Brian Frank  Creation
//

**
** Pull parsing testing
**
class PullTest : XmlTest
{

//////////////////////////////////////////////////////////////////////////
// Elem Tree
//////////////////////////////////////////////////////////////////////////

  Void testElems()
  {
    init(
      "<root>
         <a>
           <b></b>
           <c/>
         </a>
         <d/>
       </root>")

    root := XElem("root")
    a    := XElem("a")
    b    := XElem("b")
    c    := XElem("c")
    d    := XElem("d")

    verifyEq(parser.elem, null)
    verifyEq(parser.depth, -1)
    verifyNext(start, 0, [root])
    verifyNext(start, 1, [root, a])
    verifyNext(start, 2, [root, a, b])
    verifyNext(end,   2, [root, a, b])
    verifyNext(start, 2, [root, a, c])
    verifyNext(end,   2, [root, a, c])
    verifyNext(end,   1, [root, a])
    verifyNext(start, 1, [root, d])
    verifyNext(end,   1, [root, d])
    verifyNext(end,   0, [root])
    verifyNext(null, -1, empty)
  }

//////////////////////////////////////////////////////////////////////////
// Attributes
//////////////////////////////////////////////////////////////////////////

  Void testAttrs()
  {
    init(
      "<root a='foo'>
         <a b='bad!' c='good!'>
           <b xyz='4 &lt; 5'/>
           <c/>
         </a>
         <d>
           <e/>
           <f x='X'  y='Y'
              z='Z'/>
           <g/>
         </d>
       </root>")

    root := XElem("root") { addAttr("a", "foo") }
    a    := XElem("a") { addAttr("b", "bad!"); addAttr("c", "good!") }
    b    := XElem("b") { addAttr("xyz", "4 < 5") }
    c    := XElem("c")
    d    := XElem("d")
    e    := XElem("e")
    f    := XElem("f") { addAttr("x", "X"); addAttr("y", "Y"); addAttr("z", "Z") }
    g    := XElem("g")

    verifyNext(start, 0, [root])
    verifyNext(start, 1, [root, a])
    verifyNext(start, 2, [root, a, b])
    verifyNext(end,   2, [root, a, b])
    verifyNext(start, 2, [root, a, c])
    verifyNext(end,   2, [root, a, c])
    verifyNext(end,   1, [root, a])
    verifyNext(start, 1, [root, d])
    verifyNext(start, 2, [root, d, e])
    verifyNext(end,   2, [root, d, e])
    verifyNext(start, 2, [root, d, f])
    verifyNext(end,   2, [root, d, f])
    verifyNext(start, 2, [root, d, g])
    verifyNext(end,   2, [root, d, g])
    verifyNext(end,   1, [root, d])
    verifyNext(end,   0, [root])
    verifyNext(null, -1, empty)
  }

//////////////////////////////////////////////////////////////////////////
// Mixed
//////////////////////////////////////////////////////////////////////////

  Void testMixed()
  {
    init(
      "<?xml version='1.0'?>
       <root>
         <a>foo bar</a>
         <!-- comment -->
         <b>this <i>really</i> is cool</b>
         <![CDATA[anything &amp; goes]]>
       </root>")

    root := XElem("root")
    a    := XElem("a")
    b    := XElem("b")
    i    := XElem("i")

    verifyNext(start, 0, [root])
    verifyNext(start, 1, [root, a])
    verifyNext(text,  1, [root, a], XText("foo bar"))
    verifyNext(end,   1, [root, a])
    verifyNext(start, 1, [root, b])
    verifyNext(text,  1, [root, b], XText("this "))
    verifyNext(start, 2, [root, b, i])
    verifyNext(text,  2, [root, b, i], XText("really"))
    verifyNext(end,   2, [root, b, i])
    verifyNext(text,  1, [root, b], XText(" is cool"))
    verifyNext(end,   1, [root, b])
    verifyNext(text,  0, [root], XText("anything &amp; goes") {cdata=true})
    verifyNext(end,   0, [root])
    verifyNext(null, -1, empty)
  }

//////////////////////////////////////////////////////////////////////////
// Pi
//////////////////////////////////////////////////////////////////////////

  Void testPi()
  {
    init(
      "<?xml version='1.0'?>
       <?targetA?>
       <?targetB with some value?>
       <root>
         <?targetB
           with some value?>
       </root>")

    root := XElem("root")
    piA  := XPi("targetA", "")
    piB  := XPi("targetB", "with some value")

    verifyPis(parser.doc.pis, XPi[,])
    verifyNext(pi,   -1, empty, piA);  verifyPis(parser.doc.pis, [piA])
    verifyNext(pi,   -1, empty, piB);  verifyPis(parser.doc.pis, [piA, piB])
    verifyNext(start, 0, [root])
    verifyNext(pi,    0, [root], piB)
    verifyNext(end,   0, [root])
    verifyNext(null, -1, empty)
  }

//////////////////////////////////////////////////////////////////////////
// DocType
//////////////////////////////////////////////////////////////////////////

  Void testDoc()
  {
    init(
      "<?xml version='1.0'?>
       <!DOCTYPE foo\tPUBLIC\t'foo' 'urn:foo'>
       <root/>")

    root := XElem("root")

    verifyEq(parser.elem, null)
    verifyEq(parser.depth, -1)
    verifyEq(parser.doc.docType, null)
    verifyNext(start, 0, [root])
    verifyEq(parser.doc.docType.toStr, "<!DOCTYPE foo PUBLIC 'foo' 'urn:foo'>")
  }

//////////////////////////////////////////////////////////////////////////
// Namespaces
//////////////////////////////////////////////////////////////////////////

  Void testNs()
  {
    init(
      "<root xmlns='fan:def' xmlns:q='fan:q'>
         <a attr='val' q:attr='val'/>
         <q:b/>
       </root>")

    def := XNs("", `fan:def`)
    q   := XNs("q", `fan:q`)

    root := XElem("root", def) { XAttr.makeNs(def), XAttr.makeNs(q), }
    a    := XElem("a", def) { addAttr("attr", "val"); addAttr("attr", "val", q) }
    b    := XElem("b", q)

    verifyEq(parser.elem, null)
    verifyEq(parser.depth, -1)
    verifyNext(start, 0, [root])
    verifyNext(start, 1, [root, a])
    verifyNext(end,   1, [root, a])
    verifyNext(start, 1, [root, b])
    verifyNext(end,   1, [root, b])
    verifyNext(end,   0, [root])
    verifyNext(null, -1, empty)
  }

//////////////////////////////////////////////////////////////////////////
// Skip and Memory
//////////////////////////////////////////////////////////////////////////

  Void testSkipAndMem()
  {
    init(
      "<root>
         <!-- skip nodes -->
         <skip/>
         <skip><bar/></skip>
         <skip>
           <foo><bar/></foo>
           <foo/>
           <foo><bar/></foo>
         </skip>
         <!-- mem nodes -->
         <a/>
         <mem1 a='b'/>
         <a/>
         <mem2><kid><grandkid/></kid></mem2>
         <a/>
       </root>")

    root := XElem("root")
    skip := XElem("skip")
    foo  := XElem("foo")
    a    := XElem("a")
    mem1 := XElem("mem1") { addAttr("a", "b") }
    mem2 := XElem("mem2")

    verifyNext(start, 0, [root])
    verifyNext(start, 1, [root, skip]); verifyEq(parser.line, 3)

    // skip <skip/>
    parser.skip
    verifyNext(start, 1, [root, skip]); verifyEq(parser.line, 4)

    // skip <skip><bar/></skip>
    parser.skip
    verifyNext(start, 1, [root, skip]); verifyEq(parser.line, 5)
    verifyNext(start, 2, [root, skip, foo]); verifyEq(parser.line, 6)

    // we're on foo, skip all the way back up to </skip>
    parser.skip(1)
    verifyNext(start, 1, [root, a]); verifyEq(parser.line, 11)
    verifyNext(end,   1, [root, a])

    // read mem1 into memory
    verifyNext(start, 1, [root, mem1])
    xmem1 := parser.parseElem
    verifyNext(start, 1, [root, a]); verifyEq(parser.line, 13)
    verifyNext(end,   1, [root, a])
    verifyElem(xmem1, mem1)

    // read mem2 into memory
    verifyNext(start, 1, [root, mem2])
    xmem2 := parser.parseElem
    verifyNext(start, 1, [root, a]); verifyEq(parser.line, 15)
    verifyNext(end,   1, [root, a])
    verifyElem(xmem2, XElem("mem2") { XElem("kid") { XElem("grandkid"), }, })

    verifyNext(end,   0, [root])
    verifyNext(null, -1, empty)

    verifyElem(xmem1, mem1)
    verifyElem(xmem2, XElem("mem2") { XElem("kid") { XElem("grandkid"), }, })
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  Void verifyNext(XNodeType? t, Int depth, XElem[] stack, XNode? cur := null)
  {
    verifyEq(parser.next, t)
    verifyEq(parser.nodeType, t)
    verifyEq(parser.depth, depth)
    verifyElem(parser.elem, stack.last)
    stack.each |XElem e, Int i| { verifyElem(parser.elemAt(i), e) }
    verifyErr(IndexErr#) { parser.elemAt(-1) }
    verifyErr(IndexErr#) { parser.elemAt(stack.size) }
    switch (t)
    {
      case text: verifyText(parser.text, cur)
      case pi:   verifyPi(parser.pi, cur)
    }
  }

  Void dump()
  {
    echo(":::: $parser.nodeType $parser.depth")
    echo("     elem: $parser.elem")
    (parser.depth+1).times |Int i| { echo("     elemAt($i): ${parser.elemAt(i)}") }
  }

  Void init(Str src)
  {
    parser = XParser(src.in)
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static const XNodeType start := XNodeType.elemStart
  static const XNodeType end   := XNodeType.elemEnd
  static const XNodeType text  := XNodeType.text
  static const XNodeType pi    := XNodeType.pi

  static const XElem[] empty := XElem[,]

  XParser? parser
}