//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Aug 2021 Matthew Giannini Creation
//

**
** Cert defines the api for an identity certificate. An identity
** certificate binds a subject to a public key. The certificate
** is signed by an issuer.
**
const mixin Cert
{
  ** Get the subject DN from the certificate.
  abstract Str subject()

  ** Get the issuer DN from the certificate.
  abstract Str issuer()

  ** Get the type of certificate (e.g. 'X.509')
  abstract Str certType()

  ** Get the encoded form of the certificate.
  abstract Buf encoded()

  ** Get the public key from the certificate.
  abstract PubKey pub()

  ** Get the PEM encoding of the certificate
  override abstract Str toStr()
}