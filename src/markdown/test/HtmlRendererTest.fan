//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Oct 2024  Matthew Giannini  Creation
//

@Js
class HtmlRendererTest : Test
{
  Void testHtmlAllowingShouldNotEscapeInlineHtml()
  {
    r := htmlAllowing.render(parse("paragraph with <span id='foo' class=\"bar\">inline &amp; html</span>"))
    verifyEq("<p>paragraph with <span id='foo' class=\"bar\">inline &amp; html</span></p>\n", r)
  }

  Void testHtmlAllowingShouldNotEscapeBlockHtml()
  {
    r := htmlAllowing.render(parse("<div id='foo' class=\"bar\">block &amp;</div>"))
    verifyEq("<div id='foo' class=\"bar\">block &amp;</div>\n", r)
  }

  Void testHtmlEscapingShouldEscapeInlineHtml()
  {
    r := htmlEscaping.render(parse("paragraph with <span id='foo' class=\"bar\">inline &amp; html</span>"))
    // note that &amp; is not escaped, as it's a normal text node, not part of the inline html
    verifyEq("<p>paragraph with &lt;span id='foo' class=&quot;bar&quot;&gt;inline &amp; html&lt;/span&gt;</p>\n", r)
  }

  Void testHtmlEscapingShouldEscapeHtmlBlocks()
  {
    r := htmlEscaping.render(parse("<div id='foo' class=\"bar\">block &amp;</div>"))
    verifyEq("<p>&lt;div id='foo' class=&quot;bar&quot;&gt;block &amp;amp;&lt;/div&gt;</p>\n", r)
  }

  Void testTextEscaping()
  {
    r := def.render(parse("escaping: & < > \" '"))
    verifyEq("<p>escaping: &amp; &lt; &gt; &quot; '</p>\n", r)
  }

  Void testCharacterReferencesWithoutSemicolonsShouldNotBeParsedShouldBeEscaped()
  {
    input := "[example](&#x6A&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3A&#x61&#x6C&#x65&#x72&#x74&#x28&#x27&#x58&#x53&#x53&#x27&#x29)";
    r := def.render(parse(input));
    verifyEq("<p><a href=\"&amp;#x6A&amp;#x61&amp;#x76&amp;#x61&amp;#x73&amp;#x63&amp;#x72&amp;#x69&amp;#x70&amp;#x74&amp;#x3A&amp;#x61&amp;#x6C&amp;#x65&amp;#x72&amp;#x74&amp;#x28&amp;#x27&amp;#x58&amp;#x53&amp;#x53&amp;#x27&amp;#x29\">example</a></p>\n", r);
  }

  Void testAttributeEscaping()
  {
    p := Paragraph()
    p.appendChild(Link("&colon;"))
    verifyEq("<p><a href=\"&amp;colon;\"></a></p>\n", def.render(p))
  }

  Void testRawUrlsShouldNotFilterDangerousProtocols()
  {
    p := Paragraph()
    p.appendChild(Link("javascript:alert(5);"))
    verifyEq("<p><a href=\"javascript:alert(5);\"></a></p>\n", raw.render(p))
  }

  Void testSanitizedUrlsShouldSetRelNoFollow()
  {
    p := Paragraph()
    p.appendChild(Link("/exampleUrl"))
    verifyEq("<p><a rel=\"nofollow\" href=\"/exampleUrl\"></a></p>\n", sanitize.render(p))

    p = Paragraph()
    p.appendChild(Link("https://google.com"))
    verifyEq("<p><a rel=\"nofollow\" href=\"https://google.com\"></a></p>\n", sanitize.render(p))
  }

  Void testSanitzieUrlsShouldAllowSafeProtocols()
  {
    verifyEq("<p><a rel=\"nofollow\" href=\"http://google.com\"></a></p>\n",
      sanitize.render(Paragraph().appendChild(Link("http://google.com"))))

    verifyEq("<p><a rel=\"nofollow\" href=\"https://google.com\"></a></p>\n",
      sanitize.render(Paragraph().appendChild(Link("https://google.com"))))

    verifyEq("<p><a rel=\"nofollow\" href=\"mailto:foo@bar.example.com\"></a></p>\n",
      sanitize.render(Paragraph().appendChild(Link("mailto:foo@bar.example.com"))))

    image := "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAAFiUAABYlAUlSJPAAAAAQSURBVBhXY/iPBVBf8P9/AG8TY51nJdgkAAAAAElFTkSuQmCC";
    verifyEq("<p><a rel=\"nofollow\" href=\"${image}\"></a></p>\n",
      sanitize.render(Paragraph().appendChild(Link(image))))
  }

  Void testSanitizeUrlsShouldFilterDangerousProtocols()
  {
    verifyEq("<p><a rel=\"nofollow\" href=\"\"></a></p>\n",
      sanitize.render(Paragraph().appendChild(Link("javascript:alert(5)"))))

    verifyEq("<p><a rel=\"nofollow\" href=\"\"></a></p>\n",
      sanitize.render(Paragraph().appendChild(Link("ftp://google.com"))))
  }

