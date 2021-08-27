//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   05 Aug 2021 Matthew Giannini Creation
//

@NoDoc abstract class BerTest : Test
{
  protected Buf octets(Int[] bytes)
  {
    buf := Buf()
    bytes.each { buf.write(it) }
    return buf
  }

  protected InStream octIn(Int[] bytes) { octets(bytes).flip.in }
  protected Buf enc(AsnObj obj) { BerWriter.toBuf(obj) }
  protected InStream encIn(AsnObj obj) { BerWriter.toBuf(obj).in }

  Void verifyBufEq(Buf expected, Buf actual)
  {
    if (!bufEq(expected, actual))
    {
      Env.cur.out.printLine("Expected: $expected.toHex")
      Env.cur.out.printLine("  Actual: $actual.toHex")
      verify(false)
    }
    verify(true)
  }

  Bool bufEq(Buf a, Buf b)
  {
    if (a.size != b.size) return false
    for (i := 0; i < a.size; ++i)
    {
      if (a[i] != b[i]) return false
    }
    return true
  }
}