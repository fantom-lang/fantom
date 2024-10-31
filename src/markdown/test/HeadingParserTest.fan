//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Oct 2024  Matthew Giannini  Creation
//

@Js
class HeadingParserTest : CoreRenderingTest
{
  Void testAtxHeadingStart()
  {
    verifyRendering("# test", "<h1>test</h1>\n")
    verifyRendering("###### test", "<h6>test</h6>\n")
    verifyRendering("####### test", "<p>####### test</p>\n")
    verifyRendering("#test", "<p>#test</p>\n")
    verifyRendering("#", "<h1></h1>\n")
  }

  Void testAtxHeadingTrailing()
  {
    verifyRendering("# test #", "<h1>test</h1>\n")
    verifyRendering("# test ###", "<h1>test</h1>\n")
    verifyRendering("# test # ", "<h1>test</h1>\n")
    verifyRendering("# test ### ", "<h1>test</h1>\n")
    verifyRendering("# test # #", "<h1>test #</h1>\n")
    verifyRendering("# test#", "<h1>test#</h1>\n")
  }

  Void testSetextHeadingMarkers()
  {
    verifyRendering("test\n=", "<h1>test</h1>\n")
    verifyRendering("test\n-", "<h2>test</h2>\n")
    verifyRendering("test\n====", "<h1>test</h1>\n")
    verifyRendering("test\n----", "<h2>test</h2>\n")
    verifyRendering("test\n====   ", "<h1>test</h1>\n")
    verifyRendering("test\n====   =", "<p>test\n====   =</p>\n")
    verifyRendering("test\n=-=", "<p>test\n=-=</p>\n")
    verifyRendering("test\n=a", "<p>test\n=a</p>\n")
  }
}