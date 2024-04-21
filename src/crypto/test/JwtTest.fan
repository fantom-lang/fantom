//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 March 2024 Ross Schwalm Creation
//

@NoDoc
class JwtTest : CryptoTest
{

  Void testJwtConstruction()
  {
    expiration := DateTime.nowUtc + 15min
    audience := "https://service.fantom.dev"

    jwt := Jwt {
              it.header = ["customMeta": "Hello"]
              it.alg = "HS256"
              it.claims = ["testClaim": "123", "iss": "https://accounts.fantom.dev", "sub": "user@fantom.dev", "aud": audience]
              it.exp = expiration
           }

    verifyEq(jwt.iss, "https://accounts.fantom.dev")
    verifyEq(jwt.sub, "user@fantom.dev")
    verifyEq(jwt.exp, expiration)
    verifyEq(jwt.claims["exp"], expiration)
    verifyEq(jwt.aud, [audience])
    verifyEq(jwt.claims["aud"], [audience])
    verifyEq(jwt.header["alg"], "HS256")
    verifyEq(jwt.header["customMeta"], "Hello")

    jwt = Jwt {
            it.alg = "HS256"
            it.claims = ["testClaim": "123", "iss": "https://accounts.fantom.dev", "sub": "user@fantom.dev", "exp": DateTime.nowUtc, "aud": audience]
            it.exp = expiration
         }

    verifyEq(jwt.exp, expiration)
    verifyEq(jwt.claims["exp"], expiration)
    verifyEq(jwt.aud, [audience])
    verifyEq(jwt.claims["aud"], [audience])

    jwt = Jwt {
            it.alg = "HS256"
            it.claims = ["testClaim": "123", "iss": "https://accounts.fantom.dev", "sub": "user@fantom.dev", "aud": [audience]]
         }

    verifyEq(jwt.aud, [audience])
    verifyEq(jwt.claims["aud"], [audience])
    verifyEq(jwt.header["alg"], "HS256")

    jwt = Jwt {
            it.alg = "ES256"
            it.claims = ["testClaim": "123", "iss": "https://accounts.fantom.dev", "sub": "user@fantom.dev"]
            it.aud = audience
         }

    verifyEq(jwt.aud, [audience])
    verifyEq(jwt.claims["aud"], [audience])   
    verifyEq(jwt.header["alg"], "ES256") 

    jwt = Jwt {
            it.alg = "RS256"
            it.claims = ["testClaim": "123", "iss": "https://accounts.fantom.dev", "sub": "user@fantom.dev"]
            it.aud = [audience]
         }

    verifyEq(jwt.aud, [audience])
    verifyEq(jwt.claims["aud"], [audience])
    verifyEq(jwt.header["alg"], "RS256")

    verifyErrMsg(ArgErr#, "JWT (exp) claim must be DateTime")
    {
      err := Jwt {
              it.alg = "RS256"
              it.claims = ["exp": 1234567]
            }
    }

    verifyErrMsg(ArgErr#, "JWT (kid) header parameter must be Str")
    {
      err := Jwt {
              it.header = ["kid": 123456 ]
              it.alg = "RS256"
            }
    }

    verifyErrMsg(Err#, "JWT (alg) header parameter is required")
    {
      err := Jwt {it.claims = ["testClaim": "123"]}
    }

    verifyErrMsg(Err#, "Unknown or Unsupported JWT (alg) parameter: KS256")
    {
      err := Jwt {
                it.alg = "KS256"
                it.claims = ["testClaim": "123"]
             }
    }
  }

  Void testPresignedJwt()
  {
    modulus := 
      "AMiMxo9ex9Iwmlnrb4D3F0u3yVb7GF9iJyBGtas2KdoNcnf5UMAnF3xT8ZEwX-5oH" +
      "hq2Tw-9hkuz5D5IzvqCzMl0UkvEY2-FuZGc-RReroPL8r3czVn2f3AtT1GwubDzM-" +
      "zfnVwjtHXZ5zYYe2wkAleIuhLX3ESH46vYxTFwwiG__f2SzS4UJ5fsh_S1FHB8dtR" +
      "tXqfpmGBRFcHvNQRS1p_UaYwFf4QYkwFRl_POJO9gxDs4tbcDYPT181F7zQn6GKuh" +
      "zEShiow0f-5uhye3giPCibid5PyKxbBo3k3DTS-zeP67TdLLEGAf8ht4WbA_139I1" +
      "Kyr943wXxNx95B81kc="

    Str:Obj key  := [
                      "use": "sig",
                      "kty": "RSA",
                      "kid":"2Si4UIEAMQ",
                      "alg":"RS256",
                      "n":modulus, 
                      "e":"AQAB",
                    ]

    rsaJwk  := crypto.loadJwk(key)

    invalidJwtStr1 := "eyJraWQiOiIyU2k0VUlFQU1RIiwidHlwIjoiSldUIiwiYWxnIjoiUlMyNTYifQ"

  	verifyErrMsg(Err#, "Invalid JWT") { err := Jwt.decode(invalidJwtStr1, rsaJwk.key) }

    invalidJwtStr2 := 
      "eyJraWQiOiIyU2k0VUlFQU1RIiwidHlwIjoiSldUIiwiYWxnIjoiUlMyNTYifQ." +
      "eyJzdWIiOiJ1c2VyQGZhbnRvbS5vcmciLCJuYmYiOjE3MTEwNTQ1ODcsImF6cCI" +
      "6Imh0dHBzOi8vand0LmZhbnRvbS5sb2NhbDo4NDQzIiwiaXNzIjoia"

  	verifyErrMsg(Err#, "Invalid JWT") { err := Jwt.decode(invalidJwtStr2, rsaJwk.key) }

    invalidJwtStr3 := 
      "eyJraWQiOiIyU2k0VUlFQU1RIiwidHlwIjoiSldUIiwiYWxnIjoiUlMyNTYifQ." +
      "eyJzdWIiOiJ1c2VyQGZhbnRvbS5vcmciLCJuYmYiOjE3MTEwNTQ1ODcsImF6cCI" +
      "6Imh0dHBzOi8vand0LmZhbnRvbS5sb2NhbDo4NDQzIiwiaXNzIjoia.dgtre4"

    verifyErrMsg(Err#, "Error parsing JWT parts") { err := Jwt.decode(invalidJwtStr3, rsaJwk.key) }

    invalidJwtStr4 := 
      "eyJraWQiOiIyU2k0VUlFQU1RIiwidHlwIjoiSldUIiwiYWxnIjoiUlMyNTYifQ." +
      "eyJzdWIiOiJ1c2VyQGZhbnRvbS5vcmciLCJuYmYiOjE3MTEwNTQ1ODcsImF6cCI" +
      "6Imh0dHBzOi8vand0LmZhbnRvbS5sb2NhbDo4NDQzIiwiaXNzIjoiaHR0cHM6Ly" +
      "9mYW50b20uYWNjb3VudHMuZGV2IiwiZXhwIjoxNzExMDU4Nzg3LCJpYXQiOjE3M" +
      "TEwNTUxODd9." +
      "E_QILzXzRPnVugaa81iXGMNHPEfUJPN7vPPnGNtcPu8Q2lzcEwgyE8q0gEckZH5" +
      "l5_CZzDcZOYKJuUYCF43I8PmW3R-atjoN0gLhBzpX67QqfRE561IxrSCcbHJVx4" +
      "LHZisffYHUydUDfU4Ohfuls4bbVbPg7dfxjtnB0EiPlMQ2DXHzBDr6oZ8n3hnga" +
      "Fp8wybgRIDtEbgUiv2hf784dhBDizYjadUBeNZ5eP3-CNMWFaDS080CQNqRv6KC" +
      "uDoSuASSkbKC60hCWHHkfSyD8unVv5HN36qQXhW1Ur8zwGfbgKkOl8lqu34zHAR" +
      "nzwLYt0JEOHOvXq8zld5MtyQJaQ"

    verifyErrMsg(Err#, "Invalid JWT signature") { err := Jwt.decode(invalidJwtStr4, rsaJwk.key, 7300day) }

  	jwtStr := 
      "eyJraWQiOiIyU2k0VUlFQU1RIiwidHlwIjoiSldUIiwiYWxnIjoiUlMyNTYifQ." +
      "eyJzdWIiOiJ1c2VyQGZhbnRvbS5vcmciLCJuYmYiOjE3MTEwNTQ1ODcsImF6cCI" +
      "6Imh0dHBzOi8vand0LmZhbnRvbS5sb2NhbDo4NDQzIiwiaXNzIjoiaHR0cHM6Ly" +
      "9mYW50b20uYWNjb3VudHMuZGV2IiwiZXhwIjoxNzExMDU4Nzg3LCJpYXQiOjE3M" +
      "TEwNTUxODd9." +
      "E_QILzXzRPnVugaa81iXGMNHPEfUJPN7vPPnGNtcPu8Q2lzcEwgyE8q0gEckZH5" +
      "l5_CZzDcZOYKJuUYCF43I8PmW3R-atjoN0gLhBzpX67QqfRE561IxrSCcbHJVx4" +
      "LHZisffYHUydUDfU4Ohfuls4bbVbPg7dfxjtnB0EiPlMQ2DXHzBDr6oZ8n3hnga" +
      "Fp8wybgRIDtEbgUiv2hf784dhBDizYjadUBeNZ5eP3-CNMWFaDS080CQNqRv6KC" +
      "uDoSuASSkbKC60hCWHHkfSyD8unVv5HN36qQXhW1Ur8zwGfbgKkOl8lqu34zHAR" +
      "nzwLYt0JEOHOvXq8zld5MtyJJaQ"

  	issuer := "https://fantom.accounts.dev"
  	authorized := "https://jwt.fantom.local:8443"
    wrongIssuer := "https://not.the.issuer.com"

    verifyErrMsg(Err#, "JWT (iss) claim ${issuer} is not equal to expected value: ${wrongIssuer}") 
    { 
      Jwt.decode(jwtStr, rsaJwk.key, 7300day)
         .verifyClaim("iss", wrongIssuer)
    }       

    verifyErrMsg(Err#, "JWT (missing) claim is not present") 
    { 
      Jwt.decode(jwtStr, rsaJwk.key, 7300day)
         .verifyClaim("iss")
         .verifyClaim("missing")
    }

    verifyErrMsg(Err#, "JWT expired")
    {
      err := Jwt.decode(jwtStr, rsaJwk.key)
    }

    jwt :=  Jwt.decode(jwtStr, rsaJwk.key, 7300day) //use really long clock drift because pre-signed JWT is expired
                .verifyClaim("iss", issuer)
                .verifyClaim("azp", authorized) 

    verifyEq(jwt.iss, issuer)
  }

  Void testHmacSignedJwt()
  {
    Str:Obj key :=  [
                      "kty": "oct",
                      "kid": "abcd",
                      "k": "badSecret",
                      "alg": "HS384",
                    ]

    octJwk  := crypto.loadJwk(key)                

    verifyErrMsg(Err#, "JWS (alg) header parameter \"HS256\" is not compatible with Key algorithm \"HmacSHA384\"")
    {
      err := Jwt {
                it.alg = "HS256"
                it.claims = ["sub":"user2@fantom.org", "myClaim":"hello2"]
             }.encode(octJwk.key)
    }

    jwtStr := Jwt {
                it.alg = "HS384"
                it.claims = ["myClaim":"hello2"]
                it.sub = "user2@fantom.org" 
              }.encode(octJwk.key)

    verifyEq(jwtStr, "eyJhbGciOiJIUzM4NCJ9.eyJzdWIiOiJ1c2VyMkBmYW50b20ub3JnIiwibXlDbGFpbSI6ImhlbGxvMiJ9.6ZoRQ1TimaFnKgGyqlFvs6H7x_Etlt2VQDShjfghK-CtnzxN8ZzlNJQZs4g5OlIA")

    jwt := Jwt.decode(jwtStr, octJwk.key)

    verifyEq(jwt.claims["sub"], "user2@fantom.org")
    verifyEq(jwt.sub, "user2@fantom.org")
    verifyEq(jwt.claims["myClaim"], "hello2")

    verifyErrMsg(Err#, "JWT (exp) claim is not present") 
    { 
      jwt.verifyClaim("exp")
    }

    verifyErrMsg(Err#, "JWT (nbf) claim is not present") 
    { 
      jwt.verifyClaim("nbf")
    }
  }

  Void testRsaSignedJwt()
  {
    pair   := crypto.genKeyPair("RSA", 2048)
    pub    := pair.pub
    priv   := pair.priv

    jwtStr := Jwt { 
                it.alg = "RS512"
                it.claims = ["myClaim":"hello"]
                it.sub = "user@fantom.org"
                it.aud = "https://application.fantom.dev"
                it.exp = DateTime.now + 15min
              }.encode(priv)

    jwt := Jwt.decode(jwtStr, pub)

    verifyEq(jwt.claims["sub"], "user@fantom.org")
    verifyEq(jwt.sub, "user@fantom.org")
    verifyEq(jwt.claims["myClaim"], "hello")
    verifyEq(jwt.aud, ["https://application.fantom.dev"])
    verifyEq(jwt.claims["aud"], ["https://application.fantom.dev"])

    pair2  := crypto.genKeyPair("RSA", 2048)
    pub2   := pair2.pub
    priv2  := pair2.priv

    verifyErrMsg(Err#, "Invalid JWT signature")
    {
      err := Jwt.decode(jwtStr, pub2)
    }  

    pair3   := crypto.genKeyPair("EC", 256)
    pub3    := pair3.pub
    priv3   := pair3.priv

    verifyErrMsg(Err#, "JWT (alg) header parameter \"RS512\" is not compatible with Key algorithm \"EC\"")
    {
      err := Jwt.decode(jwtStr, pub3)
    }

    jwtStr = Jwt {
               it.alg = "RS256"
               it.claims = ["myClaim": "ClaimValue", "exp": DateTime.nowUtc - 10min, "iss": "https://fantom.accounts.dev"]
             }.encode(priv2) 

    verifyErrMsg(Err#, "JWT expired")
    {
      err := Jwt.decode(jwtStr, pub2)
    }         
  }

  Void testEcSignedJwt()
  {
    Str:Obj key :=  [
                      "kty": "EC",
                      "use": "sig",
                      "crv": "P-256",
                      "kid": "abcd",
                      "x": "I59TOAdnJ7uPgPOdIxj-BhWSQBXKS3lsRZJwj5eIYAo",
                      "y": "8FJEvVIZDjVBnrBJPRUCwtgS86rHoFl1kBfbjX9rOng",
                      "alg": "ES256",
                    ]

    ecJwk := crypto.loadJwk(key)

    ecPrivPem := "-----BEGIN PRIVATE KEY-----
                  MEECAQAwEwYHKoZIzj0CAQYIKoZIzj0DAQcEJzAlAgEBBCBwYc+D4HMQ5OVHQMw9
                  KsTo/26oJb6dN5QH1GbFcVysUA==
                  -----END PRIVATE KEY-----"

    ecPubPem  := "-----BEGIN PUBLIC KEY-----
                  MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEI59TOAdnJ7uPgPOdIxj+BhWSQBXK
                  S3lsRZJwj5eIYArwUkS9UhkONUGesEk9FQLC2BLzqsegWXWQF9uNf2s6eA==
                  -----END PUBLIC KEY-----"

    myPrivKey := crypto.loadPem(ecPrivPem.in, "EC") as PrivKey
    myPubKey  := crypto.loadPem(ecPubPem.in, "EC") as PubKey

    jwtStr := Jwt {
                it.alg = "ES256"
                it.sub = "user3@fantom.org"
               }.encode(myPrivKey)

    jwt := Jwt.decode(jwtStr, myPubKey)

    verifyEq(jwt.sub, "user3@fantom.org")    

    jwt = Jwt.decode(jwtStr, ecJwk.key) //JWK representation of ecPubPem

    Str:Obj key2 := [
                      "kty": "EC",
                      "use": "sig",
                      "crv": "P-256",
                      "kid": "wxyz",
                      "x": "D201cdGuig-zXWUDYqoBN8k7dEpjT7wnV5Ai4FiqcdE",
                      "y": "cMymKfwJHVj6tF_y7sPYJBEWnULIaOKIpu_x8W5lq5w",
                      "alg": "ES256",
                    ]

    ecJwk2 := crypto.loadJwk(key2)

    verifyErrMsg(Err#, "Invalid JWT signature")
    {
      err := Jwt.decode(jwtStr, ecJwk2.key)
    }

    pair2   := crypto.genKeyPair("EC", 256)
    pub2    := pair2.pub
    priv2   := pair2.priv

    jwtStr =  Jwt {
                it.alg = "ES384"
                it.claims = ["testClaim2":"important"]
                it.sub = "user5@fantom.org"
                it.aud = ["audience1", "audience2", "audience3"]
              }.encode(priv2)

    jwt = Jwt.decode(jwtStr, pub2)
              .verifyClaim("aud", "audience1")
              .verifyClaim("aud", "audience2")

    verifyEq(jwt.sub, "user5@fantom.org")
    verifyEq(jwt.claims["testClaim2"], "important")
    verify(((List)jwt.claims["aud"]).containsAll(["audience1", "audience2", "audience3"]))

    verifyErrMsg(Err#, "JWT (aud) claim [audience1, audience2, audience3] does not contain expected value: audience4")
    {
      Jwt.decode(jwtStr, pub2)
         .verifyClaim("aud", "audience4")
    }

    jwtStr =  Jwt {
                it.alg = "ES512"
                it.claims = ["sub": "user6@fantom.org"]
                it.nbf = DateTime.nowUtc + 5min
              }.encode(priv2)

    verifyErrMsg(Err#, "JWT not valid yet") 
    { 
      err := Jwt.decode(jwtStr, pub2)
    }

    jwtStr =  Jwt { 
                it.alg = "ES256"
                it.claims = ["sub": "user7@fantom.org"]
                it.exp = DateTime.nowUtc - 10min
              }.encode(priv2)

    verifyErrMsg(Err#, "JWT expired") 
    { 
      err := Jwt.decode(jwtStr, pub2)
    }    
  }

  Void testUnsignedJwt()
  {
    myJwtStr := Jwt {
                  it.alg = "none"
                  it.claims = ["sub": "user8@fantom.org"]
                  it.iat = DateTime.nowUtc
                  it.jti = Uuid.make.toStr
                  it.nbf = DateTime.nowUtc - 5min
                  it.exp = DateTime.nowUtc + 10min
                }.encode(null)
    
    myJwt := Jwt.decodeUnsigned(myJwtStr)  

    verifyEq(myJwt.claims["sub"], "user8@fantom.org")
    verifyNotNull(myJwt.claims["jti"])

    Str:Obj key1 := [
                      "use": "sig",
                      "kty": "RSA",
                      "kid":"2Si4UIEAMQ",
                      "alg":"RS256",
                      "n":"AMiMxo9ex9Iwmlnrb4D3F0u3yVb7GF9iJyBGtas2KdoNcnf5UMAnF3xT8ZEwX-5oHhq2Tw-9hkuz5D5IzvqCzMl0UkvEY2-FuZGc-RReroPL8r3czVn2f3AtT1GwubDzM-zfnVwjtHXZ5zYYe2wkAleIuhLX3ESH46vYxTFwwiG__f2SzS4UJ5fsh_S1FHB8dtRtXqfpmGBRFcHvNQRS1p_UaYwFf4QYkwFRl_POJO9gxDs4tbcDYPT181F7zQn6GKuhzEShiow0f-5uhye3giPCibid5PyKxbBo3k3DTS-zeP67TdLLEGAf8ht4WbA_139I1Kyr943wXxNx95B81kc=",
                      "e":"AQAB",
                    ]

    rsaJwk  := crypto.loadJwk(key1)    

    verifyErrMsg(Err#, "JWT (alg) header parameter \"none\" is not compatible with Key algorithm \"RSA\"")
    {
      err := Jwt.decode(myJwtStr, rsaJwk.key)
    }
  }

  // CVE-2022-21449
  Void testPsychicSignatureAttack()
  {
    psychic := "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJhZG1pbiI6InRydWUifQ.MAYCAQACAQA"

    pair   := crypto.genKeyPair("EC", 256)
    pub    := pair.pub
    priv   := pair.priv

    verifyErrMsg(Err#, "Invalid JWT signature")
    {
      err := Jwt.decode(psychic, pub)
    }
  }

}