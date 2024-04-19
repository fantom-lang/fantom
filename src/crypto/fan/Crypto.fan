//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   05 Aug 2021 Matthew Giannini   Creation
//

**
** Crypto defines a pluggable mixin for cryptography capabilities in Fantom.
** Use `cur` to access the current Crypto instance.
**
const mixin Crypto
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  ** Get the installed crypto implementation for this runtime.
  static const Crypto cur
  static
  {
    try
    {
      cur = Env.cur.runtime == "java"
       ? Type.find("cryptoJava::JCrypto").make
       : NilCrypto()
    }
    catch (Err err)
    {
      err.trace
      throw err
    }
  }

//////////////////////////////////////////////////////////////////////////
// Crypto
//////////////////////////////////////////////////////////////////////////

  ** Get a `Digest` for the given algorithm.
  **
  **   buf := Crypto.cur.digest("SHA-256").update("foo".toBuf).digest
  **
  abstract Digest digest(Str algorithm)

  ** Generate a Certificate Signing Request (CSR). The 'subjectDn' must
  ** be a valid 'X.500' distinguised name as defined in
  ** [RFC4514]`https://tools.ietf.org/html/rfc4514`.
  **
  ** By default, the implementation should choose a "strong" signing algorithm
  ** for signing the CSR. All implementations must support the 'algorithm' option
  ** with one of the following values:
  **  - 'sha256WithRSAEncryption'
  **  - 'sha512WithRSAEncryption'
  **
  **   // Generate a csr signed with the default algorithm
  **   csr := Crypto.cur.genCsr(pair, "cn=test")
  **
  **   // Generate a csr signed with SHA-512
  **   csr := Crypto.cru.genCsr(pair, "cn=test", ["algorithm": "sha512WithRSAEncryption"])
  **
  abstract Csr genCsr(KeyPair keys, Str subjectDn, Str:Obj opts := [:])

  ** Obtain a [builder]`CertSigner` that can be used to configure signing
  ** options for generating a signed certificate from a [CSR]`Csr`.
  **
  **   cert := Crypto.cur.certSigner(csr)
  **     .ca(caKeys, "cn=example,ou=example.org,o=Example Inc,c=US")
  **     .notAfter(Date.today + 365day)
  **     .sign
  **
  abstract CertSigner certSigner(Csr csr)

  ** Generate an asymmetric key pair with the given algorithm
  ** and key size (in bits). Throws Err if the algorithm or key size
  ** is not supported.
  **
  **    pair := Crypto.cur.genKeyPair("RSA", 2048)
  **
  abstract KeyPair genKeyPair(Str algorithm, Int bits)


  ** Load all X.509 certificates from the given input stream.
  **
  ** The stream will be closed after reading the certificates.
  **
  **   cert := Crypto.cur.loadX509(`server.cert`).first
  **
  abstract Cert[] loadX509(InStream in)

  ** Attempt to load the full certificate chain for the given uri. If the certificate
  ** chain cannot be obtained, throw an `sys::Err`.
  **
  ** This is an optional operation and implementations may throw `sys::UnsupportedErr`.
  **
  **   certs := Crypto.cur.loadCertForUri(`https://my.server.com/`)
  virtual Cert[] loadCertsForUri(Uri uri) { throw UnsupportedErr() }

  ** Load a `KeyStore` from the given file. If 'file' is null, then a
  ** new, empty keystore in the PKCS12 format will be returned. The keystore
  ** format is determined by the file extension:
  **  - '.p12', '.pfx': PKCS12 format
  **  - '.jks': Java KeyStore (JAVA only)
  **
  ** If the file does not have an extension, then PKCS12 format will be assumed.
  ** Other formats may be supported depending on the runtime implementation. Throws
  ** an Err if the format is not supported or there is a problem loading the keystore.
  **
  ** The following options may be supported by the implementation:
  **  - 'password': (Str) - the password used to unlock the keystore
  **  or perform integrity checks.
  **
  **   ks := Crypto.cur.loadKeyStore(`keystore.p12`, ["password":"changeit"])
  **
  abstract KeyStore loadKeyStore(File? file := null, Str:Obj opts := [:])

  ** Load the next PEM-encoded object from the input stream. Returns one of the
  ** following depending on the PEM encoding:
  **  - `PrivKey`
  **  - `Cert`
  **  - `Csr`
  **
  ** For PKCS#8, the 'algorithm' argument will be used for decoding. This
  ** argument is ignored for PKCS#1 where the alogithm is inferred.
  **
  ** Returns 'null' if there are no more PEM objects to decode. The input
  ** stream will be closed in this case.
  **
  **   key  := Crypto.cur.loadPem(`server.key`) as PrivKey
  **   cert := Crypto.cur.loadPem(`server.pem`) as Cert
  **
  abstract Obj? loadPem(InStream in, Str algorithm := "RSA")

  ** Load a JSON Web Key (JWK[`Jwk`]) from a Map. 
  **
  ** Throws an error if unable to determine the JWK type.
  **
  **   jwkRsa  := Crypto.cur.loadJwk(["kty":"RSA", "alg":"RS256", ...])
  **   jwkEc   := Crypto.cur.loadJwk(["kty":"EC", "alg":"ES256", ...])
  **   jwkHmac := Crypto.cur.loadJwk(["kty":"oct", "alg":"HS256", ...])
  **
  abstract Jwk? loadJwk(Str:Obj map)

  **
  ** Import JSON Web Key Set from a Uri
  **
  ** jwks := Crypto.cur.loadJwksForUri(`https://example.com/jwks.json`)
  **
  abstract Jwk[] loadJwksForUri(Uri uri, Int maxKeys := 10)
}