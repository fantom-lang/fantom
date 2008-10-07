//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Dec 06  Andy Frank  Creation
//

using Fan.Sys;

namespace Fanx.Test
{
  /// <summary>
  /// CallTest.
  /// </summary>
  public class CallTest : CompileTest
  {

  //////////////////////////////////////////////////////////////////////////
  // Main
  //////////////////////////////////////////////////////////////////////////

    public override void Run()
    {
      verifyReflectCalls();
    }

  //////////////////////////////////////////////////////////////////////////
  // Reflect Calls
  //////////////////////////////////////////////////////////////////////////

    private void verifyReflectCalls()
    {
      string src = "class ReflectCallTest\n";
      src += "{\n";
      src += "  Int i0() { return 0 }\n";
      src += "  Int i1(Int a) { return a }\n";
      src += "  Int i2(Int a, Int b) { return a+b }\n";
      src += "  Int i3(Int a, Int b, Int c) { return a+b+c }\n";
      src += "  Int i4(Int a, Int b, Int c, Int d) { return a+b+c+d }\n";
      src += "  Int i5(Int a, Int b, Int c, Int d, Int e) { return a+b+c+d+e }\n";
      src += "  Int i6(Int a, Int b, Int c, Int d, Int e, Int f) { return a+b+c+d+e+f }\n";
      src += "  Int i7(Int a, Int b, Int c, Int d, Int e, Int f, Int g) { return a+b+c+d+e+f+g }\n";
      src += "  Int i8(Int a, Int b, Int c, Int d, Int e, Int f, Int g, Int h) { return a+b+c+d+e+f+g+h }\n";
      src += "  Int i9(Int a, Int b, Int c, Int d, Int e, Int f, Int g, Int h, Int i) { return a+b+c+d+e+f+g+h+i }\n";
      src += "  Int i10(Int a, Int b, Int c, Int d, Int e, Int f, Int g, Int h, Int i, Int j) { return a+b+c+d+e+f+g+h+i+j }\n";
      src += "  Int i11(Int a, Int b, Int c, Int d, Int e, Int f, Int g, Int h, Int i, Int j, Int k) { return a+b+c+d+e+f+g+h+i+j+k }\n";
      src += "  Int i12(Int a, Int b, Int c, Int d, Int e, Int f, Int g, Int h, Int i, Int j, Int k, Int l) { return a+b+c+d+e+f+g+h+i+j+k+l }\n";
      src += "  static Int s0() { return 0 }\n";
      src += "  static Int s1(Int a) { return a }\n";
      src += "  static Int s2(Int a, Int b) { return a+b }\n";
      src += "  static Int s3(Int a, Int b, Int c) { return a+b+c }\n";
      src += "  static Int s4(Int a, Int b, Int c, Int d) { return a+b+c+d }\n";
      src += "  static Int s5(Int a, Int b, Int c, Int d, Int e) { return a+b+c+d+e }\n";
      src += "  static Int s6(Int a, Int b, Int c, Int d, Int e, Int f) { return a+b+c+d+e+f }\n";
      src += "  static Int s7(Int a, Int b, Int c, Int d, Int e, Int f, Int g) { return a+b+c+d+e+f+g }\n";
      src += "  static Int s8(Int a, Int b, Int c, Int d, Int e, Int f, Int g, Int h) { return a+b+c+d+e+f+g+h }\n";
      src += "  static Int s9(Int a, Int b, Int c, Int d, Int e, Int f, Int g, Int h, Int i) { return a+b+c+d+e+f+g+h+i }\n";
      src += "  static Int s10(Int a, Int b, Int c, Int d, Int e, Int f, Int g, Int h, Int i, Int j) { return a+b+c+d+e+f+g+h+i+j }\n";
      src += "  static Int s11(Int a, Int b, Int c, Int d, Int e, Int f, Int g, Int h, Int i, Int j, Int k) { return a+b+c+d+e+f+g+h+i+j+k }\n";
      src += "  static Int s12(Int a, Int b, Int c, Int d, Int e, Int f, Int g, Int h, Int i, Int j, Int k, Int l) { return a+b+c+d+e+f+g+h+i+j+k+l }\n";
      src += "}\n";

      Type t = CompileToFanType(src);
      for (int i=0; i<12; i++)
        verifyReflectCalls(t, i);
    }

