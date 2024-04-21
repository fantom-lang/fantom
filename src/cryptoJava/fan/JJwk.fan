//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Mar 2024  Ross Schwalm  Creation
//

using web
using crypto
using util

using [java] java.util::HashMap

**
** JwKey defines the api for a JSON Web Key (JWK).
**
const class JJwk : Jwk
{
  override const Str:Obj meta

  override const Key key

  override Str toStr()
  {
    JsonOutStream.prettyPrintToStr(meta)
  }

  ** The Key Identifier
  private Str? kid() { meta[JwkConst.KeyIdHeader] }

  ** The Key Type Paramter
  private Str kty() { meta[JwkConst.KeyTypeHeader] }

  ** The Algorithm Parameter
  private Str alg() { meta[JwkConst.AlgorithmHeader] }

  ** Digest algorithm
  private Str digestAlgorithm() { JwsAlgorithm.fromParameters(meta).digest }

  ** Use Parameter
  private Str? use() { meta[JwkConst.UseHeader] }

  new make(Str:Obj map)
  {
    meta = map

    //Section 6.1 of RFC7518 - JSON Web Algorithms (JWA)
    if(!meta.containsKey(JwkConst.KeyTypeHeader)) throw Err("JWK missing Key type (${JwkConst.KeyTypeHeader})")
    kty := JwsKeyType.fromParameters(meta)

    if(meta.containsKey(JwkConst.UseHeader))
    {
      if(JwsUse.fromParameters(meta) == null) throw Err("JWK Use (${JwkConst.UseHeader}) Parameter invalid type")
    }

    if(!meta.containsKey(JwkConst.AlgorithmHeader)) throw Err("JWK missing Algorithm (${JwkConst.AlgorithmHeader}) Paramter")

    if(JwsAlgorithm.fromParameters(meta) == null) throw Err("JWK Algorithm (${JwkConst.AlgorithmHeader}) Parameter invalid type")

    if(meta.containsKey(JwkConst.KeyIdHeader))
    {
      if(!(meta[JwkConst.KeyIdHeader] is Str)) throw Err("JWK Key ID (${JwkConst.KeyIdHeader}) invalid type")
    }

    if(kty == JwsKeyType.rsa) key = JwRsaPubKey.getKey(meta)
    else if (kty == JwsKeyType.ec) key = JwEcPubKey.getKey(meta)
    else if (kty == JwsKeyType.oct) key = JwHmacKey.getKey(meta)
    else throw Err("Unsupported JWK Type")
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Import JSON Web Key Set
  **
  static Jwk[] importJwksUri(Uri jwksUri, Int? maxJwKeys := 10)
  {
    try
    {
      c := WebClient(jwksUri)
      c.reqHeaders["Accept"] = "text/plain; charset=utf-8"
      buf := c.getBuf
      return importJwks(JsonInStream(buf.in).readJson, maxJwKeys)
    }
    catch (Err err)
    {
      err.trace
      throw err
    }
  }

  **
  ** Import JSON Web Key Set
  **
  internal static Jwk[] importJwks(Str:Obj jwks, Int? maxJwKeys := 10)
  {
    keysList := jwks["keys"] as List
    if (keysList == null) throw Err("Invalid JSON Web Key Set")
    if (keysList.size > maxJwKeys) { keysList = keysList.getRange(0..maxJwKeys-1) }
    jwkList := [,]
    keysList.each |k| { jwkList = jwkList.add(JJwk(k)) }
    return jwkList
  }

  **
  ** Get a Jwk from a PubKey or MacKey
  **
  @NoDoc
  static Jwk toJwk(Key key, Str digest, Str:Obj meta := [:])
  {
    jwk := [:].addAll(meta)

    if (key is PubKey)
    {
      pubKey := key as PubKey
      if (pubKey.algorithm == "EC")
      {
        keyParams := JwEcPubKey.bufToJwk(pubKey.encoded)
        jwk = jwk.addAll(keyParams)
        jwk[JwkConst.AlgorithmHeader] = JwsAlgorithm.fromKeyAndDigest("EC", digest).toStr
        jwk[JwkConst.KeyTypeHeader] = "EC"
      }
      else if (pubKey.algorithm == "RSA")
      {
        keyParams := JwRsaPubKey.bufToJwk(pubKey.encoded)
        jwk = jwk.addAll(keyParams)
        jwk[JwkConst.AlgorithmHeader] = JwsAlgorithm.fromKeyAndDigest("RSA", digest).toStr
        jwk[JwkConst.KeyTypeHeader] = "RSA"
      }
      else
      {
        throw Err("Invalid Public Key")
      }
    }
    else if (key is MacKey)
    {
      jwk[JwkConst.AlgorithmHeader] = JwsAlgorithm.fromKeyAndDigest("oct", digest).toStr
      jwk[JwkConst.KeyTypeHeader] = "oct"
      jwk[JwaConst.KeyValueParameter] = key.encoded.readAllStr
    }
    else
    {
      throw Err("Invalid key type")
    }

    return JJwk(jwk)
  }
}

**************************************************************************
** JwkConst - JSON Web Key (JWK) Constants
**************************************************************************

internal mixin JwkConst
{
  // JOSE Headers
  const static Str TypeHeader := "typ"
  const static Str KeyTypeHeader := "kty"
  const static Str AlgorithmHeader := "alg"
  const static Str KeyIdHeader := "kid"
  const static Str UseHeader := "use"
  const static Str ContentTypeHeader := "cty"
}

**************************************************************************
** JwaConst - JSON Web Algorithms (JWA) Constants
**************************************************************************

internal mixin JwaConst
{
  // Elliptic Curve Public Key Parameters
  const static Str CurveParameter := "crv"
  const static Str XCoordParameter := "x"
  const static Str YCoordParameter := "y"

  // RSA Public Key Parameters
  const static Str ModulusParameter := "n"
  const static Str ExponentParameter := "e"

  // Symmetric Key Parameters
  const static Str KeyValueParameter := "k"
}

**************************************************************************
** JwsKeyType - JSON Web Signature (JWS) Key Type (kty) Parameter
**************************************************************************

internal enum class JwsKeyType
{
  oct,
  rsa,
  ec,
  none

  static new fromParameters(Str:Obj key)
  {
    kty := key[JwkConst.KeyTypeHeader]
    if (kty == null) return null
    type := JwsKeyType.vals.find |JwsKeyType v->Bool| { return v.toStr == kty }
    return type == null ? throw Err("JWK kty invalid type") : type
  }

  override Str toStr()
  {
    if (name == "oct" || name == "none") return name
    return name.upper
  }
}

**************************************************************************
** JwsUse - JSON Web Signature (JWS) Use (use) Parameter
**************************************************************************

internal enum class JwsUse
{
  sig,
  enc

  static new fromParameters(Str:Obj key)
  {
    use := key[JwkConst.UseHeader]
    if (use == null) return null
    return JwsUse.fromStr(use, false)
  }
}

**************************************************************************
** JwPubKey
**************************************************************************

internal mixin JwPubKey
{
  static PubKey? pem(Buf der, Str algorithm)
  {
    buf := Buf.make
    out := buf.out
    out.writeChars("-----BEGIN PUBLIC KEY-----\n")
    base64 := der.toBase64
    size   := base64.size
    idx    := 0
    pemChars := 64
    while (idx < size)
    {
      end := (idx + pemChars).min(size)
      out.writeChars(base64[idx..<end]).writeChar('\n')
      idx += pemChars
    }
    out.writeChars("-----END PUBLIC KEY-----\n")
    buf.flip
    return Crypto.cur.loadPem(buf.seek(0).in, algorithm) as PubKey
  }
}


**************************************************************************
** JwRsaPubKey
**************************************************************************

**
** Models a Public RSA JSON Web Key (JWK)
**
** https://tools.ietf.org/html/rfc7517
**
**  {
**    "kid": "1234example=",
**    "alg": "RS256",
**    "kty": "RSA",
**    "e": "AQAB",
**    "n": "1234567890",
**    "use": "sig"
**  }
**
**  Key ID (kid) - The kid is a hint that indicates which key was used to
**                 secure the JSON web signature (JWS) of the token.
**
**  Algorithm (alg) - The alg header parameter represents the cryptographic
**                    algorithm that is used to secure the ID token.
**
**  Key type (kty) - The kty parameter identifies the cryptographic algorithm
**                   family that is used with the key.
**
**  RSA exponent (e) - The e parameter contains the exponent value for the RSA
**                     public key. It is represented as a Base64urlUInt-encoded value.
**
**  RSA modulus (n) - The n parameter contains the modulus value for the RSA public
**                    key. It is represented as a Base64urlUInt-encoded value.
**
**  Use (use) - The use parameter describes the intended use of the public key.
**
@NoDoc
internal class JwRsaPubKey : JwPubKey, JwaConst
{
  static const Str algorithm := "RSA"

  static Key getKey(Str:Obj map)
  {
    if (JwsKeyType.fromParameters(map) != JwsKeyType.rsa) throw Err("JWK is not RSA key type")

    if(!map.containsKey(ModulusParameter)) throw Err("JWK missing RSA modulus (${ModulusParameter})")
    if(!map.containsKey(ExponentParameter)) throw Err("JWK missing RSA exponent (${ExponentParameter})")

    return pem(der(map), algorithm)
  }

  static native Buf jwkToBuf(Str mod, Str exp)

  static native Str:Obj bufToJwk(Buf key)

  private static Buf der(Str:Obj jwk)
  {
    mod := jwk[ModulusParameter] as Str
    exp := jwk[ExponentParameter] as Str
    return jwkToBuf(mod, exp)
  }

}

**************************************************************************
** JwEcPubKey
**************************************************************************

**
** Models a Public Elliptic Curve JSON Web Key (JWK)
**
** https://tools.ietf.org/html/rfc7517
**
**  {
**    "kid": "1234example=",
**    "alg": "ES256",
**    "kty": "EC",
**    "crv": "P-256",
**    "x": "f83OJ3D2xF1Bg8vub9tLe1gHMzV76e8Tus9uPHvRVEU",
**    "y": "x_FEzRu9m36HLN_tue659LNpXW6pCyStikYjKIWI5a0",
**    "use": "sig"
**  }
**
**  Key ID (kid) - The kid is a hint that indicates which key was used to
**                 secure the JSON web signature (JWS) of the token.
**
**  Algorithm (alg) - The alg header parameter represents the cryptographic
**                    algorithm that is used to secure the ID token.
**
**  Key type (kty) - The kty parameter identifies the cryptographic algorithm
**                   family that is used with the key.
**
**  Curve (crv) - The crv parameter identifies the cryptographic curve used with the key.
**
**  X coordinate (x) - The x parameter contains the x coordinate of the EC Point.
**                     It is represented as a Base64urlUInt-encoded value.
**
**  Y coordinate (y) - The y parameter contains the y coordinate of the EC Point.
**                     It is represented as a Base64urlUInt-encoded value.
**
**  Use (use) - The use parameter describes the intended use of the public key.
**

internal class JwEcPubKey : JwPubKey, JwaConst
{
  static const Str algorithm := "EC"

  static Key getKey(Str:Obj map)
  {
    if (JwsKeyType.fromParameters(map) != JwsKeyType.ec) throw Err("JWK is not EC key type")

    if(!map.containsKey(XCoordParameter)) throw Err("JWK missing EC X coordinate parameter (${XCoordParameter})")
    if(!map.containsKey(YCoordParameter)) throw Err("JWK missing EC Y coordinate parameter (${YCoordParameter})")
    if(!map.containsKey(CurveParameter)) throw Err("JWK missing EC Curve parameter (${CurveParameter})")

    return pem(der(map), algorithm)
  }

  static native Buf jwkToBuf(Str x, Str y, Str curve)

  static native Str:Obj bufToJwk(Buf key)

  private static Buf der(Str:Obj jwk)
  {
    x := jwk[XCoordParameter] as Str
    y := jwk[YCoordParameter] as Str
    crv := jwk[CurveParameter] as Str
    return jwkToBuf(x, y, crv)
  }
}

**************************************************************************
** JwHmacKey
**************************************************************************

**
** Models a shared HMAC JSON Web Key (JWK)
**
** https://tools.ietf.org/html/rfc7517
**
**  {
**    "kty": "oct",
**    "k": "secret",
**    "kid": "HMAC Key"
**  }
**
**  Key ID (kid) - The kid is a hint that indicates which key was used to
**                 secure the JSON web signature (JWS) of the token.
**
**  Key type (kty) - The kty parameter identifies the cryptographic algorithm
**                   family that is used with the key.
**
**  Shared key (k) - The k parameter contains the shared key.
**

internal class JwHmacKey : JwaConst
{
  static Key getKey(Str:Obj map)
  {
    if (JwsKeyType.fromParameters(map) != JwsKeyType.oct) throw Err("JWK is not oct key type")

    if(!map.containsKey(KeyValueParameter)) throw Err("JWK missing Key Value Parameter (${KeyValueParameter})")

    strKey := map[KeyValueParameter] as Str

    algorithmName := "Hmac" + JwsAlgorithm.fromParameters(map).digest

    return JMacKey.load(strKey.toBuf, algorithmName)
  }
}

