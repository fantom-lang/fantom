//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   05 Aug 2021 Matthew Giannini   Creation
//

using crypto

const class JCrypto : Crypto
{
  override JDigest digest(Str algorithm)
  {
    JDigest(algorithm)
  }

  override JCsr genCsr(KeyPair keys, Str subjectDn, Str:Obj opts := [:])
  {
    JCsr(keys, subjectDn, opts)
  }

  override CertSigner certSigner(Csr csr)
  {
    JCertSigner(csr)
  }

  override JKeyPair genKeyPair(Str algorithm, Int bits)
  {
    JKeyPair.genKeyPair(algorithm, bits)
  }

  override X509[] loadX509(InStream in)
  {
    X509.load(in)
  }

  override X509[] loadCertsForUri(Uri uri)
  {
    X509.loadCertsForUri(uri)
  }

  override JKeyStore loadKeyStore(File? file := null, Str:Obj opts := [:])
  {
    JKeyStore.load(file, opts)
  }

  override Obj? readPem(InStream in)
  {
    PemReader(in).read
  }
}