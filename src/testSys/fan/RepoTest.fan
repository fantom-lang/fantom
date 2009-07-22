//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 09  Brian Frank  Creation
//

**
** RepoTest
**
class RepoTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Basics
//////////////////////////////////////////////////////////////////////////

  Void testBasics()
  {
    verifyEq(Repo.boot, Repo.boot)
    verifyEq(Repo.boot.name, "boot")
    if (Repo.boot !== Repo.working)
      verifyEq(Repo.working.name, "working")

    verifyEq(Repo.list.isImmutable, true)
    verifySame(Repo.list[0], Repo.working)
    verifySame(Repo.list[-1], Repo.boot)

    verifyEq(Repo.boot.home.isDir, true)
    verifyEq(Repo.working.home.isDir, true)
  }

//////////////////////////////////////////////////////////////////////////
// FindFile
//////////////////////////////////////////////////////////////////////////

  Void testFindFile()
  {
    // file
    file := Repo.findFile(`etc/sys/timezones.ftz`)
    verifyEq(file.readAllBuf.readS8, 0x66616e74_7a203032)

    // directories
    verifyEq(Repo.findFile(`etc/sys`).isDir, true)
    verifyEq(Repo.findFile(`etc/sys/`).isDir, true)

    // arg err
    verifyErr(ArgErr#) { Repo.findFile(`/etc/`) }

    // not found
    verifyEq(Repo.findFile(`etc/foo bar/no exist`, false), null)
    verifyErr(IOErr#) { Repo.findFile(`etc/foo bar/no exist`) }
    verifyErr(IOErr#) { Repo.findFile(`etc/foo bar/no exist`, true) }

    // findAllFiles
    verify(Repo.findAllFiles(`etc/sys/timezones.ftz`).size >= 1)
    verifyEq(Repo.findAllFiles(`bad/unknown file`).size, 0)
  }

//////////////////////////////////////////////////////////////////////////
// Read Symbols
//////////////////////////////////////////////////////////////////////////

  Void testReadSymbols()
  {
    uri := `tmp/test/foo.fansym`
    f := Repo.working.home + uri
    try
    {
      symbols := Str:Obj?["a":4, "b":"hi", "c":[2,3,4]]
      f.writeSymbols(symbols)

      verifyEq(Repo.readSymbols(`some-bad-file-foo-bar`), Str:Obj?[:])
      verifyEq(Repo.readSymbols(uri), symbols)
      verifyNotSame(Repo.readSymbols(uri), Repo.readSymbols(uri))

      cached := Repo.readSymbolsCached(uri)
      verifySame(cached, Repo.readSymbolsCached(uri))
      verifyEq(cached.isImmutable(), true)
      Actor.sleep(10ms)
      verifySame(cached, Repo.readSymbolsCached(uri, 1ns))
      symbols["foo"] = "bar"

      f.writeSymbols(symbols);
      Actor.sleep(10ms)
      newCached := Repo.readSymbolsCached(uri, 1ns)
      verifyNotSame(cached, newCached)
      verifyEq(cached["foo"], null)
      verifyEq(newCached["foo"], "bar")
    }
    finally
    {
      f.delete
    }
  }

}