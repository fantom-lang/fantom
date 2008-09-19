//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Jan 06  Brian Frank  Creation
//

using Fan.Sys;

namespace Fanx.Test
{
  /// <summary>
  /// ClosureTest.
  /// </summary>
  public class ClosureTest : CompileTest
  {

  //////////////////////////////////////////////////////////////////////////
  // Main
  //////////////////////////////////////////////////////////////////////////

    public override void Run()
    {
      verifyCvars();
      verifyDefs();
    }

  //////////////////////////////////////////////////////////////////////////
  // verifyCvars
  //////////////////////////////////////////////////////////////////////////

    public void verifyCvars()
    {
      string src = "class Simple\n";
      src += "{\n";
      src += "  static Int f(Int x)\n";
      src += "  {\n";
      src += "    y := 1\n";
      src += "    3.times |Int t| { x += y }\n";
      src += "    //echo(\"done x=\" + x + \" y=\" + y)\n";
      src += "    return x\n";
      src += "  }\n";
      src += "}\n";

      System.Type cls = CompileToType(src);
      verify(InvokeStatic(cls, "F", MakeInts(6)) == Int.make(9));
    }

  //////////////////////////////////////////////////////////////////////////
  // verifyDefs
  //////////////////////////////////////////////////////////////////////////

    public void verifyDefs()
    {
      verifyDef("|->Int| { return 0 }", 0);
      verifyDef("|Int a->Int| { return a }", 1);
      verifyDef("|Int a, Int b->Int| { return a+b }", 2);
      verifyDef("|Int a, Int b, Int c->Int| { return a+b+c }", 3);
      verifyDef("|Int a, Int b, Int c, Int d->Int| { return a+b+c+d }", 4);
      verifyDef("|Int a, Int b, Int c, Int d, Int e->Int| { return a+b+c+d+e }", 5);
      verifyDef("|Int a, Int b, Int c, Int d, Int e,Int f->Int| { return a+b+c+d+e+f }", 6);
      verifyDef("|Int a, Int b, Int c, Int d, Int e,Int f,Int g->Int| { return a+b+c+d+e+f+g }", 7);
      verifyDef("|Int a, Int b, Int c, Int d, Int e,Int f,Int g,Int h->Int| { return a+b+c+d+e+f+g+h }", 8);
      //verifyDef("|Int a, Int b, Int c, Int d, Int e,Int f,Int g,Int h,Int i->Int| { return a+b+c+d+e+f+g+h+i }", 9);
      //verifyDef("|Int a, Int b, Int c, Int d, Int e,Int f,Int g,Int h,Int i,Int j->Int| { return a+b+c+d+e+f+g+h+i+j }", 10);
      //verifyDef("|Int a, Int b, Int c, Int d, Int e,Int f,Int g,Int h,Int i,Int j,Int k->Int| { return a+b+c+d+e+f+g+h+i+j+k }", 11);
      //verifyDef("|Int a, Int b, Int c, Int d, Int e,Int f,Int g,Int h,Int i,Int j,Int k,Int l->Int| { return a+b+c+d+e+f+g+h+i+j+k+l }", 12);
    }

    private void verifyDef(string closure, int n)
    {
      string src = "class Def\n";
      src += "{\n";
      src += "  static Method f() { return " + closure + " }\n";
      src += "}\n";

      System.Type cls = CompileToType(src);
      Method m = (Method)InvokeStatic(cls, "F");

      // TODO - m.qname, parent, etc ????

      // anything less than n should throw Err
      for (int i=0; i<n; i++)
      {
        Err err = null;
        try { callList(m, i); } catch (Err.Val e) { err = e.err(); }
        verify(err != null);
        try { callIndirect(m, i); } catch (Err.Val e) { err = e.err(); }
      }

      // compute result 0->0, 1->1, 2->3, 3->7, etc
      int result = 0;
      for (int i=0; i<=n; i++) result += i;

      // anything n and over should be ok
      for (int i=n; i<12; i++)
      {
        verify(callList(m, i), Int.make(result));
        if (i <= Func.MaxIndirectParams)
          verify(callIndirect(m, i), Int.make(result));
      }
    }

    private Int callList(Method m, int argn)
    {
      List list = new List(Sys.ObjType);
      for (int i=0; i<argn; i++) list.add(Int.make(1+i));
      return (Int)m.call(list);
    }

    private Int callIndirect(Method m, int argn)
    {
      switch (argn)
      {
        case 0:  return (Int)m.call0();
        case 1:  return (Int)m.call1(Int.make(1));
        case 2:  return (Int)m.call2(Int.make(1), Int.make(2));
        case 3:  return (Int)m.call3(Int.make(1), Int.make(2), Int.make(3));
        case 4:  return (Int)m.call4(Int.make(1), Int.make(2), Int.make(3), Int.make(4));
        case 5:  return (Int)m.call5(Int.make(1), Int.make(2), Int.make(3), Int.make(4), Int.make(5));
        case 6:  return (Int)m.call6(Int.make(1), Int.make(2), Int.make(3), Int.make(4), Int.make(5), Int.make(6));
        case 7:  return (Int)m.call7(Int.make(1), Int.make(2), Int.make(3), Int.make(4), Int.make(5), Int.make(6), Int.make(7));
        case 8:  return (Int)m.call8(Int.make(1), Int.make(2), Int.make(3), Int.make(4), Int.make(5), Int.make(6), Int.make(7), Int.make(8));
        //case 9:  return (Int)m.call9(Int.make(1), Int.make(2), Int.make(3), Int.make(4), Int.make(5), Int.make(6), Int.make(7), Int.make(8), Int.make(9));
        //case 10: return (Int)m.call10(Int.make(1), Int.make(2), Int.make(3), Int.make(4), Int.make(5), Int.make(6), Int.make(7), Int.make(8), Int.make(9), Int.make(10));
        //case 11: return (Int)m.call11(Int.make(1), Int.make(2), Int.make(3), Int.make(4), Int.make(5), Int.make(6), Int.make(7), Int.make(8), Int.make(9), Int.make(10), Int.make(11));
        //case 12: return (Int)m.call12(Int.make(1), Int.make(2), Int.make(3), Int.make(4), Int.make(5), Int.make(6), Int.make(7), Int.make(8), Int.make(9), Int.make(10), Int.make(11), Int.make(12));
        default: return null; // ignore

      }
    }

  }
}
