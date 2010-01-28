//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Mar 06  Brian Frank  Creation
//

**
** PodTest
**
class PodTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  Void testIdentity()
  {
    pod := Pod.of(this)
    verifyEq(pod.name,  "testSys")
    verifyEq(pod.toStr, "testSys")
    verifyEq(pod.uri,   `fan:/sys/pod/testSys/`)
    verifySame(pod.uri.get, pod)
    verifySame(pod, Type.of(this).pod)
  }

//////////////////////////////////////////////////////////////////////////
// Find
//////////////////////////////////////////////////////////////////////////

  Void testFind()
  {
    verifySame(Pod.find("sys"), Bool#.pod)
    verifySame(Pod.find("notHereFoo", false), null)
    verifyErr(UnknownPodErr#) { Pod.find("notHereFoo") }
  }

//////////////////////////////////////////////////////////////////////////
// List
//////////////////////////////////////////////////////////////////////////

  Void testList()
  {
    pods := Pod.list
    verify(pods.isRO)
    verifyType(pods, Pod[]#)
    verify(pods.contains(Pod.find("sys")))
    verify(pods.contains(Pod.find("testSys")))
  }

//////////////////////////////////////////////////////////////////////////
// Repo
//////////////////////////////////////////////////////////////////////////

  Void testRepo()
  {
    // we assume sys pod loaded from boot repo
    verifySame(Str#.pod.repo, Repo.boot)
  }

//////////////////////////////////////////////////////////////////////////
// Meta
//////////////////////////////////////////////////////////////////////////

  Void testMeta()
  {
    sys := Pod.find("sys")
    verifyEq(sys.name, "sys")
    verifyEq(sys.depends.size, 0)

    testSys := Pod.find("testSys")
    verifyEq(testSys.name, "testSys")
    verifyEq(testSys.depends.size, 1)
    verifyEq(testSys.depends[0].name, "sys")
    verifyMeta(testSys)
  }

  Void verifyMeta(Pod pod)
  {
    if (false)
    {
      echo("verifyMeta")
      echo("  name    = $pod.name")
      echo("  version = $pod.version")
      echo("  depends = $pod.depends")
      echo("  facets  = $pod.facets")
    }

    verify(pod.version >= Version.fromStr("1.0.14"))
    verifyEq(pod.version.major, 1)
    verifyEq(pod.version.minor, 0)
    verify(pod.depends.isRO)
    verifyType(pod.facets, [Symbol:Obj?]#)
    verifyEq(pod.facets.findAll |v,s| { s.qname == "sys::podBuildTime" }.size, 1)
    verifyType(pod.facet(@podBuildTime), DateTime#)
  }

//////////////////////////////////////////////////////////////////////////
// Files
//////////////////////////////////////////////////////////////////////////

  Void testFiles()
  {
    files := Pod.of(this).files
    verify(files.containsKey(`/locale/en.props`))
    verify(files.containsKey(`/locale/en-US.props`))
    verify(files.containsKey(`/locale/es.props`))
    verify(files.containsKey(`/locale/es-MX.props`))

    f := Pod.of(this).files[`/res/test.txt`]
    verify(f != null)
    verifyEq(f.name, "test.txt")
    verifyEq(f.size, 19)
    verifyEq(f.readAllStr, "hello world\nline 2")
  }

//////////////////////////////////////////////////////////////////////////
// Log
//////////////////////////////////////////////////////////////////////////

  Void testLog()
  {
    verifyEq(Pod.of(this).log.name, "testSys")
  }

//////////////////////////////////////////////////////////////////////////
// Props
//////////////////////////////////////////////////////////////////////////

  Void testProps()
  {
    pod := typeof.pod
    verifyEq(pod.props(`locale/en.props`, 1ms)["a"], "a en")
    verifyEq(pod.props(`locale/en.props`, 1ms).isImmutable, true)

    verifyEq(pod.props(`not/found`, 1ms).size, 0)
    verifyEq(pod.props(`not/found`, 1ms).isImmutable, true)

    verifySame(pod.props(`locale/en.props`, 1ms), pod.props(`locale/en.props`, 1ms))
    verifySame(pod.props(`not/found`, 1ms), pod.props(`not/found`, 1ms))
  }


}