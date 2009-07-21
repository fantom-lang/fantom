//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Oct 06  Brian Frank  Creation
//

**
** SysTest
**
class SysTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Args
//////////////////////////////////////////////////////////////////////////

  Void testArgs()
  {
    verifyEq(Sys.args.isRO, true)
  }

//////////////////////////////////////////////////////////////////////////
// Env
//////////////////////////////////////////////////////////////////////////

  Void testEnv()
  {
    verifyEq(Sys.env.isRO, true)
    verifyEq(Sys.hostName.isEmpty, false)
    verifyEq(Sys.userName.isEmpty, false)
    verify(Sys.env.caseInsensitive)
    verify(Sys.env["os.name"] != null)
    verify(Sys.env["os.version"] != null)
    verify(Sys.env["OS.Name"] != null)
  }

//////////////////////////////////////////////////////////////////////////
// Repo
//////////////////////////////////////////////////////////////////////////

  Void testRepo()
  {
    verifyEq(Repo.boot.name, "boot")
    if (Repo.boot !== Repo.working)
      verifyEq(Repo.working.name, "working")

    verifyEq(Repo.list.isImmutable, true)
    verifySame(Repo.list[0], Repo.working)
    verifySame(Repo.list[-1], Repo.boot)

    verifyEq(Repo.boot.dir.isDir, true)
    verifyEq(Repo.working.dir.isDir, true)
  }

//////////////////////////////////////////////////////////////////////////
// Id Hash
//////////////////////////////////////////////////////////////////////////

  Void testIdHash()
  {
    verifyEq(Sys.idHash(null), 0)
    verifyEq(Sys.idHash(this), Sys.idHash(this))
    verifyNotEq(Sys.idHash("hello"), "hello".hash)
  }

}