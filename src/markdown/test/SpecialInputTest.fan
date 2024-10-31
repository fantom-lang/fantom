//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Oct 2024  Matthew Giannini  Creation
//

@Js
class SpecialInputTest : CoreRenderingTest
{
  Void testEmpty()
  {
    verifyRendering("", "")
  }

  Void testNullCharacterShouldBeReplaces()
  {
    verifyRendering("foo\u0000bar", "<p>foo\uFFFDbar</p>\n")
  }

  Void testNullCharacterEntityShouldBeReplaced()
  {
    verifyRendering("foo&#0;bar", "<p>foo\uFFFDbar</p>\n")
  }

  Void testCrLfAsLineSeparatorShouldBeParsed()
  {
    verifyRendering("foo\r\nbar", "<p>foo\nbar</p>\n")
  }

  Void testCrLfAtEndShouldBeParsed()
  {
    verifyRendering("foo\r\n", "<p>foo</p>\n")
  }

  Void testIndentedCodeBlockWithMixedTabsAndSpaces()
  {
    verifyRendering("    foo\n\tbar", "<pre><code>foo\nbar\n</code></pre>\n");
  }

  Void testListInBlockQuote()
  {
    verifyRendering("> *\n> * a", "<blockquote>\n<ul>\n<li></li>\n<li>a</li>\n</ul>\n</blockquote>\n")
  }

  Void testLooseListInBlockQuote()
  {
    // second line in block quote is considered blank for purpose of loose list
    verifyRendering("> *\n>\n> * a", "<blockquote>\n<ul>\n<li></li>\n<li>\n<p>a</p>\n</li>\n</ul>\n</blockquote>\n")
  }

  Void testLineWithOnlySpacesAfterListBullet()
  {
    verifyRendering(
      "-  \n  \n  foo\n",
      """<ul>
         <li></li>
         </ul>
         <p>foo</p>\n""")
  }

  Void testListWIthTwoSpacesForFirstBullet()
  {
    // we have two spaces after the bullet, but no content. with content,
    // the next line would be required
    verifyRendering(
      "*  \n  foo\n",
      "<ul>\n<li>foo</li>\n</ul>\n")
  }

  Void testOrderedListMarkerOnly()
  {
    verifyRendering("2.", "<ol start=\"2\">\n<li></li>\n</ol>\n")
  }

  Void testColumnIsInTabOnPreviousLine()
  {
    verifyRendering(
      "- foo\n\n\tbar\n\n# baz\n",
      """<ul>
         <li>
         <p>foo</p>
         <p>bar</p>
         </li>
         </ul>
         <h1>baz</h1>\n""")

    verifyRendering(
      "- foo\n\n\tbar\n# baz\n",
      """<ul>
         <li>
         <p>foo</p>
         <p>bar</p>
         </li>
         </ul>
         <h1>baz</h1>\n""")
  }

  Void testLinkLabelWithBracket()
  {
    verifyRendering("[a[b]\n\n[a[b]: /", "<p>[a[b]</p>\n<p>[a[b]: /</p>\n")
    verifyRendering("[a]b]\n\n[a]b]: /", "<p>[a]b]</p>\n<p>[a]b]: /</p>\n")
    verifyRendering("[a[b]]\n\n[a[b]]: /", "<p>[a[b]]</p>\n<p>[a[b]]: /</p>\n")
  }

  Void testLinkLabelLen()
  {
    label1 := "a" * 999
    verifyRendering (
      "[foo][${label1}]\n\n[${label1}]: /",
      "<p><a href=\"/\">foo</a></p>\n")
    verifyRendering(
      "[foo][x${label1}]\n\n[x${label1}]: /",
      "<p>[foo][x${label1}]</p>\n<p>[x${label1}]: /</p>\n")
    verifyRendering(
      "[foo][\n${label1}]\n\n[\n${label1}]: /",
      "<p>[foo][\n${label1}]</p>\n<p>[\n${label1}]: /</p>\n")

    label2 := "a\n" * 499
    verifyRendering(
      "[foo][${label2}]\n\n[${label2}]: /",
      "<p><a href=\"/\">foo</a></p>\n")
    verifyRendering(
      "[foo][12${label2}]\n\n[12${label2}]: /",
      "<p>[foo][12${label2}]</p>\n<p>[12${label2}]: /</p>\n")
  }

  Void testLinkDestinationEscaping()
  {
    // backslash escapes ')'
    verifyRendering("[foo](\\))", "<p><a href=\")\">foo</a></p>\n")

    // ' ' is not escapable, so the backslash is a literal backslash and
    // there's an optional space
    verifyRendering("[foo](\\ )", "<p><a href=\"\\\">foo</a></p>\n")

    // backslash is a literal, so valid
    verifyRendering("[foo](<a\\b>)", "<p><a href=\"a\\b\">foo</a></p>\n")

    // backslash escapes '>' but there's another '>', valid
    verifyRendering("[foo](<a\\>>)", "<p><a href=\"a&gt;\">foo</a></p>\n")

    // this is a tricky one. there's '<' so we try to parse it as a '<' link but fail
    verifyRendering("[foo](<\\>)", "<p>[foo](&lt;&gt;)</p>\n")
  }

