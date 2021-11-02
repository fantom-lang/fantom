//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Aug 2021 Matthew Giannini Creation
//

**
** A message digest algorithm
**
const mixin Digest
{
  ** Get the digest algorithm name
  abstract Str algorithm()

  ** Get the computed digest size in bytes
  abstract Int digestSize()

  ** Complete the digest computation and return the hash.
  ** The digest is reset after this method is called.
  abstract Buf digest()

  ** Update the digest using *all* the bytes in the buf (regardless of current position).
  ** Return this.
  abstract This update(Buf buf)

  ** Update the digest using only the 8-bit characters in given string.
  ** Return this.
  abstract This updateAscii(Str str)

  ** Update the digest with one byte / 8-bit integer.
  ** Return this.
  abstract This updateByte(Int i)

  ** Update the digest with four byte / 32-bit integer.
  ** Return this.
  abstract This updateI4(Int i)

  ** Update the digest with eight byte / 64-bit integer.
  ** Return this.
  abstract This updateI8(Int i)

  ** Reset the digest. Return this.
  abstract This reset()
}