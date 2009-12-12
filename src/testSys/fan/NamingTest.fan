//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Aug 08  Brian Frank  Creation
//

**
** NamingTest
**
class NamingTest : Test
{

//////////////////////////////////////////////////////////////////////////
// SchemeFind
//////////////////////////////////////////////////////////////////////////

  Void testSchemeFind()
  {
    x := UriScheme.find("fan")
    verifyEq(x.type.qname, "sys::FanScheme")
    verifyEq(x.scheme, "fan")
    verifyEq(x.toStr, "fan")
    verifySame(UriScheme.find("fan"), x)

    x = UriScheme.find("file")
    verifyEq(x.type.qname, "sys::FileScheme")
    verifyEq(x.scheme, "file")
    verifyEq(x.toStr, "file")
    verifySame(UriScheme.find("file"), x)

    verifyEq(UriScheme.find("foobar", false), null)
    verifyErr(UnresolvedErr#) { UriScheme.find("foobar") }
    verifyErr(UnresolvedErr#) { UriScheme.find("foobar", true) }
  }

//////////////////////////////////////////////////////////////////////////
// file:
//////////////////////////////////////////////////////////////////////////

  Void testFile()
  {
    // verify file:
    uri := Repo.boot.home.normalize.uri
    verifyEq(uri.scheme, "file")
    File home := uri.get
    verifyEq(home.list.map |File f->Str| { f.name },
      Repo.boot.home.list.map |File f->Str| { f.name })

    // verify we can resolve without trailing slash
    uri = uri.toStr[0..-2].toUri
    verifyEq(uri.toStr.endsWith("/"), false)
    home = uri.get
    verifyEq(home.isDir, true)
    verifyEq(home.uri.isDir, true)
    verifyEq(home.uri.toStr.endsWith("/"), true)
    verifyEq(home.list.map |File f->Str| { f.name },
      Repo.boot.home.list.map |File f->Str| { f.name })
  }

//////////////////////////////////////////////////////////////////////////
// fan:/sys/pod
//////////////////////////////////////////////////////////////////////////

  Void testFanPod()
  {
    verifySame(`fan:/sys/pod/sys`.get, Str#.pod)
    verifySame(`fan:/sys/pod/testSys`.get, type.pod)
    verifySame(`fan:/sys/pod/testSys/res/test.txt`.get, type.pod.files[`/res/test.txt`])

    verifySame(`fan:/sys/pod/badpod`.get(null, false), null)
    verifyErr(UnresolvedErr#) { `fan:/sys/pod/badpod`.get }
    verifyErr(UnresolvedErr#) { `fan:/sys/pod/badpod`.get(null) }
    verifyErr(UnresolvedErr#) { `fan:/sys/pod/badpod`.get(null, true) }
  }

//////////////////////////////////////////////////////////////////////////
// Base
//////////////////////////////////////////////////////////////////////////

  Void testWithBase()
  {
    p := type.pod
    f := p.files[`/res/test.txt`]
    verifySame(`fan:/sys/pod/testSys/res/test.txt`.get(null), f)
    verifySame(`fan:/sys/pod/testSys/res/test.txt`.get(UriSpace.root), f)
    verifySame(`fan:/sys/pod/testSys/res/test.txt`.get(p), f)
    verifySame(`res/test.txt`.get(p), f)

    verifyErr(UnresolvedErr#) { `res/test.txt`.get(null) }
    verifyErr(UnresolvedErr#) { `res/test.txt`.get("foo") }
    verifyErr(UnresolvedErr#) { `res/test.txt`.get(File.make(`rel`)) }
  }


}