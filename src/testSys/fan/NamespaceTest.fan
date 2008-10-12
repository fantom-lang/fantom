//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   04 Mar 08  Brian Frank  Creation
//

**
** NamespaceTest
**
class NamespaceTest : Test
{

  Void testRoot()
  {
    verifyEq(Sys.ns.type.name, "RootNamespace")
    verifyEq(Sys.ns is Namespace, true)
    verifyEq(Sys.ns.type.base, Namespace#)
    verifyEq(Sys.ns.uri, `/`)

    verifyEq(Sys.ns(`/sys`).type.qname, "sys::SysNamespace")
    verifyErr(ArgErr#) |,| { Sys.mount(`/sys`, TestNamespace.make) }

    verifyErr(ArgErr#) |,| { Sys.ns.get(`fan:/sys/foo`) }
    verifyErr(ArgErr#) |,| { Sys.ns.create(`fan:/sys/foo`, "x") }
    verifyErr(ArgErr#) |,| { Sys.ns.put(`fan:/sys/foo`, "x") }
    verifyErr(ArgErr#) |,| { Sys.ns.delete(`fan:/sys/foo`) }
  }

  Void testRootCrud()
  {
    // get unresolved
    verifyEq(Sys.ns.get(`/test/foo`, false), null)
    verifyErr(UnresolvedErr#) |,| { Sys.ns.get(`/test/foo`) }
    verifyErr(UnresolvedErr#) |,| { Sys.ns.get(`/test/foo`, true) }
    verifyEq(`fan:/test/foo`.get(null, false), null)
    verifyErr(UnresolvedErr#) |,| { `fan:/test/foo`.get }
    verifyErr(UnresolvedErr#) |,| { `fan:/test/foo`.get(null, true) }

    // put, delete unresolved
    verifyErr(UnresolvedErr#) |,| { Sys.ns.put(`/test/foo`, "bad") }
    verifyErr(UnresolvedErr#) |,| { Sys.ns.get(`/test/foo`) }
    verifyErr(UnresolvedErr#) |,| { Sys.ns.delete(`/test/foo`) }
    verifyErr(UnresolvedErr#) |,| { Sys.ns.get(`/test/foo`) }

    // create
    verifySame(Sys.ns.create(`/test/foo`, "star blazers"), `/test/foo`)
    verifyEq(Sys.ns.get(`/test/foo`), "star blazers")
    verifyEq(Sys.ns.get(`/test/foo`, true), "star blazers")
    verifyEq(Sys.ns.get(`/test/foo`, false), "star blazers")
    verifyEq(`fan:/test/foo`.get, "star blazers")
    verifyEq(`fan:/test/foo`.get(null, true), "star blazers")
    verifyEq(`fan:/test/foo`.get(null, false), "star blazers")

    // auto-id
    uriA := Sys.ns.create(null, "gamilon")
    uriB := Sys.ns.create(null, "comet empire")
    verifyEq(Sys.ns[uriA], "gamilon")
    verifyEq(Sys.ns[uriB], "comet empire")

    // put
    Sys.ns.put(`/test/foo`, 1972)
    verifyEq(Sys.ns.get(`/test/foo`), 1972)

    // delete
    Sys.ns.delete(`/test/foo`)
    verifyEq(Sys.ns.get(`/test/foo`, false), null)
    verifyErr(UnresolvedErr#) |,| { Sys.ns.get(`/test/foo`) }

    // immutable create
    immutable := ["a", "b", "c"].toImmutable
    Sys.ns.create(`/test/immutable`, immutable)
    verifySame(Sys.ns[`/test/immutable`], immutable)

    // immutable put
    now := DateTime.now
    Sys.ns.put(`/test/immutable`, now)
    verifySame(Sys.ns[`/test/immutable`], now)

    // serialized create
    mutable := ["a", [0, 1, 2], "b"]
    Sys.ns.create(`/test/mutable`, mutable)
    verifyNotSame(Sys.ns[`/test/mutable`], mutable)
    verifyEq(Sys.ns[`/test/mutable`], mutable)
    verifyEq(Sys.ns[`/test/mutable`]->get(0), "a")
    verifyEq(Sys.ns[`/test/mutable`]->get(1), [0, 1, 2])
    verifyEq(Sys.ns[`/test/mutable`]->get(2), "b")

    // check thread-safe copy is used
    mutable[1] = 8ms
    verifyNotEq(Sys.ns[`/test/mutable`], mutable)
    verifyEq(Sys.ns[`/test/mutable`]->get(0), "a")
    verifyEq(Sys.ns[`/test/mutable`]->get(1), [0, 1, 2])
    verifyEq(Sys.ns[`/test/mutable`]->get(2), "b")
    Sys.ns[`/test/mutable`]->set(2, "x")
    verifyEq(Sys.ns[`/test/mutable`]->get(2), "b")

    // serialized put
    Sys.ns.put(`/test/mutable`, mutable)
    mutable[0] = "!"
    verifyNotEq(Sys.ns[`/test/mutable`], mutable)
    verifyEq(Sys.ns[`/test/mutable`]->get(0), "a")
    verifyEq(Sys.ns[`/test/mutable`]->get(1), 8ms)
    verifyEq(Sys.ns[`/test/mutable`]->get(2), "b")
  }

  Void testMounts()
  {
    root := Sys.ns
    a := TestNamespace.make
    b := TestNamespace.make
    c := TestNamespace.make
    d := TestNamespace.make

    verifyEq(a.uri, null)
    verifyErr(ArgErr#) |,| { Sys.mount(`http://foo/`, a) }
    verifyErr(ArgErr#) |,| { Sys.mount(`http://foo/x`, a) }
    verifyErr(ArgErr#) |,| { Sys.mount(``, a) }
    verifyErr(ArgErr#) |,| { Sys.mount(`a`, a) }
    verifyErr(ArgErr#) |,| { Sys.mount(`/a?q`, a) }
    verifyErr(ArgErr#) |,| { Sys.mount(`/a#f`, a) }
    Sys.mount(`/testns`, a)
    verifyEq(a.uri, `/testns`)
    verifyErr(ArgErr#) |,| { Sys.mount(`/testns`, a) }
    verifyErr(ArgErr#) |,| { Sys.mount(`/testns`, b) }

    Sys.mount(`/testns/foo`, b)
    Sys.mount(`/testns/foo/wack`, c)
    Sys.mount(`/testns/bar/wack`, d)

    verifySame(Sys.ns(`/foo`), root)
    verifySame(Sys.ns(`/testns`), a)
    verifySame(Sys.ns(`/testns/`), a)
    verifySame(Sys.ns(`/testnsx`), root)
    verifySame(Sys.ns(`/testns/f`), a)
    verifySame(Sys.ns(`/testns/foo`), b)
    verifySame(Sys.ns(`/testns/foox`), a)
    verifySame(Sys.ns(`/testns/foo/x`), b)
    verifySame(Sys.ns(`/testns/foo?x`), b)
    verifySame(Sys.ns(`/testns/foo/a/b/c`), b)
    verifySame(Sys.ns(`/testns/foo/wack`), c)
    verifySame(Sys.ns(`/testns/foo/wack#frag`), c)
    verifySame(Sys.ns(`/testns/bar`), a)
    verifySame(Sys.ns(`/testns/barx`), a)
    verifySame(Sys.ns(`/testns/bar/x`), a)
    verifySame(Sys.ns(`/testns/bar/wack`), d)
    verifySame(Sys.ns(`/testns/bar/wackx`), a)
    verifySame(Sys.ns(`/testns/bar/wack/x`), d)
    verifySame(Sys.ns(`/testns/bar/wack/x/y/z?q`), d)

    Sys.unmount(a.uri)
    Sys.unmount(b.uri)
    Sys.unmount(c.uri)
    Sys.unmount(d.uri)
    verifyEq(a.uri, null)
    verifyErr(UnresolvedErr#) |,| { Sys.unmount(`/testns`) }
  }

  Void testMountCrud()
  {
    Sys.mount(`/testns`, TestNamespace.make)

    verifyEq(Sys.ns.get(`/testns`, false), null)
    verifyErr(UnresolvedErr#) |,| { Sys.ns.get(`/testns`) }
    verifyErr(UnresolvedErr#) |,| { Sys.ns.get(`/testns`, true) }

    // get
    Thread.locals["/testns"] = "argo"
    Thread.locals["/testns/wildstar"] = ["derek", "wildstar"]
    verifyEq(Sys.ns.get(`/testns`), "argo")
    verifyEq(Sys.ns.get(`/testns/wildstar`), ["derek", "wildstar"])

    // create
    verifyEq(Sys.ns.create(`/testns/venture`, "mark"), `/testns/venture`)
    verifyEq(Thread.locals["/testns/venture"], "mark")
    verifyEq(Sys.ns[`/testns/venture`], "mark")

    // put
    Sys.ns.put(`/testns/venture`, "Mark Venture")
    verifyEq(Thread.locals["/testns/venture"], "Mark Venture")
    verifyEq(Sys.ns[`/testns/venture`], "Mark Venture")

    // delete
    Sys.ns.delete(`/testns/venture`)
    verifyEq(Thread.locals["/testns/venture"], null)
    verifyErr(UnresolvedErr#) |,| { Sys.ns.get(`/testns/venture`) }

    Sys.unmount(`/testns`)
  }

  Void testMountDir()
  {
    (tempDir+`file.txt`).out.print("hi!").close;
    (tempDir+`dir1/dir2/file.txt`).create.out.print("deep").close

    Sys.mount(`/testdir`, Namespace.makeDir(tempDir))

    File f := `fan:/testdir/file.txt`.get
    verifyEq(f.readAllStr, "hi!")

    f = `fan:/testdir/dir1/dir2/file.txt`.get
    verifyEq(f.readAllStr, "deep")

    Sys.unmount(`/testdir`)
  }

}

const class TestNamespace : Namespace
{

  override Obj? get(Uri uri, Bool checked := true)
  {
    x := Thread.locals[uri.toStr]
    if (x != null) return x
    if (!checked) return null
    throw UnresolvedErr.make(uri.toStr)
  }

  override Uri create(Uri? uri, Obj obj)
  {
    Thread.locals[uri.toStr] = obj
    return uri
  }

  override Void put(Uri uri, Obj obj)
  {
    Thread.locals[uri.toStr] = obj
  }

  override Void delete(Uri uri)
  {
    Thread.locals.remove(uri.toStr)
  }

}