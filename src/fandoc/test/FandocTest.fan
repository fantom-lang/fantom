//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Feb 07  Brian Frank  Creation
//

**
** FandocTest
**
@Js
class FandocTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Emphasis
//////////////////////////////////////////////////////////////////////////

  Void testEmphasis()
  {
    verifyDoc("*x*", ["<body>", ["<p>", ["<em>", "x"]]])
    verifyDoc("*foo*", ["<body>", ["<p>", ["<em>", "foo"]]])
    verifyDoc("\n*foo*", ["<body>", ["<p>", ["<em>", "foo"]]])
    verifyDoc("alpha *foo* beta", ["<body>", ["<p>", "alpha ", ["<em>", "foo"], " beta"]])

    verifyDoc("**x**", ["<body>", ["<p>", ["<strong>", "x"]]])
    verifyDoc("\n\n**x**", ["<body>", ["<p>", ["<strong>", "x"]]])
    verifyDoc("alpha **foo** beta", ["<body>", ["<p>", "alpha ", ["<strong>", "foo"], " beta"]])

    ph := FandocParser { parseHeader = false }.parseStr("\n**foo**")
    verifyDocNode(ph, ["<body>", ["<p>", ["<strong>", "foo"]]])

    // strong nested in emphasis
    verifyDoc("* **wow** *", ["<body>", ["<p>",  ["<em>", " ", ["<strong>", "wow"], " "]]])
    verifyDoc("You know, *winter\n**really, really**\nsucks*!", ["<body>", ["<p>", "You know, ",
      ["<em>", "winter ", ["<strong>", "really, really"], " sucks"], "!"]])

    // emphasis nested in strong
    verifyDoc("** *wow* **", ["<body>", ["<p>",  ["<strong>", " ", ["<em>", "wow"], " "]]])
    verifyDoc("You know, **winter\n*really, really*\nsucks**!", ["<body>", ["<p>", "You know, ",
      ["<strong>", "winter ", ["<em>", "really, really"], " sucks"], "!"]])

    verifyDoc("**`foo`**", ["<body>", ["<p>", ["<strong>", ["<a foo>", "foo"]]]])
    verifyDoc("**[some Foo]`foo`**", ["<body>", ["<p>", ["<strong>", ["<a foo>", "some Foo"]]]])

    /* dfn term retired
    verifyDoc("/term/", ["<body>", ["<p>", ["<dfn>", "term"]]])
    verifyDoc("/term/ what it is", ["<body>", ["<p>", ["<dfn>", "term"], " what it is"]])
    verifyDoc("/`#jump`/", ["<body>", ["<p>", ["<dfn>", ["<a #jump>", "#jump"]]]])
    verifyDoc("/[JUMP]`#jump`/", ["<body>", ["<p>", ["<dfn>", ["<a #jump>", "JUMP"]]]])
    */

    // these are normal paragraphs because the symbol
    // isn't prefixed with a space
    verifyDoc("a*b", ["<body>", ["<p>", "a*b"]])
    verifyDoc("a**b", ["<body>", ["<p>", "a**b"]])
    verifyDoc("a/b", ["<body>", ["<p>", "a/b"]])

    // these are normal paragraphs because the symbol is followed by space
    verifyDoc("a * b",  ["<body>", ["<p>", "a * b"]])
    verifyDoc("a / b",  ["<body>", ["<p>", "a / b"]])
    /*verifyDoc("a ** b", ["<body>", ["<p>", "a ** b"]])*/
  }

  Void testEmphasisErr()
  {
    verifyDoc("Alpha beta\ngamma * in *.java,\ndelta.",
      ["<body>", ["<p>", "Alpha beta gamma * in *.java, delta."]])
  }

//////////////////////////////////////////////////////////////////////////
// Code
//////////////////////////////////////////////////////////////////////////

  Void testCode()
  {
    verifyDoc("Brian's", ["<body>", ["<p>", "Brian's"]])
    verifyDoc("'x'", ["<body>", ["<p>", ["<code>", "x"]]])
    verifyDoc("a 'x'", ["<body>", ["<p>", "a ", ["<code>", "x"]]])
    verifyDoc("a 'x' b", ["<body>", ["<p>", "a ", ["<code>", "x"], " b"]])
    verifyDoc(" 'x' b ", ["<body>", ["<p>", ["<code>", "x"], " b"]])
    verifyDoc("'x * y / z [`foo`]'", ["<body>", ["<p>", ["<code>", "x * y / z [`foo`]"]]])

    // test emphasis symbols in code block
    verifyDoc("'*a*'",    ["<body>", ["<p>", ["<code>", "*a*"]]])
    verifyDoc("'**a**'",  ["<body>", ["<p>", ["<code>", "**a**"]]])
    verifyDoc("'/foo/'",  ["<body>", ["<p>", ["<code>", "/foo/"]]])
  }