  Void testPercentEncodeUrlDisabled()
  {
    verifyEq("<p><a href=\"foo&amp;bar\">a</a></p>\n", def.render(parse("[a](foo&amp;bar)")))
    verifyEq("<p><a href=\"ä\">a</a></p>\n", def().render(parse("[a](ä)")));
    verifyEq("<p><a href=\"foo%20bar\">a</a></p>\n", def.render(parse("[a](foo%20bar)")));
  }

  Void testPercentEncodeUrl()
  {
    // Entities are escaped anyway
    verifyEq("<p><a href=\"foo&amp;bar\">a</a></p>\n", percentEnc.render(parse("[a](foo&amp;bar)")));
    // Existing encoding is preserved
    verifyEq("<p><a href=\"foo%20bar\">a</a></p>\n", percentEnc.render(parse("[a](foo%20bar)")));
    verifyEq("<p><a href=\"foo%61\">a</a></p>\n", percentEnc.render(parse("[a](foo%61)")));
    // Invalid encoding is escaped
    verifyEq("<p><a href=\"foo%25\">a</a></p>\n", percentEnc.render(parse("[a](foo%)")));
    verifyEq("<p><a href=\"foo%25a\">a</a></p>\n", percentEnc.render(parse("[a](foo%a)")));
    verifyEq("<p><a href=\"foo%25a_\">a</a></p>\n", percentEnc.render(parse("[a](foo%a_)")));
    verifyEq("<p><a href=\"foo%25xx\">a</a></p>\n", percentEnc.render(parse("[a](foo%xx)")));
    // Reserved characters are preserved, except for '[' and ']'
    verifyEq("<p><a href=\"!*'();:@&amp;=+\$,/?#%5B%5D\">a</a></p>\n", percentEnc.render(parse("[a](!*'();:@&=+\$,/?#[])")));
    // Unreserved characters are preserved
    verifyEq("<p><a href=\"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~\">a</a></p>\n",
      percentEnc.render(parse("[a](ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~)")));
    // Other characters are percent-encoded (LATIN SMALL LETTER A WITH DIAERESIS)
    verifyEq("<p><a href=\"%C3%A4\">a</a></p>\n",
      percentEnc.render(parse("[a](ä)")));

    // TODO:FIXIT - utf-8 string issues in fantom
    // Other characters are percent-encoded (MUSICAL SYMBOL G CLEF, surrogate pair in UTF-16)
    // verifyEq("<p><a href=\"%F0%9D%84%9E\">a</a></p>\n",
    //   percentEnc.render(parse("[a](\uD834\uDD1E)")));
  }

  // TODO:FIXIT - custom overrides

  Void testOrderedListStartZero()
  {
    verifyEq("<ol start=\"0\">\n<li>Test</li>\n</ol>\n", def.render(parse("0. Test\n")))
  }

  Void testImageAltTextWithSoftLineBreak()
  {
    verifyEq("<p><img src=\"/url\" alt=\"foo\nbar\" /></p>\n",
      def.render(parse("![foo\nbar](/url)\n")))
  }

  Void testAltTextWithHardLineBreak()
  {
    verifyEq("<p><img src=\"/url\" alt=\"foo\nbar\" /></p>\n",
      def.render(parse("![foo  \nbar](/url)\n")));
  }

  Void testImageAltTextWithEntities()
  {
    verifyEq("<p><img src=\"/url\" alt=\"foo \u00E4\" /></p>\n",
      def.render(parse("![foo &auml;](/url)\n")));
  }

  Void testImageAltTextWithInlines()
  {
    verifyEq("<p><img src=\"/url\" alt=\"foo bar link\" /></p>\n",
      def.render(parse("![_foo_ **bar** [link](/url)](/url)\n")))
  }

  Void testImageAltTextWithCode()
  {
    verifyEq("<p><img src=\"/url\" alt=\"foo bar\" /></p>\n",
      def.render(parse("![`foo` bar](/url)\n")))
  }

  Void testCanRenderContentsOfSingleParagraph()
  {
    paras := parse("Here I have a test [link](http://www.google.com)")
    para := paras.firstChild
    doc := Document()
    child := para.firstChild
    while (child != null)
    {
      cur := child
      child = cur.next
      doc.appendChild(cur)
    }
    verifyEq("Here I have a test <a href=\"http://www.google.com\">link</a>", def.render(doc))
  }

  Void testOmitSingleParagraphP()
  {
    r := HtmlRenderer.builder.withOmitSingleParagraphP(true).build
    verifyEq("hi <em>there</em>", r.render(parse("hi *there*")))
  }

  private static HtmlRenderer def() { HtmlRenderer() }
  private static HtmlRenderer htmlAllowing() { HtmlRenderer.builder.withEscapeHtml(false).build }
  private static HtmlRenderer htmlEscaping() { HtmlRenderer.builder.withEscapeHtml(true).build }
  private static HtmlRenderer raw() { HtmlRenderer.builder.withSanitizeUrls(false).build }
  private static HtmlRenderer sanitize() { HtmlRenderer.builder.withSanitizeUrls(true).build }
  private static HtmlRenderer percentEnc() { HtmlRenderer.builder.withPercentEncodeUrls(true).build }

  private static Node parse(Str source) { Parser().parse(source) }
}