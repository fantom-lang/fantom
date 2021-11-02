//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Aug 2021 Matthew Giannini   Creation
//

using crypto

native const class JDigest : Digest
{
  new make(Str algorithm)

  override Str algorithm()

  override Int digestSize()

  override Buf digest()

  override This update(Buf buf)

  override This updateAscii(Str str)

  override This updateByte(Int i)

  override This updateI4(Int i)

  override This updateI8(Int i)

  override This reset()
}