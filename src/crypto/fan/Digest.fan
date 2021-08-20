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

  ** Reset the digest. Return this.
  abstract This reset()
}
