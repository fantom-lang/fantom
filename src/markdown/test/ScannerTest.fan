//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   08 Oct 2024  Matthew Giannini  Creation
//

@Js
class ScannerTest : Test
{
  Void testNext()
  {
    scanner := Scanner([SourceLine("foo bar")], 0, 4)
    verifyEq('b', scanner.peek)
    scanner.next
    verifyEq('a', scanner.peek)
    scanner.next
    verifyEq('r', scanner.peek)
    scanner.next
    verifyEq('\u0000', scanner.peek)
  }

  Void testMultipleLines()
  {
    scanner := Scanner([SourceLine("ab"), SourceLine("cde")], 0, 0)
    verify(scanner.hasNext)
    verifyEq('\u0000', scanner.peekPrevCodePoint)
    verifyEq('a', scanner.peek)
    scanner.next

    verify(scanner.hasNext)
    verifyEq('a', scanner.peekPrevCodePoint)
    verifyEq('b', scanner.peek)
    scanner.next

    verify(scanner.hasNext)
    verifyEq('b', scanner.peekPrevCodePoint)
    verifyEq('\n', scanner.peek)
    scanner.next

    verify(scanner.hasNext)
    verifyEq('\n', scanner.peekPrevCodePoint)
    verifyEq('c', scanner.peek)
    scanner.next

    verify(scanner.hasNext)
    verifyEq('c', scanner.peekPrevCodePoint)
    verifyEq('d', scanner.peek)
    scanner.next

    verify(scanner.hasNext)
    verifyEq('d', scanner.peekPrevCodePoint)
    verifyEq('e', scanner.peek)
    scanner.next

    verifyFalse(scanner.hasNext)
    verifyEq('e', scanner.peekPrevCodePoint)
    verifyEq('\u0000', scanner.peek)
    scanner.next
  }

  Void testCodePoints()
  {
    // TODO: something weird is going on with fantom unicode handling
  }

  Void testTextBetween()
  {
    scanner := Scanner([
      SourceLine("ab", SourceSpan(10, 3, 2)),
      SourceLine("cde", SourceSpan(11, 4, 3))], 0, 0)

    start := scanner.pos

    scanner.next
    verifySourceLines(scanner.source(start, scanner.pos), "a", [SourceSpan(10, 3, 1)])

    afterA := scanner.pos

    scanner.next
    verifySourceLines(scanner.source(start, scanner.pos), "ab", [SourceSpan(10, 3, 2)])

    afterB := scanner.pos

    scanner.next
    verifySourceLines(scanner.source(start, scanner.pos), "ab\n", [SourceSpan(10, 3, 2)])

    scanner.next
    verifySourceLines(scanner.source(start, scanner.pos), "ab\nc",
      [SourceSpan(10, 3, 2), SourceSpan(11, 4, 1)])

    scanner.next
    verifySourceLines(scanner.source(start, scanner.pos), "ab\ncd",
      [SourceSpan(10, 3, 2), SourceSpan(11, 4, 2)])

    scanner.next
    verifySourceLines(scanner.source(start, scanner.pos), "ab\ncde",
      [SourceSpan(10, 3, 2), SourceSpan(11, 4, 3)])

    verifySourceLines(scanner.source(afterA, scanner.pos), "b\ncde",
      [SourceSpan(10, 4, 1), SourceSpan(11, 4, 3)])

    verifySourceLines(scanner.source(afterB, scanner.pos), "\ncde",
      [SourceSpan(11, 4, 3)])
  }

  Void testNextStr()
  {
    scanner := Scanner([SourceLine("hey ya"), SourceLine("hi")])
    verifyFalse(scanner.nextStr("hoy"))
    verify(scanner.nextStr("hey"))
    verify(scanner.nextCh(' '))
    verifyFalse(scanner.nextStr("yo"))
    verify(scanner.nextStr("ya"))
    verifyFalse(scanner.nextStr(" "))
  }

  Void testWhitespace()
  {
    scanner := Scanner([SourceLine("foo \t\u000B\r\n\fbar")])
    verify(scanner.nextStr("foo"))
    verifyEq(6, scanner.whitespace)
    verify(scanner.nextStr("bar"))
  }

  private Void verifySourceLines(SourceLines lines, Str expectedContent, SourceSpan[] expectedSpans)
  {
    verifyEq(expectedContent, lines.content)
    verifyEq(expectedSpans, lines.sourceSpans)
  }
}