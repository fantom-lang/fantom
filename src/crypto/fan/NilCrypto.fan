//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Aug 2023 Matthew Giannini   Creation
//

**
** Default implementation when no crypto is implemented in the
** current runtime. All operations throw an Err.
**
internal const class NilCrypto : Crypto
{
  override Digest digest(Str algorithm) { throw unsupported }
  override Csr genCsr(KeyPair keys, Str subjectDn, Str:Obj opts := [:]) { throw unsupported }
  override CertSigner certSigner(Csr csr) { throw unsupported }
  override KeyPair genKeyPair(Str algorithm, Int bits) { throw unsupported }
  override Cert[] loadX509(InStream in) { throw unsupported }
  override Cert[] loadCertsForUri(Uri uri) { throw unsupported }
  override KeyStore loadKeyStore(File? file := null, Str:Obj opts := [:]) { throw unsupported }
  override Obj? loadPem(InStream in, Str algorithm := "") { throw unsupported }
  override Jwk? loadJwk(Str:Obj map) { throw unsupported }
  override Jwk[] loadJwksForUri(Uri uri, Int maxJwKeys := 10) { throw unsupported }

  private Err unsupported()
  {
    UnsupportedErr("No crypto implementation for runtime: $Env.cur.runtime")
  }
}
