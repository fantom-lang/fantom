//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 May 07  Andy Frank  Creation
//

using fandoc

**
** DocCompilerTest
**
class DocCompilerTest : Test
{

//////////////////////////////////////////////////////////////////////////
// TypeLink
//////////////////////////////////////////////////////////////////////////

  Void testTypeLink()
  {
    verifyLink(Int#, "<a href='Int'>Int</a>")
    verifyLink(Duration[]#, "<a href='Duration'>Duration</a>[]")
    verifyLink(Duration[][]#, "<a href='Duration'>Duration</a>[][]")
    verifyLink(Duration[][][]#, "<a href='Duration'>Duration</a>[][][]")
    verifyLink(Int:Str#, "<a href='Int'>Int</a>:<a href='Str'>Str</a>")
    verifyLink(Int:Str[]#, "<a href='Int'>Int</a>:<a href='Str'>Str</a>[]")
    verifyLink(|Bool a|#, "|<a href='Bool'>Bool</a>|")
    verifyLink(|Bool a, Str b|#, "|<a href='Bool'>Bool</a>, <a href='Str'>Str</a>|")
    verifyLink(|Bool a, Str b -> Int|#, "|<a href='Bool'>Bool</a>, <a href='Str'>Str</a> -> <a href='Int'>Int</a>|")
    verifyLink(|Bool a, Str[] b -> Int|#, "|<a href='Bool'>Bool</a>, <a href='Str'>Str</a>[] -> <a href='Int'>Int</a>|")
    verifyLink(|Int:Str a -> Bool|#, "|<a href='Int'>Int</a>:<a href='Str'>Str</a> -> <a href='Bool'>Bool</a>|")
  }

  Void verifyLink(Type t, Str sig)
  {
    map  := |Type x->Uri| { return x.name.toUri }
    test := HtmlDocUtil.makeTypeLink(t, map)
    verifyEq(test, sig, "$test != $sig   $t.signature")
  }

//////////////////////////////////////////////////////////////////////////
// FirstSentanceTest
//////////////////////////////////////////////////////////////////////////

  Void testFirstSentanceTest()
  {
    verifySentence("Foo bar", "Foo bar")
    verifySentence("Foo bar.", "Foo bar.")
    verifySentence("Foo bar\n", "Foo bar")
    verifySentence("Foo bar\n ", "Foo bar")
    verifySentence("Foo bar\n\n", "Foo bar")
    verifySentence("Foo bar\n\n ", "Foo bar")
    verifySentence("Foo bar. Alpha beta", "Foo bar.")
    verifySentence("Foo bar.\nAlpha beta", "Foo bar.")
    verifySentence("Foo bar.\n\nAlpha beta", "Foo bar.")
    verifySentence("Foo bar\nAlpha beta", "Foo bar Alpha beta")
    verifySentence("Foo\nBar\nAlpha\nBeta", "Foo Bar Alpha Beta")
    verifySentence("Foo\nBar\nAlpha\nBeta.", "Foo Bar Alpha Beta.")
    verifySentence("Foo<bar> alpha & beta.", "Foo<bar> alpha & beta.")
  }

  Void verifySentence(Str para, Str sentence)
  {
    verifyEq(HtmlDocUtil.firstSentence(para), sentence)
  }

}