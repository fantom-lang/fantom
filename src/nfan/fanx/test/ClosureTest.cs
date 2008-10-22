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
      src += "  static Long f(Long x)\n";
      src += "  {\n";
      src += "    y := 1\n";
      src += "    3.times |Long t| { x += y }\n";
      src += "    //echo(\"done x=\" + x + \" y=\" + y)\n";
      src += "    return x\n";
      src += "  }\n";
      src += "}\n";

      System.Type cls = CompileToType(src);
      verify(InvokeStatic(cls, "F", MakeInts(6)) == Long.valueOf(9));
    }

  //////////////////////////////////////////////////////////////////////////
  // verifyDefs
  //////////////////////////////////////////////////////////////////////////

    public void verifyDefs()
    {
      verifyDef("|->Long| { return 0 }", 0);
      verifyDef("|Long a->Long| { return a }", 1);
      verifyDef("|Long a, Long b->Long| { return a+b }", 2);
      verifyDef("|Long a, Long b, Long c->Long| { return a+b+c }", 3);
      verifyDef("|Long a, Long b, Long c, Long d->Long| { return a+b+c+d }", 4);
      verifyDef("|Long a, Long b, Long c, Long d, Long e->Long| { return a+b+c+d+e }", 5);
      verifyDef("|Long a, Long b, Long c, Long d, Long e,Long f->Long| { return a+b+c+d+e+f }", 6);
      verifyDef("|Long a, Long b, Long c, Long d, Long e,Long f,Long g->Long| { return a+b+c+d+e+f+g }", 7);
      verifyDef("|Long a, Long b, Long c, Long d, Long e,Long f,Long g,Long h->Long| { return a+b+c+d+e+f+g+h }", 8);
      //verifyDef("|Long a, Long b, Long c, Long d, Long e,Long f,Long g,Long h,Long i->Long| { return a+b+c+d+e+f+g+h+i }", 9);
      //verifyDef("|Long a, Long b, Long c, Long d, Long e,Long f,Long g,Long h,Long i,Long j->Long| { return a+b+c+d+e+f+g+h+i+j }", 10);
      //verifyDef("|Long a, Long b, Long c, Long d, Long e,Long f,Long g,Long h,Long i,Long j,Long k->Long| { return a+b+c+d+e+f+g+h+i+j+k }", 11);
      //verifyDef("|Long a, Long b, Long c, Long d, Long e,Long f,Long g,Long h,Long i,Long j,Long k,Long l->Long| { return a+b+c+d+e+f+g+h+i+j+k+l }", 12);
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
        verify(callList(m, i), Long.valueOf(result));
        if (i <= Func.MaxIndirectParams)
          verify(callIndirect(m, i), Long.valueOf(result));
      }
    }

    private Long callList(Method m, int argn)
    {
      List list = new List(Sys.ObjType);
      for (int i=0; i<argn; i++) list.add(Long.valueOf(1+i));
      return (Long)m.call(list);
    }

    private Long callIndirect(Method m, int argn)
    {
      switch (argn)
      {
        case 0:  return (Long)m.call0();
        case 1:  return (Long)m.call1(Long.valueOf(1));
        case 2:  return (Long)m.call2(Long.valueOf(1), Long.valueOf(2));
        case 3:  return (Long)m.call3(Long.valueOf(1), Long.valueOf(2), Long.valueOf(3));
        case 4:  return (Long)m.call4(Long.valueOf(1), Long.valueOf(2), Long.valueOf(3), Long.valueOf(4));
        case 5:  return (Long)m.call5(Long.valueOf(1), Long.valueOf(2), Long.valueOf(3), Long.valueOf(4), Long.valueOf(5));
        case 6:  return (Long)m.call6(Long.valueOf(1), Long.valueOf(2), Long.valueOf(3), Long.valueOf(4), Long.valueOf(5), Long.valueOf(6));
        case 7:  return (Long)m.call7(Long.valueOf(1), Long.valueOf(2), Long.valueOf(3), Long.valueOf(4), Long.valueOf(5), Long.valueOf(6), Long.valueOf(7));
        case 8:  return (Long)m.call8(Long.valueOf(1), Long.valueOf(2), Long.valueOf(3), Long.valueOf(4), Long.valueOf(5), Long.valueOf(6), Long.valueOf(7), Long.valueOf(8));
        //case 9:  return (Long)m.call9(Long.valueOf(1), Long.valueOf(2), Long.valueOf(3), Long.valueOf(4), Long.valueOf(5), Long.valueOf(6), Long.valueOf(7), Long.valueOf(8), Long.valueOf(9));
        //case 10: return (Long)m.call10(Long.valueOf(1), Long.valueOf(2), Long.valueOf(3), Long.valueOf(4), Long.valueOf(5), Long.valueOf(6), Long.valueOf(7), Long.valueOf(8), Long.valueOf(9), Long.valueOf(10));
        //case 11: return (Long)m.call11(Long.valueOf(1), Long.valueOf(2), Long.valueOf(3), Long.valueOf(4), Long.valueOf(5), Long.valueOf(6), Long.valueOf(7), Long.valueOf(8), Long.valueOf(9), Long.valueOf(10), Long.valueOf(11));
        //case 12: return (Long)m.call12(Long.valueOf(1), Long.valueOf(2), Long.valueOf(3), Long.valueOf(4), Long.valueOf(5), Long.valueOf(6), Long.valueOf(7), Long.valueOf(8), Long.valueOf(9), Long.valueOf(10), Long.valueOf(11), Long.valueOf(12));
        default: return null; // ignore

      }
    }

  }
}
