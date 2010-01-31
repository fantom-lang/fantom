//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Jul 09  Brian Frank  Creation
//

**
** SymbolsTest
**
class SymbolsTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Basics
//////////////////////////////////////////////////////////////////////////

  Void testBasics()
  {
    verifyImmutable(@testSys::boolA, "boolA",  true)
    verifyImmutable(@boolB, "boolB",    false)
    verifyImmutable(@intA, "intA",     0xabcd_0123_eeff_7788)
    verifyImmutable(@intB, "intB",     -4)
    verifyImmutable(@floatA, "floatA",   -5f)
    verifyImmutable(@decimalA, "decimalA", 6.7d)
    verifyImmutable(@durA, "durA",     30ms)
    verifyImmutable(@strA, "strA",     "alpha")
    verifyImmutable(@strB, "strB",     "line1\nline2\nline3_\u02c3_")
    verifyImmutable(@uriA, "uriA",     `http://fantom.org/`)
    verifyImmutable(@numA, "numA",     45,   Num#)
    verifyImmutable(@numB, "numB",     null, Num?#)

    verifyImmutable(@listA, "listA",  ["a", "b", "c"])
    verifyImmutable(@listB, "listB",  [2, 3f, 4d], Num[]#)
    verifyImmutable(@listC, "listC",  [["a"], ["b"], ["c"]])
    verifyMutable(@listD, "listD",    [SerA { i = 0 }, SerA { i = 1 }, SerA { i = 2 }], Obj[]#)

    verifyImmutable(@mapA, "mapA", [0:"zero", 1:"one"])
    verifyMutable(@mapB, "mapB",   [2: SerA { i = 2 }, 3: SerA { i = 3 }])

    verifyImmutable(@serialA, "serialA", Version("2.3"))
    verifyImmutable(@serialB, "serialB", [Version("1"), Version("2")])
    verifyMutable(@serialC, "serialC", SerA { i = 12345; s = "symbols!"}, Obj#)
  }

  Void verifyImmutable(Symbol x, Str name, Obj? val, Type of := Type.of(val))
  {
    verifySymbol(x, name, val, of)
    verifySame(x.defVal, x.defVal)
  }

  Void verifyMutable(Symbol x, Str name, Obj? val, Type of := Type.of(val))
  {
    verifySymbol(x, name, val, of)
    verifyNotSame(x.defVal, x.defVal)
  }

  Void verifySymbol(Symbol x, Str name, Obj? val, Type of := Type.of(val))
  {
    verifyEq(x, Pod.of(this).symbol(name))
    verifySame(x, Pod.of(this).symbol(name))
    verifyEq(x.name, name)
    verifyEq(x.qname, "testSys::$name")
    verifyEq(x.toStr, "@testSys::$name")
    verifySame(x.pod, Pod.of(this))
    verifyEq(x.type, of)
    verifyEq(x.val, val)
    verifyEq(x.defVal, val)
  }

//////////////////////////////////////////////////////////////////////////
// Flags
//////////////////////////////////////////////////////////////////////////

  Void testFlags()
  {
    verifyEq(@intA.isVirtual, true)
    verifyEq(@intB.isVirtual,  false)
  }

//////////////////////////////////////////////////////////////////////////
// IO
//////////////////////////////////////////////////////////////////////////

/* TODO
  Void testIO()
  {
    verifyIO("", Str:Obj?[:])
    verifyIO("foo=5", Str:Obj?["foo":5])
    verifyIO("a=\"hello\"", Str:Obj?["a":"hello"])
    verifyIO("as=\"action-script\"", Str:Obj?["as":"action-script"]) // keyword as name
    verifyIO(
      """using sys
         using testSys
         n=null;   b=true;   i=123456789
         f=12.4f;  d=3.33d;  dur=3min
         uri=`http://fantom.org/`
         str="foo\nbar\u2cd3"
         ver=Version("1.2.3")
         date=Date("2009-07-21")
         listA=[1, 2, null, 4]
         listB=[Depend("sys 1.0"),
                Depend("inet 1.0")]
         // comment
         mapA=[0:"zero", 4:"four"]
         serA=SerA { i = 1972 }
         serList=[SerA { i = 1973; s="a"}, SerA { i = 1974; s="b" }]
         """,
      Str:Obj?[
        "n":null,  "b":true,  "i":123456789,
        "f":12.4f, "d":3.33d, "dur":3min,
        "uri":`http://fantom.org/`,
        "str":"foo\nbar\u2cd3",
        "ver":Version("1.2.3"),
        "date":Date("2009-07-21"),
        "listA":[1, 2, null, 4],
        "listB":[Depend("sys 1.0"), Depend("inet 1.0")],
        "mapA": [0:"zero", 4:"four"],
        "serA": SerA { i = 1972 },
        "serList": [SerA { i = 1973; s="a" }, SerA { i = 1974; s="b" }],
       ])

    verifyErr(IOErr#) { "a=3 b=5".in.readSymbols }
  }

  Void verifyIO(Str s, Str:Obj? expected)
  {
    actual := s.in.readSymbols
    verifyType(actual, [Str:Obj?]#)
    verifyEq(actual, expected)
    verifyEq(Buf().writeSymbols(actual).flip.readSymbols, expected)
  }
*/

//////////////////////////////////////////////////////////////////////////
// Overrides
//////////////////////////////////////////////////////////////////////////
/*
  Void testOverrides()
  {
    // create temp etc/testSys
    f := Env.cur.workDir + `etc/testSys/pod.fansym`
    try
    {
      f.delete
      Repo.readSymbolsCached(`etc/testSys/pod.fansym`, 0ns) // force refresh

      // before override
      verifyEq(@intA.val, 0xabcd_0123_eeff_7788)
      verifyEq(@intA.defVal, 0xabcd_0123_eeff_7788)
      verifyEq(@intB.val, -4)
      verifyEq(@intB.defVal, -4)

      // after override
      f.writeSymbols(["intA":99, "intB": 88])
      Actor.sleep(10ms)
      Repo.readSymbolsCached(`etc/testSys/pod.fansym`, 0ns) // force refresh
      verifyEq(@intA.val, 99)
      verifyEq(@intA.defVal, 0xabcd_0123_eeff_7788)
      verifyEq(@intB.val, -4) // not-virtual
      verifyEq(@intB.defVal, -4)
    }
    finally
    {
      f.delete
    }
  }
*/
}