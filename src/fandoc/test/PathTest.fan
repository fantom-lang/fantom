//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Jun 14  Matthew Giannini Creation
//

**
** PathTest
**
@Js
class PathTest : Test
{
  Void testPara()
  {
    verifyPath("", [,], [,])
    verifyPath("a", [0], [DocNodeId.para])
    verifyPath("a b c\nd e f", [0], [DocNodeId.para])
    verifyPath("a\n\nb",[1], [DocNodeId.para])
    verifyPath("NOTE: that's right", [0], [DocNodeId.para])
  }

  Void testHeading()
  {
    verifyPath("H1\n####", [0], [DocNodeId.heading])
    verifyPath("H2\n****", [0], [DocNodeId.heading])
    verifyPath("H3\n====", [0], [DocNodeId.heading])
    verifyPath("H4\n----", [0], [DocNodeId.heading])
    verifyPath("para text\n\nH4\n----", [1], [DocNodeId.heading])
  }

  Void testCode()
  {
    verifyPath("para text\n\nThis is a 'code' example.", [1,1], [DocNodeId.para, DocNodeId.code])
  }

  Void testLinks()
  {
    verifyPath("`link`", [0,0], [DocNodeId.para, DocNodeId.link])
    verifyPath("text [fantom]`http://fantom.org` text", [0,1], [DocNodeId.para, DocNodeId.link])
  }

  Void testImages()
  {
    verifyPath("![cool image]`cool.png`", [0,0], [DocNodeId.para, DocNodeId.image])
    verifyPath("An image: ![cool image]`cool.png`. Neat.", [0,1], [DocNodeId.para, DocNodeId.image])
  }

  Void testEmphasis()
  {
    verifyPath("*x*", [0,0], [DocNodeId.para, DocNodeId.emphasis])
    verifyPath("foo *emph* bar", [0,1], [DocNodeId.para, DocNodeId.emphasis])

    verifyPath("**strong**", [0,0], [DocNodeId.para, DocNodeId.strong])
    verifyPath("foo **strong** bar", [0,1], [DocNodeId.para, DocNodeId.strong])

    verifyPath("a *emp\n**emp-strong**\nemp*!", [0,1], [DocNodeId.para, DocNodeId.emphasis])
    verifyPath("a *emp\n**emp-strong**\nemp*!", [0,1,1], [DocNodeId.para, DocNodeId.emphasis, DocNodeId.strong])

    verifyPath("**`link`**", [0,0,0], [DocNodeId.para, DocNodeId.strong, DocNodeId.link])
  }

  Void testPre()
  {
    verifyPath("  a+b", [0], [DocNodeId.pre])
    verifyPath("Code:\n\n  a+b", [1], [DocNodeId.pre])
    verifyPath(
      "  class A
         {
           Int x() { return 3 }
         }

         class B : A { }
       ", [0], [DocNodeId.pre])

    verifyPath(
      "pre>
        - a
        - b
       <pre
       ", [0], [DocNodeId.pre])
  }

  Void testBlockQuotes()
  {
    verifyPath("> a", [0,0], [DocNodeId.blockQuote, DocNodeId.para])
    verifyPath("> a\n> b c\n> d", [0,0], [DocNodeId.blockQuote, DocNodeId.para])
    // NOTE: consecutive block quotes get merged
    verifyPath("> b1\n> b1\n\n> b2\n> b2", [0,1], [DocNodeId.blockQuote, DocNodeId.para])
    verifyPath("> b1\n> b1\n\nPara\n\n> b2\n> b2", [2,0], [DocNodeId.blockQuote, DocNodeId.para])
  }

  Doc verifyPath(Str str, Int[] childIndices, DocNodeId[] expected)
  {
    doc := parse(str)

    // NOTE: as a convenience we don't require DocNodeId.doc as first element expected list
    expected = [DocNodeId.doc].addAll(expected)
    DocElem target := doc
    childIndices.each |idx, i| {
      target = (DocElem)target.children[idx]
      verifyEq(target.path.map |n->DocNodeId| { n.id }, expected[0..i+1])
    }
    return doc
  }

  Void testPositions()
  {
    doc := parse("foo")

    // root position
    verifyNull(doc.pos)
    verifyFalse(doc.isFirst)
    verifyFalse(doc.isLast)

    // only child
    para := (DocElem)doc.children[0]
    verifySame(para.id, DocNodeId.para)
    verifyEq(0, para.pos)
    verify(para.isFirst)
    verify(para.isLast)

    // middle child
    doc = parse("foo\n\nbar\n\nbaz")
    para = doc.children[1]
    verifySame(para.id, DocNodeId.para)
    verifyEq(1, para.pos)
    verifyFalse(para.isFirst)
    verifyFalse(para.isLast)
  }

  Void testInsert()
  {
    // insert with text merge
    doc := parse("foo\n\nbar\n\nbaz")
    DocElem para := doc.children[1]
    verifyEq("bar", para.children.first->str)
    para.insert(0, DocText("foo"))
    verifyEq("foobar", para.children.first->str)
    para.insert(para.children.size, DocText("baz"))
    verifyEq("foobarbaz", para.children.first->str)

    // insert with blockquote merge
    doc = parse("> a")
    verifyEq(1, doc.children.size)
    bq := doc.children.first as BlockQuote
    verifyEq(1, bq.children.size)
    para = bq.children.first
    verify(para is Para)

    p1 := Para().add(DocText("foo"))
    bq = BlockQuote().add(p1)
    doc.insert(0, bq)
    verifyEq(1, doc.children.size)
    verifyEq(2, bq.children.size)
    verifySame(p1, bq.children.first)
    verifySame(para, bq.children.last)

    p2 := Para().add(DocText("baz"))
    bq2 := BlockQuote().add(p2)
    doc.insert(doc.children.size, bq2)
    verifyEq(1, doc.children.size)
    verifyEq(3, bq.children.size)
    verifySame(p1, bq.children.first)
    verifySame(para, bq.children[1])
    verifySame(p2, bq.children.last)

    p3 := Para().add(DocText("INNER"))
    bq.insert(1, p3)
    verifyEq(4, bq.children.size)
    verifySame(p1, bq.children.first)
    verifySame(p3, bq.children[1])
    verifySame(para, bq.children[2])
    verifySame(p2, bq.children.last)


  }

  Doc parse(Str str)
  {
    return FandocParser { silent = true }.parse("Test", str.in)
  }

}
