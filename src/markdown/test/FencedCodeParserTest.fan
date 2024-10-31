//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Oct 2024  Matthew Giannini  Creation
//

@Js
class FencedCodeParserTest : CoreRenderingTest
{
  Void testBacktickInfo()
  {
    doc := Parser().parse("```info ~ test\ncode\n```")
    codeBlock := (FencedCode)doc.firstChild
    verifyEq("info ~ test", codeBlock.info)
    verifyEq("code\n", codeBlock.literal)
  }

  Void testBacktickInfoDoesntAllowBacktick()
  {
    verifyRendering(
      "```info ` test\ncode\n```",
      "<p>```info ` test\ncode</p>\n<pre><code></code></pre>\n")
  }

  Void testBacktickAndTildeCantBeMixed()
  {
    verifyRendering(
      "``~`\ncode\n``~`",
      "<p><code>~` code </code>~`</p>\n")
  }

  Void testClosingCanHaveSpacesAfter()
  {
    verifyRendering(
      "```\ncode\n```  ",
      "<pre><code>code\n</code></pre>\n")
  }

  Void testClosingCanNotHavNonSpaces()
  {
    verifyRendering(
      "```\ncode\n``` a",
      "<pre><code>code\n``` a\n</code></pre>\n")
  }

  Void test151()
  {
    verifyRendering(
      "```\nthis code\n\nshould not have BRs or paragraphs in it\nok\n```",
      "<pre><code>this code\n" +
      "\n" +
      "should not have BRs or paragraphs in it\n" +
      "ok\n" +
      "</code></pre>\n")
  }
}