//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Oct 06  Brian Frank  Creation
//

**
** EnvTest
**
class EnvTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Args
//////////////////////////////////////////////////////////////////////////

  Void testArgs()
  {
    verifyEq(Env.cur.args.of, Str#)
    verifyEq(Env.cur.args.isRO, true)
    verifyEq(Env.cur.args.isImmutable, true)
  }

//////////////////////////////////////////////////////////////////////////
// Vars
//////////////////////////////////////////////////////////////////////////

  Void testEnv()
  {
    verifyEq(Env.cur.vars.typeof, [Str:Str]#)
    verifyEq(Env.cur.vars.isRO, true)
    verifyEq(Env.cur.vars.isImmutable, true)
    verify(Env.cur.vars.caseInsensitive)
    verify(Env.cur.vars["os.name"] != null)
    verify(Env.cur.vars["os.version"] != null)
    verify(Env.cur.vars["OS.Name"] != null)
  }

//////////////////////////////////////////////////////////////////////////
// Platform
//////////////////////////////////////////////////////////////////////////

  Void testPlatform()
  {
    // valid known list of os and arch constants
    os := ["win32", "macosx", "linux", "aix", "solaris", "hpux", "qnx"]
    arch := ["x86", "x86_64", "ppc", "sparc", "ia64", "ia64_32"]
    runtime := ["java", "dotnet", "js"]

    verify(os.contains(Env.cur.os))
    verify(arch.contains(Env.cur.arch))
    verify(runtime.contains(Env.cur.runtime))
    verifyEq(Env.cur.platform, "${Env.cur.os}-${Env.cur.arch}");
  }

//////////////////////////////////////////////////////////////////////////
// Misc
//////////////////////////////////////////////////////////////////////////

  Void testMisc()
  {
    verifyEq(Env.cur.host.isEmpty, false)
    verifyEq(Env.cur.user.isEmpty, false)
  }

//////////////////////////////////////////////////////////////////////////
// Id Hash
//////////////////////////////////////////////////////////////////////////

  Void testIdHash()
  {
    verifyEq(Env.cur.idHash(null), 0)
    verifyEq(Env.cur.idHash(this), Env.cur.idHash(this))
    verifyNotEq(Env.cur.idHash("hello"), "hello".hash)
  }

}