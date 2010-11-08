//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Oct 06  Brian Frank  Creation
//

using concurrent

**
** EnvTest
**
@Js
class EnvTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Setup/Cleanup
//////////////////////////////////////////////////////////////////////////

  File etcDir() { Env.cur.workDir + `etc/testSys/` }

  override Void teardown()
  {
    etcDir.delete
  }

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
    verifyErr(UnresolvedErr#) { Env.cur.findFile(`etc/foo bar/no exist`) }
    verifyErr(UnresolvedErr#) { Env.cur.findFile(`etc/foo bar/no exist`, true) }

    // findAllFiles
    verify(Env.cur.findAllFiles(`etc/sys/timezones.ftz`).size >= 1)
    verifyEq(Env.cur.findAllFiles(`bad/unknown file`).size, 0)
  }

//////////////////////////////////////////////////////////////////////////
// Props
//////////////////////////////////////////////////////////////////////////

  Void testProps()
  {
    pod := typeof.pod
    uri := `foo/bar.props`
    f := etcDir + uri
    try
    {
      props := ["a":"alpha", "b":"beta"]
      f.writeProps(props)

      // verify basics
      verifyEq(Env.cur.props(pod, `some-bad-file-foo-bar`, 1min), Str:Str[:])
      verifyEq(Env.cur.props(pod, uri, 1min), props)

      // verify cached
      cached := Env.cur.props(pod, uri, 1min)
      verifySame(cached, Env.cur.props(pod, uri, 1min))
      verifyEq(cached.isImmutable(), true)
      Actor.sleep(10ms)
      verifySame(cached, Env.cur.props(pod, uri, 1ns))

      // rewrite file until we get modified time in file system
      props["foo"] = "bar"
      oldTime := f.modified
      while (f.modified == oldTime) f.writeProps(props)

      // verify with normal maxAge still cached
      verifySame(cached, Env.cur.props(pod, uri, 1min))

      // check that we refresh the cache
      newCached := Env.cur.props(pod, uri, 1ns)
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
    verifyEq(pod.config("buildVersion"), Env.cur.config(pod, "buildVersion"))
    verifyEq(pod.config("foo.not.found"), null)
    verifyEq(pod.config("foo.not.found", "?"), "?")
    verifyEq(Env.cur.config(pod, "foo.not.found"), null)
    verifyEq(Env.cur.config(pod, "foo.not.found", "?"), "?")
  }

//////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

  Void testLocale()
  {
    f1 := etcDir + `locale/en.props`
    f2 := etcDir + `locale/en-US.props`
    try
    {
      f1.writeProps(["e":"e en etc", "f":"f en etc"])
      f2.writeProps(["f":"f en-US etc"])

      x := Locale.fromStr("en")
      verifyLocale(x, "a", "a en")
      verifyLocale(x, "b", "b en")
      verifyLocale(x, "c", "c en")
      verifyLocale(x, "d", "d en")
      verifyLocale(x, "e", "e en etc")
      verifyLocale(x, "f", "f en etc")
      verifyLocale(x, "x", null)

      x = Locale.fromStr("en-US")
      verifyLocale(x, "a", "a en-US")
      verifyLocale(x, "b", "b en")
      verifyLocale(x, "c", "c en")
      verifyLocale(x, "d", "d en")
      verifyLocale(x, "e", "e en etc")
      verifyLocale(x, "f", "f en-US etc")
      verifyLocale(x, "x", null)

      x = Locale.fromStr("es")
      verifyLocale(x, "a", "a es")
      verifyLocale(x, "b", "b es")
      verifyLocale(x, "c", "c es")
      verifyLocale(x, "d", "d en")
      verifyLocale(x, "e", "e es")
      verifyLocale(x, "f", "f en etc")
      verifyLocale(x, "x", null)

      x = Locale.fromStr("es-MX")
      verifyLocale(x, "a", "a es-MX")
      verifyLocale(x, "b", "b es")
      verifyLocale(x, "c", "c es")
      verifyLocale(x, "d", "d en")
      verifyLocale(x, "e", "e es")
      verifyLocale(x, "f", "f en etc")
      verifyLocale(x, "x", null)

      x = Locale.fromStr("fr-CA")
      verifyLocale(x, "a", "a en")
      verifyLocale(x, "b", "b en")
      verifyLocale(x, "c", "c en")
      verifyLocale(x, "d", "d en")
      verifyLocale(x, "e", "e en etc")
      verifyLocale(x, "f", "f en etc")
    }
    finally
    {
      f1.delete
      f2.delete
    }
  }

  Void verifyLocale(Locale loc, Str key, Str? expected)
  {
    // Env.cur.locale using explicit locale
    pod := typeof.pod
    verifyEq(Env.cur.locale(pod, key, null, loc), expected)
    verifyEq(Env.cur.locale(pod, key, "?!#", loc), expected ?: "?!#")

    // Locale.cur
    loc.use
    {
      if (expected != null)
      {
        verifyEq(pod.locale(key), expected)
        verifyEq(pod.locale(key, "@%#"), expected)
        verifyEq(Env.cur.locale(pod, key), expected)
        verifyEq(Env.cur.locale(pod, key, "@%#"), expected)
      }
      else
      {
        verifyEq(pod.locale(key), "testSys::" + key)
        verifyEq(pod.locale(key, "@%#"), "@%#")
        verifyEq(Env.cur.locale(pod, key), "testSys::" + key)
        verifyEq(Env.cur.locale(pod, key, "!#!"), "!#!")
      }
    }
  }

  Void testLocaleLiterals()
  {
    Locale("en").use
    {
      // existing key
      verifyEq("$<a>", "a en")
      verifyEq("_$<a>", "_a en")
      verifyEq("_$<a>_", "_a en_")
      verifyEq("$<a>_", "a en_")
    }

    Locale("es-MX").use
    {
      // existing key
      var := "hi!"
      verifyEq("$<a>", "a es-MX")
      verifyEq("${var}_$<b>", "hi!_b es")
      verifyEq("_$<c>_", "_c es_")
      verifyEq("$<d>_$var", "d en_hi!")

      // qualified
      verifyEq("$<testSys::a>", "a es-MX")
      verifyEq("_$<testSys::b>", "_b es")
      verifyEq("_$<testSys::c>_", "_c es_")
      verifyEq("$<testSys::d>_", "d en_")
    }

    // with definition
    verifyEq("$<envTest.def1=Def 1>",    "Def 1")
    verifyEq("$<envTest.def1>",          "Def 1")
    verifyEq("$<testSys::envTest.def1>", "Def 1")
    verifyEq(typeof.pod.locale("envTest.def1"), "Def 1")

    verifyEq("$<envTest.def2=Def 2\nLine 2 75 \u00B0 F>", "Def 2\nLine 2 75 \u00B0 F")
    verifyEq(typeof.pod.locale("envTest.def2"),           "Def 2\nLine 2 75 \u00B0 F")
  }

//////////////////////////////////////////////////////////////////////////
// Index
//////////////////////////////////////////////////////////////////////////

  Void testIndex()
  {
    verifyIndex("testSys.bad", Str[,])
    verifyIndex("testSys.single", ["works!"])

    mult := ["testSys-1", "testSys-2"]
    if (Pod.find("testNative", false) != null) mult.add("testNative")
    verifyIndex("testSys.mult", mult)
  }

  Void verifyIndex(Str key, Str[] expected)
  {
    actual := Env.cur.index(key)
    // echo("==> $key  $actual  ?=  $expected")
    verifyEq(actual.dup.sort, expected.sort)
    verifyEq(actual.isImmutable, true)
    verifyEq(actual.typeof, Str[]#)
    verifySame(actual, Env.cur.index(key))
  }

}