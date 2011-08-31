//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jul 08  Brian Frank  Creation
//   30 Aug 11  Brian Frank  Refactor out of fluxText
//

class SyntaxTest : Test
{

  const static SyntaxType t := SyntaxType.text
  const static SyntaxType b := SyntaxType.bracket
  const static SyntaxType k := SyntaxType.keyword
  const static SyntaxType s := SyntaxType.literal
  const static SyntaxType c := SyntaxType.comment

//////////////////////////////////////////////////////////////////////////
// Keywords
//////////////////////////////////////////////////////////////////////////

  Void testKeywords()
  {
    verifySyntax("fan",
    Str<|public class Foo
         "public"
         publicx
         public7
         xpublic
         virtual
         foo(bar)|>,
    [
      [k, "public", t, " ", k, "class", t, " Foo"],
      [s, Str<|"public"|>],
      [t, "publicx"],
      [t, "public7"],
      [t, "xpublic"],
      [k, "virtual"],
      [t, "foo", b, "(", t, "bar", b, ")"],
    ])
  }

//////////////////////////////////////////////////////////////////////////
// Single line comments
//////////////////////////////////////////////////////////////////////////

  Void testComments()
  {
    verifySyntax("fan",
    "foo/bar\n" +
    "x // y\n" +
    "// z",
    [
      [t, "foo/bar"],
      [t, "x ", c, "// y"],
      [c, "// z"],
    ])
  }

//////////////////////////////////////////////////////////////////////////
// Block comments
//////////////////////////////////////////////////////////////////////////

  Void testMultiline1()
  {
    verifySyntax("fan",
    "aa /* bb\n" +       // 0
    "ccc\n" +            // 1
    "dd */ eee\n" +      // 2
    "x /* // foo */ y",  // 3
    [
      [t, "aa ", c, "/* bb"],
      [c, "ccc"],
      [c, "dd */", t, " eee"],
      [t, "x ", c, "/* // foo */", t, " y"],
    ])
  }

  Void testMultilineNested1()
  {
    verifySyntax("fan",
    "x/* bb\n" +  // 0
    "{}\n" +      // 1
    "/*\n" +      // 2
    "a /* b /* c\n" +  // 3
    "c */ b */ c\n" +  // 4
    "*/\n" +      // 5
    "{}\n" +      // 6
    "dd */ eee",  // 7
    [
      [t, "x", c, "/* bb"],
      [c, "{}"],
      [c, "/*"],
      [c, "a /* b /* c"],
      [c, "c */ b */ c"],
      [c, "*/"],
      [c, "{}"],
      [c, "dd */", t, " eee"],
    ])
  }

  Void testMultilineNested2()
  {
    verifySyntax("fan",
    "x /* y */ z /*\n" +   // 0
    "a /* b */ xx\n" +     // 1
    "\"foo\"\n" +          // 2
    "*/ c*d /* e */\n" +   // 3
    "x/* /* /* x */ x\n" + // 4
    "*/\n" +               // 5
    "*/foo",               // 6
    [
      [t, "x ", c, "/* y */", t, " z ", c, "/*"],
      [c, "a /* b */ xx"],
      [c, "\"foo\""],
      [c, "*/", t, " c*d ", c, "/* e */"],
      [t, "x", c, "/* /* /* x */ x"],
      [c, "*/"],
      [c, "*/", t, "foo"],
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
      [t, "x ", c, "/* y */", t, " z ", c, "/*"],
      [c, "a /* {cool}"],
      [c, "ab */", t, " xx"],
      [c, "/*\"foo\""],
      [c, "*/", t, " c*d"],
    ])
  }

//////////////////////////////////////////////////////////////////////////
// Strs
//////////////////////////////////////////////////////////////////////////

  Void testStrs()
  {
    verifySyntax("fan",
                          //    0123456789_12345
    "x\"foo\"y!\n" +      // 0  x"foo"y!
    "x'c'y\n" +           // 1  x'c'y
    "`/bar`y\n" +         // 2  `/bar`y
    "a\"b\\\"c\"d\n" +    // 3  a"b\"c"d
    "'\\\\'+`x\\`x`!\n" + // 4  '\\'+`x\`x`!
    "\"x\\\\\"!\n" +      // 5  "x\\"!
    "{\"x\\\\\\\"y\"}\n"+ // 6  {"x\\\"y"}
    "\"a\",\"b\",`c`,`d`",// 7  "a","b",`c`,`d`
                          //    0123456789_12345
    [
      [t, "x", s, Str<|"foo"|>, t, "y!"],
      [t, "x", s, "'c'", t, "y"],
      [s, "`/bar`", t, "y"],
      [t, "a", s, Str<|"b\"c"|>, t, "d"],
      [s, Str<|'\\'|>, t, "+", s, Str<|`x\`x`|>, t, "!"],
      [s, Str<|"x\\"|>, t, "!"],
      [b, "{", s, Str<|"x\\\"y"|>, b, "}"],
      [s, Str<|"a"|>, t, ",",
       s, Str<|"b"|>, t, ",",
       s, Str<|`c`|>, t, ",",
       s, Str<|`d`|>],
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
      [t, "x", s, Str<|"foo|>],
      [s, "// string!"],
      [s, Str<|a=\"b\"|>],
      [s, "bar\"", t, "baz", s, "\""],
      [s, "\"", t, ";"],
    ])
  }

//////////////////////////////////////////////////////////////////////////
// Mixed Blocks
//////////////////////////////////////////////////////////////////////////

  Void testMixedBlocks()
  {
    verifySyntax("fan",
    Str<|x"""foo/*
         /* "hi"
         bar*/ */"""baz|>,
    [
      [t, "x", s, Str<|"""foo/*|>],
      [s, Str<|/* "hi"|>],
      [s, Str<|bar*/ */"""|>, t, "baz"],
    ])
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  Void verifySyntax(Str ext, Str src, Obj[][] expected)
  {
    rules := SyntaxRules.loadForExt(ext)
    if (rules == null) throw Err("no rules for $ext")
    doc := SyntaxDoc.parse(rules, src.in)

    // dump
    /*
    echo("##########################")
    doc.eachLine |line|
    {
      line.eachSegment |type, text|
      {
        Env.cur.out.print("$type $text.toCode  ")
      }
      Env.cur.out.printLine
    }
    echo()
    */

    // check number of lines
    lines := SyntaxLine[,]
    doc.eachLine |line| { lines.add(line) }
    verifyEq(lines.size, expected.size)

    // check each line
    lines.each |line, i|
    {
      verifyEq(line.num, i+1)
      segs := Obj[,]
      line.eachSegment |t, s| { segs.add(t).add(s) }
      if (segs == expected[i]) verify(true)
      else
      {
        echo("FAILURE line $line.num")
        echo("expected: " + lineToStr(expected[i]))
        echo("actual:   " + lineToStr(segs))
        fail
      }
    }
  }

  Str lineToStr(Obj[] styling)
  {
    s := StrBuf()
    for (i:=0; i<styling.size; i+=2)
    {
      type := styling[i] as SyntaxType ?: throw Err("$i ${styling[i]}")
      text := styling[i+1] as Str ?: throw Err("$i+1 ${styling[i+1]}")
      s.add(type === SyntaxType.literal ? "s" : type.toStr[0..0])
       .add(" ")
       .add(text.toCode)
       .add(", ")
    }
    return s.toStr
  }

}

