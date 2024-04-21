//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Mar 2024  Ross Schwalm  Creation
//

**
** Models a JSON Web Token (JWT) as specified by [RFC7519]`https://datatracker.ietf.org/doc/html/rfc7519`
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
    if (header[parameter] == null) return null
    val := (header[parameter]).typeof == type ? header[parameter] :
                throw ArgErr("JWT (${parameter}) header parameter must be ${type.name}")
    return val
  }

  private Obj? checkClaimMap(Str claim, Type type)
  {
    if (claims[claim] == null) return null
    val := (claims[claim]).typeof == type ? claims[claim] :
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
  ** When encoded, the value will be converted to UTC, the epoch const will be subtracted
  ** from this value and it will be converted to seconds
  const DateTime? exp

  ** Not before claim for this token
  **
  ** When encoded, the value will be converted to UTC, the epoch const will be subtracted
  ** from this value and it will be converted to seconds
  const DateTime? nbf

  ** Issued at claim for this token
  **
  ** When encoded, the value will be converted to UTC, the epoch const will be subtracted
  ** from this value and it will be converted to seconds
  const DateTime? iat

  ** JWT ID claim for this token
  const Str? jti

  ** UNIX epoch
  private const DateTime epoch := DateTime("1970-01-01T00:00:00Z UTC")

  ** Decode a `Jwt` from an encoded Str
  **
  ** Provide a `Key` (`PubKey` or `SymKey`) to verify the signature
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
  static new decode(Str encoded, Key key, Duration clockDrift := 60sec)
  {
    doDecode(encoded, key, clockDrift)
  }

  ** Decode an unsigned `Jwt` from an encoded Str
  **
  ** No claims are verified
  **
  **   jwt := Jwt.decode("1111.2222.3333")
  **
  @NoDoc
  static new decodeUnsigned(Str encoded)
  {
    doDecode(encoded, null)
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
      if (jwsAlg.keyType == "EC") signature = transcodeConcatToDer(signature)
    }
    catch (Err e) {throw Err("Error parsing JWT parts", e)}

    //Verify Signature
    if (!signature.bytesEqual(Buf.fromBase64("")) || jwsAlg != JwsAlgorithm.none || key != null)
    {
      verifyExp(claims[JwtConst.ExpirationClaim], clockDrift)
      verifyNbf(claims[JwtConst.NotBeforeClaim], clockDrift)

      if (key is PubKey)
      {
        if (jwsAlg.keyType != key.algorithm)
          throw Err("JWT (alg) header parameter \"${jwsAlg.toStr}\" is not compatible with Key algorithm \"${key.algorithm}\"")
        if (!((PubKey)key).verify(jwsSigningInput, digestAlgorithm, signature))
          throw Err("Invalid JWT signature")
      }
      else if (key is MacKey)
      {
        if(key.algorithm != "Hmac" + jwsAlg.digest)
          throw Err("JWS (alg) header parameter \"${jwsAlg.toStr}\" is not compatible with Key algorithm \"${key.algorithm}\"")
        if(!((MacKey)key).update(jwsSigningInput).digest.bytesEqual(signature))
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

  ** Provide a `Key` (`PrivKey` or `SymKey`) to sign and return the base64 encoded `Jwt`
  **
  ** Null key will return an unsigned base64 encoded JWT
  **
  ** The alg field must be set to a supported JWS algorithm
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
  **   jwtStr := Jwt {
  **                it.alg    = "RS256"
  **                it.claims = ["myClaim": "ClaimValue"]
  **                it.exp    = DateTime.nowUtc + 10min
  **                it.iss    = "https://fantom.accounts.dev"
  **             }.encode(priv)
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

  ** Convenience function to check the value of a claim
  **
  ** If value of JWT claim is a List, this function checks that the expectedValue
  ** is contained in the List.
  **
  ** If expectedValue is null, just checks if the claim exists
  **
  ** Throws Err if claim does not exist or expectedValue does not match (or is not
  ** contained in the List)
  **
  **   jwt := Jwt.decode("1111.2222.3333", pubKey)
  **             .verifyClaim("iss", "https://fantom.accounts.dev")
  **
  This verifyClaim(Str claim, Obj? expectedValue := null)
  {
    if(!claims.containsKey(claim)) { throw Err("JWT (${claim}) claim is not present") }

    if (expectedValue != null && expectedValue isnot List)
    {
      claimValue := claims[claim]

      if (claimValue is List)
      {
        if (!((List)claimValue).contains(expectedValue))
        {
          throw Err("JWT (${claim}) claim ${claimValue} does not contain expected value: ${expectedValue}")
        }
      }
      else
      {
        if (claimValue != expectedValue)
        {
          throw Err("JWT (${claim}) claim ${claimValue} is not equal to expected value: ${expectedValue}")
        }
      }
    }

    return this
  }

//////////////////////////////////////////////////////////////////////////
// Utility Functions
//////////////////////////////////////////////////////////////////////////

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

    return null
  }

  private DateTime? fromNumericDate(Int? val)
  {
    if (val != null && val is Int) return DateTime.fromJava(val * 1000)
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
      sigBuf := ((PrivKey)key).sign(signingContent, jwsAlg.digest)
      if (key.algorithm == "EC") signature = transcodeDerToConcat(sigBuf, 64).toBase64Uri
      else signature = sigBuf.toBase64Uri
    }
    else if (key is MacKey)
    {
      if(key.algorithm != "Hmac" + jwsAlg.digest)
        throw Err("JWS (alg) header parameter \"${jwsAlg.toStr}\" is not compatible with Key algorithm \"${key.algorithm}\"")
      sigBuf := ((MacKey)key).update(signingContent).digest
      signature = sigBuf.toBase64Uri
    }
    else
    {
      throw ArgErr("Invalid JWT signing key")
    }

    return signature
  }

  // The ECDSA signature must be converted to ASN.1 DER bytes for verification
  //
  // JWS ECDSA signatures are formatted as the EC point R and S unsigned integers converted to byte arrays and
  // concatenated as defined in [RFC7515]`https://datatracker.ietf.org/doc/html/rfc7515#page-45`
  private static Buf transcodeConcatToDer(Buf sig)
  {
    rawLen := sig.size / 2

    i := rawLen
    while (i > 1 && sig[rawLen - i] == 0) {--i}

    j := i
    if (sig[rawLen - i] < 0) j++
    k := rawLen
    while (k > 1 && sig[rawLen*2 - k] == 0) {--k}

    l := k
    if (sig[rawLen*2 - k] < 0) l++
    len := 2 + j + 2 + l

    if (len > 255) throw ArgErr("Invalid JWT ECDSA signature format")

    offset := 0
    derLen := 0
    setByte := false

    if (len < 128)
    {
      derLen = 2 + 2 + j + 2 + l
      offset = 1
    }
    else
    {
      derLen = 3 + 2 + j + 2 + l
      setByte = true
      offset = 2
    }

    der := Buf(derLen).fill(0, derLen)

    der.seek(0)
    der.write(48)

    if (setByte) der.write(0x81)

    der.write(len)
    der.write(2)
    der.write(j)
    offset += 3

    idx := rawLen - i
    der.seek((offset + j) - i)
    i.times { der.write(sig[idx]); ++idx }

    offset += j

    der.seek(offset)
    der.write(2)
    der.write(l)
    offset += 2

    idx = 2*rawLen - k
    der.seek((offset + l) - k)
    k.times { der.write(sig[idx]); ++idx }

    return der.seek(0)
  }

  //Format ECDSA signatures as defined in [RFC7515]`https://datatracker.ietf.org/doc/html/rfc7515#page-45`
  private Buf transcodeDerToConcat(Buf sig, Int outLen)
  {
    if (sig.size < 8 || sig[0] != 48)
      throw ArgErr("Invalid JWT ECDSA signature format")

    offset := 0
    if (sig[1] > 0)
      offset = 2
    else if (sig[1] == 0x81)
      offset = 3
    else
      throw ArgErr("Invalid JWT ECDSA signature format")

    rLen := sig[offset + 1]
    i := rLen
    while ((i > 0) && (sig[(offset + 2 + rLen) - i] == 0)) { --i }

    sLen := sig[offset + 2 + rLen + 1]
    j := sLen
    while ((j > 0) && sig[(offset + 2 + rLen + 2 + sLen) - j] == 0) { --j }

    rawLen := i.max(j)
    rawLen = rawLen.max(outLen / 2)

    if (sig[offset - 1].and(0xff) != sig.size - offset) throw ArgErr("Invalid JWT ECDSA signature format")
    if (sig[offset - 1].and(0xff) != 2 + rLen + 2 + sLen) throw ArgErr("Invalid JWT ECDSA signature format")
    if (sig[offset] != 2) throw ArgErr("Invalid JWT ECDSA signature format")
    if (sig[offset + 2 + rLen] != 2) throw ArgErr("Invalid JWT ECDSA signature format")

    concatLen := 2 * rawLen
    concat := Buf(concatLen).fill(0, concatLen)

    idx := (offset + 2 + rLen) - i
    concat.seek(rawLen - i)
    i.times { concat.write(sig[idx]); ++idx }

    idx = (offset + 2 + rLen + 2 + sLen) - j
    concat.seek(2 * rawLen - j)
    j.times { concat.write(sig[idx]); ++idx }

    return concat.seek(0)
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
    return algorithm == null ? throw Err("Unsupported or Invalid JWS (alg) Parameter: ${alg}") : algorithm
  }

  static new fromKeyAndDigest(Str keyType, Str digest)
  {
    algorithm := JwsAlgorithm.vals.find |JwsAlgorithm v->Bool|
    {
      if (keyType != "none") { return v.keyType == keyType && v.digest == digest }
      else { return v.keyType == keyType }
    }
    return algorithm == null ? throw Err("Unsupported or Invalid JWS Key/Digest: ${keyType}/${digest}") : algorithm
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

