//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Aug 2021 Matthew Giannini   Creation
//

**
** The CertSigner allows you to configure various options for signing
** a certificate from a [CSR]`Csr` to generate a signed [certifcate]`Cert`.
**
** See [RFC5280]`https://datatracker.ietf.org/doc/html/rfc5280` for more information
** on configuring v3 extension values.
**
mixin CertSigner
{

  ** Configure the CA private key and public certificate.
  ** If this method is not called, then a self-signed certificate
  ** will be generated.
  abstract This ca(PrivKey caPrivKey, Cert caCert)

  ** Configure the start date for the certificate valdity period.
  ** The default value is today.
  abstract This notBefore(Date date)

  ** Configure the end date for the certificate validity period.
  ** The default value is 365 days from today.
  abstract This notAfter(Date date)

  ** Configure the signature algorithm to sign the certificate with. This map
  ** is configured the same as a `Crypto.genCsr`. By default, an implementation
  ** should choose a "strong" signing algorithm.
  abstract This signWith(Str:Obj opts)

  ** Generate the signed certificate based on the current configuration.
  abstract Cert sign()

//////////////////////////////////////////////////////////////////////////
// V3 Extensions
//////////////////////////////////////////////////////////////////////////

  ** Configure the Subject Key Identifier V3 extenstion
  abstract This subjectKeyId(Buf buf)

  ** Configure the Authority Key Identifier V3 extension
  abstract This authKeyId(Buf buf)

  ** Configure the Basic Constraints V3 extension
  abstract This basicConstraints(Bool ca := false, Int? pathLenConstraint := null)

  ** Configure the Key Usage V3 extension
  abstract This keyUsage(Buf bits)

  ** Configure the Extended Key Usage V3 extension.
  abstract This extendedKeyUsage(Str[] oids)

  ** Add a Subject Alternative Name to the certificate. This
  ** method may be called multiple times to add different SANs.
  ** The 'name' may be one of the following types:
  **  - 'Str': a DNS name
  **  - 'Uri': a Uniform Resource Identifier name
  **  - 'IpAddr': an IP address name
  abstract This subjectAltName(Obj name)
}