//////////////////////////////////////////////////////////////////////////
// Links
//////////////////////////////////////////////////////////////////////////

  Void testLinks()
  {
    verifyDoc("`uri`", ["<body>", ["<p>", ["<a uri>", "uri"]]])
    verifyDoc("a `uri`", ["<body>", ["<p>", "a ", ["<a uri>", "uri"]]])
    verifyDoc("a `uri` b", ["<body>", ["<p>", "a ", ["<a uri>", "uri"], " b"]])
    verifyDoc("`uri` b", ["<body>", ["<p>", ["<a uri>", "uri"], " b"]])
    verifyDoc("Foo `one` bar `two`.", ["<body>", ["<p>", "Foo ", ["<a one>", "one"], " bar ", ["<a two>", "two"], "."]])

    verifyDoc("[cool site]`http://cool/`", ["<body>", ["<p>", ["<a http://cool/>", "cool site"]]])
    verifyDoc("Check [cool site]`http://cool/`!", ["<body>", ["<p>", "Check ", ["<a http://cool/>", "cool site"], "!"]])
    verifyDoc("([cool site]`http://cool/`)", ["<body>", ["<p>", "(", ["<a http://cool/>", "cool site"], ")"]])

    // empty [] are normal text
    verifyDoc("[]", ["<body>", ["<p>", "[]"]])
    verifyDoc("x [] y", ["<body>", ["<p>", "x [] y"]])
  }

//////////////////////////////////////////////////////////////////////////
// Image
//////////////////////////////////////////////////////////////////////////

  Void testImage()
  {
    verifyDoc("![cool image]`cool.png`", ["<body>", ["<p>", ["<img cool image;cool.png>"]]])
    verifyDoc("![cool image][100x200]`cool.png`", ["<body>", ["<p>", ["<img cool image;cool.png;100x200>"]]])
    verifyDoc("![Brian's Idea]`http://foo/idea.gif`", ["<body>", ["<p>", ["<img Brian's Idea;http://foo/idea.gif>"]]])
    verifyDoc("alpha ![x]`img.png` beta", ["<body>", ["<p>", "alpha ", ["<img x;img.png>"], " beta"]])
    verifyDoc("[![x]`img.png`]`#link`", ["<body>", ["<p>", ["<a>", ["<img x;img.png>"]]]])
  }

//////////////////////////////////////////////////////////////////////////
// AnchorIds
//////////////////////////////////////////////////////////////////////////

  Void testAnchorIds()
  {
    doc := verifyDoc("[#xyz]some text\nthe end.", ["<body>", ["<p>", "some text the end."]])
    verifyEq(doc.children.first->anchorId, "xyz")

    doc = verifyDoc("Chapter Two [#ch2]\n=======\nblah blah", ["<body>", ["<h3>", "Chapter Two"], ["<p>", "blah blah"]])
    verifyEq(doc.children.first->anchorId, "ch2")

    doc = verifyDoc("[#ch2]Chapter Two\n=======\nblah blah", ["<body>", ["<h3>", "Chapter Two"], ["<p>", "blah blah"]])
    verifyEq(doc.children.first->anchorId, "ch2")
  }

//////////////////////////////////////////////////////////////////////////
// Para
//////////////////////////////////////////////////////////////////////////

  Void testPara()
  {
    verifyDoc("", ["<body>"])
    verifyDoc("  \n  \n", ["<body>"])
    verifyDoc("a", ["<body>", ["<p>", "a"]])
    verifyDoc("\na", ["<body>", ["<p>", "a"]])
    verifyDoc("\n\na b c\nd e f.", ["<body>", ["<p>", "a b c d e f."]])
    verifyDoc("a b c\n\nd e f.  ", ["<body>", ["<p>", "a b c"], ["<p>", "d e f."]])
    verifyDoc("alpha\r\nbeta\r\n\r\ngamma\r\n", ["<body>", ["<p>", "alpha beta"], ["<p>", "gamma"]])
    verifyDoc("NOTE: that's right", ["<body>", ["<p NOTE>", "that's right"]])
    verifyDoc("TODO: that's right\nkeep it!", ["<body>", ["<p TODO>", "that's right keep it!"]])
    verifyDoc("Note: that's right", ["<body>", ["<p>", "Note: that's right"]])
  }

