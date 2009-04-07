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

        static Foo foos(Foo f) { return f }
        Foo fooi(Foo f) { return f }
      }

      class Foo
      {
        static Foo fromStr(Str s) { return make }
        new make() {}
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
    verifyEq(obj->h->x, 'h')
    verifyEq(obj->i->x, 'i')
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
// Errors
//////////////////////////////////////////////////////////////////////////

  Void testErrors()
  {
    // errors
    verifyErrors(
     "class Foo
      {
        static Obj a() { return A {} }
        static Obj b() { return B { x = 4 } }
        static Obj c() { return B { 6, } }
      }

      class A { new mk() {} }
      class B { }
      ",
      [ 3, 27, "Unknown method '$podName::A.make'",
        4, 31, "Unknown variable 'x'",
        5, 31, "Unknown method '$podName::B.add'",
      ])

    // errors
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
      ])
  }

}