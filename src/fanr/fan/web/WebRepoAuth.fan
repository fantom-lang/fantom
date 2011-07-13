//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    4 Jul 11  Brian Frank  Yeah USA!
//

using web
using util

**
** WebRepoAuth is used to plug in authentication and permission
** authorization for a WebRepoMod.
**
const abstract class WebRepoAuth
{

//////////////////////////////////////////////////////////////////////////
// Authentication
//////////////////////////////////////////////////////////////////////////

  ** What algorithms are supported to compute the "secret" to use
  ** for digital signatures.  They should be sorted from most
  ** preferred to least preferred.  Standard values are:
  **   - 'PASSWORD': simple plaintext password is used as secret
  **   - 'SALTED-HMAC-SHA1': HMAC of "user:salt" with password as key
  abstract Str[] secretAlgorithms()

  ** What algorithms are supported for computing the signature of a request.
  ** They should be sorted from most preferred to least preferred.
  ** Standard values are:
  **   - 'HMAC-SHA1': SHA-1 HMAC using secret as key
  ** The default implementation of both client and server only
  ** supports "HMAC-SHA1".
  virtual Str[] signatureAlgorithms() { ["HMAC-SHA1"] }

  ** Given a username, return an implementation specific object
  ** which models the user for the given username.  Or return null
  ** if username doesn't map to a valid user.
  abstract Obj? user(Str username)

  ** Get the salt used for the SALTED-HMAC-SHA1 secret algorithm for
  ** the given user.  If the user doesn't exist or salts aren't
  ** supported, then return null.
  abstract Str? salt(Obj? user)

  ** Get the secret as a byte buffer for the given user and algorithm
  ** which can be used to verify the digital signature of a request.
  ** See `secretAlgorithms` for list of algorithms (parameter is guaranteed
  ** to be in all upper case).
  abstract Buf secret(Obj? user, Str algorithm)

//////////////////////////////////////////////////////////////////////////
// Permissions
//////////////////////////////////////////////////////////////////////////

  ** Is the given user allowed to query the given pod?
  ** If pod is null, return if user is allowed to query anything.
  abstract Bool allowQuery(Obj? user, PodSpec? pod)

  ** Is the given user allowed to read/download/install the given pod?
  ** If pod is null, return if user is allowed to install anything.
  abstract Bool allowRead(Obj? user, PodSpec? pod)

  ** Is the given user allowed to publish the given pod?
  ** If pod is null, return if user is allowed to publish anything.
  abstract Bool allowPublish(Obj? user, PodSpec? pod)
}

**************************************************************************
** PublicWebRepoAuth
**************************************************************************

internal const class PublicWebRepoAuth : WebRepoAuth
{
  override Obj? user(Str username) { null }
  override Str? salt(Obj? user) { publicSalt }
  override Buf secret(Obj? user, Str algorithm) { Buf() }
  override Str[] secretAlgorithms() { ["PASSWORD", "SALTED-HMAC-SHA1"] }
  override Bool allowQuery(Obj? u, PodSpec? p) { true }
  override Bool allowRead(Obj? u, PodSpec? p)   { true }
  override Bool allowPublish(Obj? u, PodSpec? p) { true }

  private const Str publicSalt := Buf.random(16).toHex
}

**************************************************************************
** SimpleWebRepoAuth
**************************************************************************

internal const class SimpleWebRepoAuth : WebRepoAuth
{
  new make(Str username, Str password)
  {
    this.username = username
    this.userSalt = Buf.random(16).toHex
    this.password = password
  }

  override Obj? user(Str username) { username == this.username ? this : null }

  override Buf secret(Obj? user, Str algorithm)
  {
    if (user != this) throw Err("Invalid user: $user")
    switch (algorithm)
    {
      case "PASSWORD":
        return Buf().print(password)
      case "SALTED-HMAC-SHA1":
        return Buf().print("$username:$userSalt").hmac("SHA-1", password.toBuf)
      default:
        throw Err("Unexpected secret algorithm: $algorithm")
    }
  }

  override Str? salt(Obj? user) { user != null ? userSalt : null }

  override Str[] secretAlgorithms() { ["PASSWORD", "SALTED-HMAC-SHA1"] }

  override Bool allowQuery(Obj? u, PodSpec? p) { u != null }
  override Bool allowRead(Obj? u, PodSpec? p) { u != null }
  override Bool allowPublish(Obj? u, PodSpec? p) { u != null }

  private const Str username
  private const Str userSalt
  private const Str password
}

