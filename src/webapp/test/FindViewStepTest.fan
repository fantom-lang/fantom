//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jul 08  Brian Frank  Creation
//

using web

class FindViewStepTest : Test
{

  override Void setup()
  {
    Actor.locals["web.req"] = TestWebReq()
    Actor.locals["web.res"] = TestWebRes()
  }

  override Void teardown()
  {
    Actor.locals["web.req"] = null
    Actor.locals["web.res"] = null
  }

  Void test()
  {
    WebAppStep.log.level=LogLevel.silent

    // resource is weblet
    verifyView(`/foo`, TestViewA.make, TestViewA#)

    // view registered on resource
    verifyView(`/foo`, TestResource.make, TestViewB#)

    // view registered on resource with priority
    verifyView(`/foo`, this, TestViewC#)

    // error: no view (on Int)
    verifyError(`/foo`, 33, 404)

    // error: explicit view not found
    verifyError(`/foo?view=sys::FooBar`, Repo.boot.home, 404)

    // error: explicit view not weblet
    verifyError(`/foo?view=sys::Int`, Repo.boot.home, 404)
  }

  Void verifyView(Uri u, Obj r, Type t)
  {
    req := TestWebReq { uri = u; resource = r }
    res := TestWebRes {}
    FindViewStep.make.service(req, res)
    verifyEq(req.stash["webapp.view"].type, t)
    // echo("$u $r.type => $t")
  }

  Void verifyError(Uri u, Obj r, Int sc)
  {
    req := TestWebReq { uri = u; resource = r }
    res := TestWebRes {}
    FindViewStep.make.service(req, res)
    verifyEq(res.statusCode, sc)
  }

}

internal class TestResource {}

@webView=[FindViewStepTest#]
@webViewPriority=5
internal class TestViewA : Weblet {}

@webView=[TestResource#, FindViewStepTest#]
internal class TestViewB : Weblet {}

@webView=[FindViewStepTest#]
@webViewPriority=10
internal class TestViewC : Weblet {}