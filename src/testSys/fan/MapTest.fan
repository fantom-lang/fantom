//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Mar 06  Brian Frank  Creation
//

**
** MapTest
**
class MapTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Equal
//////////////////////////////////////////////////////////////////////////

  Void testEquals()
  {
    verifyEq([:], [:])
    verifyEq([0:null], [0:null])
    verifyEq([0:"a"], [0:"a"])

    verifyEq([:].hash, [:].hash)
    verifyEq([0:null].hash, [0:null].hash)
    verifyEq([0:"a"].hash, [0:"a"].hash)

    verifyNotEq([:], [0:"a"])
    verifyNotEq([0:"a"], [:])
    verifyNotEq([0:"a"], [0:null])
    verifyNotEq([0:"a"], ["f":"a"])
    verifyNotEq([0:"a"], [0:3])
    verifyNotEq([:], Str:Str[:])
    verifyNotEq([:], null)
    verifyNotEq([0:"0"], [0:"x"])
    verifyNotEq([0:"0"], [0:"x"])
    verifyNotEq([0:"0"], "hello")
  }

//////////////////////////////////////////////////////////////////////////
// Type
//////////////////////////////////////////////////////////////////////////

  Void testType()
  {
    verifyEq(Int:Str#, Int:Str#)
    verifyNotEq(Int:Str#, Int:Obj#)
    verifyNotEq(Int:Str#, Obj:Str#)
    verifyNotEq(Int:Str#, [:].type)
  }

//////////////////////////////////////////////////////////////////////////
// Is Operator
//////////////////////////////////////////////////////////////////////////

  Void testIsExplicit()
  {
    // Obj:Obj
    Obj a := Obj:Obj[:]
    verify(a is Obj)
    verify(a is Map)
    verify(a is Obj:Obj)
    verify(a is Obj:Obj)
    verifyFalse(a is Str)
    verifyFalse(a is Str:Obj)
    verifyFalse(a is Obj:Str)

    // Int:Str - empty
    Obj b := Str:Int[:]
    verify(b is Obj)
    verify(b is Map)
    verify(b is Obj:Obj)
    verify(b is Obj:Int)
    verify(b is Str:Obj)
    verify(b is Str:Int)
    verifyFalse(b is Str)
    verifyFalse(b is Str[])
    verifyFalse(b is Str:Str)

    // Int:Str - with values
    Obj c := Int:Str[2:"b"]
    verifyFalse(c is Str:Str)

    // Str:Field
    Obj d := Str:Field[:]
    verify(d is Obj)
    verify(d is Str:Obj)
    verify(d is Str:Slot)
    verify(d is Str:Field)
  }

  Void testIsInfered()
  {
    // empty Obj[Obj]
    Obj a := [:]
    verify(a is Obj:Obj)
    verifyEq(a.type, Obj:Obj#)

    // inferred Obj:Obj
    Obj b := [2:"two", "three":3]
    verify(b is Obj:Obj)
    verifyEq(b.type, Obj:Obj#)

    // inferred Int:Str
    Obj c := [3:"c"]
    verify(c is Obj)
    verify(c is Int:Str)
    verify(c is Num:Str)
    verify(c is Num:Obj)
    verify(c is Obj:Obj)
    verifyEq(c.type, Int:Str#)
    verifyEq([3 : null , 4 : "d"].type, Int:Str#)   // null

    Obj d := [3:"c"]
    verifyNotEq(d.type, Obj:Str#)
    verifyNotEq(d.type, Int:Obj#)
    verifyNotEq(d.type, Sys:Bool#)
  }

//////////////////////////////////////////////////////////////////////////
// As Operator
//////////////////////////////////////////////////////////////////////////

  Void testAsExplicit()
  {
    Obj x := [:]

    Obj o    := x as Obj;          verifySame(o , x)
    Bool b   := x as Bool;         verifySame(b , null)
    Str s    := x as Str;          verifySame(s , null)
    Map m    := x as Map;          verifySame(m , x)
    Obj:Obj  ol := x as Obj:Obj;   verifySame(ol , x)
    Obj:Int  il := x as Int:Int;   verifySame(il , null)
    Int:Str  sl := x as Int:Str;   verifySame(sl , null)

    x  = [0:"a", 1:"b"]
    o  = x as Obj;       verifySame(o , x)
    b  = x as Bool;      verifySame(b , null)
    s  = x as Str;       verifySame(s , null)
    m  = x as Map;       verifySame(m , x)
    ol = x as Obj:Obj;   verifySame(ol , x)
    il = x as Str:Int;   verifySame(il , null)
    sl = x as Int:Str;   verifySame(sl , x)
  }

//////////////////////////////////////////////////////////////////////////
// Reflection
//////////////////////////////////////////////////////////////////////////

  Void testReflect()
  {
    a := [:]
    verifyEq(a.type.base,      Map#)
    verifyEq(a.type.base.base, Obj#)
    verifyEq(a.type.pod.name,  "sys")
    verifyEq(a.type.name,      "Map")
    verifyEq(a.type.qname,     "sys::Map")
    verifyEq(a.type.signature, "[sys::Obj:sys::Obj]")
    verifyEq(a.type.toStr,     "[sys::Obj:sys::Obj]")
    verifyEq(a.type.method("isEmpty").returns,  Bool#)
    verifyEq(a.type.method("get").returns,      Obj#)
    verifyEq(a.type.method("get").params[0].of, Obj#)
    verifyEq(a.type.method("set").returns,      Obj:Obj#)
    verifyEq(a.type.method("set").params[0].of, Obj#)
    verifyEq(a.type.method("set").params[1].of, Obj#)
    verifyEq(a.type.method("each").params[0].of, |Obj v, Obj k->Void|#)
    verifyNotEq(a.type.method("each").params[0].of, |Str v, Obj k->Void|#)

    b := [0:"zero"]
    verifyEq(b.type.base,      Map#)
    verifyEq(b.type.base.base, Obj#)
    verifyEq(b.type.pod.name,  "sys")
    verifyEq(b.type.name,      "Map")
    verifyEq(b.type.qname,     "sys::Map")
    verifyEq(b.type.signature, "[sys::Int:sys::Str]")
    verifyEq(b.type.toStr,     "[sys::Int:sys::Str]")
    verifyEq(b.type.method("isEmpty").returns,  Bool#)
    verifyEq(b.type.method("get").returns,      Str#)
    verifyEq(b.type.method("get").params[0].of, Int#)
    verifyEq(b.type.method("set").returns,      Int:Str#)
    verifyEq(b.type.method("set").params[0].of, Int#)
    verifyEq(b.type.method("set").params[1].of, Str#)
    verifyEq(b.type.method("keys").returns,     Int[]#)
    verifyEq(b.type.method("values").returns,   Str[]#)
    verifyEq(b.type.method("each").params[0].of, |Str v, Int k->Void|#)
    verifyNotEq(b.type.method("each").params[0].of, |Obj v, Int i->Void|#)

    c := [ArgErr.make:[0,1,2]]
    verifyEq(c.type.base,      Map#)
    verifyEq(c.type.base.base, Obj#)
    verifyEq(c.type.pod.name,  "sys")
    verifyEq(c.type.name,      "Map")
    verifyEq(c.type.qname,     "sys::Map")
    verifyEq(c.type.signature, "[sys::ArgErr:sys::Int[]]")
    verifyEq(c.type.toStr,     "[sys::ArgErr:sys::Int[]]")
    verifyEq(c.type.method("isEmpty").returns,   Bool#)
    verifyEq(c.type.method("get").returns,       Int[]#)
    verifyEq(c.type.method("get").params[0].of,  ArgErr#)
    verifyEq(c.type.method("set").returns,       ArgErr:Int[]#)
    verifyEq(c.type.method("set").returns,       [ArgErr:Int[]]#)
    verifyEq(c.type.method("set").params[0].of,  ArgErr#)
    verifyEq(c.type.method("set").params[1].of,  Int[]#)
    verifyEq(c.type.method("keys").returns,      ArgErr[]#)
    verifyEq(c.type.method("values").returns,    Int[][]#)
    verifyEq(c.type.method("each").params[0].of, |Int[] v, ArgErr k->Void|#)
  }

//////////////////////////////////////////////////////////////////////////
// Add/Remove
//////////////////////////////////////////////////////////////////////////

  Void testItems()
  {
    m := Int:Str[:]
    verifyEq(m, Int:Str[:])
    verifyEq(m[0], null)
    verify(m.isEmpty)
    verify(m.get(null) == null)
    verifyFalse(m.containsKey(null))

    m[5] = "five"
    verifyEq(m, [5:"five"])
    verifyEq(m[0], null)
    verifyEq(m[5], "five")
    verifyEq(m.get(5), "five")
    verifyEq(m.get(3), null)
    verifyEq(m.get(3, "?"), "?")
    verifyFalse(m.isEmpty)

    m[9] = "nine"
    verifyEq(m, [5:"five", 9:"nine"])
    verifyEq(m[0], null)
    verifyEq(m[5], "five")
    verifyEq(m[9], "nine")
    verifyFalse(m.isEmpty)

    m.add(2, "two")
    verifyEq(m, [2:"two", 5:"five", 9:"nine"])
    verifyEq(m[0], null)
    verifyEq(m[2], "two")
    verifyEq(m[5], "five")
    verifyEq(m[9], "nine")
    verifyErr(ArgErr#) |,| { m.add(2, "err") }
    verifyEq(m[2], "two")

    m[9] = null
    verifyEq(m, [2:"two", 5:"five", 9:null])
    verifyEq(m[0], null)
    verifyEq(m[2], "two")
    verifyEq(m[5], "five")
    verifyEq(m[9], null)
    verifyEq(m.get(0, "?"), "?")
    verifyEq(m.get(2, "?"), "two")
    verifyEq(m.get(9, "?"), "?") // mapped, but null returns def

    m.add(9, "nine") // add overwrites null
    verifyEq(m, [2:"two", 5:"five", 9:"nine"])
    verifyEq(m[0], null)
    verifyEq(m[2], "two")
    verifyEq(m[5], "five")
    verifyEq(m[9], "nine")
    verifyErr(ArgErr#) |,| { m.add(9, "err") }
    verifyEq(m[9], "nine")
    m[9] = null

    m.remove(9)
    verifyEq(m, [2:"two", 5:"five"])
    verifyEq(m[null], null)
    verifyEq(m[0], null)
    verifyEq(m[2], "two")
    verifyEq(m[5], "five")
    verifyEq(m[9], null)
    verify(!m.containsKey(null))

    m.remove(5)
    verifyEq(m, [2:"two"])
    verifyEq(m[null], null)
    verifyEq(m[0], null)
    verifyEq(m[2], "two")
    verifyEq(m[5], null)
    verifyEq(m[9], null)

    m.remove(2)
    verifyEq(m, Int:Str[:])
    verifyEq(m[null], null)
    verifyEq(m[0], null)
    verifyEq(m[2], null)
    verifyEq(m[5], null)
    verifyEq(m[9], null)
    verify(m.isEmpty)

    for (Int i :=0;   i<10000; ++i) m[i] = i.toStr
    for (Int i :=0;   i<10000; ++i) verifyEq(m[i], i.toStr)
    for (Int i :=500; i<10000; ++i) m.remove(i)
    for (Int i :=0;   i<500;   ++i) verifyEq(m[i], i.toStr)
    for (Int i :=500; i<1000;  ++i) verifyEq(m[i], null)

    verifyErr(NullErr#) |,| { m.set(null, "foo") }
    verifyErr(NullErr#) |,| { m.add(null, "foo") }

    em := [:]
    verifyErr(NotImmutableErr#) |,| { em.add(this, "foo") }
    verifyErr(NotImmutableErr#) |,| { em.set(this, "foo") }
    verifyErr(NotImmutableErr#) |,| { em[this] = "foo" }
    verify(em.isEmpty)
  }

//////////////////////////////////////////////////////////////////////////
// Duplicate
//////////////////////////////////////////////////////////////////////////

  Void testDup()
  {
    a := ['a':"A", 'b':"B", 'c':"C"]
    verifyEq(a.size, 3)
    verifyEq(a.type, Int:Str#)
    verifyEq(a, ['a':"A", 'b':"B", 'c':"C"])

    b := a.dup
    verifyEq(b.size, 3)
    verifyEq(b.type, Int:Str#)
    verifyEq(b, ['a':"A", 'b':"B", 'c':"C"])

    a['a'] = "X"
    verifyEq(a, ['a':"X", 'b':"B", 'c':"C"])
    verifyEq(b, ['a':"A", 'b':"B", 'c':"C"])

    a.clear
    verifyEq(a, Int:Str[:])
    verifyEq(b, ['a':"A", 'b':"B", 'c':"C"])
  }

//////////////////////////////////////////////////////////////////////////
// SetAll / AddAll
//////////////////////////////////////////////////////////////////////////

  Void testSetAddAll()
  {
    m := [2:2ns, 3:3ns, 4:4ns]
    verifyEq(m.setAll([1:10ns, 3:30ns]), [1:10ns, 2:2ns, 3:30ns, 4:4ns])

    m = [2:2ns, 3:3ns, 4:4ns]
    verifyEq(m.addAll([1:10ns, 5:50ns]), [1:10ns, 2:2ns, 3:3ns, 4:4ns, 5:50ns])
    verifyErr(ArgErr#) |,| { m.addAll([1:10ns, 5:50ns]) }
  }

//////////////////////////////////////////////////////////////////////////
// Clear
//////////////////////////////////////////////////////////////////////////

  Void testClear()
  {
    map := ["a":"A", "b":"B", "c":"C"]
    verifyEq(map.size, 3)
    verifyFalse(map.isEmpty)

    map.clear
    verifyEq(map.size, 0)
    verify(map.isEmpty)

    map["d"] = "D"
    verifyEq(map.size, 1)
    verifyFalse(map.isEmpty)
    verifyEq(map, ["d": "D"])
  }

//////////////////////////////////////////////////////////////////////////
// Keys/Values
//////////////////////////////////////////////////////////////////////////

  Void testKeyValueLists()
  {
    m := [0:"zero"]
    verifyEq(m.keys,   [0])
    verifyEq(m.values, ["zero"])

    m = [0:"zero", 1:"one"]
    verifyEq(m.keys.sort,   [0, 1])
    verifyEq(m.values.sort, ["one", "zero"])

    m = [0:"zero", 1:"one", 2:"two"]
    verifyEq(m.keys.sort,   [0, 1, 2])
    verifyEq(m.values.sort, ["one", "two", "zero"])

    m = [0:"zero", 1:"one", 2:"two", 3:"three"]
    verifyEq(m.keys.sort,   [0, 1, 2, 3])
    verifyEq(m.values.sort, ["one", "three", "two", "zero"])

    m = [0:"zero", 1:"one", 2:"two", 3:"three", 4:"four"]
    verifyEq(m.keys.sort,   [0, 1, 2, 3, 4])
    verifyEq(m.values.sort, ["four", "one", "three", "two", "zero"])

    x := ["a":[0], "b":[0,1], "c":[0,1,2]]
    verifyEq(x.keys.sort,   ["a", "b", "c"])
    verifyEq(x.values.sort |Int[] a, Int[] b->Int| { return a.size <=> b.size },
             [[0], [0,1], [0,1,2]])
  }

//////////////////////////////////////////////////////////////////////////
// Case Insensitive
//////////////////////////////////////////////////////////////////////////

  Void testCaseInsensitive()
  {
    m := Str:Int[:]
    m.caseInsensitive = true

    // add, get, containsKey
    m.add("a", 'a')
    verifyEq(m["a"], 'a')
    verifyEq(m["A"], 'a')
    verifyEq(m.containsKey("a"), true)
    verifyEq(m.containsKey("A"), true)
    verifyEq(m.containsKey("ab"), false)

    // add, get, containsKey
    m.add("B", 'b')
    verifyEq(m["b"], 'b')
    verifyEq(m["B"], 'b')
    verifyEq(m.containsKey("b"), true)
    verifyEq(m.containsKey("B"), true)

    // add existing
    verifyErr(ArgErr#) |,| { m.add("B", 'x') }
    verifyErr(ArgErr#) |,| { m.add("b", 'x') }
    verifyErr(ArgErr#) |,| { m.add("A", 'x') }

    // get, set, containsKey
    m.set("Charlie", 'x')
    m.set("CHARLIE", 'c')
    verifyEq(m["a"], 'a')
    verifyEq(m["A"], 'a')
    verifyEq(m["b"], 'b')
    verifyEq(m["B"], 'b')
    verifyEq(m["charlie"], 'c')
    verifyEq(m["charlIE"], 'c')
    verifyEq(m.containsKey("a"), true)
    verifyEq(m.containsKey("A"), true)
    verifyEq(m.containsKey("b"), true)
    verifyEq(m.containsKey("B"), true)
    verifyEq(m.containsKey("charlie"), true)
    verifyEq(m.containsKey("CHARLIE"), true)

    // keys, values
    verifyEq(m.keys.sort, ["B", "Charlie", "a"])
    verifyEq(m.values.sort, ['a', 'b', 'c'])

    // each
    x := Str:Int[:]
    m.each |Int v, Str k| { x[k] = v }
    verifyEq(x, ["a":'a', "B":'b', "Charlie":'c'])

    // find, findAll, exclude, reduce, map
    verifyEq(m.find |Int v, Str k->Bool| { return k == "a" }, 'a')
    verifyEq(m.find |Int v, Str k->Bool| { return k == "B" }, 'b')
    verifyEq(m.findAll |Int v, Str k->Bool| { return k == "B" }, ["B":'b'])
    verifyEq(m.exclude |Int v, Str k->Bool| { return k == "B" }, ["a":'a', "Charlie":'c'])
    verifyEq(((Str[])m.reduce(Str[,])
      |Obj r, Int v, Str k->Obj| { return ((Str[])r).add(k) }).sort,
      ["B", "Charlie", "a"])
    verifyEq(m.map(Str:Str[:]) |Int v, Str k->Obj| { return k }, ["a":"a", "B":"B", "Charlie":"Charlie"])

    // dup
    d := m.dup
    verifyEq(d.keys.sort, ["B", "Charlie", "a"])
    verifyEq(d.values.sort, ['a', 'b', 'c'])
    d["charlie"] = 'x'
    verifyEq(m["Charlie"], 'c')
    verifyEq(m["charlIE"], 'c')
    verifyEq(d["Charlie"], 'x')
    verifyEq(d["charlIE"], 'x')

    // remove
    verifyEq(m.remove("CHARLIE"), 'c')
    verifyEq(m["charlie"], null)
    verifyEq(m.containsKey("Charlie"), false)
    verifyEq(m.keys.sort, ["B", "a"])

    // addAll (both not insensitive, and insensitive)
    m.addAll(["DAD":'d', "Egg":'e'])
    q := Str:Int[:]; q.caseInsensitive = true; q["foo"] = 'f'
    m.addAll(q)
    verifyEq(m.keys.sort, ["B", "DAD", "Egg", "a", "foo"])
    verifyEq(m["dad"], 'd')
    verifyEq(m["egg"], 'e')
    verifyEq(m["b"], 'b')
    verifyEq(m["FOO"], 'f')

    // setAll (both not insensitive, and insensitive)
    m.setAll(["dad":'D', "EGG":'E'])
    q["FOO"] = 'F'
    m.setAll(q)
    verifyEq(m.keys.sort, ["B", "DAD", "Egg", "a", "foo"])
    verifyEq(m["DaD"], 'D')
    verifyEq(m["eGg"], 'E')
    verifyEq(m["b"], 'b')
    verifyEq(m["Foo"], 'F')
    verifyEq(m.containsKey("EgG"), true)
    verifyEq(m.containsKey("A"), true)

    // to readonly
    r := m.ro
    verifyEq(r.caseInsensitive, true)
    verifyEq(r.keys.sort, ["B", "DAD", "Egg", "a", "foo"])
    verifyEq(r["DaD"], 'D')
    verifyEq(r["eGg"], 'E')
    verifyEq(r["b"], 'b')
    verifyEq(r["Foo"], 'F')
    verifyEq(r.containsKey("EgG"), true)
    verifyEq(r.containsKey("A"), true)

    // to immutable
    i := m.toImmutable
    verifyEq(i.caseInsensitive, true)
    verifyEq(i.keys.sort, ["B", "DAD", "Egg", "a", "foo"])
    verifyEq(i["DaD"], 'D')
    verifyEq(i["eGg"], 'E')
    verifyEq(i["b"], 'b')
    verifyEq(i["Foo"], 'F')
    verifyEq(i.containsKey("EgG"), true)
    verifyEq(i.containsKey("A"), true)

    // to rw
    rw := r.rw
    verifyEq(rw.caseInsensitive, true)
    verifyEq(rw.remove("Dad"), 'D')
    rw["fOo"] = '^'
    verifyEq(r.keys.sort, ["B", "DAD", "Egg", "a", "foo"])
    verifyEq(rw.keys.sort, ["B", "Egg", "a", "foo"])
    verifyEq(r["DaD"], 'D')
    verifyEq(r["eGg"], 'E')
    verifyEq(r["b"], 'b')
    verifyEq(r["Foo"], 'F')
    verifyEq(rw["DaD"], null)
    verifyEq(rw["eGg"], 'E')
    verifyEq(rw["b"], 'b')
    verifyEq(rw["Foo"], '^')

    // set false
    m.clear
    m.caseInsensitive = false
    m.add("Alpha", 'a').add("Beta", 'b')
    verifyEq(m["Alpha"], 'a')
    verifyEq(m["alpha"], null)
    verifyEq(m["ALPHA"], null)
    verifyEq(m.containsKey("Beta"), true)
    verifyEq(m.containsKey("beta"), false)

    // equals
    m.clear
    m.caseInsensitive = true
    m.add("Alpha", 'a').add("Beta", 'b')
    verifyEq(m, ["Alpha":'a', "Beta":'b'])
    verifyNotEq(m, ["alpha":'a', "Beta":'b'])
    verifyNotEq(m, ["Alpha":'x', "Beta":'b'])
    verifyNotEq(m, ["Beta":'b'])
    verifyNotEq(m, ["Alpha":'a', "Beta":'b', "C":'c'])

    // errors
    verifyErr(UnsupportedErr#) |,| { Int:Str[:].caseInsensitive = true }
    verifyErr(UnsupportedErr#) |,| { Obj:Str[:].caseInsensitive = true }
    verifyErr(UnsupportedErr#) |,| { ["a":0].caseInsensitive = true }
  }

//////////////////////////////////////////////////////////////////////////
// Def
//////////////////////////////////////////////////////////////////////////

  Void testDef()
  {
    a := [0:"zero"]
    verifyEq(a.def, null)
    verifyEq(a[0], "zero")
    verifyEq(a[3], null)
    verifyEq(a.get(3, "x"), "x")

    a.def = ""
    verifyEq(a.def, "")
    verifyEq(a[0], "zero")
    verifyEq(a[3], "")
    verifyEq(a.get(3, "x"), "x")

    a = a.ro
    verifyEq(a.def, "")
    verifyEq(a[0], "zero")
    verifyEq(a[3], "")
    verifyEq(a.get(3, "x"), "x")
    verifyErr(ReadonlyErr#) |,| { a.def = null }

    a = a.rw
    verifyEq(a.def, "")
    verifyEq(a[0], "zero")
    verifyEq(a[3], "")
    verifyEq(a.get(3, "x"), "x")
    a.def = "?"
    verifyEq(a[3], "?")

    a = a.toImmutable
    verifyEq(a.def, "?")
    verifyEq(a[0], "zero")
    verifyEq(a[3], "?")
    verifyEq(a.get(3, "x"), "x")
    verifyErr(ReadonlyErr#) |,| { a.def = null }
    verifyEq(a.def, "?")

    b := ["x":[0, 1]] { def = Int[,].toImmutable }
    verifyEq(b["x"], [0, 1])
    verifyEq(b["y"], Int[,])
    verifyErr(NotImmutableErr#) |,| { b.def = [3] }
  }

//////////////////////////////////////////////////////////////////////////
// Each
//////////////////////////////////////////////////////////////////////////

  Void testEach()
  {
    keys := Int[,]
    vals := Str[,]

    // empty list
    Int:Str[:].each |Str val, Int key|
    {
      vals.add(val)
      keys.add(key)
    }
    verifyEq(keys, Int[,])
    verifyEq(vals, Str[,]);

    // list of one
    keys.clear; vals.clear;
    [0:"zero"].each |Str val, Int key|
    {
      vals.add(val)
      keys.add(key)
    }
    verifyEq(keys, [0])
    verifyEq(vals, ["zero"]);

    // list of two
    keys.clear; vals.clear;
    [0:"zero", 1:"one"].each |Str val, Int key|
    {
      vals.add(val)
      keys.add(key)
    }
    verify(keys.size == 2);
    verify(keys.contains(0)); verify(keys.index(0) == vals.index("zero"));
    verify(keys.contains(1)); verify(keys.index(1) == vals.index("one"));

    // list of ten
    keys.clear; vals.clear;
    [0:"zero", 1:"one", 2:"two", 3:"three", 4:"four",
     5:"five", 6:"six", 7:"seven", 8:"eight", 9:"nine"].each |Str val, Int key|
    {
      vals.add(val)
      keys.add(key)
    }
    verify(keys.size == 10);
    verify(keys.contains(0)); verify(keys.index(0) == vals.index("zero"));
    verify(keys.contains(1)); verify(keys.index(1) == vals.index("one"));
    verify(keys.contains(2)); verify(keys.index(2) == vals.index("two"));
    verify(keys.contains(3)); verify(keys.index(3) == vals.index("three"));
    verify(keys.contains(4)); verify(keys.index(4) == vals.index("four"));
    verify(keys.contains(5)); verify(keys.index(5) == vals.index("five"));
    verify(keys.contains(6)); verify(keys.index(6) == vals.index("six"));
    verify(keys.contains(7)); verify(keys.index(7) == vals.index("seven"));
    verify(keys.contains(8)); verify(keys.index(8) == vals.index("eight"));
    verify(keys.contains(9)); verify(keys.index(9) == vals.index("nine"));
  }

//////////////////////////////////////////////////////////////////////////
// EachBreak
//////////////////////////////////////////////////////////////////////////

  Void testEachBreak()
  {
    x := [0:"0", 1:"1", 2:"2", 3:"3"]
    verifyEq(x.eachBreak |Str v->Str| { return v == "2" ? "!" : null }, "!")
    verifyEq(x.eachBreak |Str v->Str| { return v == "9" ? "!" : null }, null)
    verifyEq(x.eachBreak |Str v, Int k->Str| { return k == 3 ? v : null }, "3")
    verifyEq(x.eachBreak |Str v, Int k->Str| { return k == 9 ? v : null }, null)
  }

//////////////////////////////////////////////////////////////////////////
// Find
//////////////////////////////////////////////////////////////////////////

  Void testFind()
  {
    map := [0:"zero", 1:"one", 2:"two", 3:"three", 4:"four"]

    // find
    verifyEq(map.find |Str v, Int k->Bool| { return k == 2 }, "two")
    verifyEq(map.find |Str v, Int k->Bool| { return v == "four" }, "four")
    verifyEq(map.find |Str v, Int k->Bool| { return false }, null)
    verifyEq(map.find |Str v->Bool| { return false }, null)
    verifyEq(map.find |->Bool| { return false }, null)

    // typed assign
    Str x := map.find |Str v->Bool| { return v.size == 5 }
    verifyEq(x, "three")

    // findAll
    verifyEq(map.findAll|Str v, Int k->Bool| { return v.size == 3 }, [1:"one", 2:"two"])
    verifyEq(map.findAll|Str v, Int k->Bool| { return k % 2 == 0 },  [0:"zero", 2:"two", 4:"four"])
    verifyEq(map.findAll|Str v, Int k->Bool| { return false },  Int:Str[:])
    verifyEq(map.findAll|Str v->Bool| { return false },  Int:Str[:])
    verifyEq(map.findAll|->Bool| { return false },  Int:Str[:])

    // exclude
    map2 := ["off":0, "slow":50, "fast":100]
    verifyEq(map2.exclude|Int v->Bool| { return v == 0 }, ["slow":50, "fast":100])
    verifyEq(map2.exclude|Int v->Bool| { return true }, Str:Int[:])

    // typed assign
    Int:Str a := map.findAll |Str v->Bool| { return v.size == 4 }
    verifyEq(a, [0:"zero", 4:"four"])
  }

//////////////////////////////////////////////////////////////////////////
// Reduce
//////////////////////////////////////////////////////////////////////////

  Void testReduce()
  {
    map := [0:"zero", 1:"one", 2:"two", 3:"three", ]

    verifyEq(map.reduce(0) |Obj r, Str v, Int k->Obj| { return (Int)r + k }, 6)

    vals := Str[,]
    map.reduce(vals) |Obj r, Str v, Int k->Obj| { return vals.add(v) }
    verifyEq(vals.sort, ["one", "three", "two", "zero"])
  }

//////////////////////////////////////////////////////////////////////////
// Map
//////////////////////////////////////////////////////////////////////////

  Void testMap()
  {
    map := [0:"zero", 1:"one", 2:"two"]

    c := Int:Str[:]
    map.map(c) |Str v->Obj| { return "($v)" }
    verifyEq(c, [0:"(zero)", 1:"(one)", 2:"(two)"])

    c2 := Int:Int[:]
    map.map(c2) |Str v, Int k->Obj| { return k*2 }
    verifyEq(c2, [0:0, 1:2, 2:4])
  }

//////////////////////////////////////////////////////////////////////////
// AssignOps
//////////////////////////////////////////////////////////////////////////

  Void testAssignOps()
  {
    x := ["one":1, "two":2, "three":3]

    t := x["two"]++
    verifyEq(t, 2)
    verifyEq(x["two"], 3)

    t = ++x["two"]
    verifyEq(t, 4)
    verifyEq(x["two"], 4);

    ++x["two"]
    verifyEq(x["two"], 5)

    x["three"] |= 0xab00
    verifyEq(x["three"], 0xab03)
  }

//////////////////////////////////////////////////////////////////////////
// Readonly
//////////////////////////////////////////////////////////////////////////

  Void testReadonly()
  {
    // create rw map
    x := [0:"a", 1:"b", 2:"c"]
    verifyEq(x.isRW, true)
    verifyEq(x.isRO, false)
    verifySame(x.rw, x)

    // get ro list
    r := x.ro
    verifyEq(x.isRW, true)
    verifyEq(x.isRO, false)
    verifySame(x.rw, x)
    verifyEq(r.isRW, false)
    verifyEq(r.isRO, true)
    verifySame(x.ro, r)
    verifySame(x.ro, r)
    verifySame(r.ro, r)
    verifySame(r.ro, r)
    verifyEq(r, x)

    // verify all idempotent methods work
    verifyEq(r.type, Int:Str#)
    verifyEq(r.isEmpty, false)
    verifyEq(r.size, 3)
    verifyEq(r[0], "a")
    verifyEq(r[1], "b")
    verifyEq(r[2], "c")
    verifyEq(r.get(3, "?"), "?")
    verifyEq(r.containsKey(2), true)
    verifyEq(r.containsKey(4), false)
    verifyEq(r.keys.sort, [0, 1, 2])
    verifyEq(r.values.sort, ["a", "b", "c"])
    verifyEq(r.dup, [0:"a", 1:"b", 2:"c"])
    r.each |Str v, Int k| { verifyEq(r[k], v) }
    verifyEq(r.find |Str s->Bool| { return s == "b" }, "b")
    verifyEq(r.findAll |Str s->Bool| { return true }, [0:"a", 1:"b", 2:"c"])
    verifyEq(r.toStr, [0:"a", 1:"b", 2:"c"].toStr)
    verifyEq(r.caseInsensitive, false)
    verifyEq(r.def, null)
//verifyEq(r.join, "abc")

    // verify all modification methods throw ReadonlyErr
    verifyErr(ReadonlyErr#) |,| { r[2] = "x" }
    verifyErr(ReadonlyErr#) |,| { r[3] = "x" }
    verifyErr(ReadonlyErr#) |,| { r.add(2, "?") }
    verifyErr(ReadonlyErr#) |,| { r.setAll([1:"yikes!"]) }
    verifyErr(ReadonlyErr#) |,| { r.addAll([1:"yikes!"]) }
    verifyErr(ReadonlyErr#) |,| { r.remove(0) }
    verifyErr(ReadonlyErr#) |,| { r.remove(5) }
    verifyErr(ReadonlyErr#) |,| { r.clear }
    verifyErr(ReadonlyErr#) |,| { r.caseInsensitive = true }
    verifyErr(ReadonlyErr#) |,| { r.def = "" }

    // verify rw detaches ro
    x[3] = "d"
    r2 := x.ro
    verifySame(x.ro, r2)
    verifyNotSame(r2, r)
    verifyNotSame(x.ro, r)
    verifyEq(r.isRO, true)
    verifyEq(r.size, 3)
    verifyEq(r, [0:"a", 1:"b", 2:"c"])
    verifyNotEq(r, x)
    verifyNotEq(r, r2)
    x.remove(3)
    r3 := x.ro
    verifySame(x.ro, r3)
    verifyNotSame(r2, r3)
    verifyNotSame(r3, r)
    verifyNotSame(r2, r)
    verifyNotSame(x.ro, r)
    verifyEq(r.size, 3)
    verifyEq(r, [0:"a", 1:"b", 2:"c"])

    // verify ro to rw
    y := r.rw
    verifyEq(y.isRW, true)
    verifyEq(y.isRO, false)
    verifySame(y.rw, y)
    verifySame(y.ro, r)
    verifyEq(y, r)
    verifyEq(r.isRO, true)
    verifyEq(r.size, 3)
    verifyEq(r, [0:"a", 1:"b", 2:"c"])
    verifyEq(y, [0:"a", 1:"b", 2:"c"])
    y.clear
    verifyNotSame(y.ro, r)
    verifyEq(y.size, 0)
    verifySame(y.rw, y)
    verifyEq(r, [0:"a", 1:"b", 2:"c"])
    y[-1] = "!"
    verifyEq(y.size, 1)
    verifyEq(y, [-1:"!"])
    verifyEq(r.size, 3)
    verifyEq(r, [0:"a", 1:"b", 2:"c"])
  }

//////////////////////////////////////////////////////////////////////////
// ToImmutable
//////////////////////////////////////////////////////////////////////////

  Void testToImmutable()
  {
    m := [
          [0].toImmutable: [0ns:"zero"],
          [1].toImmutable: [1ns:"one"],
          [2].toImmutable :null
         ]
    mc := m.toImmutable
    verifyEq(m, mc)
    verifySame(mc.toImmutable, mc)

    verifyNotSame(m, mc)
    verifyNotSame(m.ro, mc)
    verify(mc.isRO)
    verify(mc.isImmutable)
    verifyEq(mc.type.signature, "[sys::Int[]:[sys::Duration:sys::Str]]")
    verifyEq(mc.get([0]), [0ns:"zero"])
    verifyEq(mc.get(null), null)
    verifyEq(mc.get([2]), null)
    verify(mc.get([0]).isRO)
    verify(mc.get([0]).isImmutable)
    mc.keys.each |Int[] k| { if (k != null) verify(k.isImmutable) }

    mx := mc.rw
    verifyEq(mx.isImmutable, false)
    verifyEq(mc.isImmutable, true)
    mx[[0].toImmutable] = [7ns:"seven"]
    verifyEq(mc.get([0]), [0ns:"zero"])
    verifyEq(mx.get([0]), [7ns:"seven"])

    verifyEq([0:"zero"].isImmutable, false)
    verifyEq([0:"zero"].ro.isImmutable, false)
    verifyEq([0:"zero"].toImmutable.isImmutable, true)

    verifyEq([0:this].isImmutable, false)
    verifyEq([0:this].ro.isImmutable, false)
    verifyErr(NotImmutableErr#) |,| { [0:this].toImmutable }
    verifyErr(NotImmutableErr#) |,| { [0:[this]].toImmutable }
    verifyErr(NotImmutableErr#) |,| { [4:[8ns:this]].toImmutable }
  }

}
