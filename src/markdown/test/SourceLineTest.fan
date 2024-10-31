//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   08 Oct 2024  Matthew Giannini  Creation
//

@Js
class SourceLineTest : Test
{
  Void testSubstring()
  {
    line := SourceLine("abcd", SourceSpan(3, 10, 4))

    verifySourceLine(line.substring(0, 4), "abcd", SourceSpan(3, 10, 4))
    verifySourceLine(line.substring(0, 3), "abc", SourceSpan(3, 10, 3))
    verifySourceLine(line.substring(0, 2), "ab", SourceSpan(3, 10, 2))
    verifySourceLine(line.substring(0, 1), "a", SourceSpan(3, 10, 1))

    verifySourceLine(line.substring(1, 4), "bcd", SourceSpan(3, 11, 3))
    verifySourceLine(line.substring(1, 3), "bc", SourceSpan(3, 11, 2))

    verifySourceLine(line.substring(3, 4), "d", SourceSpan(3, 13, 1))
    verifySourceLine(line.substring(4, 4), "", null)

    verifyErr(IndexErr#) {
      SourceLine("abcd", SourceSpan(3,10,4)).substring(3, 2)
    }

    verifyErr(IndexErr#) {
      SourceLine("abcd", SourceSpan(3,10,4)).substring(0, 5)
    }
  }

  private Void verifySourceLine(SourceLine line, Str expectedContent,  SourceSpan? expectedSourceSpan)
  {
    verifyEq(expectedContent, line.content)
    verifyEq(expectedSourceSpan, line.sourceSpan)
  }
}