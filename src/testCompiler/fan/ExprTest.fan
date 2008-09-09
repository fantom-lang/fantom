//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Aug 06  Brian Frank  Creation
//

**
** ExprTest
**
class ExprTest : CompilerTest
{

//////////////////////////////////////////////////////////////////////////
// Literals
//////////////////////////////////////////////////////////////////////////

  Void testLiterals()
  {
    // null
    verifyExpr("null", null)

    // bool
    verifyExpr("false", false)
    verifyExpr("true", true)

    // int
    verifyExpr("0", 0)
    verifyExpr("1", 1)
    verifyExpr("0xabcd_1234_fedc_9876", 0xabcd_1234_fedc_9876)
    verifyExpr("493859850", 493859850)
    verifyExpr("-1", -1)
    verifyExpr("-123_456", -123_456)

    // float
    verifyExpr("0f",    0.0f)
    verifyExpr("0.0f",  0.0f)
    verifyExpr("1f",    1.0f)
    verifyExpr("1.2f",  1.2f)
    verifyExpr("-1.2F", -1.2f)

    // decimal
    verifyExpr("0.00d", 0.00d)
    verifyExpr("3d",    3d)
    verifyExpr("4e55d", 4e55d)
    verifyExpr("-5.2d", -5.2d)

    // str
    verifyExpr("\"\"",  "")
    verifyExpr("\"x\"", "x")
    verifyExpr("\"x\\ny\"", "x\ny")

    // duration
    verifyExpr("0ns",     0ns)
    verifyExpr("1ms",     1000_000ns)
    verifyExpr("1.2sec",  1_200_000_000ns)
    verifyExpr("1.5min",  90_000_000_000ns)
    verifyExpr("1hr",     3_600_000_000_000ns)
    verifyExpr("0.5day",  43_200_000_000_000ns)

    // uri
    verifyExpr("`x`",  `x`)
    verifyExpr("`http://fandev/path/file?query#frag`", `http://fandev/path/file?query#frag`)

    // type
    verifyExpr("Str#", Str#)
    verifyExpr("sys::Str#", Str#)
    verifyExpr("Str[]#", Str[]#)
    verifyExpr("Str:Int#", Str:Int#)
    verifyExpr("|Str a->Bool|#", |Str a->Bool|#)

    // type
    verifyExpr("Str#slice", Str#.method("slice"))
    verifyExpr("sys::Str#slice", Str#.method("slice"))
    verifyExpr("Str[]#add", Str[]#.method("add"))
    verifyExpr("Str:Int#caseInsensitive", Str:Int#.field("caseInsensitive"))
    verifyExpr("|Str a->Bool|#call2.returns", Bool#)
    verifyExpr("#echo", Obj#.method("echo"))
    verifyExpr("#echo.returns", Void#)

    // range
    verifyExpr("2..3",  2..3)
    verifyExpr("2...3", 2...3)

    // list
    verifyExpr("[,]", [,])
    verifyExpr("Str[,]", Str[,])
    verifyExpr("Int[3]", Int[3])
    verifyExpr("[0]",  [0])
    verifyExpr("[0,1]", [0,1])
    verifyExpr("Obj[0,1]", Obj[0,1])
    verifyExpr("[2,2f]", Num[2,2f])

    // map
    verifyExpr("[:]", [:])
    verifyExpr("Int:Str[:]", Int:Str[:])
    verifyExpr("[2:2f]", [2:2f])
    verifyExpr("[2:2f, 3:3]", Int:Num[2:2f, 3:3])
    verifyExpr("[2:2f, 3f:3f]", Num:Float[2:2f, 3f:3f])
  }

//////////////////////////////////////////////////////////////////////////
// Locals
//////////////////////////////////////////////////////////////////////////

  Void testLocals()
  {
    verifyExpr("a", 3, 3)
    verifyExpr("b", 2, 1, 2)
    verifyExpr("c", 3, 1, 2, "c := 3;")
    verifyExpr("c", 3, 1, 2, "Int c := 3;")
    verifyExpr("c", 7, 1, 2, "Int c; c = 7;")
    verifyExpr("c", null, 1, 2, "Int c;")
  }

//////////////////////////////////////////////////////////////////////////
// Operators
//////////////////////////////////////////////////////////////////////////

  Void testOperators()
  {
    verifyExpr("!a", true, false)
    verifyExpr("!a", false, true)

    verifyExpr("+a", 2, 2)
    verifyExpr("+a", -2f, -2f)

    verifyExpr("a === b", true, 3, 3)
    verifyExpr("a !== b", false, 3, 3)

    verifyExpr("a == null",  false, 3)
    verifyExpr("a === null", false, 3)
    verifyExpr("a != null",  true,  3)
    verifyExpr("a !== null", true,  3)
    verifyExpr("null == a",  true,  null, null, "Str a := null;")
    verifyExpr("null === a", true,  null, null, "Str a := null;")
    verifyExpr("null != a",  false, null, null, "Str a := null;")
    verifyExpr("null !== a", false, null, null, "Str a := null;")

    verifyExpr("a || b", true, true, true)
    verifyExpr("a || b", true, false, true)
    verifyExpr("a || b", true, true, false)
    verifyExpr("a || b", false, false, false)

    verifyExpr("a && b", true, true, true)
    verifyExpr("a && b", false, false, true)
    verifyExpr("a && b", false, true, false)
    verifyExpr("a && b", false, false, false)

    verifyExpr("(Obj)a is Str", false, 4)
    verifyExpr("(Obj)a is Str", true, "x")

    verifyExpr("(Obj)a isnot Str", true, 4)
    verifyExpr("(Obj)a isnot Str", false, "x")

    verifyExpr("(Obj)a as Str", null, 4)
    verifyExpr("(Obj)a as Str", "x", "x")

    verifyExpr("(Str)a", "x", "x")
    verifyErr(CastErr#) |,| { verifyExpr("(Str)((Obj)a)", null, 3) }

    verifyExpr("true ? a : b", 1, 1, 2)
    verifyExpr("false ? a : b", 2, 1, 2)
  }

//////////////////////////////////////////////////////////////////////////
// Call
//////////////////////////////////////////////////////////////////////////

  Void testCall()
  {
    // import static with arg
    verifyExpr("Str.spaces(1)", " ")
    verifyExpr("sys::Str.spaces(2)", "  ")

    // import static no args
    verifyExpr("Sys.homeDir()", Sys.homeDir)
    verifyExpr("sys::Sys.homeDir()", Sys.homeDir)
    verifyExpr("Sys.homeDir", Sys.homeDir)
    verifyExpr("sys::Sys.homeDir", Sys.homeDir)

    // import instance target
    verifyExpr("3.increment()", 4)
    verifyExpr("5.increment", 6)
    verifyExpr("2.increment().increment.isEven", true)

    // default args
    verifyExpr("\"abcb\".index(\"b\")", 1)
    verifyExpr("\"abcb\".index(\"b\", 2)", 3)

    // instance myself
    verifyExpr("ifoo", "ifoo")
    verifyExpr("ifoo()", "ifoo")
    verifyExpr("this.ifoo", "ifoo")
    verifyExpr("this.ifoo()", "ifoo")

    // static myself
    verifyExpr("sfoo", "sfoo")
    verifyExpr("sfoo()", "sfoo")
    verifyExpr("Foo.sfoo", "sfoo")
    verifyExpr("Foo.sfoo()", "sfoo")
    verifyExpr("${podName}::Foo.sfoo", "sfoo")
    verifyExpr("${podName}::Foo.sfoo()", "sfoo")

    // generics
    verifyExpr("x.negate", -20, [0, 10, 20, 30], null, "Int x; x = a[2];")
  }

//////////////////////////////////////////////////////////////////////////
// Dynamic Call
//////////////////////////////////////////////////////////////////////////

  Void testDynamicCall()
  {
    // dynamic calls
    verifyExpr("((Obj)3)->negate", -3)
    verifyExpr("((Obj)3)->plus(2)", 5)
    verifyExpr("((Obj)3)->plus = 6", 9)
  }

//////////////////////////////////////////////////////////////////////////
// Safe Calls
//////////////////////////////////////////////////////////////////////////

  Void testSafe()
  {
    verifyExpr("a?.size()", 3, "abc")
    verifyExpr("a?.size()", null, xNull)
    verifyExpr("a?->size()", 6, "foobar")
    verifyExpr("a?->size()", null, xNull)

    verifyExpr("a?.size", 3, "abc")
    verifyExpr("a?.size", null, xNull)
    verifyExpr("a?->size", 6, "foobar")
    verifyExpr("a?->size", null, xNull)

    verifyExpr("a?.size()?.plus(6)", 9, "abc")
    verifyExpr("a?.size()?.plus(6)", null, xNull)
    verifyExpr("a?->size()?->plus(6)", 12, "foobar")
    verifyExpr("a?->size()?->plus(6)", null, xNull)

    verifyExpr("a?.size?.plus(6)", 9, "abc")
    verifyExpr("a?.size?.plus(6)", null, xNull)
    verifyExpr("a?->size?->plus(6)", 12, "foobar")
    verifyExpr("a?->size?->plus(6)", null, xNull)
  }

//////////////////////////////////////////////////////////////////////////
// Elvis
//////////////////////////////////////////////////////////////////////////

  Void testElvis()
  {
    verifyExpr("a?:\"x\"", "abc", "abc")
    verifyExpr("a?:\"x\"", "x", xNull)
    verifyExpr("a.index(\"b\")?:-1", 1, "abc")
    verifyExpr("a.index(\"b\")?:-1", -1, "xyz")

    verifyExpr("a ?: b ?: \"x\"", "foo", "foo", "bar")
    verifyExpr("a ?: b ?: \"x\"", "foo", "foo", xNull)
    verifyExpr("a ?: b ?: \"x\"", "bar", xNull, "bar")
    verifyExpr("a ?: b ?: \"x\"", "x",   xNull, xNull)

    verifyExpr("a ?: b < \"m\"", true, "a", "z")
    verifyExpr("a ?: b < \"m\"", false, xNull, "z")
  }

//////////////////////////////////////////////////////////////////////////
// Shortcuts
//////////////////////////////////////////////////////////////////////////

  Void testShortcuts()
  {
    // math operators
    verifyExpr("-a", -7, 7)
    verifyExpr("a + b", 3, 1, 2)
    verifyExpr("a - b", 2, 5, 3)
    verifyExpr("a * b", 12, 4, 3)
    verifyExpr("a / b", 3, 12, 4)
    verifyExpr("a % b", 1, 5, 2)

    // bitwise operators
    verifyExpr("~a", 0xffff_ffff_ffff_5432, 0xabcd)
    verifyExpr("a >> b", 0xa, 0xab, 4)
    verifyExpr("a << b", 0xab0, 0xab, 4)
    verifyExpr("a & b", 0x8a, 0xab, 0x9e)
    verifyExpr("a | b", 0xbf, 0xab, 0x9e)
    verifyExpr("a ^ b", 0x35, 0xab, 0x9e)

    // equality
    verifyExpr("a == b", true, "x", "x")
    verifyExpr("a == null", false, "x", "x")
    verifyExpr("null == a", false, "x", "x")
    verifyExpr("a != b", false, "x", "x")
    verifyExpr("a != null", true, "x", "x")
    verifyExpr("null != a", true, "x", "x")

    // comparisons
    verifyExpr("a < b", true, 2, 3)
    verifyExpr("a < b", false, 2, 2)
    verifyExpr("a <= b", true, 2, 3)
    verifyExpr("a <= b", true, 2, 2)
    verifyExpr("a <= b", false, 2, 1)
    verifyExpr("a > b", true, 4, 3)
    verifyExpr("a > b", false, 4, 9)
    verifyExpr("a >= b", true, 4, 3)
    verifyExpr("a >= b", true, 2, 2)
    verifyExpr("a >= b", false, 2, 4)
    verifyExpr("a <=> b", 0, 3, 3)
    verifyExpr("a <=> b", -1, 3, 7)
    verifyExpr("a <=> b", +1, -1, -2)

    // get
    verifyExpr("a[b]", 'b', "abc", 1)
    verifyExpr("a[b]", 'c', "abc", -1)

    // set
    verifyExpr("a[b] = 99", [0, 99, 2], [0, 1, 2], 1)
    verifyExpr("a[b] = 99", [99, 1, 2], [0, 1, 2], -3)

    // slice
    verifyExpr("a[b]", [1,2], [0, 1, 2, 3], 1..2)
    verifyExpr("a[b]", [1], [0, 1, 2, 3], 1...2)
    verifyExpr("a[b]", [2, 3], [0, 1, 2, 3], -2..-1)
    verifyExpr("a[b]", [2], [0, 1, 2, 3], -2...-1)
  }

//////////////////////////////////////////////////////////////////////////
// Assignments
//////////////////////////////////////////////////////////////////////////

  Void testAssignments()
  {
    verifyAssignments("a")
  }

  Void verifyAssignments(Str v)
  {
    verifyExpr("$v", 2, 1, 2, "$v = b;")

    verifyExpr("$v", 5, 2, 3, "$v = a; $v+= b;")
    verifyExpr("$v", -1, 2, 3, "$v = a; $v-= b;")
    verifyExpr("$v", 6, 2, 3, "$v = a; $v*= b;")
    verifyExpr("$v", 3, 6, 2, "$v = a; $v/= b;")
    verifyExpr("$v", 2, 8, 3, "$v = a; $v%= b;")

    verifyExpr("$v", 0xab, 0xabcd, 8, "$v = a; $v>>= b;")
    verifyExpr("$v", 0xabcd0, 0xabcd, 4, "$v = a; $v<<= b;")
    verifyExpr("$v", 0x8a, 0xab, 0x9e, "$v = a; $v&= b;")
    verifyExpr("$v", 0xbf, 0xab, 0x9e, "$v = a; $v|= b;")
    verifyExpr("$v", 0x35, 0xab, 0x9e, "$v = a; $v^= b;")
  }

//////////////////////////////////////////////////////////////////////////
// Increment Operators
//////////////////////////////////////////////////////////////////////////

  Void testIncrementOps()
  {
    verifyIncrementOps("a", true)
  }

  Void verifyIncrementOps(Str v, Bool testFloat)
  {
    verifyExpr("++$v", 3, 2, 0, "$v = a;")
    verifyExpr("$v++", 2, 2, 0, "$v = a;")
    verifyExpr("[$v,b]", [2,3], 0, 2, "$v = b++;")
    verifyExpr("[$v,b]", [3,3], 0, 2, "$v = ++b;")

    verifyExpr("--$v", 1, 2, 0, "$v = a;")
    verifyExpr("$v--", 2, 2, 0, "$v = a;")
    verifyExpr("[$v,b]", [2,1], 0, 2, "$v = b--;")
    verifyExpr("[$v,b]", [1,1], 0, 2, "$v = --b;")

    verifyExpr("--a == b", true, 3, 2)

    if (testFloat)
    {
      verifyExpr("++a", 3f, 2f)
      verifyExpr("a++", 2f, 2f)
      verifyExpr("[a,b]", [2f,3f], 0f, 2f, "a = b++;")
      verifyExpr("[a,b]", [3f,3f], 0f, 2f, "a = ++b;")

      verifyExpr("--a", 1f, 2f)
      verifyExpr("a--", 2f, 2f)
      verifyExpr("[a,b]", [2f,1f], 0f, 2f, "a = b--;")
      verifyExpr("[a,b]", [1f,1f], 0f, 2f, "a = --b;")
    }
  }

  Void testIncrementMore()
  {
    src :=
     "class Foo
      {
        Int f() { return a += b++ }
        Int g() { return a += ++b }
        Void h() { 3.times |,| { a = (b++) } }
        Int i() { return a += b++ + (c++).toInt }
        Void j() { x := 2; a = |->Int| { return x++ }.call0; b = x } // cvar field

        Int a := 2
        Int b := 3
        Float c := 4f
      }"
     compile(src)

     t := pod.types.first

     o := t.make
     verifyEq(t.method("f").callOn(o, null), 5)
     verifyEq(o->a, 5)
     verifyEq(o->b, 4)

     o = t.make
     verifyEq(t.method("g").callOn(o, null), 6)
     verifyEq(o->a, 6)
     verifyEq(o->b, 4)

     o = t.make
     verifyEq(t.method("h").callOn(o, null), null)
     verifyEq(o->a, 5)
     verifyEq(o->b, 6)

     o = t.make
     verifyEq(t.method("i").callOn(o, null), 9)
     verifyEq(o->a, 9)
     verifyEq(o->b, 4)
     verifyEq(o->c, 5.0f)

     o = t.make
     verifyEq(t.method("j").callOn(o, null), null)
     verifyEq(o->a, 2)
     verifyEq(o->b, 3)
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Void testFields()
  {
    // don't rely on field initializers in this test
    verifyExpr("f", 7, 0, 0, "f = 7;")
    verifyAssignments("f")
    verifyIncrementOps("f", false)

    // const static
    verifyExpr("sf", 1972)

    // generics
    verifyExpr("tue", Weekday.tue, null, null, "Weekday tue := Weekday.values[2];")
  }

//////////////////////////////////////////////////////////////////////////
// Safe Fields
//////////////////////////////////////////////////////////////////////////

  Void testSafeFields()
  {
    verifyExpr("x?.f", 7, 0, 0, "f = 7; Foo x := this;")
    verifyExpr("x?.f", null, 0, 0, "f = 7; Foo x := null;")
  }

//////////////////////////////////////////////////////////////////////////
// Str Concat
//////////////////////////////////////////////////////////////////////////

  Void testStrConcat()
  {
    verifyExpr("\"\$a \$b\"", "4 5", 4, 5)
    verifyExpr("\"x\" + a", "x7", 7)
    verifyExpr("a + \"x\"", "7x", 7)

    verifyExpr("a += \"y\"", "xy", "x")
  }

//////////////////////////////////////////////////////////////////////////
// Test Construction Calls
//////////////////////////////////////////////////////////////////////////

  Void testConstruction()
  {
    verifyExpr("Version(\"3.4.9\")", Version.make([3,4,9]))
    verifyExpr("sys::Version(\"\${a}.99\")", Version.make([3,6,99]), "3.6")
    verifyExpr("Range(3,7,true)", Range.make(3, 7,true))
    verifyExpr("sys::Range(3,7,false)", Range.make(3, 7,false))

    // verify fromStr gets priority
    compile(
     "class Foo
      {
        Obj a() { return Foo(\"a\") }

        new make(Str n) { name = \"make \$n\" }
        static Foo fromStr(Str n) { return make(n) {name = \"fromStr \$n\"} }
        Str name
      }
      ")

    obj := pod.types.first.make(["z"])
    verifyEq(obj->name, "make z")
    verifyEq(obj->a->name, "fromStr a")

    // but fromStr only gets priority if both have Str args
    compile(
     "class Foo
      {
        Obj a() { return Foo(\"a\") }
        Obj b() { return Foo(3) }

        static Foo make(Int n) { return m {name = \"make \$n\"} }
        static Foo fromStr(Str n) { return m {name = \"fromStr \$n\"} }
        new m() {}
        Str name
      }
      ")

    obj = pod.types.first.make([77])
    verifyEq(obj->name, "make 77")
    verifyEq(obj->a->name, "fromStr a")
    verifyEq(obj->b->name, "make 3")

    // ResolveExpr errors
    verifyErrors(
     "class Foo
      {
        static Obj a() { return SA(\"x\") }
      }

      class SA { new makex() {} }
      ",
      [ 3, 27, "Unknown construction method '$podName::SA.make'",
      ])

    // CheckErrors errors
    verifyErrors(
     "class Foo
      {
        static Obj a() { return SA(\"x\") }
        static Obj b() { return SB(\"x\") }
        static Obj c() { return SC() }
      }

      class SA { SA fromStr(Str a) {return null} }
      class SB { static SA fromStr(Str a) {return null} }
      class SC { static SA make() {return null} new m() {} }
      ",
      [ 3, 27, "Cannot call instance method 'fromStr' in static context",
        4, 27, "Construction method '$podName::SB.fromStr' must return 'SB'",
        5, 27, "Construction method '$podName::SC.make' must return 'SC'",
      ])
  }

//////////////////////////////////////////////////////////////////////////
// Test With Blocks
//////////////////////////////////////////////////////////////////////////

  Void testWithBlocks()
  {
    compile(
     "class Acme
      {
        static Obj a() { return Foo.make { i = 77 } }
        static Obj b() { return Foo.make { i = 9; j += 6 } }
        static Obj c() { return Foo.make { inc } }
        static Obj d() { return Foo { i = 10; j = 11; inc } }
        static Obj e() { return Str[,] { size = 33 } }
        static Obj f()
        {
          return Foo
          {
            i=10;
            kid = Foo
            {
              i=20;
              kid = Foo {i=30}
              kid.j = 300
            }
          }
        }

        Foo x := Foo { i=-3; j=-5 }
      }


      class Foo
      {
        Foo inc() { i++; j++; return this }
        Int i := 2
        Int j := 5
        Foo kid
      }
      ")

     t := pod.types.first

     x := t.method("a").call0
     verifyEq(x->i, 77)
     verifyEq(x->j, 5)

     x = t.method("b").call0
     verifyEq(x->i, 9)
     verifyEq(x->j, 11)

     x = t.method("c").call0
     verifyEq(x->i, 3)
     verifyEq(x->j, 6)

     x = t.method("d").call0
     verifyEq(x->i, 11)
     verifyEq(x->j, 12)

     x = t.method("e").call0
     verifyEq(x->type, Str[]#)
     verifyEq(x->size, 33)
     verifyEq(x->capacity, 33)

     x = t.method("f").call0
     verifyEq(x->i, 10)
     verifyEq(x->kid->i, 20)
     verifyEq(x->kid->kid->i, 30)
     verifyEq(x->kid->kid->j, 300)

     x = t.field("x").get(t.make)
     verifyEq(x->i, -3)
     verifyEq(x->j, -5)
  }

  Void testWithBlockAdd()
  {
    compile(
     "class Acme
      {
        Obj a() { return Foo { a=2 } }
        Obj b() { return Foo { 5 } }
        Obj c() { return Foo { 5; 7 } }
        Obj d() { return Foo { a=33; 5; 7; b=44; 9 } }
        Obj e() { return Widget { foo.b = 99 } }
        Obj f() { return Widget { Widget{name=\"a\"}; } }
        Obj g() { return Widget { Widget.make {name=\"a\"} } }
        Obj h() { return Widget { $podName::Widget{name=\"a\"} } }
        Obj i() { return Widget { $podName::Widget.make {name=\"a\"} } }
        Obj j() { return Widget { kid1 } }
        Obj k() { return Widget { kid2 } }
        Obj l() { return Widget { Foo.kid3 } }
        Obj m()
        {
          return Widget
          {
            name = \"root\"
            Widget
            {
              kid1 { name = \"a.1\" }
              name = \"a\"
              Widget.make { name = \"a.2\" }
            }
            $podName::Widget
            {
              name = \"b\"
              Widget { name = \"b.1\" }
              foo.a = 999
            }
          }
        }

        static Widget kid1() { return Widget{name=\"a\"} }
        Widget kid2() { return Widget{name=\"a\"} }
      }

      class Foo
      {
        Void add(Int i) { list.add(i) }
        Int a := 'a'
        Int b := 'b'
        Int[] list := Int[,]
        static Widget kid3() { return Widget{name=\"a\"} }
      }

      class Widget
      {
        This add(Widget w) { kids.add(w); return this }
        Str name
        Widget[] kids := Widget[,]
        Foo foo := Foo { a = 11; b = 22 }
      }
      ")

     obj := pod.types.first.make

     x := obj->a
     verifyEq(x->a, 2)
     verifyEq(x->b, 'b')
     verifyEq(x->list, Int[,])

     x = obj->b
     verifyEq(x->a, 'a')
     verifyEq(x->b, 'b')
     verifyEq(x->list, [5])

     x = obj->c
     verifyEq(x->a, 'a')
     verifyEq(x->b, 'b')
     verifyEq(x->list, [5, 7])

     x = obj->d
     verifyEq(x->a, 33)
     verifyEq(x->b, 44)
     verifyEq(x->list, [5, 7, 9])

     x = obj->e
     verifyEq(x->name, null)
     verifyEq(x->kids->size, 0)
     verifyEq(x->foo->a, 11)
     verifyEq(x->foo->b, 99)
     verifyEq(x->foo->list, Int[,])

     ('f'..'l').each |Int i|
     {
       x = obj.type.method(i.toChar).call1(obj)
       verifyEq(x->kids->first->name, "a")
     }

     x = obj->m
     verifyEq(x->name, "root")
     verifyEq(x->kids->get(0)->name, "a")
     verifyEq(x->kids->get(0)->kids->get(0)->name, "a.1")
     verifyEq(x->kids->get(0)->kids->get(1)->name, "a.2")
     verifyEq(x->kids->get(1)->name, "b")
     verifyEq(x->kids->get(1)->kids->get(0)->name, "b.1")
     verifyEq(x->kids->get(1)->foo->a, 999)
  }


  Void testWithBlockErrors()
  {
    // errors
    verifyErrors(
     "class Foo
      {
        static Obj a() { return A {} }
        static Obj b() { return B { x = 4 } }
        static Obj c() { return B { 6 } }
      }

      class A { new mk() {} }
      class B { }
      ",
      [ 3, 27, "Unknown slot '$podName::A.make'",
        4, 31, "Unknown slot '$podName::B.x'",
        5, 31, "Unknown method '$podName::B.add'",
      ])

    // errors
    verifyErrors(
     "class Foo
      {
        static Obj a() { return A { x } }
        static Obj b() { return B { 5 } }
        static Obj c() { return B { A.make } } // ok
        static Obj d() { return B { A { x=3 } } } // ok
        static Obj e() { return B { A { x=3 }; 5 } }
      }

      class A { Int x; Int y}
      class B { Void add(A x) {} }
      ",
      [ 3, 31, "Not a statement",
        4, 31, "Invalid args add($podName::A), not (sys::Int)",
        7, 42, "Invalid args add($podName::A), not (sys::Int)",
      ])
  }

//////////////////////////////////////////////////////////////////////////
// Call Operator
//////////////////////////////////////////////////////////////////////////

  Void testCallOperator()
  {
    compile(
       "class Foo
        {
          Func funcField := Foo#.method(\"m4\").func

          static Int nine() { return 9 }
          static Func nineFunc() {  return Foo#.method(\"nine\").func }

          static Int m1(Int a) { return a }
          static Int m4(Int a, Int b, Int c, Int d) { return d }
          static Int m8(Int a, Int b, Int c, Int d, Int e, Int f, Int g, Int h) { return h }

          Int i1(Int a) { return a }
          Int i4(Int a, Int b, Int c, Int d) { return d }
          Int i7(Int a, Int b, Int c, Int d, Int e, Int f, Int g) { return g }

          static Int callClosure(|->Int| c) { return c() }

          static Obj a()
          {
            m := Foo#.method(\"nine\").func
            return m()
          }

          static Obj b()
          {
            m := |->Int| { return 69 }
            return m()
          }

          static Obj c(Int a, Int b)
          {
            m := |Int x, Int y->Int| { return x + y }
            return m(a, b)
          }

          static Obj d() { return Foo#.method(\"nine\").func()() }

          static Obj e() { return ((Func)Foo#.method(\"nineFunc\").func()())() }

          static Int f()
          {
            m := (|-> |->Int| |)Foo#.method(\"nineFunc\").func
            return m()()
          }

          static Obj g() { return Foo#.method(\"m1\").func()(7) }
          static Obj h() { return Foo#.method(\"m4\").func()(10, 11, 12, 13) }
          static Obj i() { return Foo#.method(\"m8\").func()(1, 2, 3, 4, 5, 6, 7, 8) }

          Obj j() { return Foo#.method(\"i1\").func()(this, 6) }
          Obj k() { return Foo#.method(\"i4\").func()(this, 101, 111, 121, 131) }
          Obj l() { return Foo#.method(\"i7\").func()(this, -1, -2, -3, -4, -5, -6, -7) }

          Int m(Int p)
          {
            list := [ (|Int a->Int|) type.method(\"m1\").func() ]
            return list[0](p)
          }

          Obj o(Int p)
          {
            return (funcField)(0, 1, 2, p)
          }

          Obj q(Int p)
          {
            return Foo#.method(\"callClosure\").func()() |->Int| { return p }
          }
        }")

    // compiler.fpod.dump
    t := pod.types[0]
    obj := t.make
    verifyEq(obj->a, 9)
    verifyEq(obj->b, 69)
    verifyEq(obj->c(10, 3), 13)
    verifyEq(obj->d, 9)
    verifyEq(obj->e, 9)
    verifyEq(obj->f, 9)
    verifyEq(obj->g, 7)
    verifyEq(obj->h, 13)
    verifyEq(obj->i, 8)
    verifyEq(obj->j, 6)
    verifyEq(obj->k, 131)
    verifyEq(obj->l, -7)
    verifyEq(obj->m(54), 54)
    verifyEq(obj->o(33), 33)
    verifyEq(obj->q('x'), 'x')
  }

  Void testCallOperatorErrors()
  {
    verifyErrors(
     "class Foo
      {
        static Void a(Str x) { x() }
        static Void b() { Str x; x() }
        static Void c() { x := 44; x() }
        static Void d()
        {
          m := |Int a, Int b, Int c, Int d, Int e, Int f, Int g, Int h, Int j| {}
          m(0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
        }

        static Void m9(Int a, Int b, Int c, Int d, Int e, Int f, Int g, Int h, Int j) {}
      }",
      [
        3, 26, "Cannot call local variable 'x' like a function",
        4, 28, "Cannot call local variable 'x' like a function",
        5, 30, "Cannot call local variable 'x' like a function",
        9,  5, "Tough luck - cannot use () operator with more than 8 arguments, use call(List)",
      ])
  }

//////////////////////////////////////////////////////////////////////////
// Errors
//////////////////////////////////////////////////////////////////////////

  Void testErrors()
  {
    // errors
    verifyErrors(
     "class Foo
      {
        static Obj a() { return foobar }
        static Obj b() { return 3.foobar }
        static Obj c() { return 3.noway() }
        static Obj d() { return 3.nope(3) }
        static Obj e() { return sys::Str.foo }
        static Obj f() { return sys::Str.foo() }
        static Obj g(Int x) { x := 3 }
        static Obj h(Int y) { Int y; }
        static Obj i() { z := 3; z := 5 }
        static Obj j() { return foobar.x }
        static Obj k() { return 8f.foobar().x.y }
        static Obj l() { return foo + bar }
        static Obj m() { return (4.foo.ouch + bar().boo).rightOn }
        static Obj n(Str x) { return x++ }
        static Obj o(Str x) { return --x }
        static Obj q(Str x) { return x / 3 }
        static Obj r(Str x) { return x |= 3 }
        static Obj s(Str x) { return x?.foo }
        static Obj t(Str x) { return x?.foo() }
        static Obj u() { return Str#bad }
        static Obj v() { return #bad }
      }",
      [ 3, 27, "Unknown variable 'foobar'",
        4, 29, "Unknown slot 'sys::Int.foobar'",
        5, 29, "Unknown method 'sys::Int.noway'",
        6, 29, "Unknown method 'sys::Int.nope'",
        7, 36, "Unknown slot 'sys::Str.foo'",
        8, 36, "Unknown method 'sys::Str.foo'",
        9, 25, "Variable 'x' is already defined in current block",
       10, 25, "Variable 'y' is already defined in current block",
       11, 28, "Variable 'z' is already defined in current block",
       12, 27, "Unknown variable 'foobar'",
       13, 30, "Unknown method 'sys::Float.foobar'",
       14, 27, "Unknown variable 'foo'",
       14, 33, "Unknown variable 'bar'",
       15, 30, "Unknown slot 'sys::Int.foo'",
       15, 41, "Unknown method '$podName::Foo.bar'",
       16, 32, "Unknown method 'sys::Str.increment'",
       17, 32, "Unknown method 'sys::Str.decrement'",
       18, 32, "Unknown method 'sys::Str.div'",
       19, 32, "Unknown method 'sys::Str.or'",
       20, 35, "Unknown slot 'sys::Str.foo'",
       21, 35, "Unknown method 'sys::Str.foo'",
       22, 27, "Unknown slot literal 'sys::Str.bad'",
       23, 27, "Unknown slot literal '$podName::Foo.bad'",
       ])
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  const static Str xNull := "_null_"

  Void verifyExpr(Str code, Obj result, Obj a := null, Obj b := null, Str more := "")
  {
    params := ""
    if (a != null) params = a.type.signature+ " a"
    if (b != null) params += ", " + b.type.signature + " b"

    src :=
     "class Foo
      {
        new make() { return }

        Str ifoo() { return \"ifoo\" }
        static Str sfoo() { return \"sfoo\" }

        Obj func($params) { $more return $code }

        Int f
        const static Int sf := 1972
      }"
     compile(src)
     // compiler.fpod.dump

     aarg := a == xNull ? null : a
     barg := b == xNull ? null : b

     t := pod.types.first
     instance := t.method("make").call0
     actual := t.method("func").call([instance, aarg, barg])
     verifyEq(actual, result)
   }

}