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
    verifyEq(Sys.homeDir.isDir, true)
    verifyEq(Sys.appDir.isDir, true)
    verifyEq(Sys.hostName.isEmpty, false)
    verifyEq(Sys.userName.isEmpty, false)
    verify(Sys.env.caseInsensitive)
    verify(Sys.env["os.name"] != null)
    verify(Sys.env["os.version"] != null)
    verify(Sys.env["OS.Name"] != null)
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