//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   04 Mar 08  Brian Frank  Creation
//

**
** UriSpaceTest
**
class UriSpaceTest : Test
{

  Void testRoot()
  {
    verifyEq(Type.of(UriSpace.root).name, "RootUriSpace")
    verifyEq(UriSpace.root is UriSpace, true)
    verifyEq(Type.of(UriSpace.root).base, UriSpace#)
    verifyEq(UriSpace.root.uri, `/`)

    verifyEq(Type.of(UriSpace.find(`/sys`)).qname, "sys::SysUriSpace")
    verifyErr(ArgErr#) { UriSpace.mount(`/sys`, TestUriSpace.make) }

    verifyErr(ArgErr#) { UriSpace.root.get(`fan:/sys/foo`) }
    verifyErr(ArgErr#) { UriSpace.root.create(`fan:/sys/foo`, "x") }
    verifyErr(ArgErr#) { UriSpace.root.put(`fan:/sys/foo`, "x") }
    verifyErr(ArgErr#) { UriSpace.root.delete(`fan:/sys/foo`) }
  }

  Void testRootCrud()
  {
    // get unresolved
    verifyEq(UriSpace.root.get(`/test/foo`, false), null)
    verifyErr(UnresolvedErr#) { UriSpace.root.get(`/test/foo`) }
    verifyErr(UnresolvedErr#) { UriSpace.root.get(`/test/foo`, true) }
    verifyEq(`fan:/test/foo`.get(null, false), null)
    verifyErr(UnresolvedErr#) { `fan:/test/foo`.get }
    verifyErr(UnresolvedErr#) { `fan:/test/foo`.get(null, true) }

    // put, delete unresolved
    verifyErr(UnresolvedErr#) { UriSpace.root.put(`/test/foo`, "bad") }
    verifyErr(UnresolvedErr#) { UriSpace.root.get(`/test/foo`) }
    verifyErr(UnresolvedErr#) { UriSpace.root.delete(`/test/foo`) }
    verifyErr(UnresolvedErr#) { UriSpace.root.get(`/test/foo`) }

    // create
    verifySame(UriSpace.root.create(`/test/foo`, "star blazers"), `/test/foo`)
    verifyEq(UriSpace.root.get(`/test/foo`), "star blazers")
    verifyEq(UriSpace.root.get(`/test/foo`, true), "star blazers")
    verifyEq(UriSpace.root.get(`/test/foo`, false), "star blazers")
    verifyEq(`fan:/test/foo`.get, "star blazers")
    verifyEq(`fan:/test/foo`.get(null, true), "star blazers")
    verifyEq(`fan:/test/foo`.get(null, false), "star blazers")

    // auto-id
    uriA := UriSpace.root.create(null, "gamilon")
    uriB := UriSpace.root.create(null, "comet empire")
    verifyEq(UriSpace.root[uriA], "gamilon")
    verifyEq(UriSpace.root[uriB], "comet empire")

    // put
    UriSpace.root.put(`/test/foo`, 1972)
    verifyEq(UriSpace.root.get(`/test/foo`), 1972)

    // delete
    UriSpace.root.delete(`/test/foo`)
    verifyEq(UriSpace.root.get(`/test/foo`, false), null)
    verifyErr(UnresolvedErr#) { UriSpace.root.get(`/test/foo`) }

    // immutable create
    immutable := ["a", "b", "c"].toImmutable
    UriSpace.root.create(`/test/immutable`, immutable)
    verifySame(UriSpace.root[`/test/immutable`], immutable)

    // immutable put
    now := DateTime.now
    UriSpace.root.put(`/test/immutable`, now)
    verifySame(UriSpace.root.get(`/test/immutable`), now)

    // serialized create
    mutable := ["a", [0, 1, 2], "b"]
    UriSpace.root.create(`/test/mutable`, mutable)
    verifyNotSame(UriSpace.find(`/test/mutable`), mutable)
    verifyEq(UriSpace.root.get(`/test/mutable`), mutable)
    verifyEq(UriSpace.root.get(`/test/mutable`)->get(0), "a")
    verifyEq(UriSpace.root.get(`/test/mutable`)->get(1), [0, 1, 2])
    verifyEq(UriSpace.root.get(`/test/mutable`)->get(2), "b")

    // check thread-safe copy is used
    mutable[1] = 8ms
    verifyNotEq(UriSpace.root.get(`/test/mutable`), mutable)
    verifyEq(UriSpace.root.get(`/test/mutable`)->get(0), "a")
    verifyEq(UriSpace.root.get(`/test/mutable`)->get(1), [0, 1, 2])
    verifyEq(UriSpace.root.get(`/test/mutable`)->get(2), "b")
    UriSpace.root.get(`/test/mutable`)->set(2, "x")
    verifyEq(UriSpace.root.get(`/test/mutable`)->get(2), "b")

    // serialized put
    UriSpace.root.put(`/test/mutable`, mutable)
    mutable[0] = "!"
    verifyNotEq(UriSpace.root.get(`/test/mutable`), mutable)
    verifyEq(UriSpace.root.get(`/test/mutable`)->get(0), "a")
    verifyEq(UriSpace.root.get(`/test/mutable`)->get(1), 8ms)
    verifyEq(UriSpace.root.get(`/test/mutable`)->get(2), "b")
  }

  Void testMounts()
  {
    root := UriSpace.root
    a := TestUriSpace.make
    b := TestUriSpace.make
    c := TestUriSpace.make
    d := TestUriSpace.make

    verifyEq(a.uri, null)
    verifyErr(ArgErr#) { UriSpace.mount(`http://foo/`, a) }
    verifyErr(ArgErr#) { UriSpace.mount(`http://foo/x`, a) }
    verifyErr(ArgErr#) { UriSpace.mount(``, a) }
    verifyErr(ArgErr#) { UriSpace.mount(`a`, a) }
    verifyErr(ArgErr#) { UriSpace.mount(`/a?q`, a) }
    verifyErr(ArgErr#) { UriSpace.mount(`/a#f`, a) }
    UriSpace.mount(`/testns`, a)
    verifyEq(a.uri, `/testns`)
    verifyErr(ArgErr#) { UriSpace.mount(`/testns`, a) }
    verifyErr(ArgErr#) { UriSpace.mount(`/testns`, b) }

    UriSpace.mount(`/testns/foo`, b)
    UriSpace.mount(`/testns/foo/wack`, c)
    UriSpace.mount(`/testns/bar/wack`, d)

    verifySame(UriSpace.find(`/foo`), root)
    verifySame(UriSpace.find(`/testns`), a)
    verifySame(UriSpace.find(`/testns/`), a)
    verifySame(UriSpace.find(`/testnsx`), root)
    verifySame(UriSpace.find(`/testns/f`), a)
    verifySame(UriSpace.find(`/testns/foo`), b)
    verifySame(UriSpace.find(`/testns/foox`), a)
    verifySame(UriSpace.find(`/testns/foo/x`), b)
    verifySame(UriSpace.find(`/testns/foo?x`), b)
    verifySame(UriSpace.find(`/testns/foo/a/b/c`), b)
    verifySame(UriSpace.find(`/testns/foo/wack`), c)
    verifySame(UriSpace.find(`/testns/foo/wack#frag`), c)
    verifySame(UriSpace.find(`/testns/bar`), a)
    verifySame(UriSpace.find(`/testns/barx`), a)
    verifySame(UriSpace.find(`/testns/bar/x`), a)
    verifySame(UriSpace.find(`/testns/bar/wack`), d)
    verifySame(UriSpace.find(`/testns/bar/wackx`), a)
    verifySame(UriSpace.find(`/testns/bar/wack/x`), d)
    verifySame(UriSpace.find(`/testns/bar/wack/x/y/z?q`), d)

    UriSpace.unmount(a.uri)
    UriSpace.unmount(b.uri)
    UriSpace.unmount(c.uri)
    UriSpace.unmount(d.uri)
    verifyEq(a.uri, null)
    verifyErr(UnresolvedErr#) { UriSpace.unmount(`/testns`) }
  }

  Void testMountCrud()
  {
    UriSpace.mount(`/testns`, TestUriSpace.make)

    verifyEq(UriSpace.root.get(`/testns`, false), null)
    verifyErr(UnresolvedErr#) { UriSpace.root.get(`/testns`) }
    verifyErr(UnresolvedErr#) { UriSpace.root.get(`/testns`, true) }

    // get
    Actor.locals["/testns"] = "argo"
    Actor.locals["/testns/wildstar"] = ["derek", "wildstar"]
    verifyEq(UriSpace.root.get(`/testns`), "argo")
    verifyEq(UriSpace.root.get(`/testns/wildstar`), ["derek", "wildstar"])

    // create
    verifyEq(UriSpace.root.create(`/testns/venture`, "mark"), `/testns/venture`)
    verifyEq(Actor.locals["/testns/venture"], "mark")
    verifyEq(UriSpace.root[`/testns/venture`], "mark")

    // put
    UriSpace.root.put(`/testns/venture`, "Mark Venture")
    verifyEq(Actor.locals["/testns/venture"], "Mark Venture")
    verifyEq(UriSpace.root[`/testns/venture`], "Mark Venture")

    // delete
    UriSpace.root.delete(`/testns/venture`)
    verifyEq(Actor.locals["/testns/venture"], null)
    verifyErr(UnresolvedErr#) { UriSpace.root.get(`/testns/venture`) }

    UriSpace.unmount(`/testns`)
  }

  Void testMountDir()
  {
    (tempDir+`file.txt`).out.print("hi!").close;
    (tempDir+`dir1/dir2/file.txt`).create.out.print("deep").close

    UriSpace.mount(`/testdir`, UriSpace.makeDir(tempDir))

    File f := `fan:/testdir/file.txt`.get
    verifyEq(f.readAllStr, "hi!")

    f = `fan:/testdir/dir1/dir2/file.txt`.get
    verifyEq(f.readAllStr, "deep")

    UriSpace.unmount(`/testdir`)
  }

}

const class TestUriSpace : UriSpace
{

  override Obj? get(Uri uri, Bool checked := true)
  {
    x := Actor.locals[uri.toStr]
    if (x != null) return x
    if (!checked) return null
    throw UnresolvedErr.make(uri.toStr)
  }

  override Uri create(Uri? uri, Obj obj)
  {
    Actor.locals[uri.toStr] = obj
    return uri
  }

  override Void put(Uri uri, Obj obj)
  {
    Actor.locals[uri.toStr] = obj
  }

  override Void delete(Uri uri)
  {
    Actor.locals.remove(uri.toStr)
  }

}