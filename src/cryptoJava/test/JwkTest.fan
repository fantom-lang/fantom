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
                  "k": "badSecret",
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

    ecPubPem  := """-----BEGIN PUBLIC KEY-----
                    MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEI59TOAdnJ7uPgPOdIxj+BhWSQBXK
                    S3lsRZJwj5eIYArwUkS9UhkONUGesEk9FQLC2BLzqsegWXWQF9uNf2s6eA==
                    -----END PUBLIC KEY-----"""

    myPubKey  := crypto.loadPem(ecPubPem.in, "EC") as PubKey
    jwk     = JJwk.toJwk(myPubKey, "SHA384", ["kid": "1234"])
    verifyEq(jwk.meta[JwkConst.KeyTypeHeader], "EC")
    verifyEq(jwk.meta[JwkConst.AlgorithmHeader], "ES384")
    verifyEq(jwk.meta[JwkConst.KeyIdHeader], "1234")

    pair2 := crypto.genKeyPair("EC", 256)
    pub2  := pair2.pub

    jwk     = JJwk.toJwk(pub2, "SHA256", ["kid": "efgh"])
    verifyEq(jwk.meta[JwkConst.KeyTypeHeader], "EC")
    verifyEq(jwk.meta[JwkConst.AlgorithmHeader], "ES256")
    verifyEq(jwk.meta[JwkConst.KeyIdHeader], "efgh")

    jwk     = JJwk.toJwk(jwks[3].key, "SHA256", ["kid": "ijkl"])
    verifyEq(jwk.meta[JwkConst.KeyTypeHeader], "oct")
    verifyEq(jwk.meta[JwkConst.AlgorithmHeader], "HS256")
    verifyEq(jwk.meta[JwkConst.KeyIdHeader], "ijkl")
    verifyTrue(jwk.key.encoded.bytesEqual("badSecret".toBuf))    
  }

}