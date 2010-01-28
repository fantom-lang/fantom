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
// Directories
//////////////////////////////////////////////////////////////////////////

  Void testDirs()
  {
    verifyEq((Env.cur.homeDir+`bin/`).exists, true)
    verifyEnvDir(Env.cur.homeDir)
    verifyEnvDir(Env.cur.workDir)
    verifyEnvDir(Env.cur.tempDir)
  }

  Void verifyEnvDir(File f)
  {
    verifyEq(f.isDir, true)
    verifyEq(f.uri.scheme, "file")
    verifyEq(f.normalize.toStr, f.toStr)
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

//////////////////////////////////////////////////////////////////////////
// FindFile
//////////////////////////////////////////////////////////////////////////

  Void testFindFile()
  {
    // file
    file := Env.cur.findFile(`etc/sys/timezones.ftz`)
    verifyEq(file.readAllBuf.readS8, 0x66616e74_7a203032)

    // directories
    verifyEq(Env.cur.findFile(`etc/sys`).isDir, true)
    verifyEq(Env.cur.findFile(`etc/sys/`).isDir, true)

    // arg err
    verifyErr(ArgErr#) { Env.cur.findFile(`/etc/`) }

    // not found
    verifyEq(Env.cur.findFile(`etc/foo bar/no exist`, false), null)
    verifyErr(IOErr#) { Env.cur.findFile(`etc/foo bar/no exist`) }
    verifyErr(IOErr#) { Env.cur.findFile(`etc/foo bar/no exist`, true) }

    // findAllFiles
    verify(Env.cur.findAllFiles(`etc/sys/timezones.ftz`).size >= 1)
    verifyEq(Env.cur.findAllFiles(`bad/unknown file`).size, 0)
  }

//////////////////////////////////////////////////////////////////////////
// Props
//////////////////////////////////////////////////////////////////////////

  Void testProps()
  {
    uri := `temp/test/foo.props`
    f := Env.cur.workDir + uri
    try
    {
      props := ["a":"alpha", "b":"beta"]
      f.writeProps(props)

      // verify basics
      verifyEq(Env.cur.props(`some-bad-file-foo-bar`), Str:Str[:])
      verifyEq(Env.cur.props(uri), props)

      // verify cached
      cached := Env.cur.props(uri)
      verifySame(cached, Env.cur.props(uri))
      verifyEq(cached.isImmutable(), true)
      Actor.sleep(10ms)
      verifySame(cached, Env.cur.props(uri, 1ns))

      // rewrite file until we get modified time in file system
      props["foo"] = "bar"
      oldTime := f.modified
      while (f.modified == oldTime) f.writeProps(props)

      // verify with normal maxAge still cached
      verifySame(cached, Env.cur.props(uri))

      // check that we refresh the cache
      newCached := Env.cur.props(uri, 1ns)
      verifyNotSame(cached, newCached)
      verifyEq(cached["foo"], null)
      verifyEq(newCached["foo"], "bar")
    }
    finally
    {
      f.delete
    }
  }

//////////////////////////////////////////////////////////////////////////
// Config
//////////////////////////////////////////////////////////////////////////

  Void testConfig()
  {
    pod := Pod.find("build", false)
    if (pod == null) return
    verifyNotNull(pod.config("buildVersion"))
    verifySame(pod.config("buildVersion"), pod.config("buildVersion"))
    verifyEq(pod.config("buildVersion"), Env.cur.config("build", "buildVersion"))
    verifyEq(pod.config("foo.not.found"), null)
    verifyEq(pod.config("foo.not.found", "?"), "?")
    verifyEq(Env.cur.config("build", "foo.not.found"), null)
    verifyEq(Env.cur.config("build", "foo.not.found", "?"), "?")
  }

}