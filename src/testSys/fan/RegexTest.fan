//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Dec 07  Brian Frank  Creation
//

**
** RegexTest
**
class RegexTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  Void testIdentity()
  {
    re := Regex.fromStr(";")
    verifyEq(re, Regex.fromStr(";"))
    verifyNotEq(re, ";")
    verifyEq(re.toStr, ";")
    verifyEq(re.hash, ";".hash)
    verifyEq(re.type, Regex#)
  }

//////////////////////////////////////////////////////////////////////////
// Split
//////////////////////////////////////////////////////////////////////////

  Void testSplit()
  {
    // tests from javadoc
    s := "boo:and:foo"
    re := Regex.fromStr(":")
    verifyEq(re.split(s), ["boo", "and", "foo"])
    verifyEq(re.split(s, 0), ["boo", "and", "foo"])
    verifyEq(re.split(s, 1),  ["boo:and:foo"])
    verifyEq(re.split(s, 2),  ["boo", "and:foo"])
    verifyEq(re.split(s, 5),  ["boo", "and", "foo"])
    verifyEq(re.split(s, -2), ["boo", "and", "foo"])
    re = Regex.fromStr("o")
    verifyEq(re.split(s),       ["b", "", ":and:f",])
    verifyEq(re.split(s, 0),    ["b", "", ":and:f"])
    verifyEq(re.split(s, 5),    ["b", "", ":and:f", "", ""])
    verifyEq(re.split(s, -2),   ["b", "", ":and:f", "", ""])

    // spaces
    re = Regex.fromStr(r"\W+")
    s = "This is a test."
    verifyEq(re.split(s), ["This", "is", "a", "test"])
    verifyEq(re.split(s, 3), ["This", "is", "a test."])
  }

//////////////////////////////////////////////////////////////////////////
// Matches
//////////////////////////////////////////////////////////////////////////

  Void testMatches()
  {
    re := Regex.fromStr("[a-z]+")
    verifyMatches(re, "", false)
    verifyMatches(re, "q", true)
    verifyMatches(re, "aqz", true)
    verifyMatches(re, "Aqz", false)
  }

  Void verifyMatches(Regex re, Str s, Bool expected)
  {
    verifyEq(re.matches(s), expected)

    m := re.matcher(s)
    verifyEq(m.matches, expected)
    if (expected)
    {
      verifyEq(m.group, s)
      verifyEq(m.start, 0)
      verifyEq(m.end,  s.size)
      verifyEq(m.groupCount, 0)

      verifyErr(IndexErr#) |,| { m.group(1) }
      verifyErr(IndexErr#) |,| { m.start(1) }
      verifyErr(IndexErr#) |,| { m.end(1) }
    }
    else
    {
      verifyEq(m.groupCount, 0)
      verifyErr(Err#) |,| { m.group }
      verifyErr(Err#) |,| { m.start }
      verifyErr(Err#) |,| { m.end }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Groups
//////////////////////////////////////////////////////////////////////////

  Void testGroups()
  {
    // single find
    m := Regex.fromStr("(a(b)c)d").matcher("abcd")
    verifyGroups(m, [ ["abcd", 0, 4], ["abc",  0, 3], ["b",    1, 2] ])
    verify(!m.find)

    // double find
    m = Regex.fromStr("(a(b)c)d").matcher("abcdabcd")
    verifyGroups(m, [ ["abcd", 0, 4], ["abc",  0, 3], ["b",    1, 2] ])
    verifyGroups(m, [ ["abcd", 4, 8], ["abc",  4, 7], ["b",    5, 6] ])
    verify(!m.find)
  }

  Void verifyGroups(RegexMatcher m, Obj[][] expected)
  {
    verify(m.find)
    verifyEq(m.groupCount, expected.size-1)
    expected.each |Obj[] x, Int i|
    {
      if (i == 0)
      {
        verifyEq(m.group, x[0])
        verifyEq(m.start, x[1])
        verifyEq(m.end,   x[2])
      }

      verifyEq(m.group(i), x[0])
      verifyEq(m.start(i), x[1])
      verifyEq(m.end(i),   x[2])
    }
  }


}
