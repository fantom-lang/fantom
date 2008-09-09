//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Sep 06  Andy Frank  Creation
//

using System;
using System.Reflection;
using Bool  = Fan.Sys.Bool;
using Int   = Fan.Sys.Int;
using Float = Fan.Sys.Float;
using Str   = Fan.Sys.Str;
using Duration = Fan.Sys.Duration;

namespace Fanx.Test
{
  /// <summary>
  /// Test is the base class of test cases as well as the
  /// main entry for test harness.
  /// </summary>
  public abstract class Test
  {

  //////////////////////////////////////////////////////////////////////////
  // Test Case List
  //////////////////////////////////////////////////////////////////////////

    public static string[] tests =
    {
      "UtilTest",
      //"EmitTest",
      //"LiteralExprTest",
      //"ExprTest",
      //"StmtTest",
      //"SlotDefTest",
      //"TryTest",
      //"ParamTest",
      //"InheritTest",
      //"IsAsTest",
      //"ReflectTest",
      //"ListTest",
      //"CallTest",
      //"MethodTest",
      //"ClosureTest",
    };

  //////////////////////////////////////////////////////////////////////////
  // Test Cases
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Get the test name.
    /// </summary>
    public string TestName()
    {
      return testName;
    }

    /// <summary>
    /// Return true if we should skip this test.
    /// </summary>
    public virtual bool Skip()
    {
      return false;
    }

    /// <summary>
    /// Run the test case - any exception thrown
    /// is considered a failed test.
    /// </summary>
    public abstract void Run();

  //////////////////////////////////////////////////////////////////////////
  // verify Utils
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// verify the condition is true, otherwise throw an exception.
    /// </summary>
    public void verify(bool b)
    {
      if (!b) throw new Exception("Test failed");
      verified++;
      totalVerified++;
    }

    /// <summary>
    /// verify a and b are equal taking into account nulls.
    /// </summary>
    public void verify(Object a, Object b)
    {
      try
      {
        if (a == null) verify(b == null);
        else if (b == null) verify(false);
        else verify(a.Equals(b));
      }
      catch (Exception e)
      {
        if (e.Message != "Test failed") throw e;
        throw new Exception("Test failed " + a  + " != " + b);
      }
    }

    /// <summary>
    /// Force test failure
    /// </summary>
    public void Fail()
    {
      verify(false);
    }

  //////////////////////////////////////////////////////////////////////////
  // Misc Utils
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Print a line to standard out.
    /// </summary>
    public static void WriteLine(Object s)
    {
      Console.WriteLine(s);
    }

    /// <summary>
    /// Print a line to standard out if in verbose mode.
    /// </summary>
    public static void Verbose(Object s)
    {
      if (verbose) Console.WriteLine(s);
    }

    /// <summary>
    /// Get the temporary directory to use for tests.
    /// </summary>
    //public static File Temp()
    //{
    //  temp.mkdirs();
    //  return temp;
    //}

  //////////////////////////////////////////////////////////////////////////
  // Main
  //////////////////////////////////////////////////////////////////////////

    static bool RunTest(string testName)
    {
      try
      {
        Type type = Type.GetType("Fanx.Test." + testName);
        Test test = (Test)Activator.CreateInstance(type);
        test.testName = testName;
        if (test.Skip())
        {
          WriteLine("-- Skip: sys::" + testName + " [skip]");
        }
        else
        {
          WriteLine("-- Run:  sys::" + testName + "...");
          long start = Environment.TickCount;
          test.Run();
          long end = Environment.TickCount;
          WriteLine("   Pass: sys::" + testName + " [" + test.verified + "] " + (end-start) + "ms");
        }
        return true;
      }
      catch (Exception e)
      {
        WriteLine("### Failed: " + testName);
        WriteLine(e.ToString());
        return false;
      }
    }

    public static bool RunTests(string pattern)
    {
      //temp = new File("temp");

      if (pattern == null) pattern = "";

      bool allPassed = true;
      int testCount = 0;

      long start = Environment.TickCount;
      for (int i=0; i<tests.Length; i++)
      {
        if (tests[i].StartsWith(pattern))
        {
          testCount++;
          if (!RunTest(tests[i]))
            allPassed = false;
        }
      }
      long end = Environment.TickCount;

      double elapsed = (end-start) / (1000d * 60d);
      elapsed = Math.Round(elapsed, 2);

      if (allPassed)
      {
        WriteLine("\n*** All Tests Passed!!! [" + totalVerified + "] "
          + elapsed + "min (" + (end-start) + "ms)");
      }

      //CompileTest.Cleanup();
      //try { FileUtil.delete(temp); } catch(IOException e) { e.printStackTrace(); }

      return allPassed;
    }

  //////////////////////////////////////////////////////////////////////////
  // Array Utils
  //////////////////////////////////////////////////////////////////////////

    public Bool MakeBool(bool a)
    {
      return Bool.make(a);
    }

    public Bool[] MakeBools(bool a)
    {
      return new Bool[] { MakeBool(a) };
    }

    public Bool[] MakeBools(bool a, bool b)
    {
      return new Bool[] { MakeBool(a), MakeBool(b) };
    }

