//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 March 2024 Ross Schwalm Creation
//

**
** Models a JSON Web Key (JWK)
** https://datatracker.ietf.org/doc/html/rfc7517
**
const mixin Jwk
{
  ** Jwk
  abstract Str:Obj meta()

  ** Key
  abstract Key key()
}