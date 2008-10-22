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
      src += "  Long i0() { return 0 }\n";
      src += "  Long i1(Long a) { return a }\n";
      src += "  Long i2(Long a, Long b) { return a+b }\n";
      src += "  Long i3(Long a, Long b, Long c) { return a+b+c }\n";
      src += "  Long i4(Long a, Long b, Long c, Long d) { return a+b+c+d }\n";
      src += "  Long i5(Long a, Long b, Long c, Long d, Long e) { return a+b+c+d+e }\n";
      src += "  Long i6(Long a, Long b, Long c, Long d, Long e, Long f) { return a+b+c+d+e+f }\n";
      src += "  Long i7(Long a, Long b, Long c, Long d, Long e, Long f, Long g) { return a+b+c+d+e+f+g }\n";
      src += "  Long i8(Long a, Long b, Long c, Long d, Long e, Long f, Long g, Long h) { return a+b+c+d+e+f+g+h }\n";
      src += "  Long i9(Long a, Long b, Long c, Long d, Long e, Long f, Long g, Long h, Long i) { return a+b+c+d+e+f+g+h+i }\n";
      src += "  Long i10(Long a, Long b, Long c, Long d, Long e, Long f, Long g, Long h, Long i, Long j) { return a+b+c+d+e+f+g+h+i+j }\n";
      src += "  Long i11(Long a, Long b, Long c, Long d, Long e, Long f, Long g, Long h, Long i, Long j, Long k) { return a+b+c+d+e+f+g+h+i+j+k }\n";
      src += "  Long i12(Long a, Long b, Long c, Long d, Long e, Long f, Long g, Long h, Long i, Long j, Long k, Long l) { return a+b+c+d+e+f+g+h+i+j+k+l }\n";
      src += "  static Long s0() { return 0 }\n";
      src += "  static Long s1(Long a) { return a }\n";
      src += "  static Long s2(Long a, Long b) { return a+b }\n";
      src += "  static Long s3(Long a, Long b, Long c) { return a+b+c }\n";
      src += "  static Long s4(Long a, Long b, Long c, Long d) { return a+b+c+d }\n";
      src += "  static Long s5(Long a, Long b, Long c, Long d, Long e) { return a+b+c+d+e }\n";
      src += "  static Long s6(Long a, Long b, Long c, Long d, Long e, Long f) { return a+b+c+d+e+f }\n";
      src += "  static Long s7(Long a, Long b, Long c, Long d, Long e, Long f, Long g) { return a+b+c+d+e+f+g }\n";
      src += "  static Long s8(Long a, Long b, Long c, Long d, Long e, Long f, Long g, Long h) { return a+b+c+d+e+f+g+h }\n";
      src += "  static Long s9(Long a, Long b, Long c, Long d, Long e, Long f, Long g, Long h, Long i) { return a+b+c+d+e+f+g+h+i }\n";
      src += "  static Long s10(Long a, Long b, Long c, Long d, Long e, Long f, Long g, Long h, Long i, Long j) { return a+b+c+d+e+f+g+h+i+j }\n";
      src += "  static Long s11(Long a, Long b, Long c, Long d, Long e, Long f, Long g, Long h, Long i, Long j, Long k) { return a+b+c+d+e+f+g+h+i+j+k }\n";
      src += "  static Long s12(Long a, Long b, Long c, Long d, Long e, Long f, Long g, Long h, Long i, Long j, Long k, Long l) { return a+b+c+d+e+f+g+h+i+j+k+l }\n";
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
        verify(err.message().StartsWith("Too few arguments: " + i));

        err = null;
        try { callList(obj, mi, i); } catch (Err.Val e) { err = e.err(); }
  //System.out.println("  " + err);
        verify(err != null);
        verify(err.message().StartsWith("Too few arguments: " + (i+1)));

        if (i <= Func.MaxIndirectParams)
        {
          err = null;
          try { callIndirect(ms, i); } catch (Err.Val e) { err = e.err(); }
  //System.out.println("  " + err);
          verify(err != null);
          verify(err.message().StartsWith("Too few arguments: " + i));
        }

        if (i+1 <= Func.MaxIndirectParams)
        {
          err = null;
          try { callIndirect(obj, mi, i); } catch (Err.Val e) { err = e.err(); }
    //System.out.println("  " + err);
          verify(err != null);
          verify(err.message().StartsWith("Too few arguments: " + (i+1)));
        }
      }

      // compute result 0->0, 1->1, 2->3, 3->7, etc
      int result = 0;
      for (int i=0; i<=n; i++) result += i;

      // anything n and over should be ok
      for (int i=n; i<12; i++)
      {
  //System.out.println("  verify " + i + " -> " + n);
        verify(callList(obj, ms, i), Long.valueOf(result));
        verify(callList(obj, mi, i), Long.valueOf(result));
        if (i <= Func.MaxIndirectParams)
          verify(callIndirect(ms, i), Long.valueOf(result));
        if (i+1 <= Func.MaxIndirectParams)
          verify(callIndirect(obj, mi, i), Long.valueOf(result));
      }
    }

    Long callList(object obj, Method m, int argn)
    {
      List list = new List(Sys.ObjType);
      if (!m.isStatic().booleanValue()) list.add(obj);
      for (int i=0; i<argn; i++) list.add(Long.valueOf(1+i));
      return (Long)m.call(list);
    }

    Long callIndirect(Method m, int argn)
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
        default: Fail(); break;
      }
      return null;
    }

    Long callIndirect(object obj, Method m, int argn)
    {
      switch (argn)
      {
        case 0:  return (Long)m.call1(obj);
        case 1:  return (Long)m.call2(obj, Long.valueOf(1));
        case 2:  return (Long)m.call3(obj, Long.valueOf(1), Long.valueOf(2));
        case 3:  return (Long)m.call4(obj, Long.valueOf(1), Long.valueOf(2), Long.valueOf(3));
        case 4:  return (Long)m.call5(obj, Long.valueOf(1), Long.valueOf(2), Long.valueOf(3), Long.valueOf(4));
        case 5:  return (Long)m.call6(obj, Long.valueOf(1), Long.valueOf(2), Long.valueOf(3), Long.valueOf(4), Long.valueOf(5));
        case 6:  return (Long)m.call7(obj, Long.valueOf(1), Long.valueOf(2), Long.valueOf(3), Long.valueOf(4), Long.valueOf(5), Long.valueOf(6));
        case 7:  return (Long)m.call8(obj, Long.valueOf(1), Long.valueOf(2), Long.valueOf(3), Long.valueOf(4), Long.valueOf(5), Long.valueOf(6), Long.valueOf(7));
        //case 8:  return (Long)m.call9(obj, Long.valueOf(1), Long.valueOf(2), Long.valueOf(3), Long.valueOf(4), Long.valueOf(5), Long.valueOf(6), Long.valueOf(7), Long.valueOf(8));
        //case 9:  return (Long)m.call10(obj, Long.valueOf(1), Long.valueOf(2), Long.valueOf(3), Long.valueOf(4), Long.valueOf(5), Long.valueOf(6), Long.valueOf(7), Long.valueOf(8), Long.valueOf(9));
        //case 10: return (Long)m.call11(obj, Long.valueOf(1), Long.valueOf(2), Long.valueOf(3), Long.valueOf(4), Long.valueOf(5), Long.valueOf(6), Long.valueOf(7), Long.valueOf(8), Long.valueOf(9), Long.valueOf(10));
        //case 11: return (Long)m.call12(obj, Long.valueOf(1), Long.valueOf(2), Long.valueOf(3), Long.valueOf(4), Long.valueOf(5), Long.valueOf(6), Long.valueOf(7), Long.valueOf(8), Long.valueOf(9), Long.valueOf(10), Long.valueOf(11));
        default: Fail(); break;
      }
      return null;
    }

  }
}