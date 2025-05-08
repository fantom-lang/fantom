//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   01 May 2025  Matthew Giannini  Creation
//

@Js
class SourceSpanTest : Test
{
  Void testSubSpan()
  {
    span := SourceSpan.of(1, 2, 3, 5)

    verifySame(span.subSpan(0), span)
    verifySame(span.subSpan(0, 5), span)

    verifyEq(SourceSpan.of(1, 3, 4, 4), span.subSpan(1))
    verifyEq(SourceSpan.of(1, 4, 5 ,3), span.subSpan(2))
    verifyEq(SourceSpan.of(1, 5, 6 ,2), span.subSpan(3))
    verifyEq(SourceSpan.of(1, 6, 7 ,1), span.subSpan(4))
    // Not sure if empty spans are useful, but it probably makes sense to mirror
    // how substrings work
    verifyEq(SourceSpan.of(1, 7, 8 ,0), span.subSpan(5))

    verifyEq(SourceSpan.of(1, 2, 3, 5), span.subSpan(0, 5))
    verifyEq(SourceSpan.of(1, 2, 3, 4), span.subSpan(0, 4))
    verifyEq(SourceSpan.of(1, 2, 3, 3), span.subSpan(0, 3))
    verifyEq(SourceSpan.of(1, 2, 3, 2), span.subSpan(0, 2))
    verifyEq(SourceSpan.of(1, 2, 3, 1), span.subSpan(0, 1))
    verifyEq(SourceSpan.of(1, 2, 3, 0), span.subSpan(0, 0))

    verifyEq(SourceSpan.of(1, 3, 4, 3), span.subSpan(1, 4))
    verifyEq(SourceSpan.of(1, 4, 5, 1), span.subSpan(2, 3))
  }

  Void testSubSpanBeginIndexNegative()
  {
    verifyErr(ArgErr#) { SourceSpan.of(1, 2, 3, 5).subSpan(-1) }
  }

  Void testSubSpanBeginIndexBounds()
  {
    verifyErr(IndexErr#) { SourceSpan.of(1, 2, 3, 5).subSpan(6) }
  }

  Void testSubSpanEndIndexNegative()
  {
    verifyErr(ArgErr#) { SourceSpan.of(1, 2, 3, 5).subSpan(0, -1) }
  }

  Void testSubSpanEndIndexBounds()
  {
    verifyErr(IndexErr#) { SourceSpan.of(1, 2, 3, 5).subSpan(0, 6) }
  }

  Void testSubSpanBeginIndexGreaterThanEndIndex()
  {
    verifyErr(IndexErr#) { SourceSpan.of(1, 2, 3, 5).subSpan(2, 1) }
  }
}
