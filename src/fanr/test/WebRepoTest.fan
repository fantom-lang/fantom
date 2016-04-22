//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    8 Jul 11  Brian Frank  Creation
//    20 Apr 16  Steve Krytkowski HTTPS Update
//

using concurrent

**
** WebRepoTest
**
class WebRepoTest : Test
{
  internal TestWebRepoAuth auth := TestWebRepoAuth("bob", "123")
  internal Service? wispService
  internal Int httpPort := 1972
  internal Int? httpsPort := null

  internal Repo? pub      // client with no username, password
  internal Repo? badUser  // client with bad username
  internal Repo? badPass  // client with bad password
  internal Repo? good     // client with proper authentication

  PodSpec? webSpec   // set in doVerifyQuery

//////////////////////////////////////////////////////////////////////////
// Setup/Teardown
//////////////////////////////////////////////////////////////////////////

  override Void setup()
  {
    // create pod file repo
    fr := FileRepo(tempDir.uri)
    fr.publish(podFile("web"))
    fr.publish(podFile("wisp"))
    fr.publish(podFile("util")) // no one allowed to query

    // wrap with WebRepoMod
    mod := WebRepoMod
    {
      it.repo = fr
      it.auth = this.auth
      it.pingMeta = it.pingMeta.dup.add("extra", "foo")
    }

    // open wisp service on test port
    wispService = WebRepoMain.makeWispService(mod, httpPort, httpsPort)
    wispService->log->level = LogLevel.silent
    wispService.start

    // setup clients
    pub     = Repo.makeForUri(`http://localhost:$httpPort/`)
    good    = Repo.makeForUri(`http://localhost:$httpPort/`, "bob", "123")
    badUser = Repo.makeForUri(`http://localhost:$httpPort/`, "bad", "123")
    badPass = Repo.makeForUri(`http://localhost:$httpPort/`, "bob", "bad")
  }

  override Void teardown()
  {
    wispService?.uninstall
  }

  File podFile(Str podName) { Env.cur.homeDir + `lib/fan/${podName}.pod` }

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  Void test()
  {
    verifyPing
    verifyFind
    verifyQuery
    verifyRead
    verifyPublish
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
// Find
//////////////////////////////////////////////////////////////////////////

  Void verifyFind()
  {
    // bad credentials
    verifyBadCredentials |r| { r.find("foo", Version("1.0")) }

    // public not allowed
    auth.allowPublic.val = false
    verifyAuthRequired |r| { r.find("foo", Version("1.0")) }

    // public allowed
    auth.allowPublic.val = true
    doVerifyFind(pub)

    // login not allowed
    auth.allowUser.val = auth.allowPublic.val = false
    verifyForbidden |r| { r.find("foo", Version("1.0")) }

    // login allowed
    auth.allowUser.val = true
    doVerifyFind(good)
  }

  Void doVerifyFind(Repo r)
  {
    wisp := Pod.find("wisp")  // allowed
    util := Pod.find("util")  // never allowed

    pod := r.find("wisp", wisp.version)
    verifyEq(pod.name, "wisp")
    verifyEq(pod.version, wisp.version)

    pod = r.find("wisp", null)
    verifyEq(pod.name, "wisp")
    verifyEq(pod.version, wisp.version)

    badVer := Version("28.99.1234")
    verifyEq(r.find("fooBarNotFound", Version("1.0.123"), false), null)
    verifyEq(r.find("wisp", badVer, false), null)
    verifyErr(UnknownPodErr#) { r.find("wisp", badVer) }
    verifyErr(UnknownPodErr#) { r.find("wisp", badVer, true) }

    verifyForbidden |x| { x.find("util", util.version) }
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
    verifyEq(pods.size, 2)
    verifyEq(pods[0].name, "web")
    verifyEq(pods[1].name, "wisp")

    webSpec = pods[0]
  }

//////////////////////////////////////////////////////////////////////////
// Read
//////////////////////////////////////////////////////////////////////////

  Void verifyRead()
  {
    // bad credentials
    verifyBadCredentials |r| { r.read(webSpec) }

    // public not allowed
    auth.allowPublic.val = false
    verifyAuthRequired |r| { r.read(webSpec) }

    // public allowed
    auth.allowPublic.val = true
    doVerifyRead(pub)

    // login not allowed
    auth.allowUser.val = auth.allowPublic.val = false
    verifyForbidden |r| { r.read(webSpec) }

    // login allowed
    auth.allowUser.val = true
    doVerifyRead(good)
  }

  Void doVerifyRead(Repo r)
  {
    temp := tempDir + `web-download.pod`
    out := temp.out
    r.read(webSpec).pipe(out)
    out.close

    spec := PodSpec.load(temp)
    verifyEq(spec.name, "web")
    verifyEq(spec.meta["org.name"], "Fantom")
  }

//////////////////////////////////////////////////////////////////////////
// Publish
//////////////////////////////////////////////////////////////////////////

  Void verifyPublish()
  {
    f := podFile("inet")
    // bad credentials
    verifyBadCredentials |r| { r.publish(f) }

    // public not allowed
    auth.allowPublic.val = false
    verifyAuthRequired |r| { r.publish(f) }

    // public allowed
    auth.allowPublic.val = true
    doVerifyPublish(pub, f)

    // login not allowed
    f = podFile("build")
    auth.allowUser.val = auth.allowPublic.val = false
    verifyForbidden |r| { r.publish(f) }

    // login allowed
    auth.allowUser.val = true
    doVerifyPublish(good, f)

    // no one allowed to publish util
    f = podFile("util")
    verifyForbidden |r| { r.publish(f) }

    // verify query that we successfully published two new pods
    pods := good.query("*").sort
    verifyEq(pods.size, 4)
    verifyEq(pods[0].name, "build")
    verifyEq(pods[1].name, "inet")
    verifyEq(pods[2].name, "web")
    verifyEq(pods[3].name, "wisp")
  }

  Void doVerifyPublish(Repo r, File f)
  {
    spec := r.publish(f)
    verifyEq(spec.name, f.basename)
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
    if (err isnot RemoteErr) err.trace

    verifyEq(err.typeof, RemoteErr#)
    // echo("     $err")
    verifyEq(err.msg, msg)
  }

}

internal const class TestWebRepoAuth : SimpleWebRepoAuth
{
  new make(Str u, Str p) : super(u, p) {}

  override Bool allowQuery(Obj? u, PodSpec? p) { allow(u, p) }
  override Bool allowRead(Obj? u, PodSpec? p) { allow(u, p) }
  override Bool allowPublish(Obj? u, PodSpec? p) { allow(u, p) }

  const AtomicBool allowPublic := AtomicBool(false)
  const AtomicBool allowUser   := AtomicBool(false)

  Bool allow(Obj? u, PodSpec? p)
  {
    if (p?.name == "util") return false // util never allowed
    return allowPublic.val  || (u != null && allowUser.val)
  }
}

