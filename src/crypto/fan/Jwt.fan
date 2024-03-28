//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 March 2024 Ross Schwalm Creation
//

**
** Models a JSON Web Token (JWT)
** https://datatracker.ietf.org/doc/html/rfc7519
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
** The following algorithms are supported:
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
const mixin Jwt 
{
  ** JOSE Header
  abstract Str:Obj header()
  
  ** JWT Claims
  abstract Str:Obj claims()
  
  ** JWT Signature
  abstract Buf? signature()
  
  ** JWT encoded format
  abstract Str encoded()

  ** Specify a claim name and value to check
  **
  ** If the expectedValue is null, throws JwtErr if claim does not exist
  ** 
  ** If claim value is a List, throws JwtErr if the expectedValue is not
  ** contained in the List
  **
  abstract This verifyClaim(Str claim, Obj? expectedValue := null)

  ** Provide a PubKey or MacKey to verify the signature.
  **
  ** If the exp and/or nbf claims exist, those will be verified in verifySignature.
  **
  abstract This verifySignature(Key key, Duration clockDrift := 60sec)
}

**************************************************************************
** JwtBuilder
**************************************************************************
@NoDoc
mixin JwtBuilder
{
  ** Set the Key ID in the JOSE header
  abstract This setKid(Str kid)

  ** Add Issued At (iat) claim using the time when build is called
  abstract This addIat()

  ** Add the JWT ID (jti) claim using a UUID
  abstract This addJti()

  ** Set the exp claim to the time build is called plus duration
  abstract This setExp(Duration dur) 

  ** Set the nbf claim to the time build is called minus duration
  abstract This setNbf(Duration dur)

  ** If not called, the default hash algorithm SHA256 will be used
  **
  ** Supported algorithms:
  **
  **    - SHA256
  **    - SHA384
  **    - SHA512
  **
  abstract This setDigestAlgorithm(Str algorithm)

  ** Provide a PrivKey or MacKey to sign and return the Jwt
  **
  ** Null key will return an unsigned Jwt
  **
  abstract Jwt build(Key? key)
}

**************************************************************************
** JwtErr
**************************************************************************

const class JwtErr : Err
{
  new make(Str msg := "", Err? cause := null) : super(msg, cause) { }
}