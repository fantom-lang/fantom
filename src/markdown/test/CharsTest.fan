//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Oct 2024  Matthew Giannini  Creation
//

@Js
class CharsTest : Test
{
  Void testSkipBackwards()
  {
    verifyEq(2, Chars.skipBackwards(' ', "foo"))
    verifyEq(2, Chars.skipBackwards(' ', "foo "))
    verifyEq(2, Chars.skipBackwards(' ', "foo  "))
  }

  Void testSkipSpaceTabBackwards()
  {
    verifyEq(2, Chars.skipSpaceTabBackwards("foo"))
    verifyEq(2, Chars.skipSpaceTabBackwards("foo "))
    verifyEq(2, Chars.skipSpaceTabBackwards("foo\t"))
    verifyEq(2, Chars.skipSpaceTabBackwards("foo \t \t\t  "))
  }

  Void testIsBlank()
  {
    verify(Chars.isBlank(""))
    verify(Chars.isBlank(" "))
    verify(Chars.isBlank("\t"))
    verify(Chars.isBlank(" \t"))
    verifyFalse(Chars.isBlank("a"))
    verifyFalse(Chars.isBlank("\f"))
  }
}