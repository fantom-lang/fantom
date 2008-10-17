//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jan 06  Brian Frank  Creation
//

**
** ListTest
**
class ListTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Play
//////////////////////////////////////////////////////////////////////////

  Void testPlay()
  {
    x := [0, 1, 2, 3]
    verify(x.type == Int[]#)
    verify(x.type === Int[]#)
    a := x[-1]
    verify(a is Int)
    verify(a.type == Int#)
    verify(a == 3)
  }

//////////////////////////////////////////////////////////////////////////
// Equals
//////////////////////////////////////////////////////////////////////////

  Void testEquals()
  {
    verifyEq([0, 1], [0, 1])
    verifyEq([0, 1].hash, [0, 1].hash)
    verifyNotEq([0, 1], null)
    verifyNotEq(null, [0, 1])
    verifyNotEq([1, 0], [0, 1])
    verifyNotEq([0, 1], [0, 1, 2])
    verifyNotEq([0, 1, 2], [0, 1])
    verifyNotEq([0, 1, 2], "string")
  }

//////////////////////////////////////////////////////////////////////////
// Is Operator
//////////////////////////////////////////////////////////////////////////

  Void testIsExplicit()
  {
    // Obj[]
    Obj a := Obj[,]
    verify(a is Obj)
    verify(a is Obj[])
    verifyFalse(a is Str)
    verifyFalse(a is Str[])

    // Str[]
    Obj b := Str[,]
    verify(b is Obj)
    verify(b is Obj[])
    verify(b is Str[])
    verifyFalse(b is Str)
    verifyFalse(b is Int[])

    // Field[]
    Obj c := Field[,]
    verify(c is Obj)
    verify(c is Obj[])
    verify(c is Slot[])
    verify(c is Field[])
  }

  Void testInference()
  {
    verifyEq([,].type,     Obj?[]#)
    verifyEq(Obj?[,].type, Obj?[]#)
    verifyEq(Obj[,].type,  Obj[]#)
    verifyEq([null].type,  Obj?[]#)
    verifyEq([null,null].type, Obj?[]#)
    verifyEq([2,null].type,  Int?[]#)
    verifyEq([null,2].type,  Int?[]#)
    verifyEq([2,null,2f].type, Num?[]#)
    verifyEq([null,3,2f].type, Num?[]#)

    // expressions used to create list literal
    [Str:Int]? x := null
    verifyEq([this->toStr].type, Obj?[]#)
    verifyEq([Pod.find("xxxx", false)].type, Pod?[]#)
    verifyEq([this as Test].type, Test?[]#)
    verifyEq([this ?: "foo"].type, Obj?[]#)
    verifyEq([x?.toStr].type, Str?[]#)
    verifyEq([x?.def].type, Int?[]#)
    verifyEq([x?.caseInsensitive].type, Bool?[]#)
    verifyEq([x?->foo].type, Obj?[]#)
    verifyEq([returnThis].type, ListTest[]#)
    verifyEq([x == null ? "x" : null].type, Str?[]#)
    verifyEq([x == null ? null : 4f].type, Float?[]#)
  }

  This returnThis() { return this }

  Void testIsInfered()
  {
    // Obj[]
    verify([2,"a"] is Obj)
    verify([3,"b"] is Obj[])
    verify([,] is Obj?[])
    verify([null] is Obj?[])
    verify([2,null] is Obj?[])
    verify([null,"2"] is Obj?[])
    verifyFalse((Obj)[type,8f] is Str)
    verifyFalse((Obj)["a",this] is Str[])

    // Int[]
    verify([3] is Obj)
    verify([6] is Obj[])
    verify([3] is Obj)
    verify([4,3] is Int[])
    verify([4,null] is Int[])  // null doesn't count
    verify([null, null, 9] is Int[])  // null doesn't count
    verifyFalse((Obj)[-1,9] is Int)
    verifyFalse((Obj)[4,6,9] is Str[])
  }

//////////////////////////////////////////////////////////////////////////
// As Operator
//////////////////////////////////////////////////////////////////////////

  Void testAsExplicit()
  {
    Obj x := [,];

    Obj o    := x as Obj;    verifySame(o , x)
    Bool b   := x as Bool;   verifySame(b , null)
    Str s    := x as Str;    verifySame(s , null)
    List l   := x as List;   verifySame(l , x)
    Obj[] ol := x as Obj[];  verifySame(ol , x)
    Int[] il := x as Int[];  verifySame(il , null)
    Str[] sl := x as Str[];  verifySame(sl , null)

    x  = ["a", "b"]
    o  = x as Obj;    verifySame(o , x)
    b  = x as Bool;   verifySame(b , null)
    s  = x as Str;    verifySame(s , null)
    l  = x as List;   verifySame(l , x)
    ol = x as Obj[];  verifySame(ol , x)
    il = x as Int[];  verifySame(il , null)
    sl = x as Str[];  verifySame(sl , x)
  }

//////////////////////////////////////////////////////////////////////////
// Reflection
//////////////////////////////////////////////////////////////////////////

  Void testReflect()
  {
    verifyEq(["a"].of, Str#)
    verifyEq([[2]].of, Int[]#)

    x := [,]
    verifyEq(x.type.base,      List#)
    verifyEq(x.type.base.base, Obj#)
    verifyEq(x.type.pod.name,  "sys")
    verifyEq(x.type.name,      "List")
    verifyEq(x.type.qname,     "sys::List")
    verifyEq(x.type.signature, "sys::Obj?[]")
    verifyEq(x.type.toStr,     "sys::Obj?[]")
    verifyEq(x.type.method("isEmpty").returns,  Bool#)
    verifyEq(x.type.method("first").returns,    Obj?#)
    verifyEq(x.type.method("get").returns,      Obj?#)
    verifyEq(x.type.method("add").returns,      Obj?[]#)
    verifyEq(x.type.method("add").params[0].of, Obj?#)
    verifyEq(x.type.method("each").params[0].of, |Obj? a, Int i->Void|#)
    verifyNotEq(x.type.method("each").params[0].of, |Str a, Int i->Void|#)

    y := [7]
    verifyEq(y.type.base,      List#)
    verifyEq(y.type.base.base, Obj#)
    verifyEq(y.type.pod.name,  "sys")
    verifyEq(y.type.name,      "List")
    verifyEq(y.type.qname,     "sys::List")
    verifyEq(y.type.signature, "sys::Int[]")
    verifyEq(y.type.toStr,     "sys::Int[]")
    verifyEq(y.type.method("isEmpty").returns,  Bool#)
    verifyEq(y.type.method("first").returns,    Int?#)
    verifyEq(y.type.method("get").returns,      Int#)
    verifyEq(y.type.method("add").returns,      Int[]#)
    verifyEq(y.type.method("add").params[0].of, Int#)
    verifyEq(y.type.method("each").params[0].of, |Int a, Int i->Void|#)
    verifyNotEq(y.type.method("each").params[0].of, |Obj a, Int i->Void|#)

    z := [[8ms]]
    verifyEq(z.type.base,      List#)
    verifyEq(z.type.base.base, Obj#)
    verifyEq(z.type.pod.name,  "sys")
    verifyEq(z.type.name,      "List")
    verifyEq(z.type.qname,     "sys::List")
    verifyEq(z.type.signature, "sys::Duration[][]")
    verifyEq(z.type.toStr,     "sys::Duration[][]")
    verifyEq(z.type.method("isEmpty").returns,   Bool#)
    verifyEq(z.type.method("first").returns,     Duration[]?#)
    verifyEq(z.type.method("get").returns,       Duration[]#)
    verifyEq(z.type.method("add").returns,       Duration[][]#)
    verifyEq(z.type.method("add").params[0].of,  Duration[]#)
    verifyEq(z.type.method("insert").params[1].of, Duration[]#)
    verifyEq(z.type.method("removeAt").returns,    Duration[]#)
    verifyEq(z.type.method("each").params[0].of, |Duration[] a, Int i->Void|#)
    verifyEq(z.type.method("map").returns, List#)
    verifyNotEq(z.type.method("map").returns, Duration[]#)
    verifyNotEq(z.type.method("each").params[0].of, |Obj a, Int i->Void|#)
  }

//////////////////////////////////////////////////////////////////////////
// Items
//////////////////////////////////////////////////////////////////////////

  Void testItems()
  {
    // add, insert, removeAt, get, size
    Obj? r;
    list := Int?[,]
    list.add(10); verifyEq(list, Int?[10]); verifyEq(list.size, 1);
    list.add(20); verifyEq(list, Int?[10, 20]); verifyEq(list.size, 2);
    list.add(30); verifyEq(list, Int?[10, 20, 30]); verifyEq(list.size, 3);
    list.insert(0, 40); verifyEq(list, Int?[40, 10, 20, 30]); verifyEq(list.size, 4);
    list.insert(1, 50).add(60); verifyEq(list, Int?[40, 50, 10, 20, 30, 60]); verifyEq(list.size, 6);
    list.insert(-1, 70); verifyEq(list, Int?[40, 50, 10, 20, 30, 70, 60]); verifyEq(list.size, 7);
    list.insert(-3, 80); verifyEq(list, Int?[40, 50, 10, 20, 80, 30, 70, 60]); verifyEq(list.size, 8);
    verify(list.removeAt(0) == 40); verifyEq(list, Int?[50, 10, 20, 80, 30, 70, 60]); verifyEq(list.size, 7);
    verify(list.removeAt(6) == 60); verifyEq(list, Int?[50, 10, 20, 80, 30, 70]); verifyEq(list.size, 6);
    list.removeAt(3); verifyEq(list, Int?[50, 10, 20, 30, 70]); verifyEq(list.size, 5);
    list.removeAt(-1); verifyEq(list, Int?[50, 10, 20, 30]); verifyEq(list.size, 4);
    list.removeAt(-4); verifyEq(list, Int?[10, 20, 30]); verifyEq(list.size, 3);
    list.add(40); verifyEq(list, Int?[10, 20, 30, 40]); verifyEq(list.size, 4);
    verify(list.insert(2, 50) === list); verifyEq(list, Int?[10, 20, 50, 30, 40]); verifyEq(list.size, 5);
    list.removeAt(2); verifyEq(list, Int?[10, 20, 30, 40]); verifyEq(list.size, 4);
    verifyEq(list[0], 10); verifyEq(list[-4], 10);
    verifyEq(list[1], 20); verifyEq(list[-3], 20);
    verifyEq(list[2], 30); verifyEq(list[-2], 30);
    verifyEq(list[3], 40); verifyEq(list[-1], 40);
    list[0] = -10; verifyEq(list, Int?[-10, 20, 30, 40]); verifyEq(list.size, 4);
    list[2] = -30; verifyEq(list, Int?[-10, 20, -30, 40]); verifyEq(list.size, 4);
    list[-1] = -40; verifyEq(list, Int?[-10, 20, -30, -40]); verifyEq(list.size, 4);
    list[-3] = -20; verifyEq(list, Int?[-10, -20, -30, -40]); verifyEq(list.size, 4);
    list[-2] = null; verifyEq(list, Int?[-10, -20, null, -40]); verifyEq(list.size, 4);
    list[0] = null; verifyEq(list, Int?[null, -20, null, -40]); verifyEq(list.size, 4);

    // IndexErr - no items
    list = Int[,]
    verifyErr(IndexErr#) |,| { x:=list[0] }
    verifyErr(IndexErr#) |,| { x:=list[1] }
    verifyErr(IndexErr#) |,| { x:=list[-1] }
    verifyErr(IndexErr#) |,| { x:=list[-2] }

    // IndexErr - one items
    list = [77]
    verifyErr(IndexErr#) |,| { x:=list[1] }
    verifyErr(IndexErr#) |,| { x:=list[-2] }
  }

//////////////////////////////////////////////////////////////////////////
// Duplicate
//////////////////////////////////////////////////////////////////////////

  Void testDup()
  {
    a := [0, 1, 2]
    verifyEq(a.size, 3)
    verifyEq(a.type, Int[]#)
    verifyEq(a, [0, 1, 2])

    b := a.dup
    verifyEq(b.size, 3)
    verifyEq(b.type, Int[]#)
    verifyEq(b, [0, 1, 2])

    a[1] = 99
    verifyEq(a, [0, 99, 2])
    verifyEq(b, [0, 1, 2])

    a.clear
    verifyEq(a.size, 0)
    verifyEq(b.size, 3)
    verifyEq(a, Int[,])
    verifyEq(b, [0, 1, 2])
  }

//////////////////////////////////////////////////////////////////////////
// AddAll/InsertAll
//////////////////////////////////////////////////////////////////////////

  Void testInsertAll()
  {
    a := Str[,]
    x := Str[,]

    verifyEq(a.addAll(x), Str[,])
    verifyEq(a.insertAll(-1, x), Str[,])

    a.add("a")
    verifyEq(a.addAll(x), ["a"])
    verifyEq(a.insertAll(0, x), ["a"])

    x.add("x")
    verifyEq(a.addAll(x), ["a", "x"])
    verifyEq(a.insertAll(0, x), ["x", "a", "x"])

    x.add("y")
    verifyEq(a.addAll(x), ["x", "a", "x", "x", "y"])
    verifyEq(a.insertAll(1, x), ["x", "x", "y", "a", "x", "x", "y"])

    a = ["a", "b", "c"]
    verifyEq(a.insertAll(1, a), ["a", "a", "b", "c", "b", "c"])
    verifyEq(a.insertAll(-2, ["x", "y"]), ["a", "a", "b", "c", "x", "y", "b", "c"])
  }

//////////////////////////////////////////////////////////////////////////
// Size/Capacity
//////////////////////////////////////////////////////////////////////////

  Void testSizeCapacity()
  {
    x := Str?[,]

    verifyEq(x.size, 0)
    verifyEq(x.capacity, 0)

    x.capacity = 2
    verifyEq(x.size, 0)
    verifyEq(x.capacity, 2)

    x.add("a").add("b")
    verifyEq(x.size, 2)
    verifyEq(x.capacity, 2)
    verifyErr(ArgErr#) |,| { x.capacity = 1 }

    x.add("c")  // auto-grow
    verifyEq(x.size, 3)
    verifyEq(x.capacity, 10)
    verifyEq(x, Str?["a", "b", "c"])

    x.capacity = 3 // manual trim
    verifyEq(x.size, 3)
    verifyEq(x.capacity, 3)
    verifyEq(x, Str?["a", "b", "c"])

    x.size = 4
    verifyEq(x.size, 4)
    verifyEq(x.capacity, 4)
    verifyEq(x, ["a", "b", "c", null])

    x.size = 2
    verifyEq(x.size, 2)
    verifyEq(x.capacity, 2)
    verifyEq(x, Str?["a", "b"])

    x.size = 5
    verifyEq(x.size, 5)
    verifyEq(x.capacity, 5)
    verifyEq(x, ["a", "b", null, null, null])
    x.add("z")

    verifyEq(x, ["a", "b", null, null, null, "z"])
    verifyEq(x.size, 6)
    verifyEq(x.capacity, 10)

    x.size = 0
    verifyEq(x.size, 0)
    verifyEq(x.capacity, 0)
    verifyEq(x, Str?[,])

    x.add("x")
    verifyEq(x.size, 1)
    verifyEq(x.capacity, 10)
    verifyEq(x, Str?["x"])

    x.size = x.size
    verifyEq(x.size, 1)
    verifyEq(x.capacity, 1)
    verifyEq(x, Str?["x"])
  }

//////////////////////////////////////////////////////////////////////////
// Slicing
//////////////////////////////////////////////////////////////////////////

  Void testSlicing()
  {
    /* Ruby
    irb(main):001:0> a = [0, 1, 2, 3] => [0, 1, 2, 3]
    irb(main):002:0> a[0..3]   => [0, 1, 2, 3]
    irb(main):003:0> a[0..2]   => [0, 1, 2]
    irb(main):004:0> a[0..1]   => [0, 1]
    irb(main):005:0> a[0..0]   => [0]
    irb(main):006:0> a[0...0]  => []
    irb(main):007:0> a[0...1]  => [0]
    irb(main):008:0> a[0...2]  => [0, 1]
    irb(main):009:0> a[0...3]  => [0, 1, 2]
    irb(main):010:0> a[1..3]   => [1, 2, 3]
    irb(main):011:0> a[1..4]   => [1, 2, 3]
    irb(main):012:0> a[1..5]   => [1, 2, 3]
    irb(main):013:0> a[1..1]   => [1]
    irb(main):014:0> a[1..-1]  => [1, 2, 3]
    irb(main):015:0> a[1..-2]  => [1, 2]
    irb(main):016:0> a[1..-3]  => [1]
    irb(main):017:0> a[1..-4]  => []
    irb(main):018:0> a[1...-1] => [1, 2]
    irb(main):019:0> a[1...-2] => [1]
    irb(main):020:0> a[1...-3] => []
    irb(main):021:0> a[-3..-1] => [1, 2, 3]
    irb(main):022:0> a[-3..-2] => [1, 2]
    irb(main):023:0> a[-3..-3] => [1]
    */

    list := [0, 1, 2, 3]

    verifyEq(list[0..3],  [0, 1, 2, 3])
    verifyEq(list[0..2],  [0, 1, 2])
    verifyEq(list[0..1],  [0, 1])
    verifyEq(list[0..0],  [0])
    verifyEq(list[0...0], Int[,])
    verifyEq(list[0...1], [0])
    verifyEq(list[0...2], [0, 1])
    verifyEq(list[0...3], [0, 1, 2])
    verifyEq(list[0...4], [0, 1, 2, 3])
    verifyEq(list[1..3], [1, 2, 3])
    verifyEq(list[1..1], [1])
    verifyEq(list[1..-1], [1, 2, 3])
    verifyEq(list[1..-2], [1, 2])
    verifyEq(list[1..-3], [1])
    verifyEq(list[1..-4], Int[,])
    verifyEq(list[1...-1], [1, 2])
    verifyEq(list[1...-2], [1])
    verifyEq(list[1...-3], Int[,])
    verifyEq(list[-3..-1], [1, 2, 3])
    verifyEq(list[-3..-2], [1, 2])
    verifyEq(list[-3..-3], [1])
    verifyEq(list[4..-1], Int[,])

    // examples
    ex := [0, 1, 2, 3]
    verifyEq(ex[0..2], [0, 1, 2])
    verifyEq(ex[3..3], [3])
    verifyEq(ex[-2..-1], [2, 3])
    verifyEq(ex[0...2], [0, 1])
    verifyEq(ex[1..-2], [1, 2])

    // errors
    verifyErr(IndexErr#) |,| { x:=list[0..4] }
    verifyErr(IndexErr#) |,| { x:=list[0...5] }
    verifyErr(IndexErr#) |,| { x:=list[2...1] }
    verifyErr(IndexErr#) |,| { x:=list[3..1] }
    verifyErr(IndexErr#) |,| { x:=list[-5..-1] }
    verifyErr(IndexErr#) |,| { x:=list[1..4] }
    verifyErr(IndexErr#) |,| { x:=list[1..5] }
  }

//////////////////////////////////////////////////////////////////////////
// Remove
//////////////////////////////////////////////////////////////////////////

  Void testRemove()
  {
    foo := "foobar"[0..2]
    list := Str?["a", "b", foo, null, "a"]
    verifyEq(list.indexSame("foo"), null)
    verifyEq(list.remove("b"), "b");     verifyEq(list, Str?["a", "foo", null, "a"])
    verifyEq(list.remove("a"), "a");     verifyEq(list, Str?["foo", null, "a"])
    verifyEq(list.remove("x"), null);    verifyEq(list, Str?["foo", null, "a"])
    verifyEq(list.remove("a"), "a");     verifyEq(list, Str?["foo", null])
    verifyEq(list.remove(null), null);   verifyEq(list, Str?["foo"])
    verifyEq(list.removeSame("foo"), null);  verifyEq(list, Str?["foo"])
    verifyEq(list.remove("foo"), "foo"); verifyEq(list, Str?[,])
    verifyEq(list.remove("a"), null);    verifyEq(list, Str?[,])
  }

//////////////////////////////////////////////////////////////////////////
// RemoveRange
//////////////////////////////////////////////////////////////////////////

  Void testRemoveRange()
  {
    verifyEq(Int[,].removeRange(0..-1), Int[,])
    verifyEq(Int[1].removeRange(0..-1), Int[,])
    verifyEq(Int[1].removeRange(1..-1), [1])
    verifyEq(Int[1,2].removeRange(0..-1), Int[,])
    verifyEq(Int[1,2].removeRange(0..1), Int[,])
    verifyEq(Int[1,2].removeRange(0...1), [2])
    verifyEq(Int[1,2].removeRange(1..1), [1])
    verifyEq(Int[1,2].removeRange(1..-1), [1])
    verifyEq(Int[1,2,3].removeRange(0..-1), Int[,])
    verifyEq(Int[1,2,3].removeRange(1..1), [1,3])
    verifyEq(Int[1,2,3].removeRange(1...2), [1,3])
    verifyEq(Int[0,1,2,3,4,5].removeRange(0..2), [3,4,5])
    verifyEq(Int[0,1,2,3,4,5].removeRange(4..-1), [0,1,2,3])
    verifyEq(Int[0,1,2,3,4,5].removeRange(1..4), [0,5])
    verifyEq(Int[0,1,2,3,4,5].removeRange(1...4), [0,4,5])
    verifyEq(Int[0,1,2,3,4,5].removeRange(-3..-1), [0,1,2])
    verifyEq(Int[0,1,2,3,4,5].removeRange(-3..4), [0,1,2,5])
  }

//////////////////////////////////////////////////////////////////////////
// Clear
//////////////////////////////////////////////////////////////////////////

  Void testClear()
  {
    list := ["a", "b", "c"]
    verifyEq(list.size, 3)
    verifyFalse(list.isEmpty)

    list.clear
    verifyEq(list.size, 0)
    verify(list.isEmpty)
  }

//////////////////////////////////////////////////////////////////////////
// Contains/Index
//////////////////////////////////////////////////////////////////////////

  Void testContainsIndex()
  {
    foo := "foobar"[0..2]
    verify(foo !== "foo")
    list := Str?["a", "b", null, "c", null, "b", foo]

    //verifyEq([,].contains(null), false)
    verifyEq([,].contains("a"), false)

    verify(list.contains("a"))
    verify(list.contains("foo"))

    verify(list.containsSame("a"))
    verify(!list.containsSame("foo"))

    verifyEq(list.index("a"), 0)
    verifyEq(list.index("foo"), 6)

    verifyEq(list.indexSame("a"), 0)
    verifyEq(list.indexSame("foo"), null)

    verify(list.contains("b"))
    verifyEq(list.index("b"), 1)

    verify(list.contains("c"))
    verifyEq(list.index("c"), 3)

    verify(list.contains(null))
    verifyEq(list.index(null), 2)

    verifyFalse(list.contains("d"))
    verifyEq(list.index("d"), null)

    verifyEq(list.containsAll(Str[,]), true)
    verifyEq(list.containsAll(["a"]), true)
    verifyEq(list.containsAll(["c"]), true)
    verifyEq(list.containsAll(Str?[null]), true)
    verifyEq(list.containsAll(["x"]), false)
    verifyEq(list.containsAll(["b", "a"]), true)
    verifyEq(list.containsAll(["b", null, "a"]), true)
    verifyEq(list.containsAll(["b", "a", "c"]), true)
    verifyEq(list.containsAll(["b", "x"]), false)
    verifyEq(list.containsAll(["b", null, "foo"]), true)
    verifyEq(list.containsAllSame(["b", null, "foo"]), false)

    verifyEq(list.index("a", -5), null)
    verifyEq(list.index("a", -7), 0)
    verifyEq(list.index("b", 1), 1)
    verifyEq(list.index("b", 2), 5)
    verifyEq(list.index("b", -2), 5)
    verifyEq(list.index("b", -6), 1)
    verifyEq(list.index("foo", -1), 6)
    verifyEq(list.indexSame("foo", -1), null)

    verifyEq(list.index(null, 0), 2)
    verifyEq(list.index(null, 2), 2)
    verifyEq(list.index(null, 3), 4)

    verifyErr(IndexErr#) |,| { list.index("a", 7) }
    verifyErr(IndexErr#) |,| { list.index("a", -8) }
  }

//////////////////////////////////////////////////////////////////////////
// FirstLast
//////////////////////////////////////////////////////////////////////////

  Void testFirstLast()
  {
    verifyEq([,].first, null)
    verifyEq([,].last, null)

    verifyEq([5].first, 5)
    verifyEq([5].last,  5)

    verifyEq([1,2].first, 1)
    verifyEq([1,2].last,  2)

    verifyEq([1,2,3].first, 1)
    verifyEq([1,2,3].last,  3)
  }

//////////////////////////////////////////////////////////////////////////
// Stack
//////////////////////////////////////////////////////////////////////////

  Void testStack()
  {
    s := Int[,]

    verifyEq(s.peek, null); verifyEq(s.pop,  null)

    s.push(1)
    verifyEq(s.peek, 1);    verifyEq(s.pop,  1)
    verifyEq(s.peek, null); verifyEq(s.pop,  null)

    s.push(1);
    s.push(2)
    verifyEq(s.peek, 2);    verifyEq(s.pop,  2)
    verifyEq(s.peek, 1);    verifyEq(s.pop,  1)
    verifyEq(s.peek, null); verifyEq(s.pop,  null)
  }

//////////////////////////////////////////////////////////////////////////
// Each
//////////////////////////////////////////////////////////////////////////

  Void testEach()
  {
    values  := Int[,]
    indexes := Int[,]

    // empty list
    Int[,].each |Int value, Int index|
    {
      values.add(value)
      indexes.add(index)
    }
    verifyEq(values,  Int[,])
    verifyEq(indexes, Int[,])

    // list of one
    values.clear;
    indexes.clear;
    [ 7 ].each |Int value, Int index|
    {
      values.add(value)
      indexes.add(index)
    }
    verifyEq(values,  [7])
    verifyEq(indexes, [0])

    // list of two
    values.clear;
    indexes.clear;
    [ -9, 0xab ].each |Int value, Int index|
    {
      values.add(value)
      indexes.add(index)
    }
    verifyEq(values,  [-9, 0xab])
    verifyEq(indexes, [0, 1])

    // list of four
    values.clear;
    indexes.clear;
    [ 10, 20, 30, 40 ].each |Int value, Int index|
    {
      values.add(value)
      indexes.add(index)
    }
    verifyEq(values,  [10, 20, 30, 40])
    verifyEq(indexes, [0, 1, 2, 3])
  }

//////////////////////////////////////////////////////////////////////////
// Eachr
//////////////////////////////////////////////////////////////////////////

  Void testEachr()
  {
    values  := Int[,]
    indexes := Int[,]

    // empty list
    Int[,].eachr |Int value, Int index|
    {
      values.add(value)
      indexes.add(index)
    }
    verifyEq(values,  Int[,])
    verifyEq(indexes, Int[,])

    // list of one
    values.clear;
    indexes.clear;
    [ 7 ].eachr |Int value, Int index|
    {
      values.add(value)
      indexes.add(index)
    }
    verifyEq(values,  [7])
    verifyEq(indexes, [0])

    // list of two
    values.clear;
    indexes.clear;
    [ -9, 0xab ].eachr |Int value, Int index|
    {
      values.add(value)
      indexes.add(index)
    }
    verifyEq(values,  [0xab, -9])
    verifyEq(indexes, [1, 0])

    // list of four
    values.clear;
    indexes.clear;
    [ 10, 20, 30, 40 ].eachr |Int value, Int index|
    {
      values.add(value)
      indexes.add(index)
    }
    verifyEq(values,  [40, 30, 20, 10])
    verifyEq(indexes, [3, 2, 1, 0])

    // just value
    values.clear;
    indexes.clear;
    [ 1, 2, 3, 4, 5, 6, 7, 8 ].eachr |Int value|
    {
      values.add(value)
    }
    verifyEq(values,  [8, 7, 6, 5, 4, 3, 2, 1])
  }

//////////////////////////////////////////////////////////////////////////
// EachBreak
//////////////////////////////////////////////////////////////////////////

  Void testEachBreak()
  {
    x := ["a", "b", "c", "d"]
    n := 0
    verifyEq(x.eachBreak |Str s->Str| { return s == "b" ? "B" : null }, "B")
    verifyEq(x.eachBreak |Str s->Str| { return s == "x" ? "X" : null }, null)
    verifyEq(x.eachBreak |Str s, Int i->Str| { return i == 2 ? s : null }, "c")

    n = 0; x.eachBreak |Str s->Obj| { n++; return s == "b" ? true : null }; verifyEq(n, 2)
    n = 0; x.eachBreak |Str s->Obj| { n++; return s == "c" ? true : null }; verifyEq(n, 3)
    n = 0; x.eachBreak |Str s->Obj| { n++; return s == "x" ? true : null }; verifyEq(n, 4)
  }

//////////////////////////////////////////////////////////////////////////
// Find
//////////////////////////////////////////////////////////////////////////

  Void testFind()
  {
    list := [0, 10, 20, 30, 40, 60]

    // find
    verifyEq(list.find |Int v, Int i->Bool| { return v == 20 }, 20)
    verifyEq(list.find |Int v, Int i->Bool| { return i == 3 }, 30)
    verifyEq(list.find |Int v, Int i->Bool| { return false }, null)
    verifyEq(list.find |Int v->Bool| { return false }, null)
    verifyEq(list.find |->Bool| { return false }, null)

    // findIndex
    verifyEq(list.findIndex |Int v, Int i->Bool| { return v == 20 }, 2)
    verifyEq(list.findIndex |Int v, Int i->Bool| { return i == 3 }, 3)
    verifyEq(list.findIndex |Int v, Int i->Bool| { return false }, null)
    verifyEq(list.findIndex |Int v->Bool| { return false }, null)
    verifyEq(list.findIndex |->Bool| { return false }, null)

    // typed assign
    Int x := list.find |Int v->Bool| { return v.toStr == "40" }
    verifyEq(x, 40)

    // findAll
    verifyEq(list.findAll|Int v, Int i->Bool| { return v % 20 == 0 }, [0, 20, 40, 60])
    verifyEq(list.findAll|Int v, Int i->Bool| { return i % 2 == 0 },  [0, 20, 40])
    verifyEq(list.findAll|Int v, Int i->Bool| { return false },  Int[,])
    verifyEq(list.findAll|Int v->Bool| { return false },  Int[,])
    verifyEq(list.findAll|->Bool| { return false },  Int[,])

    // findType
    verifyEq(["a", 3, "b", 6sec].findType(Str#), ["a", "b"])
    verifyEq(["a", 3, "b", 6sec].findType(Str#).type, Str[]#)
    verifyEq(["a", 3, "b", 6sec, 5f].findType(Num#), [3, 5f])
    verifyEq(["a", 3, "b", 6sec, 5f].findType(Num#).type, Num[]#)
    verifyEq([null, "a", 3, "b", null, 5ms].findType(Duration#), [5ms])
    verifyEq(["a", 3, "b", 6sec, 5f].findType(Obj#), ["a", 3, "b", 6sec, 5f])

    // exclude
    verifyEq(list.exclude|Int v, Int i->Bool| { return v % 20 == 0 }, [10, 30])
    verifyEq(list.exclude|Int v, Int i->Bool| { return i % 2 == 0 },  [10, 30, 60])
    verifyEq(list.exclude|Int v, Int i->Bool| { return true },  Int[,])
    verifyEq(list.exclude|Int v->Bool| { return true },  Int[,])
    verifyEq(list.exclude|->Bool| { return true },  Int[,])

    // typed assign
    Int[] a := list.findAll |Int v->Bool| { return v.toStr.size == 1 }
    verifyEq(a, [0])
  }

//////////////////////////////////////////////////////////////////////////
// Reduce
//////////////////////////////////////////////////////////////////////////

  Void testReduce()
  {
    list := [3, 4, 5]
    verifyEq(list.reduce(0) |Obj r, Int v->Obj| { return v*2 + (Int)r }, 24)
    verifyEq(list.reduce(0) |Obj r, Int v->Obj| { return v*2 + r }, 24)
    verifyEq(list.reduce(10) |Obj r, Int v, Int i->Obj| { return v + (Int)r + i }, 25)
  }

//////////////////////////////////////////////////////////////////////////
// Map
//////////////////////////////////////////////////////////////////////////

  Void testMap()
  {
    list := [3, 4, 5]
    verifyEq(list.map(Int[,]) |Int v->Obj| { return v*2 },  [6, 8, 10])
    verifyEq(list.map([,]) |Int v->Obj?| { return null }, [null, null, null])
    verifyEq(list.map(Bool[,]) |Int v, Int i->Obj| { return i%2==0 },  [true, false, true])

    acc := [0, 1, 2]
    list.map(acc) |Int v->Obj| { return v }
    verifyEq(acc, [0, 1, 2, 3, 4, 5])
  }

//////////////////////////////////////////////////////////////////////////
// Any/All
//////////////////////////////////////////////////////////////////////////

  Void testAnyAll()
  {
    // empty
    list := Str[,]
    verifyEq(list.any |Str s->Bool| { return s.size == 3 }, false)
    verifyEq(list.all |Str s->Bool| { return s.size == 3 }, true)

    // all 3
    list = ["foo", "bar"]
    verifyEq(list.any |Str s->Bool| { return s.size == 3 }, true)
    verifyEq(list.all |Str s->Bool| { return s.size == 3 }, true)
    verifyEq(list.any |Str s->Bool| { return s.size == 4 }, false)
    verifyEq(list.all |Str s->Bool| { return s.size == 4 }, false)

    // one 3, one 4
    list = ["foo", "pool"]
    verifyEq(list.any |Str s->Bool| { return s.size == 3 }, true)
    verifyEq(list.all |Str s->Bool| { return s.size == 3 }, false)
    verifyEq(list.any |Str s->Bool| { return s.size == 4 }, true)
    verifyEq(list.all |Str s->Bool| { return s.size == 4 }, false)

    // one 3, one 4 with index
    list = ["foo", "pool"]
    verifyEq(list.any |Str s,Int i->Bool| { return s.size == 3 }, true)
    verifyEq(list.all |Str s,Int i->Bool| { return s.size == 3 }, false)
    verifyEq(list.any |Str s,Int i->Bool| { return s.size == 4 }, true)
    verifyEq(list.all |Str s,Int i->Bool| { return s.size == 4 }, false)
  }

//////////////////////////////////////////////////////////////////////////
// Min/Max
//////////////////////////////////////////////////////////////////////////

  Void testMinMax()
  {
    // empty
    list := Str[,]
    verifyEq(list.min, null)
    verifyEq(list.max, null)
    verifyEq(list.min |Str a, Str b->Int| { return a.size <=> b.size }, null)
    verifyEq(list.max |Str a, Str b->Int| { return a.size <=> b.size }, null)

    // doc example
    list = Str["albatross", "dog", "horse"]
    verifyEq(list.min, "albatross")
    verifyEq(list.max, "horse")
    verifyEq(list.min |Str a, Str b->Int| { return a.size <=> b.size }, "dog")
    verifyEq(list.max |Str a, Str b->Int| { return a.size <=> b.size }, "albatross")

    // with null
    list = Str?["a", null, "b"]
    verifyEq(list.min, null)
    verifyEq(list.max, "b")
  }

//////////////////////////////////////////////////////////////////////////
// Unique
//////////////////////////////////////////////////////////////////////////

  Void testUnique()
  {
    verifyEq(Str[,].unique, Str[,])
    verifyEq(["a"].unique, ["a"])
    verifyEq(["a", "b"].unique, ["a", "b"])
    verifyEq(["a", "b", "c"].unique, ["a", "b", "c"])
    verifyEq(["a", "a", "b", "c"].unique, ["a", "b", "c"])
    verifyEq(["a", "b", "a", "c"].unique, ["a", "b", "c"])
    verifyEq(["a", "b", "c", "a"].unique, ["a", "b", "c"])
    verifyEq(["a", null, "b", "c", "a"].unique, ["a", null, "b", "c"])
    verifyEq(["a", null, "b", "b", "c", "a", null, "c", "a", "a"].unique, ["a", null, "b", "c"])
  }

//////////////////////////////////////////////////////////////////////////
// Union
//////////////////////////////////////////////////////////////////////////

  Void testUnion()
  {
    verifyEq([0, 1, 2].union([2]).type, Int[]#)
    verifyEq(Int[,].union([2]), [2])
    verifyEq(Int[6].union(Int[,]), [6])
    verifyEq(Int[0, 1, 2].union(Int[1, 2, 3]), [0, 1, 2, 3])
    verifyEq(Int[0, 1, 2].union(Int[10, 20]), [0, 1, 2, 10, 20])
    verifyEq(Int[0, 1, 2, 1, 2, 0].union(Int[10, 20, 10, 10]), [0, 1, 2, 10, 20])
    verifyEq(Int?[null, 0, 1, 2].union(Int?[10, null, 20, 2]), [null, 0, 1, 2, 10, 20])
  }

//////////////////////////////////////////////////////////////////////////
// Intersection
//////////////////////////////////////////////////////////////////////////

  Void testIntersection()
  {
    verifyEq([0, 1, 2].intersection([2]).type, Int[]#)
    verifyEq(Int[,].intersection([2]), Int[,])
    verifyEq(Int[6].intersection(Int[,]), Int[,])
    verifyEq([4].intersection([5]), Int[,])
    verifyEq([0, 1, 2].intersection([2]), [2])
    verifyEq([0, 1, 2].intersection([0, 2]), [0,2])
    verifyEq([0, 1, 2].intersection([2, 0]), [0,2])
    verifyEq([0, 1, 2].intersection([0, 1, 2]), [0, 1, 2])
    verifyEq([0, 1, 2].intersection([0, 1, 2, 3]), [0, 1, 2])
    verifyEq([0, 1, 2].intersection([3, 2, 1, 0]), [0, 1, 2])
    verifyEq([0, 1, 2, 3].intersection([5, 3, 1]), [1, 3])
    verifyEq([0, null, 2].intersection([0, 1, 2, 3]), Int?[0, 2])
    verifyEq([0, null, 2].intersection([null, 0, 1, 2, 3]), [0, null, 2])
    verifyEq([0, 1, 2, 2, 1, 1].intersection([2, 2, 1, 0]), [0, 1, 2])
    verifyEq([0, 1, null, 2, 1, null, 1].intersection([2, null, 2, 1, 0]), [0, 1, null, 2])
  }

//////////////////////////////////////////////////////////////////////////
// Sort
//////////////////////////////////////////////////////////////////////////

  Void testSort()
  {
    x := Int[,]
    x.sort
    verifyEq(x, Int[,])

    x = [6, 3, 5, 2, 4, 1]
    x.sort
    verifyEq(x, Int[1, 2, 3, 4, 5, 6])
    x.sort
    verifyEq(x, Int[1, 2, 3, 4, 5, 6])
    x.sortr
    verifyEq(x, Int[6, 5, 4, 3, 2, 1])
    x.sortr
    verifyEq(x, Int[6, 5, 4, 3, 2, 1])

    x = [3, 1, 6, 4, 2, 5]
    x.sort |Int a, Int b->Int| { return a <=> b }
    verifyEq(x, Int[1, 2, 3, 4, 5, 6])
    x.sortr |Int a, Int b->Int| { return a <=> b }
    verifyEq(x, Int[6, 5, 4, 3, 2, 1])

    x = [3, 1, 6, 4, 2, 5]
    names := ["zero", "one", "two", "three", "four", "five", "six" ]
    comparator := |Int a, Int b->Int| { return names[a] <=> names[b] }
    x.sort(comparator)
    verifyEq(x, Int[5, 4, 1, 6, 3, 2])
    x.sortr(comparator)
    verifyEq(x, Int[2, 3, 6, 1, 4, 5])
  }

//////////////////////////////////////////////////////////////////////////
// Binary Search
//////////////////////////////////////////////////////////////////////////

  Void testBinarySearch()
  {
    x := Int[,]
    verifyEq(x.binarySearch(0), -1)
    verifyEq(x.binarySearch(99), -1)

    x = [4]
    verifyEq(x.binarySearch(0), -1)
    verifyEq(x.binarySearch(4), 0)
    verifyEq(x.binarySearch(5), -2)

    x = [4, 4]
    verifyEq(x.binarySearch(0), -1)
    verifyEq(x.binarySearch(4), 0)
    verifyEq(x.binarySearch(5), -3)

    x = [4, 6]
    verifyEq(x.binarySearch(3), -1)
    verifyEq(x.binarySearch(4), 0)
    verifyEq(x.binarySearch(5), -2)
    verifyEq(x.binarySearch(6), 1)
    verifyEq(x.binarySearch(7), -3)

    x = [4, 6, 11]
    verifyEq(x.binarySearch(-99), -1)
    verifyEq(x.binarySearch(3), -1)
    verifyEq(x.binarySearch(4), 0)
    verifyEq(x.binarySearch(5), -2)
    verifyEq(x.binarySearch(6), 1)
    verifyEq(x.binarySearch(7), -3)
    verifyEq(x.binarySearch(10), -3)
    verifyEq(x.binarySearch(11), 2)
    verifyEq(x.binarySearch(12), -4)
    verifyEq(x.binarySearch(99), -4)

    x = [4, 6, 11, 11]
    verifyEq(x.binarySearch(3), -1)
    verifyEq(x.binarySearch(4), 0)
    verifyEq(x.binarySearch(5), -2)
    verifyEq(x.binarySearch(6), 1)
    verifyEq(x.binarySearch(8), -3)
    verifyEq(x.binarySearch(11), 2)
    verifyEq(x.binarySearch(12), -5)

    y := ["4", "6", "11", "11"]
    f := |Str a, Str b->Int| { return a.toInt <=> b.toInt }
    verifyEq(y.binarySearch("3", f), -1)
    verifyEq(y.binarySearch("4", f), 0)
    verifyEq(y.binarySearch("5", f), -2)
    verifyEq(y.binarySearch("6", f), 1)
    verifyEq(y.binarySearch("8", f), -3)
    verifyEq(y.binarySearch("11", f), 2)
    verifyEq(y.binarySearch("12", f), -5)

    x = [2, 5, 7, 10, 11, 12, 15]
    verifyEq(x.binarySearch(1), -1)
    verifyEq(x.binarySearch(2), 0)
    verifyEq(x.binarySearch(3), -2)
    verifyEq(x.binarySearch(5), 1)
    verifyEq(x.binarySearch(6), -3)
    verifyEq(x.binarySearch(7), 2)
    verifyEq(x.binarySearch(9), -4)
    verifyEq(x.binarySearch(10), 3)
    verifyEq(x.binarySearch(11), 4)
    verifyEq(x.binarySearch(12), 5)
    verifyEq(x.binarySearch(13), -7)
    verifyEq(x.binarySearch(15), 6)
    verifyEq(x.binarySearch(16), -8)

    x.clear
    Int.random(100..113).times |Int a| { x.add(Int.random) }
    x.sort
    x.each |Int v, Int i| { verifyEq(x.binarySearch(v), i) }
  }

//////////////////////////////////////////////////////////////////////////
// Reverse
//////////////////////////////////////////////////////////////////////////

  Void testReverse()
  {
    verifyEq(Int[,].reverse, Int[,])
    verifyEq(Int[5].reverse, Int[5])
    verifyEq(Int[1,2].reverse, Int[2,1])
    verifyEq(Int[1,2,3].reverse, Int[3,2,1])
    verifyEq(Int[1,2,3,4].reverse, Int[4,3,2,1])
    verifyEq(Int[1,2,3,4,5].reverse, Int[5,4,3,2,1])
    verifyEq(Int[1,2,3,4,5,6].reverse, Int[6,5,4,3,2,1])
    verifyEq(Int[1,2,3,4,5,6,7].reverse, Int[7,6,5,4,3,2,1])
    verifyEq(Int[1,2,3,4,5,6,7,8].reverse, Int[8,7,6,5,4,3,2,1])
  }

//////////////////////////////////////////////////////////////////////////
// Swap
//////////////////////////////////////////////////////////////////////////

  Void testSwap()
  {
    x := [0, 1, 2, 3, 4]
    verifyEq(x.swap(0, 1),   [1, 0, 2, 3, 4])
    verifyEq(x.swap(-1, -2), [1, 0, 2, 4, 3])
    verifyEq(x.swap(2, -2),  [1, 0, 4, 2, 3])
  }

//////////////////////////////////////////////////////////////////////////
// Flatten
//////////////////////////////////////////////////////////////////////////

  Void testFlatten()
  {
    verifyEq([,].flatten, [,])
    verifyNotSame([,].flatten, [,])
    verifyEq([2].flatten, Obj?[2])
    verifyEq([2,3].flatten, Obj?[2,3])
    verifyEq([2,[3,4],5].flatten, Obj?[2,3,4,5])
    verifyEq([2,[3,[4,5]],[6,7]].flatten, Obj?[2,3,4,5,6,7])
    verifyEq([[[[34]]]].flatten, Obj?[34])
    verifyEq([[[[,]]]].flatten, Obj?[,])
    verifyEq([[[[1,2],3],4],5].flatten, Obj?[1,2,3,4,5])
  }

//////////////////////////////////////////////////////////////////////////
// Str
//////////////////////////////////////////////////////////////////////////

  Void testStr()
  {
    o := [,]
    verifyEq(o.toStr,     "[,]")
    verifyEq(o.join,      "")
    verifyEq(o.join("-"), "")
    verifyEq(o.join("-") |Obj x->Str| { return "($x)" }, "")

    s := ["foo"]
    verifyEq(s.toStr,      "[foo]")
    verifyEq(s.join,       "foo")
    verifyEq(s.join("-"),  "foo")
    verifyEq(s.join("; "), "foo")
    verifyEq(s.join("-") |Str x->Str| { return "($x)" }, "(foo)")

    s = [(Str)null]
    verifyEq(s.toStr,      "[null]")
    verifyEq(s.join,       "null")
    verifyEq(s.join("-"),  "null")
    verifyEq(s.join("; "), "null")
    verifyEq(s.join("-") |Str x->Str| { return "($x)" }, "(null)")

    s = ["a", "b", "c"]
    verifyEq(s.toStr,      "[a, b, c]")
    verifyEq(s.join,       "abc")
    verifyEq(s.join("-"),  "a-b-c")
    verifyEq(s.join("; "), "a; b; c")
    verifyEq(s.join("-") |Str x->Str| { return "($x)" }, "(a)-(b)-(c)")

    s = [null, "foo", null]
    verifyEq(s.toStr,      "[null, foo, null]")
    verifyEq(s.join,       "nullfoonull")
    verifyEq(s.join("-"),  "null-foo-null")
    verifyEq(s.join("; "), "null; foo; null")
  }

//////////////////////////////////////////////////////////////////////////
// AssignOps
//////////////////////////////////////////////////////////////////////////

  Void testAssignOps()
  {
    x := [1]
    x[0] += 1
    verifyEq(x.first, 2)
    verifyEq(x[0]++, 2); verifyEq(x.first, 3)
    verifyEq(++x[0], 4); verifyEq(x.first, 4)
    x[0] += x[0]
    verifyEq(x[0], 8)
    x.add(0xabcd)
    x[1] <<= 4
    verifyEq(x, [8, 0xabcd0])

    b := [false, false, true, true]
    b[0] |= Bool.fromStr("false")
    b[1] |= true
    b[2] |= false
    verifyEq(b[3] |= true, true)
    verifyEq(b, [false, true, true, true])
  }

//////////////////////////////////////////////////////////////////////////
// Readonly
//////////////////////////////////////////////////////////////////////////

  Void testReadonly()
  {
    // create rw list
    x := ["a", "b", "c"].trim
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
    verifyEq(r.type, Str[]#)
    verifyEq(r.isEmpty, false)
    verifyEq(r.size, 3)
    verifyEq(r.capacity, 3)
    verifyEq(r[0], "a")
    verifyEq(r[1], "b")
    verifyEq(r[2], "c")
    verifyEq(r[0..1], ["a", "b"])
    verifyEq(r.contains("b"), true)
    verifyEq(r.contains("x"), false)
    verifyEq(r.index("c"), 2)
    verifyEq(r.first, "a")
    verifyEq(r.last, "c")
    verifyEq(r.peek, "c")
    verifyEq(r.dup, ["a", "b", "c"])
    r.each |Str s, Int i| { verifyEq(r[i], s) }
    r.eachr |Str s, Int i| { verifyEq(r[i], s) }
    verifyEq(r.find |Str s->Bool| { return s == "b" }, "b")
    verifyEq(r.findAll |Str s->Bool| { return true }, ["a", "b", "c"])
    verifyEq(r.exclude |Str s->Bool| { return s == "c" }, ["a", "b"])
    verifyEq(r.any |Str s->Bool| { return true }, true)
    verifyEq(r.all |Str s->Bool| { return true }, true)
    verifyEq(r.reduce(0) |Obj result, Str ignore->Obj| { return result }, 0)
    verifyEq(r.map(Int[,]) |Str s->Obj| { return s.size}, [1, 1, 1])
    verifyEq(r.min, "a")
    verifyEq(r.max, "c")
    verifyEq(r.unique, ["a", "b", "c"])
    verifyEq(r.union(["a", "d"]), ["a", "b", "c", "d"])
    verifyEq(r.intersection(["a", "d"]), ["a"])
    verifyEq(r.toStr, "[a, b, c]")
    verifyEq(r.join, "abc")

    // verify all modification methods throw ReadonlyErr
    verifyErr(ReadonlyErr#) |,| { r.size = 10 }
    verifyErr(ReadonlyErr#) |,| { r.capacity = 10 }
    verifyErr(ReadonlyErr#) |,| { r[2] = "x" }
    verifyErr(ReadonlyErr#) |,| { r.add("x") }
    verifyErr(ReadonlyErr#) |,| { r.addAll(["x"]) }
    verifyErr(ReadonlyErr#) |,| { r.insert(2, "x") }
    verifyErr(ReadonlyErr#) |,| { r.insertAll(2, ["x"]) }
    verifyErr(ReadonlyErr#) |,| { r.remove("a") }
    verifyErr(ReadonlyErr#) |,| { r.removeAt(5) }
    verifyErr(ReadonlyErr#) |,| { r.removeSame("a") }
    verifyErr(ReadonlyErr#) |,| { r.clear }
    verifyErr(ReadonlyErr#) |,| { r.trim }
    verifyErr(ReadonlyErr#) |,| { r.pop }
    verifyErr(ReadonlyErr#) |,| { r.push("x") }
    verifyErr(ReadonlyErr#) |,| { r.sort }
    verifyErr(ReadonlyErr#) |,| { r.sortr }
    verifyErr(ReadonlyErr#) |,| { r.reverse }
    verifyErr(ReadonlyErr#) |,| { r.swap(0, 1) }

    // verify rw detaches ro
    x.add("d")
    r2 := x.ro
    verifySame(x.ro, r2)
    verifyNotSame(r2, r)
    verifyNotSame(x.ro, r)
    verifyEq(r.isRO, true)
    verifyEq(r.size, 3)
    verifyEq(r, ["a", "b", "c"])
    x.remove("b")
    r3 := x.ro
    verifySame(x.ro, r3)
    verifyNotSame(r2, r3)
    verifyNotSame(r3, r)
    verifyNotSame(r2, r)
    verifyNotSame(x.ro, r)
    verifyEq(r.size, 3)
    verifyEq(r, ["a", "b", "c"])

    // verify ro to rw
    y := r.rw
    verifyEq(y.isRW, true)
    verifyEq(y.isRO, false)
    verifySame(y.rw, y)
    verifySame(y.ro, r)
    verifyEq(y, r)
    verifyEq(r.isRO, true)
    verifyEq(r.size, 3)
    verifyEq(r, ["a", "b", "c"])
    verifyEq(y, ["a", "b", "c"])
    y.sortr
    verifyNotSame(y.ro, r)
    verifyEq(y.size, 3)
    verifyEq(y, ["c", "b", "a"])
    verifySame(y.rw, y)
    verifyEq(r, ["a", "b", "c"])
    y.add("d")
    verifyEq(y.size, 4)
    verifyEq(y, ["c", "b", "a", "d"])
    verifyEq(r.size, 3)
    verifyEq(r, ["a", "b", "c"])
  }

//////////////////////////////////////////////////////////////////////////
// ToImmutable
//////////////////////////////////////////////////////////////////////////

  Void testToImmutable()
  {
    a := ["a"]
    b := ["b"]
    c := ["c"]

    x := [a, b, c]
    xc := x.toImmutable

    y := [x]
    yc := y.toImmutable

    verifyNotSame(x.ro, xc)
    verifyEq(xc.isRO, true)
    verifyEq(xc.isImmutable, true)
    verifySame(xc.toImmutable, xc)
    verifyEq(xc[0], a)
    verifyEq(xc[1], b)
    verifyEq(xc[2], c)
    verifyEq(xc[0].isRO, true)
    verifyEq(xc[1].isRO, true)
    verifyEq(xc[2].isRO, true)

    verifyNotSame(y.ro, yc)
    verifyEq(yc.isRO, true)
    verifyEq(yc.isImmutable, true)
    verifySame(yc.toImmutable, yc)
    verifyEq(yc[0][0].isRO, true)
    verifyEq(yc[0][0].isImmutable, true)

    m := [0:"zero", 99:null]
    z := [m, null]
    zc := z.toImmutable
    verifyEq(zc.type.signature, "[sys::Int:sys::Str?]?[]")
    verify(zc.isRO)
    verify(zc[0].isRO)
    verify(zc[0].isImmutable)
    verifyEq(zc[0], m)
    verify(zc[1] == null)

    xrw := xc.rw
    verifyEq(xrw.isImmutable, false)
    verifyEq(xc.isImmutable, true)
    xrw[0] = ["Z"]
    verifyEq(xc[0], ["a"])
    verifyEq(xrw[0], ["Z"])

    verifyEq([,].isImmutable, false)
    verifyEq([,].ro.isImmutable, false)
    verifyEq([,].toImmutable.isImmutable, true)

    verifyEq([1,2].isImmutable, false)
    verifyEq([1,2].ro.isImmutable, false)
    verifyEq([1,2].toImmutable.isImmutable, true)

    verifyEq([this].isImmutable, false)
    verifyEq([this].ro.isImmutable, false)
    verifyErr(NotImmutableErr#) |,| { [this].toImmutable }
    verifyErr(NotImmutableErr#) |,| { [0, this, 2].toImmutable }
    verifyErr(NotImmutableErr#) |,| { [0, [this], 2].toImmutable }
  }

}