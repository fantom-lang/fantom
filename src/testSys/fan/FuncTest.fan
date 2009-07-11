//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Mar 08  Brian Frank  Creation
//

**
** FuncTest
**
class FuncTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Type
//////////////////////////////////////////////////////////////////////////

  Void testTypeFits()
  {
    verifyFits(Num#, Int#, false)
    verifyFits(Int#, Num#, true)

    verifyFits(|Int a|#, |Int a|#,  true)
    verifyFits(|Num a|#, |Int a|#,  true)
    verifyFits(|Int a|#, |Num a|#,  false)

    verifyFits(|Int a|#,        |Int a, Int b|#, true)
    verifyFits(|Int a, Int b|#, |Int a|#, false)

    verifyFits(|->Void|#, |->Int|#,  false)
    verifyFits(|->Int|#,  |->Void|#, true)
    verifyFits(|->Int|#,  |->Num|#,  true)
    verifyFits(|->Num|#,  |->Int|#,  false)

    verifyFits(|Obj, Num, Str|#, |Obj, Num, Str|#, true)
    verifyFits(|Obj, Num, Str|#, |Str, Num, Str|#, true)
    verifyFits(|Obj, Num, Str|#, |Obj, Int, Str|#, true)
    verifyFits(|Str, Num, Str|#, |Obj, Num, Str|#, false)
    verifyFits(|Obj, Int, Str|#, |Obj, Num, Str|#, false)
    verifyFits(|Obj, Num|#,      |Str, Num, Str|#, true)
    verifyFits(|Obj, Num, Str|#, |Obj, Int|#, false)

    verifyFits(|Obj, Num, Str->Int|#, |Obj, Num, Str->Int|#,  true)
    verifyFits(|Obj, Num, Str->Int|#, |Obj, Int, Str->Num|#,  true)
    verifyFits(|Obj, Num, Str->Num|#, |Obj, Num, Str->Int|#,  false)
    verifyFits(|Obj, Num, Str->Int|#, |Str, Num, Str->Void|#, true)
    verifyFits(|Obj, Num, Str->Void|#, |Obj, Num, Str->Int|#, false)
  }

  Void verifyFits(Type a, Type b, Bool fits)
  {
    if (a.fits(b) != fits) echo("  FAILURE: $a fits $b  != $fits")
    verifyEq(a.fits(b), fits)
  }

//////////////////////////////////////////////////////////////////////////
// Callbacks
//////////////////////////////////////////////////////////////////////////

  Void testCallbacks()
  {
    x := 0

    invoke |,| { x++ }; verifyEq(x, 1)
    invoke |->Int| { return x++ }; verifyEq(x, 2)
    invoke |Int a| { x+=a }; verifyEq(x, 5)
    invoke |Int a->Int| { return x+=a }; verifyEq(x, 8)
  }

  Void invoke(|Int a, Int b| cb) { cb(3, 4) }

//////////////////////////////////////////////////////////////////////////
// Retype
//////////////////////////////////////////////////////////////////////////

  Void testRetype()
  {
    x := |x,y->Obj?| { "$x, $y" }
    verifyEq(x.type.signature, "|sys::Obj?,sys::Obj?->sys::Obj?|")
    verifyEq(x(3, 4), "3, 4")

    x = x.retype(|Int,Int?->Str|#)
    verifyEq(x.type.signature, "|sys::Int,sys::Int?->sys::Str|")
    verifyEq(x(3, 4), "3, 4")

    y := &Str.plus
    verifyEq(y.type.signature, "|sys::Str,sys::Obj?->sys::Str|")
    verifyEq(y.method, Str#plus)
    y = y.retype(|Str,Int->Str|#)
    verifyEq(y.type.signature, "|sys::Str,sys::Int->sys::Str|")
    verifyEq(y.method, Str#plus)
    verifyEq(y("x", 5), "x5")
    verifyEq(y.callOn("x", [5]), "x5")
    verifyEq(y.callList(["x", 5]), "x5")
    verifyEq(y.call("x", 5), "x5")
    verifyEq(((Func)y).call("x", 5, "foo"), "x5")

    z := |a,b,c,d,e,f,g,h->Str| { "$a$b$c$d$e$f$g$h" }
    verifyEq(z.isImmutable, true)
    zSig := |Str a,Str b,Str c,Str d,Str e,Str f,Str g,Str h->Str|#
    verifyNotEq(z.type, zSig)
    z = z.retype(zSig)
    verifyEq(z.isImmutable, true)
    verifyEq(z.type, zSig)
    verifyEq(z("a", "b", "c", "d", "e", "f", "g", "h"), "abcdefgh")
    verifyEq(z.callOn("a", ["b", "c", "d", "e", "f", "g", "h"]), "abcdefgh")
    verifyEq(z.callList(["a", "b", "c", "d", "e", "f", "g", "h"]), "abcdefgh")

    verifyErr(ArgErr#) { z.retype(Str#) }
  }

//////////////////////////////////////////////////////////////////////////
// Curry Calls
//////////////////////////////////////////////////////////////////////////

  Void testCurryCalls()
  {
    // verify binding/calling
    verifyCurry |->Str| { return "" }
    verifyCurry |Str a->Str| { return a }
    verifyCurry |Str a, Str b->Str| { return a + b  }
    verifyCurry |Str a, Str b, Str c->Str| { return a + b + c }
    verifyCurry |Str a, Str b, Str c, Str d->Str| { return a + b + c + d }
    verifyCurry |Str a, Str b, Str c, Str d, Str e->Str| { return a + b + c + d + e }
    verifyCurry |Str a, Str b, Str c, Str d, Str e, Str f->Str| { return a + b + c + d + e + f }
    verifyCurry |Str a, Str b, Str c, Str d, Str e, Str f, Str g->Str| { return a + b + c + d + e + f + g }
    verifyCurry |Str a, Str b, Str c, Str d, Str e, Str f, Str g, Str h->Str| { return a + b + c + d + e + f + g + h }
    verifyCurry |Str a, Str b, Str c, Str d, Str e, Str f, Str g, Str h, Str i->Str| { return a + b + c + d + e + f + g + h + i }
    verifyCurry |Str a, Str b, Str c, Str d, Str e, Str f, Str g, Str h, Str i, Str j->Str| { return a + b + c + d + e + f + g + h + i + j }
  }

  Void verifyCurry(Func f)
  {
    args := Str[,]
    expected := ""
    f.params.size.times |Int i|
    {
      ch := ('a' + i).toChar
      args.add(ch)
      expected += ch
    }

    verifyEq(f.callList(args), expected)

    args.size.times |Int i|
    {
      g := f.curry(args[0..<i])
      if (i == 0) verifySame(f, g)

      // call(List)
      a := args[i..-1]
      verifyEq(g.callList(a), expected)

      // callX
      switch (a.size)
      {
        case 0: verifyEq(g.call(), expected)
        case 1: verifyEq(g.call(a[0]), expected)
        case 2: verifyEq(g.call(a[0], a[1]), expected)
        case 3: verifyEq(g.call(a[0], a[1], a[2]), expected)
        case 4: verifyEq(g.call(a[0], a[1], a[2], a[3]), expected)
        case 5: verifyEq(g.call(a[0], a[1], a[2], a[3], a[4]), expected)
        case 6: verifyEq(g.call(a[0], a[1], a[2], a[3], a[4], a[5]), expected)
        case 7: verifyEq(g.call(a[0], a[1], a[2], a[3], a[4], a[5], a[6]), expected)
        case 8: verifyEq(g.call(a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7]), expected)
      }

      // callOn
      if (a.size >= 1) verifyEq(g.callOn(a[0], a[1..-1]), expected)

      // curry operator
      Func? c := null
      switch (i)
      {
        case 0: c = f
        case 1: c = &f(args[0])
        case 2: c = &f(args[0], args[1])
        case 3: c = &f(args[0], args[1], args[2])
        case 4: c = &f(args[0], args[1], args[2], args[3])
        case 5: c = &f(args[0], args[1], args[2], args[3], args[4])
        case 6: c = &f(args[0], args[1], args[2], args[3], args[4], args[5])
        case 7: c = &f(args[0], args[1], args[2], args[3], args[4], args[5], args[6])
        case 8: c = &f(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7])
      }
      if (c != null) verifyEq(c.callList(a), expected)

    }

    x := f.curry(args)
    verifyEq(x.callList([,]), expected)
    verifyEq(x.callList(["x", "y"]), expected)
    verifyEq(x.call, expected)
    verifyEq(x.call("x"), expected)
    verifyEq(x.call("x", "y"), expected)
  }

//////////////////////////////////////////////////////////////////////////
// Curry Signatures
//////////////////////////////////////////////////////////////////////////

  Void testCurrySig()
  {
    Func f := |Bool b, Int i, Float f, Str s->Str| { return "$b $i $f $s" }
    verifyEq(f.type.signature, "|sys::Bool,sys::Int,sys::Float,sys::Str->sys::Str|")
    verifyEq(f.params[0].of, Bool#)
    verifyEq(f.params[1].of, Int#)
    verifyEq(f.params[2].of, Float#)
    verifyEq(f.params[3].of, Str#)
    verifyEq(f.returns, Str#)

    g := f.curry([true])
    verifyEq(g.type.signature, "|sys::Int,sys::Float,sys::Str->sys::Str|")
    verifyEq(g.params[0].of, Int#)
    verifyEq(g.params[1].of, Float#)
    verifyEq(g.params[2].of, Str#)
    verifyEq(g.returns, Str#)

    h := f.curry([true, 9, 4f])
    verifyEq(h.type.signature, "|sys::Str->sys::Str|")
    verifyEq(h.params[0].of, Str#)
    verifyEq(h.returns, Str#)

    i := g.curry([7])
    verifyEq(i.type.signature, "|sys::Float,sys::Str->sys::Str|")
    verifyEq(i.params[0].of, Float#)
    verifyEq(i.params[1].of, Str#)
    verifyEq(i.returns, Str#)

    verifyEq(f.call(false, 8, 3f, "x"), "false 8 3.0 x")
    verifyEq(g.call(33, 6f, "y"), "true 33 6.0 y")
    verifyEq(i.callList([2f, "q"]), "true 7 2.0 q")
    verifyEq(i.call(2f, "q"), "true 7 2.0 q")
    verifyEq(i.curry([2f, "q"]).call, "true 7 2.0 q")
    verifyEq(i.curry([2f, "q"]).call('x'), "true 7 2.0 q")

    verifyErr(ArgErr#) |,| { f.curry([true, 8, 8f, "x", "y"]) }
    verifyErr(ArgErr#) |,| { i.curry([8f, "x", null]) }
  }

//////////////////////////////////////////////////////////////////////////
// Curry Operator
//////////////////////////////////////////////////////////////////////////

  Void testCurryOp()
  {
    f := |Int a, Str b, Float c->Str| { return "$a $b $c" }
    verifyEq(f(1, "x", 2.0f), "1 x 2.0")

    g := &f(1)
    verifyEq(g("x", 2.0f), "1 x 2.0")

    h := &g("y")
    verifyEq(h(3.0f), "1 y 3.0")

    i := &h(4.0f)
    verifyEq(i(), "1 y 4.0")

    j := Int#minus.func
    verifyEq(j(3, 4), -1)

    k := &j(10)
    verifyEq(k(4), 6)

    l := &j(10, 8)
    verifyEq(l.call, 2)

    m := &Str#spaces.func()(3)
    verifyEq(m(), "   ")

    verifySame(j.method, Int#minus)
    verifySame((&Str.spaces).method, Str#spaces)
    verifySame((&10.plus).method, Int#plus)
  }

//////////////////////////////////////////////////////////////////////////
// Curry Def Params
//////////////////////////////////////////////////////////////////////////

  Void testCurryDefParams()
  {
    o := CurryDef()
    // instance methods
    verifyEq(CurryDef#i.func.curry([o]).call, [1, 2, 3])
    verifyEq(CurryDef#i.func.curry([o]).call(7), [7, 2, 3])
    verifyEq(CurryDef#i.func.curry([o]).callList([7,8]), [7, 8, 3])
    verifyEq(CurryDef#i.func.curry([o]).callList([7,8,9]), [7, 8, 9])
    verifyEq(CurryDef#i.func.curry([o]).call(7,8,9), [7, 8, 9])

    verifyEq(CurryDef#i.func.curry([o, 7]).call, [7, 2, 3])
    verifyEq(CurryDef#i.func.curry([o, 7]).call(8), [7, 8, 3])
    verifyEq(CurryDef#i.func.curry([o, 7]).callList([8,9]), [7, 8, 9])
    verifyEq(CurryDef#i.func.curry([o, 7]).call(8,9), [7, 8, 9])

    verifyEq(CurryDef#i.func.curry([o, 7, 8]).call, [7, 8, 3])
    verifyEq(CurryDef#i.func.curry([o, 7, 8]).call(9), [7, 8, 9])
    verifyEq(CurryDef#i.func.curry([o, 7, 8]).callList([9]), [7, 8, 9])

    verifyEq(CurryDef#i.func.curry([o, 7, 8, 9]).call, [7, 8, 9])
    verifyEq(CurryDef#i.func.curry([o, 7, 8, 9]).call(10), [7, 8, 9])

    // static methods
    verifyEq(CurryDef#s.func.curry([7]).call, [7, 2, 3])
    verifyEq(CurryDef#s.func.curry([7]).call(8), [7, 8, 3])
    verifyEq(CurryDef#s.func.curry([7]).callList([8,9]), [7, 8, 9])
    verifyEq(CurryDef#s.func.curry([7]).call(8,9), [7, 8, 9])

    verifyEq(CurryDef#s.func.curry([7, 8]).call, [7, 8, 3])
    verifyEq(CurryDef#s.func.curry([7, 8]).call(9), [7, 8, 9])
    verifyEq(CurryDef#s.func.curry([7, 8]).callList([9]), [7, 8, 9])

    verifyEq(CurryDef#s.func.curry([7, 8, 9]).call, [7, 8, 9])
    verifyEq(CurryDef#s.func.curry([7, 8, 9]).call(10), [7, 8, 9])


    // ctor methods
    verifyEq(CurryDef#make.func.curry([7]).call->list, [7, 2, 3])
    verifyEq(CurryDef#make.func.curry([7]).call(8)->list, [7, 8, 3])
    verifyEq(CurryDef#make.func.curry([7]).callList([8,9])->list, [7, 8, 9])
    verifyEq(CurryDef#make.func.curry([7]).call(8,9)->list, [7, 8, 9])

    verifyEq(CurryDef#make.func.curry([7, 8]).call->list, [7, 8, 3])
    verifyEq(CurryDef#make.func.curry([7, 8]).call(9)->list, [7, 8, 9])
    verifyEq(CurryDef#make.func.curry([7, 8]).callList([9])->list, [7, 8, 9])

    verifyEq(CurryDef#make.func.curry([7, 8, 9]).call->list, [7, 8, 9])
    verifyEq(CurryDef#make.func.curry([7, 8, 9]).callList([,])->list, [7, 8, 9])
    verifyEq(CurryDef#make.func.curry([7, 8, 9]).call(10)->list, [7, 8, 9])
  }

}

internal class CurryDef
{
  Int[] list := Int[,]
  new make(Int a := 1, Int b := 2, Int c := 3) { list = [a, b, c] }
  Int[] i(Int a := 1, Int b := 2, Int c := 3) { [a, b, c] }
  static Int[] s(Int a := 1, Int b := 2, Int c := 3) { [a, b, c] }
}