//////////////////////////////////////////////////////////////////////////
// Pre
//////////////////////////////////////////////////////////////////////////

  Void testPre()
  {
    verifyDoc("  a+b", ["<body>", ["<pre>", "a+b"]])
    verifyDoc("a\n\n  foo\n  bar\n\nb", ["<body>", ["<p>", "a"], ["<pre>", "foo\nbar"], ["<p>", "b"],])

    verifyDoc(
     "  class A
        {
          Int x()
          {
            return 3
          }
        }


        class B {}
      ",
         ["<body>", ["<pre>", "class A\n{\n  Int x()\n  {\n    return 3\n  }\n}\n\n\nclass B {}"]])

    verifyDoc("Code:\n  [,]", ["<body>", ["<p>", "Code:"], ["<pre>", "[,]"]])
  }

//////////////////////////////////////////////////////////////////////////
// PreExplicit
//////////////////////////////////////////////////////////////////////////

  Void testPreExplicit()
  {
    verifyDoc(
     "pre>
        - a

        - b
      <pre
      ", ["<body>", ["<pre>", "- a\n\n- b\n"]])

    verifyDoc(
     "pre>
        a
       b
      c
      <pre
      ", ["<body>", ["<pre>", "  a\n b\nc\n"]])

    verifyDoc(
     "pre>
         3
        2
           5
          4
      <pre
      ", ["<body>", ["<pre>", " 3\n2\n   5\n  4\n"]])
  }

//////////////////////////////////////////////////////////////////////////
// Headings
//////////////////////////////////////////////////////////////////////////

  Void testHeadings()
  {
    verifyDoc(
     "Chapter 1
      *********

      1.1
      ===
      Alpha
      Beta

      1. 1.1
      -----
        Foo

      New Book
      ########
      Chapter 2
      *********

      Roger - chapter two!
      ", ["<body>",
            ["<h2>", "Chapter 1"],
            ["<h3>", "1.1"],
            ["<p>", "Alpha Beta"],
            ["<h4>", "1. 1.1"],
            ["<pre>", "Foo"],
            ["<h1>", "New Book"],
            ["<h2>", "Chapter 2"],
            ["<p>", "Roger - chapter two!"],
          ])

    verifyDoc("a\n\n####\nb", ["<body>", ["<p>", "a"], ["<p>", "#### b"]])
    verifyDoc("a\n\n===\n\nb", ["<body>", ["<p>", "a"], ["<p>", "==="], ["<p>", "b"]])
    verifyDoc("\n\n------\n", ["<body>", ["<hr>"]])
  }

//////////////////////////////////////////////////////////////////////////
// HR
//////////////////////////////////////////////////////////////////////////

  Void testHr()
  {
    verifyDoc("Foo\n\n---\nBar", ["<body>", ["<p>", "Foo"], ["<hr>"], ["<p>", "Bar"]])
    verifyDoc("\n\n---", ["<body>", ["<hr>"]])
    verifyDoc("\n\n---\n", ["<body>", ["<hr>"]])
  }

//////////////////////////////////////////////////////////////////////////
// BlockQuotes
//////////////////////////////////////////////////////////////////////////

  Void testBlockQuotes()
  {
    verifyDoc("> a", ["<body>", ["<blockquote>", ["<p>", "a"]]])
    verifyDoc("> a\n> b c\n> d", ["<body>", ["<blockquote>", ["<p>", "a b c d"]]])
    verifyDoc("> a\nb c\nd\n\np2", ["<body>", ["<blockquote>", ["<p>", "a b c d"]], ["<p>", "p2"]])
    verifyDoc("> a\nb\n\n> c\nd\ne\n\nf", ["<body>", ["<blockquote>", ["<p>", "a b"], ["<p>", "c d e"]], ["<p>", "f"]])
    verifyDoc("> a\n> b\n\n> c\n> d\n> e\n\nf", ["<body>", ["<blockquote>", ["<p>", "a b"], ["<p>", "c d e"]], ["<p>", "f"]])
  }

//////////////////////////////////////////////////////////////////////////
// UL
//////////////////////////////////////////////////////////////////////////

  Void testUL()
  {
    verifyDoc(
     "- a

      heading
      ----", ["<body>", ["<ul>", ["<li>", "a"]], ["<h4>", "heading"]])

    verifyDoc("- a", ["<body>", ["<ul>", ["<li>", "a"]]])

    verifyDoc(
     "- a
      - b
      - c
      ",
    ["<body>", ["<ul>", ["<li>", "a"], ["<li>", "b"], ["<li>", "c"]]])

    verifyDoc(
     "- li [link]`uri` text
      - li", ["<body>", ["<ul>", ["<li>", "li ", ["<a uri>", "link"], " text"], ["<li>", "li"]]])

    verifyDoc(
     "- one
        - a
        - b
      - two
        - c
        - d
      ",
    ["<body>",
      ["<ul>",
        ["<li>", "one", ["<ul>", ["<li>", "a"], ["<li>", "b"]]],
        ["<li>", "two", ["<ul>", ["<li>", "c"], ["<li>", "d"]]]]])

    verifyDoc(
     "- one
        - a
          - i
          - j
        - b
      - two
        - c
        - d
          - k
      ",
    ["<body>",
      ["<ul>",
        ["<li>", "one", ["<ul>",
          ["<li>", "a", ["<ul>", ["<li>", "i"], ["<li>", "j"]]],
          ["<li>", "b"]]],
        ["<li>", "two", ["<ul>",
          ["<li>", "c"],
          ["<li>", "d", ["<ul>", ["<li>", "k"]]]
        ]]]])

    verifyDoc(
     "  - a b c
          d e f
        - g h i j k
      l m n o
        - p q
            r s
      ",
    ["<body>", ["<ul>", ["<li>", "a b c d e f"], ["<li>", "g h i j k l m n o"], ["<li>", "p q", ["<pre>", "r s"]]]])

    verifyDoc(
     "- 1-a
        1-b
      - 2-a
        2-b
      ",
      ["<body>", ["<ul>", ["<li>", "1-a 1-b"], ["<li>", "2-a 2-b"]]])

    verifyDoc(
     "- one
        line 2

        one para 2
        more

      - two

          Int x()
            {
              return x
            }

          Int y

        two para another
      ",
    ["<body>", ["<ul>",
      ["<li>", "one line 2", ["<p>", "one para 2 more"]],
      ["<li>", "two", ["<pre>", "Int x()\n  {\n    return x\n  }\n\nInt y"], ["<p>", "two para another"]]]])
  }

//////////////////////////////////////////////////////////////////////////
// OL
//////////////////////////////////////////////////////////////////////////

  Void testOL()
  {
    // these are not lists
    verifyDoc("This is\nit. Right?", ["<body>", ["<p>", "This is it. Right?"]])

    verifyDoc("1. one\n2. two", ["<body>", ["<ol 1>", ["<li>", "one"], ["<li>", "two"]]])
    verifyDoc("  A. one\n  B. two", ["<body>", ["<ol A>", ["<li>", "one"], ["<li>", "two"]]])
    verifyDoc("a. one\ntwo\nthree", ["<body>", ["<ol a>", ["<li>", "one two three"]]])
    verifyDoc("I. one\nII. two\nIII. three", ["<body>", ["<ol I>", ["<li>", "one"], ["<li>", "two"], ["<li>", "three"]]])
    verifyDoc("i. one\nii. two", ["<body>", ["<ol i>", ["<li>", "one"], ["<li>", "two"]]])

    verifyDoc(
     "I. ONE
        A. alpha
          i. one
          ii. two
        B. beta
      II. TWO
        A. gamma
        B. delta

             - a
             - b
             - c

           delta continues
           again

             some code
               -> foo

           delta another para

      ",
    ["<body>",
      ["<ol I>",
        ["<li>", "ONE", ["<ol A>",
          ["<li>", "alpha", ["<ol i>",
                            ["<li>", "one"], ["<li>", "two"]]],
          ["<li>", "beta"]]],
        ["<li>", "TWO", ["<ol A>",
          ["<li>", "gamma"],
          ["<li>", "delta", ["<ul>", ["<li>", "a"], ["<li>", "b"], ["<li>", "c"]],
                            ["<p>", "delta continues again"],
                            ["<pre>", "some code\n  -> foo"],
                            ["<p>", "delta another para"]]
        ]]]])


    verifyDoc(
     "1. 1-a
         1-b
      2. 2-a
         2-b

         2-c
         2-d
      ",
      ["<body>", ["<ol 1>", ["<li>", "1-a 1-b"], ["<li>", "2-a 2-b", ["<p>", "2-c 2-d"]]]])

    verifyDoc(
      "i. 1-a
          1-b
       ii. 2-a
           2-b
       iii. 3-a
            3-b
       ",
      ["<body>", ["<ol i>", ["<li>", "1-a 1-b"], ["<li>", "2-a 2-b"], ["<li>", "3-a 3-b"]]])
  }

//////////////////////////////////////////////////////////////////////////
// Meta
//////////////////////////////////////////////////////////////////////////

  Void testMeta()
  {
    doc := verifyDoc(
     "**************************************
      ** a: b
      ** title: Rocking test here!
      **************************************

      head
      ***

      para", ["<body>", ["<h2>", "head"], ["<p>", "para"]])


     verifyEq(doc.meta.size, 2)
     verifyEq(doc.meta["a"], "b")
     verifyEq(doc.meta["title"], "Rocking test here!")
  }

//////////////////////////////////////////////////////////////////////////
// Errors
//////////////////////////////////////////////////////////////////////////

  Void testErrs()
  {
    verifyErrs("*i",
     ["<body>", ["<p>", "*i"]],
     [1, "Invalid *emphasis*"])

    verifyErrs("a\nb\n**i",
     ["<body>", ["<p>", "a b **i"]],
     [3, "Invalid **strong**"])

    verifyErrs("aaaa\nbbbb bbb\n\nccc\n**i",
     ["<body>", ["<p>", "aaaa bbbb bbb"], ["<p>", "ccc **i"]],
     [5, "Invalid **strong**"])

    verifyErrs(
    "abc `foo

     1. ok
     2. *bad
     3. **worse
     ",
     ["<body>", ["<p>", "abc `foo"], ["<ol 1>", ["<li>", "ok"], ["<li>", "*bad"], ["<li>", "**worse"]]],
     [
       1, "Invalid uri",
       4, "Invalid *emphasis*",
       5, "Invalid **strong**",
     ])

    verifyErrs("------\na\n- one\n- two",
     ["<body>", ["<pre>", "------\na\n- one\n- two"]],
     [1, "Invalid line 1"])
  }

  Void verifyErrs(Str str, Obj[] expected, Obj[] errs)
  {
    parser := FandocParser { silent = true }
    doc := parser.parse("Test", str.in)
    verifyDocNode(doc, expected)
    // echo("======")
    // parser.errs.each |Err e| { echo(e) }
    verifyEq(parser.errs.size, errs.size/2)
    parser.errs.each |FandocErr e, Int i|
    {
      verifyEq(e.file, "Test")
      verifyEq(e.line, errs[i*2])
      verifyEq(e.msg,  errs[i*2+1])
    }

  }

//////////////////////////////////////////////////////////////////////////
// ListItem
//////////////////////////////////////////////////////////////////////////

  Void testToB26()
  {
    li := ListIndex(OrderedListStyle.lowerAlpha)
    verifyEq(li.toStr, "a. ")
    verifyEq(li.increment.toStr, "b. ")
    verifyEq(li.increment.toStr, "c. ")
    verifyEq(li.increment.toStr, "d. ")
    verifyEq(li.increment.toStr, "e. ")
    verifyEq(li.increment.toStr, "f. ")
    verifyEq(li.increment.toStr, "g. ")

    li.index = 25
    verifyEq(li.toStr, "y. ")
    verifyEq(li.increment.toStr, "z. ")
    verifyEq(li.increment.toStr, "aa. ")
    verifyEq(li.increment.toStr, "ab. ")
    verifyEq(li.increment.toStr, "ac. ")

    li = ListIndex(OrderedListStyle.upperAlpha)
    verifyEq(li.toStr, "A. ")
    verifyEq(li.increment.toStr, "B. ")
    verifyEq(li.increment.toStr, "C. ")
    verifyEq(li.increment.toStr, "D. ")
    verifyEq(li.increment.toStr, "E. ")
    verifyEq(li.increment.toStr, "F. ")
    verifyEq(li.increment.toStr, "G. ")

    li.index = 26
    verifyEq(li.toStr, "Z. ")
    verifyEq(li.increment.toStr, "AA. ")
    verifyEq(li.increment.toStr, "AB. ")
    verifyEq(li.increment.toStr, "AC. ")
  }

  Void testToRoman()
  {
    li := ListIndex(OrderedListStyle.lowerRoman)
    verifyEq(li.toStr, "i. ")
    verifyEq(li.increment.toStr, "ii. ")
    verifyEq(li.increment.toStr, "iii. ")
    verifyEq(li.increment.toStr, "iv. ")
    verifyEq(li.increment.toStr, "v. ")
    verifyEq(li.increment.toStr, "vi. ")
    verifyEq(li.increment.toStr, "vii. ")

    li.index = 26
    verifyEq(li.toStr, "xxvi. ")
    verifyEq(li.increment.toStr, "xxvii. ")
    verifyEq(li.increment.toStr, "xxviii. ")
    verifyEq(li.increment.toStr, "xxix. ")

    li = ListIndex(OrderedListStyle.upperRoman)
    verifyEq(li.toStr, "I. ")
    verifyEq(li.increment.toStr, "II. ")
    verifyEq(li.increment.toStr, "III. ")
    verifyEq(li.increment.toStr, "IV. ")
    verifyEq(li.increment.toStr, "V. ")
    verifyEq(li.increment.toStr, "VI. ")
    verifyEq(li.increment.toStr, "VII. ")

    li.index = 26
    verifyEq(li.toStr, "XXVI. ")
    verifyEq(li.increment.toStr, "XXVII. ")
    verifyEq(li.increment.toStr, "XXVIII. ")
    verifyEq(li.increment.toStr, "XXIX. ")
  }

//////////////////////////////////////////////////////////////////////////
// VerifyDoc
//////////////////////////////////////////////////////////////////////////

  Doc verifyDoc(Str str, Obj[] expected)
  {
    parser := FandocParser { silent = true }
    doc := parser.parse("Test", str.in)

    // echo("__________________\n$str\n\n")
    // doc.write(HtmlDocWriter())

    verifyDocNode(doc, expected)

    roundtrip := StrBuf()
    doc.write(FandocDocWriter(roundtrip.out))
    // echo; echo(roundtrip.toStr)
    doc2 := parser.parse("Test-2", roundtrip.toStr.in)
    verifyDocNode(doc2, expected)

    return doc
  }

  Void verifyDocNode(DocElem actual, Obj[] expected)
  {
    // first item is <elem>, rest are children nodes
    expectedElem := expected.first
    expectedKids := expected[1..-1]

    elemName := expectedElem.toStr[1..-2]
    olStyle := OrderedListStyle.number
    if (elemName.startsWith("ol"))
    {
      olStyle = OrderedListStyle.fromFirstChar(elemName[-1])
      elemName = "ol"
      verifyEq(actual->style, olStyle)
    }
    else if (elemName.startsWith("p "))
    {
      admonition := elemName[2..-1]
      elemName = "p"
      verifyEq(actual->admonition, admonition)
    }
    else if (elemName.startsWith("a "))
    {
      uri := elemName[2..-1]
      elemName = "a"
      verifyEq(actual->uri, uri)
    }
    else if (elemName.startsWith("img "))
    {
      body := elemName[4..-1]
      elemName = "img"
      verifyEq(actual->alt, body.split(';')[0])
      verifyEq(actual->uri, body.split(';')[1])
      verifyEq(actual->size, body.split(';').getSafe(2))
    }

    verifyEq(actual.htmlName, elemName)
    if (actual.children.size != expectedKids.size)
    {
      echo("")
      echo("actual   = $actual.children")
      echo("expected = $expectedKids")
    }
    verifyEq(actual.children.size, expectedKids.size)
    actual.children.size.times |Int i|
    {
      a := actual.children[i]
      e := expectedKids[i]
      if (a is DocElem)
      {
        verifyDocNode((DocElem)a, (Obj[])e)
      }
      else
      {
        verifyType(a, DocText#)
        if (a->str != e) {
            Env.cur.err.printLine("-----")
            Env.cur.err.printLine(a->str)
            Env.cur.err.printLine(" != ")
            Env.cur.err.printLine(e)
            Env.cur.err.printLine("-----")
        }
        verifyEq(a->str, e)
      }
    }
  }

}