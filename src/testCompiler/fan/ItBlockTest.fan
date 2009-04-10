//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    7 Apr 09  Brian Frank  Creation
//

**
** ItBlockTest
**
class ItBlockTest : CompilerTest
{

//////////////////////////////////////////////////////////////////////////
// Basics
//////////////////////////////////////////////////////////////////////////

  Void testBasics()
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

//////////////////////////////////////////////////////////////////////////
// Targets
//////////////////////////////////////////////////////////////////////////

  Void testTargets()
  {
    compile(
     "class Acme
      {
        Obj a() { Foo { x = 'a' } }
        Obj b() { Foo() { x = 'b' } }
        Obj c() { f := Foo(); f { x = 'c' }; return f }
        Obj d() { f := Foo(); return f { x = 'd' } }
        Obj e() { foos(Foo { x ='e' }) }
        Obj f() { fooi(Foo { x ='f' }) }
        Obj g() { foos(Foo()) { x ='g' } }
        Obj h() { fooi(Foo()) { x ='h' } }
        Obj i() { Foo.fromStr(\"ignore\") { x = 'i' } } // we don't support short form

        Foo s := Foo { x = 's' }
        Foo t := Foo() { x = 't' }
        Foo u := fooi(Foo {x=3}) { x += 20 }
        static const ConstFoo v := ConstFoo {}
        static const ConstFoo w := ConstFoo { x = 'w' }
        static const ConstFoo c_x0 := ConstFoo.x0
        static const ConstFoo c_x2 := ConstFoo.x2

        static Foo foos(Foo f) { return f }
        Foo fooi(Foo f) { return f }
      }

      class Foo
      {
        static Foo fromStr(Str s) { return make }
        new make() {}
        Int x
      }

      const class ConstFoo
      {
        new make(|This|? f := null) { if (f != null) f(this) }
        static const ConstFoo x0 := ConstFoo {}
        static const ConstFoo x2 := ConstFoo { it.x = 2 }
        const Int x
      }")

    obj := pod.types.first.make
    verifyEq(obj->a->x, 'a')
    verifyEq(obj->b->x, 'b')
    verifyEq(obj->c->x, 'c')
    verifyEq(obj->d->x, 'd')
    verifyEq(obj->e->x, 'e')
    verifyEq(obj->f->x, 'f')
    verifyEq(obj->g->x, 'g')
    verifyEq(obj->h->x, 'h')
    verifyEq(obj->i->x, 'i')
    verifyEq(obj->s->x, 's')
    verifyEq(obj->t->x, 't')
    verifyEq(obj->u->x, 23)
    verifyEq(obj->v->x, 0)
    verifyEq(obj->w->x, 'w')
    verifyEq(obj->c_x0->x, 0)
    verifyEq(obj->c_x2->x, 2)
  }

//////////////////////////////////////////////////////////////////////////
// Add
//////////////////////////////////////////////////////////////////////////

  Void testAdd()
  {
    compile(
     "class Acme
      {
        Obj a() { return Foo { it.a=2 } }
        Obj b() { return Foo { 5, } }
        Obj c() { return Foo { 5, 7 } }
        Obj d() { return Foo { it.a=33; 5, 7; it.b=44; 9,12, } }
        Obj e() { return Widget { foo.b = 99 } }
        Obj f() { return Widget { Widget{name=\"a\"}, } }
        Obj g() { return Widget { Widget.make {name=\"a\"}, } }
        Obj h() { return Widget { $podName::Widget{name=\"a\"}, } }
        Obj i() { return Widget { $podName::Widget.make {name=\"a\"}, } }
        Obj j() { return Widget { kid1, } }
        Obj k() { return Widget { kid2, } }
        Obj l() { return Widget { Foo.kid3, } }
        Obj m()
        {
          return Widget
          {
            name = \"root\"
            Widget
            {
              kid1 { name = \"a.1\" },;
              name = \"a\"
              Widget.make { name = \"a.2\" },
            },
            $podName::Widget
            {
              name = \"b\"
              Widget { name = \"b.1\" },;
              foo.a = 999
            }
          }
        }

        static Widget kid1() { return Widget{name=\"a\"} }
        Widget kid2() { return Widget{name=\"a\"} }
      }

      class Foo
      {
        This add(Int i) { list.add(i); return this }
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
     verifyEq(x->list, [5, 7, 9, 12])

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

//////////////////////////////////////////////////////////////////////////
// This
//////////////////////////////////////////////////////////////////////////

  Void testThis()
  {
    compile(
     "class Acme
      {
        Obj a() { Foo { add(1).add(2) } }
      }

      class Foo
      {
        This add(Int x) { list.add(x); return this }
        Int[] list := Int[,]
      }")

    obj := pod.types.first.make
    verifyEq(obj->a->list, [1, 2])
  }

//////////////////////////////////////////////////////////////////////////
// Inference
//////////////////////////////////////////////////////////////////////////

  Void testInference()
  {
    compile(
     "class Acme
      {
        Obj a() { Foo().m1(null) { it.x = 'a' } }
        Obj b() { Foo().m1(null) { x = 'b' } }
        Obj c() { Foo().m2 { it.x = 'c' } }
        Obj d() { Foo().m2 { x = 'd' } }
        Obj e() { Foo().m2(5, null) { it.x = 'e' } }
        Obj f() { Foo().m2(5, null) { x = 'f' } }
        Obj g() { Foo().m3 { x = 'g' } }
        Obj h() { Foo().m4 { fill(2, 2) } }
        Obj i() { Foo().m4(9) { fill(3, 3) } }
      }

      class Foo
      {
        Foo m1(|Str|? f := null) { return this }
        Foo m2(Int a := 5, |Str|? f := null) { return this }
        This m3() { return this }
        Int[] m4(Int a := 5) { return Int[,] }
        Int x
      }")

    obj := pod.types.first.make
    verifyEq(obj->a->x, 'a')
    verifyEq(obj->b->x, 'b')
    verifyEq(obj->c->x, 'c')
    verifyEq(obj->d->x, 'd')
    verifyEq(obj->e->x, 'e')
    verifyEq(obj->f->x, 'f')
    verifyEq(obj->g->x, 'g')
    verifyEq(obj->h, [2,2])
    verifyEq(obj->i, [3,3,3])
  }

//////////////////////////////////////////////////////////////////////////
// Catch
//////////////////////////////////////////////////////////////////////////

  Void testCatch()
  {
    compile(
     "class Acme
      {
        Obj m(Str a)
        {
          try
          {
            if (a == \"throw\") throw ArgErr()
            else return Obj[,] { add(a) }
          }
          catch (Err e)
          {
            list := Obj[,] { add(e.toStr) }
            list.add(e.type.name)
            return list
          }
        }
      }")

    obj := pod.types.first.make
    verifyEq(obj->m("foo"), Obj["foo"])
    verifyEq(obj->m("throw"), Obj["sys::ArgErr", "ArgErr"])
  }

//////////////////////////////////////////////////////////////////////////
// This Funcs
//////////////////////////////////////////////////////////////////////////

/* TODO-IT
  Void testThisFuncs()
  {
    compile(
     "class Acme
      {
      }")
  }

  Void testThisFuncsErrors()
  {
    // errors CheckErrors
    verifyErrors(
     "class Foo
      {
        static |Void| m03(Void x) { throw Err() }
      }
      ",
      [ 3, 2, "????",
      ])
  }
*/

//////////////////////////////////////////////////////////////////////////
// ConstErr
//////////////////////////////////////////////////////////////////////////

  Void testConstErr()
  {
    compile(
     "class Acme
      {
        Int test1()  { Foo.make1.x }
        Int test2()  { Foo.make2(2).x }
        Int test3()  { Foo.make3 { x = 3 }.x }
        Int test4()  { Foo.make4 { x = -1 }.x }
        Int test5()  { Foo.make5 { x += 200 }.x }
        Int test6()  { return Foo.makeX(true) { x = 6 }.x }
        Int test7()  { return Foo.makeX(false) { x = 7 }.x }
        Int test8()  { Foo.factory5 { x += 200 }.x }  // line 10
        Int test9()  { Foo.factoryX(true) { x = 9 }.x }
        Int test10() { Foo.factoryX(false) { x = 10 }.x }
        Int test11() { Foo().factoryI1(true, 11).x }
        Int test12() { Foo().factoryI1(false, 12).x }

        Int bad1()   { f := Foo(); f { x = 6 }; return f.x }
        Foo bad2()   { Foo.factory5bad { x = 2 } }
        Foo bad3()   { Foo.factoryXbad(true) { x = 3 } }
        Foo bad4()   { Foo.factoryXbad(false) { x = 4 } }
      }

      class Foo
      {
        new make()         { }
        new make1()        { x = 1 }
        new make2(Int x)   { this.x = x }
        new make3(|This| f) { f(this) }
        new make4(|This| f) { f(this); x = 4 }

        static Foo factory5(|This| f) { return make5(f) }
        static Foo factory5bad(|This| f) { x := make5(f); f(x); return x }
        new make5(|This| f) { x += 30; f(this); x += 1000 }

        static Foo factoryX(Bool b, |This| f) { return makeX(b, f) }
        Foo factoryI1(Bool b, Int i) { return makeX(b) { it.x = i } }
        static Foo factoryXbad(Bool b, |This| f) { x := makeX(b, f); f(x); return x }
        new makeX(Bool b, |This| f)
        {
           if (b) { f(this); x += 10; return; }
           else { f(this); x += 20; return; }
        }

        const Int x := 9
      }")

    obj := pod.types.first.make
    verifyEq(obj->test1, 1)
    verifyEq(obj->test2, 2)
    verifyEq(obj->test3, 3)
    verifyEq(obj->test4, 4)
    verifyEq(obj->test5, 1239)
    verifyEq(obj->test6, 16)
    verifyEq(obj->test7, 27)
    verifyEq(obj->test8, 1239)
    verifyEq(obj->test9, 19)
    verifyEq(obj->test10, 30)
    verifyEq(obj->test11, 21)
    verifyEq(obj->test12, 32)
    verifyErr(ConstErr#) |,| { obj->bad1 }
    verifyErr(ConstErr#) |,| { obj->bad2 }
    verifyErr(ConstErr#) |,| { obj->bad3 }
    verifyErr(ConstErr#) |,| { obj->bad4 }
  }

//////////////////////////////////////////////////////////////////////////
// Errors
//////////////////////////////////////////////////////////////////////////

  Void testErrors()
  {
    // errors ResolveExpr
    verifyErrors(
     "class Foo
      {
        static Obj a() { return A {} }
        static Obj b() { return it.toStr }
        Obj c() { return it.toStr }
        static Obj d() { return B { x = 4 } }
        static Obj e() { return B { 6, } }
      }

      class A { new mk() {} }
      class B { }
      ",
      [ 3, 27, "Unknown method '$podName::A.make'",
        4, 27, "Invalid use of 'it' outside of it-block",
        5, 20, "Invalid use of 'it' outside of it-block",
        6, 31, "Unknown variable 'x'",
        7, 31, "Unknown method '$podName::B.add'",
      ])

    // errors CheckErrors
    verifyErrors(
     "class Foo
      {
        static Obj a() { return A { x } }          // missing comma
        static Obj b() { return B { 5, } }         // can't add Int
        static Obj c() { return B { A(), 5, } }    // can't add Int
        static Obj d() { return B { A.make, } }    // ok
        static Obj e() { return B { A { x=3 }, } } // ok
        static Obj f() { return B { A() } }        // missing comma
        static Obj g() { return B { A() {} } }     // missing comma
        static Obj h() { return B { A {} } }       // missing comma
        static Obj i(Foo f) { f { it = f } }       // not assignable
      }

      class A { Int x; Int y}
      class B { B add(A x) { return this } }
      ",
      [ 3, 31, "Not a statement",
        4, 31, "Invalid args add($podName::A), not (sys::Int)",
        5, 36, "Invalid args add($podName::A), not (sys::Int)",
        8, 31, "Not a statement",
        9, 35, "Not a statement",
       10, 33, "Not a statement",
       11, 29, "Left hand side is not assignable",
      ])
  }

  Void testAmbiguous()
  {
    verifyErrors(
     "class Foo
      {
        // instance methods
        Obj m04() { Foo { x } }
        Obj m05() { Bar { x } }
        // instance fields
        Obj m07() { Foo { y = 3 } }
        Obj m08() { Bar { y = 3 } }
        // static methods
        Obj m10() { Foo { s } }  // ok
        Obj m11() { Bar { s } }
        // static fields
        Obj m13() { Foo { it.y = t } }  // ok
        Obj m14() { Bar { it.y = t } }

        Void x() {}
        Int y
        static Void s() {}
        static const Int t := 8
      }

      class Bar
      {
        Void x() {}
        Int y
        static Void s() {}
        static const Int t := 8
      }
      ",
      [ 4, 21, "Ambiguous slot 'x' on both 'this' ($podName::Foo) and 'it' ($podName::Foo)",
        5, 21, "Ambiguous slot 'x' on both 'this' ($podName::Foo) and 'it' ($podName::Bar)",
        7, 21, "Ambiguous slot 'y' on both 'this' ($podName::Foo) and 'it' ($podName::Foo)",
        8, 21, "Ambiguous slot 'y' on both 'this' ($podName::Foo) and 'it' ($podName::Bar)",
       11, 21, "Ambiguous slot 's' on both 'this' ($podName::Foo) and 'it' ($podName::Bar)",
       14, 28, "Ambiguous slot 't' on both 'this' ($podName::Foo) and 'it' ($podName::Bar)",
      ])
  }
}