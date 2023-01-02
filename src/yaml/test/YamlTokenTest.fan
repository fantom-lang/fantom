#! /usr/bin/env fan
//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Jul 2022  Kiera O'Flynn   Creation
//

using util

**
** A test suite for the YamlTokenizer class.
**
class YamlTokenTest : Test
{
  Void testEat()
  {
    // eatChar, eatStr, eatToken

    r := YamlTokenizer("abcd !@#\n \$%^&*test".in)
    verifyEq(r.loc.line, 1)
    verifyEq(r.loc.col, fc - 1)
    r.eatToken("abcd")
    verifyEq(r.loc.col, fc + 3)
    r.eatChar(' ')
    r.eatToken("!@#")
    verifyEq(r.loc.col, fc + 7)
    r.eatToken("")
    verifyEq(r.loc.line, 1)
    verifyEq(r.loc.col, fc + 7)
    r.eatChar('\n')
    verifyEq(r.loc.line, 2)
    verifyEq(r.loc.col, fc - 1)
    r.eatChar(' ')
    verifyEq(r.loc.col, fc)
    r.eatChar('$')
    verifyEq(r.loc.col, fc + 1)
    r.eatStr("%^&*")
    verifyEq(r.loc.col, fc + 5)
    r.eatStr("")
    verifyEq(r.loc.col, fc + 5)
    r.eatStr("test")
    verifyEq(r.loc.col, fc + 9)
    r.eatStr("")
    verifyEq(r.loc.col, fc + 9)
    verifyEq(r.printable()(), null)
    verifyEq(r.loc.line, 2)
    verifyEq(r.loc.col, fc + 9)

    YamlTokenizer("test1".in).eatStr("test")
    YamlTokenizer("test1".in).eatStr("test1")
    verifyErr (FileLocErr#) { YamlTokenizer("test1".in).eatStr("test2") }
    verifyErr (FileLocErr#) { YamlTokenizer("test1".in).eatStr("test100") }
    verifyErr (FileLocErr#) { YamlTokenizer("test1".in).eatStr("t3st1") }

    YamlTokenizer("test2".in).eatChar('t')
    verifyErr (FileLocErr#) { YamlTokenizer("test2".in).eatChar('a') }

    r = YamlTokenizer("test3".in)
    r.eatToken("test3")
    verifyErr (FileLocErr#) { r = YamlTokenizer("test3".in); r.eatToken("test0") }
    verifyErr (FileLocErr#) { r = YamlTokenizer("test3".in); r.eatToken("") }

    // eatUntil, eatLine, eatWs

    r = YamlTokenizer("{test1}}    \t    test2aa :)    test3    \n\n   \n   \n".in)
    verifyEq(r.loc.line, 1)
    verifyEq(r.loc.col, fc - 1)
    verifyEq(r.eatUntil |c| { c == '}' }, "{test1")
    verifyEq(r.loc.col, fc + 5)
    verifyEq(r.eatUntil |c| { c == '}' }, "")
    verifyEq(r.loc.col, fc + 5)
    r.eatChar('}')
    r.eatChar('}')
    verifyEq(r.loc.col, fc + 7)
    r.eatWs
    verifyEq(r.loc.col, fc + 16)
    r.eatStr("test2")
    verifyEq(r.loc.col, fc + 21)
    verifyEq(r.eatLine, "aa :)    test3    ")
    verifyEq(r.loc.col, fc - 1)
    verifyEq(r.eatLine, "")
    verifyEq(r.loc.col, fc - 1)
    r.eatWs
    verifyEq(r.loc.col, fc + 2)
    r.eatChar('\n')
    verifyEq(r.eatLine, "   ")
    verifyEq(r.loc.col, fc - 1)
    verifyEq(r.eatLine, "")
    verifyEq(r.loc.col, fc - 1)
    verifyEq(r.loc.line, 5)
  }

  Void testPeek()
  {
    // peek, peekToken, peekNextNs, peekUntil, peekPast

    r := YamlTokenizer("abcd   \n         a\na\n".in)
    verifyEq(r.loc.line, 1)
    verifyEq(r.loc.col, fc - 1)
    verifyEq(r.peek, 'a')
    verifyEq(r.peekToken, "abcd")
    verifyEq(r.peekUntil |c| { c == 'c' }, "ab")
    verifyEq(r.peekUntil |c| { c == 'a' }, "")
    verifyEq(r.peekPast  |_| { true }, null)
    verifyEq(r.peekPast  |_| { false }, 'a')
    verifyEq(r.loc.col, fc - 1)
    r.eatToken
    verifyEq(r.peekNextNs, '\n')
    verifyEq(r.peekToken, "")
    verifyEq(r.peekUntil |c| { c == 'a' }, "   \n         ")
    verifyEq(r.loc.col, fc + 3)
    r.eatLine
    verifyEq(r.peekNextNs, 'a')
    verifyEq(r.peekPast  |c| { c == ' ' || c == 'a' }, '\n')
    verifyEq(r.loc.col, fc - 1)
    r.eatLine
    verifyEq(r.peekNextNs, 'a')
    verifyEq(r.peekToken, "a")
    verifyEq(r.loc.col, fc - 1)
    r.eatLine
    verifyEq(r.peek, null)
    verifyEq(r.peekToken, "")
    verifyEq(r.loc.line, 4)
    verifyEq(r.loc.col, fc - 1)
  }

  Void testSpecial()
  {
    // eatCommentLine

    r := YamlTokenizer("     # This is a comment!\na     \n".in)
    r.eatCommentLine
    verifyEq(r.loc.col, fc - 1)
    r.eatChar('a')
    r.eatCommentLine
    r.eatCommentLine
    r.eatCommentLine
    verifyEq(r.loc.line, 3)
    verifyEq(r.loc.col, fc - 1)

    verifyErr (FileLocErr#) { YamlTokenizer("   Content here oops\n".in).eatCommentLine }

    // nextKeyStr

    r = YamlTokenizer("     # This is a comment!\n\t    \n  ajd a ds  ds  sd sdsdskhf\naaa".in)
    verifyEq(r.nextKeyStr(-1), "ajd a ds  ds  sd sdsdskhf\naaa")
    verifyEq(r.nextKeyStr(2), "ajd a ds  ds  sd sdsdskhf\naaa")
    verifyEq(r.nextKeyStr(0), "ajd a ds  ds  sd sdsdskhf\naaa")
    verifyEq(r.nextKeyStr(3), "")
    verifyEq(r.loc.line, 1)
    verifyEq(r.loc.col, fc - 1)

    verifyEq(YamlTokenizer(("a" * 1100).in).nextKeyStr(0), "a" * 1026)

    // nextKeyIsJson

    r = YamlTokenizer("!!str} &test-thing ! 'str':valid".in)
    verify(!r.nextKeyIsJson)
    verifyEq(r.loc.col, fc - 1)
    r.eatToken
    verify(r.nextKeyIsJson)
    verifyEq(r.loc.line, 1)
    verifyEq(r.loc.col, fc + 5)

    // peekIndentedNs, peekIndentedToken

    r = YamlTokenizer("     # This is a comment!\n\t    \n  ajd a ds  ds  sd sdsdskhf\naaa".in)
    verifyEq(r.peekIndentedNs(2), 'a')
    verifyEq(r.peekIndentedNs(0), 'a')
    verifyEq(r.peekIndentedNs(3), null)
    verifyEq(r.peekIndentedToken(2), "ajd")
    verifyEq(r.peekIndentedToken(0), "ajd")
    verifyEq(r.peekIndentedToken(3), null)
    verifyEq(r.loc.line, 1)
    verifyEq(r.loc.col, fc - 1)

    r = YamlTokenizer("     # This is a comment!\n\t    \n \tajd".in)
    verifyEq(r.peekIndentedNs(2), null)
    verifyEq(r.peekIndentedToken(2), null)
    verifyEq(r.peekIndentedToken(1), "ajd")

    // nextTokenEndsDoc

    r = YamlTokenizer("# Comment\n    # c2\n   \n\n ... ".in)
    verify(!r.nextTokenEndsDoc)
    verifyEq(r.loc.line, 1)
    verifyEq(r.loc.col, fc - 1)
    r = YamlTokenizer("# Comment\n    # c2\n   \n\n... ".in)
    verify(r.nextTokenEndsDoc)
    verifyEq(r.loc.line, 1)
    verifyEq(r.loc.col, fc - 1)

    verify(YamlTokenizer("...".in).nextTokenEndsDoc)
    verify(YamlTokenizer("---".in).nextTokenEndsDoc)
    verify(YamlTokenizer("\uFFFE---\n".in).nextTokenEndsDoc)
  }

  Int fc := 2
}