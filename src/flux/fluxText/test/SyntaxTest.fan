//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jul 08  Brian Frank  Creation
//

using fwt

class SyntaxTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Setup
//////////////////////////////////////////////////////////////////////////

  const SyntaxOptions opt := SyntaxOptions.load
  const RichTextStyle t := opt.text
  const RichTextStyle s := opt.literal
  const RichTextStyle c := opt.comment
  const RichTextStyle b := opt.bracket
  const RichTextStyle bm := opt.bracketMatch

  Void testSetup()
  {
    verifyNotSame(t, s)
    verifyNotSame(t, c)
    verifyNotSame(t, b)
    verifyNotSame(s, c)
    verifyNotSame(s, b)
    verifyNotSame(c, b)
    verifyNotSame(b, bm)
  }

//////////////////////////////////////////////////////////////////////////
// Single line comments
//////////////////////////////////////////////////////////////////////////

  Void testComments()
  {
    verifySyntax("fan",
    "x // y\n" +
    "// z",
    [
      [0, t, 2, c],
      [0, c],
    ])
  }

//////////////////////////////////////////////////////////////////////////
// Block comments
//////////////////////////////////////////////////////////////////////////

  Void testMultiline1()
  {
    verifySyntax("fan",
   //0123456789
    "aa /* bb\n" +  // 0
    "ccc\n" +       // 1
    "dd */ eee",    // 2
    [
      [0, t, 3, c],
      [0, c],
      [0, c, 5, t],
    ])
  }

  Void testMultilineNested1()
  {
    verifySyntax("fan",
   //0123456789
    "x/* bb\n" +  // 0
    "{}\n" +      // 1
    "/*\n" +      // 2
    "a /* b /* c\n" +  // 3
    "c */ b */ c\n" +  // 4
    "*/\n" +      // 5
    "{}\n" +      // 6
    "dd */ eee",  // 7
    [
      [0, t, 1, c],
      [0, c],
      [0, c],
      [0, c],
      [0, c],
      [0, c],
      [0, c],
      [0, c, 5, t],
    ])
  }

  Void testMultilineNested2()
  {
    verifySyntax("fan",
   //0123456789
    "x /* y */ z /*\n" +   // 0
    "a /* b */ xx\n" +     // 1
    "\"foo\"\n" +          // 2
    "*/ c*d /* e */\n" +   // 3
    "x/* /* /* x */ x\n" + // 4
    "*/\n" +               // 5
    "*/foo",               // 6
    [
      [0, t, 2, c, 9, t, 12, c],
      [0, c],
      [0, c],
      [0, c, 2, t, 7, c],
      [0, t, 1, c],
      [0, c],
      [0, c, 2, t],
    ])
  }

  Void testMultilineUnnested()
  {
    verifySyntax("java",
   //0123456789
    "x /* y */ z /*\n" +   // 0
    "a /* {cool}\n" +      // 1
    "ab */ xx\n" +         // 2
    "/*\"foo\"\n" +        // 3
    "*/ c*d",              // 4
    [
      [0, t, 2, c, 9, t, 12, c],
      [0, c],
      [0, c, 5, t],
      [0, c],
      [0, c, 2, t],
    ])
  }

//////////////////////////////////////////////////////////////////////////
// Strs
//////////////////////////////////////////////////////////////////////////

  Void testStrs()
  {
    verifySyntax("fan",
                          //    0123456789_12345
    "x\"foo\"y\n" +       // 0  x"foo"y
    "x'c'y\n" +           // 1  x'c'y
    "`/bar`y\n" +         // 2  `/bar`y
    "a\"b\\\"c\"d\n" +    // 3  a"b\"c"d
    "'\\\\'+`x\\`x`!\n" + // 4  '\\'+`x\`x`!
    "\"x\\\\\"!\n" +      // 5  "x\\"!
    "{\"x\\\\\\\"y\"}\n"+ // 6  {"x\\\"y"}
    "\"a\",\"b\",`c`,`d`",// 7  "a","b",`c`,`d`
                          //    0123456789_12345
    [
      [0, t, 1, s, 6, t],
      [0, t, 1, s, 4, t],
      [0, s, 6, t],
      [0, t, 1, s, 7, t],
      [0, s, 4, t, 5, s, 11, t],
      [0, s, 5, t],
      [0, b, 1, s, 9, b],
      [0, s, 3, t, 4, s, 7, t, 8, s, 11, t, 12, s],
    ])
  }

  Void testMultiLineStr()
  {
    verifySyntax("fan",
                       //    0123456789_12345
    "x\"foo\n" +       // 0  x"foo
    "// string!\n" +   // 1  // string
    "a=\\\"b\\\"\n" +  // 2  a=\"b\"
    "bar\"baz\"\n" +   // 3  bar"baz"
    "\";",             // 4  ";
    [
      [0, t, 1, s],
      [0, s],
      [0, s],
      [0, s, 4, t, 7, s],
      [0, s, 1, t],
    ])
  }