    public Bool[] MakeBools(bool a, bool b, bool c)
    {
      return new Bool[] { MakeBool(a), MakeBool(b), MakeBool(c) };
    }

    public Int[] MakeInts(long a)
    {
      return new Int[] { Int.make(a) };
    }

    public Int[] MakeInts(long a, long b)
    {
      return new Int[] { Int.make(a), Int.make(b) };
    }

    public Int[] MakeInts(long a, long b, long c)
    {
      return new Int[] { Int.make(a), Int.make(b), Int.make(c) };
    }

    public Int[] MakeInts(long a, long b, long c, long d)
    {
      return new Int[] { Int.make(a), Int.make(b), Int.make(c), Int.make(d) };
    }

    public Int[] MakeInts(long a, long b, long c, long d, long e)
    {
      return new Int[] { Int.make(a), Int.make(b), Int.make(c), Int.make(d), Int.make(e) };
    }

    public Int[] MakeInts(long a, long b, long c, long d, long e, long f)
    {
      return new Int[] { Int.make(a), Int.make(b), Int.make(c), Int.make(d), Int.make(e), Int.make(f) };
    }

    public Float[] MakeFloats(double a)
    {
      return new Float[] { Float.make(a) };
    }

    public Float[] MakeFloats(double a, double b)
    {
      return new Float[] { Float.make(a), Float.make(b) };
    }

    public Float[] MakeFloats(double a, double b, double c)
    {
      return new Float[] { Float.make(a), Float.make(b), Float.make(c) };
    }

    public Str[] MakeStrs(String a)
    {
      return new Str[] { Str.make(a) };
    }

    public Str[] MakeStrs(String a, String b)
    {
      return new Str[] { Str.make(a), Str.make(b) };
    }

    public Str[] MakeStrs(String a, String b, String c)
    {
      return new Str[] { Str.make(a), Str.make(b), Str.make(c) };
    }

    public Str[] MakeStrs(String a, String b, String c, String d)
    {
      return new Str[] { Str.make(a), Str.make(b), Str.make(c), Str.make(d) };
    }

    public Str[] MakeStrs(String a, String b, String c, String d, String e)
    {
      return new Str[] { Str.make(a), Str.make(b), Str.make(c), Str.make(d), Str.make(e) };
    }

    public Duration[] MakeDurs(long a)
    {
      return new Duration[] { Duration.make(a) };
    }

    public Duration[] MakeDurs(long a, long b)
    {
      return new Duration[] { Duration.make(a), Duration.make(b)  };
    }

    public Duration[] MakeDurs(long a, long b, long c)
    {
      return new Duration[] { Duration.make(a), Duration.make(b), Duration.make(c) };
    }

  //////////////////////////////////////////////////////////////////////////
  // Reflection Utils
  //////////////////////////////////////////////////////////////////////////

    public object Make(System.Type type) { return Make(type, new object[0]); }
    public object Make(System.Type type, object[] args)
    {
      return type.InvokeMember("Make", GetStaticFlags(), null, null, args);
    }

    public object InvokeStatic(System.Type type, string name)
    {
      return InvokeStatic(type, name, new object[0]);
    }
    public object InvokeStatic(System.Type type, string name, object[] args)
    {
      return type.InvokeMember(name, GetStaticFlags(), null, null, args);
    }

    public object InvokeInstance(System.Type type, object obj, string name)
    {
      return InvokeInstance(type, obj, name, new object[0]);
    }
    public object InvokeInstance(System.Type type, object obj, string name, object[] args)
    {
      return type.InvokeMember(name, GetInstanceFlags(), null, obj, args);
    }

    public MethodInfo FindMethod(Type type, String name)
    {
      return FindMethod(type, name, -1);
    }

    public MethodInfo FindMethod(Type type, String name, int paramCount)
    {
      MethodInfo method;
      method = FindMethod(type, name, paramCount, type.GetMethods()); if (method != null) return method;
      //method = FindMethod(type, name, paramCount, type.GetDeclaredMethods()); if (method != null) return method;
      throw new Exception("No method " + name);
    }

    public MethodInfo FindMethod(Type type, String name, int paramCount, MethodInfo[] methods)
    {
      for (int i=0; i<methods.Length; ++i)
        if (methods[i].Name == name)
        {
          if (paramCount != -1 && methods[i].GetParameters().Length != paramCount) continue;
          return methods[i];
        }
      return null;
    }

    public Object Get(Object instance, string name)
    {
      BindingFlags flags = BindingFlags.Public | BindingFlags.Static | BindingFlags.Instance;
      if (instance is Type)
        return ((Type)instance).GetField(name, flags).GetValue(null);
      else
        return instance.GetType().GetField(name, flags).GetValue(instance);
    }

    public BindingFlags GetStaticFlags()
    {
      return BindingFlags.Public | BindingFlags.InvokeMethod | BindingFlags.Static;
    }

    public BindingFlags GetInstanceFlags()
    {
      return BindingFlags.Public | BindingFlags.InvokeMethod | BindingFlags.Instance;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public static bool verbose;
    public static int totalVerified;
    //private static File temp;
    private int verified;
    private string testName = null;
  }
}