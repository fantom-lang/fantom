//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Aug 2021 Matthew Giannini   Creation
//

using crypto

**
** X.509 Certificate.
**
native const class X509 : Cert
{
  static X509[] load(InStream in)

  static X509[] loadCertsForUri(Uri uri)

  override Str subject()

  override Str issuer()

  override Str certType()

  override Buf encoded()

  override PubKey pub()

  override Str toStr()

  Buf serialNum()

  Date notBefore()

  Date notAfter()
}