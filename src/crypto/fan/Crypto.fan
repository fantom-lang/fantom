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
  ** jwks := Crypto.cur.loadJwk(`https://example.com/jwks.json`)
  **
  abstract Jwk[] loadJwksForUri(Uri uri, Int maxKeys := 10)

  **
  ** Decode a JWT[`Jwt`] from an encoded Str
  **
  ** Provide a Key[`Key`] (PubKey[`PubKey`] or MacKey[`MacKey`]) to verify the signature
  **
  ** If the exp and/or nbf claims exist, those will be verified
  **
  **   jwk :=  [
  **             "kty": "EC",
  **             "use": "sig",
  **             "crv": "P-256",
  **             "kid": "abcd",
  **             "x": "I59TOAdnJ7uPgPOdIxj-BhWSQBXKS3lsRZJwj5eIYAo",
  **             "y": "8FJEvVIZDjVBnrBJPRUCwtgS86rHoFl1kBfbjX9rOng",
  **             "alg": "ES256",
  **           ]
  **
  **   ecJwk := Crypto.cur.loadJwk(jwk)
  **
  **   jwt := Jwt.decode("1111.2222.3333", ecJwk.key)
  **
  **   jwt2 := Crypto.cur.decodeJwt("1111.2222.3333", ecJwk.key)
  **
  @NoDoc
  abstract Jwt decodeJwt(Str encoded, Key key, Duration clockDrift := 60sec)

  ** Digitally sign and return a base64 encoded JWT[`Jwt`]
  ** 
  ** The (alg) parameter must be set in the header parameter to a supported JWS algorithm
  **
  ** The key parameter (PrivKey[`PrivKey`] or MacKey[`MacKey`]) is used to sign and return the base64 encoded JWT
  ** 
  ** The following JWS Algorithms are supported:
  **
  **   -   HS256 - HMAC using SHA-256
  **   -   HS384 - HMAC using SHA-384
  **   -   HS512 - HMAC using SHA-512 
  **   -   RS256 - RSASSA-PKCS1-v1_5 using SHA-256
  **   -   RS384 - RSASSA-PKCS1-v1_5 using SHA-384
  **   -   RS512 - RSASSA-PKCS1-v1_5 using SHA-512
  **   -   ES256 - ECDSA using P-256 and SHA-256
  **   -   ES384 - ECDSA using P-256 and SHA-384
  **   -   ES512 - ECDSA using P-256 and SHA-512
  **   -   none  - No digital signature or MAC performed 
  **
  **   pair   := Crypto.cur.genKeyPair("RSA", 2048)
  **   priv   := pair.priv
  **
  **   jwtStr := Crypto.cur.encodeJwt(["alg": "RS256"], ["myClaim": "ClaimValue", "exp": DateTime.nowUtc + 10min, "iss": "https://fantom.accounts.dev"], priv)
  **
  @NoDoc
  abstract Str encodeJwt(Str:Obj header, Str:Obj claims, Key key)
}