//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   01 May 2025  Matthew Giannini  Creation
//

@Js
class LineReaderTest : Test
{
  Void testReadLine()
  {
    sz := LineReader.buf_size
    verifyLines(Str?[,])
    verifyLines(Str?["","\n"])
    verifyLines(Str?["foo", "\n", "bar", "\n"])
    verifyLines(Str?["foo", "\n", "bar", null])
    verifyLines(Str?["", "\n", "", "\n"])
    verifyLines(Str?["a".mult(sz-1), "\n"])
    verifyLines(Str?["a".mult(sz), "\n"])
    verifyLines(Str?["a".mult(sz) + "b", "\n"])

    verifyLines(Str?["", "\r\n"])
    verifyLines(Str?["foo", "\r\n", "bar", "\r\n"])
    verifyLines(Str?["foo", "\r\n", "bar", null])
    verifyLines(Str?["", "\r\n", "", "\r\n"])
    verifyLines(Str?["a".mult(sz-1), "\r\n"])
    verifyLines(Str?["a".mult(sz), "\r\n"])
    verifyLines(Str?["a".mult(sz) + "b", "\r\n"])

    verifyLines(Str?["", "\r"])
    verifyLines(Str?["foo", "\r", "bar", "\r"])
    verifyLines(Str?["foo", "\r", "bar", null])
    verifyLines(Str?["", "\r", "", "\r"])
    verifyLines(Str?["a".mult(sz-1), "\r"])
    verifyLines(Str?["a".mult(sz), "\r"])
    verifyLines(Str?["a".mult(sz) + "b", "\r"])

    verifyLines(Str?["", "\n", "", "\r", "", "\r\n", "", "\n"])
    verifyLines(Str?["what", "\r", "are", "\r", "", "\r", "you", "\r\n", "", "\r\n", "even", "\n", "doing", null])
  }

  private Void verifyLines(Str?[] parts)
  {
    input := parts.findNotNull.join("")
    lineReader := LineReader(input.in)
    try
    {
      Str? line := null
      lines := Str?[,]
      while ((line = lineReader.readLine) != null)
      {
        lines.add(line)
        lines.add(lineReader.lineTerminator)
      }
      verifyNull(lineReader.lineTerminator)
      verifyEq(parts, lines)
    }
    finally lineReader.close
  }
}