//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Apr 2025  Matthew Giannini  Creation
//

@Js
class TextWriterTest : Test
{
  override Void setup()
  {
    this.buf = Buf()
  }

  private Buf? buf
  private Str content() { buf.seek(0).readAllStr }

  Void testWhitespace()
  {
    writer := TextWriter(buf.out)
    writer.write("foo").whitespace.write("bar")
    verifyEq("foo bar", content)
  }

  Void testColon()
  {
    writer := TextWriter(buf.out)
    writer.write("foo").colon.write("bar")
    verifyEq("foo:bar", content)
  }

  Void testLine()
  {
    writer := TextWriter(buf.out)
    writer.write("foo").line.write("bar")
    verifyEq("foo\nbar", content)
  }

  Void testWriteStripped()
  {
    writer := TextWriter(buf.out)
    writer.writeStripped("foo\n bar")
    verifyEq("foo bar", content)
  }

  Void testWrite()
  {
    writer := TextWriter(buf.out)
    writer.writeStripped("foo bar")
    verifyEq("foo bar", content)
  }
}