//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Mar 2024  Ross Schwalm  Creation
//

**
** Models a JSON Web Token (JWT) as specified by [RFC7519](https://datatracker.ietf.org/doc/html/rfc7519)
**
** A JWT includes three sections:
**
** 1. Javascript Object Signing and Encryption (JOSE) Header
** 2. Claims
** 3. Signature
**
** 11111111111.22222222222.33333333333
**
** These sections are encoded as base64url strings and are separated by dot (.) characters.
**
** The (alg) parameter must be set to a supported JWS algorithm.
**
** The following JWS algorithms are supported:
**
**   - HS256 - HMAC using SHA-256
**   - HS384 - HMAC using SHA-384
**   - HS512 - HMAC using SHA-512
**   - RS256 - RSASSA-PKCS1-v1_5 using SHA-256
**   - RS384 - RSASSA-PKCS1-v1_5 using SHA-384
**   - RS512 - RSASSA-PKCS1-v1_5 using SHA-512
**   - ES256 - ECDSA using P-256 and SHA-256
**   - ES384 - ECDSA using P-384 and SHA-384
**   - ES512 - ECDSA using P-521 and SHA-512
**   - none  - No digital signature or MAC performed
**
const class Jwt
{

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

  ** It-block constructor
  new make(|This| f)
  {
    // call it-block initializer
    f(this)

    //Initialize Header
    if (kid == null) this.kid = checkHeaderMap(JwtConst.KeyIdHeader, Str#)
    //Validate alg Parameter
    jwsAlg := JwsAlgorithm.fromAlg(alg)
    this.alg = jwsAlg.toStr
    this.header = normalizeHeaderMap

    //Initialize Registered Claims
    if (iss == null) this.iss = checkClaimMap(JwtConst.IssuerClaim, Str#)
    if (sub == null) this.sub = checkClaimMap(JwtConst.SubjectClaim, Str#)
    if (jti == null) this.jti = checkClaimMap(JwtConst.JwtIdClaim, Str#)
    if (exp == null) this.exp = checkClaimMap(JwtConst.ExpirationClaim, DateTime#)
    if (nbf == null) this.nbf = checkClaimMap(JwtConst.NotBeforeClaim, DateTime#)
    if (iat == null) this.iat = checkClaimMap(JwtConst.IssuedAtClaim, DateTime#)
    if (aud == null) this.aud = toAudienceClaim(claims[JwtConst.AudienceClaim])
    else this.aud = toAudienceClaim(aud)
    this.claims = normalizeClaimsMap
  }

  private Str:Obj normalizeHeaderMap()
  {
    params := [:].addAll(header)
    if (kid != null) params[JwtConst.KeyIdHeader] = kid
    params[JwtConst.AlgorithmHeader] = alg
    return params
  }

  private Str:Obj normalizeClaimsMap()
  {
    claimsSet := [:].addAll(claims)
    if (iss != null) claimsSet[JwtConst.IssuerClaim] = iss
    if (sub != null) claimsSet[JwtConst.SubjectClaim] = sub
    if (aud != null) claimsSet[JwtConst.AudienceClaim] = toAudienceClaim(aud)
    if (jti != null) claimsSet[JwtConst.JwtIdClaim] = jti
    if (exp != null) claimsSet[JwtConst.ExpirationClaim] = exp
    if (nbf != null) claimsSet[JwtConst.NotBeforeClaim] = nbf
    if (iat != null) claimsSet[JwtConst.IssuedAtClaim] = iat
    return claimsSet
  }

  private Obj? checkHeaderMap(Str parameter, Type type)
  {
    val := header[parameter]
    if (val != null && val.typeof != type)
      throw ArgErr("JWT (${parameter}) header parameter must be ${type.name}")
    return val
  }

  private Obj? checkClaimMap(Str claim, Type type)
  {
    val := claims[claim]
    if (val != null && val.typeof != type)
      throw ArgErr("JWT (${claim}) claim must be ${type.name}")
    return val
  }

//////////////////////////////////////////////////////////////////////////
// Header
//////////////////////////////////////////////////////////////////////////

  ** JOSE Header
  const Str:Obj header := [:]

  ** Key ID header
  **
  ** When encoding this value will take precedent if the kid
  ** parameter is also set in the JOSE header
  const Str? kid

  ** Algorithm header
  const Str alg

//////////////////////////////////////////////////////////////////////////
// Registered Claims
//////////////////////////////////////////////////////////////////////////

  ** JWT Claims
  const Str:Obj claims := [:]

  ** Issuer claim for this token
  const Str? iss

  ** Subject claim for this token
  const Str? sub

  ** Audience claim for this token (Str or Str[])
  **
  ** If value is a Str it will converted to a Str[] of size 1
  const Obj? aud

  ** Expiration claim for this token
  **
  ** When encoded, the value will be converted to `TimeZone.utc`, the epoch const will be subtracted
  ** from this value and it will be converted to seconds
  **
  ** When decoded, the value will be converted to `TimeZone.utc`
  const DateTime? exp

  ** Not before claim for this token
  **
  ** When encoded, the value will be converted to `TimeZone.utc`, the epoch const will be subtracted
  ** from this value and it will be converted to seconds
  **
  ** When decoded, the value will be converted to `TimeZone.utc`
  const DateTime? nbf

  ** Issued at claim for this token
  **
  ** When encoded, the value will be converted to `TimeZone.utc`, the epoch const will be subtracted
  ** from this value and it will be converted to seconds
  **
  ** When decoded, the value will be converted to `TimeZone.utc`
  const DateTime? iat

  ** JWT ID claim for this token
  const Str? jti

  ** UNIX epoch
  private const DateTime epoch := DateTime("1970-01-01T00:00:00Z UTC")

  ** Decode a [Jwt] from an encoded Str
  **
  ** The key parameter supports these types to verify the signature:
  **
  **   - [Key] ([PubKey] or [SymKey])
  **   - [Jwk][] - An error is thrown if the Jwt kid header parameter
  **               is missing or no matching kid is found in the list
  **
  ** If the exp and/or nbf claims exist, those will be verified
  **
  **     jwk :=  [
  **               "kty": "EC",
  **               "use": "sig",
  **               "crv": "P-256",
  **               "kid": "abcd",
  **               "x": "I59TOAdnJ7uPgPOdIxj-BhWSQBXKS3lsRZJwj5eIYAo",
  **               "y": "8FJEvVIZDjVBnrBJPRUCwtgS86rHoFl1kBfbjX9rOng",
  **               "alg": "ES256",
  **             ]
  **
  **     ecJwk := Crypto.cur.loadJwk(jwk)
  **
  **     jwt   := Jwt.decode("1111.2222.3333", ecJwk.key)
  **
  **     jwks := Crypto.cur.loadJwksForUri(`https://example.com/jwks.json`)
  **
  **     jwt2  := Jwt.decodeJwks("4444.5555.6666", jwks)
  **
  static new decode(Str encoded, Obj key, Duration clockDrift := 60sec)
  {
    if (key is List)
    {
      if (!((List)key).all { it is Jwk }) throw ArgErr("The key parameter must contain all Jwk objects")
      return decodeFromJwks(encoded, key, clockDrift)
    }
    if (key is Key) return doDecode(encoded, key, clockDrift)
    throw ArgErr("The key parameter must be a Jwk[] or Key")
  }

  ** Decode an unsigned [Jwt] from an encoded Str
  **
  ** No claims are verified
  **
  **     jwt := Jwt.decode("1111.2222.")
  **
  @NoDoc
  static new decodeUnsigned(Str encoded)
  {
    doDecode(encoded, null)
  }

  private static new decodeFromJwks(Str encoded, Jwk[] jwks, Duration clockDrift := 60sec)
  {
    jwt := decodeUnsigned(encoded)
    kid := jwt.kid
    if (kid == null) throw Err("JWT missing (kid) header parameter: ${jwt.header}")
    matchingJwk := jwks.find |Jwk jwk->Bool| { return jwk.meta[JwtConst.KeyIdHeader] != null &&
                                                      (Str)jwk.meta[JwtConst.KeyIdHeader] == kid }

    if (matchingJwk == null) throw Err("Could not find JWK with matching kid: ${kid}")

    // JWK alg is optional; without it doDecode still requires the JWT alg to match the key type
    jwkAlg := matchingJwk.meta[JwtConst.AlgorithmHeader]
    if (jwkAlg != null && jwkAlg != jwt.alg)
      throw Err("JWT (alg) header parameter ${jwt.alg} != JWK alg ${jwkAlg}")

    return doDecode(encoded, matchingJwk.key, clockDrift)
  }

  private static new doDecode(Str encoded, Key? key, Duration clockDrift := 60sec)
  {
    parts := encoded.split('.')
    if (parts.size != 3) throw Err("Invalid JWT")

    Str:Obj header := [:]
    Str:Obj claims := [:]
    Buf? jwsSigningInput := null
    Buf? signature := null
    Str digestAlgorithm := ""
    JwsAlgorithm jwsAlg := JwsAlgorithm.none

    try
    {
      header = readJson(parts[0])
      if (!header.containsKey(JwtConst.AlgorithmHeader)) throw Err("JWT missing (${JwtConst.AlgorithmHeader}) header parameter")
      jwsAlg = JwsAlgorithm.fromParameters(header)
      digestAlgorithm = jwsAlg.digest
      claims = readJson(parts[1])
      jwsSigningInput = (parts[0] + "." + parts[1]).toBuf
      signature = Buf.fromBase64(parts[2])
    }
    catch (Err e) {throw Err("Error parsing JWT parts", e)}

    //Verify Signature
    if (key != null)
    {
      verifyExp(claims[JwtConst.ExpirationClaim], clockDrift)
      verifyNbf(claims[JwtConst.NotBeforeClaim], clockDrift)

      if (key is PubKey)
      {
        if (jwsAlg.keyType != key.algorithm)
          throw Err("JWT (alg) header parameter \"${jwsAlg.toStr}\" is not compatible with Key algorithm \"${key.algorithm}\"")
        if (jwsAlg.keyType == "EC")
        {
          jwsAlg.checkEcKey(key)
          if (signature.size != jwsAlg.ecSigSize) throw Err("Invalid JWT signature")
          signature = transcodeConcatToDer(signature)
        }
        if (!((PubKey)key).verify(jwsSigningInput, digestAlgorithm, signature))
          throw Err("Invalid JWT signature")
      }
      else if (key is MacKey)
      {
        if(key.algorithm != "Hmac" + jwsAlg.digest)
          throw Err("JWS (alg) header parameter \"${jwsAlg.toStr}\" is not compatible with Key algorithm \"${key.algorithm}\"")
        if(!macEquals(jwsSigningInput.hmac(key.algorithm, key.encoded), signature))
          throw Err("Invalid JWT MAC")
      }
      else
      {
        throw ArgErr("Invalid key provided. Unable to verify signature.")
      }
    }

    return Jwt {
      it.header = header
      it.kid = header[JwtConst.KeyIdHeader]
      it.alg = header[JwtConst.AlgorithmHeader]
      it.claims = claims
      it.iss = claims[JwtConst.IssuerClaim]
      it.sub = claims[JwtConst.SubjectClaim]
      it.aud = toAudienceClaim(claims[JwtConst.AudienceClaim])
      it.exp = fromNumericDate(claims[JwtConst.ExpirationClaim])
      it.nbf = fromNumericDate(claims[JwtConst.NotBeforeClaim])
      it.iat = fromNumericDate(claims[JwtConst.IssuedAtClaim])
      it.jti = claims[JwtConst.JwtIdClaim]
    }
  }

  ** Provide a `[Key] ([PrivKey] or [SymKey])` to sign and return the base64 encoded [Jwt]
  **
  ** Null key will return an unsigned base64 encoded JWT
  **
  ** The alg field must be set to a supported JWS algorithm
  **
  ** The following JWS Algorithms are supported:
  **
  **   - HS256 - HMAC using SHA-256
  **   - HS384 - HMAC using SHA-384
  **   - HS512 - HMAC using SHA-512
  **   - RS256 - RSASSA-PKCS1-v1_5 using SHA-256
  **   - RS384 - RSASSA-PKCS1-v1_5 using SHA-384
  **   - RS512 - RSASSA-PKCS1-v1_5 using SHA-512
  **   - ES256 - ECDSA using P-256 and SHA-256
  **   - ES384 - ECDSA using P-384 and SHA-384
  **   - ES512 - ECDSA using P-521 and SHA-512
  **   - none  - No digital signature or MAC performed
  **
  ** ```fantom
  ** pair   := Crypto.cur.genKeyPair("RSA", 2048)
  ** priv   := pair.priv
  **
  ** jwtStr := Jwt {
  **             it.alg    = "RS256"
  **             it.claims = ["myClaim": "ClaimValue"]
  **             it.exp    = DateTime.nowUtc + 10min
  **             it.iss    = "https://fantom.accounts.dev"
  **           }.encode(priv)
  ** ```
  **
  Str encode(Key? key)
  {
    claimsSet := formatRegisteredClaims

    if (key == null && header[JwtConst.AlgorithmHeader] != "none")
      throw Err("JWT (${JwtConst.AlgorithmHeader}) header parameter must be \"none\" if key is null")

    encodedHeader := writeJsonToStr(header).toBuf.toBase64Uri
    encodedClaims := writeJsonToStr(claimsSet).toBuf.toBase64Uri
    signingContent := "${encodedHeader}.${encodedClaims}".toBuf
    signature := key == null ? "" : generateSignature(signingContent, key)

    return "${encodedHeader}.${encodedClaims}.${signature}"
  }

  ** Convenience function to check the value of a claim.
  **
  ** If expectedValue is null, just checks that the claim exists.  Otherwise
  ** the claim value and expectedValue are each treated as a set of values
  ** (a non-List is a one-item set) and at least one of the claim values must
  ** be contained in the expectedValue values.  An empty expectedValue List
  ** never matches.
  **
  ** Throws Err if the claim does not exist or does not match.
  **
  **     jwt := Jwt.decode("1111.2222.3333", pubKey)
  **               .verifyClaim("iss", "https://fantom.accounts.dev")
  **               .verifyClaim("aud", ["client1", "client2"])
  **
  This verifyClaim(Str claim, Obj? expectedValue := null)
  {
    if (!claims.containsKey(claim)) throw Err("JWT (${claim}) claim is not present")
    if (expectedValue == null) return this

    claimValue := claims[claim]
    Obj?[] actual   := claimValue as List ?: [claimValue]
    Obj?[] accepted := expectedValue as List ?: [expectedValue]
    if (!actual.any |v| { accepted.contains(v) })
      throw Err("JWT (${claim}) claim ${claimValue} does not match expected value: ${expectedValue}")

    return this
  }

//////////////////////////////////////////////////////////////////////////
// Utility Functions
//////////////////////////////////////////////////////////////////////////

  override Str toStr()
  {
    return "JOSE HEADER:\n" + prettyPrint(header) + "\nJWT CLAIMS:\n" + prettyPrint(claims)
  }

  private Str prettyPrint(Str:Obj map) { Type.find("util::JsonOutStream").method("prettyPrintToStr").call(map) }

  private Str writeJsonToStr(Str:Obj map) { Type.find("util::JsonOutStream").method("writeJsonToStr").call(map) }

  private static Obj? readJson(Str encoded) { Type.find("util::JsonInStream").make([Buf.fromBase64(encoded).in])->readJson }

  private static Void verifyExp(Int? exp, Duration clockDrift)
  {
    if(exp == null) return

    if(!(exp is Int)) throw Err("JWT (${JwtConst.ExpirationClaim}) claim is not a valid value: ${exp}")

    nowDrift := DateTime.nowUtc - clockDrift
    if(nowDrift > DateTime.fromJava(exp * 1000)) throw Err("JWT expired")
  }

  private static Void verifyNbf(Int? nbf, Duration clockDrift)
  {
    if(nbf == null) return

    if(!(nbf is Int)) throw Err("JWT (${JwtConst.NotBeforeClaim}) claim is not a valid value: ${nbf}")

    nowDrift := DateTime.nowUtc + clockDrift
    if(nowDrift < DateTime.fromJava(nbf*1000, TimeZone.utc)) throw Err("JWT not valid yet")
  }

  private Str:Obj formatRegisteredClaims()
  {
    claimsSet := [:].addAll(claims)
    if (exp != null) claimsSet[JwtConst.ExpirationClaim] = toNumericDate(exp)
    if (nbf != null) claimsSet[JwtConst.NotBeforeClaim] = toNumericDate(nbf)
    if (iat != null) claimsSet[JwtConst.IssuedAtClaim] = toNumericDate(iat)
    return claimsSet
  }

  private Str[]? toAudienceClaim(Obj? aud)
  {
    if (aud == null) return null
    else if (aud is Str) return [(Str)aud]
    else if (aud is List)
    {
      unique := ((List)aud).unique
      return unique.findType(Str#)
    }
    else throw ArgErr("JWT (aud) claim must be a Str or Str[]")
  }

  ** Constant time compare so timing does not leak how many leading MAC bytes match
  private static Bool macEquals(Buf a, Buf b)
  {
    if (a.size != b.size) return false
    diff := 0
    for (i := 0; i < a.size; ++i) diff = diff.or(a[i].xor(b[i]))
    return diff == 0
  }

  private DateTime? fromNumericDate(Int? val)
  {
    if (val != null) return DateTime.fromJava(val * 1000).toUtc
    return null
  }

  private Int toNumericDate(DateTime dt)
  {
    (dt.toUtc - epoch).toSec
  }

  private Str generateSignature(Buf signingContent, Key key)
  {
    signature := ""
    jwsAlg := JwsAlgorithm.fromAlg(alg)
    if (key is PrivKey)
    {
      if (jwsAlg.keyType != key.algorithm)
        throw Err("JWT (alg) header parameter \"${jwsAlg.toStr}\" is not compatible with Key algorithm \"${key.algorithm}\"")
      if (jwsAlg.keyType == "EC") jwsAlg.checkEcKey(key)
      sigBuf := ((PrivKey)key).sign(signingContent, jwsAlg.digest)
      if (key.algorithm == "EC") signature = transcodeDerToConcat(sigBuf, jwsAlg.ecSigSize).toBase64Uri
      else signature = sigBuf.toBase64Uri
    }
    else if (key is MacKey)
    {
      if(key.algorithm != "Hmac" + jwsAlg.digest)
        throw Err("JWS (alg) header parameter \"${jwsAlg.toStr}\" is not compatible with Key algorithm \"${key.algorithm}\"")
      // one-shot hmac since MacKey holds shared mutable digest state
      signature = signingContent.hmac(key.algorithm, key.encoded).toBase64Uri
    }
    else
    {
      throw ArgErr("Invalid JWT signing key")
    }

    return signature
  }

  // JWS ECDSA signatures are R||S as fixed size unsigned big-endian integers
  // (RFC 7515 A.3), but Java signs and verifies ASN.1 DER SEQUENCE {r INTEGER, s INTEGER}
  private static Buf transcodeConcatToDer(Buf sig)
  {
    half := sig.size / 2
    body := Buf()
    writeDerInt(body, sig[0..<half])
    writeDerInt(body, sig[half..<sig.size])
    der := Buf().write(0x30)
    writeDerLen(der, body.size)
    return der.writeBuf(body.flip).flip
  }

  // DER INTEGER is signed and minimal: strip leading zeros, add 0x00 if the high bit is set
  private static Void writeDerInt(Buf out, Buf mag)
  {
    i := 0
    while (i < mag.size - 1 && mag[i] == 0) ++i
    pad := mag[i] >= 0x80 ? 1 : 0
    out.write(0x02)
    writeDerLen(out, mag.size - i + pad)
    if (pad == 1) out.write(0)
    out.writeBuf(mag[i..<mag.size])
  }

  // P-521 is the largest curve so the SEQUENCE never exceeds 255 bytes
  private static Void writeDerLen(Buf out, Int len)
  {
    if (len >= 0x80) out.write(0x81)
    out.write(len)
  }

  private static Buf transcodeDerToConcat(Buf der, Int outLen)
  {
    err  := ArgErr("Invalid JWT ECDSA signature format")
    half := outLen / 2
    if (der.size < 8 || der[0] != 0x30) throw err
    pos := 2
    seqLen := der[1]
    if (seqLen == 0x81) { seqLen = der[2]; pos = 3 }
    else if (seqLen >= 0x80) throw err
    if (pos + seqLen != der.size) throw err

    out := Buf()
    for (n := 0; n < 2; ++n)
    {
      if (pos + 2 > der.size || der[pos] != 0x02) throw err
      end := pos + 2 + der[pos + 1]
      if (der[pos + 1] >= 0x80 || end > der.size) throw err
      i := pos + 2
      while (i < end && der[i] == 0) ++i
      if (end - i > half) throw err
      out.fill(0, half - (end - i)).writeBuf(der[i..<end])
      pos = end
    }
    if (pos != der.size) throw err
    return out.flip
  }
}

**************************************************************************
** JwtConst
**************************************************************************

internal mixin JwtConst
{
  // Javascript Object Signing and Encryption (JOSE) Headers
  const static Str AlgorithmHeader := "alg"
  const static Str KeyIdHeader := "kid"

  // Jwt Registered Claim Names
  const static Str ExpirationClaim := "exp"
  const static Str NotBeforeClaim := "nbf"
  const static Str IssuedAtClaim := "iat"
  const static Str JwtIdClaim := "jti"
  const static Str SubjectClaim := "sub"
  const static Str IssuerClaim := "iss"
  const static Str AudienceClaim := "aud"
}

**************************************************************************
** JwsAlgorithm - models the JSON Web Signature (JWS) Algorithm (alg) Parameter
**************************************************************************
@NoDoc
enum class JwsAlgorithm
{
  hs256,
  hs384,
  hs512,
  rs256,
  rs384,
  rs512,
  es256,
  es384,
  es512,
  none

  static new fromAlg(Str? name)
  {
    if (name == null) throw Err("JWT (alg) header parameter is required")
    jwsAlg := JwsAlgorithm.fromStr(name.lower, false)
    if (jwsAlg == null) throw Err("Unknown or Unsupported JWT (alg) parameter: ${name}")
    return jwsAlg
  }

  static new fromParameters(Str:Obj params)
  {
    alg := params[JwtConst.AlgorithmHeader]
    if (alg == null) throw Err("Missing (${JwtConst.AlgorithmHeader}) Parameter: ${params}")
    algorithm := JwsAlgorithm.vals.find |JwsAlgorithm v->Bool| { return v.name.equalsIgnoreCase(alg) }
    return algorithm ?: throw Err("Unsupported or Invalid JWS (alg) Parameter: ${alg}")
  }

  static new fromKeyAndDigest(Str keyType, Str digest)
  {
    algorithm := JwsAlgorithm.vals.find |JwsAlgorithm v->Bool|
    {
      if (keyType != "none") { return v.keyType == keyType && v.digest == digest }
      else { return v.keyType == keyType }
    }
    return algorithm ?: throw Err("Unsupported or Invalid JWS Key/Digest: ${keyType}/${digest}")
  }

  ** Curve size in bits an ES algorithm is bound to (RFC 7518 3.4), or null
  Int? curveBits()
  {
    switch (this)
    {
      case es256: return 256
      case es384: return 384
      case es512: return 521
      default:    return null
    }
  }

  ** JWK curve name an ES algorithm is bound to, or null
  Str? crv() { curveBits == null ? null : "P-${curveBits}" }

  ** Size in bytes of an ES signature (R and S each padded to the curve size), or null
  Int? ecSigSize() { curveBits == null ? null : (curveBits + 7) / 8 * 2 }

  ** Check an EC key is on the curve this ES algorithm is bound to
  Void checkEcKey(AsymKey key)
  {
    if (key.keySize != curveBits)
      throw Err("JWT (alg) header parameter \"${this}\" requires curve ${crv}, key is ${key.keySize} bits")
  }

  public Str digest()
  {
    size := name[-3..-1]
    switch(size)
    {
      case "256": return "SHA256"
      case "384": return "SHA384"
      case "512": return "SHA512"
      default:    return "none"
    }
  }

  public Str keyType()
  {
    switch(name[0])
    {
      case 'h': return "oct"
      case 'r': return "RSA"
      case 'e': return "EC"
      case 'n': return "none"
      default:  return "none"
    }
  }

  override Str toStr()
  {
    if (name != "none") return name.upper
    else return name
  }
}

