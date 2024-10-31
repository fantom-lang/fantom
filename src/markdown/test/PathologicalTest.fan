//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Oct 2024  Matthew Giannini  Creation
//

**
** Pathological input cases (from commonmark.js)
**
class PathologicalTest : CoreRenderingTest
{
  private Int x := 100_000

  Void testNestedStrongEmphasis()
  {
    // this is lmited by the stack size because visitor is recursive
    x = 100
    verifyRendering(
      "*a **a ".mult(x) + "b" + " a** a*".mult(x),
      "<p>" + "<em>a <strong>a ".mult(x) + "b" + " a</strong> a</em>".mult(x) + "</p>\n")
  }

  Void testEmphasisClosersWithNoOpeners()
  {
    verifyRendering(
      "a_ " * x,
      "<p>" + "a_ " * (x-1) + "a_</p>\n")
  }

  Void testEmphasisOpenersWithNoClosers()
  {
    verifyRendering(
      "_a " * x,
      "<p>" + "_a " * (x-1) + "_a</p>\n")
  }

  Void testLinkClosersWithNoOpeners()
  {
    verifyRendering(
      "a] " * x,
      "<p>" + "a] " * (x-1) + "a]</p>\n")
  }

  Void testLinkOpenersWithNoCloser()
  {
    verifyRendering(
      "[ a_ " * x,
      "<p>" + "[ a_ " * (x-1) + "[ a_</p>\n")
  }

  Void testMismatchedOpenersAndClosers()
  {
    verifyRendering(
      "*a_ " * x,
      "<p>" + "*a_ " * (x-1) + "*a_</p>\n")
  }

  Void testNestedBrackets()
  {
    // it works fine at x=100_000, but slows down the test
    x=50_000
    verifyRendering(
      "["*x + "a" + "]"*x,
      "<p>" + "["*x + "a" + "]"*x + "</p>\n")
  }

  Void testNestedBlockQuotes()
  {
    // this is limited by the stack size since visitor is recursive
    x = 250
    verifyRendering(
      "> "*x + "a\n",
      "<blockquote>\n"*x + "<p>a</p>\n" + "</blockquote>\n"*x)
  }

  Void testHugeHorizontalRule()
  {
    verifyRendering("*"*10_000 + "\n", "<hr />\n")
  }

  Void testBackslashInLink()
  {
    verifyRendering("[" + "\\"*x + "\n", "<p>[" + "\\"*(x/2) + "</p>\n")
  }

  Void testUnclosedInlineLinks()
  {
    verifyRendering("[]("*x + "\n", "<p>" + "[]("*x + "</p>\n")
  }
}