//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 May 08  Brian Frank  Creation
//

**
** MimeUtilTest
**
class MimeUtilTest : Test
{

//////////////////////////////////////////////////////////////////////////
// EncodedWord
//////////////////////////////////////////////////////////////////////////

  Void testEncodedWord()
  {
    verifySame(MimeUtil.toEncodedWord("hi!"), "hi!")
    verifyEq(MimeUtil.toEncodedWord("\u00ff!"), "=?UTF-8?B?w78h?=")
  }

}