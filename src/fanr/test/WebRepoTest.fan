//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    8 Jul 11  Brian Frank  Creation
//

using concurrent

**
** WebRepoTest
**
class WebRepoTest : Test
{
  internal TestWebRepoAuth auth := TestWebRepoAuth("bob", "123")
  internal Service? wispService
  internal Int port := 1972

  internal Repo? pub      // client with no username, password
  internal Repo? badUser  // client with bad username
  internal Repo? badPass  // client with bad password
  internal Repo? good     // client with proper authentication

//////////////////////////////////////////////////////////////////////////
// Setup/Teardown
//////////////////////////////////////////////////////////////////////////

  override Void setup()
  {
    // create pod file repo
    fr := FileRepo(tempDir.uri)
    fr.publish(Env.cur.homeDir + `lib/fan/web.pod`)
    fr.publish(Env.cur.homeDir + `lib/fan/wisp.pod`)
    fr.publish(Env.cur.homeDir + `lib/fan/util.pod`)

    // wrap with WebRepoMod
    mod := WebRepoMod
    {
      it.repo = fr
      it.auth = this.auth
      it.pingMeta = it.pingMeta.dup.add("extra", "foo")
    }

    // open wisp service on test port
    wispService = WebRepoMain.makeWispService(mod, port)
    wispService->log->level = LogLevel.silent
    wispService.start

    // setup clients
    pub     = Repo.makeForUri(`http://localhost:$port/`)
    good    = Repo.makeForUri(`http://localhost:$port/`, "bob", "123")
    badUser = Repo.makeForUri(`http://localhost:$port/`, "bad", "123")
    badPass = Repo.makeForUri(`http://localhost:$port/`, "bob", "bad")
  }

  override Void teardown()
  {
    wispService?.uninstall
  }

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  Void test()
  {
    verifyPing
    verifyQuery
  }

//////////////////////////////////////////////////////////////////////////
// Ping
//////////////////////////////////////////////////////////////////////////

  Void verifyPing()
  {
    // bad credentials
    verifyBadCredentials |r| { r.ping }

    // public and login have access to ping
    doVerifyPing(pub)
    doVerifyPing(good)
  }

  Void doVerifyPing(Repo r)
  {
    p := r.ping
    verifyEq(p["fanr.version"], typeof.pod.version.toStr)
    verifyEq(p["fanr.type"], WebRepo#.qname)
    verifyEq(p["extra"], "foo")
    verifyEq(DateTime.fromStr(p["ts"]).date, Date.today)
  }

//////////////////////////////////////////////////////////////////////////
// Query
//////////////////////////////////////////////////////////////////////////

  Void verifyQuery()
  {
    // bad credentials
    verifyBadCredentials |r| { r.query("*") }

    // public not allowed
    auth.allowPublic.val = false
    verifyAuthRequired |r| { r.query("*") }

    // public allowed
    auth.allowPublic.val = true
    doVerifyQuery(pub)

    // login not allowed
    auth.allowUser.val = auth.allowPublic.val = false
    verifyForbidden |r| { r.query("*") }

    // login allowed
    auth.allowUser.val = true
    doVerifyQuery(good)
  }

  Void doVerifyQuery(Repo r)
  {
    pods := r.query("*").sort
    verifyEq(pods.size, 3)
    verifyEq(pods[0].name, "util")
    verifyEq(pods[1].name, "web")
    verifyEq(pods[2].name, "wisp")

// TODO verify per pod security
  }

//////////////////////////////////////////////////////////////////////////
// Authentication
//////////////////////////////////////////////////////////////////////////

  ** Test with invalid username and invalid password
  Void verifyBadCredentials (|Repo| f)
  {
    verifyAuthErr("Invalid username: bad [401]", badUser, f)
    verifyAuthErr("Invalid password (invalid signature) [401]", badPass, f)
  }

  ** Test that public (no credentials) reports auth required
  Void verifyAuthRequired(|Repo| f)
  {
    verifyAuthErr("Authentication required [401]", pub, f)
  }

  ** Test that valid login account is forbidden from an operation
  Void verifyForbidden(|Repo| f)
  {
    verifyAuthErr("Not allowed [403]", good, f)
  }

  Void verifyAuthErr(Str msg, Repo r, |Repo| f)
  {
    Err? err := null
    try
      f(r)
    catch (Err e)
      err = e

    if (err == null) fail("No err raised: $msg")

    verifyEq(err.typeof, RemoteErr#)
    // echo("     $err")
    verifyEq(err.msg, msg)
  }

}

internal const class TestWebRepoAuth : SimpleWebRepoAuth
{
  new make(Str u, Str p) : super(u, p) {}
  const AtomicBool allowPublic := AtomicBool(false)
  const AtomicBool allowUser   := AtomicBool(false)
  override Bool allowQuery(Obj? u, PodSpec? p) { allowPublic.val  || (u != null && allowUser.val) }
}