    private void verifyReflectCalls(Type t, int n)
    {
      object obj = t.make();
      Method ms = t.method("s" + n, true);
      Method mi = t.method("i" + n, true);

  //System.Console.WriteLine("-- " + ms);
  //System.Console.WriteLine("   " + mi);

      // anything less than n should throw Err
      for (int i=0; i<n; i++)
      {
        Err err = null;
        try { callList(obj, ms, i); } catch (Err.Val e) { err = e.err(); }
  //System.out.println("  " + err);
        verify(err != null);
        verify(err.message().val.StartsWith("Too few arguments: " + i));

        err = null;
        try { callList(obj, mi, i); } catch (Err.Val e) { err = e.err(); }
  //System.out.println("  " + err);
        verify(err != null);
        verify(err.message().val.StartsWith("Too few arguments: " + (i+1)));

        if (i <= Func.MaxIndirectParams)
        {
          err = null;
          try { callIndirect(ms, i); } catch (Err.Val e) { err = e.err(); }
  //System.out.println("  " + err);
          verify(err != null);
          verify(err.message().val.StartsWith("Too few arguments: " + i));
        }

        if (i+1 <= Func.MaxIndirectParams)
        {
          err = null;
          try { callIndirect(obj, mi, i); } catch (Err.Val e) { err = e.err(); }
    //System.out.println("  " + err);
          verify(err != null);
          verify(err.message().val.StartsWith("Too few arguments: " + (i+1)));
        }
      }

      // compute result 0->0, 1->1, 2->3, 3->7, etc
      int result = 0;
      for (int i=0; i<=n; i++) result += i;

      // anything n and over should be ok
      for (int i=n; i<12; i++)
      {
  //System.out.println("  verify " + i + " -> " + n);
        verify(callList(obj, ms, i), Int.make(result));
        verify(callList(obj, mi, i), Int.make(result));
        if (i <= Func.MaxIndirectParams)
          verify(callIndirect(ms, i), Int.make(result));
        if (i+1 <= Func.MaxIndirectParams)
          verify(callIndirect(obj, mi, i), Int.make(result));
      }
    }

    Int callList(object obj, Method m, int argn)
    {
      List list = new List(Sys.ObjType);
      if (!m.isStatic().val) list.add(obj);
      for (int i=0; i<argn; i++) list.add(Int.make(1+i));
      return (Int)m.call(list);
    }

    Int callIndirect(Method m, int argn)
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
        default: Fail(); break;
      }
      return null;
    }

    Int callIndirect(object obj, Method m, int argn)
    {
      switch (argn)
      {
        case 0:  return (Int)m.call1(obj);
        case 1:  return (Int)m.call2(obj, Int.make(1));
        case 2:  return (Int)m.call3(obj, Int.make(1), Int.make(2));
        case 3:  return (Int)m.call4(obj, Int.make(1), Int.make(2), Int.make(3));
        case 4:  return (Int)m.call5(obj, Int.make(1), Int.make(2), Int.make(3), Int.make(4));
        case 5:  return (Int)m.call6(obj, Int.make(1), Int.make(2), Int.make(3), Int.make(4), Int.make(5));
        case 6:  return (Int)m.call7(obj, Int.make(1), Int.make(2), Int.make(3), Int.make(4), Int.make(5), Int.make(6));
        case 7:  return (Int)m.call8(obj, Int.make(1), Int.make(2), Int.make(3), Int.make(4), Int.make(5), Int.make(6), Int.make(7));
        //case 8:  return (Int)m.call9(obj, Int.make(1), Int.make(2), Int.make(3), Int.make(4), Int.make(5), Int.make(6), Int.make(7), Int.make(8));
        //case 9:  return (Int)m.call10(obj, Int.make(1), Int.make(2), Int.make(3), Int.make(4), Int.make(5), Int.make(6), Int.make(7), Int.make(8), Int.make(9));
        //case 10: return (Int)m.call11(obj, Int.make(1), Int.make(2), Int.make(3), Int.make(4), Int.make(5), Int.make(6), Int.make(7), Int.make(8), Int.make(9), Int.make(10));
        //case 11: return (Int)m.call12(obj, Int.make(1), Int.make(2), Int.make(3), Int.make(4), Int.make(5), Int.make(6), Int.make(7), Int.make(8), Int.make(9), Int.make(10), Int.make(11));
        default: Fail(); break;
      }
      return null;
    }

  }
}