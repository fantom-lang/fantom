//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Sep 06  Brian Frank  Creation
//

using compiler

**
** MiscTest for various steps: DefaultCtor, Normalize, CheckParamDefs
**
class MiscTest : CompilerTest
{

//////////////////////////////////////////////////////////////////////////
// DefaultCtor
//////////////////////////////////////////////////////////////////////////

  Void testDefaultCtor()
  {
    compile(
     "class Foo
      {
        Int x() { return 7 }
      }")
     t := pod.types.first
     mk := t.method("make")
     verifyEq(mk.isCtor, true)
     verifyEq(mk.isPublic, true)
     verifyEq(mk.params.isEmpty, true)
     verifyEq(mk.call0->x, 7)

    verifyErrors(
      "class A { Void make() {} }
       class B { Int make }
       class C : Foo { } // ok
       class D { static D make() { return null } private new privateMake() { return } }
       class E : D {}
       class Foo { new make(Int x := 0) {} }
       ",
       [1, 1, "Default constructor 'make' conflicts with slot at Script(1,11)",
        2, 1, "Default constructor 'make' conflicts with slot at Script(2,11)",
        5, 1, "Default constructor 'make' conflicts with inherited slot '$podName::D.make'",
       ])
  }

//////////////////////////////////////////////////////////////////////////
// Normalize
//////////////////////////////////////////////////////////////////////////

  Void testNormalize()
  {
    compile(
     "class Foo
      {
        new makeItBaby() {}
        Void x() {}
        static Void y(Int v) {}

        Int i := 6
        Int j := 7

        static { y(33) }
        const static Int k := 8
        static { y(44) }
      }

      class Bar : Foo
      {
        new make() {}

        Int g
      }")
     t := compiler.types.first

     // implicit return
     x := t.slotDef("x")->code as Block
     verifyEq(x.size, 1)
     verifyEq(x.stmts[0].id, StmtId.returnStmt)

     // instance$init
     iInit := t.slotDef("instance\$init\$$t.pod.name\$$t.name")->code as Block
     verifyEq(iInit.size, 3)
     verifyEq(iInit.stmts[0]->expr->id, ExprId.assign)
     verifyEq(iInit.stmts[0]->expr->lhs->name, "i")
     verifyEq(iInit.stmts[0]->expr->rhs->val, 6)
     verifyEq(iInit.stmts[1]->expr->id, ExprId.assign)
     verifyEq(iInit.stmts[1]->expr->lhs->name, "j")
     verifyEq(iInit.stmts[1]->expr->rhs->val, 7)
     verifyEq(iInit.stmts[2].id, StmtId.returnStmt)

     // static$init (each one broken up into if (true) stmt)
     sInit := t.slotDef("static\$init")->code as Block
     verifyEq(sInit.size, 4)
     verifyEq(sInit.stmts[0]->trueBlock->stmts->first->expr->id, ExprId.call)
     verifyEq(sInit.stmts[0]->trueBlock->stmts->first->expr->args->get(0)->val, 33)
     verifyEq(sInit.stmts[1]->expr->id, ExprId.assign)
     verifyEq(sInit.stmts[1]->expr->lhs->name, "k")
     verifyEq(sInit.stmts[1]->expr->rhs->val, 8)
     verifyEq(sInit.stmts[2]->trueBlock->stmts->first->expr->id, ExprId.call)
     verifyEq(sInit.stmts[2]->trueBlock->stmts->first->expr->args->get(0)->val, 44)
     verifyEq(sInit.stmts[3].id, StmtId.returnStmt)

     // super ctor
     bar := compiler.types[1]
     ctor := bar.slotDef("make") as MethodDef
     verifyEq(ctor.ctorChain.target.id, ExprId.superExpr)
     verifyEq(ctor.ctorChain.method.parent.name, "Foo")
     verifyEq(ctor.ctorChain.method.name, "makeItBaby")

     // g field getter
     g := bar.slot("g") as FieldDef
     verify(bar.slotDefs.find |SlotDef s->Bool| { return s === g.get } != null)
     verifyEq(g.get.name, "g")
     verifyEq(g.get.returnType.qname, "sys::Int")
     verifyEq(g.get.params.size, 0)
     verifyEq(g.get.code.stmts.size, 1)
     verifyEq(g.get.code.stmts[0].id, StmtId.returnStmt)
     verifyEq(g.get.code.stmts[0]->expr->id, ExprId.field)
     verifyEq(g.get.code.stmts[0]->expr->name, "g")

     // g field setter
     verify(bar.slotDefs.find |SlotDef s->Bool| { return s === g.set } != null)
     verifyEq(g.set.name, "g")
     verifyEq(g.set.returnType.qname, "sys::Void")
     verifyEq(g.set.params.size, 1)
     verifyEq(g.set.params[0].paramType.qname, "sys::Int")
     verifyEq(g.set.params[0].name, "val")
     verifyEq(g.set.code.stmts.size, 2)
     verifyEq(g.set.code.stmts[0].id, StmtId.expr)
     verifyEq(g.set.code.stmts[0]->expr->id, ExprId.assign)
     verifyEq(g.set.code.stmts[0]->expr->lhs->id, ExprId.field)
     verifyEq(g.set.code.stmts[0]->expr->lhs->name, "g")
     verifyEq(g.set.code.stmts[1].id, StmtId.returnStmt)
  }

//////////////////////////////////////////////////////////////////////////
// Static Init Scoping
//////////////////////////////////////////////////////////////////////////

  Void testStaticInitScoping()
  {
    // verify two static init blocks with same local
    // are given different scopes
    compile(
       "class Foo
        {
          const static Int i
          static
          {
            x := 3
            i = x
          }

          const static Str s
          static
          {
            x := \"hello\"
            s = x
          }
        }")

    t := pod.types[0]
    verifyEq(t.field("i").get, 3)
    verifyEq(t.field("s").get, "hello")
  }

//////////////////////////////////////////////////////////////////////////
// Field Type Inference
//////////////////////////////////////////////////////////////////////////

  Void testFieldTypeInference()
  {
   verifyErrors(
     "class Foo
      {
        Void something() { a.ouch() }
        a := false
        b := 0
        c := \"hello\"
        d := d+1
        e := d { get { return d } }
      }",
      [
        4, 3, "Type inference not supported for fields",
        5, 3, "Type inference not supported for fields",
        6, 3, "Type inference not supported for fields",
        7, 3, "Type inference not supported for fields",
        8, 3, "Type inference not supported for fields",
      ])
  }

//////////////////////////////////////////////////////////////////////////
// CheckParamDefs
//////////////////////////////////////////////////////////////////////////

  Void testCheckParamDefs()
  {
    compile(
     "class Foo
      {
        Void f(Int a := 0, Int b := a+1, Int c := a+2, Int d := -c) {}
      }")
     t := compiler.types.first
     f := t.slot("f") as MethodDef
     verifyEq(f.paramDefs[0].def.id, ExprId.assign)    // save to local, used by b, c
     verifyEq(f.paramDefs[1].def.id, ExprId.shortcut)  // not saved to local
     verifyEq(f.paramDefs[2].def.id, ExprId.assign)    // save to local, used by d
     verifyEq(f.paramDefs[3].def.id, ExprId.shortcut)  // not saved to local

   verifyErrors(
     "class Foo
      {
        Void a(Str a := 6)    {}
        Void b(Int a := 6f, Num b := \"f\") {}
        Void c(Str a := null) {}  // ok
        Void d(Num a := 7)    {}  // ok
      }",
      [
        3, 19, "'sys::Int' is not assignable to 'sys::Str'",
        4, 19, "'sys::Float' is not assignable to 'sys::Int'",
        4, 32, "'sys::Str' is not assignable to 'sys::Num'",
      ])
  }

//////////////////////////////////////////////////////////////////////////
// Generic with Generic Params
//////////////////////////////////////////////////////////////////////////

  Void testGenericWithGenericParams()
  {
    compile(
     "class Foo : Test
      {
        static Str it(Int[] a, Int:Str b, |Int x| c) { return a.toStr }
        Obj testIt() { return type.method(\"it\").call3([1, 2, 3], [4:4.toStr], |Int x| {}) }
      }")

     t := pod.types.first
     verifyEq(t.method("testIt").callOn(t.make, [,]), "[1, 2, 3]")
  }

//////////////////////////////////////////////////////////////////////////
// Currying
//////////////////////////////////////////////////////////////////////////

  Void testCurrying()
  {
    ["static", ""].each |Str mod|
    {
      compile(
       "class Foo
        {
          $mod Func t00() { return &s0 }
          $mod Int[] t01() { m := &s0; return m() }

          $mod Func t02() { return &s1(2) }
          $mod Int[] t03() { m := &s1; return m(66) }

          $mod Func t04() { return &s2(99) }
          $mod Int[] t05() { return (&s2)(5, 6) }
          $mod Int[] t06() { m := &s2(99); return m.call1(5) }
          $mod Int[] t07(Int a, Int b) { return (&s2(a, b)).call([5, 6, 7]) }

          $mod Int[] t08(Int a, Int h) { return (&s8(a, 2, 3, 4, 5, 6, 7))(h) }
          $mod Int[] t09(Int a, Int b, Int c, Int d, Int e, Int f, Int g, Int h) { return (&s8)(a, b, c, d, e, f, g, h) }

          $mod Int[] t10(Int a, Int b, Int c, Int d, Int e, Int f, Int g, Int h, Int i, Int j) { return (&s10(a, b, c, d))(e, f, g, h, i, j) }
          $mod Int[] t11(Int a, Int b, Int c, Int d, Int e, Int f, Int g, Int h, Int i, Int j) { return (&s10(99)).call([b, c, d, e, f, g, h, i, j]) }

          $mod Int[] s0() { return Int[,] }
          $mod Int[] s1(Int a) { return [a] }
          $mod Int[] s2(Int a, Int b) { return [a, b] }
          $mod Int[] s8(Int a, Int b, Int c, Int d, Int e, Int f, Int g, Int h) { return [a, b, c, d, e, f, g, h] }
          $mod Int[] s10(Int a, Int b, Int c, Int d, Int e, Int f, Int g, Int h, Int i, Int j) { return [a, b, c, d, e, f, g, h, i, j] }
        }")

       // compiler.fpod.dump
       t := pod.types.first
       obj := t.make

       if (mod == "static")
         verifySame(obj->t00, t.method("s0").func)
       verifyEq(obj->t01, Int[,])
       verify(obj->t01 != t.method("s1").func)

       verifyEq(obj->t02->params->size, 0)
       verifyEq(obj->t02->returns, Int[]#)
       verifyEq(obj->t03, [66])

       verifyEq(obj->t04->params->size, 1)
       verifyEq(obj->t04->params->first->of, Int#)
       verifyEq(obj->t04->returns, Int[]#)
       verifyEq(obj->t05, [5, 6])
       verifyEq(obj->t06, [99, 5])
       verifyEq(obj->t07(99, 88), [99, 88])

       verifyEq(obj->t08('a', 'h'), ['a', 2, 3, 4, 5, 6, 7, 'h'])
       verifyEq(obj->t09(1, 2, 3, 4, 5, 6, 7, 8), [1, 2, 3, 4, 5, 6, 7, 8])

       verifyEq(obj->s10(1, 2, 3, 4, 5, 6, 7, 8, 9, 10), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
       verifyEq(obj->t10(1, 2, 3, 4, 5, 6, 7, 8, 9, 10), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
       verifyEq(obj->t11(1, 2, 3, 4, 5, 6, 7, 8, 9, 10), [99, 2, 3, 4, 5, 6, 7, 8, 9, 10])
     }
  }

  Void testCurryingMore()
  {
    compile(
     "class Foo
      {
        Obj[] t00() { m := &pass(this).x3; return m(0, 1, 2) }
        Obj[] t01(Int a) { return (&pass(this).x3(a))(1, 2) }
        static Obj[] t02(Int a, Int b, Int c, Foo foo) { m := &foo.x3(7, 8, 9); return m() }
        static Obj[] t03(Foo foo) { m := &x3; return m(foo, 4, 5, 6) }

        Obj[] t04(Int a)
        {
          return |->Obj[]|
          {
            m := &x3; return m(a, 77, 88)
          }()
        }

        Int[] t05(Int x)
        {
          a := &Int.plus
          b := &1.plus
          c := &x.plus(2)
          return [a(4, 7), b(8), c()]
        }

        static Foo pass(Foo f) { return f }

        Obj[] x3(Int a, Int b, Int c) { return [this, a, b, c] }
      }")

     // compiler.fpod.dump
     t := pod.types.first
     obj := t.make

     verifyEq(obj->t00, [obj, 0, 1, 2])
     verifyEq(obj->t01(7), [obj, 7, 1, 2])
     verifyEq(obj->t02(0, 1, 2, obj), [obj, 7, 8, 9])
     verifyEq(obj->t03(obj), [obj, 4, 5, 6])

     verifyEq(obj->t04(18), [obj, 18, 77, 88])

     verifyEq(obj->t05(3), [11, 9, 5])
  }

  Void testCurryingYetMore()
  {
    compile(
     "class Foo
      {
        Obj t01() { return m.call0 }

        Str x := \"abc\"
        Func m := &x.upper
      }")

     // compiler.fpod.dump
     t := pod.types.first
     obj := t.make

     verifyEq(obj->t01, "ABC")
  }

  Void testCurryingMixin()
  {
    compile(
     "mixin Foo
      {
        static Obj[] t00() { m := &s2; return m(1, 2) }
        static Obj[] t01() { m := &s2(7); return m(8) }

        Obj[] t02() { m := &i2; return m('a', 'b') }
        Obj[] t03(Int b) { return (&pass(this).self.i2('A'))(b) }

        Foo self() { return this }
        static Foo pass(Foo foo) { return foo }

        static Obj[] s2(Int a, Int b) { return [a, b] }
        Obj[] i2(Int a, Int b) { return [a, b] }
      }

      class Bar : Foo {}
      ")

     // compiler.fpod.dump
     t := pod.types.first
     obj := pod.types[1].make

     verifyEq(t->method("t00")->call0, [1, 2])
     verifyEq(t->method("t01")->call0, [7, 8])

     verifyEq(obj->t02, ['a', 'b'])
     verifyEq(obj->t03(7), ['A', 7])
  }

//////////////////////////////////////////////////////////////////////////
// IsConst
//////////////////////////////////////////////////////////////////////////

  Void testIsConst()
  {
    compile(
     "class Foo
      {
        // fields
        Int f00
        const Int f01 := 1
        const static Int f02 := 2

        // methods
        Void m00() {}
        Int m01(List list) { return null }
        static Void m02(Obj x) {}
        static Str[] m03(Int a, Int b) { return null }

        // closures
        static Func c00() { return |,| {} }
        Func c01() { return |->Int| { a := 3; return a; } }
        Func c02() { return |->Obj| { return m01(null) } }
        static Func c03() { a := 3; return |->Obj| { return a } }
        static Func c04() { a := 3; m := |->Func| { return |->Obj| { return a } }; return m() }
        Func c05() { a := 3; m := |->Func| { return |->Obj| { return this } }; return m() }
        Func c06() { list := [0,1]; return |->Obj| { return m01(list) } }

        // curries
        static Func r00() { return &m02 }
        static Func r01() { return &m02(99) }
        Func r02() { return &m02(this) }
        Func r03() { return &m02(9ns) }
        Func r04() { return &m02([,]) }
        Func r05() { return &m00 }
        Func r06() { return &m01([,]) }
        Func r07() { return &Int.plus }
        Func r08(Int x) { return &(x.plus) }
        Func r09(Int x) { return &(8.plus(x)) }
      }")

     // compiler.fpod.dump
     t := pod.types.first
     obj := t.make

     // defined fields
     verify(!t.field("f00").isConst)
     verify(t.field("f01").isConst)
     verify(t.field("f02").isConst)

     // defined methods
     verify(!t.method("m00").isConst)
     verify(!t.method("m01").isConst)
     verify(t.method("m02").isConst)
     verify(t.method("m03").isConst)

     // closures
     verifyEq(obj->c00()->isImmutable, true)
     verifyEq(obj->c01()->isImmutable, true)
     verifyEq(obj->c02()->isImmutable, false)
     verifyEq(obj->c03()->isImmutable, false)
     verifyEq(obj->c04()->isImmutable, false)
     verifyEq(obj->c05()->isImmutable, false)
     verifyEq(obj->c06()->isImmutable, false)

     // curried methods
     verifyEq(obj->r00()->isImmutable, true)
     verifyEq(obj->r01()->isImmutable, true)
     verifyEq(obj->r02()->isImmutable, false)
     verifyEq(obj->r03()->isImmutable, true)
     verifyEq(obj->r04()->isImmutable, false)
     verifyEq(obj->r05()->isImmutable, false)
     verifyEq(obj->r06()->isImmutable, false)
     verifyEq(obj->r07()->isImmutable, true)
     verifyEq(obj->r08(7)->isImmutable, true)
     verifyEq(obj->r09(7)->isImmutable, true)
  }

//////////////////////////////////////////////////////////////////////////
// Indexed Assign
//////////////////////////////////////////////////////////////////////////

  Void testIndexedAssign()
  {
    compile(
     "class Foo
      {
        static Void it(Int[] x) { x[0] += 3 }
        static Int wow(Int[] x) { return ++x[0] }
        static Int wee(Int[] x) { return x[0]++ }

        Int[] f := [99, 2]
        Void fit() { f[1] += 3 }
        Int fwow() { return ++f[1] }
        Int fwee() { return f[1]++ }
      }")

    // compiler.fpod.dump
    t := pod.types.first

    x := [2]
    verifyEq(x[0], 2)
    t.method("it").call1(x)
    verifyEq(x[0], 5)
    verifyEq(t.method("wow").call1(x), 6)
    verifyEq(x[0], 6)
    verifyEq(t.method("wee").call1(x), 6)
    verifyEq(x[0], 7)

    o := t.make
    verifyEq(o->f, [99, 2])
    o->fit()
    verifyEq(o->f, [99, 5])
    verifyEq(o->fwow, 6)
    verifyEq(o->f, [99, 6])
    verifyEq(o->fwee, 6)
    verifyEq(o->f, [99, 7])

    verifyErrors(
      "class Foo
       {
         Str get(Str s) { return s}
         Void it(Str s) { this[s] += s }
       }
       ",
       [4, 24, "No matching 'set' method for '$podName::Foo.get'",
       ])
  }

//////////////////////////////////////////////////////////////////////////
// Facets
//////////////////////////////////////////////////////////////////////////

  Void testFacets()
  {
    // we really test facets in testSys::FacetsTest, we just verify errors here
    verifyErrors(
      "@x=null
       class Foo
       {
       }
       ",
       [
         1, 4, "Facet value is not serializable: 'x' ('nullLiteral' not serializable)",
       ])
  }

//////////////////////////////////////////////////////////////////////////
// Auto-Cast
//////////////////////////////////////////////////////////////////////////

  Void testAutoCast()
  {
    compile(
     "class Foo
      {
        Str a() { Str x := this->toStr; return x }
        Str b() { return thru(x(\"B\")) }
        Int c() { return x(7) }
        Int d() { f := |Int x->Int| { return x }; return f(x(9)) }
        Int e() { return x(true) ? 2 : 3 }
        Int f() { if (x(false)) return 2; else return 3 }
        Int g() { throw x(ArgErr.make) }
        Int[] h() { acc := Int [,]; for (i:=0; x(i<3); ++i) acc.add(i); return acc }
        Int[] i() { acc := Int [,]; while (x(acc.size < 4)) acc.add(acc.size); return acc }
        Bool j(Bool a) { return !x(a) }
        Bool k(Bool a, Bool b) { return x(a) && x(b) }
        Int l(Num a) { return a }
        Int m(Num a) { Int i := a; return i }
        Int n(Num a) { return thrui(a) }
        Int[] o(Obj[] a) { return a }

        Str thru(Str x) { return x }
        Int thrui(Int x) { return x }
        Obj x(Obj x) { return x }
        override Str toStr() { return \"Foo!\" }
      }")

    // compiler.fpod.dump
    t := pod.types.first
    o := t.make
    verifyEq(o->a, "Foo!")
    verifyEq(o->b, "B")
    verifyEq(o->c, 7)
    verifyEq(o->d, 9)
    verifyEq(o->e, 2)
    verifyEq(o->f, 3)
    verifyErr(ArgErr#) |,| { o->g }
    verifyEq(o->h, [0, 1, 2])
    verifyEq(o->i, [0, 1, 2, 3])
    verifyEq(o->j(true), false)
    verifyEq(o->j(false), true)
    verifyEq(o->k(false, false), false)
    verifyEq(o->k(false, true), false)
    verifyEq(o->k(true, true), true)
    verifyEq(o->l(6), 6)
    verifyEq(o->m(7), 7)
    verifyEq(o->n(8), 8)
    verifyEq(o->o([1,2,3]), [1,2,3])
  }

//////////////////////////////////////////////////////////////////////////
// Special Errors
//////////////////////////////////////////////////////////////////////////

  Void testSpecialErrors()
  {
    verifyErrors("class Foo { Void x() { Bar b := Bar.make } }",
       [ 1, 24, "Unknown type 'Bar' for local declaration"])

    verifyErrors("class Foo { Void x() { Bar b = dkdkdkd } }",
       [ 1, 24, "Unknown type 'Bar' for local declaration"])

    verifyErrors("class Foo { Void x() { Bar b } }",
       [ 1, 24, "Expected expression statement"])
  }

//////////////////////////////////////////////////////////////////////////
// DefDoc
//////////////////////////////////////////////////////////////////////////

  Void testDefDoc()
  {
    pn := podName

    compile(
     "class Foo
      {
        Void a(Str x := null) { }
        Void b(Int[] y := Int[,] , Str z := \"hi\\n\") {}
        Void c(Int x := 7, Int y := x-x , Int z := ~ y) {}
        Void d(Str x := mi(), Str y := ms(5)) {}

        Str mi() { return null }
        static Str ms(Int i) { return null }
      }"
    )

    t := compiler.pod.types.first
    verifyEq(t.method("a").params[0]->def->toDocStr, "null")
    verifyEq(t.method("b").params[0]->def->toDocStr, "Int[,]")
    verifyEq(t.method("b").params[1]->def->toDocStr, "\"hi\\n\"")
    verifyEq(t.method("c").params[0]->def->toDocStr, "7")
    verifyEq(t.method("c").params[1]->def->toDocStr, "x - x")
    verifyEq(t.method("c").params[2]->def->toDocStr, "~y")
    verifyEq(t.method("d").params[0]->def->toDocStr, "this.mi()")
    verifyEq(t.method("d").params[1]->def->toDocStr, "Foo.ms(5)")
  }

//////////////////////////////////////////////////////////////////////////
// Once
//////////////////////////////////////////////////////////////////////////

  Void testOnce()
  {
    compile(
     "class A
      {
        virtual once DateTime x() { return DateTime.now(null) }
        once DateTime bad() { throw Err.make }
      }

      class B : A
      {
        override DateTime x() { return DateTime.now(null) }
      }
      ")

     a := pod.findType("A").make
     b := pod.findType("B").make
     verifySame(a->x, a->x)
     verifyNotSame(b->x, b->x)
     verifyErr(Err#) |,| { a->bad }
     verifyErr(Err#) |,| { a->bad }
     verifyErr(Err#) |,| { a->bad }

    verifyErrors(
      "class Foo
       {
         once Void x() {}
         once Str y(Str p) { return p }
       }
       ",
       [3, 3, "Once method 'x' cannot return Void",
        4, 3, "Once method 'y' cannot have parameters",
       ])
  }

//////////////////////////////////////////////////////////////////////////
// Func Types
//////////////////////////////////////////////////////////////////////////

  Void testFuncTypes()
  {
    compile(
     "class Foo
      {
        Void a(|Int a, Str b| f) {}
        Void b(|Int a, Str| f) {}
        Void c(|Int, Str a| f) {}
        Void d(|Int, Str| f) {}
        Void e(|Duration| f) {}
        Void f(|Duration->Int| f) {}
        Void x() { a |Int, Str| { } }
      }")

    t := pod.types.first
    verifyEq(t.method("a").params[0].of, |Int a, Str b|#)
    verifyEq(t.method("b").params[0].of, |Int a, Str b|#)
    verifyEq(t.method("c").params[0].of, |Int a, Str b|#)
    verifyEq(t.method("d").params[0].of, |Int a, Str b|#)
    verifyEq(t.method("e").params[0].of, |Duration|#)
    verifyEq(t.method("f").params[0].of, |Duration->Int|#)
  }

//////////////////////////////////////////////////////////////////////////
// Call Parens
//////////////////////////////////////////////////////////////////////////

  Void testCallParens()
  {
    // we require that calls paren be on the same
    // line to prevent ambiguity
    x := "foo"
    (0..2).each |Int i| { x += "," + i }
    verifyEq(x, "foo,0,1,2")

    x = "foo".size.toStr
    (0..2).each |Int i| { x += "," + i }
    verifyEq(x, "3,0,1,2")
  }

//////////////////////////////////////////////////////////////////////////
// Index Brackets
//////////////////////////////////////////////////////////////////////////

  Void testIndexBrackets()
  {
    // we require that index brackets be on the same
    // line to prevent ambiguity
    x := "foo"
    [0, 1, 2].each |Int i| { x += "," + i }
    verifyEq(x, "foo,0,1,2")

    x = "foo".size.toStr
    [0, 1, 2].each |Int i| { x += "," + i }
    verifyEq(x, "3,0,1,2")
  }

//////////////////////////////////////////////////////////////////////////
// No Leave Pops
//////////////////////////////////////////////////////////////////////////

  Void testNoLeavePops()
  {
    // this is kind of a random regression test
    // for a problem I stubmled across
    compile(
     "class Foo
      {
        Void a(Bool b) { if (b) Foo { x=7 } }
        Void b(Bool b, Obj x) { if (b) (Str)x->toHex }
        const Int x
      }")
    //compiler.fpod.dump

    obj := pod.types.first.make
    obj->a(true)     // JVM will throw VerifyError if problem exists
    obj->b(true, 3)  // JVM will throw VerifyError if problem exists
  }

//////////////////////////////////////////////////////////////////////////
// Implicit ToImmutable
//////////////////////////////////////////////////////////////////////////

  Void testImplicitToImmutable()
  {
    compile(
     "class Foo
      {
        const Int[] a
        const Int[] b := null
        const Int[] c := [2,3]
        const Int[] d := wrap(null)
        const Int[] e := wrap([4])
        const Int[] f
        const Int[] g

        const Int:Str h := null
        const Int:Str i := map(null)
        const Int:Str j := map(c)
        const Int:Str k := map(c)

        const Type l := null
        const Type m := Str#
        const Type n
        const Type o

        new make()
        {
          f = wrap(null)
          g = wrap([5,6])
          k = map(g)
          n = thru(null)
          o = thru(Bool#)
        }

        Foo with()
        {
          return make
          {
            f = wrap(null)
            g = wrap([5,6])
            k = map(g)
            n = thru(null)
            o = thru(Bool#)
          }
        }

        static Int[] wrap(Int[] x) { return x }
        static Type thru(Type t) { return t }

        static Int:Str map(Int[] x)
        {
          if (x == null) return null
          m := Int:Str[:]
          x.each |Int i| { m[i] = i.toStr }
          return m
        }

      }")
    // compiler.fpod.dump

    obj := pod.types.first.make
    verifyImplicitToImmutable(obj)
    verifyImplicitToImmutable(obj->with)
 }

 Void verifyImplicitToImmutable(Obj obj)
 {
    verifyEq(obj->a, null)
    verifyEq(obj->b, null)
    verifyEq(obj->c, [2,3])
    verifyEq(obj->c->isImmutable, true)
    verifyEq(obj->d, null)
    verifyEq(obj->e, [4])
    verifyEq(obj->e->isImmutable, true)
    verifyEq(obj->f, null)
    verifyEq(obj->g, [5,6])
    verifyEq(obj->g->isImmutable, true)

    verifyEq(obj->h, null)
    verifyEq(obj->i, null)
    verifyEq(obj->j, [2:"2", 3:"3"])
    verifyEq(obj->j->isImmutable, true)
    verifyEq(obj->k, [5:"5", 6:"6"])
    verifyEq(obj->k->isImmutable, true)

    verifyEq(obj->l, null)
    verifyEq(obj->m, Str#)
    verifyEq(obj->n, null)
    verifyEq(obj->o, Bool#)
  }

//////////////////////////////////////////////////////////////////////////
// Generics
//////////////////////////////////////////////////////////////////////////

  Void testGenericList()
  {
    // problem reported on forum
    compile("class Foo { Bool foo(List x) { return x[0] == 7 } }")
    //compiler.fpod.dump

    obj := pod.types.first.make
    verifyEq(obj->foo(["x"]), false)
    verifyEq(obj->foo([7]), true)
  }

}