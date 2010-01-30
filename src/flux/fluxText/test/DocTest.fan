//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jul 08  Brian Frank  Creation
//

using fwt

class DocTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Basic Text Handling
//////////////////////////////////////////////////////////////////////////

  Void testEmpty()
  {
    doc := makeDoc("")
    verifyEq(doc.text, "")
    verifyEq(doc.charCount, 0)
    verifyEq(doc.lineCount, 1)
    verifyEq(doc.lineAtOffset(0), 0)
    verifyEq(doc.offsetAtLine(0), 0)
    verifyEq(doc.textRange(0,0), "")
  }

  Void testOne()
  {
    doc := makeDoc("x")
    verifyEq(doc.text, "x")
    verifyEq(doc.charCount, 1)
    verifyEq(doc.lineCount, 1)
    verifyEq(doc.lineAtOffset(0), 0)
    verifyEq(doc.lineAtOffset(1), 0)
    verifyEq(doc.offsetAtLine(0), 0)
    verifyEq(doc.textRange(0,1), "x")
  }

  Void testTwo()
  {
    doc := makeDoc("xy")
    verifyEq(doc.text, "xy")
    verifyEq(doc.charCount, 2)
    verifyEq(doc.lineCount, 1)
    verifyEq(doc.lineAtOffset(0), 0)
    verifyEq(doc.lineAtOffset(1), 0)
    verifyEq(doc.offsetAtLine(0), 0)
    verifyEq(doc.textRange(0,2), "xy")
    verifyEq(doc.textRange(0,1), "x")
    verifyEq(doc.textRange(1,1), "y")
  }

  Void testTwoLines()
  {
    doc := makeDoc("x\ny")
    verifyEq(doc.text, "x\ny")
    verifyEq(doc.charCount, 3)
    verifyEq(doc.lineCount, 2)
    verifyEq(doc.offsetAtLine(0), 0)
    verifyEq(doc.offsetAtLine(1), 2)
    verifyEq(doc.lineAtOffset(0), 0)
    verifyEq(doc.lineAtOffset(1), 0)
    verifyEq(doc.lineAtOffset(2), 1)
    verifyEq(doc.textRange(0,1), "x")
    verifyEq(doc.textRange(0,2), "x\n")
    verifyEq(doc.textRange(0,3), "x\ny")
    verifyEq(doc.textRange(1,1), "\n")
    verifyEq(doc.textRange(1,2), "\ny")
    verifyEq(doc.textRange(2,1), "y")
  }

  Void testThreeLines()
  {
    doc := makeDoc("abc\nd\nef")
    verifyEq(doc.text, "abc\nd\nef")
    verifyEq(doc.charCount, 8)
    verifyEq(doc.lineCount, 3)
    verifyEq(doc.offsetAtLine(0), 0)
    verifyEq(doc.offsetAtLine(1), 4)
    verifyEq(doc.offsetAtLine(2), 6)
    verifyEq(doc.lineAtOffset(0), 0)
    verifyEq(doc.lineAtOffset(1), 0)
    verifyEq(doc.lineAtOffset(3), 0)
    verifyEq(doc.lineAtOffset(4), 1)
    verifyEq(doc.lineAtOffset(5), 1)
    verifyEq(doc.lineAtOffset(6), 2)
    verifyText(doc, "abc\nd\nef")
  }

  Void testReplaceBasic()
  {
    doc := makeDoc("")
    doc.modify(0, 0, "y");       verifyText(doc, "y")
    doc.modify(0, 0, "x");       verifyText(doc, "xy")
    doc.modify(2, 0, "z");       verifyText(doc, "xyz")
    doc.modify(1, 0, "!");       verifyText(doc, "x!yz")
    doc.modify(1, 1, "");        verifyText(doc, "xyz")
    doc.modify(0, 3, "a\nb\nc"); verifyText(doc, "a\nb\nc")
    doc.modify(2, 1, "x");       verifyText(doc, "a\nx\nc")
    doc.modify(1, 1, "");        verifyText(doc, "ax\nc")
    doc.modify(4, 0, "\nd\ne");  verifyText(doc, "ax\nc\nd\ne")
    doc.modify(3, 2, "#");       verifyText(doc, "ax\n#d\ne")
    doc.modify(3, 2, "");        verifyText(doc, "ax\n\ne")
    doc.modify(2, 2, "q");       verifyText(doc, "axqe")
    doc.modify(1, 3, "\nfoo\nbar"); verifyText(doc, "a\nfoo\nbar")
    doc.modify(3, 2, "x\ny");    verifyText(doc, "a\nfx\ny\nbar")
    doc.modify(0, 0, "\n");      verifyText(doc, "\na\nfx\ny\nbar")
    doc.modify(11, 0, "\nw");    verifyText(doc, "\na\nfx\ny\nbar\nw")
    doc.modify(0, 13, "");       verifyText(doc, "")
  }

  Void testReplaceRand()
  {
    doc := makeDoc("")
    text := ""
    20.times
    {
      newText := randLines(1..5)
      start := Int.random(0..doc.size)
      len   := Int.random(0..doc.size).min(doc.size-start)
      text = text[0..<start] + newText + text[start+len..-1]
      doc.modify(start, len, newText)
      verifyText(doc, text)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Tabs
//////////////////////////////////////////////////////////////////////////

 Void testTabsWithoutConv()
 {
   options := TextEditorOptions()
   {
     tabSpacing = 2
     convertTabsToSpaces = false
   }

   doc := makeDoc("x\ty\t\tz\n\tabc", options)
   verifyEq(doc.line(0), "x\ty\t\tz")
   verifyEq(doc.line(1), "\tabc")

   doc.modify(0, 0, "\t")
   verifyEq(doc.line(0), "\tx\ty\t\tz")

   doc.modify(doc.offsetAtLine(1)+2, 0, "\t\t")
   verifyEq(doc.line(1), "\ta\t\tbc")
 }

 Void testTabsWithConv()
 {
   options := TextEditorOptions()
   {
     tabSpacing = 2
     convertTabsToSpaces = true
   }

   doc := makeDoc("x\ty\t\tz\n\tabc", options)
                        //__|_|_|_|
   verifyEq(doc.line(0), "x y   z")
   verifyEq(doc.line(1), "  abc")

   doc.modify(0, 0, "\t")
   verifyEq(doc.line(0), "  x y   z")

   doc.modify(doc.offsetAtLine(1)+3, 0, "\t\t")
                        //__|_|_|_|
   verifyEq(doc.line(1), "  a   bc")

 }

 Void testTabsConvertToSpaces()
 {
   verifySame(Parser.convertTabsToSpaces("a b c d", 2), "a b c d")
   verifyEq(Parser.convertTabsToSpaces("\t{}", 2),     "  {}")
   verifyEq(Parser.convertTabsToSpaces(" \t{}", 2),    "  {}")
   verifyEq(Parser.convertTabsToSpaces("\t\t{}", 2),   "    {}")
   verifyEq(Parser.convertTabsToSpaces("\t{}", 4),     "    {}")
   verifyEq(Parser.convertTabsToSpaces(" \t{}", 4),    "    {}")
   verifyEq(Parser.convertTabsToSpaces("  \t{}", 4),   "    {}")
   verifyEq(Parser.convertTabsToSpaces("   \t{}", 4),  "    {}")
   verifyEq(Parser.convertTabsToSpaces("    \t{}", 4), "        {}")
   verifyEq(Parser.convertTabsToSpaces("\t\t{}", 4),   "        {}")
   verifyEq(Parser.convertTabsToSpaces("\t \t{}", 4),  "        {}")
   verifyEq(Parser.convertTabsToSpaces("\t  \t{}", 4), "        {}")
   verifyEq(Parser.convertTabsToSpaces("\t   \t{}", 4),"        {}")
 }

//////////////////////////////////////////////////////////////////////////
// Bracket Matching
//////////////////////////////////////////////////////////////////////////

 Void testMatchBracket()
 {
   // basic
   //    01234567
   s := "<{[()]}>"
   doc := makeDoc(s)
   verifyMatchBracket(doc, 0, 7)
   verifyMatchBracket(doc, 1, 6)
   verifyMatchBracket(doc, 2, 5)
   verifyMatchBracket(doc, 3, 4)

   // spanning multiple lines
   //   0 12 34 56 78 90 12 34
   s = "<\n{\n[\n(\n)\n]\n}\n>"
   doc = makeDoc(s)
   verifyMatchBracket(doc, 0, 14)
   verifyMatchBracket(doc, 2, 12)
   verifyMatchBracket(doc, 4, 10)
   verifyMatchBracket(doc, 6, 8)

   // nested
   //   0 12 34 56 78 90 12 34
   s = "}\n{\n{\n{\n}\n}\n}\n{"
   doc = makeDoc(s)
   verifyEq(doc.matchBracket(0), null)
   verifyEq(doc.matchBracket(14), null)
   verifyMatchBracket(doc, 2, 12)
   verifyMatchBracket(doc, 4, 10)
   verifyMatchBracket(doc, 6, 8)
 }

 Void verifyMatchBracket(Doc doc, Int a, Int b)
 {
   verifyEq(doc.matchBracket(a), b)
   verifyEq(doc.matchBracket(b), a)
 }

//////////////////////////////////////////////////////////////////////////
// Find
//////////////////////////////////////////////////////////////////////////

  Void testFind()
  {
    doc := makeDoc("")
    doc.text =
    //0123456789_123456789_
     "Hello there, x foo!
      Thing xyz foo! foo!
      And that is all."

    verifyEq(doc.findNext("th", 0, true), 6)
    verifyEq(doc.findNext("Th", 0, true), 20)
    verifyEq(doc.findNext("Th", 0, false), 6)
    verifyEq(doc.findNext("TH", 0, true), null)
    verifyEq(doc.findNext("TH", 0, false), 6)
    verifyEq(doc.findNext("THING", 0, true), null)
    verifyEq(doc.findNext("THING", 0, false), 20)

    verifyEq(doc.findNext("foo", 0, true), 15)
    verifyEq(doc.findNext("foo", 16, true), 30)
    verifyEq(doc.findNext("foo", 32, true), 35)
    verifyEq(doc.findNext("foo", 36, true), null)
    verifyEq(doc.findNext("Foo", 0, true), null)
    verifyEq(doc.findNext("Foo", 0, false), 15)
    verifyEq(doc.findNext("Foo", 16, false), 30)
    verifyEq(doc.findNext("FOO", 32, false), 35)
    verifyEq(doc.findNext("fOO", 36, false), null)

    verifyEq(doc.findPrev("foo", 99, true), 35)
    verifyEq(doc.findPrev("foo", 34, true), 30)
    verifyEq(doc.findPrev("foo", 29, true), 15)
    verifyEq(doc.findPrev("foo", 14, true), null)
    verifyEq(doc.findPrev("FOO", 99, true), null)
    verifyEq(doc.findPrev("FOO", 99, false), 35)
    verifyEq(doc.findPrev("fOo", 34, false), 30)
    verifyEq(doc.findPrev("Foo", 29, false), 15)
    verifyEq(doc.findPrev("foO", 14, false), null)

    /* don't support mult-line find right now
    verifyEq(doc.findNext("oo!\nThing", 0, false), 16)
    verifyEq(doc.findNext("oo!\nThinx", 0, false), null)
    */
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  Str randLines(Range numLines)
  {
    text := ""
    Int.random(numLines).times
    {
      line := "abcdefghijklmnopqrstuvwxyz"[0..<Int.random(0..25)] + "\n"
      text += line
    }
    return text[0..-2]
  }

  Doc makeDoc(Str text, TextEditorOptions options := TextEditorOptions.load)
  {
    doc := Doc(options,
               SyntaxOptions.load,
               SyntaxRules.load(SyntaxOptions.load, null, null))
    doc.text = text
    return doc
  }

  Void verifyText(Doc doc, Str text)
  {
    verifyEq(doc.text, text)

    // try every offset to end
    lineIndex := 0
    text.size.times |Int s|
    {
      // ranges
      (text.size-s).times |Int i|
      {
        verifyEq(doc.textRange(s,i), text[s..<s+i])
      }

      // test line at offset
      verifyEq(doc.lineAtOffset(s), lineIndex)
      if (text[s] == '\n') lineIndex++
    }

    // try every single one char
    text.size.times |Int i|
    {
      verifyEq(doc.textRange(i, 1), text[i..i])
    }
  }
}