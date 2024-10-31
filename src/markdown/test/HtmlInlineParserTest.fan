//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Oct 2024  Matthew Giannini  Creation
//

@Js
class HtmlInlineParserTest : CoreRenderingTest
{
  Void testComment()
  {
    verifyRendering("inline <!---->", "<p>inline <!----></p>\n")
    verifyRendering("inline <!-- -> -->", "<p>inline <!-- -> --></p>\n")
    verifyRendering("inline <!-- -- -->", "<p>inline <!-- -- --></p>\n")
    verifyRendering("inline <!-- --->", "<p>inline <!-- ---></p>\n")
    verifyRendering("inline <!-- ---->", "<p>inline <!-- ----></p>\n")
    verifyRendering("inline <!-->-->", "<p>inline <!-->--&gt;</p>\n")
    verifyRendering("inline <!--->-->", "<p>inline <!--->--&gt;</p>\n")
  }

  Void testCdata()
  {
    verifyRendering("inline <![CDATA[]]>", "<p>inline <![CDATA[]]></p>\n")
    verifyRendering("inline <![CDATA[ ] ]] ]]>", "<p>inline <![CDATA[ ] ]] ]]></p>\n")
  }

  Void testDeclaration()
  {
    // whitespace is mandatory
    verifyRendering("inline <!FOO>", "<p>inline &lt;!FOO&gt;</p>\n")
    verifyRendering("inline <!FOO >", "<p>inline <!FOO ></p>\n")
    verifyRendering("inline <!FOO 'bar'>", "<p>inline <!FOO 'bar'></p>\n")

    // lowercase
    verifyRendering("inline <!foo bar>", "<p>inline <!foo bar></p>\n")
  }
}