//////////////////////////////////////////////////////////////////////////
// Mixed Blocks
//////////////////////////////////////////////////////////////////////////

  Void testMixedBlocks()
  {
    verifySyntax("fan",
                       //    0123456789_12345
    "x\"foo/*\n" +     // 0  x"foo/*
    "/*\n" +           // 1  /*
    "bar*/ */\"baz",   // 2  bar*/ */"baz
    [
      [0, t, 1, s],
      [0, s],
      [0, s, 9, t],
    ])
  }

//////////////////////////////////////////////////////////////////////////
// Bracket Matching
//////////////////////////////////////////////////////////////////////////

  Void testBracketMatching()
  {
    // basics
    verifyBrackets("fan", "{}",  0, 0, [[0, bm, 1, bm]])
    verifyBrackets("fan", "x{}", 0, 1, [[0, t, 1, bm, 2, bm]])
    verifyBrackets("fan", "{x}", 0, 2, [[0, bm, 1, t, 2, bm]])
    verifyBrackets("fan", "{}x", 0, 1, [[0, bm, 1, bm, 2, t]])
    verifyBrackets("fan", "xx{}", 0, 2, [[0, t, 2, bm, 3, bm]])
    verifyBrackets("fan", "{xx}", 0, 3, [[0, bm, 1, t, 3, bm]])
    verifyBrackets("fan", "{}xx", 0, 1, [[0, bm, 1, bm, 2, t]])
    verifyBrackets("fan", "x{}x", 0, 1, [[0, t, 1, bm, 2, bm, 3, t]])
    verifyBrackets("fan", "x{x}x", 0, 1, [[0, t, 1, bm, 2, t, 3, bm, 4, t]])

    // nested
    verifyBrackets("fan", "[[]]",    0, 0, [[0, bm, 1, b, 3, bm]])
    verifyBrackets("fan", "[[]]",    0, 1, [[0, b, 1, bm, 2, bm, 3, b]])
    verifyBrackets("fan", "[[[]]]",  0, 0, [[0, bm, 1, b, 5, bm]])
    verifyBrackets("fan", "[[[]]]",  0, 1, [[0, b, 1, bm, 2, b, 4, bm, 5, b]])

    // multi-line (have spurious extra no-length text segments)
    verifyBrackets("fan", "{\n}",   0, 0, [[0, bm, 1, t], [0, bm, 1, t]])
    verifyBrackets("fan", "{\n\n}", 0, 0, [[0, bm, 1, t], [0, t], [0, bm, 1, t]])
    verifyBrackets("fan", "x{\n}",  0, 1, [[0, t, 1, bm], [0, bm, 1, t]])
    verifyBrackets("fan", "{x\n}",  0, 0, [[0, bm, 1, t], [0, bm, 1, t]])
    verifyBrackets("fan", "{\nx}",  0, 0, [[0, bm, 1, t], [0, t, 1, bm]])
    verifyBrackets("fan", "{\n}x",  0, 0, [[0, bm, 1, t], [0, bm, 1, t]])
  }

  Void verifyBrackets(Str ext, Str src, Int line, Int col, Obj[][] styling, Bool testReverse := true)
  {
    doc := Doc(TextEditorOptions.load,
               SyntaxOptions.load,
               SyntaxRules.load(SyntaxOptions.load, "foo.$ext".toUri.toFile, null))
    doc.text = src

    a := doc.offsetAtLine(line) + col
    b := doc.matchBracket(a)
    verify(b != null)

    bLine := doc.lineAtOffset(b)
    bCol  := b - doc.offsetAtLine(bLine)
    doc.setBracketMatch(line, col, bLine, bCol)

    verifySyntaxDoc(doc, styling)

    if (testReverse)
      verifyBrackets(ext, src, doc.bracketLine2, doc.bracketCol2, styling, false)
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  Void verifySyntax(Str ext, Str src, Obj[][] styling)
  {
    doc := Doc(TextEditorOptions.load,
               SyntaxOptions.load,
               SyntaxRules.load(SyntaxOptions.load, "foo.$ext".toUri.toFile, null))
    doc.text = src
    verifySyntaxDoc(doc, styling)
  }

  Void verifySyntaxDoc(Doc doc, Obj[][] styling)
  {
    trace := false
    if (trace) echo("###################")
    if (trace) doc.dump
    if (trace) echo("")
    styling.each |Obj[] expected, Int i|
    {
      actual := doc.lineStyling(i)
      if (trace) echo("Line $i: " + doc.line(i))
      if (trace) echo("         " + stylingToStr(expected))
      if (trace) echo("         " + stylingToStr(actual))
      verifyEq(expected, actual)
      expected.size.times |Int j|
      {
        verifySame(expected[j], actual[j])
      }
    }
    verifyEq(doc.lineCount, styling.size)
  }

  Str stylingToStr(Obj[] styling)
  {
    return styling.join(", ") |Obj x, Int i->Str|
    {
      if (i.isEven) return x.toStr
      if (x === t)  return "t"
      if (x === c)  return "c"
      if (x === s)  return "s"
      if (x === b)  return "b"
      if (x === bm) return "bm"
      return "?"
    }
  }

}