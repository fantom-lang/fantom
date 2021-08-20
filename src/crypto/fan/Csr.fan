//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Aug 2021 Matthew Giannini   Creation
//

**
** A Certificate Signing Request (CSR)
**
const mixin Csr
{
  ** Get the public key for the CSR
  abstract PubKey pub()

  ** Get the subject dn
  abstract Str subject()

  ** Get the immutable signing options
  abstract Str:Obj opts()
}