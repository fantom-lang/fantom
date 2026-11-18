//
// Copyright (c) 2024, SkyFoundry
// All Rights Reserved
//
// History:
//  26 Mar 2024   Ross Schwalm  Creation
//

using crypto

class JwkTest : Test
{

  Void testJwk()
  {
    test := [
              "keys": [
                [
                  "alg":"RS256",
                  "e":"AQAB",
                  "kid":"wU99adUipEErJshyqJ6vE+q+aQt0K3g5oyoxy2kKvJo=",
                  "kty":"RSA",
                  "n":"nWxKIyGg_t1KZ56lhfd2i9M_BmiYOMfzUhGSf7sOhlkiTxVQMCSYQiS9SU2o4UMYV2ZykBhuGduPxZsvvcwNsB37ubFpBzoi3MJR0C9YOYGju5PrFhClSKeIJznI6e2_fs7TepJxlF-Wtj4Oa8-mN_Z7ydUg6nToqgRKWsXtAKVj1fX_m0pEamnr0STKF-Z58FrZ8rtul__hBAHsTRxV0tLqNCHIC0zAOPxhZlt7OCbJvhnr68R4GyIi4hyWR6LH--BxY_LebtM67qDdIRBOpkhG6Gmj4HXw6xFroVRzzfYVdJKQHpqXmF-4s93g_ETf5C5nF1B_ZHVaCV9mrv-alw",
                  "use":"sig"
                ],
                [
                  "alg":"RS256",
                  "e":"AQAB",
                  "kid":"hEbJ9Cd2TKaOUMAHj67J1O4bjN6wDxa2l+W1l3Nnh6I=",
                  "kty":"RSA",
                  "n":"sK5zlF0epYoBXE6jb4IuFrMhex88bC7gjjrl8tppIqbuV7hozLRNDFWlHdOYwtB0_Q1T6pvmHvoxYLPxv4aabawXgZ_Ca1K4NV5FBmOFSHjk_SltA6FLGxCAg61hdXMegTSiuANhqO3kYUGc0JnYOdc_6UR6NIfKsNxik5e0m82xsslpsOiqSJSugEswQxa5yEjs0gx6BVuxBVPm7g8jzRg9VL51D8A8eOfluv_cCAmL-4TYV8NlzTQ945_-wDgnJeRhzaEcmyHtSKNEM4bFXjzJPnKmUPFSxuGFy_JjBb_qGnvKWeP4-HV2TkcOpAZoGjgcAGs3lzabJxFbsaOwEw",
                  "use":"sig"
                ],
                [
                  "kty": "EC",
                  "use": "sig",
                  "crv": "P-256",
                  "kid": "abcd",
                  "x": "BBeYJFS8V8j-hnvrLzDXgswQ1WrDyKmWunhucquXr2c",
                  "y": "DLr-IapghPc0cdarUpjbrW0U6ZbnqX7TQJdhRoR-xco",
                  "alg": "ES256"
                ],
                [
                  "kty": "oct",
                  "kid": "jwtId",
                  "k": "YmFkU2VjcmV0",
                  "alg": "HS384",
                ]
              ]
            ]
    
    jwks := JJwk.importJwks(test)

    verifyEq(jwks[0].meta[JwkConst.KeyIdHeader], "wU99adUipEErJshyqJ6vE+q+aQt0K3g5oyoxy2kKvJo=")
    verifyEq(jwks[1].meta[JwkConst.KeyIdHeader], "hEbJ9Cd2TKaOUMAHj67J1O4bjN6wDxa2l+W1l3Nnh6I=")
    verifyEq(jwks[2].meta[JwkConst.KeyIdHeader], "abcd")
    verifyEq(jwks[3].meta[JwkConst.KeyIdHeader], "jwtId")

    crypto := Crypto.cur
    pair   := crypto.genKeyPair("RSA", 2048)
    pub    := pair.pub

    jwk    := JJwk.toJwk(pub, "SHA256", ["customMeta": "Hello"])
    verifyEq(jwk.meta[JwkConst.KeyTypeHeader], "RSA")
    verifyEq(jwk.meta[JwkConst.AlgorithmHeader], "RS256")
    verifyEq(jwk.meta["customMeta"], "Hello")
    verifyEq(jwk.meta["e"], "AQAB")
    verifyJwkParam(jwk, "n", 256)
    verifyNotEq(Buf.fromBase64(jwk.meta["n"]).get(0), 0)

    ecPubPem  := """-----BEGIN PUBLIC KEY-----
                    MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEI59TOAdnJ7uPgPOdIxj+BhWSQBXK
                    S3lsRZJwj5eIYArwUkS9UhkONUGesEk9FQLC2BLzqsegWXWQF9uNf2s6eA==
                    -----END PUBLIC KEY-----"""

    myPubKey  := crypto.loadPem(ecPubPem.in, "EC") as PubKey
    jwk     = JJwk.toJwk(myPubKey, "SHA256", ["kid": "1234"])
    verifyEq(jwk.meta[JwkConst.KeyTypeHeader], "EC")
    verifyEq(jwk.meta[JwkConst.AlgorithmHeader], "ES256")
    verifyEq(jwk.meta[JwkConst.KeyIdHeader], "1234")

    // the curve picks the ES alg, so a P-256 key cannot be ES384
    verifyErrMsg(Err#, "EC curve P-256 requires digest SHA256: SHA384") { x := JJwk.toJwk(myPubKey, "SHA384") }

    pair2 := crypto.genKeyPair("EC", 256)
    pub2  := pair2.pub

    jwk     = JJwk.toJwk(pub2, "SHA256", ["kid": "efgh"])
    verifyEq(jwk.meta[JwkConst.KeyTypeHeader], "EC")
    verifyEq(jwk.meta[JwkConst.AlgorithmHeader], "ES256")
    verifyEq(jwk.meta[JwkConst.KeyIdHeader], "efgh")
    verifyJwkParam(jwk, "x", 32)
    verifyJwkParam(jwk, "y", 32)

    // coordinates are always full field size, even with leading zeros
    [256: [32, "SHA256", "ES256"], 384: [48, "SHA384", "ES384"], 521: [66, "SHA512", "ES512"]].each |v, bits|
    {
      Int len := v[0]
      20.times
      {
        jwk = JJwk.toJwk(crypto.genKeyPair("EC", bits).pub, v[1])
        verifyEq(jwk.meta["alg"], v[2])
        verifyEq(jwk.meta["crv"], "P-${bits}")
        verifyJwkParam(jwk, "x", len)
        verifyJwkParam(jwk, "y", len)
      }
    }

    jwk     = JJwk.toJwk(jwks[3].key, "SHA256", ["kid": "ijkl"])
    verifyEq(jwk.meta[JwkConst.KeyTypeHeader], "oct")
    verifyEq(jwk.meta[JwkConst.AlgorithmHeader], "HS256")
    verifyEq(jwk.meta[JwkConst.KeyIdHeader], "ijkl")
    verifyTrue(jwk.key.encoded.bytesEqual("badSecret".toBuf))
    verifyEq(jwk.meta["k"], "YmFkU2VjcmV0")

    // binary key round trips as unpadded base64url
    secret := Buf.fromHex("fbff00fe")
    jwk = JJwk.toJwk(JMacKey.load(secret, "HmacSHA256"), "SHA256")
    verifyEq(jwk.meta["k"], "-_8A_g")
    verifyTrue(jwk.key.encoded.bytesEqual(secret))
  }

  Void testJwksSkipsUnsupported()
  {
    crypto := Crypto.cur
    pair   := crypto.genKeyPair("RSA", 2048)
    rsa    := JJwk.toJwk(pair.pub, "SHA256").meta.dup
    rsa.remove("alg")
    rsa["kid"] = "noAlg"

    jwks := JJwk.importJwks(["keys": [
      "notAMap",
      ["kty":"OKP", "crv":"Ed25519", "alg":"EdDSA", "kid":"okp", "x":"11qYAYKxCrfVS_7TyWQHOg7hcvPapiMlrwIaaPcHURo"],
      rsa.dup.set("alg", "RSA-OAEP").set("use", "enc").set("kid", "enc"),
      rsa.dup.set("alg", "ES256").set("kid", "mismatch"),
      ["kty":"oct", "kid":"octNoAlg", "k":"YmFkU2VjcmV0"],
      rsa,
    ]])
    verifyEq(jwks.map { it.meta["kid"] }, Obj?["noAlg"])

    // JWK without alg verifies a JWT whose alg matches the key type
    tok := Jwt { it.alg = "RS256"; it.kid = "noAlg"; it.claims = ["a":1] }.encode(pair.priv)
    verifyEq(Jwt.decode(tok, jwks).claims["a"], 1)

    // but not one whose alg is for another key type
    hk  := JMacKey.load(pair.pub.encoded, "HmacSHA256")
    tok  = Jwt { it.alg = "HS256"; it.kid = "noAlg"; it.claims = ["a":1] }.encode(hk)
    verifyErrMsg(Err#, "JWT (alg) header parameter \"HS256\" is not compatible with Key algorithm \"RSA\"") { x := Jwt.decode(tok, jwks) }

    // single key loads still report the problem
    verifyErrMsg(Err#, "JWK Algorithm (alg) does not match key type: RSA") { x := crypto.loadJwk(rsa.dup.set("alg", "ES256")) }
    verifyErrMsg(Err#, "JWK missing Algorithm (alg) Parameter") { x := crypto.loadJwk(["kty":"oct", "k":"YmFkU2VjcmV0"]) }
  }

  Void testEcAlgBoundToCurve()
  {
    crypto := Crypto.cur
    ec     := JJwk.toJwk(crypto.genKeyPair("EC", 256).pub, "SHA256", ["kid":"p256"]).meta
    jwks   := JJwk.importJwks(["keys": [
      ec,
      ec.dup.set("alg", "ES384").set("kid", "es384"),
      ec.dup.set("alg", "ES512").set("kid", "es512"),
    ]])
    verifyEq(jwks.map { it.meta["kid"] }, Obj?["p256"])

    verifyErrMsg(Err#, "JWK Algorithm (alg) ES384 requires curve P-384") { x := crypto.loadJwk(ec.dup.set("alg", "ES384")) }

    // without alg the key loads and Jwt.decode binds the curve
    noAlg := ec.dup
    noAlg.remove("alg")
    verifyEq(crypto.loadJwk(noAlg).key.algorithm, "EC")
  }

  Void testJwkToStrRedactsSecret()
  {
    secret := Buf.fromHex("fbff00fe")
    jwk := JJwk.toJwk(JMacKey.load(secret, "HmacSHA256"), "SHA256")
    verifyEq(jwk.meta["k"], "-_8A_g")
    verifyFalse(jwk.toStr.contains("-_8A_g"))
    verify(jwk.toStr.contains("<redacted>"))

    // public keys print in full
    rsa := JJwk.toJwk(Crypto.cur.genKeyPair("RSA", 2048).pub, "SHA256")
    verify(rsa.toStr.contains(rsa.meta["n"]))
  }

  Void testJwksUseAndMax()
  {
    sig := |Str kid->Str:Obj| { JJwk.toJwk(Crypto.cur.genKeyPair("EC", 256).pub, "SHA256", ["kid":kid]).meta }
    enc := sig("enc1").dup.set("use", "enc")
    jwks := ["keys": [sig("a"), sig("b").dup.set("use", "sig"), enc, enc.dup.set("kid", "enc2"), sig("c")]]

    // enc keys are skipped and do not count toward the max
    verifyEq(JJwk.importJwks(jwks, 3).map { it.meta["kid"] }, Obj?["a", "b", "c"])
    verifyEq(JJwk.importJwks(jwks, null).size, 3)
    verifyErrMsg(Err#, "JWKS has 3 signature keys, max is 2") { x := JJwk.importJwks(jwks, 2) }
  }

  Void testJwksUriRequiresHttps()
  {
    verifyErrMsg(ArgErr#, "JWKS uri must be https: http://example.com/jwks.json") { x := JJwk.importJwksUri(`http://example.com/jwks.json`) }
    verifyErrMsg(ArgErr#, "JWKS uri must be https: file:/jwks.json") { x := Crypto.cur.loadJwksForUri(`file:/jwks.json`) }
  }

  ** Verify param is unpadded base64url of exactly size bytes
  private Void verifyJwkParam(Jwk jwk, Str name, Int size)
  {
    Str val := jwk.meta[name]
    verifyFalse(val.containsChar('='))
    verifyFalse(val.containsChar('+'))
    verifyFalse(val.containsChar('/'))
    verifyEq(Buf.fromBase64(val).size, size)
  }

}