  Void testLinkReferenceBackslash()
  {
    // backslash escapes ']' so not a valid link label
    verifyRendering("[\\]: test", "<p>[]: test</p>\n")
    // backslash is a literal, so valid
    verifyRendering("[a\\b]\n\n[a\\b]: test", "<p><a href=\"test\">a\\b</a></p>\n")
    // backslash escapes ']' but there's another ']', valid
    verifyRendering("[a\\]]\n\n[a\\]]: test", "<p><a href=\"test\">a]</a></p>\n")
  }

  Void testEmphasisMultipleOf3Rule()
  {
    verifyRendering("a***b* c*", "<p>a*<em><em>b</em> c</em></p>\n")
  }

  Void testRenderEvenRegexpProducesStackoverflow()
  {
    render("Contents: <!--[if gte mso 9]> <w:LatentStyles DefLockedState=\"false\" DefUnhideWhenUsed=\"false\" DefSemiHidden=\"false\" DefQFormat=\"false\" DefPriority=\"99\" LatentStyleCount=\"371\">  <w:xxx Locked=\"false\" Priority=\"52\" Name=\"Grid Table 7 Colorful 6\"/> <w:xxx Locked=\"false\" Priority=\"46\" Name=\"List Table 1 Light\"/> <w:xxx Locked=\"false\" Priority=\"47\" Name=\"List Table 2\"/> <w:xxx Locked=\"false\" Priority=\"48\" Name=\"List Table 3\"/> <w:xxx Locked=\"false\" Priority=\"49\" Name=\"List Table 4\"/> <w:xxx Locked=\"false\" Priority=\"50\" Name=\"List Table 5 Dark\"/> <w:xxx Locked=\"false\" Priority=\"51\" Name=\"List Table 6 Colorful\"/> <w:xxx Locked=\"false\" Priority=\"52\" Name=\"List Table 7 Colorful\"/> <w:xxx Locked=\"false\" Priority=\"46\" Name=\"List Table 1 Light Accent 1\"/> <w:xxx Locked=\"false\" Priority=\"47\" Name=\"List Table 2 Accent 1\"/> <w:xxx Locked=\"false\" Priority=\"48\" Name=\"List Table 3 Accent 1\"/> <w:xxx Locked=\"false\" Priority=\"49\" Name=\"List Table 4 Accent 1\"/> <w:xxx Locked=\"false\" Priority=\"50\" Name=\"List Table 5 Dark Accent 1\"/>  <w:xxx Locked=\"false\" Priority=\"52\" Name=\"List Table 7 Colorful Accent 1\"/> <w:xxx Locked=\"false\" Priority=\"46\" Name=\"List Table 1 Light Accent 2\"/> <w:xxx Locked=\"false\" Priority=\"47\" Name=\"List Table 2 Accent 2\"/> <w:xxx Locked=\"false\" Priority=\"48\" Name=\"List Table 3 Accent 2\"/> <w:xxx Locked=\"false\" Priority=\"49\" Name=\"List Table 4 Accent 2\"/> <w:xxx Locked=\"false\" Priority=\"50\" Name=\"List Table 5 Dark Accent 2\"/> <w:xxx Locked=\"false\" Priority=\"51\" Name=\"List Table 6 Colorful Accent 2\"/> <w:xxx Locked=\"false\" Priority=\"52\" Name=\"List Table 7 Colorful Accent 2\"/> <w:xxx Locked=\"false\" Priority=\"46\" Name=\"List Table 1 Light Accent 3\"/> <w:xxx Locked=\"false\" Priority=\"47\" Name=\"List Table 2 Accent 3\"/> <w:xxx Locked=\"false\" Priority=\"48\" Name=\"List Table 3 Accent 3\"/> <w:xxx Locked=\"false\" Priority=\"49\" Name=\"List Table 4 Accent 3\" /> <w:xxx Locked=\"false\" Priority=\"50\" Name=\"List Table 5 Dark Accent 3\"/><w:xxx Locked=\"false\" Priority=\"51\" Name=\"List Table 6 Colorful Accent 3\"/></xml>");
    verify(true)
  }

  Void testDeeplyIndentedList()
  {
    verifyRendering(
      """* one
           * two
             * three
               * four""",
      """<ul>
         <li>one
         <ul>
         <li>two
         <ul>
         <li>three
         <ul>
         <li>four</li>
         </ul>
         </li>
         </ul>
         </li>
         </ul>
         </li>
         </ul>\n""")
  }

  Void testTrailingTabs()
  {
    // the tab is not treated as 4 spaces here and so does not result in a hard line
    // break, but is just preserved.
    // this matches what common-java did at the time of writing
    verifyRendering("a\t\nb\n", "<p>a\t\nb</p>\n")
  }

  Void testUnicodePunctuation()
  {
    // TODO:FIXIT - we can't really test this i don't think because of utf-8 issues
  }

  Void testHtmlBlockInterruptingList()
  {
    verifyRendering(
      """- <script>
         - some text
         some other text
         </script>\n""",
      """<ul>
         <li>
         <script>
         </li>
         <li>some text
         some other text
         </script></li>
         </ul>\n""")

    verifyRendering(
      """- <script>
         - some text
         some other text

         </script>\n""",
      """<ul>
         <li>
         <script>
         </li>
         <li>some text
         some other text</li>
         </ul>
         </script>\n""")
  }
}
